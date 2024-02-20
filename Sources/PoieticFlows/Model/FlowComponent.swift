//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
//

import PoieticCore

extension Trait {
    public static let Flow = Trait(
        name: "Flow",
        attributes: [
            Attribute("priority", type: .int, default: ForeignValue(0),
                abstract: "Priority during computation. The flows are considered in the ascending order of priority."),
        ]
    )
}

/// Object representing a flow.
///
/// Flow is a node that can be connected to two stocks by a flow edge. One stock
/// is an inflow - stock from which the node drains, and another stock is an
/// outflow - stock to which the node fills.
///
/// - Note: Current implementation considers are flows to be one-directional
///         flows. Flow with negative value, which is in fact an outflow,
///         will be ignored.
///
// FIXME: [REFACTORING] Merge with CompiledFlow
public struct FlowComponent: InspectableComponent,
                             CustomStringConvertible {

    public static let trait = Trait.Flow
    
    /// Default priority – when a priority is not specified, then the priority
    /// is in the order of Flow nodes created.
    ///
    /// This is a convenience feature. User is advised to provide priority
    /// explicitly if a functionality that considers the priority is used.
    ///
    static var defaultPriority = 0
    
    /// Priority specifies an order in which the flow will be considered
    /// when draining a non-negative stocks. The lower the number, the higher
    /// the priority.
    ///
    /// - Note: It is highly recommended to specify priority explicitly if a
    /// functionality that considers the priority is used. It is not advised
    /// to rely on the default priority.
    ///
    public var priority: Int

    /// Create a new flow component.
    ///
    public init() {
        FlowComponent.defaultPriority += 1
        self.init(priority: FlowComponent.defaultPriority)
    }
    
    public init(priority: Int) {
        self.priority = priority
    }

    public func attribute(forKey key: AttributeKey) -> ForeignValue? {
        switch key {
        case "priority": return ForeignValue(priority)
        default: return nil
        }
    }
    
    public mutating func setAttribute(value: ForeignValue,
                                      forKey key: AttributeKey) throws {
        switch key {
        case "priority": self.priority = try value.intValue()
        default:
            throw AttributeError.unknownAttribute(name: key,
                                                  type: String(describing: type(of: self)))
        }
    }
    
    public var description: String {
        "Flow(priority: \(priority))"
    }
}

