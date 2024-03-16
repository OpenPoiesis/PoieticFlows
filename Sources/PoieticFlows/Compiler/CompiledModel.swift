//
//  CompiledModel.swift
//  
//
//  Created by Stefan Urbanek on 05/06/2022.
//

import PoieticCore

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
  
//    case statefulFunction(StatefulFunction, [VariableIndex])
    
    public var valueType: ValueType {
        switch self {
        case let .formula(formula):
            return formula.valueType
        case .graphicalFunction(_, _):
            return ValueType.double
        }
    }
    
    // case dataInput(???)

    public var description: String {
        switch self {
        case let .formula(formula):
            return "\(formula)"
        case let .graphicalFunction(fun, index):
            return "graphical(\(fun.name), \(index))"
        }
        
    }
}

/// Structure representing compiled control-to-value binding.
///
public struct CompiledControlBinding {
    /// ID of a control node.
    public let control: ObjectID
    
    /// Index of the simulation variable that the control controls.
    public let variableIndex: SimulationState.Index
}


/// Compiled representation of the stock.
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
    public let variableIndex: SimulationState.Index
    
    /// Flag whether the value of the node can be negative.
    public var allowsNegative: Bool = false
    
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
    public var delayedInflow: Bool = false

    /// List indices of simulation variables representing flows
    /// which fill the stock.
    ///
    /// - SeeAlso: ``Solver/computeStock(_:at:with:)``
    ///
    public let inflows: [SimulationState.Index]

    /// List indices of simulation variables representing flows
    /// which drain the stock.
    ///
    /// - SeeAlso: ``Solver/computeStock(_:at:with:)``
    ///
    public let outflows: [SimulationState.Index]
}

public struct CompiledFlow {
    /// Object ID of the flow that this compiled structure represents.
    ///
    /// This is used mostly for inspection and debugging purposes.
    ///
    public let id: ObjectID

    public let variableIndex: SimulationState.Index
    /// Index in of the simulation state variable that represents the flow.
    ///
    /// This is the main information used during the computation.
    ///
    public let objectIndex: Int
    /// Component representing the flow as it was at the time of compilation.
    ///
    public let priority: Int
}


/// Plain compiled variable without any additional information.
///
/// This is a default structure that represents a simulation node variable
/// in which any additional information is not relevant to the computation.
///
/// It is used for example for nodes of type auxiliary –
/// ``/PoieticCore/ObjectType/Auxiliary``.
///
public struct CompiledAuxiliary {
    public let id: ObjectID
    public let variableIndex: SimulationState.Index
    // Index into list of simulation objects
    public let objectIndex: Int
}

/// A structure representing a concrete instance of a graphical function
/// in the context of a graph.
///
public struct CompiledGraphicalFunction {
    /// ID of a node where the function is defined
    public let id: ObjectID
    public let variableIndex: SimulationState.Index
    
    /// The function object itself
    public let function: Function
    /// ID of a node that is a parameter for the function.
    public let parameterIndex: SimulationState.Index
}

// TODO: Not used
/// Defaults fro simulation taken from an object with a trait
/// ``/PoieticCore/Trait/Simulation``.
///
public struct SimulationDefaults {
    public let initialTime: Double
    public let timeDelta: Double
    public let simulationSteps: Int
}


/// Structure used by the simulator.
///
/// Compiled model is an internal representation of the model design. The
/// representation contains information that is necessary for computation
/// and is guaranteed to be consistent.
///
/// If the model design violates constraints or contains user errors, the
/// compiler refuses to create the compiled model.
///
/// - Note: The compiled model can also be used in a similar way as
///  "explain plan" in SQL. It contains some information how the simulation
///   will be carried out.
///
public struct CompiledModel {
    // TODO: Alternative names: InternalRepresentation, SimulableRepresentation, SRep, ResolvedModel, ExecutableModel
    
    /// List of simulation state variables.
    ///
    /// The list of state variables contain values of builtins, values of
    /// nodes and values of internal states.
    ///
    /// Each node is typically assigned one state variable which represents
    /// the node's value at given state. Some nodes might contain internal
    /// state that might be present in multiple state variables.
    ///
    /// The internal state is typically not user-presentable and is a state
    /// associated with stateful functions or other computation objects.
    ///
    /// - SeeAlso: ``Compiler/stateVariables``
    ///
    public let stateVariables: [StateVariable]
    

