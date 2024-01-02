//
//  ControlComponent.swift
//  
//
//  Created by Stefan Urbanek on 24/08/2023.
//

import PoieticCore

public struct ControlComponent: InspectableComponent {
    public static var componentSchema = ComponentSchema(
        name: "Control",
        attributes: [
            Attribute(
                name: "value",
                type: .double,
                abstract: "Value of the target node"),
        ]
    )

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

public struct Control {
    public let snapshot: ObjectSnapshot
    public let component: ControlComponent
    
    public init?(_ snapshot: ObjectSnapshot) {
        guard let component: ControlComponent = snapshot[ControlComponent.self] else {
            return nil
        }
        self.snapshot = snapshot
        self.component = component
    }
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

