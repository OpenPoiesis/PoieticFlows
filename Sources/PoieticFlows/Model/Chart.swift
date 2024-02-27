//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 11/09/2023.
//

import PoieticCore

// TODO: [EXPERIMENTAL] Make this a runtime component
/// Object representing a chart.
///
/// - ToDo: This is experimental.
///
public struct Chart {
    public let node: ObjectSnapshot
    public let series: [ObjectSnapshot]
    
    public init(node: ObjectSnapshot, series: [ObjectSnapshot]) {
        self.node = node
        self.series = series
    }
    
}

// TODO: This is unused
public struct ChartSeries {
    public let node: ObjectSnapshot
    var name: String { node.name! }
}

extension StockFlowView {
    // FIXME: [REFACTORING] Move to Compiler
    public var charts: [Chart] {
        let nodes = frame.filterNodes { $0.type === ObjectType.Chart }
        
        var charts: [PoieticFlows.Chart] = []
        for node in nodes {
            let hood = frame.hood(node.id,
                                  selector: NeighborhoodSelector(
                                    predicate: IsTypePredicate(ObjectType.ChartSeries),
                                    direction: .outgoing))
            let series = hood.nodes.map { $0.snapshot }
            let chart = PoieticFlows.Chart(node: node.snapshot,
                                           series: series)
            charts.append(chart)
        }
        return charts
    }

}

//public struct CompiledChart {
//    public let id: ObjectID
//    public let index: ValueIndex
//    public let series: [CompiledObject]
//}
