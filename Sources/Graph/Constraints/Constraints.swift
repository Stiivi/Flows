//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
//

/*

 Potential merge:
 
 - class Constraint(name:, match:, requirement)
 - match is a graph object Predicate which matches either nodes or links
 - requirement is ConstraintRequirement
 
 */

/// Graph constraint
public protocol Constraint {
    var name: String { get }
    /// Checks whether the graph satisfies the constraint. Returns a list of
    /// graph objects that violate the constraint
    func check(_ graph: Graph) -> [GraphObject]
    
    // TODO: Rename to non-conflicting attribute, like "message"
    var description: String? { get }
}

public protocol ObjectConstraintRequirement: LinkConstraintRequirement, NodeConstraintRequirement {
    func check(objects: [GraphObject]) -> [GraphObject]
}

extension ObjectConstraintRequirement {
    public func check(_ links: [Link]) -> [GraphObject] {
        return check(objects: links)
    }
    public func check(_ nodes: [Node]) -> [GraphObject] {
        return check(objects: nodes)
    }
}

/// Specifies links that are prohibited. If the constraint is applied, then it
/// matches links that are not prohibited and rejects the prohibited ones.
///
public class RejectAll: ObjectConstraintRequirement {
    public init() {
    }
   
    public func check(objects: [GraphObject]) -> [GraphObject] {
        /// We reject whatever comes in
        return objects
    }
}

/// Requirement that accepts all objects selected by the predicate. Used mostly
/// as a placeholder or for testing.
///
public class AcceptAll: ObjectConstraintRequirement {
    public init() {
    }
   
    public func check(objects: [GraphObject]) -> [GraphObject] {
        // We accept everything, therefore we do not return any violations.
        return []
    }
}

/// Check all non-nil properties
public class UniqueProperty<Value>: ObjectConstraintRequirement
        where Value: Hashable {
    public var extract: (GraphObject) -> Value?
    
    public init(_ extract: @escaping (GraphObject) -> Value?) {
        self.extract = extract
    }
    
    public func check(objects: [GraphObject]) -> [GraphObject] {
        var seen: [Value:Array<GraphObject>] = [:]
        
        for object in objects {
            guard let value = extract(object) else {
                continue
            }
            
            if seen[value] == nil {
                seen[value] = [object]
            }
            else {
                seen[value]!.append(object)
            }
        }
        
        let duplicates = seen.filter {
            $0.value.count > 1
        }.flatMap {
            $0.value
        }
        return duplicates
    }
}

public class ObjectConstraint: Constraint {
    public let name: String
    public let match: Predicate
    public let requirement: ObjectConstraintRequirement
    public let description: String?
    
    public init(name: String, description: String? = nil, match: Predicate, requirement: ObjectConstraintRequirement) {
        self.name = name
        self.description = description
        self.match = match
        self.requirement = requirement
    }

    /// Check the graph for the constraint and return a list of nodes that
    /// violate the constraint
    ///
    public func check(_ graph: Graph) -> [GraphObject] {
        let matched = graph.links.filter { match.match($0) }
        let violating = requirement.check(matched)
        return violating
    }
}
