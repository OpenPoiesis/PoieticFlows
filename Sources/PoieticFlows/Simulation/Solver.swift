//
//  Solver.swift
//  
//
//  Created by Stefan Urbanek on 27/07/2022.
//
import PoieticCore

/**
 
 initializeState()
    newState()
    builtins
 compute(current)
    new = prepareStage(current)
    delta
    add delta
    return new
 
 
 */

/*
 
 INIT:
    FOR EACH stock
        compute value # requires aux
 
 ITERATE:
 
    STORE initial state # make it current/last state
 
    FOR EACH STAGE:
        FOR EACH aux
            compute value
        FOR EACH flow
            compute flow rate
    ESTIMATE flows
 
 */

/// An abstract class for equations solvers.
///
/// Purpose of a solver is to initialise values of the nodes and then
/// to compute and integrate each step of the simulation.
///
/// Solver is using a ``CompiledModel``, which is guaranteed to be correct
/// for computation.
///
/// The main method of the solver is ``compute(_:at:timeDelta:)``, which is
/// provided by concrete subclasses of the solver.
///
/// To use the solver, it needs to be initialised first, then the
/// ``compute(_:at:timeDelta:)`` is called for each step of the simulation.
///
/// ```swift
/// // Assume we have a compiled model.
/// let compiled: CompiledModel
///
/// let solver = EulerSolver(compiled)
///
/// var state: StateVector = solver.initialize()
/// var time: Double = 0.0
/// let timeDelta: Double = 1.0
///
/// for step in (1...100) {
///     time += timeDelta
///     state = try solver.compute(at: time,
///                                with: state,
///                                timeDelta: timeDelta)
///     print(state)
/// }
/// ```
///
/// To get a solver by name:
///
/// ```swift
/// // Assume this is given, provided by the user or in a configuration.
/// let solverTypeName: String
/// guard let solverType = Solver.registeredSolvers[solverTypeName] else {
///     fatalError("Unknown solver: \(solverTypeName)")
/// }
///
/// let solver = solverType.init()
///
/// // ... now we can use the solver
/// ```
///
public class Solver {
    /// Compiled model that the solver is solving for.
    ///
    /// The compiled model is created using the ``Compiler``.
    ///
    ///
    /// - SeeAlso: ``Compiler``
    ///
    public let compiledModel: CompiledModel
    
    /// Values of constants (auxiliaries) to be replaced.
    ///
    /// This mapping is typically used to replace values of constants by
    /// controls.
    ///
    public var constants: [ObjectID:Variant]

    /// Return list of registered solver names.
    ///
    /// The list is alphabetically sorted, as the typical usage of this method is
    /// to display the list to the user.
    ///
    public static var registeredSolverNames: [String] {
        return registeredSolvers.keys.sorted()
    }
    
    /// A dictionary of registered solver types.
    ///
    /// The key is the solver name and the value is the solver class (type).
    ///
    public static private(set) var registeredSolvers: [String:Solver.Type] = [
        "euler": EulerSolver.self,
        "rk4": RungeKutta4Solver.self,
    ]
    
    /// Register a solver within the solver registry.
    ///
    /// Registered solvers can be retrieved through the ``registeredSolvers``
    /// dictionary.
    ///
    /// - Note: Solvers do not have to be registered if there is other method
    /// provided for the user to get a desired solver.
    ///
    public static func registerSolver(name: String, solver: Solver.Type) {
        registeredSolvers[name] = solver
    }
    
    /// Create a solver.
    ///
    /// The provided ``CompiledModel`` is typically created by the ``Compiler``.
    /// It is guaranteed to be consistent and useable by the solver without
    /// any issues. Design that contains errors that would prevent correct
    /// computation are prevented from being compiled.
    ///
    /// - Note: Do not use this method on this abstract class. Use a concrete
    ///   solver subclass, such as ``EulerSolver`` or ``RungeKutta4Solver``
    ///
    public required init(_ compiledModel: CompiledModel) {
        // TODO: How to make this private? (see note below)
        // If this method is made private, we can't create instances of solver
        // if we get the solver type through registeredSolvers.
        //
        
        self.compiledModel = compiledModel
        // TODO: Pass overrides in init()
        self.constants = [:]
    }

