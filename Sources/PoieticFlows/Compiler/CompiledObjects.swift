//
//  File 2.swift
//  
//
//  Created by Stefan Urbanek on 15/03/2024.
//

import PoieticCore


/// Representation of a node in the simulation denoting how the node will
/// be computed.
///
public enum ComputationalRepresentation: CustomStringConvertible {
    /// Arithmetic formula representation of a node.
    ///
    case formula(BoundExpression)
    
    /// Graphic function representation of a node.
    ///
    /// The first value is a generated function for computing the values. The
    /// second value of the tuple is an index of a state variable representing
    /// the function's parameter node.
    ///
    case graphicalFunction(Function, SimulationState.Index)
  
    /// First value is parameter node, the second is state variable.
    case delay(CompiledDelay)
    
    public var valueType: ValueType {
        switch self {
        case let .formula(formula):
            return formula.valueType
        case .graphicalFunction(_, _):
            return ValueType.double
        case let .delay(delay):
            return delay.valueType
        }
    }
    
    // case dataInput(???)

    public var description: String {
        switch self {
        case let .formula(formula):
            return "\(formula)"
        case let .graphicalFunction(fun, index):
            return "graphical(\(fun.name), \(index))"
        case let .delay(delay):
            let initialValue = delay.initialValue.map { $0.description } ?? "nil"
            return "delay(\(delay.parameterIndex), \(delay.duration), \(initialValue)"
        }
        
    }
}

/// Structure describing an object to be simulated.
///
/// This is the core detail information of the simulation.
///
/// The simulation object provides information about what kind of computation
/// is performed (see ``ComputationalRepresentation``), which variable
/// represents the object's state and what is the type of the stored value.
///
/// - SeeAlso: ``ComputationalRepresentation``,
///   ``Solver/evaluate(objectAt:with:)``
///
public struct SimulationObject: CustomStringConvertible {
    /// ID of the object, usually a node, that is being represented.
    ///
    public let id: ObjectID

    public enum SimulationObjectType: Codable {
        case stock
        case flow
        case auxiliary
    }
   
    public let type: SimulationObjectType

    /// Index of the variable representing the object's state in the
    /// simulation state.
    ///
    /// - SeeAlso: ``CompiledModel/stateVariables``
    ///
    public let variableIndex: Int
    
    /// Type of the variable value.
    ///
    public var valueType: ValueType
    
    /// Information denoting how the object is being computed.
    ///
    public let computation: ComputationalRepresentation
    
    /// Name of the object.
    ///
    public let name: String
    
    public var description: String {
        "var(\(name), id:\(id), idx:\(variableIndex))"
    }
}

/// Builtin variable kind.
///
/// The enum is used during computation to set value of a builtin variable.
///
/// - SeeAlso: ``CompiledBuiltin``,
/// ``Solver/updateBuiltins(_:time:timeDelta:),
/// ``Solver/initializeState(override:time:timeDelta:)
///
public enum BuiltinVariable: Equatable, CustomStringConvertible {
    case time
    case timeDelta
//    case initialTime
//    case endTime
    
    public var description: String {
        switch self {
        case .time: "time"
        case .timeDelta: "time_delta"
        }
    }
}


/// Structure representing builtin and reference to its simulation state
/// variable.
///
/// - SeeAlso: ``CompiledModel/stateVariables``,
/// ``Solver/updateBuiltins(_:time:timeDelta:),
/// ``Solver/initializeState(override:time:timeDelta:)
///
public struct CompiledBuiltin {
    /// Builtin being represented by a variable.
    ///
    let builtin: BuiltinVariable

    /// Index into the simulation state variable list.
    ///
    /// - SeeAlso: ``CompiledModel/stateVariables``
    ///
    let variableIndex: Int
}

/// Compiled representation of a stock.
///
/// This structure is used during computation.
///
/// - SeeAlso: ``Solver/computeStockDelta(_:at:with:)``
///
public struct CompiledStock {
    /// Object ID of the stock that this compiled structure represents.
    ///
    /// This is used mostly for inspection and debugging purposes.
    ///
    public let id: ObjectID
    
    /// Index in of the simulation state variable that represents the stock.
    ///
    /// This is the main information used during the computation.
    ///
    /// - SeeAlso: ``CompiledModel/stateVariables``
    ///
    public let variableIndex: SimulationState.Index
    
    /// Flag whether the value of the node can be negative.
    ///
    public let allowsNegative: Bool
    
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
    public let delayedInflow: Bool

    /// List indices of simulation variables representing flows
    /// which fill the stock.
    ///
    /// - SeeAlso: ``Solver/computeStockDelta(_:at:with:)``
    ///
    public let inflows: [SimulationState.Index]

    /// List indices of simulation variables representing flows
    /// which drain the stock.
    ///
    /// - SeeAlso: ``Solver/computeStockDelta(_:at:with:)``
    ///
    public let outflows: [SimulationState.Index]
}

/// Compiled representation of a flow.
///
/// This structure is used during computation.
///
/// - SeeAlso: ``Solver/computeStockDelta(_:at:with:)``
///
@available(*, deprecated,  message: "Just use priority")
struct CompiledFlow {
    // TODO: Remove historical remnant CompiledFlow. See Compiler.compile(stocks:,flows:) -> [CompiledStock]

    /// Object ID of the flow that this compiled structure represents.
    ///
    /// This is used mostly for inspection and debugging purposes.
    ///
    let id: ObjectID

    /// Component representing the flow as it was at the time of compilation.
    ///
    let priority: Int
}


/// A structure representing a concrete instance of a graphical function
/// in the context of a graph.
///
/// - SeeAlso: ``Compiler/compileGraphicalFunctionNode(_:)``, ``Solver/evaluate(objectAt:with:)``
///
public struct CompiledGraphicalFunction {
    /// ID of a node where the function is defined
    public let id: ObjectID
    
    /// Index to the list of simulation state variables.
    ///
    public let variableIndex: SimulationState.Index
    
    /// The function object itself
    public let function: Function
    
    /// ID of a node that is a parameter for the function.
    public let parameterIndex: SimulationState.Index
}

/// Structure representing compiled control-to-value binding.
///
/// - SeeAlso: ``PoieticCore/ObjectType/Control``, ``PoieticCore/ObjectType/ValueBinding``
///
public struct CompiledControlBinding {
    /// ID of a control node.
    ///
    /// - SeeAlso: ``PoieticCore/ObjectType/Control``
    public let control: ObjectID
    
    /// Index of the simulation variable that the control controls.
    public let variableIndex: SimulationState.Index
}

public struct CompiledDelay {
    // TODO: add at least smoothing (SMTH1)
    public enum OutputType {
        case delay
        case smooth
    }
//    public let order: Int
    
    //    public let initialValueIndex: SimulationState.Index
    public let valueQueueIndex: SimulationState.Index
    public let duration: Double
    public let initialValue: Variant?
    public let parameterIndex: SimulationState.Index
    public let valueType: ValueType
}


/// Describes a connection between two stocks through a flow.
///
public struct StockAdjacency: EdgeType {
    // TODO: Add "delayed inflow" flag to prevent cycles
    // TODO: Maybe just a type alias to some "LightEdge" type?
    /// OD of a flow that connects the two stocks
    public let id: ObjectID
    /// ID of a stock being drained by the flow.
    public let origin: ObjectID
    /// ID of a stock being filled by the flow.
    public let target: ObjectID
}
