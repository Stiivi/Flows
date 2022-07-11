//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/06/2022.
//

import Foundation

public struct FunctionError {
    public let function: String
    public let message: String
    public let argument: Int?
    
    public init(function: String, message: String, argument: Int?=nil) {
        self.function = function
        self.message = message
        self.argument = argument
    }
}


public protocol FunctionProtocol {
    var name: String { get }
    /// Validate arguments that are expected to be passed to the function.
    /// Returns a list of errors if there are issues with the arguments.
    /// The list is empty if there are no issues.
    ///
    func validate(_ arguments: [Value]) -> [FunctionError]
    
    /// Applies the function to the arguments and returns the result. This
    /// function is guaranteed not to fail.
    ///
    /// - Note: Invalid arguments result in fatal error.
    ///
    func apply(_ arguments: [Value]) -> Value
}

typealias FunctionImplementation = ([Value]) -> Value

class NumericBinaryOperator: FunctionProtocol {
    
    typealias Implementation = (Double, Double) -> Double
    
    let name: String
    let implementation: Implementation
    
    init(name: String, implementation: @escaping Implementation) {
        self.name = name
        self.implementation = implementation
    }
    
    /// Returns a list of indices of arguments that have mismatched types
    public func validate(_ arguments: [Value]) -> [FunctionError] {
        var errors: [FunctionError] = []
        
        if arguments.count != 2 {
            errors.append(
                FunctionError(function: name,
                              message: "Invalid number of arguments (\(arguments.count) for binary operator. Expected exactly 2.")
            )
        }
        
        for (i, arg) in arguments.enumerated() {
            if !arg.valueType.isNumeric {
                errors.append(
                    FunctionError(function: name,
                                  message: "Invalid argument type. Argument number \(i) is \(arg.valueType) expected is float or int")
                )
            }
        }
        
        return errors
    }
    
    /// Applies the function to the arguments and returns result.
    ///
    /// - Precondition: Arguments must be float convertible.
    ///
    public func apply(_ arguments: [Value] ) -> Value {
        guard arguments.count == 2 else {
            fatalError("Invalid number of arguments (\(arguments.count) to a binary operator.")
        }

        let lhs = arguments[0].doubleValue()!
        let rhs = arguments[1].doubleValue()!

        let result = implementation(lhs, rhs)
        
        return .double(result)
    }
}

class NumericUnaryOperator: FunctionProtocol {
    typealias Implementation = (Double) -> Double
    
    let name: String
    let implementation: Implementation
    
    init(name: String, implementation: @escaping Implementation) {
        self.name = name
        self.implementation = implementation
    }
    
    /// Returns a list of indices of arguments that have mismatched types
    func validate(_ arguments: [Value]) -> [FunctionError] {
        var errors: [FunctionError] = []
        
        if arguments.count != 1 {
            errors.append(
                FunctionError(function: name,
                              message: "Invalid number of arguments (\(arguments.count) for unary operator. Expected exactly 1.")
            )
        }
        let arg = arguments[0]
        
        if !arg.valueType.isNumeric {
            errors.append(
                FunctionError(function: name,
                              message: "Invalid argument type. Argument is \(arg.valueType) expected is float or int")
            )
        }
        
        return errors
    }
    
    /// Applies the function to the arguments and returns result.
    ///
    /// - Precondition: Arguments must be float convertible.
    ///
    func apply(_ arguments: [Value] ) -> Value {
        guard arguments.count == 1 else {
            fatalError("Invalid number of arguments (\(arguments.count) to a binary operator.")
        }

        let operand = arguments[0].doubleValue()!

        let result = implementation(operand)
        
        return .double(result)
    }
}


public class NumericFunction: FunctionProtocol {
    public typealias Implementation = ([Double]) -> Double
    
    public let name: String
    let implementation: Implementation
    let signature: [String]
    let isVariadic: Bool
    
    public init(name: String, signature: [String]=[], isVariadic: Bool=false,
         implementation: @escaping Implementation) {
        self.name = name
        self.implementation = implementation
        self.signature = signature
        self.isVariadic = isVariadic
    }
    
    /// Returns a list of indices of arguments that have mismatched types
    public func validate(_ arguments: [Value]) -> [FunctionError] {
        var errors: [FunctionError] = []
        
        // FIXME: Use new flag "required" - whether at least one argument is required
        if isVariadic {
            if signature.count == 0 && arguments.count == 0 {
                errors.append(
                    FunctionError(function: name,
                                  message: "Variadic function expects at least one argument")
                )
            }
        }
        else {
            if arguments.count != signature.count {
                errors.append(
                    FunctionError(function: name,
                                  message: "Expected \(signature.count) arguments, provided (\(arguments.count).")
                )
            }
        }
        
        for (i, arg) in arguments.enumerated() {
            if !arg.valueType.isNumeric {
                errors.append(
                    FunctionError(function: name,
                                  message: "Invalid argument type. Argument number \(i) is \(arg.valueType) expected is float or int")
                )
            }
        }
        
        return errors
    }

    /// Applies the function to the arguments and returns result.
    ///
    /// - Precondition: Arguments must be float convertible.
    ///
    public func apply(_ arguments: [Value]) -> Value {
        let floatArguments = arguments.map { $0.doubleValue()! }

        let result = implementation(floatArguments)
        
        return .double(result)
    }
}

// Mark: Builtins

let builtinUnaryOperators = [
    NumericUnaryOperator(name: "-") { -$0 }
]

let builtinBinaryOperators = [
    NumericBinaryOperator(name: "+") { $0 + $1 },
    NumericBinaryOperator(name: "-") { $0 - $1 },
    NumericBinaryOperator(name: "*") { $0 * $1 },
    NumericBinaryOperator(name: "/") { $0 / $1 },
    NumericBinaryOperator(name: "%") { $0.truncatingRemainder(dividingBy: $1) },
]

let builtinFunctions: [NumericFunction] = [
    NumericFunction(name: "abs", signature: ["value"]) { args
        in args[0].magnitude
    },
    NumericFunction(name: "floor", signature: ["value"]) { args
        in args[0].rounded(.down)
    },
    NumericFunction(name: "ceiling", signature: ["value"]) { args
        in args[0].rounded(.up)
    },
    NumericFunction(name: "round", signature: ["value"]) { args
        in args[0].rounded()
    },

    // Variadic
    
    NumericFunction(name: "sum", isVariadic: true) { args
        in args.reduce(0, { x, y in x + y })
    },
    NumericFunction(name: "min", isVariadic: true) { args
        in args.min()!
    },
    NumericFunction(name: "max", isVariadic: true) { args
        in args.max()!
    },
]

let allBuiltinFunctions: [FunctionProtocol] = builtinUnaryOperators + builtinBinaryOperators + builtinFunctions
