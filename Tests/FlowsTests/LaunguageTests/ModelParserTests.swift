//
//  ModelParserTests.swift
//  
//
//  Created by Stefan Urbanek on 14/07/2022.
//

import XCTest
@testable import Flows

// TODO: Test stock options

final class ModelParserTests: XCTestCase {
    func testEmpty() throws {
        let parser = ModelParser(string: "")
        let statements = try parser.parseModel()
        XCTAssertTrue(statements.isEmpty)
    }
    
    func testEmptyComment() throws {
        // TODO: Move this to lexer tests
        let parser = ModelParser(string: "# This is a comment\n")
        let statements = try parser.parseModel()
        XCTAssertTrue(statements.isEmpty)
    }
    
    func testExpressionWithComment() throws {
        // TODO: Move this to lexer tests
        let parser = ModelParser(string: """
                                         # A comment
                                         stock x = 10  # Trailing comment
                                         """)
        let statements = try parser.parseModel()
        XCTAssertEqual(statements.count, 1)
        
        guard let stmt = statements.first else {
            XCTFail()
            return
        }
        
        if case let .stock(token, _, _) = stmt.kind {
            XCTAssertEqual(token, "x")
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
        let statements = try parser.parseModel()
        XCTAssertEqual(statements.count, 1)
        
        guard let stmt = statements.first else {
            XCTFail()
            return
        }
        
        if case let .stock(token, _, _) = stmt.kind {
            XCTAssertEqual(token, "x")
        }
    }
    func testStock() throws {
        let parser = ModelParser(string: "stock x = 10")
        let statements = try parser.parseModel()
        XCTAssertEqual(statements.count, 1)
        
        guard let stmt = statements.first else {
            XCTFail()
            return
        }
        
        if case let .stock(token, _, _) = stmt.kind {
            XCTAssertEqual(token, "x")
        }
    }

    func testVar() throws {
        let parser = ModelParser(string: "var x = 10")
        let statements = try parser.parseModel()
        XCTAssertEqual(statements.count, 1)
        
        guard let stmt = statements.first else {
            XCTFail()
            return
        }
        
        if case let .variable(token, _) = stmt.kind {
            XCTAssertEqual(token, "x")
        }
    }
    func testOutput() throws {
        let parser = ModelParser(string: "output a, b, c")
        let statements = try parser.parseModel()
        XCTAssertEqual(statements.count, 1)
        
        guard let stmt = statements.first else {
            XCTFail()
            return
        }
        
        if case let .output(tokens) = stmt.kind {
            XCTAssertEqual(tokens.count, 3)
            XCTAssertEqual(tokens, ["a", "b", "c"])
        }
    }
    func testFlow() throws {
        let parser = ModelParser(string: "flow f = 10 from drains to fills")
        let statements = try parser.parseModel()
        XCTAssertEqual(statements.count, 1)
        
        guard let stmt = statements.first else {
            XCTFail()
            return
        }
        
        if case let .flow(token, _, drains, fills) = stmt.kind {
            XCTAssertEqual(token, "f")
            XCTAssertEqual(drains, "drains")
            XCTAssertEqual(fills, "fills")
        }
    }
    
    func testCaseInsensitiveKeywords() throws {
        let parser = ModelParser(string: "FLOW f = 10 FROM drains TO fills")
        let statements = try parser.parseModel()
        XCTAssertEqual(statements.count, 1)
        
        guard let stmt = statements.first else {
            XCTFail()
            return
        }
        
        if case let .flow(token, _, drains, fills) = stmt.kind {
            XCTAssertEqual(token, "f")
            XCTAssertEqual(drains, "drains")
            XCTAssertEqual(fills, "fills")
        }
        
    }

}
