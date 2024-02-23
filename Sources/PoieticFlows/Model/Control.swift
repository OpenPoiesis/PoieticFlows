//
//  ControlComponent.swift
//  
//
//  Created by Stefan Urbanek on 24/08/2023.
//

import PoieticCore

extension Trait {
    public static let Control = Trait(
        name: "Control",
        attributes: [
            Attribute("value",
                      type: .double,
                      default: ForeignValue(0.0),
                      abstract: "Value of the target node"),
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

