# Tasks for Issue 3: `Geometry` — rectangular layout, `:vertexheights` and `:vertexlevels`

Parent issue: Issue 3
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `.workflow-docs/00-design/controlled-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

Canonical terms enforced throughout: `vertex`/`vertices`, `leaf`/`leaves`,
`rootvertex`, `fromvertex`/`tovertex`, `edgelength`, `vertexvalue`,
`branchingtime`, `coalescenceage`, `vertex_positions`, `edge_paths`,
`leaf_order`, `leaf_spacing`, `boundingbox`, `lineageunits`.

---

## Tasks

### 1. Research Makie `lines!` data conventions; define `TreeGeometry` and `boundingbox`

**Type**: WRITE
**Output**: `src/Geometry.jl` defines and exports `TreeGeometry` and
`boundingbox`; the struct compiles and the module loads cleanly.
**Depends on**: none

Before writing any code, read the following files in the local Makie source at
`/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/`:
`src/basic_recipes/lines.jl` (or wherever `lines!` and `linesegments!` are
defined), focusing on what data types and shapes they accept for the positional
argument — specifically whether they consume `Vector{Point2f}`, vectors of
`NaN`-separated segments, or a `Vector{Vector{Point2f}}`. Choose the
representation that best matches how multiple separate edge paths can be drawn in
a single `lines!` or `linesegments!` call. Document the chosen representation
and the Makie source file and line number in a comment in `src/Geometry.jl`.

Define `TreeGeometry` as a parametric immutable `struct TreeGeometry{V}` with
four fields: `vertex_positions::Dict{V,Point2f}`, `edge_paths::Vector{Point2f}`
(type chosen from the research above), `leaf_order::Vector{V}`, and
`boundingbox::Rect2f`. Per STYLE-julia.md §1.12 ("Concrete struct fields and
parametric type design"), bare `Dict` and `Vector` are not acceptable field
types — every field must be concretely typed or parameterized. In practice
`V=Any` (both `leaves` and `preorder` return `Vector{Any}`), so the runtime
type will be `TreeGeometry{Any}`; the parametric form is still required.
Write a triple-quoted docstring on the struct describing each field, the type
parameter `V`, and the coordinate convention (process coordinate on the primary
axis; transverse coordinate on the secondary axis).

Define `boundingbox(geom::TreeGeometry) -> Rect2f` as a pure function that
computes the smallest axis-aligned bounding rectangle enclosing all values in
`geom.vertex_positions`. Use `Makie.Rect2f` or `GeometryBasics.Rect2f`
(whichever is re-exported by the loaded Makie version — confirm from source).
Write a docstring. Export both names from `src/Geometry.jl`. This module must
not import anything from `src/Accessors.jl` directly — it receives a
`TreeAccessor` by type but the import direction is caller → callee only.
Confirm with `julia --project -e 'using LineagesMakie'`.

---

### 2. `rectangular_layout` for `:vertexheights` — leaf positioning and edge paths

**Type**: WRITE
**Output**: `rectangular_layout(root, acc; lineageunits=:vertexheights)` returns
a `TreeGeometry` where all leaves have process coordinate 0.0, internal vertices
have positive process coordinates equal to their height, and `edge_paths`
contains correct right-angle segment data.
**Depends on**: Task 1

Implement `rectangular_layout(rootvertex, accessor::TreeAccessor;
leaf_spacing=:equal, lineageunits=:vertexheights) -> TreeGeometry`. In this
task, only `:vertexheights` is implemented; the `lineageunits` dispatch
infrastructure must be extensible (use an internal dispatch function or
`if`/`elseif` block that will be extended in Task 3 and Issue 4).

For `:vertexheights`: compute the height of each vertex as the maximum edge
count to any descendant leaf (leaf height = 0). Use a single postorder depth-
first pass via `preorder(accessor, rootvertex)` (from `Accessors`) reversed, or
an explicit postorder traversal. The process coordinate of each vertex is its
height. For the transverse axis, with `leaf_spacing = :equal`, assign leaves
integer positions 1, 2, 3, … in their traversal order; internal vertex
transverse position is the mean of its children's transverse positions.

For `edge_paths`, produce right-angle segments: for each edge from `fromvertex`
to `tovertex`, the path is two segments — a horizontal segment from
`(process(fromvertex), transverse(fromvertex))` to
`(process(fromvertex), transverse(tovertex))`, then a vertical segment from
there to `(process(tovertex), transverse(tovertex))`. Confirm the path
representation matches the Makie `lines!` convention decided in Task 1.

Use `Accessors.is_leaf`, `Accessors.leaves`, and `Accessors.preorder` by
explicit qualified name or by including them via the module. Do not import
`Accessors` with a bare `using Accessors` — use `using LineagesMakie.Accessors:
is_leaf, leaves, preorder` or equivalent explicit form. Write a full docstring
on `rectangular_layout`. Export it.

---

### 3. `:vertexlevels` mode, `leaf_spacing` as `Float64`, and zero-leaf guard

**Type**: WRITE
**Output**: `rectangular_layout` supports `:vertexlevels`, accepts a `Float64`
`leaf_spacing`, and raises `ArgumentError` for a zero-leaf tree.
**Depends on**: Task 2

Extend the `lineageunits` dispatch in `rectangular_layout` to handle
`:vertexlevels`. For `:vertexlevels`, the process coordinate of each vertex is
its integer edge count from the rootvertex (rootvertex = 0, its children = 1,
etc.). This is a simple preorder pass counting depth. Internal vertex transverse
positions are computed identically to `:vertexheights`.

Extend the `leaf_spacing` parameter: if `leaf_spacing` is the `Symbol` `:equal`,
use the existing integer-index spacing. If `leaf_spacing` is a positive
`Float64`, space leaves `leaf_spacing` units apart (first leaf at 0.0, next at
`leaf_spacing`, etc.). Raise `ArgumentError` with a descriptive message if
`leaf_spacing` is a negative `Float64`.

Add a zero-leaf guard at the top of `rectangular_layout`: before any layout
computation, call `leaves(accessor, rootvertex)` and check whether the resulting
collection is empty; if so, raise `ArgumentError` identifying the rootvertex.

Update the `TreeGeometry` struct's `boundingbox` field to be computed from the
final `vertex_positions` at the end of layout, using the `boundingbox` function
from Task 1. Confirm the module stays within 400–600 LOC.

---

### 4. Write `test/test_Geometry.jl` initial slice

**Type**: TEST
**Output**: All `test_Geometry` assertions green; no Aqua or JET regressions.
**Depends on**: Task 3

Write `test/test_Geometry.jl`. Reuse or copy the four tree fixtures from
`test/test_Accessors.jl` (4-leaf balanced, 6-leaf unbalanced, polytomy, single-
leaf). Organize `@testset` blocks by function and mode.

Cover:
- `TreeGeometry` construction: that it is an immutable struct with the expected
  fields.
- `rectangular_layout` with `:vertexheights` on all four fixtures: all leaves at
  process coordinate 0.0; root at maximum process coordinate; all vertices have
  entries in `vertex_positions`.
- `:vertexlevels` on all four fixtures: rootvertex at process coordinate 0;
  leaves at maximum integer level; all vertices have entries.
- Equal-spacing invariant: for any fixture with ≥ 2 leaves, all adjacent leaf
  transverse positions differ by exactly the same amount.
- `leaf_spacing` as `Float64`: pass `leaf_spacing = 2.5` and verify adjacent
  leaf transverse gap is 2.5.
- Negative `leaf_spacing` raises `ArgumentError`.
- `boundingbox` encloses all `vertex_positions` values: for each fixture, assert
  that every position `p` in `geom.vertex_positions` satisfies
  `p ∈ geom.boundingbox`.
- Zero-leaf tree raises `ArgumentError` (construct a root with no children).

Use `@test`, `@test_throws`, and `@testset` throughout. All tests deterministic.
