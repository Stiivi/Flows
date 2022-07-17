//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 05/06/2022.
//


/// Structure that represents a compiled expression node. The string expression
/// is parsed and represented as an `Expression` structure.
///
/// The `CompiledExpressionNode` can be safely used by the interpreter and is
/// expected to be a valid node representation.
///
public struct CompiledExpressionNode {
    let node: ExpressionNode
    let expression: Expression
   
    var name: String { node.name }
    

    init(node: ExpressionNode, expression: Expression) {
        self.node = node
        self.expression = expression
    }
}

/// Compiled version of the model for the simulator.
///
/// The simulator is using compiled model for performing the simulation. The
/// original model might contain additional information that might need to be
/// derived or it might not be valid. The original model serves modelling
/// purposes.
///
/// Compiled model has graph validated, references resolved and nodes ordered.
///
public class CompiledModel {
    /// The model that was compiled into this compiled model
    let model: Model
    
    /// Topologically sorted nodes
    let sortedNodes: [CompiledExpressionNode]

//    var stocks: [Stock] { sortedNodes.compactMap { $0 as? Stock } }
    
    /// Creates a compiled model.
    ///
    /// - Parameters:
    ///     - model: Model from which this object was compiled
    ///     - nodes: list of topologically sorted expression nodes
    ///
    public init(model: Model, nodes: [CompiledExpressionNode]) {
        self.model = model
        self.sortedNodes = nodes
    }
}
