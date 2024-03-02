//
//  ControlComponent.swift
//  
//
//  Created by Stefan Urbanek on 24/08/2023.
//

import PoieticCore

/**
 
 - control_type: text | slider(min, max, step) | checkbox(0 | 1)
 - min_value
 - max_value
 - step_value
 
 */

extension Trait {
    public static let Control = Trait(
        name: "Control",
        attributes: [
            Attribute("value",
                      type: .double,
                      default: Variant(0.0),
                      abstract: "Value of the target node"),
            Attribute("control_type",
                      type: .string,
                      optional: true,
                      abstract: "Visual type of the control"),
            Attribute("min_value",
                      type: .double,
                      optional: true,
                      abstract: "Minimum possible value of the target variable."),
            Attribute("max_value",
                      type: .double,
                      optional: true,
                      abstract: "Maximum possible value of the target variable."),
            Attribute("step_value",
                      type: .double,
                      optional: true,
                      abstract: "Step for a slider control."),
            // TODO: numeric (default), percent, currency
            Attribute("value_format",
                      type: .string,
                      optional: true,
                      abstract: "Display format of the value"),

        ]
    )
}

extension StockFlowView {
//    public var controls: [Chart] {
//        graph.selectNodes(HasComponentPredicate(ControlComponent.self))
//            .compactMap { Control($0.snapshot) }
//    }
}
public struct BoundComponent<T: Component> {
    public typealias ComponentType = T
    public let snapshot: ObjectSnapshot
    public let component: ComponentType
    
    public init?(_ snapshot: ObjectSnapshot) {
        guard let component: ComponentType = snapshot[ComponentType.self] else {
            return nil
        }
        self.snapshot = snapshot
        self.component = component
    }
    
}

