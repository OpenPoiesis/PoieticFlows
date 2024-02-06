//
//  Stock.swift
//  
//
//  Created by Stefan Urbanek on 13/06/2022.
//
import PoieticCore

// Alias: Accumulator, level, state, container, reservoir, pool

/// A node representing a stock – accumulator, container, reservoir, a pool.
///
public struct StockComponent: InspectableComponent,
                              CustomStringConvertible {
    
    public static var componentSchema = ComponentDescription(
        name: "Stock",
        attributes: [
            Attribute(
                name: "allows_negative",
                type: .bool,
                abstract: "Flag whether the stock can contain a negative value."
            ),
            Attribute(
                name: "delayed_inflow",
                type: .bool,
                abstract: "Flag whether the inflow of the stock is delayed by one step, when the stock is part of a cycle."
            ),
        ]
    )
    
    /// Flag whether the value of the node can be negative.
    var allowsNegative: Bool = false
    
    /// Flag that controls how flow for the stock is being computed when the
    /// stock is non-negative.
    ///
    /// If the stock is non-negative, normally its outflow depends on the
    /// inflow. This is not a problem unless there is a loop of flows between
    /// stocks. In that case, to proceed with computation we need to break the
    /// loop. Stock being with 'delayed inflow' means that the outflow will not
    /// immediately depend on the inflow. The outflow will be computed from
    /// the actual stock value, ignoring the inflow. The inflow will be added
    /// later to the stock.
    ///
    var delayedInflow: Bool = false
    
    /// Create a new stock component.
    ///
    /// The `allowsNegative` is set to `false` and `delayedInflow` is set to
    /// `false` as well.
    ///
    public init() {
        self.init(allowsNegative: false, delayedInflow: false)
    }
    
    public init(allowsNegative: Bool, delayedInflow: Bool) {
        self.allowsNegative = allowsNegative
        self.delayedInflow = delayedInflow
    }
    
    public func attribute(forKey key: AttributeKey) -> ForeignValue? {
        switch key {
        case "allows_negative": return ForeignValue(allowsNegative)
        case "delayed_inflow": return ForeignValue(delayedInflow)
        default: return nil
        }
    }
    
    public mutating func setAttribute(value: ForeignValue,
                                      forKey key: AttributeKey) throws {
        switch key {
        case "allows_negative": self.allowsNegative = try value.boolValue()
        case "delayed_inflow": self.delayedInflow = try value.boolValue()
        default:
            throw AttributeError.unknownAttribute(name: key,
                                                  type: String(describing: type(of: self)))
        }
    }
    
    public var description: String {
        "Stock(allowsNegative: \(allowsNegative) delayedInflow: \(delayedInflow)"
    }

}
