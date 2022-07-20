//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 06/06/2022.
//

/// Captured state of the simulation.
///
/// The structure contains collection of values of the nodes at a particular
/// step of the simulation.
///
public class SimulationState: CustomStringConvertible {
    // FIXME: WARNING: The state of flows is corrupted in simulation.step()
    /// The step of the simulation at which the state was captured.
    public let step: Int
    
    // FIXME: Use object IDs not names
     
    /// Values of the nodes. The keys are node names, the values are numerical
    /// values of the nodes.
    ///
    var values: [ExpressionNode:Double] = [:]

    var variables: [String:Double] {
        Dictionary(uniqueKeysWithValues:
                    values.map { (node, value) in (node.name, value) }
        )
    }
    // TODO: Change keys to be OIDs not names to be resistant to node renaming.
    
    /// Create an empty simulation state with a reference to a given step.
    init(step: Int) {
        self.step = step
    }
    
    
    /// Get or set a value of a node.
    public subscript(node: ExpressionNode) -> Double? {
        get {
            return values[node]
        }
        set(value) {
            guard let value = value else {
                fatalError("Value for simulation state should not be nil")
            }
            values[node, default: 0] = value
        }
    }
    /// Get a value of a node with given name.
    // TODO: This is just a convenience
    public subscript(name: String) -> Double? {
        get {
            return variables[name]
        }
    }
    
    public var description: String {
        return variables.description
    }
}

public class StateDelta {
}
