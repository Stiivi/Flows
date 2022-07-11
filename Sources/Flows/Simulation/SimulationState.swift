//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 06/06/2022.
//

import Foundation

public class SimulationState {
    public let step: Int
    var values: [String:Double] = [:]
    
    init(step: Int) {
        self.step = step
    }
    
    public subscript(name: String) -> Double? {
        get {
            return values[name]
        }
    }
}
