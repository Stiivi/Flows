//
//  Simulator.swift
//  
//
//  Created by Stefan Urbanek on 26/05/2022.
//


/// Simulation state

public class Simulator {
    public let model: Model
    public let compiledModel: CompiledModel
    public var history: [SimulationState] = []
    
    var last: SimulationState? { history.last }
    
    public init(model: Model) {
        self.model = model
        do {
            let compiler = Compiler(model: model)
            try self.compiledModel = compiler.compile()
        }
        catch {
            fatalError("Model compilation error: \(error)")
        }
    }
    
    /// Runs the simulation for given number of steps and return last state
    /// of the simulation.
    ///
    public func run(steps: Int) -> SimulationState {
        guard steps > 0 else {
            fatalError("Number of simulation steps should be > 0")
        }
        
        // Initialise state
        if history.isEmpty {
            initialize()
        }
        
        for t in 1...steps {
            let state: SimulationState
            state = step(t)
            history.append(state)
        }
        return last!
    }
    
    /// Initialize the simulation
    func initialize() {
        let state = SimulationState()
        
        for node in compiledModel.sortedNodes {
            do {
                state.values[node.name] = try evaluate(node: node, state: state)
            }
            catch {
                fatalError("Evaluation failed: \(error)")
            }
        }
        history.removeAll()
        history.append(state)
    }
    
    func evaluate() -> SimulationState {
        let state = SimulationState()
        
        for node in compiledModel.sortedNodes {
            do {
                state.values[node.name] = try evaluate(node: node, state: last!)
            }
            catch {
                fatalError("Evaluation failed: \(error)")
            }
        }
        
        return state
    }
    
    func evaluate(node: CompiledExpressionNode, state: SimulationState) throws -> Float{
        let evaluator = NumericExpressionEvaluator()
        var functions: [String:FunctionProtocol] = [:]
        
        for function in allBuiltinFunctions {
            functions[function.name] = function
        }
        evaluator.functions = functions
        
        for (key, value) in state.values {
            evaluator.variables[key] = .float(value)
        }

        let value = try evaluator.evaluate(node.expression)
        return value!.floatValue()!
    }
    
    func step(_ t: Int) -> SimulationState {
        let newState = evaluate()
        
        for stock in model.stocks {
            var delta: Float = 0
            
            for inflow in model.inflows(stock) {
                delta += last![inflow.name]!
            }
            
            for outflow in model.outflows(stock) {
                delta -= last![outflow.name]!
            }
            
            newState.values[stock.name]! = last![stock.name]! + delta
        }
        return newState
    }
}
