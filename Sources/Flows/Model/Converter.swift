//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
//

import Foundation

// Alias: auxiliary, expression, constant, variable, ...

public class Transform: ExpressionNode {
    public init(name: String, expression: String) {
        super.init(name: name, expression: expression, labels: ["converter"])
    }
}
