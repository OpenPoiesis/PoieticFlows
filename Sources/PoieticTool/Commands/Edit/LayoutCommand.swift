//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 19/10/2023.
//

import ArgumentParser
import PoieticCore
import PoieticFlows
import RealModule

enum LayoutType: String, CaseIterable, ExpressibleByArgument{
    case circle
//    case forceDirected
    
    var defaultValueDescription: String { "circle" }
    
    static var allValueStrings: [String] {
        LayoutType.allCases.map { "\($0)" }
    }
}


extension PoieticTool {
    struct Layout: ParsableCommand {
        static var configuration
            = CommandConfiguration(
                abstract: "Lay out objects"
            )

        @OptionGroup var options: Options

        @Option
        var layout: LayoutType = .circle

        @Argument(help: "IDs of objects to be laid out. If not specified, then lay out all.")
        var references: [String] = []
        
        mutating func run() throws {
            let memory = try openMemory(options: options)
            let frame = memory.deriveFrame()
            
            var objects: [ObjectSnapshot] = []
            if references.isEmpty {
                objects = frame.graph.nodes.map { $0.snapshot }
            }
            else {
                for ref in references {
                    guard let object = frame.object(stringReference: ref) else {
                        throw ToolError.unknownObject(ref)
                    }
                    objects.append(object)
                }
            }
            let center = Point(100.0, 100.0)
            let radius: Double = 100.0
            var angle: Double = 0.0
            let step: Double = (2 * Double.pi) / Double(objects.count)
            
            for obj in objects {
                let obj = frame.mutableObject(obj.id)
                let position = Point(center.x + radius * Double.cos(angle),
                                     center.y + radius * Double.sin(angle))
                if obj.components.has(PositionComponent.self) {
                    obj[PositionComponent.self]!.position = position
                }
                else {
                    let component = PositionComponent(position)
                    obj.components.set(component)
                }
                angle += step
            }
            
            try acceptFrame(frame, in: memory)
            try closeMemory(memory: memory, options: options)

//            print("Current frame ID: \(memory.currentFrame.id)")
        }
    }
}
