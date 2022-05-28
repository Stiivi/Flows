//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 27/05/2022.
//

import Foundation

enum LexerError: Error, Equatable {
    case invalidCharacterInNumber
    case unexpectedCharacter
}

enum TokenType: Equatable {
    case empty
    case int
    case float
    case `operator`
    case identifier
    case leftParen
    case rightParen
    case comma
    case error(LexerError)
}

struct Token {
    let type: TokenType
    let location: Int
    let text: String
}

// TODO: Use drop(while:)

class Lexer {
    var iterator: String.Iterator
    var currentChar: Character?
    var location: Int
    
    var start: Int
    var text: String
    var seenWhitespace: Bool = false
    
    init(string: String) {
        self.iterator = string.makeIterator()
        location = 0
        start = 0
        text = ""
        advance()
    }
    
    var atEnd: Bool {
        return currentChar == nil
    }
    
    func advance() {
        currentChar = iterator.next()
        if currentChar != nil {
            location += 1
        }
    }
    
    func accept() {
        guard let char = currentChar else {
            fatalError("Accepting without current character")
        }
        text += String(char)
        advance()
    }
    
    @discardableResult
    func accept(_ char: Character) -> Bool {
        if currentChar == char {
            accept()
            return true
        }
        else {
            return false
        }
    }
    
    @discardableResult
    func accept(_ predicate: (Character) -> Bool) -> Bool {
        guard let char = currentChar else {
            return false
        }
        if predicate(char) {
            accept()
            return true
        }
        else {
            return false
        }
    }
    
    func acceptNumber() -> Token? {
        var type: TokenType = .int
        guard accept(\.isWholeNumber) else {
            return nil
        }

        while accept(\.isWholeNumber) || accept("_") {
            // Just accept it
        }

        if accept(".") {
            // At least one number after the decimal point
            if !accept(\.isWholeNumber) {
                return Token(type: .error(.invalidCharacterInNumber),
                             location: start,
                             text: text
                )
            }
            while accept(\.isWholeNumber) || accept("_") {
                // Just accept it
            }

            type = .float
        }
        
        if accept("e") || accept("E") {
            // Possible float
            // At least one number after the decimal point
            accept("-")
            if !accept(\.isWholeNumber) {
                return Token(type: .error(.invalidCharacterInNumber),
                             location: start,
                             text: text
                )
            }
            while accept(\.isWholeNumber) || accept("_") {
                // Just accept it
            }
            type = .float
        }
        
        if accept(\.isLetter) {
            return Token(type: .error(.invalidCharacterInNumber),
                         location: start,
                         text: text
            )
        }
        else {
            return Token(type: type,
                         location: start,
                         text: text
            )
        }
    }
    
    func acceptIdentifier() -> Token? {
        guard accept(\.isLetter) || accept("_") else {
            return nil
        }

        while accept(\.isLetter) || accept(\.isWholeNumber) || accept("_") {
            // Just accept it
        }
        
        return Token(type: .identifier, location: start, text: text)
    }

    func acceptOperator() -> Token? {
        if accept("-") {
//            if let maybeNumber = acceptNumber() {
//                return maybeNumber
//            }
//            else {
                return Token(type: .operator, location: start, text: text)
//            }
            // FIXME: Deal with negative integer and/or unary minus
        }
        else if accept("+") || accept("*") || accept("/") || accept("^") {
            return Token(type: .operator, location: start, text: text)
        }
        else {
            return nil
        }
    }

    func acceptPunctuation() -> Token? {
        if accept("(") {
            return Token(type: .leftParen, location: start, text: text)
        }
        else if accept(")") {
            return Token(type: .rightParen, location: start, text: text)
        }
        else if accept(",") {
            return Token(type: .comma, location: start, text: text)
        }
        else {
            return nil
        }
    }
    
