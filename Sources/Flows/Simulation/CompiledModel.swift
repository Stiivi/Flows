//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 05/06/2022.
//

import Foundation


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

public class CompiledModel {
    /// Topologically sorted nodes
    let sortedNodes: [CompiledExpressionNode]

    var stocks: [Stock] { sortedNodes.compactMap { $0 as? Stock } }
    
    public init(nodes: [CompiledExpressionNode]) {
        self.sortedNodes = nodes
    }
}
