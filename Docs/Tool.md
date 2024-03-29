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
    - `set`: Set an attribute value
    - `undo`: Undo last change
    - `redo`: Redo undone change
    - `add`: Create a new node
    - `connect`: Create a new connection (edge) between two nodes
    - `remove`: Remove an object – a node or a connection
    - `auto-parameters`: Automatically connect parameter nodes: connect required, disconnect unused
    - `layout`: Lay out objects
    - `align`: Align objects on canvas
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

### Metamodel and Object Types

To get the list of object types that the tool supports and to get more
information about the metamodel, run `poietic metamodel`. See the
Metamodel Command documentation for more information.


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
Run the metamodel command for more information about the list of options
that can be set for the simulation defaults:

```bash
poietic metamodel Simulation
```

### Gnuplot Output

To process the generated gnuplot files run: `gnuplot *.gnuplot`.


## Editing Commands

There are multiple commands for model editing:

- `set`: Set an attribute value
- `undo`: Undo last change
- `redo`: Redo undone change
- `add`: Create a new node
- `connect`: Create a new connection (edge) between two nodes
- `remove`: Remove an object – a node or a connection
- `auto-parameters`: Automatically connect parameter nodes: connect required, disconnect unused
- `layout`: Lay out objects
- `align`: Align objects on canvas

All edit commands alter the history which can be reversed. The editing commands
are not destructive to the design, simply use `undo` and `redo` edit commands
to revert undesired changes.

### Set Attribute Command

Set an attribute value.

Usage:

```sh
poietic edit set [--design <design>] <reference> <attribute-name> <value>
```

Arguments:

- `reference`: ID or a name of an object to be modified. See the section
  about object references for more information.
- `attribute-name`: Name of the attribute to be set.
- `value`: Attribute value to be set.

The type of the attribute is determined by the object type. The following rules
apply:

- If the type is an array, then the value string is a JSON representation of
  the array, for example: `"[10, 20, 30, 40]"`
- If the type is a point, then the value is a JSON array of two elements, for
  example: `"[100, 0]"` for a point at `x=100` and `y=0`.

### Undo Command

Undo last change.

The previous frame in the history will become the current frame. All frames
that are undone are preserved until a next change. On a change, the frames
held in the undo-buffer are removed.

### Redo Command

Redo last undone change.

The next frame in the history after the current frame will become current.

The previous frame in the history will become the current frame. All frames
that are undone are preserved until a next change. On a change, the frames
held in the undo-buffer are removed.

### Add Object Command

Create a new node or an unstructured object

Usage examples:

```
poietic add Stock name=account formula=100
poietic add Flow name=expenses formula=50
```

Arguments:

- `<type-name>`: Type of the object to be created.
- `<attribute-assignments>`: Attributes to be set in form 'attribute=value'.

To get a list of types that can be created, run:

```sh
poietic metamodel
```

To get more information about the type and its attributes, run:

```sh
poietic metamodel TYPE_NAME
```

For example:

```sh
poietic metamodel Stock
poietic metamodel DesignInfo
```

**IMPORTANT**: The format of the attribute assignments will likely change in the
upcoming releases.


### Connect Command

Create a new connection (edge) between two nodes.

Usage:

```sh
poietic edit connect [--design <design>] <type-name> <origin> <target>
```

Arguments:

- `type-name`: Type of the connection to be created
- `origin`: Reference to the connection's origin node
- `target`: Reference to the connection's target node

See section about Object References for more information.

_Note:_ To set attributes on an edge use the `edit set` command. Currently it is
not possible to set attributes during edge creation.


### Remove Command

Remove an object – a node or a connection.

Usage: 
```sh
poietic edit remove [--design <design>] <reference>
```

Arguments:

- `reference`: Object to be removed. See Object References for more information.

If the object is a node and there are any edges connected with the node, then
all the edges are removed as well.

### Auto-Parameters Command

Automatically connect parameter nodes: connect required, disconnect unused.

```sh
poietic edit auto-parameters [--design <design>] [--verbose]
```

Options:

- `-v, --verbose`: Print IDs of created and removed edges.

The Stock and Flow model requires that all parameters used in formulas
must be connected to their corresponding nodes. Moreover, there must be no
connected parameters that are not used in the model. If this requirement is not
satisfied, the compiler will refuse to compile the model and it will be not
possible to simulate it. This is a design principle, not a fussiness of the
compiler.

This command connects the required parameter nodes and removes connections
from the nodes that are not used in the formulas.

### Layout Command

Lay out objects in 2D space.

_Note_: This is a preview feature. Use with caution.

Usage:

```sh
poietic edit layout [--design <design>] [--layout <layout>] [<references> ...]
```

Arguments:

- `references`: Objects to be laid out. If not specified, then all objects 
  where the object type contains position trait are considered.

