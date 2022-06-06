//
//  Simulator.swift
//  
//
//  Created by Stefan Urbanek on 26/05/2022.
//


/// Simulation state
public class SimulationState {
    var values: [String:Float] = [:]
    
    public subscript(name: String) -> Float? {
        get {
            return values[name]
        }
    }
}

public class Simulator {
    public let model: Model
    public let compiledModel: CompiledModel
    public var history: [SimulationState] = []
    
    var last: SimulationState? { history.last }
    
    init(model: Model) {
        self.model = model
        do {
            try self.compiledModel = model.compile()
        }
        catch {
            fatalError("Model compilation error: \(error)")
        }
    }
    
    /// Runs the simulation for given number of steps and return last state
    /// of the simulation.
    ///
    func run(steps: Int) -> SimulationState {
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
        
        for node in compiledModel.nodes {
            do {
                state.values[node.name] = try node.evaluate(state: state)
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
        
        for node in model.nodes {
            do {
                state.values[node.name] = try node.evaluate(state: last!)
            }
            catch {
                fatalError("Evaluation failed: \(error)")
            }
        }
        
        return state
    }
    
    func step(_ t: Int) -> SimulationState {
        let newState = evaluate()
        
        for container in model.containers {
            var delta: Float = 0
            
            for inflow in model.inflows(container) {
                delta += last![inflow.name]!
            }
            
            for outflow in model.outflows(container) {
                delta -= last![outflow.name]!
            }
            
            newState.values[container.name]! = last![container.name]! + delta
        }
        return newState
    }
}
