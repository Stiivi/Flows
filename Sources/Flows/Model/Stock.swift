//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
//

import Foundation
public class Stock: ExpressionNode {
    public init(name: String, expression: String) {
        super.init(name: name, expressionString: expression)
    }
    public init(name: String, float value: Float) {
        let expression = Expression.value(.float(value))
        super.init(name: name, expression: expression, labels: ["stock"])
    }
}
