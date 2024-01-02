//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 11/01/2022.
//

import Foundation
import ArgumentParser
import PoieticCore
import PoieticFlows

// TODO: Merge with PrintCommand, use --format=id
extension PoieticTool {
    struct List: ParsableCommand {
        static var configuration
            = CommandConfiguration(abstract: "List all nodes and edges")
        @OptionGroup var options: Options

        enum ListType: String, CaseIterable, ExpressibleByArgument{
            case all = "all"
            case names = "names"
            case formulas = "formulas"
            case charts = "charts"
            var defaultValueDescription: String { "all" }
            
            static var allValueStrings: [String] {
                ListType.allCases.map { "\($0)" }
            }
        }
        
        @Argument(help: "What kind of list to show.")
        var listType: ListType = .all

        mutating func run() throws {
            let memory = try openMemory(options: options)
            
            if memory.isEmpty {
                throw CleanExit.message("The design memory is empty.")
            }
            
            switch listType {
            case .all:
                listAll(memory)
            case .names:
                listNames(memory)
            case .formulas:
                listFormulas(memory)
            case .charts:
                listCharts(memory)
            }
        }
        func listAll(_ memory: ObjectMemory) {
            let graph = memory.currentFrame.graph

            print("NODES:")
            let nodes = graph.nodes.sorted { left, right in
                left.id < right.id
            }
            for node in nodes {
                print("    \(node.snapshot.prettyDescription)")
            }

            print("EDGES:")
            let edges = graph.edges.sorted { left, right in
                left.id < right.id
            }
            for edge in edges {
                print("    \(edge.snapshot.prettyDescription)")
            }
        }
        
        func listNames(_ memory: ObjectMemory) {
            let frame = memory.currentFrame
            let names: [String] = frame.snapshots.compactMap { $0.name }
                .sorted { $0.lexicographicallyPrecedes($1)}
            
            for name in names {
                print(name)
            }
        }
        
        func listFormulas(_ memory: ObjectMemory) {
            let frame = memory.currentFrame
            var result: [String: String] = [:]
            
            for object in frame.snapshots {
                guard let name = object.name else {
                    continue
                }
                if let component: FormulaComponent = object[FormulaComponent.self] {
                    result[name] = component.expressionString
                }
                else if let component: GraphicalFunctionComponent = object[GraphicalFunctionComponent.self] {
                    result[name] = component.description
                }
            }
            
            let sorted = result.keys.sorted {
                $0.lexicographicallyPrecedes($1)
            }
            
            for name in sorted {
                print("\(name) = \(result[name]!)")
            }
        }
        
        func listCharts(_ memory: ObjectMemory) {
            let frame = memory.currentFrame
            let view = StockFlowView(frame.graph)
            
            let charts = view.charts
            
            let sorted = charts.sorted {
                ($0.node.name!).lexicographicallyPrecedes($1.node.name!)
            }
            
            for chart in sorted {
                let seriesStr = chart.series.map { $0.name! }
                    .joined(separator: " ")
                print("\(chart.node.name!): \(seriesStr)")
            }
        }

    }
}
