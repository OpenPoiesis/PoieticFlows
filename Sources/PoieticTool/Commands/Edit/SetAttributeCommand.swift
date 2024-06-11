//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

// TODO: Add import from CSV for multiple attributes and objects
// TODO: Add import from JSON for multiple attributes and objects

extension PoieticTool {
    struct SetAttribute: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "set",
                abstract: "Set an attribute value"
            )

        @OptionGroup var options: Options

        @Argument(help: "ID of an object to be modified")
        var reference: String

        @Argument(help: "Attribute to be set")
        var attributeName: String

        @Argument(help: "New attribute value")
        var value: String

        
        mutating func run() throws {
            let design = try openDesign(options: options)
            let frame = design.currentFrame
            
            guard let object = frame.object(stringReference: reference) else {
                throw ToolError.unknownObject(reference)
            }

            let newFrame: MutableFrame = design.deriveFrame(original: frame.id)

            let mutableObject = newFrame.mutableObject(object.id)

            try setAttributeFromString(object: mutableObject,
                                       attribute: attributeName,
                                       string: value)
            
            try acceptFrame(newFrame, in: design)

            try closeDesign(design: design, options: options)
            print("Property set in \(reference): \(attributeName) = \(value)")
        }
    }

}

