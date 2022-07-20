//
//  Stock.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
//

import Graph

// Alias: Accumulator, level, state, container, reservoir, pool

/// A node representing a stock – accumulator, container, reservoir, a pool.
///
public class Stock: ExpressionNode {
    /// Flag whether the value of the node can be negative.
    var allowsNegative: Bool = false

    /// List of flows flowing into a stock.
    ///
    var inflows: [Flow] {
        let links = linksWithSelector(Model.InflowSelector)
        return links.compactMap { $0.origin as? Flow }
    }

    /// List of flows flowing out from a stock.
    ///
    var outflows: [Flow] {
        let links = linksWithSelector(Model.OutflowSelector)
        return links.compactMap { $0.target as? Flow }
    }

    public override var attributeKeys: [AttributeKey] {
        super.attributeKeys + ["allowsNegative"]
    }

    public override func attribute(forKey key: AttributeKey) -> AttributeValue? {
        switch key {
        case "allowsNegative": return allowsNegative
        default: return super.attribute(forKey: key)
        }
    }

}
