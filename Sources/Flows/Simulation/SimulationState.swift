//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 06/06/2022.
//

import Foundation

/// Captured state of the simulation.
///
/// The structure contains collection of values of the nodes at a particular
/// step of the simulation.
///
public class SimulationState {
    /// The step of the simulation at which the state was captured.
    public let step: Int
    
    /// Values of the nodes. The keys are node names, the values are numerical
    /// values of the nodes.
    ///
    var values: [String:Double] = [:]
    // TODO: Change keys to be OIDs not names to be resistant to node renaming.
    
    /// Create an empty simulation state with a reference to a given step.
    init(step: Int) {
        self.step = step
    }
    
    
    /// Get a value of a node with given name.
    public subscript(name: String) -> Double? {
        get {
            return values[name]
        }
    }
}
