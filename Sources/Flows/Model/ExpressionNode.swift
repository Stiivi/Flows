//
//  ExpressionNode.swift
//
//
//  Created by Stefan Urbanek on 17/06/2022.
//


import Graph

// FIXME: Consider consolidating all node types into this class.

/// Abstract class that represents a node with an arithmetic expression.
///
public class ExpressionNode: Node {
    static let ParameterSelector = LinkSelector(Model.ParameterLinkLabel, direction: .incoming)

    /// Name of the node
    public var name: String
    
    /// Arithmetic expression
    var expressionString: String
    
    /// Creates an expression node.
    public init(name: String, expression: String, labels: LabelSet = []) {
        self.name = name
        self.expressionString = expression
        let typeName = String(describing: type(of: self))
        let systemLabels = Set([typeName])
        super.init(labels: Set(systemLabels).union(labels))
    }
        
    public convenience init(name: String, float value: Float) {
        self.init(name: name, expression: String(value))
    }
    
    public static func ==(lhs: ExpressionNode, rhs: ExpressionNode) -> Bool {
        return lhs.name == rhs.name && lhs.expressionString == rhs.expressionString
    }
    
    
    override public var description: String {
        let typename = "\(type(of: self))"
        return "\(typename)(\(name), id: \(id!), expr: \(expressionString))"
    }
    
    /// List of incoming links to parameters.
    ///
    public var incomingParameterNodes: [ExpressionNode] {
        let links = linksWithSelector(Self.ParameterSelector)
        return links.compactMap { $0.origin as? ExpressionNode }

    }
        
}
