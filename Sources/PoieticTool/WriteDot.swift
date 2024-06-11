//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 27/06/2023.
//

import SystemPackage
import Foundation
@preconcurrency import ArgumentParser

import PoieticFlows
import PoieticCore

let DefaultDOTStyle = DotStyle(
    nodes: [
        DotNodeStyle(predicate: AnyPredicate(),
                     attributes: [
                        "labelloc": "b",
                     ]),
        DotNodeStyle(predicate: IsTypePredicate(ObjectType.Flow),
                     attributes: [
                        "shape": "ellipse",
                        "style": "bold",

                     ]),
        DotNodeStyle(predicate: IsTypePredicate(ObjectType.Stock),
                     attributes: [
                        "style": "bold",
                        "shape": "box",
                     ]),
        DotNodeStyle(predicate: IsTypePredicate(ObjectType.Auxiliary),
                     attributes: [
                        "shape": "ellipse",
                        "style": "dotted",
                     ]),
    ],
    edges: [
        DotEdgeStyle(predicate: IsTypePredicate(ObjectType.Drains),
                     attributes: [
                        "color": "blue:white:blue",
                        "arrowhead": "empty",
                        "arrowsize": "2",
                     ]),
        DotEdgeStyle(predicate: IsTypePredicate(ObjectType.Fills),
                     attributes: [
                        "color": "blue:white:blue",
                        "arrowhead": "empty",
                        "arrowsize": "2",
                     ]),
        DotEdgeStyle(predicate: IsTypePredicate(ObjectType.Parameter),
                     attributes: [
                        "arrowhead": "open",
                        "color": "red",
                     ]),
    ]
)


extension PoieticTool {
    struct WriteDOT: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Write a Graphviz DOT file.")

        @OptionGroup var options: Options
        
        @Option(name: [.long, .customShort("n")],
                help: "Name of the graph in the output file")
        var name = "output"

        @Option(name: [.long, .customShort("o")],
                help: "Path to a DOT file where the output will be written.")
        var output = "output.dot"

        @Option(name: [.long, .customShort("l")],
                help: "Node attribute that will be used as node label")
        var labelAttribute = "id"
        
        @Option(name: [.long, .customShort("m")],
                help: "Label used if the node has no label attribute")
        var missingLabel = "(none)"
        
        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            let design = try env.open()

            guard let testURL = URL(string: output) else {
                fatalError("Invalid resource reference: \(output)")
            }
            let outputURL: URL

            if testURL.scheme == nil {
                outputURL = URL(fileURLWithPath: output)
            }
            else {
                outputURL = testURL
            }

            let exporter = DotExporter(path: FilePath(outputURL.path),
                                       name: name,
                                       labelAttribute: labelAttribute,
                                       missingLabel: missingLabel,
                                       style: DefaultDOTStyle)

            // TODO: Allow export of a selection
            let graph = design.currentFrame.graph
            try exporter.export(graph: graph)
        }
    }
}
