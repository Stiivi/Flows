//
//  Model+Validation.swift
//  
//
//  Created by Stefan Urbanek on 27/05/2022.
//

import Foundation

extension Model {
    public func validate() -> [ModelError] {
        let errors: [ModelError]
        
        errors = validateFlowInputOutput()
                    + validateUniqueNames()
                    + validateCycles()
                    + validateUsedInputs()

        return errors
    }
    
    /// Validate inputs and outputs of flows
    ///
    public func validateFlowInputOutput() -> [ModelError] {
        // Check for same input/output of flows
        //
        let errors: [ModelError] = flows.filter { flow in
            flow.origin === flow.target
        }.map { flow in
            .sameFlowInputOutput(flow)
        }
        
        return errors
    }
    
    public func validateUniqueNames() -> [ModelError] {
        
        // Check names
        //
        var seen: [String:Set<Node>] = [:]
        for node in nodes {
            if seen[node.name] != nil {
                seen[node.name]!.insert(node)
            }
            else {
                seen[node.name] = Set([node])
            }
        }
        
        let dupes: [ModelError] = seen.filter { (name, nodes) in
            nodes.count > 1
        }.map { (name, nodes) in
            .duplicateName(name, nodes)
        }
    
        return dupes
    }
    
    public func validateCycles() -> [ModelError] {
        var errors: [ModelError] = []
        var seen: [Node] = []
        
        for startNode in nodes {
            guard !seen.contains(startNode) else {
                continue
            }
            seen.append(startNode)
            
            var follow: [Node] = outgoing(startNode).map { $0.target }
            while !follow.isEmpty {
                let node = follow.removeFirst()
                if seen.contains(node) {
                    errors.append(.cycle(node))
                }
                else {
                    seen.append(node)
                    follow += outgoing(node).map { $0.target }
                }
            }
        }
        return errors
    }
    
    public func validateUsedInputs() -> [ModelError] {
        var errors: [ModelError] = []

        // FIXME: Not implemented - we need expressions
        return []
    }

}
