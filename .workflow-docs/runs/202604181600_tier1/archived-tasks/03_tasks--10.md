# Tasks for Issue 10: Clade annotation and scale bar layers

Parent issue: Issue 10
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `STYLE-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

Canonical terms: `clade_vertices` (the attribute holding MRCA vertices),
`leaf`/`leaves`, `vertex`/`vertices`, `boundingbox`, `lineageunits`. Use these
exactly. The term `MRCA` (most recent common ancestor) is acceptable in
docstrings for biological context but the code identifier must be `clade_vertices`.

If any helper `struct` is introduced alongside the `@recipe` types, all fields
must be concretely typed or parameterized (STYLE-julia.md §1.12).

---

## Tasks

### 1. `CladeHighlightLayer` recipe with CoordTransform padding

**Type**: WRITE
**Output**: `CladeHighlightLayer` renders a colored rectangle enclosing all
leaves of each specified clade; `padding` is applied in pixel space and
correctly mapped back to data space via `CoordTransform`.
**Depends on**: none

Implement `CladeHighlightLayer` in `src/Layers.jl` using `@recipe`. Positional
input: a `LineageGraphGeometry` and a `LineageGraphAccessor`. Attributes: `clade_vertices` (a
`Vector` of MRCA vertex values whose subtrees should be highlighted; default
`[]`), `color` (default `RGBA(0.2, 0.6, 1.0, 0.15)`), `alpha` (default `0.15`),
`padding` (default `Vec2f(4, 4)` in pixels), `visible` (default `true`).

In the `plot!` method, for each MRCA vertex in `clade_vertices`: collect all
leaf positions in the subtree rooted at that vertex (using a subtree traversal
via `accessor.children`); compute the bounding box of those leaf positions using
`Geometry.boundingbox` logic; expand the bounding box by `padding` mapped to
data space via `CoordTransform.pixel_offset_to_data_delta`; draw a filled
rectangle using `poly!` or `rect!`. Use `register_pixel_projection!` so padding
updates on resize. Write a docstring. Export `CladeHighlightLayer` and
`cladehighlightlayer!`. Wire into `lineageplot!`.

---

### 2. `CladeLabelLayer` recipe with vertical bracket

**Type**: WRITE
**Output**: `CladeLabelLayer` renders a vertical bracket (line + tick marks)
outside the leaf labels and a text annotation for each specified clade; the
bracket is positioned in data space from the clade's bounding box.
**Depends on**: Task 1

Implement `CladeLabelLayer` in `src/Layers.jl` using `@recipe`. Positional
input: a `LineageGraphGeometry` and a `LineageGraphAccessor`. Attributes: `clade_vertices`
(default `[]`), `label_func` (a callable `mrca_vertex -> String`; default:
`v -> ""`), `color` (default `:black`), `fontsize` (default `11`), `offset`
(default `Vec2f(6, 0)` pixels beyond the leaf label column), `visible` (default
`true`).

In the `plot!` method, for each MRCA vertex: compute the clade's leaf bounding
box (same subtree traversal as `CladeHighlightLayer`); draw a vertical line
segment at the right edge of the bounding box (plus `offset`) spanning the full
transverse extent of the clade's leaves; draw two short horizontal tick marks at
the top and bottom of that line; draw a `text!` call with `label_func(mrca)` at
the midpoint of the bracket. Use `register_pixel_projection!` so `offset` is
applied correctly. Write a docstring. Export `CladeLabelLayer` and
`cladelabellayer!`. Wire into `lineageplot!`.

---

### 3. `ScaleBarLayer` recipe with auto-omit logic

**Type**: WRITE
**Output**: `ScaleBarLayer` defaults to `visible = false` for non-quantitative
`lineageunits` values and `visible = true` for quantitative ones; renders a
correctly sized bar with label when visible.
**Depends on**: Task 2

Implement `ScaleBarLayer` in `src/Layers.jl` using `@recipe`. Positional input:
a `LineageGraphGeometry`, a `LineageGraphAccessor`, and a `Symbol` `lineageunits` value. Attributes:
`position` (default `(:left, :bottom)` as a tuple of anchor hints), `length`
(default: auto-computed as 10% of the process-coordinate range), `label` (default
`""`), `color` (default `:black`), `linewidth` (default `1.5`), `visible`
(default: derived from `lineageunits` — `true` for `:edgelengths`,
`:branchingtime`, `:coalescenceage`; `false` for all others).

For the default `visible` derivation, implement a private `_scalebar_visible(lineageunits::Symbol) -> Bool` helper. In the `plot!` method, when `visible`, draw a horizontal line of the specified `length` at the specified `position` (use `position` to anchor within the current axis limits) and a `text!` call below it showing `label`. Write a docstring on the recipe and on `_scalebar_visible`. Export `ScaleBarLayer` and `scalebarlayer!`. Wire into `lineageplot!`; pass the `lineageunits` value already known at the stub call site.

---

### 4. Extend `test_Layers.jl` for annotation layers

**Type**: TEST
**Output**: All annotation layer test assertions green; no regression in earlier
layer tests.
**Depends on**: Task 3

Extend `test/test_Layers.jl` with `@testset` blocks for all three new layers.

Cover:
- `cladehighlightlayer!`: pass one clade MRCA vertex; verify the plot object is
  created without error; inspect the rendered rectangle's data-space bounds and
  confirm they enclose all leaf positions of that clade (use the known fixture
  geometry to compute expected bounds).
- `cladehighlightlayer!` with empty `clade_vertices = []`: renders without error,
  produces no visible geometry.
- `cladelabellayer!` with `label_func = v -> "Clade A"`: plot created without
  error; the text attribute of the resulting `text!` plot equals `"Clade A"`.
- `scalebarlayer!` with `lineageunits = :vertexheights`: `visible` is `false` by
  default.
- `scalebarlayer!` with `lineageunits = :edgelengths`: `visible` is `true` by
  default.
- `scalebarlayer!` with explicit `visible = true` overriding the default:
  renders a non-empty line plot.

All tests use `CairoMakie`. All deterministic.
