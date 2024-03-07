//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 30/06/2023.
//

import ArgumentParser
import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct Info: ParsableCommand {
        static var configuration
            = CommandConfiguration(abstract: "Get information about the design")
        @OptionGroup var options: Options

        mutating func run() throws {
            let memory = try openMemory(options: options)
            let frame = memory.currentFrame
            let graph = frame.graph
            
            // At this point the URL is assumed to be well formed, otherwise
            // we would get an error above.
            //
            let url = try! databaseURL(options: options)
            
            let solverList = Solver.registeredSolverNames.joined(separator: ", ")
            let functionList = PoieticFlows.BuiltinFunctions.map {
                $0.name
            }.joined(separator: ", ")
            
            
            let items: [(String?, String?)] = [
                ("Available solvers", solverList),
                ("Built-in functions", functionList),
                (nil, nil),
                ("Design database", url.relativeString),
                (nil, nil),
                ("Current frame ID", "\(frame.id)"),
                ("Frame object count", "\(frame.snapshots.count)"),
                ("Total snapshot count", "\(memory.validatedSnapshots.count)"),

                (nil, nil),
                ("Graph", nil),
                ("Nodes", "\(graph.nodes.count)"),
                ("Edges", "\(graph.edges.count)"),

                (nil, nil),
                ("History", nil),
                ("History frames", "\(memory.versionHistory.count)"),
                ("Undoable frames", "\(memory.undoableFrames.count)"),
                ("Redoable frames", "\(memory.redoableFrames.count)"),
            ]
            
            let formattedItems = formatLabelledList(items)
            
            for item in formattedItems {
                print(item)
            }
            
        }
    }
}

