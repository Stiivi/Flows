//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
//

import Foundation
public class Flow: ExpressionNode {
    var expressionString: String
    
    public init(name: String,
         expression: String){
        self.expressionString = expression
        super.init(name: name, expressionString: expression, labels: ["flow"])
    }
}

