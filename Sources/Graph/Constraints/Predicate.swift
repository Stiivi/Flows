//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
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

/// Protocol for a predicate that matches a link.
///
/// Objects conforming to this protocol are expected to implement the method
/// `match(from:, to:, labels:)`.
///
public protocol LinkPredicate {
    /// Tests a link whether it matches the predicate.
    ///
    /// - Returns: `true` if the link matches.
    ///
    /// Default implementation calls `match(from:,to:,labels:)`
    ///
    func match(_ link: Link) -> Bool

    /// Tests whether the components of a potential link match the predicate.
    ///
    /// - Returns: `true` if the link component match.
    ///
    func match(from: Node, to: Node, labels: LabelSet) -> Bool
}

public extension LinkPredicate {
    func match(_ link: Link) -> Bool {
        return match(from: link.origin, to: link.target, labels: link.labels)
    }
}

/// Predicate that matches a graph object (either a node or a link) for
/// existence of labels. The tested object must have all the specified labels
/// set.
///
public class LabelsPredicate: NodePredicate, LinkPredicate  {
    let labels: LabelSet
    
    /// Creates a predicate from a list of labels to be matched.
    ///
    public convenience init(_ labels: String...) {
        self.init(labels: Set(labels))
    }

    /// Creates a predicate from a list of labels to be matched.
    ///
    public init(labels: LabelSet) {
        self.labels = labels
    }
    
    public func match(_ node: Node) -> Bool {
        return node.contains(labels: labels)
    }

    public func match(from: Node, to: Node, labels: LabelSet) -> Bool {
        return self.labels.isSubset(of: labels)
    }
}
