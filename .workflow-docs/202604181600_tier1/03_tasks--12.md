# Tasks for Issue 12: Composite `LineagePlot` recipe and Observable reactivity

Parent issue: Issue 12
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `.workflow-docs/00-design/controlled-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

ComputeGraph (`map!` / `register_computation!`) is mandatory throughout. The
`onany`-based pattern must not be used. All reactive wiring must go through the
ComputeGraph so that Makie's update-ordering guarantees apply.

If any helper `struct` is introduced alongside the `@recipe` type, all fields
must be concretely typed or parameterized (STYLE-julia.md §1.12).

---

## Tasks

### 1. `LineagePlot` composite recipe skeleton

**Type**: WRITE
**Output**: `LineagePlot` / `lineageplot!` composite recipe is defined and
replaces the stub; it delegates to all eight individual layer recipes; a single
`lineageplot!` call renders all layers without error.
**Depends on**: none

Before writing any code, read `src/compute-plots.jl` at
`/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/compute-plots.jl`
to understand how a composite recipe registers multiple sub-plots and how
ComputeGraph inputs flow from parent to child recipes. Also re-read
`GraphMakie.jl/src/recipes.jl` for the composite recipe pattern used in that
package. Document the chosen wiring approach in a comment with source citation.

Define `LineagePlot` using `@recipe` in `src/Layers.jl`. Positional inputs:
`rootvertex` (a plain Julia value at this stage — Observable wrapping is Task
2) and `accessor::LineageGraphAccessor`. Attributes: all layer-specific attributes
exposed as passthrough keywords (e.g., `edge_color`, `edge_linewidth`,
`vertex_marker`, `leaf_color`, `leaf_label_func`, `vertex_label_threshold`,
`clade_vertices`, `scale_bar_visible`, etc.). Follow the naming convention
in `STYLE-julia.md` — all lowercase with underscores.

In the `plot!` method: call `Geometry.rectangular_layout` (or `circular_layout`
if `lineage_orientation = :radial`) to obtain a `LineageGraphGeometry`; then call each
of `edgelayer!`, `vertexlayer!`, `leaflayer!`, `leaflabellayer!`,
`vertexlabellayer!`, `cladehighlightlayer!`, `cladelabellayer!`, and
`scalebarlayer!` in order, passing the appropriate attributes from `LineagePlot`'s
attribute dict. Remove the temporary stub `lineageplot!` defined in Issue 7.
Export `LineagePlot` and `lineageplot!`. Write a docstring.

---

### 2. ComputeGraph reactive layout recomputation on `rootvertex` Observable

**Type**: WRITE
**Output**: Wrapping `rootvertex` in an `Observable` and updating it triggers a
full layout recomputation; `vertex_positions` in the rendered scene reflect the
new tree without re-calling `lineageplot!`.
**Depends on**: Task 1

Extend `LineagePlot` to accept `rootvertex` as an `Observable` or plain value.
In Makie recipe convention, positional arguments are already wrapped in
Observables by the framework; confirm this from `docs/src/explanations/recipes.md`
and from the `@recipe` macro internals. Use `map!` or `register_computation!`
on the `rootvertex` Observable to derive `LineageGraphGeometry` reactively: whenever
`rootvertex[]` changes, recompute the layout and update all derived Observables
(positions, edge shapes, bounding box).

The reactive chain must update `LineageAxis.reset_limits!` after recomputation
if the axis is a `LineageAxis` (so the axis limits adjust to the new lineage graph). Use
a single ComputeGraph node for the layout computation, not multiple `on`
callbacks. Confirm from `src/compute-plots.jl` the correct API to register this
node. Write a comment explaining the reactive topology.

---

### 3. Observable-valued layer attributes and circular layout path

**Type**: WRITE
**Output**: `Observable`-valued `color`, `linewidth`, and `alpha` attributes
update live; `lift` on a recipe attribute works; `lineage_orientation = :radial`
triggers `circular_layout`.
**Depends on**: Task 2

Ensure all layer attribute Observables are propagated from `LineagePlot` to each
sub-layer recipe so that updating an `Observable` bound to (e.g.) `edge_color`
updates the rendered edge colors without re-calling `lineageplot!`. This follows
from Makie's standard attribute Observable contract — confirm the wiring is
correct by reading how `GraphMakie.jl/src/recipes.jl` forwards attributes to
sub-recipes.

Wire the circular layout path: in `LineagePlot`'s `plot!` method, check
`lineage_orientation` (from the axis if a `LineageAxis`, or from a keyword if a
plain `Axis`). If `:radial`, call `Geometry.circular_layout` instead of
`rectangular_layout` and route the resulting `LineageGraphGeometry` to `EdgeLayer` with
`edge_style = :chord`. Add `lineage_orientation` as an attribute on `LineagePlot`
with default `:left_to_right`.

Verify with a minimal test that `lift(p -> RGBA(p, 0.5), color_obs)` bound to
the `edge_color` attribute of a `lineageplot!` result updates when `color_obs`
changes.

---

### 4. Extend `test_Layers.jl` and `test_Integration.jl`

**Type**: TEST
**Output**: Composite recipe tests green; Observable reactivity verified;
circular layout integration smoke test passes; no regression.
**Depends on**: Task 3

Extend `test/test_Layers.jl` with `@testset "LineagePlot"` covering:
- Full composite render (all 8 layers) completes without error on the 4-leaf
  fixture.
- Each layer can be independently suppressed via its `visible`-equivalent
  attribute passthrough.
- Observable `rootvertex`: wrap the root in `Observable(root)`, call
  `lineageplot!`, then set the Observable to a different lineage graph (with a different
  leaf count); assert that the number of leaf positions in the `LeafLayer`
  scatter updates to the new count.
- Observable `color`: bind `Observable(:blue)` to `edge_color`; call
  `lineageplot!`; update the Observable to `:red`; assert the edge color
  attribute changes.
- `lift` wiring: create `c = Observable(:black)`; bind
  `lift(x -> RGBA(x, 0.5), c)` to `edge_color`; update `c`; assert the edge
  color changes.

Extend `test/test_Integration.jl` with:
- Circular layout smoke test: render a 4-leaf lineage graph with `lineage_orientation =
  :radial` on a `CairoMakie` `LineageAxis`; assert the figure is non-empty.
- Full-pipeline test: render with all layers active and all non-default
  attributes set to confirm no attribute passthrough is silently ignored.

All tests deterministic. Use `CairoMakie`.
