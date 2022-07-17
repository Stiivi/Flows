//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 18/06/2022.
//

import Graph

/// Predicate that matches flow nodes with the same drain and fill stocks
public class SameDrainFill: NodePredicate {
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


/**
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
        name: "single_outflow_target",
        description: """
                     All flows must have only one outgoing 'flow' link to a \
                     stock. This is a model integrity constraint.
                     """,
        match: LabelPredicate(all: Model.FlowNodeLabel),
        requirement: UniqueNeighbourRequirement(Model.OutflowSelector)
    ),

    NodeConstraint(
        name: "single_inflow_origin",
        description: """
                     All flows must have only one incoming "flow" link
                     from a stock. This is a model integrity constraint.
                     """,
        match: LabelPredicate(all: Model.FlowNodeLabel),
        requirement: UniqueNeighbourRequirement(Model.InflowSelector)
    ),

    NodeConstraint(
        name: "drain_and_fill_is_different",
        description: """
                     Inflow of a stock node must be different from the outflow.
                     """,
        match: SameDrainFill(),
        requirement: RejectAll()
    ),

    NodeConstraint(
        // Name
        name: "unique_node_name",
        description: """
                     Expression nodes (flows, stocks and transformations) \
                     should have a unique name.
                     """,

        match: LabelPredicate(any: Model.FlowLinkLabel, Model.StockNodeLabel, Model.TransformNodeLabel),
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
        description: """
                     There must be no link of type "flow" from a flow to \
                     another flow.
                     """,
        match: LinkObjectPredicate(
            origin: LabelPredicate(all: Model.FlowNodeLabel),
            target: LabelPredicate(all: Model.FlowNodeLabel),
            link: LabelPredicate(all: Model.FlowLinkLabel)
        ),
        requirement: RejectAll()
    )
]
