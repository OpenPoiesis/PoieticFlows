//
//  Simulator.swift
//  
//
//  Created by Stefan Urbanek on 25/08/2023.
//

import PoieticCore

public protocol SimulatorDelegate {
    func simulatorDidInitialize(_ simulator: Simulator, context: SimulationContext)
    func simulatorDidStep(_ simulator: Simulator, context: SimulationContext)
    func simulatorDidRun(_ simulator: Simulator, context: SimulationContext)
}

/// Object for controlling a simulation session.
///
public class Simulator {
    var delegate: SimulatorDelegate?
    
    /// Solver to be used for the simulation.
    public var solverType: Solver.Type
    public var solver: Solver
    
    // Simulation parameters

    /// Initial time of the simulation.
    public var initialTime: Double
    
    /// Time between simulation steps.
    public var timeDelta: Double
    
    // MARK: - Simulator state
    
    /// Current simulation step
    public var currentStep: Int = 0
    public var currentTime: Double = 0
    // TODO: Make currentState non-optional
    public var currentState: SimulationState!
    public var compiledModel: CompiledModel
    
    /// Collected data
    /// TODO: Make this an object, so we can derive more info
    public var output: [SimulationState]
    
    // MARK: - Initialisation
    
    /// Creates and initialises a simulator.
    ///
    /// - Properties:
    ///   - model: Compiled simulation model that describes the computation.
    ///   - solverType: Type of the solver to be used.
    ///
    /// The simulator is initialised by creating a new solver and initialising
    /// simulation values from the ``CompiledModel/simulationDefaults`` such as
    /// initial time or time delta (_dt_). If the defaults are not provided then
    /// the following values are used:
    ///
    /// - `initialTime = 0.0`
    /// - `timeDelta = 1.0`
    ///
    public init(model: CompiledModel, solverType: Solver.Type = EulerSolver.self) {
        self.compiledModel = model
        self.solverType = solverType
        self.solver = solverType.init(compiledModel)
        self.currentState = nil
        if let defaults = model.simulationDefaults {
            self.initialTime = defaults.initialTime
            self.timeDelta = defaults.timeDelta
        }
        else {
            self.initialTime = 0.0
            self.timeDelta = 1.0
        }
        
        output = []
    }

    // MARK: - Simulation methods

    /// Initialise the simulation state with existing frame.
    ///
    /// The initialisation process:
    /// - The current time is set to ``initialTime``.
    /// - All output is cleared.
    /// - Initial state is created and added to the output.
    ///
    /// If a delegate is set, then delegate's
    /// ``SimulatorDelegate/simulatorDidInitialize(_:context:)`` is called.
    ///
    /// - Parameters:
    ///     - override: Computed values to override. The keys are computed
    ///       node IDs and dictionary values are values to be used instead
    ///       the ones specified in the original nodes.
    ///
    /// - Returns: Initial state.
    ///
    @discardableResult
    public func initializeState(override: [ObjectID:Double] = [:]) throws -> SimulationState {
        currentStep = 0
        currentTime = initialTime
        
        currentState = try solver.initializeState(override: override,
                                                  time: currentTime,
                                                  timeDelta: timeDelta)

        output.removeAll()
        output.append(currentState!)
        
        let context = SimulationContext(
            time: currentTime,
            timeDelta: timeDelta,
            step: currentStep,
            state: currentState!,
            model: compiledModel)

        delegate?.simulatorDidInitialize(self, context: context)

        return currentState!
    }
    
    /// Perform one step of the simulation.
    ///
    /// - Precondition: Frame and model must exist.
    ///
    public func step() throws {
        currentStep += 1
        currentTime += timeDelta
        
        currentState = try solver.compute(currentState!,
                                          at: currentTime,
                                          timeDelta: timeDelta)
        
        let context = SimulationContext(
            time: currentTime,
            timeDelta: timeDelta,
            step: currentStep,
            state: currentState!,
            model: compiledModel)

        delegate?.simulatorDidStep(self, context: context)
    }
    
    /// Run the simulation for given number of steps.
    ///
    public func run(_ steps: Int) throws {
        for _ in (1...steps) {
            try step()
            output.append(self.currentState!)
        }

        let context = SimulationContext(
            time: currentTime,
            timeDelta: timeDelta,
            step: currentStep,
            state: currentState!,
            model: compiledModel)
        delegate?.simulatorDidRun(self, context: context)
    }
    
    /// Get data series for computed variable at given index.
    ///
    public func dataSeries(index: Int) -> [Double] {
        return output.map { try! $0[index].doubleValue() }
    }
    
    /// Return a mapping of control IDs and values of their targets.
    ///
    /// The values are obtained from the current simulation state.
    ///
    /// - SeeAlso: ``CompiledModel/valueBindings``,
    ///   ``PoieticCore/ObjectType/Control``
    ///
    public func controlValues() -> [ObjectID:Double] {
        precondition(currentState != nil,
                    "Trying to get control values without initialized state")
        // TODO: [REFACTORING] Move to SimulationState
        // TODO: This is redundant, it is extracted in the control nodes
        var values: [ObjectID:Double] = [:]
        for binding in compiledModel.valueBindings {
            values[binding.control] = currentState![double: binding.variableIndex]
        }
        return values
    }
    
    /// Get series of time points.
    ///
    /// - SeeAlso: ``CompiledModel/timeVariableIndex``
    ///
    public var timePoints: [Double] {
        // TODO: We need a cleaner way how to get this.
        return output.map {
            try! $0[compiledModel.timeVariableIndex].doubleValue()
        }
    }
}
