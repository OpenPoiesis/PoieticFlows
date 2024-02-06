//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

import ArgumentParser
import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct AutoParameters: ParsableCommand {
        static var configuration
            = CommandConfiguration(
                commandName: "auto-parameters",
                abstract: "Automatically connect parameter nodes: connect required, disconnect unused"
            )

        @OptionGroup var options: Options

        @Flag(name: [.customLong("verbose"), .customShort("v")],
                help: "Print created and removed edges")
        var verbose: Bool = false

        mutating func run() throws {
            let memory = try openMemory(options: options)
            let frame = memory.deriveFrame()
            let view = StockFlowView(frame)
            var addedCount = 0
            var removedCount = 0
            
            let builtinNames: Set<String> = Set(FlowsMetamodel.variables.map {
                $0.name
            })
            
            for target in view.simulationNodes {
                guard let expression = try target.parsedExpression() else {
                    continue
                }
                let allNodeVars: Set<String> = Set(expression.allVariables)
                let required = Array(allNodeVars.subtracting(builtinNames))
                let params = view.parameters(target.id, required: required)
                
                for (name, status) in params {
                    switch status {
                    case .missing:
                        // Find missing parameter
                        let parameterID = frame.object(named: name)!.id
                        let edge = frame.createEdge(Metamodel.Parameter,
                                                    origin: parameterID,
                                                  target: target.id)
                        if verbose {
                            print("Connected parameter\(name) (\(parameterID)) to \(target.name!) (\(target.id)), edge: \(edge)")
                        }
                        addedCount += 1
                    case let .unused(node, edge):
                        frame.remove(edge: edge)
                        if verbose {
                            print("Disconnected parameter \(name) (\(node)) from \(target.name!) (\(target.id)), edge: \(edge)")
                        }
                        removedCount += 1
                    case .used:
                        continue
                    }
                }
            }

            if addedCount + removedCount > 0 {
                print("Added \(addedCount) edges and removed \(removedCount) edges.")
                try acceptFrame(frame, in: memory)
            }
            else {
                print("All parameter connections seem to be ok.")
            }
            try closeMemory(memory: memory, options: options)
            
//            print("Current frame ID: \(memory.currentFrame.id)")
        }
    }

}


