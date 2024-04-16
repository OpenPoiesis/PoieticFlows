//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

import ArgumentParser
import PoieticCore
import PoieticFlows

// TODO: Allow setting attributes on creation

extension PoieticTool {
    struct NewConnection: ParsableCommand {
        static var configuration
            = CommandConfiguration(
                commandName: "connect",
                abstract: "Create a new connection (edge) between two nodes"
            )

        @OptionGroup var options: Options

        @Argument(help: "Type of the connection to be created")
        var typeName: String

        @Argument(help: "Reference to the connection's origin node")
        var origin: String

        @Argument(help: "Reference to the connection's target node")
        var target: String

        
        mutating func run() throws {
            let design = try openDesign(options: options)
            let frame = design.deriveFrame()
            let graph = frame
            
            guard let type = FlowsMetamodel.objectType(name: typeName) else {
                throw ToolError.unknownObjectType(typeName)
            }
            
            guard type.structuralType == .edge else {
                throw ToolError.structuralTypeMismatch(StructuralType.edge.rawValue,
                                                       type.structuralType.rawValue)
            }
            
            guard let originObject = frame.object(stringReference: self.origin) else {
                throw ToolError.unknownObject( self.origin)
            }
            
            guard let origin = Node(originObject) else {
                throw ToolError.nodeExpected(self.origin)

            }
            
            guard let targetObject = frame.object(stringReference: self.target) else {
                throw ToolError.unknownObject(self.target)
            }

            guard let target = Node(targetObject) else {
                throw ToolError.nodeExpected(target)

            }

            let id = graph.createEdge(type,
                                      origin: origin.id,
                                      target: target.id,
                                      components: [])
            
            try acceptFrame(frame, in: design)
            try closeDesign(design: design, options: options)

            print("Created edge \(id)")
//            print("Current frame ID: \(design.currentFrame.id)")
        }
    }

}


