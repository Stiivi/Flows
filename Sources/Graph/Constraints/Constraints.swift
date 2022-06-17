//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
//

import Foundation

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

}
