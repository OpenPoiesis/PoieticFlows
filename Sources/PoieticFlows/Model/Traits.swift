//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 23/02/2024.
//

import PoieticCore

extension Trait {
    
    /// Trait of simulation nodes that are computed using an arithmetic formula.
    ///
    /// Variables used in the formula refer to other nodes by their name. Nodes
    /// referring to other nodes as parameters must have an edge from the
    /// parameter nodes to the nodes using the parameter.
    ///
    public static let Formula = Trait(
        name: "Formula",
        attributes: [
            Attribute("formula", type: .string,
                      abstract: "Arithmetic formula or a constant value represented by the node."
                     ),
        ]
    )
    
    /// Trait of nodes representing a stock.
    ///
    /// Analogous concept to a stock is an accumulator, container, reservoir
    /// or a pool.
    ///
    public static let Stock = Trait(
        name: "Stock",
        attributes: [
            Attribute("allows_negative", type: .bool,
                      default: ForeignValue(false),
                      abstract: "Flag whether the stock can contain a negative value."
                     ),
            Attribute("delayed_inflow", type: .bool,
                      default: ForeignValue(false),
                      abstract: "Flag whether the inflow of the stock is delayed by one step, when the stock is part of a cycle."
                     ),
        ]
    )
    
    /// Trait of nodes representing a flow.
    ///
    /// Flow is a node that can be connected to two stocks by a flow edge.
    /// One stock is an inflow - stock from which the node drains,
    /// and another stock is an outflow - stock to which the node fills.
    ///
    /// - Note: Current implementation considers are flows to be one-directional
    ///         flows. Flow with negative value, which is in fact an outflow,
    ///         will be ignored.
    ///
    public static let Flow = Trait(
        name: "Flow",
        attributes: [
            /// Priority specifies an order in which the flow will be considered
            /// when draining a non-negative stocks. The lower the number, the higher
            /// the priority.
            ///
            /// - Note: It is highly recommended to specify priority explicitly if a
            /// functionality that considers the priority is used. It is not advised
            /// to rely on the default priority.
            ///
            Attribute("priority", type: .int, default: ForeignValue(0),
                      abstract: "Priority during computation. The flows are considered in the ascending order of priority."),
        ]
    )
    
    /// Trait of a node representing a graphical function.
    ///
    /// Graphical function is a function defined by its points and an
    /// interpolation method that is used to compute values between the points.
    /// 
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
    
    
    /// Trait of a node that represents a chart.
    /// 
    public static let Chart = Trait(
        name: "Chart",
        attributes: [
//            AttributeDescription(
//                name: "chartType",
//                type: .string,
//                abstract: "Chart type"),
        ]
    )

    
    public static let Simulation = Trait(
        name: "Simulation",
        attributes: [
            Attribute("steps", type: .int,
                      default: ForeignValue(100),
                      optional: true,
                      abstract: "Number of steps the simulation is run by default."
                     ),
            Attribute("time_delta", type: .double,
                      default: ForeignValue(1.0),
                      optional: true,
                      abstract: "Simulation step time delta."
                     ),
        ]
    )
}
