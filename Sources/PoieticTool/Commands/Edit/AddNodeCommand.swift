//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

// TODO: Add option to use foreign object JSON representation
// TODO: Add option to use JSON attributes
// TODO: Add option to specify object ID

extension PoieticTool {
    struct Add: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "add",
                abstract: "Create a new node or an unstructured object",
                usage: """
Create a new node:

poietic add Stock name=account formula=100
poietic add Flow name=expenses formula=50
"""
            )

        @OptionGroup var options: Options

        @Argument(help: "Type of the object to be created")
        var typeName: String

        @Argument(help: "Attributes to be set in form 'attribute=value'")
        var attributeAssignments: [String] = []
        
        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            let design = try env.open()
            let frame = design.deriveFrame()
            
            guard let type = FlowsMetamodel.objectType(name: typeName) else {
                throw ToolError.unknownObjectType(typeName)
            }

            let id: ObjectID
            
            switch type.structuralType {
            case .unstructured:
                id = frame.create(type)
            case .node:
                id = frame.createNode(type)
            default:
                throw ToolError.structuralTypeMismatch("node or unstructured",
                                                       type.structuralType.rawValue)
            }
            
            let object = frame[id]
            
            for item in attributeAssignments {
                guard let split = parseValueAssignment(item) else {
                    throw ToolError.invalidAttributeAssignment(item)
                }
                let (name, stringValue) = split
                try setAttributeFromString(object: object,
                                           attribute: name,
                                           string: stringValue)

            }

            try env.accept(frame)
            try env.close()

            print("Created node \(id)")
        }
    }

}
