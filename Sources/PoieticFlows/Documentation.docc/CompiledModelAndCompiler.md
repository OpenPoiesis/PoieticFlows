# Compiled Model and Compiler

Compiler creates a compiled model, which is an internal representation of
a design that can be simulated.

## Overview

A design represents user's idea, user's creation. To be able to perform the
computation, the design has to be validated and converted into a
representation understandable by a simulator. That conversion is done by
the compiler.

![Compiler Overview](compiler-overview)


## Topics

### Compiled Model

- ``Compiler``
- ``CompiledModel``
- ``SimulationDefaults``
- ``ComputationalRepresentation``
- ``SimulationObject``
- ``StateVariable``
- ``BuiltinVariable``
- ``CompiledBuiltin``
- ``CompiledStock``
- ``CompiledDelay``
- ``CompiledGraphicalFunction``
- ``CompiledControlBinding``
- ``SimulationVariableType``

### Errors

- ``NodeIssuesError``
- ``NodeIssue``

### Bound Expression

- ``BoundExpression``
- ``BoundVariable``
- ``ExpressionError``
- ``bindExpression(_:variables:names:functions:)``
