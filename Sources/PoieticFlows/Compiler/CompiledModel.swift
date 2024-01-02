//
//  CompiledModel.swift
//  
//
//  Created by Stefan Urbanek on 05/06/2022.
//

import PoieticCore

/// Index of a simulation variable that is represented by an object.
///
/// The index is used to refer to a variable value in the
/// ``SimulationState//values`` vector.
///
/// - SeeAlso: ``SimulationState``
public typealias VariableIndex = Int

/// Representation of a node in the simulation denoting how the node will
/// be computed.
///
public enum ComputationalRepresentation: CustomStringConvertible {
    /// Arithmetic formula representation of a node.
    ///
    case formula(BoundExpression)
    
    /// Graphic function representation of a node.
    ///
    case graphicalFunction(NumericUnaryFunction, VariableIndex)
    
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
    // TODO: Rename to CompiledControlBinding
    /// ID of a control node.
    let control: ObjectID
    
    /// Index of the simulation variable that the control controls.
    let variableIndex: VariableIndex
}

#if false
/// List of extracted components with associated IDs of objects containing them.
///
public struct ObjectComponentList<T: Component> {
    // TODO: [IMPORTANT] Move to Frame
    public typealias ComponentType = T
    public let ids: [ObjectID]
    public let components: [ObjectID:ComponentType]
    
    /// Create a new object component list from a list of snapshots.
    ///
    /// - Precondition: All snapshots must contain the required component.
    ///
    public init(_ validatedSnapshots: [ObjectSnapshot]) {
        ids = validatedSnapshots.map { $0.id }
        let items = validatedSnapshots.map {
            let component: ComponentType = $0[ComponentType.self]!
            return ($0.id, component)
        }
        components = Dictionary(uniqueKeysWithValues: items)
    }
    
    /// Get a component for object with given ID.
    ///
    /// The component list must contain the id.
    ///
    public subscript(id: ObjectID) -> ComponentType {
        return components[id]!
    }
}
#endif

/// Protocol for structures and objects that contain or represent an index.
///
/// Typically compiled equivalents of various simulation types contain an
/// index referring to their corresponding simulation variable. This
/// protocol makes it more convenient to be used as indices directly, reducing
/// noise in the code.
///
/// This is rather a cosmetic protocol.
///
public protocol IndexRepresentable {
//    var id: ObjectID { get }
    var index: VariableIndex { get }
}

public struct CompiledStock: IndexRepresentable {
    /// Object ID of the stock that this compiled structure represents.
    ///
    /// This is used mostly for inspection and debugging purposes.
    ///
    public let id: ObjectID
    
    /// Index in of the simulation state variable that represents the stock.
    ///
    /// This is the main information used during the computation.
    ///
    public let index: VariableIndex
    
    /// Component representing the stock as it was at the time of compilation.
    ///
    public let component: StockComponent

    /// List indices of simulation variables representing flows
    /// which fill the stock.
    ///
    public let inflows: [VariableIndex]

    /// List indices of simulation variables representing flows
    /// which drain the stock.
    ///
    public let outflows: [VariableIndex]
}

public struct CompiledFlow: IndexRepresentable {
    /// Object ID of the flow that this compiled structure represents.
    ///
    /// This is used mostly for inspection and debugging purposes.
    ///
    public let id: ObjectID

    /// Index in of the simulation state variable that represents the flow.
    ///
    /// This is the main information used during the computation.
    ///
    public let index: VariableIndex

    /// Component representing the flow as it was at the time of compilation.
    ///
    public let component: FlowComponent
}


/// Plain compiled variable without any additional information.
///
/// This is a default structure that represents a simulation node variable
/// in which any additional information is not relevant to the computation.
///
/// It is used for example for nodes of type auxiliary –
/// ``FlowsMetamodel/Auxiliary``.
/// 
public struct CompiledObject: IndexRepresentable {
    public let id: ObjectID
    public let index: VariableIndex
}

/// A structure representing a concrete instance of a graphical function
/// in the context of a graph.
public struct CompiledGraphicalFunction: IndexRepresentable {
    /// ID of a node where the function is defined
    public let id: ObjectID
    public let index: VariableIndex
    
    /// The function object itself
    public let function: NumericUnaryFunction
    /// ID of a node that is a parameter for the function.
    public let parameterIndex: VariableIndex
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
    
    /// List of builtin variables
    let builtinVariables: [BuiltinVariable]

    // TODO: Rename to: computedVariables with renamed type ComputedVariable
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
    public let computedVariables: [ComputedVariable]
    
    /// List of all simulation variables: built-in and computed.
    ///
    /// To fetch values from a simulation state:
    ///
    /// ```swift
    /// // Let the following two be given
    /// let model: CompiledModel
    /// let state: SimulationState
    ///
    /// // Print values from the state
    /// for variable in model.allVariables {
    ///     let value = state[variable]
    ///     print("\(variable.name): \(value)"
    /// }
    /// ```
    ///
    public var allVariables: [SimulationVariable] {
        // TODO: Don't compute, materialize?
        var result: [SimulationVariable] = []
        
        for (index, builtin) in builtinVariables.enumerated() {
            let variable = BoundBuiltinVariable(builtin: builtin, index: index)
            result.append(SimulationVariable.builtin(variable))
        }
        for computed in computedVariables {
            result.append(SimulationVariable.computed(computed))
        }
 
        return result
    }
    /// Get index of an object with given ID.
    ///
    /// This function is just for debugging purposes.
    ///
    /// - Complexity: O(n)
    ///
    public func index(of id: ObjectID) -> VariableIndex? {
        // TODO: Do we need a pre-computed map here or are we fine with O(n)?
        // Since this is just for debug purposes, O(n) should be fine, no need
        // for added complexity of the code.
        return computedVariables.firstIndex { $0.id == id }
    }
    
    /// Get a simulation variable for an object with given ID, if exists.
    ///
    /// This function is just for debugging purposes.
    ///
    /// - Complexity: O(n)
    ///
    public func variable(for id: ObjectID) -> ComputedVariable? {
        return computedVariables.first { $0.id == id }
        
    }

    /// Stocks ordered by the computation (parameter) dependency.
    ///
    /// This list contains all stocks used in the simulation and adds
    /// derived information to each stock such as its inflows and outflows.
    ///
    /// See ``CompiledStock`` for more information.
    ///
    let stocks: [CompiledStock]
    
    /// Get a compiled stock by object ID.
    ///
    ///
    /// - Complexity: O(n)
    ///
    func compiledStock(_ id: ObjectID) -> CompiledStock {
        // TODO: What to do with this method?
        return stocks.first { $0.id == id }!
    }
    
    /// Flows ordered by the computation (parameter) dependency.
    ///
    let flows: [CompiledFlow]

    /// Auxiliaries required by stocks, by order of dependency.
    ///
    let auxiliaries: [CompiledObject]


    /// Compiled bindings of controls to their value objects.
    ///
    /// - See also: ``ControlComponent`` and ``ControlBindingSystem``.
    ///
    let valueBindings: [CompiledControlBinding]
    
    /// Selection of simulation variables that represent graphical functions.
    var graphicalFunctions: [CompiledGraphicalFunction] {
        let vars: [CompiledGraphicalFunction] = computedVariables.compactMap {
            if case let .graphicalFunction(fun, param) = $0.computation {
                return CompiledGraphicalFunction(id: $0.id,
                                                 index: $0.index,
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
    /// - Complexity: O(n)
    ///
    public func variable(named name: String) -> ComputedVariable? {
        return computedVariables.first { $0.name == name }
    }
}

