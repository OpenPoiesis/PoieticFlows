//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 11/09/2023.
//

import PoieticCore

extension Trait {
    public static let Chart = Trait(
        name: "Chart",
        attributes: [
//            AttributeDescription(
//                name: "chartType",
//                type: .string,
//                abstract: "Chart type"),
        ]
    )
}

#if false
public struct ChartComponent: InspectableComponent {
    public static let trait = Trait.Chart
    
    public var value: Double

    public init() {
        self.value = 0
    }

    public func attribute(forKey key: PoieticCore.AttributeKey) -> PoieticCore.ForeignValue? {
        switch key {
        case "value": return ForeignValue(value)
        default: return nil
        }
    }
    
    public mutating func setAttribute(value: PoieticCore.ForeignValue, forKey key: PoieticCore.AttributeKey) throws {
        switch key {
        case "value": self.value = try value.doubleValue()
        default:
            throw AttributeError.unknownAttribute(name: key,
                                                  type: String(describing: type(of: self)))
        }
    }
}
#endif

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
    public var charts: [Chart] {
        let nodes = frame.filterNodes { $0.type === Chart }
        
        var charts: [PoieticFlows.Chart] = []
        for node in nodes {
            let hood = frame.hood(node.id,
                                  selector: NeighborhoodSelector(
                                    predicate: IsTypePredicate(ChartSeries),
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
