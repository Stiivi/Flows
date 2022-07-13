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


class ModelParser: ExpressionParser {
    
    public convenience init(string: String) {
        self.init(lexer: Lexer(string: string, mode: .model))
    }

    // ----------------------------------------------------------------
    

    func accept(keyword: String) -> Bool {
        guard let token = currentToken else {
            return false
        }
        if token.type == .keyword && token.text == keyword {
            advance()
            return true
        }
        else {
            return false
        }
    }

    func stock() throws -> ModelAST? {
        guard let name = identifier() else {
            throw ParserError.identifierExpected
        }
        guard accept(.assignment) != nil else {
            throw ParserError.assignmentExpected
        }
        guard let expression = try self.expression() else {
            throw ParserError.expressionExpected
        }
        return .stock(name, expression)
    }
    
    func variable() throws -> ModelAST? {
        guard let name = identifier() else {
            throw ParserError.identifierExpected
        }
        guard accept(.assignment) != nil else {
            throw ParserError.assignmentExpected
        }
        guard let expression = try self.expression() else {
            throw ParserError.expressionExpected
        }
        return .variable(name, expression)
    }

    func flow() throws -> ModelAST? {
        guard let name = identifier() else {
            throw ParserError.identifierExpected
        }
        guard accept(.assignment) != nil else {
            throw ParserError.assignmentExpected
        }
        guard let expression = try self.expression() else {
            throw ParserError.expressionExpected
        }
        let drainsName: Token?
        let fillsName: Token?
        
        if accept(keyword: "from") {
            guard let name = identifier() else {
                throw ParserError.identifierExpected
            }
            drainsName = name
        }
        else {
            drainsName = nil
        }
        
        if accept(keyword: "to") {
            guard let name = identifier() else {
                throw ParserError.identifierExpected
            }
            fillsName = name
        }
        else {
            fillsName = nil
        }
        
        return .flow(name, expression, drainsName, fillsName)
    }
    func output() throws -> ModelAST? {
        var items: [Token] = []
        
        guard let item = identifier() else {
            throw ParserError.identifierExpected
        }

        items.append(item)
        
        while accept(.comma) != nil {
            guard let item = identifier() else {
                throw ParserError.identifierExpected
            }
            items.append(item)
        }

        return .output(items)
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
    
    public func parseModel() throws -> ModelAST {
        let statements = try self.statements() ?? []

        if currentToken?.type != .empty {
            throw ParserError.unexpectedToken
        }

        return .model(statements)
    }
    
}
