# Tasks for Issue 7: `EdgeLayer` recipe and minimal smoke test

Parent issue: Issue 7
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `STYLE-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

Canonical terms: `edge_shapes`, `edgelayer!`, `lineageplot!`. Use
`ComputeGraph` (`map!` / `register_computation!`) throughout; the `onany`-based
fallback pattern must not appear anywhere in this codebase.

If any helper `struct` is introduced alongside the `@recipe` type, all fields
must be concretely typed or parameterized (STYLE-julia.md §1.12). The
`@recipe` macro generates its own type internally; do not add raw `struct`
fields to the generated type.

---

## Tasks

### 1. `EdgeLayer` recipe with right-angle edge style

**Type**: WRITE
**Output**: `src/Layers.jl` defines and exports `EdgeLayer`; `edgelayer!` draws
right-angle edge segments from a `LineageGraphGeometry`; `visible = false` suppresses
all edge rendering; per-edge color function works.
**Depends on**: none

Before writing any code, read the following in the local Makie resources:
- `docs/src/explanations/recipes.md` at
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`
  — understand the `@recipe` macro, attribute declaration, and the `plot!`
  method that must be implemented.
- `src/compute-plots.jl` at
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/compute-plots.jl`
  — understand `map!` and `register_computation!` for reactive attribute
  derivation.
- `GraphMakie.jl/src/recipes.jl` at
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/GraphMakie.jl/src/recipes.jl`
  — reference implementation for per-element attribute handling.

Document the chosen ComputeGraph pattern in a comment citing source file and
line before any recipe code.

Implement `EdgeLayer` using `@recipe`. Positional input: a `LineageGraphGeometry` value.
Attributes: `color` (default `:black`; may be a single color or a function
`(fromvertex, tovertex) -> color`), `linewidth` (default `1.0`), `linestyle`
(default `:solid`), `alpha` (default `1.0`), `edge_style` (default
`:right_angle`; `:chord` will be wired up in Issue 12), `visible` (default
`true`).

In the `plot!` method, use `CoordTransform.register_pixel_projection!` so the
layer is viewport-aware. Draw edges using the `edge_shapes` from the
`LineageGraphGeometry` input via `lines!` or `linesegments!` — the choice must be
consistent with the `edge_shapes` representation decided in Issue 3 Task 1.
When `color` is a function, map it over edges at render time via ComputeGraph
`map!` to produce a per-segment color array. Write a docstring on `EdgeLayer`.
Export `EdgeLayer` and `edgelayer!`. Import from `CoordTransform` using the
explicit `using LineagesMakie.CoordTransform: register_pixel_projection!` form.

---

### 2. Minimal `lineageplot!` stub

**Type**: WRITE
**Output**: `lineageplot!(ax, rootvertex, accessor)` renders `EdgeLayer` on
a `CairoMakie` `Axis` without error; the figure is non-empty.
**Depends on**: Task 1

Add a minimal `lineageplot!` function to `src/Layers.jl` that:
1. Calls `Geometry.rectangular_layout(rootvertex, accessor)` to obtain a
   `LineageGraphGeometry`.
2. Creates and returns an `EdgeLayer` plot on the given axis.

This stub accepts `rootvertex` (a plain value, not yet an `Observable`) and an
`accessor::LineageGraphAccessor` as positional arguments, followed by keyword arguments
forwarded to `EdgeLayer`. It dispatches on `Makie.Axis` for now; the
`LineageAxis` dispatch will be added in Issue 11. Use explicit qualified names
for `Geometry.rectangular_layout` and `Accessors.LineageGraphAccessor`. Write a
docstring marking this as the Tier-1 composite entry point (stub). Export
`lineageplot!`.

---

### 3. `test_Layers.jl` EdgeLayer tests and `test_Integration.jl` smoke test

**Type**: TEST
**Output**: All `test_Layers` EdgeLayer assertions green; `test_Integration.jl`
smoke test passes; no Aqua or JET regressions.
**Depends on**: Task 2

Write the initial `test/test_Layers.jl`. Define the same four lineage graph fixtures used
in `test/test_Accessors.jl`. Organize with `@testset "EdgeLayer"`.

Cover:
- `edgelayer!` on the 4-leaf balanced fixture renders without error using
  `CairoMakie`.
- `visible = false`: call `edgelayer!` with `visible = false` and verify the
  plot object has `visible == false` (do not attempt pixel-level inspection).
- Per-edge color function: pass `color = (u, v) -> :red` and verify the returned
  plot has a non-scalar color attribute (confirming it was expanded per-edge
  rather than left as a scalar function).
- `linewidth` and `alpha` are accepted without error.

Replace the stub content of `test/test_Integration.jl` with one real smoke test:
create a `CairoMakie` `Figure`, add an `Axis`, call `lineageplot!(ax, root, acc)`
on the 4-leaf balanced fixture, render to an in-memory buffer using
`Makie.colorbuffer` or save to a `tempname() * ".png"` file, and assert the
output is non-empty (file size > 0 or buffer length > 0). Use `@test` for the
assertion. Clean up any temp file in a `try/finally` block.
