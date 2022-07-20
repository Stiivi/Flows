# Design Notes

This document contains some design notes that might explain why parts of the
library is designed in a particular way.

- __Note:__ This library is currently a prototype. It might contain
  architectural artefacts that might seem questionable at first. They are a
  brain-dump of the author at the time of writing as he is exploring the problem
  space.

  The library architecture will eventually converge as it will emerge from the
  exploration process.

## Requirements

- User first, computer second
- Interactive and incremental modelling
- Understandable visual representability of the model
- Composability
- Explicit metamodel
- Allow evolution of the metamodel

Not a priority:

- Performance
- Textual model representation, such as domain-specific programming language to
  describe the model


### User First, Computer Second

Design the library that provides functionality for user-oriented applications,
not for convenience of automated tools.

Assumed user is a creative individual.


### Model and Graph

The modelled problem itself is a graph. Any additional entities are part of the
graph. Therefore the best abstract structure to represent it is a graph.

Links between entities are first class citizens in the model. Therefore they
should be modelled as graph edges and be accessible as such. We need to be
able to reason about them at different levels of abstraction.


### Interactive and incremental modelling

The objective is to allow build applications that provide modelling experience
that is interactive and incremental. That means that the user is getting
immediate feedback about the components he adds or changes in the model. User
can perform experiments with the model immediately without waiting for some
long lasting compile phase.

Analogy: Spreadsheet application


### Explicit Metamodel

The metamodel, ideally, should be explicit. That means, that the metamodel
should be available (ideally as a whole) outside of the source code.

This is to allow creation of third-party tools that can operate on the model.


### Allow Evolution of the Metamodel

The metamodel is going to evolve. The underlying structures must allow this
evolution without breaking backward compatibility as much as possible
or at least by allowing easy conversion of models.

It has to be noted, that there might exist multiple models of different
metamodel versions out there. Friction for sharing them and reusing them
must be minimal.


### Composability

The models should be composable. One should be able to compare two or more
models. Differences and conflicts should be provided and the user should
have the ability to merge them together.


## Design Principles

Main principles:

- That what represents captured knowledge - a model - is represented as a graph
- Code readability and understandability matters
- Error reporting matters
- If new functionality adds just convenience over existing functionality or 
  wraps existing functionalities only for convenience purposes, it has to be
  marked as such in the documentation (and optionally in the code)


Concerns to be separated:

- modelled vs. derived or computed artefacts
- modelling vs. simulation/computation

Weak coupling with the model:

- error reporting propagated to the model (as derived artefact)
- analysis/explanation of the model propagated to the model

Swift language usage:

- Only basic language features are to be used
    - the code should be reasonably understandable by non-Swift users
- Allowed:
    - classes
    - enums with values
    - protocols
- Limited:
    - simple generics
- Not allowed:
    - custom operators
    - property wrappers
    - function builders


### Error Reporting

User must know where in user's input the error happened and what kind of error
happened. Even better if we can provide information how to fix the error.

## Architecture

_... or rather expected architectural components, that are under evolution._

The Flows module:

```
┌───────────────────────────────────────────────────┐
│                   Application                     │
└───────────────────────────────────────────────────┘

┌──────────────────────────────────────┬────────────┐
│              Simulation              │ Rewriting* │
├─────────────────────────┬────────────┼────────────┤
│         Model           │ Evaluation │ Language   │
├──────────────────────┬──┴────────────┴────────────┤
│        Graph         │          Expression        │
└──────────────────────┴────────────────────────────┘

```

- __Simulation__ - perform simulation, related computation
- __Model__ representation of the model, including metamodel
- __Graph__ - underlying mutable structure to store the model in, provides
  functionality for creating, changing the graph and maintaining graph
  in consistent state through constraints.
- __Evaluation__ - arithmetic expression evaluation
- __Expression__ - numeric value and arithmetic expression representation
- __Language__ - parser for arithmetic expressions and 
- __Rewriting__ - arithmetic expression rewriting for interactive applications
  (not implemented yet)


## The Language

The provided "Flow" language is there just for convenience and basic
demonstrations.  It is not intended to expose full functionality of the library
to the end-user as the textual model representation is not a priority.

Sharing models should be done through one of the graph interfaces. Formats
that preserve the graph more accurately without potential ambiguity.


## The Graph

The graph module is to be developed as a stand-alone module for mutable
historical graph.

- Everything in the model and elements that can not be (re)produced from other
  data should be graph-representable
- Graph and related structures is mutable
- Graph must preserve reversible history (not implemented yet)

The Graph module:

```
┌─────────┬─────────────┬─────────┬────────────┐
│         │ Constraints │ History*│ Interfaces │
│         └─────────────┴─────────┴────────────┤
│                      Core                    │
└──────────────────────────────────────────────┘

```

- __Core__ - core abstract data structures for representing a graph: graph,
  link, node. Contains core functionality for fetching the graph components.
- __Constraints__ - structures describing constraints that are imposed on the 
  graph by the metamodel. Provides also a constraint checker.
- __History__ (not implemented, but important) - provides functionality for 
  preserving and fetching the graph history - changes of the graph components.
  Used in applications for undo/redo functionality.
- __Interfaces__ - import and export of graph in different formats, not always
  preserving everything (for example Dot/DIA export is just a presentation export)


Note: The Graph module has been ported, or rather extracted, from the author's
another library. Mode sub-modules that might be relevant exist and will be
ported as needed. For example: more import/export options, Projections,
Neighbourhoods or meta-modeling features. The History submodule exists, but
is not quite as we might need it here.


## Technical Debt

- Most of the technical debt is marked with `TODO:` or if more serious then
  with `FIXME:` markers in the code
- There exist debt that is a result of evolution of the thought, of
  understanding of the problem space and consequentially in seemingly
  inconsistent architectural or style decisions. Just ask the author (politely)
  "Why is this or that this way?".
