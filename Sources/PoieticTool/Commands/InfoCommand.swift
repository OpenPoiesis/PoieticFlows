//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 30/06/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct Info: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Get information about the design")
        @OptionGroup var options: Options

        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            let design = try env.open()
            let frame = design.currentFrame
            
            let items: [(String?, String?)] = [
                ("Design", env.url.relativeString),
                (nil, nil),
                ("Current frame ID", "\(frame.id)"),
                ("Frame object count", "\(frame.snapshots.count)"),
                ("Total snapshot count", "\(design.validatedSnapshots.count)"),

                (nil, nil),
                ("Graph", nil),
                ("Nodes", "\(frame.nodes.count)"),
                ("Edges", "\(frame.edges.count)"),

                (nil, nil),
                ("History", nil),
                ("History frames", "\(design.versionHistory.count)"),
                ("Undoable frames", "\(design.undoableFrames.count)"),
                ("Redoable frames", "\(design.redoableFrames.count)"),
            ]
            
            let formattedItems = formatLabelledList(items)
            
            for item in formattedItems {
                print(item)
            }
            
        }
    }
}

