//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 28/05/2022.
//

import XCTest
@testable import Flows


final class ParserTests: XCTestCase {
    func testEmpty() {
        let parser = Parser(string: "")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.emptyString)
        }
    }

    func testBinary() {
        let expr = Expression.binary(
            "+",
            .variable("a"),
            .value(.int(1))
        )
        XCTAssertEqual(try Parser(string: "a + 1").parse(), expr)
        XCTAssertEqual(try Parser(string: "a+1").parse(), expr)
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
        XCTAssertEqual(try Parser(string: "a + b * c").parse(), expr)
        XCTAssertEqual(try Parser(string: "a + (b * c)").parse(), expr)

        let expr2 = Expression.binary(
            "+",
            .binary(
                "*",
                .variable("a"),
                .variable("b")
            ),
            .variable("c")
        )
        XCTAssertEqual(try Parser(string: "a * b + c").parse(), expr2)
        XCTAssertEqual(try Parser(string: "(a * b) + c").parse(), expr2)
    }
    
    func testUnary() {
        let expr = Expression.unary("-", .variable("x"))
        XCTAssertEqual(try Parser(string: "-x").parse(), expr)

        let expr2 = Expression.binary(
            "-",
            .variable("x"),
            .unary(
                "-",
                .variable("y")
            )
        )
        XCTAssertEqual(try Parser(string: "x - -y").parse(), expr2)
    }
    func testFunction() {
        let expr = Expression.function("fun", [.variable("x")])
        XCTAssertEqual(try Parser(string: "fun(x)").parse(), expr)

        let expr2 = Expression.function("fun", [.variable("x"), .variable("y")])
        XCTAssertEqual(try Parser(string: "fun(x,y)").parse(), expr2)

    }
    
    func testErrorMissingParenthesis() throws {
        let parser = Parser(string: "(")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.missingRightParenthesis)
        }
    }
    func testErrorMissingParenthesisFunctionCall() throws {
        let parser = Parser(string: "func(1,2,3")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.missingRightParenthesis)
        }
    }
    
    func testUnaryExpressionExpected() throws {
        let parser = Parser(string: "1 + -")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.expressionExpected)
        }

        let parser2 = Parser(string: "-")
        XCTAssertThrowsError(try parser2.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.expressionExpected)
        }
    }
    
    func testFactorUnaryExpressionExpected() throws {
        let parser = Parser(string: "1 *")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.expressionExpected)
        }
    }
    
    func testTermExpressionExpected() throws {
        let parser = Parser(string: "1 +")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.expressionExpected)
        }
    }

    func testUnexpectedToken() throws {
        let parser = Parser(string: "1 1")
        XCTAssertThrowsError(try parser.parse()) {
            XCTAssertEqual($0 as! ParserError, ParserError.unexpectedToken)
        }
    }

}
