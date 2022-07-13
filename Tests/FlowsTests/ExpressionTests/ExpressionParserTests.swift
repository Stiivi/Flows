//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 28/05/2022.
//

import XCTest
@testable import Flows


final class ExpressionParserTests: XCTestCase {
    func testEmpty() {
        let parser = ExpressionParser(string: "")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.expressionExpected)
        }
    }

    func testBinary() {
        let expr = Expression.binary(
            "+",
            .variable("a"),
            .value(.int(1))
        )
        XCTAssertEqual(try ExpressionParser(string: "a + 1").parse(), expr)
        XCTAssertEqual(try ExpressionParser(string: "a+1").parse(), expr)
    }
    
    func testPrecedence() {
        let expr = Expression.binary(
            "+",
            .variable("a"),
            .binary(
                "*",
                .variable("b"),
                .variable("c")
            )
        )
        XCTAssertEqual(try ExpressionParser(string: "a + b * c").parse(), expr)
        XCTAssertEqual(try ExpressionParser(string: "a + (b * c)").parse(), expr)

        let expr2 = Expression.binary(
            "+",
            .binary(
                "*",
                .variable("a"),
                .variable("b")
            ),
            .variable("c")
        )
        XCTAssertEqual(try ExpressionParser(string: "a * b + c").parse(), expr2)
        XCTAssertEqual(try ExpressionParser(string: "(a * b) + c").parse(), expr2)
    }
    
    func testUnary() {
        let expr = Expression.unary("-", .variable("x"))
        XCTAssertEqual(try ExpressionParser(string: "-x").parse(), expr)

        let expr2 = Expression.binary(
            "-",
            .variable("x"),
            .unary(
                "-",
                .variable("y")
            )
        )
        XCTAssertEqual(try ExpressionParser(string: "x - -y").parse(), expr2)
    }
    func testFunction() {
        let expr = Expression.function("fun", [.variable("x")])
        XCTAssertEqual(try ExpressionParser(string: "fun(x)").parse(), expr)

        let expr2 = Expression.function("fun", [.variable("x"), .variable("y")])
        XCTAssertEqual(try ExpressionParser(string: "fun(x,y)").parse(), expr2)

    }
    
    func testErrorMissingParenthesis() throws {
        let parser = ExpressionParser(string: "(")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.expressionExpected)
        }
    }
    func testErrorMissingParenthesisFunctionCall() throws {
        let parser = ExpressionParser(string: "func(1,2,3")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.missingRightParenthesis)
        }
    }
    
    func testUnaryExpressionExpected() throws {
        let parser = ExpressionParser(string: "1 + -")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.expressionExpected)
        }

        let parser2 = ExpressionParser(string: "-")
        XCTAssertThrowsError(try parser2.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.expressionExpected)
        }
    }
    
    func testFactorUnaryExpressionExpected() throws {
        let parser = ExpressionParser(string: "1 *")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.expressionExpected)
        }
    }
    
    func testTermExpressionExpected() throws {
        let parser = ExpressionParser(string: "1 +")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.expressionExpected)
        }
    }

    func testUnexpectedToken() throws {
        let parser = ExpressionParser(string: "1 1")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.unexpectedToken)
        }
    }
}
