# Flows

Dynamical model simulation library.

A prototype.


## Flow Tool and Flow Language

### Tool

```
OVERVIEW: Flows – dynamical systems simulator

USAGE: flows [--steps <steps>] <source>

ARGUMENTS:
  <source>                Name of a model file (path or URL)

OPTIONS:
  -s, --steps <steps>     Number of steps to run (default: 10)
  -h, --help              Show help information.
```

Example use:

```
flow Models/hello.flow
flow --steps 1000 Models/predator-prey.flow
```

### Language

The package comes with a tool to run models written in a simple "Flow" language.

Syntax of the language is demonstrated in the following example:

```
# Hello Flow!
#
# Simple flow demonstration.
#
# +--------+              +-----+
# | kettle |===( pour )==>| cup |
# +--------+              +-----+
#

# Stocks (aka containers, pools, accumulators, ...)
#
stock kettle = 100
stock cup = 0

# Variables
#
var rate = 10

# Flows
#
# Pouring from the kettle to the cup at given rate, spilling some water.
#
flow pour = rate
     from kettle
     to cup


# Values to be printed to the output
#
output kettle, cup
```

Model statements:

- ``stock NAME = EXPRESSION`` - defines a stock (accumulator) node
- ``flow NAME = EXPRESSION [from STOCK] [to STOCK]``- defines a flow.
    ``from STOCK`` defines which stock this flow drains and ``to STOCK`` defines
    which stock this flow fills.
- ``var NAME = EXPRESSION`` - defines an auxiliary node, a variable or
    a transformation

Other statements:

- ``output NAME, ...`` – list of nodes which values are to be printed to the
  output
  
### Operators

The following operators are available for the arithmetic expression:

- `+` addition
- `-` subtraction
- `*` multiplication
- `/` division
- `%` remainder

  
### Built-in functions

The arithmetic expressions might use functions. Here is the list of provided
numeric functions:

- `abs(number)` absolute value of a number
- `floor(number)` number rounded down, floor value
- `ceiling(number)` number rounded up, ceiling value
- `round(number)` rounded value of a number
- `sum(number, ...)` sum of multiple values
- `min(number, ...)` min out of of multiple values
- `max(number, ...)` max out of of multiple values
- `power(number, exponent)` power of a number to the exponent
  

## Build and Install

This software is written in [Swift](https://www.swift.org/), download it [here](https://www.swift.org/download/).

Dependencies:

- [Swift Argument Parser](https://github.com/apple/swift-argument-parser) (for the `flow` command-line tool)

The dependencies are automatically downloaded by the Swift package manager.

### Build

```sh
swift build
```

### Run (in the source directory)

```sh
swift run flow
```


## Development

Read [Design Notes](DESIGN.md) for more information about how this library
is being developed and what are the priorities.


## Author

Author: [Stefan Urbanek](mailto:stefan.urbanek@gmail.com)
