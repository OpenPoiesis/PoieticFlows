//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 23/02/2024.
//

import PoieticCore

extension ObjectType {
    /// A stock node - one of the two core nodes.
    ///
    /// Stock node represents a pool, accumulator, a stored value.
    ///
    /// Stock can be connected to many flows that drain or fill the stock.
    ///
    /// - SeeAlso: ``FlowsMetamodel/Flow``, ``FlowsMetamodel/ImplicitFlow``
    ///
    public static let Stock = ObjectType(
        name: "Stock",
        structuralType: .node,
        traits: [
            Trait.Name,
            Trait.Formula,
            Trait.Stock,
            Trait.Position,
            // DescriptionComponent.self,
            // ErrorComponent.self,
        ]
    )
    
    /// A flow node - one of the two core nodes.
    ///
    /// Flow node represents a rate at which a stock is drained or a stock
    /// is filed.
    ///
    /// Flow can be connected to only one stock that the flow fills and from
    /// only one stock that the flow drains.
    ///
    /// ```
    ///                    drains           fills
    ///     Stock source ----------> Flow ---------> Stock drain
    ///
    /// ```
    ///
    /// - SeeAlso: ``FlowsMetamodel/Stock``, ``FlowsMetamodel/Fills-8qqu8``,
    /// ``FlowsMetamodel/Drains-38oqw``.
    ///
    public static let Flow = ObjectType(
        name: "Flow",
        structuralType: .node,
        traits: [
            Trait.Name,
            Trait.Formula,
            Trait.Flow,
            Trait.Position,
            // DescriptionComponent.self,
            // ErrorComponent.self,
        ]
    )
    
    /// An auxiliary node - containing a constant or a formula.
    ///
    public static let Auxiliary = ObjectType(
        name: "Auxiliary",
        structuralType: .node,
        traits: [
            Trait.Name,
            Trait.Formula,
            Trait.Position,
            // DescriptionComponent.self,
            // ErrorComponent.self,
        ]
    )
    
    /// An auxiliary node with a function that is described by a graph.
    ///
    /// Graphical function is specified by a collection of 2D points.
    ///
    public static let GraphicalFunction = ObjectType(
        name: "GraphicalFunction",
        structuralType: .node,
        traits: [
            Trait.Name,
            Trait.Position,
            Trait.GraphicalFunction,
            // DescriptionComponent.self,
            // ErrorComponent.self,
            // TODO: IMPORTANT: Make sure we do not have formula component here or handle the type
        ]
    )
    
    /// A user interface mode representing a control that modifies a value of
    /// its target node.
    ///
    /// For control node to work, it should be connected to its target node with
    /// ``FlowsMetamodel/ValueBinding`` edge.
    ///
    public static let Control = ObjectType(
        name: "Control",
        structuralType: .node,
        traits: [
            Trait.Name,
            Trait.Control,
        ]
    )
    
    /// A user interface node representing a chart.
    ///
    /// Chart contains series that are connected with the chart using the
    /// ``FlowsMetamodel/ChartSeries`` edge where the origin is the chart and
    /// the target is a value node.
    ///
    public static let Chart = ObjectType(
        name: "Chart",
        structuralType: .node,
        traits: [
            Trait.Name,
            Trait.Chart,
        ]
    )
    
    /// A node that contains a note, a comment.
    ///
    /// The note is not used for simulation, it exists solely for the purpose
    /// to provide user-facing information.
    ///
    public static let Note = ObjectType(
        name: "Note",
        structuralType: .node,
        traits: [
            Trait.Note,
        ]
    )
    
    /// Edge from a stock to a flow. Denotes "what the flow drains".
    ///
    /// - SeeAlso: ``FlowsMetamodel/Flow``, ``FlowsMetamodel/Fills-8qqu8``
    ///
    public static let Drains = ObjectType(
        name: "Drains",
        structuralType: .edge,
        traits: [
            // None for now
        ],
        abstract: "Edge from a stock node to a flow node, representing what the flow drains."
    )
    
    /// Edge from a flow to a stock. Denotes "what the flow fills".
    ///
    /// - SeeAlso: ``FlowsMetamodel/Flow``, ``FlowsMetamodel/Drains-38oqw``
    ///
    public static let Fills = ObjectType(
        name: "Fills",
        structuralType: .edge,
        traits: [
            // None for now
        ],
        abstract: "Edge from a flow node to a stock node, representing what the flow fills."
        
    )
    
    /// An edge between a node that serves as a parameter in another node.
    ///
    /// For example, if a flow has a formula `rate * 10` then the node
    /// with name `rate` is connected to the flow through the parameter edge.
    ///
    public static let Parameter = ObjectType(
        name: "Parameter",
        structuralType: .edge,
        traits: [
            // None for now
        ]
    )
    
    /// Edge between two stocks that are connected through a flow.
    ///
    /// Implicit flow is an edge between two stocks connected by a flow
    /// where one stocks fills the flow and another stock drains the flow.
    ///
    /// ```
    ///              Drains           Fills
    ///    Stock a ==========> Flow =========> Stock b
    ///       |                                  ^
    ///       +----------------------------------+
    ///                   implicit flow
    ///
    /// ```
    
    /// - Note: This edge is created by the system, not by the user.
    ///
    public static let ImplicitFlow = ObjectType(
        name: "ImplicitFlow",
        structuralType: .edge,
        plane: .system,
        traits: [
            // None for now
        ],
        abstract: "Edge between two stocks."
    )
    
    /// An edge type to connect controls with their targets.
    ///
    /// The origin of the node is a control – ``FlowsMetamodel/Control``, the
    /// target is a node representing a value.
    ///
    public static let ValueBinding = ObjectType(
        name: "ValueBinding",
        structuralType: .edge,
        plane: .system,
        traits: [
            // None for now
        ],
        abstract: "Edge between a control and a value node. The control observes the value after each step."
    )
    
    /// An edge type to connect a chart with a series that are included in the
    /// chart.
    ///
    /// The origin of the node is a chart – ``FlowsMetamodel/Chart`` and
    /// the target of the node is a node representing a value.
    ///
    public static let ChartSeries = ObjectType(
        // TODO: Origin: Chart, target: Expression
        name: "ChartSeries",
        structuralType: .edge,
        plane: .system,
        traits: [
            // None for now
        ],
        abstract: "Edge between a control and its target."
    )
}

// FIXME: [REFACTORING] This does not belong here (historical refactoring remnant)
extension ObjectType {
    // FIXME: Move this to some variable catalog, out of metamodel. This is specific to stock-flow model
    // MARK: Built-in variables
    // ---------------------------------------------------------------------
    /// Built-in variable reference that represents the simulation time.
    ///
    public static let TimeVariable = BuiltinVariable(
        name: "time",
        abstract: "Current simulation time"
    )

    /// Built-in variable reference that represents the time delta.
    ///
    public static let TimeDeltaVariable = BuiltinVariable(
        name: "time_delta",
        abstract: "Simulation time delta - time between discrete steps of the simulation."
    )
}
