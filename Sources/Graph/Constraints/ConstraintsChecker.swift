//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 16/06/2022.
//

import Foundation

public struct ConstraintViolation: CustomStringConvertible {
    // TODO: Use constraint reference instead of just a name
    public let name: String
    public let objects: [GraphObject]
    
    public var description: String {
        "ConstraintViolation(\(name), \(objects))"
    }
}

public class ConstraintChecker {
    // TODO: Dissolve this class back into Model?
    // TODO: This is a separate class to make thinking about the problem more explicit
    // TODO: Remove graph, use check(graph:)
    
    let graph: Graph
    let nodeConstraints: [NodeConstraint]
    let linkConstraints: [LinkConstraint]
    
    public init(graph: Graph, nodeConstraints: [NodeConstraint]=[], linkConstraints: [LinkConstraint]=[]) {
        self.graph = graph
        self.nodeConstraints = nodeConstraints
        self.linkConstraints = linkConstraints
    }
    
    public func check() -> [ConstraintViolation] {
        let nodeViolations: [ConstraintViolation]
        let linkViolations: [ConstraintViolation]
        
        nodeViolations = nodeConstraints.compactMap {
            let violators = $0.check(graph)
            
            if violators.isEmpty {
                return nil
            }
            else {
                return ConstraintViolation(name: $0.name, objects: violators)
            }
            
        }

        linkViolations = linkConstraints.compactMap {
            let violators = $0.check(graph)
            
            if violators.isEmpty {
                return nil
            }
            else {
                return ConstraintViolation(name: $0.name, objects: violators)
            }
            
        }

        return nodeViolations + linkViolations
    }
}
