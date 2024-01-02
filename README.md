# Poietic Flows

Systems Dynamics Modelling and simulation toolkit based on the
[Stock and Flow](https://en.wikipedia.org/wiki/Stock_and_flow) methodology.

Core functionality:

- Creation and iterative design of [stock and flow](https://en.wikipedia.org/wiki/Stock_and_flow) models.
- Simulation of systems dynamics models.

## Features

Current:

- [Stock and Flow](https://en.wikipedia.org/wiki/Stock_and_flow) model
    - Implemented nodes: Stock, Flow, Auxiliary, Graphical Function
    - Stocks can be either non-negative or can allow negative values
    - Included [Euler](https://en.wikipedia.org/wiki/Euler_method) and [RK4](https://en.wikipedia.org/wiki/Runge–Kutta_methods) solvers
- Simple arithmetic expressions (formulas)
    - Built-in functions: abs, floor, ceiling, round, power, sum, min, max
- Whole editing history is preserved.
- Editing is non-destructive and can be reversed using undo and
  redo commands.
- Exports:
    - [Graphviz](https://graphviz.org) dot files.
    - Export to CSV.
    - Charts to [Gnuplot](http://gnuplot.info)

See also: [PoieticCore](https://github.com/OpenPoiesis/PoieticCore).

Planned:

- More useful built-in functions and variables for the Stock and Flow model.
- Sub-systems.

## Demos

Example models can be found in the [Demos repository](https://github.com/OpenPoiesis/Demos).


## Documentation

- [PoieticFlows](https://openpoiesis.github.io/PoieticFlows/documentation/poieticflows/)
- [PoieticCore](https://openpoiesis.github.io/PoieticCore/documentation/poieticcore/) (underlying graph design framework)

## Tool

At the moment, the only user-facing interface is a command-line tool called
``poietic``. The available commands are:

```
  new                     Create an empty design.
  info                    Get information about the design
  list                    List all nodes and edges
  describe                Describe an object
  edit                    Edit an object or a selection of objects
  import                  Import a frame bundle into the design
  run                     Run a model
  write-dot               Write a Graphviz DOT file.
  metamodel               Show the metamodel
```

The edit subcommands are:

```
  set                     Set an attribute value
  undo                    Undo last change
  redo                    Redo undone change
  add                     Create a new node
  connect                 Create a new connection (edge) between two nodes
```

Use `--help` with the desired command to learn more.

### Pseudo-REPL

Think of this tool as [ed](https://en.wikipedia.org/wiki/Ed_(text_editor)) but
for data represented as a graph. At least for now.

The tool is designed in a way that it is by itself interactive for a single-user. 
For interactivity in a shell, set the `POIETIC_DATABASE` environment variable to
point to a file where the design is stored.

Example session:

```
export POIETIC_DATABASE="MyDesign.poietic"

poietic new
poietic info

poietic edit add Stock name=water formula=100
poietic edit add Flow name=outflow formula=10
poietic edit connect Drains water outflow

poietic list formulas

poietic edit add Stock name=unwanted
poietic list formulas
poietic edit undo

poietic list formulas

poietic run
```


# Author

[Stefan Urbanek](mailto:stefan.urbanek@gmail.com)

