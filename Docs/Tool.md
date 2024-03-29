# Command Line Tool

The Poietic Flows includes a command-line tool to create, edit and run
Stock and Flow models.

Usage:

```sh
poietic <subcommand> [options]
```

To get help use `--help` either to the top-level tool or to any sub-command:
```sh
poietic --help
poietic edit --help
poietic edit add --help
```

Command summary:

- `new`: Create an empty design.
- `info`: Get information about the design
- `list`: List design content objects.
- `show`: Describe an object.
- `edit`: Edit an object or a selection of objects.
- `import`: Import a frame into the design.
- `run`: Run the simulation and generate output
- `write-dot`: Write a Graphviz DOT file.
- `metamodel`: Show the metamodel
- `create-library` Create a library of multiple models.


## Commons

Before describing the commands in detail, here are some commonalities of all
the commands.

### Specifying Design File

Most of the commands operate on a design file. Due to iterative usage of the
tool, the design file is not specified on each invocation explicitly.
The default design file name is `design.poietic`. To use another name either
specify an environment variable `POIETIC_DESIGN` or use the `-d` option.
The following three invocations are equivalent:

```bash
# Explicit
poietic new -d MyDesigns/my.poietic
poietic new --design MyDesigns/my.poietic

# Environment variable
export POIETIC_DESIGN=MyDesigns/my.poietic
poietic new
```

### Object References

Multiple commands operating on objects expect an object reference. For example
the `show` command or any of the `edit` sub-commands. Object reference can be
given directly either as object ID or as object name.

When an object ID is provided, it must exist in the current frame.

When an object name is provided and multiple objects carry the same name, then
one of the objects is selected arbitrarily. It is advised to reference objects
by their names only when it is assured that only one object with given name
exists.

## New Command

Create a new, empty database. Usage:

```bash
poietic new [--design <design>] [--import <import> ...] [--auto-parameters]
```

Options:
                          
- `-i`, `--import <import>`: Poietic frame to import into the first frame. See
  `import` command for more information.
- `--auto-parameters`: Automatically connect parameter nodes. See
   the `edit auto-parameters` command for more information.

During the creation of a new frame the user has an option to import one or
multiple frames that will be combined into the first frame of the design.

Example:

```
% poietic new --import ../PoieticExamples/ThinkingInSystems/Capital.poieticframe --auto-parameters
Importing from: ../PoieticExamples/ThinkingInSystems/Capital.poieticframe
Read 3 objects from collection 'design'
Read 19 objects from collection 'objects'
Read 6 objects from collection 'report'
Added 12 parameter edges and removed 0 edges.
Design created.
```

The above is a convenience for the following:

```
poietic new
poietic import ../PoieticExamples/ThinkingInSystems/Capital.poieticframe
poietic auto-parameters
```

## Info Command

Get information about the design.

Usage:

```bash
poietic info [--design <design>]
```

Example:

```
% poietic info
   Available solvers: euler, rk4
  Built-in functions: abs, floor, ceiling, round, power, sum, min, max

     Design database: design.poietic

    Current frame ID: 1
  Frame object count: 40
Total snapshot count: 40

               Graph
               Nodes: 15
               Edges: 22

             History
      History frames: 1
     Undoable frames: 0
     Redoable frames: 0
```

## List Command

List design content objects.

Usage:

```
poietic list [--design <design>] [<list-type>]
```

The list type can be:
- `all`: List all objects in the design in groups: unstructured objects, nodes and
   edges. Each entry contains object ID, object type name and object name
- `names`: list only names of objects
- `formulas`: List arithmetic formulas in the form: `name = formula`, for example
  `growth_goal = capital * 0.1`
- `charts`: List charts in the form: `chart: series`

## Show Command

Describe a design object.

Usage:

```sh
poietic show [--design <design>] [--output-format <output-format>] <reference>
```

Options:

- `-f, --output-format <output-format>`: Format in which the object is
  described. Can be `text` for mostly human-readable description and `json`
  for machine processable description.

The text output is grouped by traits of object's type.

Example:

```
% poietic show depreciation
                Type: Flow
           Object ID: 26
         Snapshot ID: 27
           Structure: node

                Name
                name: depreciation

             Formula
             formula: capital / capital_lifetime

                Flow
            priority: 0

            Position
            position: [0, 0]
             z_index: 0
             
% poietic show -f json depreciation
{"type":"Flow","snapshot_id":27,"id":26,"structure":"node","attributes":{"formula":"capital \/ capital_lifetime","position":[0,0],"name":"depreciation","priority":0,"z_index":0}}
```

## Import Command

Import a frame into the design.

Usage:

```sh
poietic import [--design <design>] <file-name>
```

Imports a poietic frame file or a bundle into the design. See documentation
of the frame file or a bundle for more information.

Notes:

- If the imported frame requires explicit object IDs, then the design
  the frame is being imported to must not contain objects with given IDs.
- The imported frame must contain only types the design supports.
- Structural type of the imported objects (node, edge, unstructured) is
  determined by the target design object types.

Current shortcomings, which might be resolved in the future:

- Imported frame has no way to specify edges between its objects and the target
  design objects.
- User has no way to ignore imported IDs, this this should be an option.


## Run Command

Run the simulation and generate output.

Usage:

```
poietic run [--design <design>] \
            [--steps <steps>] \
            [--time-delta <time-delta>] \
            [--solver <solver>] \
            [--output-format <output-format>] \
            [--variable <variable> ...] \
            [--constant <constant> ...] \
            [--output <output>]
```

Options:

- `-s, --steps <steps>`: Number of steps to run
- `-t, --time-delta`: Time delta to use. Default: 1.0 (unit-less)
- `--solver <solver>`: Type of the solver to be used for computation.
- `-f, --output-format <output-format>`: Output format, see below.
- `-V, --variable <variable>`: Values to observe in the output; can be object IDs or object names.
  If not specified, all simulation variables are used.
- `-c, --constant <constant>`: Set (override) a value of a constant node in a
  form 'attribute=value'.
- `-o, --output <output>`: Output path. Default or '-' is standard output.

Output formats:

- `csv`: Create a CSV file where columns represent either builtin-variables
  (such as time) or value of one simulation object (stock, flow, auxiliary.
  Column names are object or variable names. Row is a simulation step.
- `gnuplot`: Create an output for chart objects, one gnuplot file per chart,
  to be processed later by [gnuplot](http://gnuplot.info).

### Simulation Defaults

The `run` command is trying to get simulation defaults contained within the
design. The defaults are stored in a singleton object of type `Simulation`.
See the metamodel for more information about the list of options
that can be set for the simulation defaults:

```bash
poietic metamodel Simulation
```

## Edit Commands

To be described later.
