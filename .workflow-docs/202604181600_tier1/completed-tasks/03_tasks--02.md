# Tasks for Issue 2: `Accessors` module

Parent issue: Issue 2
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `.workflow-docs/00-design/controlled-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

Canonical terms: `vertex`/`vertices` (not `node`), `leaf`/`leaves` (not `tip`),
`rootvertex` (not `root`), `fromvertex`/`tovertex` (not `parent`/`child`).
Use these in all identifiers, docstrings, and comments without exception.

---

## Tasks

### 1. `LineageGraphAccessor` struct and `lineagegraph_accessor` constructor

**Type**: WRITE
**Output**: `src/Accessors.jl` defines and exports `LineageGraphAccessor` and
`lineagegraph_accessor`; `julia --project -e 'using LineagesMakie'` loads without error.
**Depends on**: none

In `src/Accessors.jl`, define `LineageGraphAccessor` as a fully parametric immutable
`struct` (per `STYLE-julia.md`: `struct` is default; `mutable struct` requires
justification) with seven fields: `children`, `edgelength`, `vertexvalue`,
`branchingtime`, `coalescenceage`, `vertexcoords`, `vertexpos`. Use a type
parameter for each field — per `STYLE-julia.md` "Concrete struct fields and
parametric type design", every struct field must be concretely typed or made
concrete through type parameters at instantiation:

```julia
struct LineageGraphAccessor{C, E, V, B, CA, VC, VP}
    children::C
    edgelength::Union{Nothing, E}
    vertexvalue::Union{Nothing, V}
    branchingtime::Union{Nothing, B}
    coalescenceage::Union{Nothing, CA}
    vertexcoords::Union{Nothing, VC}
    vertexpos::Union{Nothing, VP}
end
```

`C` captures the concrete type of the required `children` callable. Each
optional field uses `Union{Nothing, F}` where `F` is its type parameter: when
the caller passes `nothing`, `F = Nothing` and the field is typed `Nothing`;
when the caller passes a lambda or function, `F` is that callable's concrete
singleton type. All fields are therefore concretely typed at every instantiation
— `Any`, abstract types, and unparameterised unions are not used. This is the
high-priority design for performance: Julia's compiler can specialise on every
instantiation, and small `Union{Nothing, F}` unions are stack-allocated with a
tag bit rather than boxed.

Define `lineagegraph_accessor(rootvertex; children, edgelength=nothing,
vertexvalue=nothing, branchingtime=nothing, coalescenceage=nothing,
vertexcoords=nothing, vertexpos=nothing) -> LineageGraphAccessor`. Include an explicit
return type annotation `-> LineageGraphAccessor`. Validate that `children` is callable
using `isa(children, Base.Callable)` or equivalent; raise `ArgumentError` with a
message identifying the non-callable value if not. Write a triple-quoted
docstring on both `LineageGraphAccessor` and `lineagegraph_accessor` describing fields,
parameters, return value, and the `ArgumentError` condition. Export both names
from the module. Verify the file stays within 400–600 LOC (it will be far below
at this stage).

---

### 2. `abstracttrees_accessor`, `is_leaf`, `leaves`, `preorder`, and cycle detection

**Type**: WRITE
**Output**: `src/Accessors.jl` defines and exports `abstracttrees_accessor`,
`is_leaf`, `leaves`, and `preorder`; cycle detection raises `ArgumentError`
before producing any output.
**Depends on**: Task 1

Add `abstracttrees_accessor(rootvertex; edgelength=nothing, vertexvalue=nothing,
branchingtime=nothing, coalescenceage=nothing) -> LineageGraphAccessor`. This function
must use `AbstractTrees.children` as the `children` callable. Use a
`hasmethod(AbstractTrees.children, Tuple{typeof(rootvertex)})` check (or
equivalent) to raise an informative `ArgumentError` if the rootvertex type does
not implement the AbstractTrees interface. Import from `AbstractTrees` using the
explicit form `using AbstractTrees: children` (not bare `using AbstractTrees`).

Add `is_leaf(accessor::LineageGraphAccessor, vertex) -> Bool`: returns `true` when
`accessor.children(vertex)` returns an empty iterable. Add
`leaves(accessor::LineageGraphAccessor, rootvertex) -> iterator` returning all leaf
vertices in a deterministic traversal order. Add
`preorder(accessor::LineageGraphAccessor, rootvertex) -> iterator` returning all
vertices in preorder.

For both `leaves` and `preorder`, implement cycle detection using a `Set` of
visited vertices. If a vertex is encountered a second time, raise `ArgumentError`
with a message that names the repeated vertex. Raise this error before returning
any output — do not yield partial results. Write docstrings on all four
functions. Export all four names.

---

### 3. Write `test/test_Accessors.jl`

**Type**: TEST
**Output**: `julia --project=test test/runtests.jl` passes with all
`test_Accessors` assertions green; JET reports no new dispatch errors.
**Depends on**: Task 2

Write `test/test_Accessors.jl`. Define four shared lineage graph fixtures at the top of
the file as constants: a 4-leaf balanced binary lineage graph, a 6-leaf unbalanced
lineage graph, a polytomy (one root with 4 direct leaf children), and a single-leaf
lineage graph. Construct these using a minimal anonymous struct or named `struct`
defined inside the test file — do not import any external lineage graph package.
Each fixture must be compatible with both the keyword-accessor and AbstractTrees
adapter paths.

Organize tests in `@testset` blocks grouped by function name. Cover:
`lineagegraph_accessor` construction with all keyword combinations (including all-nothing
optionals); `ArgumentError` when `children` is not callable (pass an integer);
`abstracttrees_accessor` wrapping; `is_leaf` returning correct `Bool` for leaf
and internal vertices on each fixture; `leaves` returning the exact expected
count and a deterministic order; `preorder` returning all vertices in correct
preorder sequence; cycle detection raising `ArgumentError` on a manually
constructed cyclic structure (create a mutable struct whose `children` field
points back to an ancestor). Use `@test_throws ArgumentError` for all error
cases. Tests must be deterministic (no random seeds, no external network). Each
test sets up its own state.
