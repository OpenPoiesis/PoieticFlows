//
//  Metamodel.swift
//  
//
//  Created by Stefan Urbanek on 06/06/2023.
//

import PoieticCore

//public class _FlowsBoundMetamodel {
//    let Stock: ObjectType
//    let Flow: ObjectType
//    let Auxiliary: ObjectType
//    let GraphicalFunction: ObjectType
//    
//    public init(metamodel: Metamodel) {
//        
//    }
//    
//}
/// The metamodel for Stock-and-Flows domain model.
///
/// The `FlowsMetamodel` describes concepts, components, constraints and
/// queries that define the [Stock and Flow](https://en.wikipedia.org/wiki/Stock_and_flow)
/// model domain.
///
/// The basic object types are: ``Stock``, ``Flow``, ``Auxiliary``. More advanced
/// node type is ``GraphicalFunction``.
///
/// - SeeAlso: `Metamodel` protocol description for more information and reasons
/// behind this approach of describing the metamodel.
///
public let FlowsMetamodel = Metamodel(
    // TODO: Rename to StockFlowMetamodel
    // MARK: Components
    // ---------------------------------------------------------------------

    /// List of components that are used in the Stock and Flow models.
    /// 
    traits: BasicMetamodel.traits + [
        Trait.Name,
        Trait.Stock,
        Trait.Flow,
        Trait.Formula,
        Trait.Position,
        Trait.GraphicalFunction,
        Trait.Chart,
    ],

    // NOTE: If we were able to use Mirror on types, we would not need this
    /// List of object types for the Stock and Flow metamodel.
    ///
    objectTypes: [
        ObjectType.Stock,
        ObjectType.Flow,
        ObjectType.Auxiliary,
        ObjectType.GraphicalFunction,
        
        ObjectType.Drains,
        ObjectType.Fills,
        ObjectType.Parameter,
        ObjectType.ImplicitFlow,

        // UI
        ObjectType.Control,
        ObjectType.Chart,
        ObjectType.ChartSeries,
        ObjectType.ValueBinding,
    ] + BasicMetamodel.objectTypes,
    
    /// List of all built-in variables.
    ///
    /// The list contains:
    ///
    /// - ``TimeVariable``
    /// - ``TimeDeltaVariable``
    ///
    variables: [
        ObjectType.TimeVariable,
        ObjectType.TimeDeltaVariable,
    ],

    // MARK: Constraints
    // TODO: Add tests for violation of each of the constraints
    // --------------------------------------------------------------------
    /// List of constraints of the Stock and Flow metamodel.
    ///
    /// The constraints include:
    ///
    /// - Flow must drain (from) a stock, no other kind of node.
    /// - Flow must fill (into) a stock, no other kind of node.
    ///
    constraints: [
        Constraint(
            name: "flow_fill_is_stock",
            abstract: """
                      Flow must drain (from) a stock, no other kind of node.
                      """,
            match: EdgePredicate(IsTypePredicate(ObjectType.Fills)),
            requirement: AllSatisfy(
                EdgePredicate(
                    origin: IsTypePredicate(ObjectType.Flow),
                    target: IsTypePredicate(ObjectType.Stock)
                )
            )
        ),
            
        Constraint(
            name: "flow_drain_is_stock",
            abstract: """
                      Flow must fill (into) a stock, no other kind of node.
                      """,
            match: EdgePredicate(IsTypePredicate(ObjectType.Drains)),
            requirement: AllSatisfy(
                EdgePredicate(
                    origin: IsTypePredicate(ObjectType.Stock),
                    target: IsTypePredicate(ObjectType.Flow)
                )
            )
        ),
        
        Constraint(
            name: "one_parameter_for_graphical_function",
            abstract: """
                      Graphical function must not have more than one incoming parameters.
                      """,
            match: IsTypePredicate(ObjectType.GraphicalFunction),
            requirement: UniqueNeighbourRequirement(
                NeighborhoodSelector(
                    predicate: IsTypePredicate(ObjectType.Parameter),
                    direction: .incoming
                ),
                required: false
            )
        ),
        
        // UI
        // TODO: Make the value binding target to be "Value" type (how?)
        Constraint(
            name: "control_value_binding",
            abstract: """
                      Control binding's origin must be a Control and target must be a formula node.
                      """,
            match: EdgePredicate(IsTypePredicate(ObjectType.ValueBinding)),
            requirement: AllSatisfy(
                EdgePredicate(
                    origin: IsTypePredicate(ObjectType.Control),
                    target: HasTraitPredicate(Trait.Formula)
                )
            )
        ),
        Constraint(
            name: "chart_series",
            abstract: """
                      Chart series edge must originate in Chart and end in Value node.
                      """,
            match: EdgePredicate(IsTypePredicate(ObjectType.ChartSeries)),
            requirement: AllSatisfy(
                EdgePredicate(
                    origin: IsTypePredicate(ObjectType.Chart),
                    target: HasTraitPredicate(Trait.Formula)
                )
            )
        ),
    ]
)
