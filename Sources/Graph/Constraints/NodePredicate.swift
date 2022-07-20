//
//  NodePredicate.swift
//  
//
//  Created by Stefan Urbanek on 17/06/2022.
//

/// Protocol for a predicate that matches a node.
///
/// Objects conforming to this protocol are expected to implement the method `match()`
///
public protocol NodePredicate {
    /// Tests a node whether it matches the predicate.
    ///
    /// - Returns: `true` if the node matches.
    ///
    func match(_ node: Node) -> Bool
}

/// Predicate that matches any node.
///
public class AnyNodePredicate: NodePredicate {
    public init() {}
    
    /// Matches any node – always returns `true`.
    ///
    public func match(_ node: Node) -> Bool {
        return true
    }
}
