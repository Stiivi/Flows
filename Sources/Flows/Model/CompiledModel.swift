//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 05/06/2022.
//

import Foundation

public class CompiledModel {
    /// Topologically sorted nodes
    let nodes: [ExpressionNode]

    var stocks: [Stock] { nodes.compactMap { $0 as? Stock } }
    
    public init(nodes: [ExpressionNode]) {
        self.nodes = nodes
    }
}
