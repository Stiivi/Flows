//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
//

import Foundation


// Alias: Accumulator, level, state, container, reservoir, pool

/// A node representing a stock – accumulator, container, reservoir, a pool.
///
public class Stock: ExpressionNode {
    public init(name: String, expression: String) {
        super.init(name: name, expression: expression)
    }
    public init(name: String, float value: Float) {
        super.init(name: name, expression: String(value), labels: ["stock"])
    }
}