    func next() -> Token {
        // Skip whitespace
        seenWhitespace = false
        while(accept(\.isWhitespace)) {
            seenWhitespace = true
        }

        guard !atEnd else {
            return Token(type: .empty, location: start, text: "")
        }

        start = location
        text = ""
                
        if let token = acceptNumber()
                        ?? acceptIdentifier()
                        ?? acceptOperator()
                        ?? acceptPunctuation() {
            return token
        }
        else {
            accept()
            return Token(type: .error(.unexpectedCharacter), location: start, text: text)
        }
    }
}

// https://craftinginterpreters.com/parsing-expressions.html

class Parser {
    let lexer: Lexer
    var currentToken: Token?
    
    init(lexer: Lexer) {
        self.lexer = lexer
    }
    
    init(string: String) {
        self.lexer = Lexer(string: string)
        advance()
    }
    
    var atEnd: Bool { currentToken == nil }
    
    func advance() {
        currentToken = lexer.next()
    }
    
    func accept(_ type: TokenType) -> Token? {
        guard let token = currentToken else {
            return nil
        }
        if token.type == type {
            advance()
            return token
        }
        else {
            return nil
        }
    }

    // ----------------------------------------------------------------
    
    func `operator`(_ op: String) -> String? {
        guard let token = currentToken else {
            return nil
        }
        if token.type == .operator && token.text == op {
            advance()
            return token.text
        }
        else {
            return nil
        }

    }
    
    func identifier() -> String? {
        if let ident = accept(.identifier) {
            return ident.text
        }
        else {
            return nil
        }
    }

    func number() -> Value? {
        if let number = accept(.int) {
            return Value.int(Int(number.text)!)
        }
        else if let number = accept(.float) {
            return Value.float(Float(number.text)!)
        }
        else {
            return nil
        }
    }
    
    // variable_call -> IDENTIFIER ["(" ARGUMENTS ")"]
    
    func variable_call() -> Expression? {
        guard let ident = identifier() else {
            return nil
        }
        
        if accept(.leftParen) != nil {
            var arguments: [Expression] = []
            if accept(.rightParen) == nil {
                repeat {
                    if let arg = expression() {
                        arguments.append(arg)
                    }
                } while accept(.comma) != nil
            }
            if accept(.rightParen) == nil {
                fatalError("Expected ')' after arguments")
            }
            return .function(ident, arguments)
        }
        else {
            // We got a variable
            return .variable(ident)
        }
    }
    
    // primary -> NUMBER | STRING | VARIABLE_CALL | "(" expression ")" ;

    func primary() -> Expression? {
        // TODO: true, false, nil
        if let value = number() {
            return .value(value)
        }
        else if let expr = variable_call() {
            return expr
        }
        if accept(.leftParen) != nil {
            let expr = expression()
            if accept(.rightParen) == nil {
                fatalError("Expected ')'")
            }
            return expr
        }
        return nil
    }
    
    // unary -> ( "!" | "-" ) unary | primary ;
    //
    func unary() -> Expression? {
        // TODO: Add '!'
        if let op = `operator`("-") {
            guard let right = unary() else {
                fatalError("Expected expression")
            }
            return .unary(op, right)
        }
        else {
            return primary()
        }
        
    }

    // factor -> unary ( ( "/" | "*" ) unary )* ;
    //

    func factor() -> Expression? {
        guard var expr = unary() else {
            return nil
        }
        
        while let op = `operator`("/") ?? `operator`("*") {
            guard let right = unary() else {
                fatalError("Expected factor")
            }
            expr = .binary(op, expr, right)
        }
        
        return expr
    }

    // term -> factor ( ( "-" | "+" ) factor )* ;
    //
    func term() -> Expression? {
        guard var expr = factor() else {
            return nil
        }
        
        while let op = `operator`("+") ?? `operator`("-") {
            guard let right = factor() else {
                fatalError("Expected factor")
            }
            expr = .binary(op, expr, right)
        }
        
        return expr
    }
    
    func expression() -> Expression? {
        return term()
    }
    
    
    public func parse() -> Expression? {
        let expr = expression()
        
        print("FINISHED WITH: \(currentToken)")
        if currentToken?.type != .empty {
            fatalError("Unexpected token: \(String(describing: currentToken))")
        }
        return expr
    }
}
