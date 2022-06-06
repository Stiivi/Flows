public class Node: Equatable, Hashable {
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
}

func evaluateExpression(_ expression: Expression, state: SimulationState) -> Float {
    return 0
}

public class Flow: Node, CustomStringConvertible {
    var origin: Container?
    var target: Container?
    var expressionString: String
    
    init(name: String,
         from origin: Container?=nil,
         to target: Container?=nil,
         expression: String){
        self.origin = origin
        self.target = target
        self.expressionString = expression
        super.init(name: name, expressionString: expression)
    }

    public var description: String {
        return "Transform(\(name), \(expressionString))"
    }
}

public class Transform: Node, CustomStringConvertible {
    init(name: String, expression: String) {
        super.init(name: name, expressionString: expression)
    }
    
    public var description: String {
        return "Transform(\(name), \(expression))"
    }
}

public class Container: Node {
    init(name: String, expression: String) {
        super.init(name: name, expressionString: expression)
    }
    init(name: String, float value: Float) {
        let expression = Expression.value(.float(value))
        super.init(name: name, expression: expression)
    }
}

public class Link {
    let origin: Node
    let target: Node
    
    init(from origin: Node, to target: Node){
        self.origin = origin
        self.target = target
    }
}

