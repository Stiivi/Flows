//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 05/06/2022.
//

import Foundation

public class CompiledModel {
    /// Topologically sorted nodes
    let nodes: [Node]

    var containers: [Container] { nodes.compactMap { $0 as? Container } }
    
    public init(nodes: [Node]) {
        self.nodes = nodes
    }
}