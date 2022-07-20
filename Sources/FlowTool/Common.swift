//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 21/07/2022.
//

import SystemPackage
import Flows


/// Loads a model from file
///
func modelFromFile(path: FilePath) throws -> (model: Model, output: [String]) {
    let sourceString = try String(contentsOf: path)

    let model = Model()
    let compiler = ModelLanguageCompiler(model: model)
    
    try compiler.compile(source: sourceString)
    
    // TODO: Use some nicer result
    return (model: model, output: compiler.output)
}
