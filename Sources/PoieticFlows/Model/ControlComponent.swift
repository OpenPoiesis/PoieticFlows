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

public struct ControlComponent: InspectableComponent {
    public static let trait = Trait.Control

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

