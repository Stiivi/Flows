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
var spill = 0.1

# Flows
#
# Pouring from the kettle to the cup at given rate, spilling some water.
#
flow pour = rate - (rate * spill)
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
  

  
## Author

Author: [Stefan Urbanek](mailto:stefan.urbanek@gmail.com)
