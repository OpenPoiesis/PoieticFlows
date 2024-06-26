//
//  StateVariable.swift
//
//
//  Created by Stefan Urbanek on 19/09/2023.
//

import PoieticCore


/// Type of the simulation variable.
///
/// - SeeAlso: ``StateVariable``
///
public enum SimulationVariableType: String {
    /// The simulation variable represents a computation defined
    /// by a node.
    case object
    /// The simulation variable represents a built-in variable.
    ///
    case builtin
}

/// Reference to a variable.
///
/// The variable reference is used in arithmetic expressions and might represent
/// a built-in variable provided by the application or a value of an object.
///
/// One object can represent only one variable.
///
public enum StateVariableContent: Hashable, CustomStringConvertible {
    /// The variable is represented by an object with given object ID.
    ///
    case object(ObjectID)
    // TODO: point to computed object
    
    /// The variable is a built-in variable.
    ///
    case builtin(BuiltinVariable)
    
    /// Internal state of an object.
    ///
    /// An object might have additional internal states. The case parameter
    /// is ID of an object that owns the state.
    ///
    case internalState(ObjectID)
    
    public static func ==(lhs: StateVariableContent, rhs: StateVariableContent) -> Bool {
        switch (lhs, rhs) {
        case let (.object(left), .object(right)): return left == right
        case let (.builtin(left), .builtin(right)): return left == right
        case let (.internalState(left), .internalState(right)): return left == right
        default: return false
        }
    }
    
    public var description: String {
        switch self {
        case .object(let id): "object(\(id))"
        case .builtin(let variable): "builtin(\(variable))"
        case .internalState(let id): "internal(\(id))"
        }
    }
}

/// Structure representing a reference to a simulation variable.
///
/// The structure is analogous to an entry in a symbol table generated by the
/// compiler. It provides information about where a particular simulation
/// variable can be found in the simulation state.
///
/// This structure provides information about a variable used in the simulation.
/// Variable can be built-in or computed. The computed variable is representing
/// a node in the model, typically a node with a formula.
///
public struct StateVariable: CustomStringConvertible {
    // TODO: Rename to SimulationVariable?

    /// Index of the variable's value in a simulation state.
    ///
    public let index: Int

    /// Content of the state variable - whether it is an object or a builtin.
    ///
    public let content: StateVariableContent

    /// Type of the simulation variable.
    ///
    public var type: SimulationVariableType {
        switch content {
        case .builtin: .builtin
        case .object: .object
        case .internalState:
            // FIXME: What was the original intent here?
            fatalError("Internal state type not implemented")
        }
    }

    
    /// Variable value type
    ///
    public let valueType: ValueType

    public let name: String
    
    /// ID of a simulation node that the variable represents, if the variable
    /// represents a node.
    ///
    /// ID is `nil` when the variable is a built-in variable or an internal
    /// state variable.
    ///
    /// Each object can be represented by only one state variable.
    ///
    public var objectID: ObjectID? {
        switch content {
        case .builtin(_): nil
        case .object(let id): id
        case .internalState(_): nil
        }
    }

    public var description: String {
        "\(name)@\(index):\(type):\(valueType)"
    }
}

