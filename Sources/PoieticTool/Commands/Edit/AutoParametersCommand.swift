//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct AutoParameters: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "auto-parameters",
                abstract: "Automatically connect parameter nodes: connect required, disconnect unused"
            )

        @OptionGroup var options: Options

        @Flag(name: [.customLong("verbose"), .customShort("v")],
                help: "Print created and removed edges")
        var verbose: Bool = false

        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            let design = try env.open()
            let frame = design.deriveFrame()

            let result = try autoConnectParameters(frame)
            
            if verbose {
                for info in result.added {
                    print("Connected parameter \(info.parameterName) (\(info.parameterID)) to \(info.targetName ?? "(unnamed)") (\(info.targetID)), edge: \(info.edgeID)")
                }
                for info in result.removed {
                    print("Disconnected parameter \(info.parameterName) (\(info.parameterID)) from \(info.targetName ?? "(unnamed)") (\(info.targetID)), edge: \(info.edgeID)")
                }
            }

            try env.accept(frame)
            try env.close()
            
            if result.added.count + result.removed.count > 0 {
                print("Added \(result.added.count) edges and removed \(result.removed.count) edges.")
            }
            else {
                print("All parameter connections seem to be ok.")
            }
        }
    }

}
