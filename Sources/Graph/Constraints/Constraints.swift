//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
//

import Foundation

// NOTE: This file is empty - original code run away to other files. Keeping it
// here as a remainder for potential future unification.

// TODO: Merge LinkConstraint and NodeConstraint

// NOTE: The two can be merged using generics, although not doing it right now,
//       trying to not to use generics, since I am not 100% sure whether this
//       library will stay written in Swift at this moment.


/*

 Potential merge:
 
 - class Constraint(name:, match:, requirement)
 - match is a graph object Predicate which matches either nodes or links
 - requirement is CosntraintRequirement
 
 */

/// Graph constraint
public protocol Constraint {
    // TODO: Abandoned protocol
    /// Checks whether the graph satisfies the constraint. Returns a list of
    /// graph objects that violate the constraint
    func check(_ graph: Graph) -> [GraphObject]

}
