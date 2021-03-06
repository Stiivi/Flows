//
//  ModelParser.swift
//  
//
//  Created by Stefan Urbanek on 13/07/2022.
//

/*
 syntax:
 
 STOCK identifier = expression
 FLOW identifier = expression
    FROM identifier
    TO identifier
 
 VAR identifier = expression
 

 OUTPUT identifier, identifier, identifier
 */


/// Error that occurred during parsing.
public enum ParseError: Error, Equatable, CustomStringConvertible {
    /// Syntax error encountered. Information about location is contained in
    /// the token.
    case syntaxError(SyntaxError, Token)
    
    public var description: String {
        switch self {
        case let .syntaxError(error, token):
            return "Syntax error at \(token.textLocation) around '\(token.text)': \(error)"
        }
    }
}

class ModelParser: ExpressionParser {
    
    public convenience init(string: String) {
        self.init(lexer: Lexer(string: string, mode: .model))
    }

    // ----------------------------------------------------------------
    

    func accept(keyword: String) -> Bool {
        guard let token = currentToken else {
            return false
        }
        if token.type == .keyword && token.text.lowercased() == keyword {
            advance()
            return true
        }
        else {
            return false
        }
    }

    func stock() throws -> ModelAST? {
        var tokens: [Token] = []
        let options: [String]
        
        if let lparen = accept(.leftParen) {
            tokens.append(lparen)
            
            guard let option = identifier() else {
                throw SyntaxError.identifierExpected
            }
            tokens.append(option)
            guard let rparen = accept(.rightParen) else {
                throw SyntaxError.missingRightParenthesis
            }
            tokens.append(rparen)
            options = [option.text]
        }
        else {
            options = []
        }
        
        guard let name = identifier() else {
            throw SyntaxError.identifierExpected
        }
        tokens.append(name)
        guard let assignment = accept(.assignment) else {
            throw SyntaxError.assignmentExpected
        }
        tokens.append(assignment)
        guard let expression = try self.expression() else {
            throw SyntaxError.expressionExpected
        }
        tokens += expression.tokens
        return ModelAST(.stock(name.text, options, expression),
                        tokens: tokens)
    }
    
    func variable() throws -> ModelAST? {
        guard let name = identifier() else {
            throw SyntaxError.identifierExpected
        }
        guard accept(.assignment) != nil else {
            throw SyntaxError.assignmentExpected
        }
        guard let expression = try self.expression() else {
            throw SyntaxError.expressionExpected
        }
        // FIXME: Assign tokens
        return ModelAST(.variable(name.text, expression),
                        tokens: [])
    }

    func flow() throws -> ModelAST? {
        guard let name = identifier() else {
            throw SyntaxError.identifierExpected
        }
        guard accept(.assignment) != nil else {
            throw SyntaxError.assignmentExpected
        }
        guard let expression = try self.expression() else {
            throw SyntaxError.expressionExpected
        }
        let drainsName: Token?
        let fillsName: Token?
        
        if accept(keyword: "from") {
            guard let name = identifier() else {
                throw SyntaxError.identifierExpected
            }
            drainsName = name
        }
        else {
            drainsName = nil
        }
        
        if accept(keyword: "to") {
            guard let name = identifier() else {
                throw SyntaxError.identifierExpected
            }
            fillsName = name
        }
        else {
            fillsName = nil
        }
        
        // FIXME: Assign tokens
        return ModelAST(.flow(name.text, expression,
                              drainsName?.text, fillsName?.text),
                        tokens: [])
    }
    func output() throws -> ModelAST? {
        var items: [Token] = []
        
        guard let item = identifier() else {
            throw SyntaxError.identifierExpected
        }

        items.append(item)
        
        while accept(.comma) != nil {
            guard let item = identifier() else {
                throw SyntaxError.identifierExpected
            }
            items.append(item)
        }

        // FIXME: Assign tokens
        return ModelAST(.output(items.map { $0.text }),
                        tokens: [])
    }

    public func statement() throws -> ModelAST? {
        if accept(keyword: "stock") {
            return try stock()
        }
        else if accept(keyword: "flow") {
            return try flow()
        }
        else if accept(keyword: "var") {
            return try variable()
        }
        else if accept(keyword: "output") {
            return try output()
        }
        else {
            return nil
        }
    }
    
    public func statements() throws -> [ModelAST]? {
        var list: [ModelAST] = []
        
        while let item = try statement() {
            list.append(item)
        }

        guard !list.isEmpty else {
            return nil
        }
        
        return list
    }
    
    public func parseModel() throws -> [ModelAST] {
        let statements: [ModelAST]
        do {
            statements = try self.statements() ?? []
        }
        catch let error as SyntaxError {
            guard let token = currentToken else {
                fatalError("No current token")
            }
            throw ParseError.syntaxError(error, token)
        }

        guard let lastToken = currentToken else {
            fatalError("No current token")
        }

        if lastToken.type != .empty {
            throw ParseError.syntaxError(.unexpectedToken, lastToken)
        }

        return statements
    }
    
}
