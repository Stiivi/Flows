//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 18/06/2022.
//

import Graph

/// Predicate that matches flow nodes with the same drain and fill stocks
public class SameDrainFill: NodePredicate {
    // TODO: Be free from the model, rethink the inflow/outflow model methods
    // TODO: This requires re-introduction of "neighbourhoods" to the graph (see TarotKit)
    
    public init() {
    }
    
    public func match(_ node: Node) -> Bool {
        guard let flow = node as? Flow else {
            return false
        }
        
        if let node = flow.drains {
            return node === flow.fills
        }
        else {
            return false
        }
    }
}


/*
 
 Constraints - list of rules that have to be satisfied in the model graph.
 
 Types:
 
 - integrity: these constraints must be satisfied even during the editing process,
   an editor should not allow violation of the constraints to happen
 - content:  constraints that guard the content. These constraints might be
   violated during editing process, users should get warnings about them. However,
   they must be satisfied for the model compilation.
 
 */

let ModelConstraints: [Constraint] = [
    NodeConstraint(
        // All flows must have only one outgoing "flow" link to a stock.
        // This is a model integrity constraint.
        name: "single_outflow_target",
        match: LabelPredicate(all: "flow"),
        requirement: UniqueNeighbourRequirement("flow", direction: .outgoing)
    ),
    NodeConstraint(
        // All flows must have only one incoming "flow" link from a stock.
        name: "single_inflow_origin",
        match: LabelPredicate(all: "flow"),
        requirement: UniqueNeighbourRequirement("flow", direction: .incoming)
    ),
    NodeConstraint(
        // Inflow of a stock node must be different from the outflow
        // TODO: Remove the model requirement
        name: "different_drain_fill",
        match: SameDrainFill(),
        requirement: RejectAll()
    ),
    NodeConstraint(
        // Name
        name: "unique_node_name",
        match: LabelPredicate(any: "flow", "node", "stock"),
        requirement: UniqueProperty<String> {
            if let node = $0 as? ExpressionNode {
                return node.name
            }
            else {
                return nil
            }
        }
    ),
    LinkConstraint(
        name: "forbidden_flow_to_flow",
        match: LinkObjectPredicate(
            origin: LabelPredicate(all: "flow"),
            target: LabelPredicate(all: "flow"),
            link: LabelPredicate(all: "flow")
        ),
        requirement: RejectAll()
    )
]
