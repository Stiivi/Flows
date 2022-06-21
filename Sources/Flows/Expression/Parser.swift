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



enum TokenType: Equatable {
    case empty
    case int
    case float
    case `operator`
    case identifier
    case leftParen
    case rightParen
    case comma
    case error(ParserError)
}

struct Token {
    let type: TokenType
    let location: Lexer.Location
    let startIndex: String.Index
    let endIndex: String.Index
    
    /// Flag whether the lexer has seen a whitespace before the token
    let seenWhitespace: Bool
    let text: String
}

// TODO: Use drop(while:)

class Lexer {
    var string: String
    var currentIndex: String.Index
    
    var currentChar: Character?
    
    var location: Location
    
    /// Token start index
    var startIndex: String.Index
    var endIndex: String.Index
    
    var text: Substring {
        string[startIndex..<currentIndex]
    }
    
    var seenWhitespace: Bool = false
    
    /// Location within a text.
    public struct Location: CustomStringConvertible {
        /// Line number in human representation, starting with 1.
        var line: Int = 1
        
        /// Column number in human representation, starting with 1 for the
        /// leftmost column.
        var column: Int = 1

        /// Advances the location by one character.
        ///
        /// - Parameters:
        ///     - newLine: if `true` then we are advancing to the new line and
        ///       resetting the column to 1.
        ///
        mutating func advance(_ character: Character) {
            if character.isNewline {
                column = 1
                line += 1
            }
            else {
                column += 1
            }
        }

        public var description: String {
            return "\(line):\(column)"
        }
    }
    
    
    init(string: String) {
        self.string = string
        currentIndex = string.startIndex
        startIndex = currentIndex
        endIndex = currentIndex
        
        if string.startIndex < string.endIndex {
            currentChar = string[currentIndex]
        }
        else {
            currentChar = nil
        }
        
        location = Location()
    }
    
    var atEnd: Bool {
        return currentIndex == string.endIndex
    }
    
    func advance() {
        guard !atEnd else {
            return
        }
        
        // Advance current index and current character
        //
        currentIndex = string.index(after: currentIndex)

        if currentIndex < string.endIndex {
            currentChar = string[currentIndex]
            location.advance(currentChar!)
        }
        else {
            currentChar = nil
        }
    }
    
    func makeToken(type: TokenType) -> Token {
        return Token(type: type,
                     location: location,
                     startIndex: startIndex,
                     endIndex: currentIndex,
                     seenWhitespace: seenWhitespace,
                     text: String(text))
    }
    
    func accept() {
        guard currentChar != nil else {
            fatalError("Accepting without current character")
        }
        endIndex = currentIndex
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
    
    func acceptNumber() -> TokenType? {
        var type: TokenType = .int
        
        if !accept(\.isWholeNumber) {
            return nil
        }

        while accept(\.isWholeNumber) || accept("_") {
            // Just accept it
        }

        if accept(".") {
            // At least one number after the decimal point
            if !accept(\.isWholeNumber) {
                return .error(.invalidCharacterInNumber)
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
                return .error(.invalidCharacterInNumber)
            }
            while accept(\.isWholeNumber) || accept("_") {
                // Just accept it
            }
            type = .float
        }
        
        if accept(\.isLetter) {
            return .error(.invalidCharacterInNumber)
        }
        else {
            return type
        }
    }
    
    func acceptIdentifier() -> TokenType? {
        guard accept(\.isLetter) || accept("_") else {
            return nil
        }

        while accept(\.isLetter) || accept(\.isWholeNumber) || accept("_") {
            // Just accept it
        }
        
        return .identifier
    }

    func acceptOperator() -> TokenType? {
        if accept("-") || accept("+") || accept("*") || accept("/") || accept("%") {
            return .operator
        }
        else {
            return nil
        }
    }

    func acceptPunctuation() -> TokenType? {
        if accept("(") {
            return .leftParen
        }
        else if accept(")") {
            return .rightParen
        }
        else if accept(",") {
            return .comma
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
            return makeToken(type: .empty)
        }

        startIndex = currentIndex
                
        if let type = acceptNumber()
                        ?? acceptIdentifier()
                        ?? acceptOperator()
                        ?? acceptPunctuation() {
            return makeToken(type: type)
        }
        else {
            accept()
            return makeToken(type: .error(.unexpectedCharacter))
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
