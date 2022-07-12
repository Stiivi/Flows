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
    
    public var description: String {
        switch self {
        case .invalidCharacterInNumber: return "Invalid character in a number"
        case .unexpectedCharacter: return "Unexpected character"
        case .missingRightParenthesis: return "Right parenthesis ')' expected"
        case .expressionExpected: return "Expected expression"
        case .unexpectedToken: return "Unexpected token"
        }
    }
}

// https://craftinginterpreters.com/parsing-expressions.html
// https://stackoverflow.com/questions/2245962/writing-a-parser-like-flex-bison-that-is-usable-on-8-bit-embedded-systems/2336769#2336769


public class Parser {
    let lexer: Lexer
    var currentToken: Token?
    
    /// Creates a new parser using an expression lexer.
    ///
    public init(lexer: Lexer) {
        self.lexer = lexer
        advance()
    }
    
    /// Creates a new parser for an expression source string.
    ///
    public convenience init(string: String) {
        self.init(lexer: Lexer(string: string))
    }
    
    /// True if the parser is at the end of the source.
    public var atEnd: Bool {
        if let token = currentToken {
            return token.type == .empty
        }
        else {
            return true
        }
    }
    
    /// Advance to the next token.
    ///
    func advance() {
        currentToken = lexer.next()
    }
    
    /// Accent a token a type ``type``.
    ///
    /// - Returns: A token if the token matches the expected type, ``nil`` if
    ///     the token does not match the expected type.
    ///
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
    
    func `operator`(_ op: String) -> Token? {
        guard let token = currentToken else {
            return nil
        }
        if token.type == .operator && token.text == op {
            advance()
            return token
        }
        else {
            return nil
        }

    }
    
    func identifier() -> Token? {
        if let token = accept(.identifier) {
            return token
        }
        else {
            return nil
        }
    }

    func number() -> ASTExpression? {
        if let token = accept(.int) {
            return .number(token)
        }
        else if let token = accept(.float) {
            return .number(token)
        }
        else {
            return nil
        }
    }
    
    // variable_call -> IDENTIFIER ["(" ARGUMENTS ")"]
    
    func variable_or_call() throws -> ASTExpression? {
        guard let ident = identifier() else {
            return nil
        }
        // FIXME: Preserve the paren tokens
        if let leftParen = accept(.leftParen) {
            var arguments: [ASTExpression] = []
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
    
    // primary -> NUMBER | STRING | VARIABLE_OR_CALL | "(" expression ")" ;

    func primary() throws -> ASTExpression? {
        // TODO: true, false, nil
        if let node = number() {
            return node
        }
        else if let node = try variable_or_call() {
            return node
        }
        else if let lparen = accept(.leftParen) {
            if let expr = try expression() {
                guard let rparen = accept(.rightParen) else {
                    throw ParserError.missingRightParenthesis
                }
                return .parenthesis(lparen, expr, rparen)
            }
        }
        return nil
    }
    
    // unary -> "-" unary | primary ;
    //
    func unary() throws -> ASTExpression? {
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

    func factor() throws -> ASTExpression? {
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
    func term() throws -> ASTExpression? {
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
    
    func expression() throws -> ASTExpression? {
        return try term()
    }
    
    
    public func parse() throws -> Expression {
        guard let expr = try expression() else {
            throw ParserError.expressionExpected
        }
        
        if currentToken?.type != .empty {
            throw ParserError.unexpectedToken
        }
        return expr.toExpression()
    }
    
}
