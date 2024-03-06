//
//  EulerSolver.swift
//  
//
//  Created by Stefan Urbanek on 30/07/2022.
//

/// Solver that integrates using the Euler method.
///
/// - SeeAlso: [Euler method](https://en.wikipedia.org/wiki/Euler_method)
///
public class EulerSolver: Solver {
    public override func compute(_ current: SimulationState,
                                 at time: Double,
                                 timeDelta: Double = 1.0) throws -> SimulationState {
        let stage = try prepareStage(current, at: time, timeDelta: timeDelta)
        let delta = try difference(at: time,
                                   with: stage,
                                   timeDelta: timeDelta)
        
        let result = stage + (delta * timeDelta)
        return result
    }

}
