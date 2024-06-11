//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 10/03/2024.
//

import PoieticCore

extension Variable {
    // MARK: Built-in variables
    // ---------------------------------------------------------------------
    /// Built-in variable reference that represents the simulation time.
    ///
    nonisolated(unsafe) public static let TimeVariable = Variable(
        name: "time",
        abstract: "Current simulation time"
    )

    // TODO: Rename to 'dt'?
    /// Built-in variable reference that represents the time delta.
    ///
    nonisolated(unsafe) public static let TimeDeltaVariable = Variable(
        name: "time_delta",
        abstract: "Simulation time delta - time between discrete steps of the simulation."
    )
    
    // TODO: Add 'initial_time'
    // TODO: Add 'final_time'
    // TODO: Add 'simulation_step'
}
