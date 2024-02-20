//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 09/07/2023.
//

import PoieticCore

extension Trait {
    public static let GraphicalFunction = Trait(
        name: "GraphicalFunction",
        attributes: [
            Attribute("interpolation_method", type: .string, default: "step",
                      abstract: "Method of interpolation for values between the points."),
            Attribute("graphical_function_points", type: .points,
                      default: ForeignValue(Array<Point>()),
                      abstract: "Points of the graphical function."),
        ],
        abstract: "Function represented by a set of points and an interpolation method."
    )

}

// TODO: Not used any more
public struct GraphicalFunctionComponent: InspectableComponent, CustomStringConvertible {
    public static let trait = Trait.GraphicalFunction
    
    var points: [Point]
    
    // TODO: Use this. Currently unused.
    var method: InterpolationMethod

    public init() {
        self.init(points: [], method: .step)
    }
    
    public init(points: [Point], method: InterpolationMethod = .step) {
        self.points = points
        self.method = method
    }

    
    public mutating func setAttribute(value: ForeignValue, forKey key: AttributeKey) throws {
        switch key {
        case "interpolation_method":
            let methodName = try value.stringValue()
            self.method = InterpolationMethod.init(rawValue: methodName) ?? .step
        case "graphical_function_points":
            points = try value.pointArray()
        default:
            throw AttributeError.unknownAttribute(name: key,
                                                  type: String(describing: type(of: self)))
        }

    }
    
    public func attribute(forKey key: String) -> ForeignValue? {
        switch key {
        case "interpolation_method": return ForeignValue(method.rawValue)
        case "graphical_function_points": return ForeignValue(points)
        default:
            return nil
        }
    }
    
    public var description: String {
        let value = ForeignValue(points)
        return "graphical(\(value.description))"
    }
    
    /// Returns a graphical function object.
    ///
    public var function: GraphicalFunction {
        // TODO: Consider the interpolation method (currently unused)
        return GraphicalFunction(points: points)
    }
}
