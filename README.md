# Poietic Flows

Package for simulation of
[Stock and Flow](https://en.wikipedia.org/wiki/Stock_and_flow) models.


See the [Poietic Tool](https://github.com/OpenPoiesis/poietic-tool) for
a command-line tool that uses this library to manipulate
and run the models.

## Features

### Model Components

The library provides the following nodes to form stock-flow models:

- Stock and Flow computation model nodes:
    - Stock – value container, accumulator
    - Flow – flow of material between stocks
    - Auxiliary – stand-alone computation formula or a constant
    - Graphical Function – a function defined by a set of 2D _(x, y)_ points
- Visualisation nodes:
    - Chart – node representing a chart plotting one or multiple nodes with a computed value
- Solvers:
    - [Euler](https://en.wikipedia.org/wiki/Euler_method)
    - [Runge-Kutta 4](https://en.wikipedia.org/wiki/Runge–Kutta_methods)
- Experimental features:
    - Delay node – node providing a delay of a value in time

See [Metamodel](https://openpoiesis.github.io/poietic-flows/documentation/poieticflows/metamodel)
for more information.

### Arithmetic Expressions

The arithmetic expression supports the following built-in functions:
`abs(x)`, `floor(x)`, `ceiling(x)`, `round(x)`, `power(x,e)`,
`sum(a,c,...)`, `min(a,b,c,...)`, `max(a,b,c,...)`.

Supported logical operations and conditionals: `if(cond,true_val,false_val)`,
`not(a)`, `or(a,b,...)`, `and(a,b,...)`.

- See [Formulas](https://openpoiesis.github.io/poietic-flows/documentation/poieticflows/formulas)
  documentation) for more information.

## Documentation

- Stock and Flow package: [PoieticFlows](https://openpoiesis.github.io/poietic-flows/documentation/poieticflows/)

## See Also

- Poietic Command-line Tool: [repository](https://github.com/OpenPoiesis/poietic-tool)
- Poietic Core: [repository](https://github.com/openpoiesis/poietic-core),
  [documentation](https://openpoiesis.github.io/poietic-core/documentation/poieticcore/)

## Author

[Stefan Urbanek](mailto:stefan.urbanek@gmail.com)

