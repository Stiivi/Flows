//
//  NumericExpressionEvaluator.swift
//  
//
//  Created by Stefan Urbanek on 28/05/2022.
//

import Foundation

enum SimpleExpressionError: Error {
    case unknownVariable(String)
    case unknownFunction(String)
}


/// Object that evaluates numeric expressions.
///
/// The object is associated with list of numeric functions and variables that
/// will be used during each expression evaluation.
///
class NumericExpressionEvaluator {
    var functions: [String:FunctionProtocol]
    var variables: [String:Value]
    
    init(variables: [String:Value]=[:], functions: [String:FunctionProtocol]=[:]) {
        self.variables = variables
        self.functions = functions
    }
    
    /// Evaluates an expression using object's functions and variables. Returns
    /// the evaluation result.
    ///
    /// - Throws: The function throws an error when it encounters a variable
    ///   or a function with unknown name
    func evaluate(_ expression: Expression) throws -> Value? {
        switch expression {
        case let .value(value): return value
        case let .binary(op, lhs, rhs):
            return try apply(op, arguments: [try evaluate(lhs), try evaluate(rhs)])
        case let .unary(op, operand):
            return try apply(op, arguments: [try evaluate(operand)])
        case let .function(name, arguments):
            let evaluatedArgs = try arguments.map { try evaluate($0) }
            return try apply(name, arguments: evaluatedArgs)
        case let .variable(name):
            if let value = variables[name] {
                return value
            }
            else {
                throw SimpleExpressionError.unknownVariable(name)
            }
        case .null: return nil
        }
    }
    
    /// Applies the function to the arguments and returns the result.
    ///
    /// - Throws: If the function with given name does not exist, it throws
    ///   an error.
    ///
    func apply(_ functionName: String, arguments: [Value?]) throws -> Value {
        guard let function = functions[functionName] else {
            throw SimpleExpressionError.unknownFunction(functionName)
        }
        // FIXME: Handle optionals, the following is workaround
        let args: [Value] = arguments.map { $0! }
        return function.apply(args)
    }
}