    /// Initialise the computation state.
    ///
    /// - Parameters:
    ///     - `time`: Initial time. This parameter is usually not used, but
    ///     some computations in the model might use it. Default value is 0.0
    ///     - `override`: Dictionary of values to override during initialisation.
    ///     The values of nodes that are present in the dictionary will not be
    ///     evaluated, but the value from the dictionary will be used.
    ///
    /// This function computes the initial state of the computation by
    /// evaluating all the nodes in the order of their dependency by parameter.
    ///
    /// - Returns: `StateVector` with initialised values.
    ///
    /// - Precondition: The compiled model must be valid. If the model
    ///   is not valid and contains elements that can not be computed
    ///   correctly, such as invalid variable references, this function
    ///   will fail.
    ///
    /// - Note: Use only constants in the `override` dictionary. Even-though
    ///   any node value can be provided, in the future only constants will
    ///   be allowed.
    ///
    /// - Note: Values for stocks in the `override` dictionary will be used
    ///   only during initialisation.
    ///
    public func initializeState(override: [ObjectID:Double] = [:],
                                time: Double = 0.0,
                                timeDelta: Double = 1.0) throws -> SimulationState {

        // FIXME: make override [ObjectID:Variant] and validate types(?)
        self.constants = [:]
        var state = SimulationState(model: compiledModel)
        updateBuiltins(&state, time: time, timeDelta: timeDelta)

        for (index, object) in compiledModel.computedObjects.enumerated() {
            if let value = override[object.id] {
                state[object.variableIndex] = Variant(value)

                // Keep only overrides for auxiliaries
                // FIXME: [REFACTORING] simplify
                // TODO: Introduce object.type enum? or isAuxiliary? (too specific)
                if compiledModel.auxiliaries.contains(where: { $0.id == object.id }) {
                    self.constants[object.id] = Variant(value)
                }
            }
            else {
                let result = try evaluate(objectAt: index,
                                          with: &state)
                state[object.variableIndex] = result
            }
        }
        
        return state
    }

    public func updateBuiltins(_ state: inout SimulationState,
                               time: Double = 0.0,
                               timeDelta: Double = 1.0) {
        
        for variable in compiledModel.builtins {
            let value: Variant

            switch variable.builtin {
            case .time:
                value = Variant(time)
            case .timeDelta:
                value = Variant(timeDelta)
            }
            state[variable.variableIndex] = value
        }
    }

    /// Compute auxiliaries and stocks for given stage of the computation step.
    ///
    /// If solvers use multiple stages, they must call this method if they do
    /// not prepare the state by themselves.
    ///
    /// The ``EulerSolver`` uses only one stage, the ``RungeKutta4Solver`` uses
    /// 4 stages.
    ///
    func update(_ state: inout SimulationState,
                at time: Double,
                timeDelta: Double = 1.0) throws {
        
        for aux in compiledModel.auxiliaries {
            let value = try evaluate(objectAt: aux.objectIndex,
                                     with: &state)
            state[aux.variableIndex] = value
        }

        for flow in compiledModel.flows {
            let value = try evaluate(objectAt: flow.objectIndex,
                                     with: &state)
            state[flow.variableIndex] = value
        }
    }
    

    /// Evaluate an expression within the context of a simulation state.
    ///
    /// - Parameters:
    ///     - expression: An arithmetic expression to be evaluated
    ///     - state: simulation state within which the expression is evaluated
    ///     - time: simulation time at which the evaluation takes place
    ///     - timeDelta: time difference between steps of the simulation
    ///
    /// - Returns: an evaluated value of the expression.
    ///
    public func evaluate(objectAt index: Int,
                         with state: inout SimulationState) throws -> Variant {
        let object = compiledModel.computedObjects[index]
        if let value = constants[object.id] {
            return value
        }
        
        switch object.computation {

        case let .formula(expression):
            return try evaluate(expression: expression,
                                with: state)
            
        case let .graphicalFunction(function, index):
            let value = state[index]
            return try function.apply([value])
        case let .delay(delay):
            return try evaluate(delay: delay,
                                with: &state)
        }
    }

    public func evaluate(expression: BoundExpression,
                         with state: SimulationState) throws -> Variant {
        switch expression {
        case let .value(value):
            return value

        case let .binary(op, lhs, rhs):
            return try op.apply([try evaluate(expression: lhs, with: state),
                                 try evaluate(expression: rhs, with: state)])

        case let .unary(op, operand):
            return try op.apply([try evaluate(expression: operand, with: state)])

        case let .function(functionRef, arguments):
            let evaluatedArgs = try arguments.map {
                try evaluate(expression: $0, with: state)
            }
            return try functionRef.apply(evaluatedArgs)

        case let .variable(variable):
            return state[variable.index]
        }
    }

    public func evaluate(delay: CompiledDelay,
                         with state: inout SimulationState) throws -> Variant {
        // FIXME: Propagate time or include time in the state
        // FIXME: Numeric delay
        let inputValue = try! state[delay.parameterIndex].doubleValue()
        let queue = state[delay.valueQueueIndex]
        let outputValue: Variant
        
        // TODO: This assumes time starts at 0.0
        if state.time < delay.duration {
            var items: [Double] = (try? queue.doubleArray()) ?? []
            items.append(inputValue)
            state[delay.valueQueueIndex] = Variant(items)
            // TODO: Use first input value
            outputValue = delay.initialValue!
        }
        else {
            var items: [Double] = (try? queue.doubleArray()) ?? []
            items.append(inputValue)
            let output = items.remove(at:0)
            state[delay.valueQueueIndex] = Variant(items)
            outputValue = Variant(output)
        }
        return outputValue
    }
    
    /// - Important: Do not use for anything but testing or debugging.
    ///
    func computeStockDelta(_ id: ObjectID,
                           at time: Double,
                           with state: inout SimulationState) throws -> Double {
        let stock = compiledModel.compiledStock(id)
        return try self.computeStockDelta(stock,
                                          at: time,
                                          with: &state)
    }
    
