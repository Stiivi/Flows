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
/// - Note: Currently we are not using any solver. The simulation is just step
/// based.
///
/// - ToDo: Add solvers: Euler, RK and RK4
///
public class Simulator {
    // TODO: Add solvers
    
    /// Compiled version of the model.
    public let compiledModel: CompiledModel

    /// Model to be simulated.
    ///
    public var model: Model { compiledModel.model }

    /// History of captured values of the simulation.
    public var history: [SimulationState] = []
    
    /// Current step of the simulation.
    public var currentStep: Int = 0
    
    /// State of the simulation at the previous step.
    var current: SimulationState { history.last! }
    
    /// Creates a new simulator with given model.
    ///
    public init(compiledModel: CompiledModel) {
        // FIXME: Do not compile here. Get directly a compiled model.
        self.compiledModel = compiledModel
    }
   
    /// Convenience initialiser for a valid model.
    ///
    /// - Note: The model is expected to be valid and compilable, otherwise the
    /// method fails.
    ///
    public convenience init(model: Model) {
        let compiler = Compiler(model: model)
        let compiledModel: CompiledModel
        
        do {
            compiledModel = try compiler.compile()
        }
        catch {
            fatalError("Model compilation failed: \(error)")
        }
        
        self.init(compiledModel: compiledModel)
    }
    
    /// Runs the simulation for given number of steps and return last state
    /// of the simulation.
    ///
    @discardableResult
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
        return current
    }
    
    /// Initialise the simulation
    ///
    /// Each expression node (stock, flow, auxiliary) in the model is evaluated
    /// to its value.
    ///
    /// The computed values are store in the history as initial value.
    ///
    func initialize() {
        let state = SimulationState(step: currentStep)
        history.removeAll()
        
        for node in compiledModel.sortedNodes {
            do {
                state.values[node.node] = try evaluate(node: node, state: state)
            }
            catch {
                fatalError("Evaluation failed: \(error)")
            }
        }
        history.append(state)
        currentStep = 0
    }
    
    /// Reset the simulation
    ///
    /// - Note: This method just calls `initialize()`. It is here only for
    /// semantic reasons at this moment. In the caller, it marks the difference between
    /// initialisation and actual reset of the simulation.
    ///
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
        
        // FIXME: This is not quite correct, we should consider aux and flows only
        for node in compiledModel.sortedNodes {
            do {
                state[node.node] = try evaluate(node: node, state: current)
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
        
        for (name, value) in state.variables {
            evaluator.variables[name] = .double(value)
        }

        let value = try evaluator.evaluate(node.expression)
        return value!.doubleValue()!
    }
    
    /// Perform one step of the simulation.
    ///
    /// - ToDo: This is preliminary implementation of a simulation step.
    ///
    func step() -> SimulationState {
        // FIXME: IMPORTANT! This is corrupting the current state, add "estimated" state instead
        currentStep += 1
        
        let newState = evaluate()

        for stock in model.stocks {
            var totalInflow: Double = 0.0
            var totalOutflow: Double = 0.0
            
            if stock.allowsNegative {
                for inflow in stock.inflows {
                    totalInflow += current[inflow]!
                }
                
                for outflow in stock.outflows {
                    totalOutflow += current[outflow]!
                }
            }
            else {
                // We have:
                // - current stock values
                // - expected flow values
                // We need:
                // - get actual flow values based on stock non-negative constraint
                
                // TODO: Simplify this
                // TODO: Use Flow.priority (once the attribute is added)
                // TODO: Add other ways of draining non-negative stocks, not only priority based
                
                // We are looking at a stock, and we know expected inflow and
                // expected outflow. Outflow must be less or equal to the
                // expected inflow plus current state of the stock.
                for inflow in stock.inflows {
                    totalInflow += current[inflow]!
                }

                // Maximum outflow that we can drain from the stock. It is the
                // current value of the stock with aggregate of all inflows.
                //
                var availableOutflow: Double = current[stock]! + totalInflow
                
                // We assume that outflows get their share by their priority
                // (currently arbitrary, as provided by the model).
                for outflow in stock.outflows {
                    // Assumed outflow value can not be greater than what we
                    // have in the stock. We either take it all or whatever is
                    // expected to be drained.
                    //
                    let actualOutflow = min(availableOutflow, current[outflow]!)
                    
                    totalOutflow += actualOutflow
                    // We drain the stock
                    availableOutflow -= actualOutflow
                    
                    // Adjust the flow value to the value actually drained,
                    // so we do not fill another stock with something that we
                    // did not drain.
                    //
                    // FIXME: We are changing the current state, we should be changing some "estimated state"
                    current[outflow] = actualOutflow

                    assert(current[outflow]! >= 0.0)
                }
            }

            let delta = totalInflow - totalOutflow
            newState[stock] = current[stock]! + delta
        }
        return newState
    }
}
