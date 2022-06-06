public class Node: Equatable, Hashable, CustomStringConvertible {
    
    /// The model this node is associated with. A node can be associated only
    /// with one model.
    ///
    public var model: Model? = nil
    
    var name: String
    var expression: Expression
    
    init(name: String, expression: Expression) {
        self.name = name
        self.expression = expression
    }
    
    init(name: String, expressionString: String) {
        guard let expression = Parser(string: expressionString).parse() else {
            fatalError("Invalid expression: '\(expressionString)'")
        }
        self.name = name
        self.expression = expression
    }
    
    public static func ==(lhs: Node, rhs: Node) -> Bool {
        return lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
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
    
    public var description: String {
        let typename = "\(type(of: self))"
        return "\(typename)(\(name))"
    }
}

public class Flow: Node{
    var expressionString: String
    
    public init(name: String,
         expression: String){
        self.expressionString = expression
        super.init(name: name, expressionString: expression)
    }
}

public class Transform: Node{
    public init(name: String, expression: String) {
        super.init(name: name, expressionString: expression)
    }
}

public class Container: Node {
    public init(name: String, expression: String) {
        super.init(name: name, expressionString: expression)
    }
    public init(name: String, float value: Float) {
        let expression = Expression.value(.float(value))
        super.init(name: name, expression: expression)
    }
}
public enum LinkType {
    /// Denotes a link where the origin is a variable parameter for the target
    case parameter
    /// Denotes a link where the one of the sides is a flow and another is a
    /// container
    case flow
}

public class Link: CustomStringConvertible {
    let origin: Node
    let target: Node
    let type: LinkType
    
    init(from origin: Node, to target: Node, type: LinkType = .parameter){
        self.origin = origin
        self.target = target
        self.type = type
    }
    
    public var description: String {
        return "Link(\(origin) -> \(target), \(type)"
    }
}

