//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 2021/10/10.
//

/// Type for graph object identifier. There should be no expectation about
/// the value of the identifier.
///
public typealias OID = Int

/// Type of a node or a link label.
///
public typealias Label = String

/// Type for set of labels.
///
public typealias LabelSet = Set<String>


/// An abstract class representing all objects in a graph. Concrete
/// kinds of graph objects are ``Node`` and ``Link``.
///
/// Each graph objects has a unique identity within the graph.
///
/// All object's attributes are optional. It is up to the user to add
/// constraints or validations for the attributes of graph objects.
///
open class GraphObject: Identifiable, CustomStringConvertible {
    /// Graph the object is associated with.
    ///
    public internal(set) var graph: Graph?
    
    /// A set of labels.
    ///
    public internal (set) var labels: LabelSet = []
    
    /// Identifier of the object that is unique within the owning graph.
    /// The attribute is populated when the object is associated with a graph.
    /// When the object is disassociate from a graph, the identifier is set to
    /// `nil`.
    ///
    public var id: OID?
    //    public internal(set) var id: OID?
    

    // TODO: Make this private. Use Graph.create() and Graph.connect()
    /// Create an empty object. The object needs to be associated with a graph.
    ///
    public init(id: OID?=nil, labels: LabelSet=[]) {
        self.id = id
        self.labels = labels
    }

    /// Returns `true` if the object contains the given label.
    ///
    public func contains(label: Label) -> Bool {
        return labels.contains(label)
    }
    
    /// Returns `true` if the object contains all of the labels.
    ///
    public func contains(labels: LabelSet) -> Bool {
        return labels.isSubset(of: self.labels)
    }

    /// Sets object label.
    public func set(label: Label) {
        labels.insert(label)
    }
    
    /// Unsets object label.
    public func unset(label: Label) {
        labels.remove(label)
    }
    
    open var description: String {
        let idString = id.map { String($0) } ?? "nil"
        
        return "Object(id: \(idString), labels: \(labels.sorted())])"
    }
    
    // MARK: - Prototyping/Experimental

    open var attributeKeys: [AttributeKey] {
        return []
    }
    
    open func attribute(forKey key: String) -> AttributeValue? {
        return nil
    }
}

extension GraphObject: Hashable {
    public static func == (lhs: GraphObject, rhs: GraphObject) -> Bool {
        lhs.id == rhs.id && lhs.labels == rhs.labels
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


