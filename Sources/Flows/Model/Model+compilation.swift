//
//  Model+Validation.swift
//  
//
//  Created by Stefan Urbanek on 27/05/2022.
//

import Graph

public enum ModelCompilationError: Error {
    case validation([ModelError])
}

extension Model {
    func compile() throws -> CompiledModel {
        let errors = validate()
        guard errors.isEmpty else {
            throw ModelCompilationError.validation(errors)
        }
        
        // Topologically sort
        
        // L ← Empty list that will contain the sorted elements
        var sorted: [ExpressionNode] = []

        // S ← Set of all nodes with no incoming edge
        var sources: [ExpressionNode] = self.expressionNodes.filter {
            $0.incomingParameterNodes.isEmpty
        }

        var links = self.parameterLinks
        
        //
        //while S is not empty do
        var node: ExpressionNode
        while !sources.isEmpty {
            //    remove a node n from S
            node = sources.removeFirst()
            print("Looking at \(node.name)")
            //    add n to L
            sorted.append(node)
            
            let outgoing = links.filter { $0.origin === node }
            
            for link in outgoing {
                links.removeAll { $0 === link }
                let m = link.target as! ExpressionNode
                print("    - m: \(m.name)")
                if links.allSatisfy({$0.target != m}) {
                    print("    + adding new source: \(m.name)")
                    sources.append(m)
                }
            }

            //    for each node m with an edge e from n to m do
            //        remove edge e from the graph
            //        if m has no other incoming edges then
            //            insert m into S

        }
        if !links.isEmpty {
            fatalError("Graph contains cycles. Links: \(links)")
        }

        let compiledModel = CompiledModel(nodes: sorted)

        return compiledModel
        
    }
    
    
    public func validate() -> [ModelError] {
        let errors: [ModelError]
       
        // Validate constraints
        
        errors = validateFlowInputOutput()
                    + validateUniqueNames()
//                    + validateCycles()
                    + validateUsedInputs()
        + validateConstraints()

        return errors
    }
    
    public func validateConstraints() -> [ModelError] {
        var errors: [ModelError] = []
        
        for constraint in linkConstraints {
            for link in graph.links {
                guard constraint.match(link) else {
                    continue
                }
                if !constraint.check(link) {
                    let text = "Link \(link) violates constraint: \(constraint)"
                    errors.append(ModelError.unknown(text))
                }
            }
        }
        return errors
    }
    /// Validate inputs and outputs of flows
    ///
    public func validateFlowInputOutput() -> [ModelError] {
        // Check for same input/output of flows
        //
        let errors: [ModelError] = flows.filter { flow in
            let node = drainedBy(flow)
            return node != nil && drainedBy(flow) === filledBy(flow)
        }.map { flow in
            .sameFlowInputOutput(flow)
        }
        
        return errors
    }
    
    public func validateUniqueNames() -> [ModelError] {
        
        // Check names
        //
        var seen: [String:Set<Node>] = [:]
        for node in expressionNodes {
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
    
//    public func validateCycles() -> [ModelError] {
//        var errors: [ModelError] = []
//        var seen: [Node] = []
//
//        for startNode in nodes {
//            guard !seen.contains(startNode) else {
//                continue
//            }
//            seen.append(startNode)
//
//            var follow: [Node] = outgoing(startNode).map { $0.target }
//            while !follow.isEmpty {
//                let node = follow.removeFirst()
//                if seen.contains(node) {
//                    errors.append(.cycle(node))
//                }
//                else {
//                    seen.append(node)
//                    follow += outgoing(node).map { $0.target }
//                }
//            }
//        }
//        return errors
//    }
    
    public func validateUsedInputs() -> [ModelError] {
        var errors: [ModelError] = []

        // FIXME: Not implemented - we need expressions
        return []
    }

}
