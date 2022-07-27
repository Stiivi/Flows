//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 14/07/2022.
//


public struct ModelSourceError: Error {
    public let messages: [String]
}

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
        
        let statements = try parser.parseModel()
        try compile(statements: statements)
    }

    func compile(stock name: String, options: [String], expression: ExpressionAST) {
        // TODO: We are de-compiling here, since ExpressionNode has to way to provide expression directly (for reasons)
        let node = Stock(name: name, expression: expression.fullText)
        model.add(node)
        
        // FIXME: We have only one possible option now
        
        if options.count > 0 {
            let option = options[0]
            if option == "allowsnegative" {
                node.allowsNegative = true
            }
            else if option == "positive" {
                node.allowsNegative = false
            }
            else {
                print("ERROR: Unknown option: \(option)")
            }
        }
        
        let variables = Set(expression.variables)
        parameterLinks += variables.map { (node, $0) }
    }
    func compile(variable name: String, expression: ExpressionAST) {
        // TODO: We are de-compiling here, since ExpressionNode has to way to provide expression directly (for reasons)
        let node = Transform(name: name, expression: expression.fullText)
        model.add(node)

        let variables = Set(expression.variables)
        parameterLinks += variables.map { (node, $0) }
    }
    func compile(flow name: String, expression: ExpressionAST, drains: String?, fills: String?) {
        // TODO: We are de-compiling here, since ExpressionNode has to way to provide expression directly (for reasons)
        let node = Flow(name: name, expression: expression.fullText)
        model.add(node)
        if let drains = drains {
            drainLinks.append((node, drains))
        }
        if let fills = fills {
            fillLinks.append((node, fills))
        }

        let variables = Set(expression.variables)
        parameterLinks += variables.map { (node, $0) }
    }
    
    func compile(output names: [String]) {
        output = names
    }

    func compile(statements: [ModelAST]) throws {
        var errors: [String] = []

        for statement in statements {
            switch statement.kind {
            case let .stock(name, options, expression):
                compile(stock: name, options: options, expression: expression)
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
                errors.append("Unknown target '\(name)' for flow '\(flow.name)'")
                continue
            }
            model.connectFlow(from: flow, to: target)
        }

        for (flow, name) in drainLinks {
            guard let origin = model[name] else {
                errors.append("Unknown origin '\(name)' for flow '\(flow.name)'")
                continue
            }
            model.connectFlow(from: origin, to: flow)
        }
        
        for (node, name) in parameterLinks {
            guard let origin = model[name] else {
                errors.append("Unknown parameter '\(name)' in node '\(node.name)'")
                continue
            }
            
            model.connect(from: origin, to: node)
        }
        
        for name in output {
            if model[name] == nil {
                errors.append("Unknown node in output: '\(name)'")
            }
        }
        
        if !errors.isEmpty {
            throw ModelSourceError(messages: errors)
        }
    }
    
}
