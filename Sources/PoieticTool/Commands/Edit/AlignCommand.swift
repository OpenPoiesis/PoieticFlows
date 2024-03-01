//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

import ArgumentParser
import PoieticCore
import PoieticFlows
import RealModule

enum AlignmentMode: String, CaseIterable, ExpressibleByArgument{
    case alignLeft = "left"
    case alignCenterHorizontal = "center-horizontal" // center-horizontal
    case alignRight = "right"

    case alignTop = "top"
    case alignCenterVertical = "center-vertical" // center-vertical
    case alignBottom = "bottom"

    case offsetHorizontal = "offset-horizontal"
    case offsetVertical = "offset-vertical"
    
    case spreadHorizontal = "spread-horizontal"
    case spreadVertical = "spread-vertical"
    
    var defaultValueDescription: String { "align" }
    
    static var allValueStrings: [String] {
        AlignmentMode.allCases.map { "\($0)" }
    }
}

extension PoieticTool {
    struct Align: ParsableCommand {
        static var configuration
            = CommandConfiguration(
                abstract: "Align objects on canvas"
            )

        @OptionGroup var options: Options

        @Argument(help: "Alignment mode")
        var mode: AlignmentMode

        @Option(help: "Spacing between objects")
        var spacing: Double = 10

        @Argument(help: "Objects to be aligned")
        var references: [String]
        
        mutating func run() throws {
            let memory = try openMemory(options: options)
            let frame = memory.deriveFrame()
            
            var objects: [ObjectSnapshot] = []
            
            for ref in references {
                guard let object = frame.object(stringReference: ref) else {
                    throw ToolError.unknownObject(ref)
                }
                objects.append(object)
            }

            align(objects: objects,
                  mode: mode,
                  spacing: spacing)
            
            try acceptFrame(frame, in: memory)
            try closeMemory(memory: memory, options: options)
        }
    }
}

func align(objects: [ObjectSnapshot], mode: AlignmentMode, spacing: Double) {
    let items: [(ObjectSnapshot, Point)] = objects.compactMap {
        if let position = $0.position {
            ($0, position)
        }
        else {
            nil
        }
    }
    guard let referenceTuple = items.first else {
        // Nothing to align
        return
    }
    let reference = referenceTuple.1
    
    // FIXME: Implement top, bottom, left and right once we have bounding box
    switch mode {
    case .alignCenterHorizontal, .alignTop, .alignBottom:
        for (object, current) in items {
            let newPosition = Point(
                x: current.x,
                y: reference.y
            )
            object.position = newPosition
        }
    case .alignCenterVertical, .alignLeft, .alignRight:
        for (object, current) in items {
            let newPosition = Point(
                x: reference.x,
                y: current.y
            )
            object.position = newPosition
        }
    case .offsetHorizontal:
        // FIXME: Spacing requires bounding box
        var x = reference.x
        
        for (object, current) in items {
            let newPosition = Point(
                x: x,
                y: current.y
            )
            object.position = newPosition
            x += spacing
        }
    case .offsetVertical:
        // FIXME: Spacing requires bounding box
        var y = reference.y
        
        for (object, current) in items {
            let newPosition = Point(
                x: current.x,
                y: y
            )
            object.position = newPosition
            y += spacing
        }
    case .spreadHorizontal:
        let last = items.last!
        let spacing = last.1.x - reference.x
        var x = reference.x
        
        for (object, current) in items {
            let newPosition = Point(
                x: x,
                y: current.y
            )
            object.position = newPosition
            x += spacing
        }

    case .spreadVertical:
        let last = items.last!
        let spacing = last.1.y - reference.y
        var y = reference.y
        
        for (object, current) in items {
            let newPosition = Point(
                x: current.x,
                y: y
            )
            object.position = newPosition
            y += spacing
        }
    }
}
