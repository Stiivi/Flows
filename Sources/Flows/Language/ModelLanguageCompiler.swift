//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 14/07/2022.
//

public class ModelLanguageCompiler {
    public let model: Model
    /// Links to be created between flows and stocks that the flow drains
    public var drainLinks: [(Flow, String)] = []
    /// Links to be created between flows and stocks that the flow fills
    public var fillLinks: [(Flow, String)] = []
    
    /// Variables referenced by nodes
    public var parameterLinks: [(ExpressionNode, String)] = []
    
    public var output: [String] = []
    /// Creates a language compiler with a model to compile into
    public init(model: Model) {
        self.model = model
    }
    
    public func compile(source: String) throws {
        let parser = ModelParser(string: source)
        
        let ast = try parser.parseModel()
        
        if case let .model(statements) = ast {
            compile(statements: statements)
        }
        else {
            fatalError("Parser did not return a model")
        }
    }

    func compile(stock: Token, expression: ExpressionAST) {
        let name = stock.text
        
        // TODO: We are de-compiling here, since ExpressionNode has to way to provide expression directly (for reasons)
        let node = Stock(name: name, expression: expression.text)
        model.add(node)
        
        let variables = Set(expression.variables.map { $0.text })
        parameterLinks += variables.map { (node, $0) }
    }
    func compile(variable: Token, expression: ExpressionAST) {
        let name = variable.text
        
        // TODO: We are de-compiling here, since ExpressionNode has to way to provide expression directly (for reasons)
        let node = Transform(name: name, expression: expression.text)
        model.add(node)

        let variables = Set(expression.variables.map { $0.text })
        parameterLinks += variables.map { (node, $0) }
    }
    func compile(flow: Token, expression: ExpressionAST, drains: Token?, fills: Token?) {
        let name = flow.text
        
        // TODO: We are de-compiling here, since ExpressionNode has to way to provide expression directly (for reasons)
        let node = Flow(name: name, expression: expression.text)
        model.add(node)
        if let name = drains?.text {
            drainLinks.append((node, name))
        }
        if let name = fills?.text {
            fillLinks.append((node, name))
        }

        let variables = Set(expression.variables.map { $0.text })
        parameterLinks += variables.map { (node, $0) }
    }
    
    func compile(output tokens: [Token]) {
        output = tokens.map { $0.text }
    }

    func compile(statements: [ModelAST]) {
        for statement in statements {
            switch statement {
            case let .stock(name, expression):
                compile(stock: name, expression: expression)
            case let .variable(name, expression):
                compile(variable: name, expression: expression)
            case let .flow(name, expression, drains, fills):
                compile(flow: name, expression: expression, drains: drains, fills: fills)
            case let .output(names):
                compile(output: names)
            case .model:
                fatalError("Got model node, expected statement node.")
            }
        }
        
        for (flow, name) in fillLinks {
            guard let target = model[name] else {
                fatalError("Unknown target '\(name)' for flow '\(flow.name)'")
            }
            model.connectFlow(from: flow, to: target)
        }

        for (flow, name) in drainLinks {
            guard let origin = model[name] else {
                fatalError("Unknown origin '\(name)' for flow '\(flow.name)'")
            }
            model.connectFlow(from: origin, to: flow)
        }
        
        for (node, name) in parameterLinks {
            guard let origin = model[name] else {
                fatalError("Unknown parameter '\(name)' in node '\(node.name)'")
            }
            
            model.connect(from: origin, to: node)
        }
        
        for name in output {
            if model[name] == nil {
                fatalError("Unknown node for output: \(name)")
            }
        }
    }
    

    
}
