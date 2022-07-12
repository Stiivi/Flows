//
//  Simulator.swift
//  
//
//  Created by Stefan Urbanek on 26/05/2022.
//


/// An object that performs the simulation.
///
/// Simulator is an object that given a valid model performs an iterative
/// simulation of the dynamical system described by the model.
///
public class Simulator {
    /// Model to be simulated.
    ///
    public let model: Model
    
    /// Compiled version of the model.
    public let compiledModel: CompiledModel
    
    /// History of captured values of the simulation.
    public var history: [SimulationState] = []
    
    /// Current step of the simulation.
    public var currentStep: Int = 0
    
    /// Last state of the simulation.
    var last: SimulationState? { history.last }
    
    /// Creates a new simulator with given model.
    ///
    public init(model: Model) {
        // FIXME: Do not compile here. Get directly a compiled model.
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
        
        for _ in 1...steps {
            let state: SimulationState
            currentStep += 1
            state = step()
            history.append(state)
        }
        return last!
    }
    
    /// Initialize the simulation
    func initialize() {
        let state = SimulationState(step: currentStep)
        
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
        currentStep = 0
    }
    
    public func reset() {
        // TODO: Unite with initialize()
        // NOTE: This is here for now, because there are multiple pathways of resetting
        //       the simulation. Semantically they are different, functionally
        //       they are the same at this moment.
        initialize()
    }

    
    /// Evaluate the model based on the last state and returns a new state.
    ///
    func evaluate() -> SimulationState {
        let state = SimulationState(step: currentStep)
        
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
    
    /// Evaluate a node within the context of a simulation state.
    ///
    func evaluate(node: CompiledExpressionNode, state: SimulationState) throws -> Double {
        let evaluator = NumericExpressionEvaluator()
        var functions: [String:FunctionProtocol] = [:]
        
        for function in AllBuiltinFunctions {
            functions[function.name] = function
        }
        evaluator.functions = functions
        
        for (key, value) in state.values {
            evaluator.variables[key] = .double(value)
        }

        let value = try evaluator.evaluate(node.expression)
        return value!.doubleValue()!
    }
    
    /// Perform one step of the simulation.
    /// 
    func step() -> SimulationState {
        currentStep += 1
        
        let newState = evaluate()
        
        for stock in model.stocks {
            var delta: Double = 0
            
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
