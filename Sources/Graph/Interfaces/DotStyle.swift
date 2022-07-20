//
//  DotStyle.swift
//  
//
//  Created by Stefan Urbanek on 18/07/2022.
//

/// Object that encapsulates multiple styles for nodes and links of a Graphviz
/// graph.
///
public class DotStyle {
    /// List of link styles
    public let linkStyles: [DotLinkStyle]
    /// List of node styles
    public let nodeStyles: [DotNodeStyle]
    
    public init(nodes: [DotNodeStyle]? = nil, links: [DotLinkStyle]? = nil){
        self.linkStyles = links ?? []
        self.nodeStyles = nodes ?? []
    }
}

/// Style of a link for Graphviz/DOT export.
///
public struct DotLinkStyle {
    /// Predicate that determines which links match this style.
    ///
    public let predicate: LinkPredicate

    /// List of attributes to apply to the link.
    ///
    public let attributes: [String:String]

    /// Creates a Graphviz link style for links that match the predicate
    /// `predicate`. The style is defined by the `attributes`.
    ///
    public init(predicate: LinkPredicate, attributes: [String:String]) {
        self.predicate = predicate
        self.attributes = attributes
    }
}

/// Style of a node for Graphviz/DOT export.
///
public struct DotNodeStyle {
    /// Predicate that determines which nodes match this style.
    ///
    public let predicate: NodePredicate

    /// List of attributes to apply to the link.
    ///
    public let attributes: [String:String]
    
    /// Creates a Graphviz node style for nodes that match the predicate
    /// `predicate`. The style is defined by the `attributes`.
    ///
    public init(predicate: NodePredicate, attributes: [String:String]) {
        self.predicate = predicate
        self.attributes = attributes
    }
}
