# Tasks for Issue 5: `Geometry` — circular layout (`:chord` edge style)

Parent issue: Issue 5
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `STYLE-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

Canonical terms: `leaf`/`leaves`, `vertex`/`vertices`, `rootvertex`,
`leaf_spacing`, `edge_shapes`, `vertex_positions`, `boundingbox`,
`lineageunits`, `circular_edge_style`. Use these exactly.

---

## Tasks

### 1. `circular_layout` skeleton — angular leaf placement and `min_leaf_angle`

**Type**: WRITE
**Output**: `circular_layout` places leaves at equal angular spacing; radial
process coordinates are computed from the active `lineageunits` value; the
`min_leaf_angle` parameter is documented and implemented.
**Depends on**: none

Add `circular_layout(rootvertex, accessor::LineageGraphAccessor; leaf_spacing=:equal,
lineageunits=:vertexheights, circular_edge_style=:chord,
min_leaf_angle=nothing) -> LineageGraphGeometry` to `src/Geometry.jl`. Write a full
docstring.

For angular leaf placement with `leaf_spacing = :equal`: collect all leaves in
traversal order; assign each leaf an angle evenly spaced from 0 to 2π
(exclusive), e.g., `θ_i = 2π * (i-1) / n_leaves` for `i` in `1:n_leaves`.

Decide and document the `min_leaf_angle` floor (PRD Open Q3). The recommended
default is `min_leaf_angle = 2π / 360` (one degree) — if the computed equal
spacing would be smaller than `min_leaf_angle`, warn and use `min_leaf_angle`
instead, which will cause the layout to span less than a full circle. Document
this decision in the docstring with the reasoning. Set `min_leaf_angle = nothing`
as the default (no floor applied unless user supplies a value) and note this in
the docstring.

For radial coordinates: reuse the same `lineageunits` dispatch infrastructure
from `rectangular_layout`. The process coordinate of each vertex becomes its
radial distance from the origin. The `vertex_positions` of each vertex are
`(r * cos(θ), r * sin(θ))` where `r` is the process coordinate and `θ` is the
angular position. For internal vertices, `θ` is the mean of their children's
angles; `r` is their process coordinate from the `lineageunits` computation. Add
the same zero-leaf guard as in `rectangular_layout`.

---

### 2. `:chord` edge shape construction

**Type**: WRITE
**Output**: `circular_layout` produces `edge_shapes` where all segments are
straight lines (no arc data); the bounding box correctly encloses all vertex
and chord-midpoint positions.
**Depends on**: Task 1

Implement the `:chord` edge path geometry for `circular_layout`. For each edge
from `fromvertex` to `tovertex`, the path consists of two straight-line segments:
(1) a chord segment from the parent's polar position `(r_from, θ_from)` to a
connector point at `(r_from, θ_to)` — both at the parent's radial distance but
spanning the angular difference; (2) a radial segment from that connector point
`(r_from, θ_to)` to the child's polar position `(r_to, θ_to)`. All positions
are converted to Cartesian `(x, y)` coordinates before being stored in
`edge_shapes`.

Use the same `edge_shapes` representation confirmed in Issue 3 Task 1. Each edge
contributes two segments (four points, or two point pairs depending on the
chosen representation). Ensure `NaN`-separator logic (if used for `lines!`) or
segment grouping is consistent with the rectangular layout path representation.

Update `boundingbox` computation at the end of `circular_layout` to enclose all
`vertex_positions` values. Note that chord midpoints may extend beyond the leaf
circle, so the bounding box must be computed from positions, not analytically
from the radius. Export `circular_layout`. Confirm the module stays within
400–600 LOC; if `src/Geometry.jl` is approaching the upper limit, discuss with
the project owner before splitting.

---

### 3. Extend `test/test_Geometry.jl` for circular layout

**Type**: TEST
**Output**: All circular layout tests green; all pre-existing rectangular layout
tests still pass; no Aqua or JET regressions.
**Depends on**: Task 2

Extend `test/test_Geometry.jl` with a new `@testset "circular_layout"` block.
Use the same four lineage graph fixtures.

Cover:
- Equal angular spacing: for the 4-leaf balanced fixture, verify that all leaves
  are at angles approximately `0`, `π/2`, `π`, `3π/2` (in any rotation, checking
  equal gaps of `π/2`). Use `≈` with `atol = 1e-8`.
- Radial positions: for `:vertexheights`, verify that all leaves have radial
  distance 0.0 (process coord = 0 for leaves in this mode). For a
  `:vertexlevels` layout, verify rootvertex is at radius 0.
- `boundingbox` encloses all `vertex_positions`: same assertion as for
  rectangular layout.
- `circular_edge_style = :chord`: inspect `edge_shapes` and confirm all segment
  endpoints are finite `Point2f` values (no `NaN` in unexpected positions).
- Zero-leaf lineage graph raises `ArgumentError`.
- Non-regression: run all existing `@testset "rectangular_layout"` assertions
  after the circular tests to confirm no shared state was corrupted.

All tests deterministic. No external network. Do not test internal angular
arithmetic implementation details — only the observable contract (leaf angles,
radii, bbox).
