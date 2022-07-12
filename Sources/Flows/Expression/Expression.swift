//
//  Expression.swift
//  
//
//  Created by Stefan Urbanek on 26/05/2022.
//

import Foundation


public protocol ExpressionConvertible {
    var toExpression: Expression { get }
}


/// Arithmetic expression.
///
/// Represents components of an arithmetic expression: values, variables,
/// operators and functions.
///
public indirect enum Expression: Hashable {
    // Literals
    /// `NULL` literal
    case null

    /// Integer number literal
    case value(Value)

    /// Binary operator
    case binary(String, Expression, Expression)
    
    /// Unary operator
    case unary(String, Expression)

    /// Function with multiple expressions as arguments
    case function(String, [Expression])

    /// Variable reference
    case variable(String)

    /// List of children from which the expression is composed. Does not go
    /// to underlying table expressions.
    public var children: [Expression] {
        switch self {
        case let .binary(_, lhs, rhs): return [lhs, rhs]
        case let .unary(_, expr): return [expr]
        case let .function(_, exprs): return exprs
        default: return []
        }
    }

    // Hashable protocol
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .null: hasher.combine(0)
        case let .value(value): hasher.combine(value)
        case let .variable(value): hasher.combine(value)
        case let .binary(op, lhs, rhs):
            hasher.combine(op)
            hasher.combine(lhs)
            hasher.combine(rhs)
        case let .unary(op, operand):
            hasher.combine(op)
            hasher.combine(operand)
        case let .function(f, arguments):
            hasher.combine(f)
            hasher.combine(arguments)
        }
    }

    /// List of all variables that the expression and its children reference
    public var referencedVariables: [String] {
        switch self {
        case .null: return []
        case .value(_): return []
        case let .variable(name):
            return [name]
        case let .binary(_, lhs, rhs):
            return lhs.referencedVariables + rhs.referencedVariables
        case let .unary(_, expr):
            return expr.referencedVariables
        case let .function(_, arguments):
            return arguments.flatMap { $0.referencedVariables }
        }
    }
    
}

public func ==(left: Expression, right: Expression) -> Bool {
    switch (left, right) {
    case (.null, .null): return true
    case let(.value(lval), .value(rval)) where lval == rval: return true
    case let(.binary(lop, lv1, lv2), .binary(rop, rv1, rv2))
                where lop == rop && lv1 == rv1 && lv2 == rv2: return true
    case let(.unary(lop, lv), .unary(rop, rv))
                where lop == rop && lv == rv: return true
    case let(.variable(lval), .variable(rval)) where lval == rval: return true
    case let(.function(lname, largs), .function(rname, rargs))
                where lname == rname && largs == rargs: return true
    default:
        return false
    }
}

extension Expression: ExpressibleByStringLiteral {
    public init(stringLiteral value: String.StringLiteralType) {
        self = .value(.string(value))
    }
    public init(extendedGraphemeClusterLiteral value:
            String.ExtendedGraphemeClusterLiteralType){
        self = .value(.string(value))
    }
    public init(unicodeScalarLiteral value: String.UnicodeScalarLiteralType) {
        self = .value(.string(value))
    }
}


extension String: ExpressionConvertible {
    public var toExpression: Expression { return .value(.string(self)) }
}

extension Expression: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int.IntegerLiteralType) {
        self = .value(.int(value))
    }
}

extension Int: ExpressionConvertible {
    public var toExpression: Expression { return .value(.int(self)) }
}

extension Expression: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool.BooleanLiteralType){
        self = .value(.bool(value))
    }
}

extension Bool: ExpressionConvertible {
    public var toExpression: Expression { return .value(.bool(self)) }
}

extension Expression: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}