Options:

- `--layout`: Type of the layout to use.

Currently there is only one layout style: `circle`, which lays out the nodes
in a circle in order as specified.

### Align Command

Align objects on canvas.

_Note_: Preliminary functionality, a preview of a possibility. Might not
function to full satisfaction.

Usage:

```sh
poietic edit align [--design <design>] <mode> [--spacing <spacing>] <references> ...
```

Arguments:

- `mode`: Alignment mode – see below.
- `references`: Objects to be aligned.

Options:

- `--spacing <spacing>`: Spacing between objects (default: 10.0).

Alignment modes:

- Alignment: `left`, `center-horizontal`, `right`, `top`,
  `center-vertical`, `bottom`
- Offset: `offset-horizontal`, `offset-vertical`
- Spread: `spread-horizontal`, `spread-vertical`


## Metamodel Command

Show information about the metamodel and object types.

Usage:

```sh
poietic metamodel [--design <design>] [<object-type>]
```

If `object-type` is provided, then the command lists all attributes of the 
object type and their description. If `object-type` is not provided, then the
command lists all object types and constraints.

Example output of `poietic metamodel` (trimmed):

```
TYPES AND COMPONENTS

DesignInfo (unstructured)
    title (string)
    author (string)
    license (string)
    abstract (string)
...

Stock (node)
    name (string)
    formula (string)
    allows_negative (bool)
...

Flow (node)
    name (string)
    formula (string)
    priority (int)
    position (point)
    z_index (int)

...

Simulation (unstructured)
    steps (int)
    initial_time (double)
    time_delta (double)

...

CONSTRAINTS

flow_fill_is_stock: Flow must drain (from) a stock, no other kind of node.
flow_drain_is_stock: Flow must fill (into) a stock, no other kind of node.
one_parameter_for_graphical_function: Graphical function must not have more than one incoming parameters.
...
```

Output of `poietic metamodel Stock`:

```
Stock (node)
    name (string)
        - Object name
    formula (string)
        - Arithmetic formula or a constant value represented by the node.
    allows_negative (bool)
        - Flag whether the stock can contain a negative value.
    delayed_inflow (bool)
        - Flag whether the inflow of the stock is delayed by one step, when the stock is part of a cycle.
    position (point)
    z_index (int)
```

Try:

```
poietic metamodel Flow
poietic metamodel Stock
poietic metamodel DesignInfo
poietic metamodel Simulation
```


## Create Library Command

Create a library info referencing multiple models. The command creates a
library description from a given list of design files. The library info is used
by the Poietic Server (preview).

_Note_: This is a preview feature. Use with caution.

Use:

```sh
poietic create-library [--output-file <output-file>] <designs> ...
```

The command takes a list of design files (_important_: not a list of frames).
The command extracts `DesignInfo` from the designs. If multiple instances of
`DesignInfo` are present, then one is chosen arbitrarily.


See also: [Poietic Server](https://github.com/OpenPoiesis/PoieticServer)
(preview package, unstable).



## Write Graphviz Dot File Command

Write a [Graphviz](https://graphviz.org) DOT file.

_Note:_ This command is not using Graphviz directly, it just generates a file
that is processable by the Graphviz toolkit.

Usage:

```sh
poietic write-dot [--design <design>] \
                    [--name <name>] \
                    [--output <output>] \
                    [--label-attribute <label-attribute>] \
                    [--missing-label <missing-label>]
```

Options:

- `-n, --name <name>`: Name of the graph in the output file (default: output)
- `-o, --output <output>`:   Path to a DOT file where the output will be
   written. (default: output.dot)
- `-l, --label-attribute <label-attribute>`: Node attribute that will be used
   as node label (default: id).
- `-m, --missing-label <missing-label>`: Label used if the node has no label
   attribute (default: `(none)`)

Practical options:
- Use `-l name` to display node name
- Use `-l formula` to display arithmetic formula of the node.

If you have Graphviz installed, then to process the generated file
(assuming default `output.dot` output), run:

```
dot -Tpng -odiagram.png output.dot
```

This will create `diagram.png` file with the design diagram.


## Future

The tool is currently part of PoieticFlows, however it serves two distinct
purposes. One is model editing and the other is simulation or domain-specific
functionality. It should be split into two tools, one part of the PoieticCore
and the other part of PoieticFlows, or in the future, other packages with
simulation capabilities.

The nice to have commands and functionalities:

- `repair` – attempt to repair a broken design or a design of older versions
- `export` – export a collection of objects as a frame bundle
- `compare` or `diff` – compare two designs
- `merge` merge two or more designs, with rules and conflict resolution
- `edit change-type` – change object type
- `edit unset` - remove an attribute
- more input/output in JSON or CSV format

