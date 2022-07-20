//
//  ModelParserTests.swift
//  
//
//  Created by Stefan Urbanek on 14/07/2022.
//

import XCTest
@testable import Flows


final class ModelParserTests: XCTestCase {
    func testEmpty() throws {
        let parser = ModelParser(string: "")
        let ast = try parser.parseModel()
        XCTAssertTrue(ast.statements.isEmpty)
    }
    
    func testEmptyComment() throws {
        // TODO: Move this to lexer tests
        let parser = ModelParser(string: "# This is a comment\n")
        let ast = try parser.parseModel()
        XCTAssertTrue(ast.statements.isEmpty)
    }
    
    func testExpressionWithComment() throws {
        // TODO: Move this to lexer tests
        let parser = ModelParser(string: """
                                         # A comment
                                         stock x = 10  # Trailing comment
                                         """)
        let ast = try parser.parseModel()
        XCTAssertEqual(ast.statements.count, 1)
        
        guard let stmt = ast.statements.first else {
            XCTFail()
            return
        }
        
        if case let .stock(token, _) = stmt {
            XCTAssertEqual(token.text, "x")
        }
    }
    func testExpressionWithMultipleComment() throws {
        // TODO: Move this to lexer tests
        // Having some weird parser behaviour
        let parser = ModelParser(string: """
                                         # A comment
                                         # Another comment line
                                         
                                         stock x = 10
                                         """)
        let ast = try parser.parseModel()
        XCTAssertEqual(ast.statements.count, 1)
        
        guard let stmt = ast.statements.first else {
            XCTFail()
            return
        }
        
        if case let .stock(token, _) = stmt {
            XCTAssertEqual(token.text, "x")
        }
    }
    func testStock() throws {
        let parser = ModelParser(string: "stock x = 10")
        let ast = try parser.parseModel()
        XCTAssertEqual(ast.statements.count, 1)
        
        guard let stmt = ast.statements.first else {
            XCTFail()
            return
        }
        
        if case let .stock(token, _) = stmt {
            XCTAssertEqual(token.text, "x")
        }
    }

    func testVar() throws {
        let parser = ModelParser(string: "var x = 10")
        let ast = try parser.parseModel()
        XCTAssertEqual(ast.statements.count, 1)
        
        guard let stmt = ast.statements.first else {
            XCTFail()
            return
        }
        
        if case let .variable(token, _) = stmt {
            XCTAssertEqual(token.text, "x")
        }
    }
    func testOutput() throws {
        let parser = ModelParser(string: "output a, b, c")
        let ast = try parser.parseModel()
        XCTAssertEqual(ast.statements.count, 1)
        
        guard let stmt = ast.statements.first else {
            XCTFail()
            return
        }
        
        if case let .output(tokens) = stmt {
            XCTAssertEqual(tokens.count, 3)
            XCTAssertEqual(tokens.map { $0.text }, ["a", "b", "c"])
        }
    }
    func testFlow() throws {
        let parser = ModelParser(string: "flow f = 10 from drains to fills")
        let ast = try parser.parseModel()
        XCTAssertEqual(ast.statements.count, 1)
        
        guard let stmt = ast.statements.first else {
            XCTFail()
            return
        }
        
        if case let .flow(token, _, drains, fills) = stmt {
            XCTAssertEqual(token.text, "f")
            XCTAssertEqual(drains?.text, "drains")
            XCTAssertEqual(fills?.text, "fills")
        }
    }
    
    func testCaseInsensitiveKeywords() throws {
        let parser = ModelParser(string: "FLOW f = 10 FROM drains TO fills")
        let ast = try parser.parseModel()
        XCTAssertEqual(ast.statements.count, 1)
        
        guard let stmt = ast.statements.first else {
            XCTFail()
            return
        }
        
        if case let .flow(token, _, drains, fills) = stmt {
            XCTAssertEqual(token.text, "f")
            XCTAssertEqual(drains?.text, "drains")
            XCTAssertEqual(fills?.text, "fills")
        }
        
    }

}
