//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 2021/11/30.
//

/// Representation of a change within a graph.
///
/// ``GraphChange`` is used for observation of changes. Instances are being
/// sent in the observation process through methods such as ``Graph/observe()``,
/// ``Graph/observeNeighbourhood(node:)`` or ``Graph/observeAttributes(object:)``.
///
public enum GraphChange: Equatable {
    /// Denotes a change to a graph when a node was added.
    ///
    case addNode(Node)
    
    /// Denotes a change to a graph when a node was removed.
    ///
    /// - Note: Node's `graph` property is set to `nil`, since the node
    /// no longer belongs to the graph.
    ///
    /// - Important: It is advised that an observer of this change will not
    /// change the removed node properties. Some applications might retain
    /// the node to perform undo cations.
    ///
    case removeNode(Node)

    /// Denotes a change to a graph when a link was created.
    ///
    case connect(Link)

    /// Denotes a change to a graph when a link was removed.
    ///
    /// - Note: The `graph` property of the link is set to `nil`, since the link
    /// no longer belongs to the graph. The link still points to valid
    /// origin and target nodes, but they are not guaranteed to have `graph`
    /// property set either.
    ///
    /// - Important: It is advised that an observer of this change will not
    /// change the removed link properties. Some applications might retain
    /// the link to perform undo cations.
    ///
    case disconnect(Link)
    
    /// Denotes a change to a graph object - either a node or a link - where
    /// an attribute was set to a new, non-nil value.
    ///
//    case setAttribute(GraphObject, AttributeKey, Value)

    /// Denotes a change to a graph object - either a node or a link - where
    /// an attribute was removed or set to a `nil` value.
    ///
//    case unsetAttribute(GraphObject, AttributeKey)
    
    /// Returns `true` if the change is related to given object. For node
    /// removal, node addition and attribute changes the object is related
    /// is the only objects of the change. For connection and disconnection
    /// changes the object is related if the object is the link, origin or
    /// a target of the link.
    ///
    public func isRelated(_ object: GraphObject) -> Bool {
        switch self {
        case let .addNode(node): return node === object
        case let .removeNode(node): return node === object
        case let .connect(link): return link === object || link.origin === object || link.target === object
        case let .disconnect(link): return link === object || link.origin === object || link.target === object
//        case let .setAttribute(another, _, _): return another === object
//        case let .unsetAttribute(another, _): return another === object
        }
    }
    
    /// Compare two changes. Two graph changes are equal if they are of the same
    /// type, when the graph objects are identical and when the rest of
    /// compared change attributes are equal.
    /// 
    public static func ==(lhs: GraphChange, rhs: GraphChange) -> Bool {
        switch (lhs, rhs) {
        case let (.addNode(lnode), .addNode(rnode)):
            return lnode == rnode
        case let (.removeNode(lnode), .removeNode(rnode)):
            return lnode == rnode
        case let (.connect(llink), .connect(rlink)):
            return llink == rlink
        case let (.disconnect(llink), .disconnect(rlink)):
            return llink == rlink
//        case let (.setAttribute(lobj, lattr, lvalue), .setAttribute(robj, rattr, rvalue)):
//            return lobj == robj && lattr == rattr && lvalue == rvalue
//        case let (.unsetAttribute(lobj, lattr), .unsetAttribute(robj, rattr)):
//            return lobj == robj && lattr == rattr
        default: return false
        }
    }
}
