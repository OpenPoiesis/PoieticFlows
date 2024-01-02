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
    struct SetAttribute: ParsableCommand {
        // TODO: Add import from CSV with format: id,attr,value
        static var configuration
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
            let memory = try openMemory(options: options)
            let frame = memory.currentFrame
            
            guard let object = frame.object(stringReference: reference) else {
                throw ToolError.unknownObject(reference)
            }

            let newFrame: MutableFrame = memory.deriveFrame(original: frame.id)

            let mutableObject = newFrame.mutableObject(object.id)

            try setAttributeFromString(object: mutableObject,
                                       attribute: attributeName,
                                       string: value)
            
            try acceptFrame(newFrame, in: memory)

            try closeMemory(memory: memory, options: options)
            print("Property set in \(reference): \(attributeName) = \(value)")
//            print("Current frame ID: \(memory.currentFrame.id)")
        }
    }

}

