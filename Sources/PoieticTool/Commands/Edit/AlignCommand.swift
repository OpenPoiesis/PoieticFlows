//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows
import RealModule

// TODO: We need bounding box
// TODO: For bounding box, we need "VisualLanguage" metadata or something like that, related to Metamodel

enum AlignmentMode: String, CaseIterable, ExpressibleByArgument {
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
    
    var defaultValueDescription: String { "left" }
    
    static var allValueStrings: [String] {
        AlignmentMode.allCases.map { "\($0.rawValue)" }
    }
}

extension PoieticTool {
    struct Align: ParsableCommand {
        static let configuration
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
            let env = try ToolEnvironment(location: options.designLocation)
            let design = try env.open()
            let frame = design.deriveFrame()
            
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
            
            try env.accept(frame)
            try env.close()
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
            object.position = Point(x:current.x, y:reference.y)
        }
    case .alignCenterVertical, .alignLeft, .alignRight:
        for (object, current) in items {
            object.position = Point(x:reference.x, y:current.y)
        }
    case .offsetHorizontal:
        // FIXME: Spacing requires bounding box
        var x = reference.x
        
        for (object, current) in items {
            object.position = Point(x:x, y:current.y)
            x += spacing
        }
    case .offsetVertical:
        // FIXME: Spacing requires bounding box
        var y = reference.y
        
        for (object, current) in items {
            object.position = Point(x: current.x, y: y)
            y += spacing
        }
    case .spreadHorizontal:
        let last = items.last!
        let spacing = last.1.x - reference.x
        var x = reference.x
        
        for (object, current) in items {
            object.position = Point(x:x, y:current.y)
            x += spacing
        }

    case .spreadVertical:
        let last = items.last!
        let spacing = last.1.y - reference.y
        var y = reference.y
        
        for (object, current) in items {
            object.position = Point(x:current.x, y:y)
            y += spacing
        }
    }
}
