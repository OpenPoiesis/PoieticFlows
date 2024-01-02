//
//  StateVector.swift
//  
//
//  Created by Stefan Urbanek on 30/07/2022.
//

import PoieticCore

/// A simple vector-like structure to hold an unordered collection of numeric
/// values that can be accessed by key. Simple arithmetic operations can be done
/// with the structure, such as addition, subtraction and multiplication
/// by a scalar value.
///
public struct SimulationState: CustomStringConvertible {
    
    public var model: CompiledModel
    /// Values of built-in variables.
    public var builtins: [ForeignValue] = []
    /// Values of computed variables.
    public var values: [Double]
    
    /// All values of the state variables.
    ///
    /// The list is a concatenation of ``builtins`` and ``values``.
    public var allValues: [ForeignValue] {
        return builtins + values.map { ForeignValue($0) }
    }
    
    /// Create a simulation state with all variables set to zero.
    ///
    /// The list of builtins and simulation variables will be initialised
    /// according to the count of the respective variables in the compiled
    /// model.
    ///
    public init(model: CompiledModel) {
        self.builtins = Array(repeating: ForeignValue(0),
                              count: model.builtinVariables.count)
        self.values = Array(repeating: 0,
                           count: model.computedVariables.count)
        self.model = model
    }
    
    public init(_ items: [Double], builtins: [ForeignValue], model: CompiledModel) {
        precondition(items.count == model.computedVariables.count,
                     "Count of items (\(items.count) does not match required items count \(model.computedVariables.count)")
        self.builtins = builtins
        self.values = items
        self.model = model
    }

    /// Get or set a computed variable at given index.
    ///
    @inlinable
    public subscript(rep: IndexRepresentable) -> Double {
        get {
            return values[rep.index]
        }
        set(value) {
            values[rep.index] = value
        }
    }
    
    /// Get or set a computed variable at given index.
    ///
    @inlinable
    public subscript(index: Int) -> Double {
        get {
            return values[index]
        }
        set(value) {
            values[index] = value
        }
    }
    
    /// Get or set a computed variable at given index.
    ///
    /// ```swift
    ///  // Let the following two be given
    /// let state: SimulationState
    /// let variable: SimulationVariable
    ///
    /// // Fetch the value
    /// let value: ForeignValue = state[variable]
    ///
    /// // Use the value...
    /// ```
    ///
    @inlinable
    public subscript(variable: SimulationVariable) -> ForeignValue {
        get {
            switch variable {
            case let .builtin(v): return builtins[v.index]
            case let .computed(v): return ForeignValue(values[v.index])
            }
        }
    }

    /// Create a new state with variable values multiplied by given value.
    ///
    /// The built-in values will remain the same.
    ///
    @inlinable
    public func multiplied(by value: Double) -> SimulationState {
        return SimulationState(values.map { value * $0 },
                               builtins: builtins,
                               model: model)

    }
    
    /// Create a new state by adding each value with corresponding value
    /// of another state.
    ///
    /// The built-in values will remain the same.
    ///
    /// - Precondition: The states must be of the same length.
    ///
    public func adding(_ state: SimulationState) -> SimulationState {
        precondition(model.computedVariables.count == state.model.computedVariables.count,
                     "Simulation states must be of the same length.")
        let result = zip(values, state.values).map {
            (lvalue, rvalue) in lvalue + rvalue
        }
        return SimulationState(result,
                               builtins: builtins,
                               model: model)

    }

    /// Create a new state by subtracting each value with corresponding value
    /// of another state.
    ///
    /// The built-in values will remain the same.
    ///
    /// - Precondition: The states must be of the same length.
    ///
    public func subtracting(_ state: SimulationState) -> SimulationState {
        precondition(model.computedVariables.count == state.model.computedVariables.count,
                     "Simulation states must be of the same length.")
        let result = zip(values, state.values).map {
            (lvalue, rvalue) in lvalue - rvalue
        }
        return SimulationState(result,
                               builtins: builtins,
                               model: model)

    }
    
    /// Create a new state with variable values divided by given value.
    ///
    /// The built-in values will remain the same.
    ///
    @inlinable
    public func divided(by value: Double) -> SimulationState {
        return SimulationState(values.map { value / $0 },
                               builtins: builtins,
                               model: model)

    }

    @inlinable
    public static func *(lhs: Double, rhs: SimulationState) -> SimulationState {
        return rhs.multiplied(by: lhs)
    }

    @inlinable
    public static func *(lhs: SimulationState, rhs: Double) -> SimulationState {
        return lhs.multiplied(by: rhs)
    }
    public static func /(lhs: SimulationState, rhs: Double) -> SimulationState {
        return lhs.divided(by: rhs)
    }
    public var description: String {
        let builtinsStr = builtins.enumerated().map { (index, value) in
            let builtin = model.builtinVariables[index]
            return "\(builtin.name): \(value)"
        }.joined(separator: ",")
        let stateStr = values.enumerated().map { (index, value) in
            let variable = model.computedVariables[index]
            return "\(variable.id): \(value)"
        }.joined(separator: ", ")
        return "[builtins(\(builtinsStr)), values(\(stateStr))]"
    }
    
    public func namedDictionary() -> [String:ForeignValue] {
        fatalError()
    }
}


// TODO: Make proper additive arithmetic once we get rid of the map
extension SimulationState {
    public static func - (lhs: SimulationState, rhs: SimulationState) -> SimulationState {
        return lhs.subtracting(rhs)
    }
    
    public static func + (lhs: SimulationState, rhs: SimulationState) -> SimulationState {
        return lhs.adding(rhs)
    }
    
//    public static var zero: StateVector {
//        return KeyedNumericVector<Key>()
//    }
}

