//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 17/07/2022.
//
//  Ported from Tarot.

// TODO: This is a prototype

/// Type for object attribute key.
public typealias AttributeKey = String

/// Type for object attribute values.
//public typealias AttributeValue = Value
// FIXME: Use Value from Simulation Foundation
// For now we are using this only for generating user output
public typealias AttributeValue = CustomStringConvertible

/// Type for a dictionary of graph object attributes.
public typealias AttributeDictionary = [AttributeKey:AttributeValue]

/// A protocol for objects that provide their attributes by keys.
///
public protocol KeyedValues {
    /// List of attributes that the object provides.
    ///
    var attributeKeys: [AttributeKey] { get }
    
    /// Returns a dictionary of attributes.
    ///
    func dictionary(withKeys: [AttributeKey]) -> AttributeDictionary

    /// Returns an attribute value for given key.
    ///
    func attribute(forKey key: String) -> AttributeValue?
///    subscript(key: AttributeKey) -> AttributeValue? { get }
}

extension KeyedValues {
    public func dictionary(withKeys: [AttributeKey]) -> AttributeDictionary {
        let tuples = attributeKeys.compactMap { key in
            self.attribute(forKey: key).map { (key, $0) }
        }

        return AttributeDictionary(uniqueKeysWithValues: tuples)
    }

}
//
