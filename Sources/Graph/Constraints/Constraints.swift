//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
//

import Foundation

/// A protocol for validating links whether they satisfy given constraints.
///
public protocol LinkConstraint {
    
    /// Validates whether the constraint can be applied to an existing link.
    ///
    /// Implementation is required.
    ///
    func match(_ link: Link) -> Bool
    
    /// Check whether the constrain is satisfied or not.
    ///
    /// - Returns: `true` if the constraint is satisfied for the link, `false`
    /// if the constraint is not satisfied.
    ///
    /// Default implementation is provided and it calls `check(from:, to:, labels:)`
    ///
    func check(_ link: Link) -> Bool
    
    /// Checks whether a link that might exist between given two nodes satisfies
    /// the constraint. The link does not have to exist.
    ///
    /// This method can be used in connection with a user interface to validate
    /// user's intent.
    ///
    /// - Precondition: Both origin and target must exist in a graph.
    ///
    /// Implementation is required.
    ///
    func check(from origin: Node, to target: Node, labels: LabelSet) -> Bool
}

public extension LinkConstraint {
    func check(_ link: Link) -> Bool {
        precondition(link.graph != nil)
        return check(from: link.origin, to: link.target, labels: link.labels)
    }
}
/// Check whether a node has unique neighbour.
///
public class UniqueNeighbourConstraint: LinkConstraint {
    public let nodePredicate: NodePredicate
    public let linkSelector: LinkSelector
    public let isRequired: Bool
    
    /// Creates a constraint for unique neighbour.
    ///
    /// If the unique neighbour is required, then the constraint fails if there
    /// is no neighbour matching the link selector. If the neighbour is not
    /// required, then the constraint succeeds either where there is exactly
    /// one neighbour or when there is none.
    ///
    /// - Parameters:
    ///     - nodeLabels: labels that match the nodes for the constraint
    ///     - linkSelector: link selector that has to be unique for the matching node
    ///     - required: Wether the unique neighbour is required.
    ///
    public init(nodes nodePredicate: NodePredicate, links linkSelector: LinkSelector, required: Bool=false) {
        self.nodePredicate = nodePredicate
        self.linkSelector = linkSelector
        self.isRequired = required
    }

    /// Returns `true` if the constraint matches the link. That is, whether
    /// the constraint is relevant to the link and whether it makes sense to
    /// perform constraint checks on the link.
    ///
    public func match(_ link: Link) -> Bool {
        return nodePredicate.match(link.origin)
    }
    
    public func check(from origin: Node, to target: Node, labels: LabelSet) -> Bool {
        guard origin.graph != nil else {
            fatalError("Constraint can not be checked on an objects without a graph")
        }
        guard target.graph === origin.graph else {
            fatalError("Constraint can be checked only on nodes from the same graph ")
        }
        
        let links = linkSelector.links(with: origin)
        
        if isRequired {
            return links.count == 1
        }
        else {
            return links.count == 0 || links.count == 1
        }
    }
}

/// Specifies links that are prohibited. If the constraint is applied, then it
/// matches links that are not prohibited and rejects the prohibited ones.
///
public class ProhibitedLink: LinkConstraint {
    let originPredicate: NodePredicate?
    let targetPredicate: NodePredicate?
    let linkPredicate: LinkPredicate?
    
    
    public init(origin: NodePredicate? = nil, target: NodePredicate? = nil, links: LinkPredicate? = nil) {
        guard !(origin == nil && target == nil && links == nil) else {
            fatalError("At least one of origin, target or links has to be specified")
        }
        
        self.originPredicate = origin
        self.targetPredicate = target
        self.linkPredicate = links
    }
    
    public func match(_ link: Link) -> Bool {
        if let predicate = originPredicate {
            if predicate.match(link.origin) {
                return false
            }
        }
        if let predicate = targetPredicate {
            if predicate.match(link.target) {
                return false
            }
        }
        if let predicate = linkPredicate {
            if predicate.match(link) {
                return false
            }
        }
        return true
    }
    
    public func check(from origin: Node, to target: Node, labels: LabelSet) -> Bool {
        if let predicate = originPredicate {
            if predicate.match(origin) {
                return false
            }
        }
        if let predicate = targetPredicate {
            if predicate.match(target) {
                return false
            }
        }
        if let predicate = linkPredicate {
            if predicate.match(from: origin, to: target, labels: labels) {
                return false
            }
        }
        return true
    }

}
