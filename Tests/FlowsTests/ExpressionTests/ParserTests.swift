//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 28/05/2022.
//

import XCTest
@testable import Flows

final class LexerTests: XCTestCase {
    func testAcceptFunction() throws {
        let lexer = Lexer(string: " ")
        XCTAssertNotNil(lexer.currentChar)
        XCTAssertTrue(lexer.accept(\.isWhitespace))
        XCTAssertNil(lexer.currentChar)
        XCTAssertTrue(lexer.atEnd)
        XCTAssertEqual(lexer.text, " ")
    }
    
    func testEmpty() throws {
        let lexer = Lexer(string: "")
        
        XCTAssertTrue(lexer.atEnd)
        XCTAssertEqual(lexer.next().type, TokenType.empty)
        lexer.advance()
        XCTAssertTrue(lexer.atEnd)
        XCTAssertEqual(lexer.next().type, TokenType.empty)
    }

    func testSpace() throws {
        let lexer = Lexer(string: " ")
        
        XCTAssertFalse(lexer.atEnd)
        XCTAssertEqual(lexer.next().type, TokenType.empty)
        XCTAssertTrue(lexer.atEnd)
    }
    func testUnexpected() throws {
        let lexer = Lexer(string: "$")
        let token = lexer.next()

        XCTAssertEqual(token.type, TokenType.error(.unexpectedCharacter))
        XCTAssertEqual(token.text, "$")
    }

    func testInteger() throws {
        let lexer = Lexer(string: "1234")
        let token = lexer.next()
        XCTAssertEqual(token.type, TokenType.int)
        XCTAssertEqual(token.text, "1234")
    }

    func testThousandsSeparator() throws {
        let lexer = Lexer(string: "123_456_789")
        let token = lexer.next()
        XCTAssertEqual(token.type, TokenType.int)
        XCTAssertEqual(token.text, "123_456_789")
    }

    func testMultipleInts() throws {
        let lexer = Lexer(string: "1 22 333 ")
        var token = lexer.next()
        XCTAssertEqual(token.type, TokenType.int)
        XCTAssertEqual(token.text, "1")

        token = lexer.next()
        XCTAssertEqual(token.type, TokenType.int)
        XCTAssertEqual(token.text, "22")

        token = lexer.next()
        XCTAssertEqual(token.type, TokenType.int)
        XCTAssertEqual(token.text, "333")
    }

    func testInvalidInteger() throws {
        let lexer = Lexer(string: "1234x")
        let token = lexer.next()
        XCTAssertEqual(token.type, TokenType.error(.invalidCharacterInNumber))
        XCTAssertEqual(token.text, "1234x")
    }

    func testFloat() throws {
        let lexer = Lexer(string: "10.20 10e20 10.20e30 10.20e-30")
        var token = lexer.next()
        XCTAssertEqual(token.type, TokenType.float)
        XCTAssertEqual(token.text, "10.20")

        token = lexer.next()
        XCTAssertEqual(token.type, TokenType.float)
        XCTAssertEqual(token.text, "10e20")
        
        token = lexer.next()
        XCTAssertEqual(token.type, TokenType.float)
        XCTAssertEqual(token.text, "10.20e30")

        token = lexer.next()
        XCTAssertEqual(token.type, TokenType.float)
        XCTAssertEqual(token.text, "10.20e-30")
    }


    func testOperator() throws {
        let lexer = Lexer(string: "+ - * / %")

        var token = lexer.next()
        XCTAssertEqual(token.type, TokenType.operator)
        XCTAssertEqual(token.text, "+")

        token = lexer.next()
        XCTAssertEqual(token.type, TokenType.operator)
        XCTAssertEqual(token.text, "-")

        token = lexer.next()
        XCTAssertEqual(token.type, TokenType.operator)
        XCTAssertEqual(token.text, "*")

        token = lexer.next()
        XCTAssertEqual(token.type, TokenType.operator)
        XCTAssertEqual(token.text, "/")

        token = lexer.next()
        XCTAssertEqual(token.type, TokenType.operator)
        XCTAssertEqual(token.text, "%")
    }

    func testIdentifier() throws {
        let lexer = Lexer(string: "an_identifier_1")
        let token = lexer.next()
        XCTAssertEqual(token.type, TokenType.identifier)
        XCTAssertEqual(token.text, "an_identifier_1")
    }

    func testPunctuation() throws {
        let lexer = Lexer(string: "( , )")

        var token = lexer.next()
        XCTAssertEqual(token.type, TokenType.leftParen)
        XCTAssertEqual(token.text, "(")

        token = lexer.next()
        XCTAssertEqual(token.type, TokenType.comma)
        XCTAssertEqual(token.text, ",")

        token = lexer.next()
        XCTAssertEqual(token.type, TokenType.rightParen)
        XCTAssertEqual(token.text, ")")
    }

    func testMinusAsOperator() throws {
        let lexer = Lexer(string: "1-2")
        var token = lexer.next()
        XCTAssertEqual(token.type, TokenType.int)
        XCTAssertEqual(token.text, "1")

        token = lexer.next()
        XCTAssertEqual(token.type, TokenType.operator)
        XCTAssertEqual(token.text, "-")

        token = lexer.next()
        XCTAssertEqual(token.type, TokenType.int)
        XCTAssertEqual(token.text, "2")
    }

}


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
