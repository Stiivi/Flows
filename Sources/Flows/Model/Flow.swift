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
    
    /// Stock that the flow drains, if the flow input is connected.
    ///
    /// - Note: If there are multiple stocks connected, the model has no
    /// integrity and then the value is one of the stocks, chosen arbitrarily.
    ///
    public var drains: Stock? {
        let links = incoming.filter {
            $0.origin as? Stock != nil
        }
        
        // If we get multiple results then we pick arbitrarily "first". The model
        // is inconsistent anyway.
        //
        
        if let link = links.first {
            return link.origin as? Stock
        }
        else {
            return nil
        }
    }
    
    /// Stock that the flow fills, if the flow output is connected.
    ///
    /// - Note: If there are multiple stocks connected, the model has no
    /// integrity and then the value is one of the stocks, chosen arbitrarily.
    ///
    public var fills: Stock? {
        let links = outgoing.filter {
            $0.target as? Stock != nil
        }
        
        if let link = links.first {
            return link.target as? Stock
        }
        else {
            return nil
        }
    }
}

