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
}
