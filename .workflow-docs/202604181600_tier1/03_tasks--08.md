# Tasks for Issue 8: Vertex and leaf marker layers

Parent issue: Issue 8
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `.workflow-docs/00-design/controlled-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

Canonical terms: `vertex`/`vertices`, `leaf`/`leaves`. Per the PRD:
`VertexLayer` renders at internal vertices only; `LeafLayer` renders at leaf
vertices only. These are distinct categories and must not be conflated.

---

## Tasks

### 1. `VertexLayer` recipe with pixel-space marker sizing

**Type**: WRITE
**Output**: `VertexLayer` / `vertexlayer!` renders markers only at internal
vertex positions; marker pixel size is unchanged after a viewport resize event;
the recipe is wired into the `lineageplot!` stub.
**Depends on**: none

Implement `VertexLayer` in `src/Layers.jl` using `@recipe`. Positional input: a
`TreeGeometry` value and a `TreeAccessor` value (needed to distinguish internal
vertices from leaves via `Accessors.is_leaf`). Attributes: `marker` (default
`:circle`), `color` (default `:black`), `markersize` (default `8`), `strokecolor`
(default `:black`), `alpha` (default `1.0`), `visible` (default `true`).

In the `plot!` method, extract the positions of internal vertices only: iterate
`geom.vertex_positions`, filter to keys for which `is_leaf(accessor, vertex)` is
`false`, and collect the positions. Draw with `scatter!` using
`markerspace = :pixel` so that marker size is fixed in screen pixels regardless
of axis scale. Use `CoordTransform.register_pixel_projection!` to keep the
mapping reactive on resize. Write a docstring. Export `VertexLayer` and
`vertexlayer!`. Wire `vertexlayer!` into the `lineageplot!` stub: after the
`EdgeLayer` call, add a `vertexlayer!` call passing the same `TreeGeometry` and
`accessor`.

---

### 2. `LeafLayer` recipe wired into stub

**Type**: WRITE
**Output**: `LeafLayer` / `leaflayer!` renders markers only at leaf positions;
`visible = false` on either layer does not affect the other.
**Depends on**: Task 1

Implement `LeafLayer` in `src/Layers.jl` using `@recipe`. The attribute set is
identical to `VertexLayer`: `marker`, `color`, `markersize`, `strokecolor`,
`alpha`, `visible`. In the `plot!` method, filter `geom.vertex_positions` to
keys for which `is_leaf(accessor, vertex)` is `true`. Otherwise the
implementation is identical to `VertexLayer`. Do not create a shared supertype
or abstract type for the two layers — they share a similar shape but are
independently composable; premature abstraction is not permitted per
`STYLE-julia.md` (YAGNI). Write a docstring. Export `LeafLayer` and
`leaflayer!`.

Wire `leaflayer!` into the `lineageplot!` stub: after the `vertexlayer!` call,
add a `leaflayer!` call. The stub now delegates to three layers: `edgelayer!`,
`vertexlayer!`, `leaflayer!`.

---

### 3. Extend `test_Layers.jl` for marker layers

**Type**: TEST
**Output**: All `VertexLayer` and `LeafLayer` test assertions green; pixel-size
stability test passes; no regression in EdgeLayer tests.
**Depends on**: Task 2

Extend `test/test_Layers.jl` with `@testset "VertexLayer"` and
`@testset "LeafLayer"` blocks.

Cover:
- `vertexlayer!` on the 4-leaf balanced fixture: the plot object is created
  without error; inspect the scatter positions and confirm there are exactly 3
  positions (3 internal vertices in a 4-leaf balanced binary tree).
- `leaflayer!` on the same fixture: exactly 4 positions (the 4 leaves).
- Independence: create a scene with both layers; set `visible = false` on the
  `LeafLayer` plot object and verify that the `VertexLayer` plot object's
  `visible` attribute is still `true`.
- Pixel-size stability: create a `CairoMakie` scene, call `vertexlayer!`, record
  the `markersize` attribute, then simulate a viewport change by updating the
  scene's viewport observable, and verify `markersize` is unchanged (it is in
  pixels and should not scale with the axis).
- `@test` that no EdgeLayer test (from Issue 7) fails after adding the new
  `@testset` blocks (run the full file and check).

All tests deterministic; use `CairoMakie`.
