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
    let model: Model
    var history: [SimulationState] = []
    
    var last: SimulationState? { history.last }
    
    init(model: Model) {
        self.model = model
    }
    
    /// Runs the simulation for given number of steps and return last state
    /// of the simulation.
    ///
    func run(steps: Int) -> SimulationState {
        // Initialise state

        var state: SimulationState
        
        if let lastState = last {
            state = lastState
        }
        else {
            state = evaluate()
            history.append(state)
        }

        print("0: \(state)")
        for t in 1...steps {
            state = step(t)
            print("\(t): \(state)")
            history.append(state)
        }
        return state
    }
    
    func evaluate() -> SimulationState {
        let state = SimulationState()
        
        for node in model.nodes {
            state.values[node.name] = node.evaluate(state: state)
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
