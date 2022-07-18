//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 06/06/2022.
//

import ArgumentParser
import Flows
import Foundation

func coalesceURL(_ source: String) -> URL {
    guard let testURL = URL(string: source) else {
        fatalError("Invalid resource reference: \(source)")
    }
    
    let sourceURL: URL

    if testURL.scheme == nil {
        sourceURL = URL(fileURLWithPath: source)
    }
    else {
        sourceURL = testURL
    }
    return sourceURL
}

// The Command
// ------------------------------------------------------------------------
// TODO: Change current default command to "run" command
// TODO: Add 'graph' command to create graph output
// TODO: Add 'explain' command to display how the model is executed
// TODO: Add CSV options

struct Flows: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Flows – dynamical systems simulator",
        subcommands: [
            Run.self,
            WriteDOT.self,
        ],
        defaultSubcommand: Run.self
    )
}

Flows.main()
