//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 19/10/2023.
//

@preconcurrency import ArgumentParser
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
        static let configuration
            = CommandConfiguration(
                abstract: "Lay out objects"
            )

        @OptionGroup var options: Options

        @Option
        var layout: LayoutType = .circle

        @Argument(help: "IDs of objects to be laid out. If not specified, then lay out all.")
        var references: [String] = []
        
        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            let design = try env.open()
            let frame = design.deriveFrame()
            
            var objects: [ObjectSnapshot] = []
            if references.isEmpty {
                objects = frame.nodes.map { $0.snapshot }
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
                obj.position = position
                angle += step
            }
            
            try env.accept(frame)
            try env.close()
        }
    }
}
