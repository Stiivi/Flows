//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 06/06/2022.
//

import Foundation

public class SimulationState {
    var values: [String:Float] = [:]
    
    public subscript(name: String) -> Float? {
        get {
            return values[name]
        }
    }
}