    /// List of compiled builtin variables.
    ///
    /// The compiled builtin variable references a state variable that holds
    /// the value for the builtin variable and a kind of the builtin variable.
    ///
    /// - SeeAlso: ``stateVariables``, ``CompiledBuiltin``, ``Variable``,
    ///   ``FlowsMetamodel``
    ///
    public let builtins: [CompiledBuiltin]
    /// List of variables that are computed, ordered by computational dependency.
    ///
    /// The variables are ordered so that variables that do not require other
    /// variables to be computed, such as constants are at the beginning.
    /// The variables that depend on others by using them as a parameter
    /// follow the variables they depend on.
    ///
    /// Computing variables in this order assures that we have all the
    /// parameters computed when needed them.
    ///
    /// - Note: It is guaranteed that the variables are ordered. If a cycle was
    ///         present in the model, the compiled model would not have been
    ///         created.
    ///
    /// - SeeAlso: ``computedVariableIndex(of:)``
    ///
    public let computedObjects: [ComputedObject]

    
    /// Index of _time_ variable within the state variables.
    ///
    public let timeVariableIndex: SimulationState.Index
    
    
    /// Get index into a list of computed variables for an object with given ID.
    ///
    /// This function is just for inspection and debugging purposes, it is not
    /// used during computation.
    ///
    /// - Complexity: O(n)
    /// - SeeAlso: ``resultIndex(of:)``
    ///
    public func variableIndex(of id: ObjectID) -> SimulationState.Index? {
        // TODO: Do we need a pre-computed map here or are we fine with O(n)?
        // Since this is just for debug purposes, O(n) should be fine, no need
        // for added complexity of the code.
        guard let first = computedObjects.first(where: {$0.id == id}) else {
            return nil
        }
        return first.variableIndex
    }
   
    
    /// Get a simulation variable for an object with given ID, if exists.
    ///
    /// This function is not used during computation, it is provided for
    /// consumers of the simulation state or simulation result.
    ///
    /// - Complexity: O(n)
    ///
    public func computedObject(of id: ObjectID) -> ComputedObject? {
        return computedObjects.first { $0.id == id }
        
    }

    /// Stocks ordered by the computation (parameter) dependency.
    ///
    /// This list contains all stocks used in the simulation and adds
    /// derived information to each stock such as its inflows and outflows.
    ///
    /// This property is used in computation.
    ///
    /// See ``CompiledStock`` for more information.
    ///
    /// - SeeAlso: ``Solver/difference(at:with:timeDelta:)``,
    ///
    public let stocks: [CompiledStock]
    
    /// Get a compiled stock by object ID.
    ///
    /// This property is used in computation.
    ///
    /// - SeeAlso: ``Solver/computeStockDelta(_:at:with:)``
    ///
    /// - Complexity: O(n)
    ///
    func compiledStock(_ id: ObjectID) -> CompiledStock {
        // TODO: What to do with this method?
        return stocks.first { $0.id == id }!
    }
    
    /// Flows ordered by the computation (parameter) dependency.
    ///
    /// This property is used in computation.
    ///
    /// - SeeAlso: ``Solver/difference(at:with:timeDelta:)``,
    ///
    public let flows: [CompiledFlow]

    /// Auxiliaries required by stocks, by order of dependency.
    ///
    /// This property is used in computation.
    ///
    /// - SeeAlso: ``Solver/difference(at:with:timeDelta:)``,
    ///
    public let auxiliaries: [CompiledAuxiliary]
    
    /// List of charts.
    ///
    /// This property is not used during computation, it is provided for
    /// consumers of the simulation state or simulation result.
    ///
    public let charts: [Chart]


    /// Compiled bindings of controls to their value objects.
    ///
    /// - See also: ``/PoieticCore/ObjectType/Control``.
    ///
    public let valueBindings: [CompiledControlBinding]
        
    public var simulationDefaults: SimulationDefaults?
    
    /// Selection of simulation variables that represent graphical functions.
    ///
    /// This property is not used during computation, it is provided for
    /// consumers of the simulation state or simulation result.
    ///
    public var graphicalFunctions: [CompiledGraphicalFunction] {
        let vars: [CompiledGraphicalFunction] = computedObjects.compactMap {
            if case let .graphicalFunction(fun, param) = $0.computation {
                return CompiledGraphicalFunction(id: $0.id,
                                                 variableIndex: $0.variableIndex,
                                                 function: fun,
                                                 parameterIndex: param)
            }
            else {
                return nil
            }
        }
        return vars
    }
    
    
    /// Get a compiled variable by its name.
    ///
    /// This function is mostly for user-facing tools that would like to
    /// interfere with the simulation state. Example use-cases are:
    ///
    /// - querying the state by variable name
    /// - modifying state variables by user provided variable values
    ///
    /// Since the function is slow, it is highly not recommended to be used
    /// during iterative computation.
    ///
    /// This property is not used during computation, it is provided for
    /// consumers of the simulation state or simulation result.
    ///
    /// - Complexity: O(n)
    ///
    public func variable(named name: String) -> ComputedObject? {
        guard let object = computedObjects.first(where: { $0.name == name}) else {
            return nil
        }
                 
        return object
    }
    
    /// Index of a stock in a list of stocks or in a stock difference vector.
    ///
    /// This function is not used during computation. It is provided for
    /// potential inspection, testing and debugging.
    ///
    /// - Precondition: The compiled model must contain a stock with given ID.
    ///
    public func stockIndex(_ id: ObjectID) -> NumericVector.Index {
        guard let index = stocks.firstIndex(where: { $0.id == id }) else {
            fatalError("The compiled model does not contain stock with ID \(id)")
        }
        return index
    }
}

