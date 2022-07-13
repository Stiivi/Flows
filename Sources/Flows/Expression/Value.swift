//
//  Value.swift
//  
//
//  Created by Stefan Urbanek on 2020/12/14.
//

// Note: This is from project Tarot. Still evolving. Keep concepts in sync if possible.

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
    /// Boolean value type
    case bool
    /// Integer value type
    case int
    /// Double precision floating point value type
    case double
    /// String value type
    case string
    
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
        case (.bool,   .double): return false

        // Int to all except bool
        case (.int,    .string): return true
        case (.int,    .bool):   return false
        case (.int,    .int):    return true
        case (.int,    .double): return true

        // Float to all except bool
        case (.double, .string): return true
        case (.double, .bool):   return false
        case (.double, .int):    return true
        case (.double, .double): return true

        // String to all
        case (.string, .string): return true
        case (.string, .bool):   return true
        case (.string, .int):    return true
        case (.string, .double): return true
        }
    }
   
    /// True if the type is either `int` or `float`
    public var isNumeric: Bool {
        switch self {
        case .double: return true
        case .int: return true
        default: return false
        }
    }
    
    public var description: String {
        switch self {
        case .bool: return "bool"
        case .int: return "int"
        case .double: return "double"
        case .string: return "string"
        }
    }
}

/// Multy-type scalar value representation. The type can represent one of the
/// following values:
///
/// - `bool` – a boolean value
/// - `int` – an integer value
/// - `double` – a double precision floating point number
/// - `string` – a string representing a valid identifier
///
public enum Value: Equatable, Hashable, Codable, ValueProtocol {
    /// A string value representation
    case string(String)
    
    /// A boolean value representation
    case bool(Bool)
    
    /// An integer value representation
    case int(Int)
    
    /// A double precision floating point number value representation
    case double(Double)
    
    // TODO: case point2d(Double, Double)
    // TODO: case point3d(Double, Double, Double)
    // TODO: case date(Date)

    
    /// Initialise value from any object and match type according to the
    /// argument type. If no type can be matched, then returns nil.
    ///
    /// Matches to built-in types:
    ///
    /// - string: String
    /// - bool: Bool
    /// - int: Int
    /// - double: Double
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
        else if let value = value as? Double {
            self = .double(value)
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
        case .double: return .double
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
        case .double(_): return nil
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
        case .double(let value): return Int(value)
        }
    }

    /// Get a floating point value. All types can be attempted to be converted
    /// to a floating point value except boolean.
    ///
    public func doubleValue() -> Double? {
        switch self {
        case .string(let value): return Double(value)
        case .bool(_): return nil
        case .int(let value): return Double(value)
        case .double(let value): return value
        }
    }
    
    /// Get a string value. Any type can be converted to a string.
    /// 
    public func stringValue() -> String {
        switch self {
        case .string(let value): return String(value)
        case .bool(let value): return String(value)
        case .int(let value): return String(value)
        case .double(let value): return String(value)
        }
    }

    /// Get a type erased value.
    ///
    public func anyValue() -> Any {
        switch self {
        case .string(let value): return String(value)
        case .bool(let value): return Bool(value)
        case .int(let value): return Int(value)
        case .double(let value): return Float(value)
        }
    }

    /// `true` if the value is considered empty empty.
    ///
    /// The respective types and their values that are considered to be empty:
    ///
    /// - `string` value is considered empty if the length of
    ///    a string is zero
    /// - `int` and `double` numeric value is considered empty if the value is
    ///    equal to zero
    /// - `bool` value is never considered empty.
    ///
    public var isEmpty: Bool {
        return stringValue() == "" || intValue() == 0 || doubleValue() == 0.0
    }
    
    /// Converts value to a value of another type, if possible. Caller is
    /// advised to call ``ValueType.isConvertible()`` to prevent potential
    /// convention errors.
    ///
    public func convert(to otherType:ValueType) -> Value? {
        switch (otherType) {
        case .int: return self.intValue().map { .int($0) } ?? nil
        case .string: return .string(self.stringValue())
        case .bool: return self.boolValue().map { .bool($0) } ?? nil
        case .double: return self.doubleValue().map { .double($0) } ?? nil
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
        case let (.double(lhs), .double(rhs)): return lhs < rhs
        case let (.string(lhs), .string(rhs)): return lhs < rhs
        default: return false
        }
    }
    
    /// Returns itself. Conformance to the `ValueProtocol`.
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
        self = .double(Double(floatLiteral))
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
        return .double(Double(self))
    }
}

extension Double: ValueProtocol {
    public func asValue() -> Value {
        return .double(self)
    }
}
