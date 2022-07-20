//
//  ConstaintChecker.swift
//  
//
//  Created by Stefan Urbanek on 16/06/2022.
//

public struct ConstraintViolation: CustomStringConvertible, CustomDebugStringConvertible {
    // TODO: Use constraint reference instead of just a name
    public let constraint: Constraint
    
    // FIXME: Split into links and nodes
    public let objects: [GraphObject]

    public var name: String { constraint.name }

    public var description: String {
        if let desc = constraint.description {
            return "\(name): \(desc)"
        }
        else {
            return "\(name) (no detailed violation description)"
        }
    }
    public var debugDescription: String {
        "ConstraintViolation(\(name), \(objects))"
    }

    public var nodes:[Node] {
        objects.compactMap { $0 as? Node }
    }

    public var links:[Link] {
        objects.compactMap { $0 as? Link }
    }
}

/// An object that check constraints on a graph.
///
public class ConstraintChecker {
    // TODO: Dissolve this class back into Model?
    // TODO: This is a separate class to make thinking about the problem more explicit
    // TODO: Maybe convert to: extension Array where Element == Constraint

    let constraints: [Constraint]
    
    public init(constraints: [Constraint]) {
        self.constraints = constraints
    }
    
    public func check(graph: Graph) -> [ConstraintViolation] {
        let violations: [ConstraintViolation]
        
        violations = constraints.compactMap {
            let violators = $0.check(graph)
            
            if violators.isEmpty {
                return nil
            }
            else {
                return ConstraintViolation(constraint: $0, objects: violators)
            }
            
        }

        return violations
    }
}
