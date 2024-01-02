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
    struct Add: ParsableCommand {
        static var configuration
            = CommandConfiguration(
                commandName: "add",
                abstract: "Create a new node",
                usage: """
Create a new node:

poietic add Stock name=account formula=100
poietic add Flow name=expenses formula=50
"""
            )

        @OptionGroup var options: Options

        @Argument(help: "Type of the node to be created")
        var typeName: String

        @Argument(help: "Attributes to be set in form 'attribute=value'")
        var attributeAssignments: [String] = []
        
        mutating func run() throws {
            let memory = try openMemory(options: options)
            let frame = memory.deriveFrame()
            let graph = frame.mutableGraph
            
            guard let type = FlowsMetamodel.objectType(name: typeName) else {
                throw ToolError.unknownObjectType(typeName)
            }
            
            guard type.structuralType == .node else {
                throw ToolError.structuralTypeMismatch(StructuralType.node.rawValue,
                                                       type.structuralType.rawValue)
            }

            guard type.plane == .user else {
                throw ToolError.creatingSystemPlaneType(type.name)
            }
            
            let id = graph.createNode(type)
            let object = frame.object(id)
            
            for item in attributeAssignments {
                guard let split = parseValueAssignment(item) else {
                    throw ToolError.invalidAttributeAssignment(item)
                }
                let (name, stringValue) = split
                try setAttributeFromString(object: object,
                                           attribute: name,
                                           string: stringValue)

            }
            
            try acceptFrame(frame, in: memory)
            try closeMemory(memory: memory, options: options)

            print("Created node \(id)")
//            print("Current frame ID: \(memory.currentFrame.id)")
        }
    }

}
