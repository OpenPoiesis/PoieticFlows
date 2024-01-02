# ``PoieticFlows``

Poietic library for modelling and simulation of the _Stock and Flow_ model.

## Overview

The Poietic package provides functionality for modelling and simulation
in the the model domain of [Stock and Flow](https://en.wikipedia.org/wiki/Stock_and_flow).

The package provides basic concepts from the modelling domain:

- Core computational nodes: ``FlowsMetamodel/Stock``,
``FlowsMetamodel/Flow`` and ``FlowsMetamodel/Auxiliary``
- ``FlowsMetamodel/GraphicalFunction`` node for a function that is represented
 by a graph – set of points in a 2D plane.
- Component for arithmetic formulas ``FormulaComponent`` for all core 
  computational nodes.
- Built-in functions: `abs`, `floor`, `ceiling`, `round`, `power`, `sum`, `min`,
  `max`
- Included [Euler](https://en.wikipedia.org/wiki/Euler_method)
  and [RK4](https://en.wikipedia.org/wiki/Runge–Kutta_methods) solvers: 
  ``EulerSolver`` and ``RungeKutta4Solver`` respectively.

More information about the model is contained in the ``FlowsMetamodel``.


## Topics

### Model and Components

- ``FlowsMetamodel``
- ``FormulaComponent``
- ``FlowComponent``
- ``StockComponent``
- ``PositionComponent``
- ``GraphicalFunction``
- ``ChartComponent``
- ``GraphicalFunctionComponent``
- ``ControlComponent``

### Compiled Model and Compiler

- ``StockFlowView``
- ``CompiledModel``
- ``ComputedVariable``
- ``Compiler``
- ``NodeIssuesError``
- ``NodeIssue``
- ``BoundVariableReference``
- ``IndexRepresentable``

- ``CompiledControlBinding``
- ``CompiledFlow``
- ``CompiledGraphicalFunction``
- ``CompiledObject``
- ``CompiledStock``

- ``BoundBuiltinVariable``
- ``BoundComponent``

### Simulation

- ``Simulator``
- ``SimulationState``
- ``Solver``
- ``EulerSolver``
- ``RungeKutta4Solver``

### Built-in Functions

- ``BuiltinUnaryOperators``
- ``BuiltinBinaryOperators``
- ``BuiltinFunctions``

