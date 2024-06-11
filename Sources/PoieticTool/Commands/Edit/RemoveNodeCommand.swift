//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

// TODO: Add possibility of using multiple references

extension PoieticTool {
    struct Remove: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                abstract: "Remove an object – a node or a connection"
            )

        @OptionGroup var options: Options

        @Argument(help: "ID of an object to be removed")
        var reference: String

        
        mutating func run() throws {
            let design = try openDesign(options: options)
            let frame = design.deriveFrame()
            
            guard let object = frame.object(stringReference: reference) else {
                throw ToolError.unknownObject(reference)
            }

            let removed = frame.removeCascading(object.id)
            try acceptFrame(frame, in: design)
            try closeDesign(design: design, options: options)

            print("Removed object: \(object.id)")
            if !removed.isEmpty {
                let list = removed.map { String($0) }.joined(separator: ", ")
                print("Removed cascading: \(list)")
            }
//            print("Current frame ID: \(design.currentFrame.id)")
        }
    }
}
