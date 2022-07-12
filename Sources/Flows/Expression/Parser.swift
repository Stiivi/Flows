//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 27/05/2022.
//

import Foundation

public enum ParserError: Error, Equatable, CustomStringConvertible {
    case invalidCharacterInNumber
    case unexpectedCharacter
    case missingRightParenthesis
    case expressionExpected
    case unexpectedToken
    case emptyString
    
    public var description: String {
        switch self {
        case .invalidCharacterInNumber: return "Invalid character in a number"
        case .unexpectedCharacter: return "Unexpected character"
        case .missingRightParenthesis: return "Right parenthesis ')' expected"
        case .expressionExpected: return "Expected expression"
        case .unexpectedToken: return "Unexpected token"
        case .emptyString: return "Empty expression string"
        }
    }
}

// https://craftinginterpreters.com/parsing-expressions.html
// https://stackoverflow.com/questions/2245962/writing-a-parser-like-flex-bison-that-is-usable-on-8-bit-embedded-systems/2336769#2336769

enum ASTNode {
    case identifier(String)
    case number(String)
    case call(String, [ASTNode])
}

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
            var sanitizedString = number.text
            sanitizedString.removeAll { $0 == "_" }
            return Value.int(Int(sanitizedString)!)
        }
        else if let number = accept(.float) {
            var sanitizedString = number.text
            sanitizedString.removeAll { $0 == "_" }
            return Value.double(Double(sanitizedString)!)
        }
        else {
            return nil
        }
    }
    
    // variable_call -> IDENTIFIER ["(" ARGUMENTS ")"]
    
    func variable_call() throws -> Expression? {
        guard let ident = identifier() else {
            return nil
        }
        
        if accept(.leftParen) != nil {
            var arguments: [Expression] = []
            if accept(.rightParen) == nil {
                repeat {
                    if let arg = try expression() {
                        arguments.append(arg)
                    }
                } while accept(.comma) != nil
            }
            if accept(.rightParen) == nil {
                throw ParserError.missingRightParenthesis
            }
            return .function(ident, arguments)
        }
        else {
            // We got a variable
            return .variable(ident)
        }
    }
    
    // primary -> NUMBER | STRING | VARIABLE_CALL | "(" expression ")" ;

    func primary() throws -> Expression? {
        // TODO: true, false, nil
        if let value = number() {
            return .value(value)
        }
        else if let expr = try variable_call() {
            return expr
        }
        if accept(.leftParen) != nil {
            let expr = try expression()
            if accept(.rightParen) == nil {
                throw ParserError.missingRightParenthesis
            }
            return expr
        }
        return nil
    }
    
    // unary -> "-" unary | primary ;
    //
    func unary() throws -> Expression? {
        // TODO: Add '!'
        if let op = `operator`("-") {
            guard let right = try unary() else {
                throw ParserError.expressionExpected
            }
            return .unary(op, right)
        }
        else {
            return try primary()
        }
        
    }

    // factor -> unary ( ( "/" | "*" ) unary )* ;
    //

    func factor() throws -> Expression? {
        guard var expr = try unary() else {
            return nil
        }
        
        while let op = `operator`("*") ?? `operator`("/") ?? `operator`("%"){
            guard let right = try unary() else {
                throw ParserError.expressionExpected
            }
            expr = .binary(op, expr, right)
        }
        
        return expr
    }

    // term -> factor ( ( "-" | "+" ) factor )* ;
    //
    func term() throws -> Expression? {
        guard var expr = try factor() else {
            return nil
        }
        
        while let op = `operator`("+") ?? `operator`("-") {
            guard let right = try factor() else {
                throw ParserError.expressionExpected
            }
            expr = .binary(op, expr, right)
        }
        
        return expr
    }
    
    func expression() throws -> Expression? {
        return try term()
    }
    
    
    public func parse() throws -> Expression {
        guard let expr = try expression() else {
            throw ParserError.emptyString
        }
        
        if currentToken?.type != .empty {
            throw ParserError.unexpectedToken
        }
        return expr
    }
    
}
