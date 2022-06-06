//
//  Value.swift
//  
//
//  Created by Stefan Urbanek on 2020/12/14.
//

// Note: This is from project Tarot. Still evolving. Keep concepts in sync if possible.

import Foundation

// TODO: Use ValueProtocol and then Something.asValue

/// Protocol for objects that can be represented as ``Value``.
///
public protocol ValueProtocol {
    /// Representation of the receiver as a ``Value``
    /// 
    func asValue() -> Value
}

/// ValueType specifies a data type of a value that is used in interfaces.
///
public enum ValueType: String, Equatable, Codable, CustomStringConvertible {
    case bool
    case int
    case float
    case string
    // TODO: case date
    // TODO: case double
    
    /// Returns `true` if the value of this type is convertible to
    /// another type using `xxxValue()` conversion.
    /// Conversion might not be precise, just possible.
    ///
    public func isConvertible(to other: ValueType) -> Bool{
        switch (self, other) {
        // Bool to string, not to int or float
        case (.bool,   .string): return true
        case (.bool,   .bool):   return true
        case (.bool,   .int):    return false
        case (.bool,   .float): return false

        // Int to all except bool
        case (.int,    .string): return true
        case (.int,    .bool):   return false
        case (.int,    .int):    return true
        case (.int,    .float): return true

        // Float to all except bool
        case (.float, .string): return true
        case (.float, .bool):   return false
        case (.float, .int):    return true
        case (.float, .float): return true

        // String to all
        case (.string, .string): return true
        case (.string, .bool):   return true
        case (.string, .int):    return true
        case (.string, .float): return true
        }
    }
   
    /// True if the type is either `int` or `float`
    public var isNumeric: Bool {
        switch self {
        case .float: return true
        case .int: return true
        default: return false
        }
    }
    
    public var description: String {
        switch self {
        case .bool: return "bool"
        case .int: return "int"
        case .float: return "float"
        case .string: return "string"
        }
    }
}

/// Multy-type scalar value representation. The type can represent one of the
/// following values:
///
/// - `bool` – a boolean value
/// - `int` – an integer value
/// - `float` – a floating point number
/// - `string` – a string representing a valid identifier
///
public enum Value: Equatable, Hashable, Codable, ValueProtocol {
    /// A string value representation
    case string(String)
    
    /// A boolean value representation
    case bool(Bool)
    
    /// An integer value representation
    case int(Int)
    
    /// A floating point number value representation
    case float(Float)
    
    /// Initialise value from any object and match type according to the
    /// argument type. If no type can be matched, then returns nil.
    ///
    /// Matches to types:
    ///
    /// - string: String
    /// - bool: Bool
    /// - int: Int
    /// - float: Float
    ///
    public init?(any value: Any) {
        if let value = value as? Int {
            self = .int(value)
        }
        else if let value = value as? String {
            self = .string(value)
        }
        else if let value = value as? Bool {
            self = .bool(value)
        }
        else if let value = value as? Float {
            self = .float(value)
        }
        else {
            return nil
        }
    }
    
    
    public var valueType: ValueType {
        switch self {
        case .string: return .string
        case .bool: return .bool
        case .int: return .int
        case .float: return .float
        }
    }
    
    // Note: When changing the following conversion methods,
    // check ValueType.isConvertible method for maintaining consistency
    //
    
    /// Get a boolean value. String is converted to boolean when it contains
    /// values `true` or `false`. Int and float can not be converted to
    /// booleans.
    ///
    public func boolValue() -> Bool? {
        switch self {
        case .string(let value): return Bool(value)
        case .bool(let value): return value
        case .int(_): return nil
        case .float(_): return nil
        }
    }
    
    /// Get an integer value. All types can be attempted to be converted to an
    /// integer except boolean.
    ///
    public func intValue() -> Int? {
        switch self {
        case .string(let value): return Int(value)
        case .bool(_): return nil
        case .int(let value): return value
        case .float(let value): return Int(value)
        }
    }

    /// Get a float value. All types can be attempted to be converted to a
    /// float value except boolean.
    ///
    public func floatValue() -> Float? {
        switch self {
        case .string(let value): return Float(value)
        case .bool(_): return nil
        case .int(let value): return Float(value)
        case .float(let value): return value
        }
    }
    
    /// Get a string value. Any type can be converted to a string.
    /// 
    public func stringValue() -> String {
        switch self {
        case .string(let value): return String(value)
        case .bool(let value): return String(value)
        case .int(let value): return String(value)
        case .float(let value): return String(value)
        }
    }

    /// Get a type erased value.
    ///
    public func anyValue() -> Any {
        switch self {
        case .string(let value): return String(value)
        case .bool(let value): return Bool(value)
        case .int(let value): return Int(value)
        case .float(let value): return Float(value)
        }
    }

    /// `true` if the value is considered empty empty.
    /// String value is considered empty if the length of
    /// a string is zero, numeric value is considered empty if the value is
    /// equal to zero. Boolean value is not considered empty.

    public var isEmpty: Bool {
        return stringValue() == "" || intValue() == 0 || floatValue() == 0.0
    }
    
    /// Converts value to a value of another type, if possible. Caller is
    /// advised to call ``ValueType.isConvertible()`` to prevent potential
    /// convention errors.
    public func convert(to otherType:ValueType) -> Value? {
        switch (otherType) {
        case .int: return self.intValue().map { .int($0) } ?? nil
        case .string: return .string(self.stringValue())
        case .bool: return self.boolValue().map { .bool($0) } ?? nil
        case .float: return self.floatValue().map { .float($0) } ?? nil
        }
    }
    
    /// Compare a value to other value. Returns true if the other value is in
    /// increasing order compared to this value.
    ///
    /// Only values of the same type can be compared. If the types are different,
    /// then the result is undefined.
    ///
    public func isLessThan(other: Value) -> Bool {
        switch (self, other) {
        case let (.int(lhs), .int(rhs)): return lhs < rhs
        case let (.float(lhs), .float(rhs)): return lhs < rhs
        case let (.string(lhs), .string(rhs)): return lhs < rhs
        default: return false
        }
    }
    
    public func asValue() -> Value {
        return self
    }
}

extension Value: CustomStringConvertible {
    public var description: String {
        return stringValue()
    }
}

extension Value: ExpressibleByStringLiteral {
    public init(stringLiteral: String) {
        self = .string(stringLiteral)
    }
}

extension Value: ExpressibleByBooleanLiteral {
    public init(booleanLiteral: Bool) {
        self = .bool(booleanLiteral)
    }
    
}

extension Value: ExpressibleByIntegerLiteral {
    public init(integerLiteral: Int) {
        self = .int(integerLiteral)
    }
}

extension Value: ExpressibleByFloatLiteral {
    public init(floatLiteral: Float) {
        self = .float(Float(floatLiteral))
    }
}

extension String: ValueProtocol {
    public func asValue() -> Value {
        return .string(self)
    }
}

extension Int: ValueProtocol {
    public func asValue() -> Value {
        return .int(self)
    }
}

extension Bool: ValueProtocol {
    public func asValue() -> Value {
        return .bool(self)
    }
}

extension Float: ValueProtocol {
    public func asValue() -> Value {
        return .float(self)
    }
}
