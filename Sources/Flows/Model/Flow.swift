//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
//

/// Object representing a flow.
///
/// Flow is a node that can be connected to two stocks by a flow link. One stock
/// is an inflow - stock from which the node drains, and another stock is an
/// outflow - stock to which the node fills.
///
public class Flow: ExpressionNode {
    /// Stock that the flow drains, if the flow input is connected.
    ///
    /// - Note: If there are multiple stocks connected, the model has no
    /// integrity and then the value is one of the stocks, chosen arbitrarily.
    ///
    public var drains: Stock? {
        let links = incoming.filter {
            $0.contains(label:Model.FlowLinkLabel) && $0.origin as? Stock != nil
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
            $0.contains(label:Model.FlowLinkLabel) && $0.target as? Stock != nil
        }
        
        if let link = links.first {
            return  link.target as? Stock
        }
        else {
            return nil
        }
    }
}

