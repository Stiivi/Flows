//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 18/07/2022.
//

import Foundation

public class DotStyle {
    public let linkStyles: [DotLinkStyle]
    public let nodeStyles: [DotNodeStyle]
    
    public init(nodes: [DotNodeStyle]? = nil, links: [DotLinkStyle]? = nil){
        self.linkStyles = links ?? []
        self.nodeStyles = nodes ?? []
    }
}

/// Style of a link for Graphviz/DOT export.
///
public struct DotLinkStyle {
    public let predicate: LinkPredicate
    public let attributes: [String:String]
    public init(predicate: LinkPredicate, attributes: [String:String]) {
        self.predicate = predicate
        self.attributes = attributes
    }
}

/// Style of a node for Graphviz/DOT export.
///
public struct DotNodeStyle {
    public let predicate: NodePredicate
    public let attributes: [String:String]
    
    public init(predicate: NodePredicate, attributes: [String:String]) {
        self.predicate = predicate
        self.attributes = attributes
    }
}
