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

/// Predicate that matches any node.
///
public class AnyNodePredicate: NodePredicate {
    
    /// Matches any node – always returns `true`.
    ///
    public func match(_ node: Node) -> Bool {
        return true
    }
}


/// Protocol for a predicate that matches a link.
///
/// Objects conforming to this protocol are expected to implement the method
/// `match(from:, to:, labels:)`.
///
public protocol LinkPredicate: Predicate {
    /// Tests a link whether it matches the predicate.
    ///
    /// - Returns: `true` if the link matches.
    ///
    /// Default implementation calls `match(from:,to:,labels:)`
    ///
    func match(_ link: Link) -> Bool
}

// TODO: Reason: see generics rant in Predicate.swift
extension LinkPredicate {
    // TODO: This is a HACK that assumes I know what I am doing when using this.
    public func match(_ object: GraphObject) -> Bool {
        match(object as! Link)
    }
}

/// Predicate that tests the link object itself together with its objects -
/// origin and target.
///
public class LinkObjectPredicate: LinkPredicate {
    
    // TODO: Use CompoundPredicate
    // FIXME: I do not like this class
    
    let originPredicate: NodePredicate?
    let targetPredicate: NodePredicate?
    let linkPredicate: LinkPredicate?
    
    public init(origin: NodePredicate? = nil, target: NodePredicate? = nil, link: LinkPredicate? = nil) {
        guard !(origin == nil && target == nil && link == nil) else {
            fatalError("At least one of the parameters must be set: origin, target or link")
        }
        
        self.originPredicate = origin
        self.targetPredicate = target
        self.linkPredicate = link
    }
    
    public func match(_ link: Link) -> Bool {
        if let predicate = originPredicate, !predicate.match(link.origin) {
            return false
        }
        if let predicate = targetPredicate, !predicate.match(link.target) {
            return false
        }
        if let predicate = linkPredicate, !predicate.match(link) {
            return false
        }
        return true
    }
}

/// Predicate that matches a graph object (either a node or a link) for
/// existence of labels. The tested object must have all the specified labels
/// set.
///
public class LabelPredicate: NodePredicate, LinkPredicate  {
    public let mode: MatchMode
    public let labels: LabelSet
    
    public enum MatchMode {
        /// Match any of the labels specified in the predicate
        case any
        /// Match all of the labels specified in the predicate
        case all
    }
    
    /// Creates a predicate from a list of labels to be matched.
    ///
    public convenience init(any labels: String...) {
        self.init(labels: Set(labels), mode: .any)
    }

    /// Creates a predicate from a list of labels to be matched.
    ///
    public convenience init(all labels: String...) {
        self.init(labels: Set(labels), mode: .all)
    }

    /// Creates a predicate from a list of labels to be matched.
    ///
    public init(labels: LabelSet, mode: MatchMode) {
        self.labels = labels
        self.mode = mode
    }
    
    public func match(_ node: Node) -> Bool {
        switch mode {
        case .all: return node.contains(labels: labels)
        case .any: return labels.contains { node.contains(label: $0) }
        }
    }

    public func match(_ link: Link) -> Bool {
        return self.labels.isSubset(of: link.labels)
    }
}

public enum LogicalConnective {
    case and
    case or
}

// TODO: Convert this to a generic.
// NOTE: So far I was fighting with the compiler (5.6):
// - compiler segfaulted
// - got: "Runtime support for parameterized protocol types is only available in macOS 99.99.0 or newer"
// - various compilation errors

public protocol Predicate {
    func match(_ object: GraphObject) -> Bool
    func and(_ predicate: Predicate) -> CompoundPredicate
    func or(_ predicate: Predicate) -> CompoundPredicate
}

extension Predicate {
    public func and(_ predicate: Predicate) -> CompoundPredicate {
        return CompoundPredicate(.and, predicates: self, predicate)
    }
    public func or(_ predicate: Predicate) -> CompoundPredicate {
        return CompoundPredicate(.or, predicates: self, predicate)
    }

}

public class CompoundPredicate: Predicate {
    public let connective: LogicalConnective
    public let predicates: [Predicate]
    
    public init(_ connective: LogicalConnective, predicates: any Predicate...) {
        self.connective = connective
        self.predicates = predicates
    }
    
    public func match(_ object: GraphObject) -> Bool {
        switch connective {
        case .and: return predicates.allSatisfy{ $0.match(object) }
        case .or: return predicates.contains{ $0.match(object) }
        }
    }
}
