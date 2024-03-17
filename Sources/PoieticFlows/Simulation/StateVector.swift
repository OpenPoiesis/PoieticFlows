//
//  StateVector.swift
//  
//
//  Created by Stefan Urbanek on 30/07/2022.
//

import PoieticCore


// FIXME: Consolidate SimulationState and SimulationContext?
// FIXME: Extract the stock/flows vector

/// A simple vector-like structure to hold an unordered collection of numeric
/// values that can be accessed by key. Simple arithmetic operations can be done
/// with the structure, such as addition, subtraction and multiplication
/// by a scalar value.
///
public struct SimulationState: CustomStringConvertible {
    // FIXME: Add time and maybe step
    
    public typealias Index = Int
    
    public let model: CompiledModel

    public var values: [Variant]
    
    var time: Double {
        // TODO: Make this a native property?
        let timeValue = values[model.timeVariableIndex]
        return try! timeValue.doubleValue()
    }

    // FIXME: Swift 6: Replace with [Variant] and use RangeSet
//    public var internalStates: [SimulationState.Index:[Variant]]
    
    /// Create a simulation state with all variables set to zero.
    ///
    /// The list of builtins and simulation variables will be initialised
    /// according to the count of the respective variables in the compiled
    /// model.
    ///
    public init(model: CompiledModel) {
        self.model = model
        self.values = Array(repeating: Variant(0), count: model.stateVariables.count)
//        self.internalStates = [:]
    }
    
    public init(_ values: [Variant], model: CompiledModel) {
        precondition(values.count == model.stateVariables.count,
                     "Count of values (\(values.count) does not match required items count \(model.stateVariables.count)")
        self.model = model
        self.values = values
//        self.internalStates = [:]
    }

    /// Get or set a simulation variable by reference.
    ///
    @inlinable
    public subscript(ref: Index) -> Variant {
        get {
            return values[ref]
        }
        set(value) {
            values[ref] = value
        }
    }
    
    /// Get or set a simulation variable as double by reference.
    ///
    /// This subscript should be used when it is guaranteed that the value
    /// is convertible to _double_, such as values for stocks or flows.
    ///
    @inlinable
    public subscript(double ref: Index) -> Double {
        // FIXME: [REFACTORING] Alternative names: func double(at:)
        get {
            do {
                return try values[ref].doubleValue()
            }
            catch {
                fatalError("Unexpected non-double state value at \(ref)")
            }
        }
        set(value) {
            values[ref] = Variant(value)
        }
    }

    
    public var description: String {
        // FIXME: [REFACTORING] [IMPORTANT] Requires state variable to have name
        fatalError("re-implement this")
//        let valuesString = values.enumerated().map { (index, value) in
//            let variable = model.stateVariables[index]
//            return "\(variable.name): \(value)"
//        }.joined(separator: ", ")
//        return "[\(valuesString)]"
    }
}



