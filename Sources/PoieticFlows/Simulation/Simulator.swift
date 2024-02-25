//
//  Simulator.swift
//  
//
//  Created by Stefan Urbanek on 25/08/2023.
//

import PoieticCore

/// Object for controlling a simulation session.
///
public class Simulator {
    // Object memory in which the simulator operates.
    // public var memory: ObjectMemory
    
    /// List of systems that the simulator will call during various stages
    /// of the simulation process.
    ///
    public var systems: [any SimulationSystem]
    
    /// Solver to be used for the simulation.
    public var solverType: Solver.Type
    public var solver: Solver?
    
    // Simulation parameters

    /// Initial time of the simulation.
    public var initialTime: Double = 0
    
    /// Time between simulation steps.
    public var timeDelta: Double = 1.0
    
    // MARK: - Simulator state
    
    /// Current simulation step
    public var currentStep: Int = 0
    public var currentTime: Double = 0
    public var currentState: SimulationState?
    public var frame: MutableFrame?
    public var compiledModel: CompiledModel?
    
    /// Collected data
    /// TODO: Make this an object, so we can derive more info
    public var output: [SimulationState]
    
    // MARK: - Initialisation
    
    // FIXME: [REFACTORING] We do not need memory here any more.
    public init(memory: ObjectMemory, solverType: Solver.Type = EulerSolver.self) {
        // self.memory = memory
        self.solverType = solverType
        self.currentState = nil
        
        // TODO: Make this not built-in
        systems = [
            ControlBindingSystem()
        ]
        output = []
    }

    // MARK: - Compilation methods
    
    @available(*, deprecated, message: "This was a convenience. Compile separately.")
    public func compile(_ frame: MutableFrame) throws {
        self.frame = frame
        // FIXME: [IMPORTANT] What if frame != view.frame???
        let compiler = Compiler(frame: frame)
        
//        let context = CompilationContext(frame: frame)
//        for system in systems {
//            system.prepareForCompilation(context)
//        }

        let compiledModel = try compiler.compile()

//        for system in systems {
//            system.didCompile(context, model: compiledModel)
//        }
//        
        self.compiledModel = compiledModel
    }
    
    // MARK: - Simulation methods
    
    public func initializeSimulation(override: [ObjectID:Double] = [:]) {
        guard let frame = self.frame else {
            fatalError("Trying to initialize a simulation without a frame")
        }
        guard let model = self.compiledModel else {
            fatalError("Trying to step a simulation without a compiled model")
        }
        currentStep = 0
        currentTime = initialTime
        
        solver = solverType.init(model)
        currentState = solver!.initialize(time: currentTime,
                                          override: override,
                                          timeDelta: timeDelta)

        output.removeAll()
        output.append(currentState!)
        
        let context = SimulationContext(
            time: currentTime,
            timeDelta: timeDelta,
            step: currentStep,
            state: currentState!,
            frame: frame,
            model: model)

        for system in systems {
            system.didInitialize(context)
        }
    }
    
    /// Perform one step of the simulation.
    ///
    /// - Precondition: Frame and model must exist.
    ///
    public func step() {
        guard let frame = self.frame else {
            fatalError("Trying to step a simulation without a frame")
        }
        guard let model = self.compiledModel else {
            fatalError("Trying to step a simulation without a compiled model")
        }
        guard let solver = self.solver else {
            fatalError("Trying to step a simulation without a solver")
        }
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
            frame: frame,
            model: model)

        for system in systems {
            system.didStep(context)
        }
    }
    
    /// Run the simulation for given number of steps.
    public func run(_ steps: Int) {
        guard let frame = self.frame else {
            fatalError("Trying to run a simulation without a frame")
        }
        guard let model = self.compiledModel else {
            fatalError("Trying to run a simulation without a compiled model")
        }

        for _ in (1...steps) {
            step()
            output.append(self.currentState!)
        }
        
        let context = SimulationContext(
            time: currentTime,
            timeDelta: timeDelta,
            step: currentStep,
            state: currentState!,
            frame: frame,
            model: model)
        for system in systems {
            system.didRun(context)
        }
    }
    
    /// Get data series for variable at given index.
    ///
    public func dataSeries(index: Int) -> [Double] {
        return output.map { $0[index] }
    }
    
    /// Get series of time points.
    public var timePoints: [Double] {
        guard let timeIndex = compiledModel?.builtinTimeIndex else {
            fatalError("Unable to get time variable index. Hint: Check compiled model.")
        }
        // FIXME: [REFACTORING] We need a cleaner way how to get this.
        return output.map { try! $0.builtins[timeIndex].doubleValue() }
    }
}
