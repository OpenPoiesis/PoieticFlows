# Simulation and Computation

The Simulator runs the simulation and produces a simulation result as a
collection of time series.

## Overview

The simulator takes the compiled model, initialises the state and computes
desired number of steps of the simulation.

The initial state is created using ``Solver/initializeState(override:time:timeDelta:)``

1. Empty state is created with a zero value for each computed variable
2. Formulas of simulation objects are evaluated in their order of dependency
3. Evaluation result is stored in the state.

Each step is computed using a solver's ``Solver/compute(_:at:timeDelta:)``.

## Topics

### Simulator

- ``Simulator``
- ``SimulationState``
- ``SimulationSystem``
- ``SimulationContext``

### Solver

- ``Solver``
- ``EulerSolver``
- ``RungeKutta4Solver``
- ``NumericVector``

### Formulas

- ``BuiltinVariable``
- ``ExpressionError``

### Functions

- ``BuiltinUnaryOperators``
- ``BuiltinBinaryOperators``
- ``BuiltinFunctions``
- ``GraphicalFunction``
