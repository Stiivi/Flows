import Graph

public class ExpressionNode: Node {
    /// Name of the node
    var name: String
    
    /// Arithmetic expression
    var expression: Expression
    
    init(name: String, expression: Expression, labels: LabelSet = []) {
        self.name = name
        self.expression = expression
        super.init(labels: Set([Model.ExpressionLabel]).union(labels))
    }
    
    init(name: String, expressionString: String, labels: LabelSet = []) {
        guard let expression = Parser(string: expressionString).parse() else {
            fatalError("Invalid expression: '\(expressionString)'")
        }
        self.name = name
        self.expression = expression
        super.init(labels: labels)
    }
    
    public static func ==(lhs: ExpressionNode, rhs: ExpressionNode) -> Bool {
        return lhs.name == rhs.name && lhs.expression == rhs.expression
    }
    

    func evaluate(state: SimulationState) throws -> Float {
        let evaluator = NumericExpressionEvaluator()
        var functions: [String:FunctionProtocol] = [:]
        
        for function in allBuiltinFunctions {
            functions[function.name] = function
        }
        evaluator.functions = functions
        
        for (key, value) in state.values {
            evaluator.variables[key] = .float(value)
        }

        let value = try evaluator.evaluate(expression)
        return value!.floatValue()!
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

