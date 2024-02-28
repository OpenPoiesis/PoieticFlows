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
    public var initialTime: Double = 0
    
    /// Time between simulation steps.
    public var timeDelta: Double = 1.0
    
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
    
    public init(model: CompiledModel, solverType: Solver.Type = EulerSolver.self) {
        self.compiledModel = model
        self.solverType = solverType
        self.solver = solverType.init(compiledModel)
        self.currentState = nil
        output = []
    }

    // MARK: - Simulation methods

    /// Initialize the simulation state with existing frame.
    ///
    @discardableResult
    public func initializeState(override: [ObjectID:Double] = [:]) -> SimulationState {
        currentStep = 0
        currentTime = initialTime
        
        currentState = solver.initializeState(time: currentTime,
                                         override: override,
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
    public func step() {
        currentStep += 1
        currentTime += timeDelta
        
        currentState = solver.compute(currentState!,
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
    public func run(_ steps: Int) {
        for _ in (1...steps) {
            step()
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
        return output.map { $0[index] }
    }
    
    /// Return a mapping of control IDs and values of their targets.
    ///
    /// The values are obtained from the current simulation state.
    ///
    public func controlValues() -> [ObjectID:Double] {
        precondition(currentState != nil,
                    "Trying to get control values without initialized state")
        // TODO: [REFACTORING] Move to SimulationState
        // TODO: This is redundant, it is extracted in the control nodes
        var values: [ObjectID:Double] = [:]
        for binding in compiledModel.valueBindings {
            values[binding.control] = currentState!.computedValues[binding.variableIndex]
        }
        return values
    }
    /// Get series of time points.
    public var timePoints: [Double] {
        // FIXME: [REFACTORING] We need a cleaner way how to get this.
        return output.map {
            try! $0.builtins[compiledModel.builtinTimeIndex].doubleValue()
        }
    }
}