    // TODO: [RELEASE] Review documentation
    /// Compute a difference of a stock.
    ///
    /// This function computes amount which is expected to be drained from/
    /// filled in a stock.
    ///
    /// - Parameters:
    ///     - stock: Stock for which the difference is being computed
    ///     - time: Simulation time at which we are computing
    ///     - state: Simulation state vector
    ///
    /// The flows in the state vector will be updated based on constraints.
    /// For example, if the model contains non-negative stocks and a flow
    /// trains a stock with multiple outflows, then other outflows must be
    /// adjusted or set to zero.
    ///
    /// - Note: Current implementation considers are flows to be one-directional
    ///         flows. Flow with negative value, which is in fact an outflow,
    ///         will be ignored.
    ///
    /// - Precondition: The simulation state vector must have all variables
    ///   that are required to compute the stock difference.
    ///
    public func computeStockDelta(_ stock: CompiledStock,
                                  at time: Double,
                                  with state: inout SimulationState) throws -> Double {
        var totalInflow: Double = 0.0
        var totalOutflow: Double = 0.0
        
        // Compute inflow (regardless whether we allow negative)
        //
        for inflow in stock.inflows {
            // TODO: All flows are uni-flows for now. Ignore negative inflows.
            totalInflow += max(state[double: inflow], 0)
        }
        
        if stock.allowsNegative {
            for outflow in stock.outflows {
                totalOutflow += state[double: outflow]
            }
        }
        else {
            // Compute with a constraint: stock can not be negative
            //
            // We have:
            // - current stock values
            // - expected flow values
            // We need:
            // - get actual flow values based on stock non-negative constraint
            
            // TODO: Add other ways of draining non-negative stocks, not only priority based
            
            // We are looking at a stock, and we know expected inflow and
            // expected outflow. Outflow must be less or equal to the
            // expected inflow plus current state of the stock.
            //
            // Maximum outflow that we can drain from the stock. It is the
            // current value of the stock with aggregate of all inflows.
            //
            var availableOutflow: Double = state[double: stock.variableIndex] + totalInflow
            let initialAvailableOutflow: Double = availableOutflow

            for outflow in stock.outflows {
                // Assumed outflow value can not be greater than what we
                // have in the stock. We either take it all or whatever is
                // expected to be drained.
                //
                let actualOutflow = min(availableOutflow,
                                        max(state[double: outflow], 0))
                
                totalOutflow += actualOutflow
                // We drain the stock
                availableOutflow -= actualOutflow
                
                // Adjust the flow value to the value actually drained,
                // so we do not fill another stock with something that we
                // did not drain.
                //
                // FIXME: We are changing the current state, we should be changing some "estimated state"
                state[double: outflow] = actualOutflow

                // Sanity check. This should always pass, unless we did
                // something wrong above.
                assert(actualOutflow >= 0.0,
                       "Resulting state must be non-negative")
            }
            // Another sanity check. This should always pass, unless we did
            // something wrong above.
            assert(totalOutflow <= initialAvailableOutflow,
                   "Resulting total outflow must not exceed initial available outflow")

        }
        let delta = totalInflow - totalOutflow
        return delta
    }
    
    /// Comptes differences of stocks.
    ///
    /// - Returns: A state vector that contains difference values for each
    /// stock.
    ///
    public func stockDifference(state current: SimulationState,
                                at time: Double,
                                timeDelta: Double = 1.0) throws -> NumericVector {
        // Get a mutable copy of the state.
        var estimate = current
        
        // 4. Compute stock levels
        //
        var deltaVector = NumericVector(zeroCount: compiledModel.stocks.count)

        for (index, stock) in compiledModel.stocks.enumerated() {
            let delta = try computeStockDelta(stock, at: time, with: &estimate)
            let dtAdjusted = delta * timeDelta
            let newValue = estimate[double: stock.variableIndex] + dtAdjusted
            estimate[stock.variableIndex] = Variant(newValue)
            deltaVector[index] = dtAdjusted
        }
        return deltaVector
    }
    
    // FIXME: [REFACTORING] Rename to "accumulateStocks"
    public func addStocks(_ state: inout SimulationState, delta: NumericVector) {
        for (stock, stockDelta) in zip(compiledModel.stocks, delta) {
            let value = try! state[stock.variableIndex].doubleValue()
            state[stock.variableIndex] = Variant(value + stockDelta)
        }
    }
    
    /// Compute the next state vector.
    ///
    /// - Parameters:
    ///     - time: Time of the computation step.
    ///     - state: Previous state of the computation.
    ///     - timeDelta: Time delta of the computation step.
    ///
    /// - Returns: Computed state vector.
    ///
    /// - Important: Do not call this method directly. Subclasses are
    ///   expected to implement this method.
    ///
    public func compute(_ state: SimulationState,
                        at time: Double,
                        timeDelta: Double = 1.0) throws -> SimulationState {
        fatalError("Subclasses of Solver are expected to override \(#function)")
    }
}
