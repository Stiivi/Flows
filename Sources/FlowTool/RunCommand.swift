//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 17/07/2022.
//

import Flows
import ArgumentParser

extension Flows {
    struct Run: ParsableCommand {
        static var configuration
            = CommandConfiguration(abstract: "Run a model")

//        @OptionGroup var options: Options
        @Option(name: [.long, .customShort("s")],
                help: "Number of steps to run")
        var steps: Int = 10

        @Argument(help: "Name of a model file (path or URL)")
        var source: String

        mutating func run() throws {
            let sourceURL = coalesceURL(source)
            let sourceString: String

            sourceString = try String(contentsOf: sourceURL)

            let model = Model()
            let sourceCompiler = ModelLanguageCompiler(model: model)
            
            do {
                try sourceCompiler.compile(source: sourceString)
            }
            catch let error as ParseError {
                // TODO: Use stderr
                print("ERROR: \(error)")
                throw ExitCode(1)
            }
            catch let error as ModelSourceError {
                for message in error.messages {
                    print("ERROR: \(message)")
                }
            }
            
            let outputNodes = sourceCompiler.output
            
            let compiler = Compiler(model: model)
            let compiledModel: CompiledModel
            
            do {
                compiledModel = try compiler.compile()
            }
            catch let error as ModelCompilationError {
                for message in error.messages {
                    print("ERROR: \(message)")
                }
                throw ExitCode(1)
            }
            
    //         model.debugPrint()
            
            let simulator = Simulator(compiledModel: compiledModel)
            
            simulator.run(steps: steps)
            
            
            let headersLine = outputNodes.joined(separator: "\t")
            print("step\t\(headersLine)")

            for (i, state) in simulator.history.enumerated() {
                let values = outputNodes.map { state[$0]! }
                let valuesLine = values.map {String($0)}.joined(separator: "\t")
                let line = "\(i)\t\(valuesLine)"
                print(line)
            }
        }
    }
}


