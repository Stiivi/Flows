//
//  SyntaxError.swift
//  
//
//  Created by Stefan Urbanek on 13/07/2022.
//


/// Error thrown by the expression or model language parser.
///
public enum SyntaxError: Error, Equatable, CustomStringConvertible {
    // Expression errors
    case invalidCharacterInNumber
    case unexpectedCharacter
    case missingRightParenthesis
    case expressionExpected
    case unexpectedToken

    // Model errors
    case identifierExpected
    case assignmentExpected
    case statementExpected

    public var description: String {
        switch self {
        // Expression errors
        case .invalidCharacterInNumber: return "Invalid character in a number"
        case .unexpectedCharacter: return "Unexpected character"
        case .missingRightParenthesis: return "Right parenthesis ')' expected"
        case .expressionExpected: return "Expected expression"
        case .unexpectedToken: return "Unexpected token"

        // Model errors
        case .identifierExpected: return "Expected identifier"
        case .assignmentExpected: return "Expected assignment '=' and expression"
        case .statementExpected: return "Model statement expected"
        }
    }
}
