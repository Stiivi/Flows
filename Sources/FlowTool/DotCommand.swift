//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 17/07/2022.
//

import SystemPackage

import Flows
import ArgumentParser
import Graph

let DefaultDOTStyle = DotStyle(
    nodes: [
        DotNodeStyle(predicate: AnyNodePredicate(),
                     attributes: [
                        "labelloc": "b",
                     ]),
        DotNodeStyle(predicate: LabelPredicate(all: "Flow"),
                     attributes: [
                        "shape": "ellipse",
                        "style": "bold",

                     ]),
        DotNodeStyle(predicate: LabelPredicate(all: "Stock"),
                     attributes: [
                        "style": "bold",
                        "shape": "box",
                     ]),
        DotNodeStyle(predicate: LabelPredicate(all: "Transform"),
                     attributes: [
                        "shape": "ellipse",
                        "style": "dotted",
                     ]),
    ],
    links: [
        DotLinkStyle(predicate: LabelPredicate(all: "flow"),
                     attributes: [
                        "shape": "ellipse",
                        "style": "bold",
                        "color": "blue",
                        "dir": "both",
                     ]),
        DotLinkStyle(predicate: LabelPredicate(all: "drains"),
                     attributes: [
                        "arrowhead": "none",
                        "arrowtail": "inv",
                     ]),
        DotLinkStyle(predicate: LabelPredicate(all: "fills"),
                     attributes: [
                        "arrowhead": "normal",
                        "arrowtail": "none",
                     ]),
        DotLinkStyle(predicate: LabelPredicate(all: "parameter"),
                     attributes: [
                        "arrowhead": "open",
                        "color": "red",
                     ]),
    ]
)

extension Flows {
    struct WriteDOT: ParsableCommand {
        static var configuration
            = CommandConfiguration(abstract: "Write a DOT file")

        @Option(name: [.long, .customShort("n")],
                help: "Name of the graph in the output file")
        var name = "output"

//        @OptionGroup var options: Options
        @Option(name: [.long, .customShort("o")],
                help: "Path to a DOT file where the output will be written.")
        var output: String = "output.dot"

        @Argument(help: "Name of a model file (path or URL)")
        var source: String

        mutating func run() throws {

            let model: Model
            
            do {
                let result = try modelFromFile(path: FilePath(source))
                model = result.model
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
                throw ExitCode(1)
            }
            
            let outputPath = FilePath(output)
           
            let exporter = DotExporter(path: outputPath,
                                       name: name,
                                       labelAttribute: "name",
                                       style: DefaultDOTStyle)

            // TODO: Allow export of a selection
            try exporter.export(nodes: Array(model.graph.nodes),
                                links: Array(model.graph.links))
        }
    }
}


