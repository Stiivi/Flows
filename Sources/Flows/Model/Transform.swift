//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
//

import Foundation

// Alias: auxiliary, expression, constant, variable, ...

// TODO: Rename to Auxiliary
// FIXME: Match label

/// Auxiliary node that contains either a constant or a formula.
///
public class Transform: ExpressionNode {
    public init(name: String, expression: String) {
        super.init(name: name, expression: expression, labels: ["converter"])
    }
}
