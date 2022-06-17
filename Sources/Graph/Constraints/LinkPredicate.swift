//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 17/06/2022.
//

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
