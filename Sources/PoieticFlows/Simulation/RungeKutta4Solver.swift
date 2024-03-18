//
//  RK4Solver.swift
//  
//
//  Created by Stefan Urbanek on 30/07/2022.
//



/// Solver that integrates using the Runge Kutta 4 method.
///
/// - SeeAlso: [Runge Kutta methods](https://en.wikipedia.org/wiki/Runge–Kutta_methods)
/// - Important: Does not work well with non-negative stocks.
///
public class RungeKutta4Solver: Solver {
    /*
        RK4:
     
        dy/dt = f(t,y)
         
        k1 = f(tn, yn)
        k2 = f(tn + h/2, yn + h*k1/2)
        k3 = f(tn + h/2, yn + h*k2/2)
        k4 = f(tn + h, yn + h*k3)

     yn+1 = yn + 1/6(k1 + 2k2 + 2k3 + k4)*h
     tn+1 = tn + h
    */
    // TODO: Does not work well with non-negative stocks.
    // Is this the issue?
    // https://arxiv.org/abs/2005.06268
    // Paper: "Positivity-Preserving Adaptive Runge-Kutta Methods"
    
    override public func compute(_ current: SimulationState,
                                 at time: Double,
                                 timeDelta: Double = 1.0) throws -> SimulationState {
        var stage1 = current
        updateBuiltins(&stage1, time: time, timeDelta: timeDelta)
        let k1 = try stockDifference(state: stage1,
                                        at: time,
                                        timeDelta: timeDelta)

        var stage2 = current
        updateBuiltins(&stage2, time: time, timeDelta: timeDelta)
        accumulateStocks(&stage2, delta: timeDelta * (k1 / 2))
        let k2 = try stockDifference(state: stage2,
                                        at: time + timeDelta / 2,
                                        timeDelta: timeDelta)

        var stage3 = current
        updateBuiltins(&stage3, time: time, timeDelta: timeDelta)
        accumulateStocks(&stage3, delta: timeDelta * (k2 / 2))
        let k3 = try stockDifference(state: stage3,
                                        at: time + timeDelta / 2,
                                        timeDelta: timeDelta)

        var stage4 = current
        updateBuiltins(&stage4, time: time, timeDelta: timeDelta)
        accumulateStocks(&stage4, delta: timeDelta * (k2 / 2))
        let k4 = try stockDifference(state: stage3,
                                        at: time + timeDelta / 2,
                                        timeDelta: timeDelta)

        let resultDelta = (1.0/6.0) * timeDelta * (k1 + (2*k2) + (2*k3) + k4)
        var result = current
        updateBuiltins(&result, time: time, timeDelta: timeDelta)
        accumulateStocks(&result, delta: resultDelta)
        try update(&result, at: time, timeDelta: timeDelta)

        return result
    }
}
