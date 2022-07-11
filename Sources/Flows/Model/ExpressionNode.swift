import Graph

public class ExpressionNode: Node {
    /// Name of the node
    public var name: String
    
    /// Arithmetic expression
    var expressionString: String

    init(name: String, expression: String, labels: LabelSet = []) {
        self.name = name
        self.expressionString = expression
        super.init(labels: Set([Model.ExpressionLabel]).union(labels))
    }
        
    public static func ==(lhs: ExpressionNode, rhs: ExpressionNode) -> Bool {
        return lhs.name == rhs.name && lhs.expressionString == rhs.expressionString
    }
    
    
    override public var description: String {
        let typename = "\(type(of: self))"
        return "\(typename)(\(name))"
    }
    
    /// List of incoming links to parameters.
    ///
    public var incomingParameterNodes: [ExpressionNode] {
        let links = incoming.filter { $0.contains(label: Model.ParameterLabel) }
        return links.compactMap { $0.target as? ExpressionNode }
    }
        
}
