//
//  LinkConstraints.swift
//  
//
//  Created by Stefan Urbanek on 16/06/2022.
//

// TODO: Merge with NodeConstraint

/// Graph constraint for a link.
///
public class LinkConstraint: Constraint {
    public let name: String
    public let description: String?
    public let match: LinkPredicate
    public let requirement: LinkConstraintRequirement
    
    public init(name: String, description: String? = nil, match: LinkPredicate, requirement: LinkConstraintRequirement) {
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

/// Definition of a constraint satisfaction requirement.
///
public protocol LinkConstraintRequirement {
    /// Check whether the constraint requirement is satisfied within the group
    /// of provided links.
    ///
    /// - Returns: List of graph objects that cause constraint violation.
    ///
    func check(_ links: [Link]) -> [GraphObject]
}

