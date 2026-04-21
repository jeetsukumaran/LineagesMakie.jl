---
date-created: 2026-04-20
prd: .workflow-docs/202604181600_tier1/01_prd.md
---

# Issues: LineagesMakie.jl — Tier 1 MVP

All issues are **AFK** (no human decision required during implementation).

Resolved design decisions incorporated here:

- **PRD Open Q5** (`lineage_orientation = :right_to_left`): implement fully as
  a distinct attribute value. Redundancy with `display_polarity = :reversed` +
  `:left_to_right` is resolved by delegating internally (`:right_to_left` calls
  the reversed-display path) to stay DRY. No separate decision issue required.
- **PRD Open Q1** (Makie version floor): resolved — Makie ≥ 0.24, ComputeGraph
  (`map!` / `register_computation!`) throughout.

## Governance requirements (all issues)

Every issue must comply with:

- `STYLE-julia.md` — naming, annotations, mutation contract, file structure,
  Runic.jl formatting, anti-patterns.
- `STYLE-git.md` — OneFlow branching, commit message conventions.
- `STYLE-docs.md` — sentence case, punctuation, prose style for all
  documentation text.
- `CONTRIBUTING.md` — PR process and community standards.
- `.workflow-docs/00-design/controlled-vocabulary.md` — all identifiers, type
  names, keyword arguments, symbols, and documentation must use canonical terms.
  No proscribed alternates anywhere. New terms may be proposed and added only
  after explicit discussion with and approval from the project owner.
- **Concrete struct fields** — every `struct` field must be concretely typed or
  made concrete via type parameters (STYLE-julia.md §1.12 "Concrete struct
  fields and parametric type design"). Bare `Dict`, `Vector`, abstract types,
  and `Any` are not acceptable field types without an explicit, justified
  comment in the code. Prefer parametric structs (`struct Foo{V}`) over
  `Any`-typed fields. This applies to every explicit `struct` definition in
  every module.

### Version control responsibilities

Read-only and non-mutating Git and shell commands (status, log, diff, show,
grep, find, read) may be used freely without restriction during implementation.

Mutating Git operations — commits, merges, rebases, pushes, branch creation or
deletion, tags — are the responsibility of the human project owner. Implementing
agents must not perform these operations unilaterally.

These requirements are not repeated in each issue but are binding for all of
them.

---

## Issue 1: Project scaffolding and dependency setup

**Type**: AFK
**Blocked by**: None — can start immediately

### Parent PRD

`.workflow-docs/202604181600_tier1/01_prd.md`

### What to build

Establish the full project skeleton before any module code is written:

1. Add `Makie` (≥ 0.24), `AbstractTrees` to `[deps]` and `[compat]` in
   `Project.toml` using `Pkg.add`. Do not edit `Project.toml` directly.
2. Create the five stub module files under `src/`:
   `src/Accessors.jl`, `src/Geometry.jl`, `src/CoordTransform.jl`,
   `src/Layers.jl`, `src/LineageAxis.jl` — each declares its module and
   exports nothing yet.
3. Update `src/LineagesMakie.jl` to `include` each stub file and re-export
   nothing yet.
4. Create the seven stub test files under `test/`:
   `test/test_Accessors.jl`, `test/test_Geometry.jl`,
   `test/test_CoordTransform.jl`, `test/test_Layers.jl`,
   `test/test_LineageAxis.jl`, `test/test_Integration.jl` — each contains
   only a commented-out `# Tests for <Module>` header and an empty
   `@testset "<Module>" begin end` block.
5. Update `test/runtests.jl` to `include` each test file inside the top-level
   `@testset` block, after the existing Aqua and JET checks. Aqua and JET must
   run first on every CI invocation so quality regressions are caught early.
6. Add a Runic formatting check step to `.github/workflows/CI.yml`:
   `runic --check src/ test/`. This step must fail CI if any file is not
   formatted to Runic conventions.
7. Add `CairoMakie` to the test environment (`test/Project.toml`) via
   `Pkg.add` in the test environment, since integration smoke tests require a
   non-interactive backend.

### How to verify

**Manual:**
- `julia --project -e 'using LineagesMakie'` completes without error.
- `julia --project=test -e 'using Test, Aqua, JET, LineagesMakie; Aqua.test_all(LineagesMakie)'`
  passes.
- `julia --project=test test/runtests.jl` completes (all stubs pass trivially).

**Automated:**
- CI passes on the new branch.
- Runic check step runs and exits 0 for the stub files.

### Acceptance criteria

- [ ] Given a fresh clone, when `julia --project -e 'using LineagesMakie'` is
  run, then the package loads without error or warning.
- [ ] Given `test/runtests.jl`, when run, then Aqua and JET checks pass and
  all stub `@testset` blocks report 0 failures.
- [ ] Given `.github/workflows/CI.yml`, when a PR is opened, then a Runic
  formatting check step is present and enforced.
- [ ] Given `test/Project.toml`, then `CairoMakie` is listed as a test
  dependency.
- [ ] Given `Project.toml`, then `Makie` ≥ 0.24 and `AbstractTrees` appear in
  `[deps]` and `[compat]`.

### User stories addressed

- User story 3: No internet / no R — addressed by being a pure Julia/Makie
  package from the start.
- User story 4: Backend independence — addressed by depending on `Makie`
  (backend-agnostic) rather than any specific backend.
- User story 49: Unit tests for every exported function.
- User story 51: Aqua.jl and JET.jl checks in CI.

---

## Issue 2: `Accessors` module

**Type**: AFK
**Blocked by**: Issue 1

### Parent PRD

`.workflow-docs/202604181600_tier1/01_prd.md`

### What to build

Implement `src/Accessors.jl` as described in PRD Module 1. This module defines
the fundamental accessor protocol that all downstream modules depend on. It has
no Makie dependency.

Deliver:

- `TreeAccessor` struct holding the seven accessor callables (`children`
  required; the remaining six optional, defaulting to `nothing`).
- `tree_accessor(rootvertex; children, edgelength=nothing, vertexvalue=nothing,
  branchingtime=nothing, coalescenceage=nothing, vertexcoords=nothing,
  vertexpos=nothing) -> TreeAccessor`: validates that `children` is callable;
  raises `ArgumentError` otherwise.
- `abstracttrees_accessor(rootvertex; edgelength=nothing, vertexvalue=nothing,
  branchingtime=nothing, coalescenceage=nothing) -> TreeAccessor`: wraps
  `AbstractTrees.children`; requires `AbstractTrees` to be loaded.
- `is_leaf(accessor::TreeAccessor, vertex) -> Bool`
- `leaves(accessor::TreeAccessor, rootvertex) -> iterator`
- `preorder(accessor::TreeAccessor, rootvertex) -> iterator`
- Cycle detection in `preorder` and `leaves`: raises `ArgumentError` with an
  informative message (including the repeated vertex) before any layout begins.

Export all public names from `src/Accessors.jl`. Add them to
`src/LineagesMakie.jl` re-exports.

Write `test/test_Accessors.jl` covering: construction with all keyword
combinations; `ArgumentError` on non-callable `children`; `AbstractTrees`
adapter wrapping; `is_leaf`, `leaves`, `preorder` on a 4-leaf balanced tree,
a 6-leaf unbalanced tree, a polytomy, and a single-leaf tree; cycle detection
raising `ArgumentError`.

All tests must run under Aqua and JET without new violations.

### How to verify

**Manual:**
```julia
using LineagesMakie
struct Node; children::Vector{Node}; name::String end
root = Node([Node([Node([], "a"), Node([], "b")], "ab"),
             Node([Node([], "c"), Node([], "d")], "cd")], "root")
acc = tree_accessor(root; children = n -> n.children)
collect(leaves(acc, root))   # should return 4 leaf nodes
collect(preorder(acc, root)) # should return all 7 nodes
```

**Automated:**
- `julia --project=test test/runtests.jl` passes with all `test_Accessors`
  assertions green.
- JET reports no new dispatch errors in `Accessors`.

### Acceptance criteria

- [ ] Given a callable `children` keyword, when `tree_accessor` is called,
  then a `TreeAccessor` is returned.
- [ ] Given a non-callable value for `children`, when `tree_accessor` is
  called, then `ArgumentError` is raised with a descriptive message.
- [ ] Given an `AbstractTrees`-compliant object, when `abstracttrees_accessor`
  is called, then a `TreeAccessor` wrapping `AbstractTrees.children` is
  returned.
- [ ] Given a tree with a cycle in `children`, when `leaves` or `preorder` is
  called, then `ArgumentError` is raised before any output is produced.
- [ ] Given a 4-leaf balanced tree, when `leaves` is called, then exactly 4
  leaf vertices are returned in a deterministic order.

### User stories addressed

- User story 1: AbstractTrees-compliant rootvertex accepted.
- User story 2: Explicit `children`, `edgelength`, `vertexvalue` keyword
  functions accepted.
- User story 8: `vertexvalue` callable stored in `TreeAccessor`.
- User story 44: Cycle detection raises informative error.

---

## Issue 3: `Geometry` — rectangular layout, `:vertexheights` and `:vertexlevels`

**Type**: AFK
**Blocked by**: Issue 2

### Parent PRD

`.workflow-docs/202604181600_tier1/01_prd.md`

### What to build

Implement the `Geometry` module skeleton and the two no-accessor `lineageunits`
modes for rectangular layout. This slice delivers the minimal geometry needed
for a renderable tree, independently testable with no Makie dependency.

Deliver in `src/Geometry.jl`:

- `TreeGeometry{V}` immutable parametric struct: `vertex_positions::Dict{V,Point2f}`,
  `edge_paths::Vector{Point2f}` (element type determined by reading Makie's
  `lines!` conventions in the local source — `Vector{Point2f}` with `NaN`
  separators), `leaf_order::Vector{V}`, `boundingbox::Rect2f`. `V` is the
  vertex identity type; in generic use `V` is `Any`. Per STYLE-julia.md §1.12
  and the governance rule above, bare `Dict` and `Vector` are not acceptable.
- `rectangular_layout(rootvertex, accessor::TreeAccessor;
  leaf_spacing=:equal, lineageunits=:vertexheights) -> TreeGeometry`:
  implements `:vertexheights` and `:vertexlevels` modes only in this issue.
  Right-angle edge segments. Equal or explicit positive real number `leaf_spacing`.
- `boundingbox(geom::TreeGeometry) -> Rect2f`.
- Zero-leaf tree raises `ArgumentError`.

Leaf positions on the transverse axis use equal spacing by default; a positive
`Float64` `leaf_spacing` value sets an explicit inter-leaf distance in layout
units. Process coordinates for `:vertexheights`: leaves = 0, increases toward
root. For `:vertexlevels`: rootvertex = 0, integer level increases toward
leaves.

Write `test/test_Geometry.jl` (initial slice): `TreeGeometry` construction;
`rectangular_layout` with `:vertexheights` and `:vertexlevels` on all four
tree fixtures (4-leaf balanced, 6-leaf unbalanced, polytomy, single-leaf);
equal spacing invariant (all leaf transverse gaps equal); `leaf_spacing` as
`Float64`; `boundingbox` contains all vertex positions; zero-leaf
`ArgumentError`.

### How to verify

**Manual:**
```julia
using LineagesMakie
# reuse Node fixture from Issue 2
acc = tree_accessor(root; children = n -> n.children)
geom = rectangular_layout(root, acc; lineageunits = :vertexheights)
geom.vertex_positions  # Dict: vertex => Point2f
geom.boundingbox       # Rect2f enclosing all positions
```

**Automated:**
- All `test_Geometry` assertions green.
- Leaves are all at process coordinate 0.0 for `:vertexheights`.
- Root is at process coordinate 0 for `:vertexlevels`, leaves at max integer
  level.
- All leaf transverse gaps are equal when `leaf_spacing = :equal`.

### Acceptance criteria

- [ ] Given a 4-leaf balanced tree and `lineageunits = :vertexheights`, when
  `rectangular_layout` is called, then all leaves have process coordinate 0.0
  and the root has the highest process coordinate.
- [ ] Given `lineageunits = :vertexlevels`, when `rectangular_layout` is
  called, then the rootvertex has process coordinate 0 and leaves have the
  maximum integer level.
- [ ] Given `leaf_spacing = :equal`, when any rectangular layout is computed,
  then all adjacent leaf transverse positions are equal distances apart.
- [ ] Given a positive `Float64` `leaf_spacing`, when `rectangular_layout` is
  called, then adjacent leaves are that distance apart in layout units.
- [ ] Given a tree with zero leaves, when `rectangular_layout` is called, then
  `ArgumentError` is raised.
- [ ] Given any `TreeGeometry`, when `boundingbox` is called, then the returned
  `Rect2f` contains every entry in `vertex_positions`.

### User stories addressed

- User story 6: Omitting `edgelength` yields leaf-aligned clade graph.
- User story 11: `lineageunits` keyword controls process coordinate mode.
- User story 12: Default `lineageunits` is `:vertexheights` when no
  `edgelength` is supplied.
- User story 13: Leaves equally spaced on transverse axis by default.
- User story 14: `leaf_spacing` keyword controls spacing.
- User story 48: Zero-leaf tree raises clear error.

---

## Issue 4: `Geometry` — complete `lineageunits` stack and error modes

**Type**: AFK
**Blocked by**: Issue 3

### Parent PRD

`.workflow-docs/202604181600_tier1/01_prd.md`

### What to build

Extend `src/Geometry.jl` to cover all remaining `lineageunits` modes and all
documented error/fallback paths. After this issue every `lineageunits` value in
the PRD table is implemented and tested.

Deliver:

- `:edgelengths` mode: preorder cumulative sum of `edgelength(fromvertex,
  tovertex)`; rootvertex = 0; missing / `nothing` edge lengths fall back to
  unit length with a `@warn` message identifying the edge; negative edge lengths
  raise `ArgumentError` identifying the edge.
- `:branchingtime` mode: reads `branchingtime(vertex)` directly; preorder
  traversal.
- `:coalescenceage` mode: postorder traversal; reads `coalescenceage(vertex)`;
  leaves = 0; requires ultrametric tree by default (`nonultrametric = :error`);
  `nonultrametric = :minimum` / `:maximum` selects the fallback policy when
  sibling coalescence-age estimates are inconsistent.
- `:vertexdepths` mode: cumulative edge count from rootvertex (all weights = 1).
- `:vertexcoords` mode: reads `vertexcoords(vertex) -> Point2f` directly;
  bypasses layout computation.
- `:vertexpos` mode: reads `vertexpos(vertex) -> Point2f` directly; bypasses
  layout computation.
- Default `lineageunits` detection: if `edgelength` is supplied and
  `lineageunits` is not set, default is `:edgelengths`; otherwise
  `:vertexheights`.

Extend `test/test_Geometry.jl`: one test per mode on the standard tree
fixtures; missing edge-length warning with unit-length fallback; negative
edge-length `ArgumentError`; non-ultrametric `ArgumentError` with
`nonultrametric = :error`; `:minimum` and `:maximum` fallback policies; default
`lineageunits` detection.

### How to verify

**Manual:**
```julia
acc = tree_accessor(root;
    children  = n -> n.children,
    edgelength = (u, v) -> 1.5)
geom = rectangular_layout(root, acc)   # defaults to :edgelengths
# rootvertex process coord = 0; leaves at cumulative sum
```

**Automated:**
- `:edgelengths` leaves are at cumulative sum from rootvertex.
- `@warn` is emitted (captured with `@test_warn`) when an edge returns
  `nothing`.
- Negative edge length raises `ArgumentError` naming the offending edge.
- Non-ultrametric tree raises `ArgumentError` under `nonultrametric = :error`.
- `:minimum` / `:maximum` modes produce positions without error on a
  non-ultrametric tree.

### Acceptance criteria

- [ ] Given `edgelength` returning positive `Float64` values, when
  `:edgelengths` is used, then each vertex's process coordinate equals the
  cumulative sum of edge lengths from rootvertex.
- [ ] Given `edgelength` returning `nothing` for one edge, when `:edgelengths`
  is used, then a warning is emitted and that edge uses unit-length fallback.
- [ ] Given `edgelength` returning a negative value, when `:edgelengths` is
  used, then `ArgumentError` is raised identifying the specific edge.
- [ ] Given a non-ultrametric tree and `lineageunits = :coalescenceage` with
  `nonultrametric = :error`, then `ArgumentError` is raised.
- [ ] Given `nonultrametric = :minimum`, when layout is computed on a
  non-ultrametric tree, then positions are produced without error.
- [ ] Given `vertexcoords` accessor, when `lineageunits = :vertexcoords`,
  then `vertex_positions` matches the `vertexcoords` output directly.

### User stories addressed

- User story 5: `edgelength` returning `Float64` or `(; value, units)`.
- User story 7: Missing edge lengths produce warning + unit-length fallback.
- User story 9: `coalescenceage` accessor with `:coalescenceage` mode.
- User story 10: `branchingtime` accessor with `:branchingtime` mode.
- User story 11: All eight `lineageunits` values implemented.
- User story 45: Negative edge length raises `ArgumentError`.
- User story 46: Non-ultrametric handling via `nonultrametric` keyword.

---

## Issue 5: `Geometry` — circular layout (`:chord` edge style)

**Type**: AFK
**Blocked by**: Issue 4

### Parent PRD

`.workflow-docs/202604181600_tier1/01_prd.md`

### What to build

Implement `circular_layout` in `src/Geometry.jl` with `circular_edge_style =
:chord` (Tier 1 default). Tier 2 `:arc` style is explicitly out of scope.

Deliver:

- `circular_layout(rootvertex, accessor::TreeAccessor; leaf_spacing=:equal,
  lineageunits=:vertexheights, circular_edge_style=:chord) -> TreeGeometry`
- Leaves placed at equal angular spacing by default. Radial position
  determined by the active `lineageunits` value.
- `:chord` edge style: angular connectors are straight line segments (chords)
  from the parent's angular position to each child's angular position, both at
  the parent's radial distance; radial segments are straight lines from that
  chord endpoint to the child's radial position.
- Decide and document the `min_leaf_angle` floor parameter (PRD Open Q3) during
  implementation; add it as a keyword with a documented default.

Extend `test/test_Geometry.jl`: circular layout on all four tree fixtures; leaf
positions lie on a circle; equal angular gaps; `boundingbox` contains all
positions; all existing rectangular tests still pass.

### How to verify

**Manual:**
```julia
geom = circular_layout(root, acc; lineageunits = :vertexheights)
# All leaf positions should lie at equal angles on the unit circle
angles = [atan(p[2], p[1]) for p in values(geom.vertex_positions)
          if is_leaf(acc, v)]  # equally spaced
```

**Automated:**
- All leaf angular positions are equally spaced (modulo floating-point
  tolerance).
- `boundingbox` encloses all vertex positions.
- No regression in rectangular layout tests.

### Acceptance criteria

- [ ] Given a 4-leaf tree and `circular_layout`, when `leaf_spacing = :equal`,
  then all leaves are at equal angular spacing (π/2 apart for 4 leaves).
- [ ] Given any `circular_layout` result, when `boundingbox` is called, then
  every vertex position is inside the returned `Rect2f`.
- [ ] Given `circular_edge_style = :chord`, when layout is computed, then all
  edge path segments are straight lines (no arc data).
- [ ] Given a tree with zero leaves, when `circular_layout` is called, then
  `ArgumentError` is raised.

### User stories addressed

- User story 15: Circular layout with equal angular leaf spacing by default.

---

## Issue 6: `CoordTransform` module

**Type**: AFK
**Blocked by**: Issue 1

### Parent PRD

`.workflow-docs/202604181600_tier1/01_prd.md`

### What to build

Implement `src/CoordTransform.jl` as described in PRD Module 3. This module has
no knowledge of tree structure or process coordinate semantics; it operates
purely on geometric values.

Deliver:

- `data_to_pixel(scene, point::Point2f) -> Point2f`
- `pixel_to_data(scene, point::Point2f) -> Point2f`
- `pixel_offset_to_data_delta(scene, data_point::Point2f,
  pixel_offset::Vec2f) -> Vec2f`
- `register_pixel_projection!(plot_attrs, scene)`: registers `viewport` and
  `projectionview` as ComputeGraph inputs so that pixel↔data mappings update
  reactively on viewport change.
- Degenerate viewport (zero-size): identity transform with `@warn`.

Read `src/compute-plots.jl` and `GraphMakie.jl/src/recipes.jl` in the local
Makie source before writing any ComputeGraph code.

Write `test/test_CoordTransform.jl`: round-trip `data_to_pixel` /
`pixel_to_data`; `pixel_offset_to_data_delta` for a known non-isotropic scene;
degenerate viewport produces identity transform and emits warning. Tests must
use a `CairoMakie` scene so they exercise real coordinate transform paths.

All tests must pass under Aqua and JET without new violations.

### How to verify

**Automated:**
- `data_to_pixel(scene, pixel_to_data(scene, p)) ≈ p` for a non-isotropic
  scene (x and y scales differ by ≥ 10×).
- A registered scene emits updated pixel coordinates after the viewport
  Observable is triggered.
- Degenerate viewport emits `@warn` and returns identity.

### Acceptance criteria

- [ ] Given a scene with non-isotropic axes (x scale ≠ y scale), when
  `data_to_pixel` and `pixel_to_data` are applied in sequence, then the round-
  trip result matches the original point within floating-point tolerance.
- [ ] Given a zero-size viewport, when any conversion function is called, then
  a warning is emitted and the identity transform is applied.
- [ ] Given `register_pixel_projection!`, when the scene viewport Observable
  changes, then subsequent conversion calls reflect the new mapping.

### User stories addressed

- User story 17: Marker and label sizes remain correct after figure resize.
- User story 39: `LineageAxis` pixel↔data correctness for non-isotropic axes.

---

## Issue 7: `EdgeLayer` recipe and minimal smoke test

**Type**: AFK
**Blocked by**: Issues 3, 6

### Parent PRD

`.workflow-docs/202604181600_tier1/01_prd.md`

### What to build

Implement `EdgeLayer` in `src/Layers.jl` and wire it into a minimal
`lineageplot!` stub that produces a renderable figure. This is the first end-
to-end path through the system.

Read `docs/src/explanations/recipes.md`, `src/compute-plots.jl`, and
`GraphMakie.jl/src/recipes.jl` in the local Makie documentation and source
before writing any recipe code. Use ComputeGraph (`map!` /
`register_computation!`) throughout; `onany`-based fallback is not used.

Deliver:

- `EdgeLayer` / `edgelayer!` `@recipe`: attributes — `color`, `linewidth`,
  `linestyle`, `alpha`, `edge_style` (`:right_angle` only for rectangular
  layouts in this issue; `:chord` added when circular layout is wired up in
  Issue 12/13), `visible`. Uses `CoordTransform.register_pixel_projection!`.
- A minimal `lineageplot!` that accepts `rootvertex`, `accessor`, and renders
  `EdgeLayer` only. Full composite recipe is Issue 12.
- A stub `test/test_Integration.jl` with one smoke test: render a 4-leaf tree
  via `lineageplot!` on a `CairoMakie` `Axis`; assert the scene is non-empty
  and no error is raised.

Write `test/test_Layers.jl` (initial slice): `EdgeLayer` renders without error
on rectangular layouts; `visible = false` suppresses rendering; per-edge color
function works; tests use `CairoMakie`.

All tests must pass under Aqua and JET without new violations.

### How to verify

**Manual:**
```julia
using CairoMakie, LineagesMakie
fig = Figure()
ax = Axis(fig[1,1])
lineageplot!(ax, root, acc)
save("smoke.png", fig)  # non-empty PNG
```

**Automated:**
- `test/test_Integration.jl` smoke test passes.
- `visible = false` on `EdgeLayer` produces a scene with no edge primitives.
- Per-edge color function (returning one color per edge) produces distinct
  segment colors.

### Acceptance criteria

- [ ] Given a 4-leaf tree, when `lineageplot!` is called on a `CairoMakie`
  `Axis`, then the figure saves to a non-empty PNG without error.
- [ ] Given `visible = false` on `EdgeLayer`, when the scene is rendered, then
  no edge lines appear.
- [ ] Given a color function `(fromvertex, tovertex) -> color`, when
  `EdgeLayer` is rendered, then each edge segment uses the color returned for
  that edge.

### User stories addressed

- User story 23: Edges rendered as right-angle segments for rectangular layout.
- User story 24: Edge color, linewidth, linestyle, alpha controllable uniformly
  or per edge.
- User story 25: Edge layer independently toggleable.
- User story 50: Integration test renders tree end-to-end via CairoMakie.

---

## Issue 8: Vertex and leaf marker layers

**Type**: AFK
**Blocked by**: Issue 7

### Parent PRD

`.workflow-docs/202604181600_tier1/01_prd.md`

### What to build

Implement `VertexLayer` and `LeafLayer` in `src/Layers.jl`.

Deliver:

- `VertexLayer` / `vertexlayer!` `@recipe`: attributes — `marker`,
  `color`, `markersize`, `strokecolor`, `alpha`, `visible`. Uses
  `markerspace = :pixel` (or `CoordTransform`) so markers remain fixed-size
  on resize. Renders at internal vertex positions only.
- `LeafLayer` / `leaflayer!` `@recipe`: identical attributes; renders at leaf
  positions only.
- Wire both layers into the `lineageplot!` stub from Issue 7.

Extend `test/test_Layers.jl`: both layers render without error; `visible =
false` suppresses each independently; marker appears at correct vertex
positions; no regression in edge-layer tests.

### How to verify

**Automated:**
- `VertexLayer` renders markers only at internal vertices (not leaves).
- `LeafLayer` renders markers only at leaves.
- Setting `visible = false` on either layer does not affect the other.
- Marker pixel size is unchanged after a viewport resize event.

### Acceptance criteria

- [ ] Given a 4-leaf balanced tree, when `VertexLayer` is rendered, then
  markers appear at exactly the 3 internal vertices and not at any leaf.
- [ ] Given `visible = false` on `LeafLayer`, when the scene is rendered, then
  `VertexLayer` markers are still visible.
- [ ] Given a viewport resize, when marker sizes are checked, then they remain
  the same number of pixels.

### User stories addressed

- User story 26: Internal vertex markers independently controllable.
- User story 27: Leaf markers independently controllable.

---

## Issue 9: Label layers

**Type**: AFK
**Blocked by**: Issue 7

### Parent PRD

`.workflow-docs/202604181600_tier1/01_prd.md`

### What to build

Implement `LeafLabelLayer` and `VertexLabelLayer` in `src/Layers.jl`.

Deliver:

- `LeafLabelLayer` / `leaflabellayer!` `@recipe`: attributes — `text_func`
  (vertex → `String`), `font`, `fontsize`, `color`, `offset` (pixel-space
  offset from leaf position), `italic`, `align`, `visible`.
- `VertexLabelLayer` / `vertexlabellayer!` `@recipe`: attributes —
  `value_func` (vertex → any), `threshold` (predicate; default: show all),
  `position` (`:vertex` | `:toward_parent`), `font`, `fontsize`, `color`,
  `visible`. Raises an informative error at plot time if `value_func` returns a
  value of a type not renderable as text.
- Wire both layers into the `lineageplot!` stub.

Extend `test/test_Layers.jl`: leaf labels appear at correct positions; italic
attribute applies; `threshold` predicate filters vertex labels; `value_func`
type error raises an informative error (not a silent rendering failure);
`visible = false` on each layer is independent.

### How to verify

**Automated:**
- `LeafLabelLayer` with `text_func = n -> n.name` renders one label per leaf.
- A `threshold` of `v -> false` produces zero vertex labels.
- Passing a `value_func` that returns a non-renderable type raises an
  informative error at plot time, not a silent failure.

### Acceptance criteria

- [ ] Given `text_func = n -> n.name`, when `LeafLabelLayer` is rendered, then
  each leaf has exactly one text label at the leaf position plus offset.
- [ ] Given `threshold = v -> false`, when `VertexLabelLayer` is rendered, then
  no vertex labels appear.
- [ ] Given a `value_func` returning a value of an unexpected type, when the
  layer is added to a scene, then an informative error is raised identifying
  the vertex and the returned type.

### User stories addressed

- User story 28: Leaf labels with font, size, color, offset, italic.
- User story 29: Vertex labels with threshold filter.
- User story 30: Threshold predicate defaults to show-all.
- User story 47: `vertexvalue` type error surfaced at plot time.

---

## Issue 10: Clade annotation and scale bar layers

**Type**: AFK
**Blocked by**: Issue 7

### Parent PRD

`.workflow-docs/202604181600_tier1/01_prd.md`

### What to build

Implement `CladeHighlightLayer`, `CladeLabelLayer`, and `ScaleBarLayer` in
`src/Layers.jl`.

Deliver:

- `CladeHighlightLayer` / `cladehighlightlayer!` `@recipe`: attributes —
  `clade_vertices` (vector of MRCA vertices), `color`, `alpha`, `padding`
  (pixel-space padding around the clade bounding box). Rectangle is computed
  in data space from the clade's `boundingbox` plus `padding` mapped back via
  `CoordTransform`.
- `CladeLabelLayer` / `cladelabellayer!` `@recipe`: attributes —
  `clade_vertices`, `label_func` (clade MRCA → `String`), `color`, `fontsize`,
  `offset`. Renders a vertical bracket (bar + tick marks) outside the leaf
  labels plus a text annotation.
- `ScaleBarLayer` / `scalebarlayer!` `@recipe`: attributes — `position`,
  `length`, `label`, `color`, `linewidth`, `visible`. Auto-omitted (default
  `visible = false`) when `lineageunits` is `:vertexheights` or `:vertexlevels`
  (non-quantitative modes); explicitly shown when `lineageunits` is
  `:edgelengths`, `:branchingtime`, or `:coalescenceage`.
- Wire all three layers into the `lineageplot!` stub.

Extend `test/test_Layers.jl`: highlight rectangle covers all leaves of the
specified clade; clade bracket is placed outside leaf labels; scale bar is
absent by default for `:vertexheights`; scale bar is present for `:edgelengths`
when explicitly shown.

### How to verify

**Automated:**
- `CladeHighlightLayer` rectangle bounding box contains all leaf positions for
  the specified clade.
- `ScaleBarLayer` with `lineageunits = :vertexheights` has `visible = false`
  by default.
- `ScaleBarLayer` with `lineageunits = :edgelengths` has `visible = true` by
  default.

### Acceptance criteria

- [ ] Given a clade MRCA vertex, when `CladeHighlightLayer` is rendered, then
  the colored rectangle encloses all leaves descended from that vertex.
- [ ] Given `lineageunits = :vertexheights`, when `ScaleBarLayer` is created,
  then its default `visible` is `false`.
- [ ] Given `lineageunits = :edgelengths`, when `ScaleBarLayer` is created,
  then its default `visible` is `true`.

### User stories addressed

- User story 31: Clade highlight rectangle.
- User story 32: Clade label bracket.
- User story 33: Scale bar at configurable position.
- User story 34: Scale bar omitted by default for non-quantitative
  `lineageunits`.

---

## Issue 11: `LineageAxis` block

**Type**: AFK
**Blocked by**: Issues 6, 7

### Parent PRD

`.workflow-docs/202604181600_tier1/01_prd.md`

### What to build

Implement `src/LineageAxis.jl` as described in PRD Module 5.

Before writing any code:

1. Read `src/makielayout/` in the local Makie source (path:
   `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/makielayout/`)
   to establish the correct `@Block` definition pattern, attribute registration
   idiom, and `reset_limits!` / `autolimits!` override mechanism.
2. Resolve PRD Open Q4: confirm the exact Makie idiom for reversed axis limits
   under `display_polarity = :reversed` (reversed limits vs. `xreversed = true`
   attribute). Document the chosen idiom in a comment citing the Makie source
   file and line.

Deliver:

- `LineageAxis` defined with `Makie.@Block LineageAxis <: AbstractAxis`.
- Attributes: `axis_polarity` (`:forward` | `:backward`), `display_polarity`
  (`:standard` | `:reversed`; default `:standard`), `lineage_orientation`
  (`:left_to_right` | `:right_to_left` | `:radial`; default `:left_to_right`).
  `lineage_orientation = :right_to_left` is implemented as a distinct value;
  internally it delegates to the `:left_to_right` path with
  `display_polarity = :reversed` to stay DRY — but the attribute is fully
  public and independently settable. `show_x_axis` (default `false`),
  `show_y_axis` (default `false`), `show_grid` (default `false`), `title`,
  `xlabel`, `ylabel`.
- Default axis appearance: no tick marks, no grid lines, no spines (naked tree
  appearance). `show_x_axis = true` activates a quantitative x-axis.
- `axis_polarity` is inferred from the active `lineageunits` value when not
  set manually (forward modes → `:forward`; backward modes → `:backward`).
- `reset_limits!(ax::LineageAxis)`: fits axis to `TreeGeometry.boundingbox`,
  applying `display_polarity` and `lineage_orientation` when setting limits.
- `autolimits!(ax::LineageAxis)`: delegates to `reset_limits!`.
- `lineageplot!` dispatches on `Union{LineageAxis, Axis}`.
- Viewport-aware pixel↔data infrastructure via
  `CoordTransform.register_pixel_projection!`.

Write `test/test_LineageAxis.jl`: default attribute values; axis limits set
correctly for each `display_polarity` value; screen direction correct for each
`lineage_orientation` value (`:left_to_right`, `:right_to_left`, `:radial`);
`lineageplot!` works on both `LineageAxis` and `Axis`; pixel↔data correctness
after a simulated resize event. Use `CairoMakie`. Run Aqua and JET.

### How to verify

**Manual:**
```julia
using CairoMakie, LineagesMakie
fig = Figure()
ax = LineageAxis(fig[1,1]; display_polarity = :reversed)
lineageplot!(ax, root, acc)
# Rootvertex should appear at the right; leaves at the left
save("reversed.png", fig)
```

**Automated:**
- `LineageAxis` with `display_polarity = :reversed` sets x-axis limits so that
  the maximum process coordinate is at `xmin`.
- `lineage_orientation = :right_to_left` produces equivalent visual output to
  `display_polarity = :reversed` on a `:left_to_right` axis (same limits).
- `lineageplot!` on a plain `Axis` completes without error.
- After a viewport resize Observable update, pixel↔data mappings are updated.

### Acceptance criteria

- [ ] Given `display_polarity = :standard`, when `reset_limits!` is called,
  then the x-axis minimum is the minimum process coordinate and the maximum is
  the maximum process coordinate.
- [ ] Given `display_polarity = :reversed`, when `reset_limits!` is called,
  then the axis limits are set so that the maximum process coordinate appears
  at the visual left (for `:left_to_right` orientation).
- [ ] Given `lineage_orientation = :right_to_left`, when the axis is rendered,
  then the rootvertex appears at the right and leaves at the left.
- [ ] Given `axis_polarity` not manually set, when `LineageAxis` is created
  with a `lineageunits` value, then `axis_polarity` is inferred correctly
  (`:forward` for forward modes, `:backward` for backward modes).
- [ ] Given `show_x_axis = false` (default), when the scene is rendered, then
  no x-axis tick marks or labels appear.
- [ ] Given `lineageplot!` called on a plain `Axis`, then the plot renders
  without error using standard Makie axis defaults.

### User stories addressed

- User story 18: `axis_polarity` inferred automatically from `lineageunits`.
- User story 19: `axis_polarity` overridable.
- User story 20: `display_polarity = :reversed` on forward-time tree.
- User story 21: `display_polarity = :reversed` on coalescent tree.
- User story 22: `lineage_orientation` controls which screen axis carries the
  process coordinate.
- User story 36: `LineageAxis` block placeable in a `Figure` layout.
- User story 37: Default naked-tree appearance (no ticks, no grid, no spines).
- User story 38: Optional quantitative x-axis via `show_x_axis`.
- User story 39: Non-isotropic pixel↔data correctness.
- User story 40: `lineageplot!` works on both `LineageAxis` and `Axis`.

---

## Issue 12: Composite `LineagePlot` recipe and Observable reactivity

**Type**: AFK
**Blocked by**: Issues 8, 9, 10, 11

### Parent PRD

`.workflow-docs/202604181600_tier1/01_prd.md`

### What to build

Replace the `lineageplot!` stub from Issue 7 with the full composite
`LineagePlot` recipe that assembles all layers and wires Observable reactivity
end-to-end.

Deliver:

- `LineagePlot` / `lineageplot!` composite `@recipe`: accepts `rootvertex`
  (plain value or `Observable`) plus all accessor keywords and layer attribute
  keywords; delegates to `EdgeLayer`, `VertexLayer`, `LeafLayer`,
  `LeafLabelLayer`, `VertexLabelLayer`, `CladeHighlightLayer`,
  `CladeLabelLayer`, `ScaleBarLayer`.
- All layer attributes are exposed as Observables on `LineagePlot` following
  standard Makie recipe conventions.
- Layout recomputation is triggered reactively via ComputeGraph when the
  `rootvertex` Observable or any accessor-derived input Observable changes.
  Read `src/compute-plots.jl` in the local Makie source before implementing
  any ComputeGraph wiring.
- `Observable`-valued color, linewidth, alpha attributes update live without
  re-calling `lineageplot!`.
- `lift` works on any `LineagePlot` attribute Observable using standard Makie
  idioms.
- Wire circular layout into `EdgeLayer` (`:chord` edge style).

Extend `test/test_Layers.jl` and `test/test_Integration.jl`: full composite
recipe renders all layers; updating the `rootvertex` Observable triggers re-
layout; updating a color Observable changes the rendered color; `lift` on a
recipe attribute works; circular layout integration smoke test.

### How to verify

**Manual:**
```julia
using CairoMakie, LineagesMakie, Observables
tree_obs = Observable(root)
fig = Figure()
ax = LineageAxis(fig[1,1])
lineageplot!(ax, tree_obs, acc)
# Update the tree Observable — layout should recompute
tree_obs[] = new_root
```

**Automated:**
- Updating `tree_obs` triggers a layout recomputation (all vertex positions
  change to reflect the new tree).
- Updating a color `Observable` triggers a color update without full re-layout.
- A `lift`-derived attribute tracks its source Observable.

### Acceptance criteria

- [ ] Given `rootvertex` wrapped in an `Observable`, when the Observable is
  updated, then `vertex_positions` in the rendered scene reflect the new tree.
- [ ] Given an `Observable`-valued `color` attribute, when the Observable is
  updated, then the rendered edge colors change without re-calling
  `lineageplot!`.
- [ ] Given `lift(color_obs) do c; RGBA(c, 0.5) end` wired to an edge layer
  attribute, when `color_obs` changes, then the edge color updates.
- [ ] Given a `lineage_orientation = :radial` axis, when `lineageplot!` is
  called, then a circular layout is rendered.
- [ ] Each layer (`EdgeLayer`, `VertexLayer`, `LeafLayer`, `LeafLabelLayer`,
  `VertexLabelLayer`, `CladeHighlightLayer`, `CladeLabelLayer`,
  `ScaleBarLayer`) renders correctly in the composite recipe with no visible
  regression from its individual-layer tests.

### User stories addressed

- User story 16: Layout recomputed reactively when input tree Observable
  updates.
- User story 35: Each layer composable via separate `layer!` calls.
- User story 41: `rootvertex` wrapped in `Observable` triggers reactive update.
- User story 42: `Observable`-valued attributes update live.
- User story 43: `lift` works on recipe attributes using standard Makie idioms.

---

## Issue 13: Full integration test suite

**Type**: AFK
**Blocked by**: Issue 12

### Parent PRD

`.workflow-docs/202604181600_tier1/01_prd.md`

### What to build

Complete `test/test_Integration.jl` with systematic end-to-end coverage across
all layout × `lineageunits` × axis combinations.

Deliver:

- Smoke tests: rectangular layout × every `lineageunits` value × `CairoMakie`
  `Axis` and `LineageAxis` — renders to non-empty `Figure` without error.
- Smoke tests: circular layout × `:vertexheights` and `:edgelengths` ×
  `CairoMakie` `LineageAxis` with `lineage_orientation = :radial`.
- Polarity matrix: 2 `axis_polarity` values × 2 `display_polarity` values on
  `LineageAxis` — all four combinations render without error.
- Resize test: render a tree, simulate a viewport resize event, assert that
  markers remain the same pixel size.
- Observable reactivity test: update the tree `Observable` and assert
  `vertex_positions` reflect the new tree.
- Aqua and JET: confirm all new modules pass `Aqua.test_all(LineagesMakie)` and
  `JET.test_package(LineagesMakie)` with no new violations.

These tests are integration-only: they verify the end-to-end pipeline, not
internal module behavior. All module-level unit tests live in their respective
`test_<Module>.jl` files (already written in Issues 2–11).

### How to verify

**Automated:**
- Every integration test passes in a `CairoMakie` environment.
- `Aqua.test_all(LineagesMakie)` reports no ambiguities, piracy, or
  unbound type parameters.
- `JET.test_package(LineagesMakie; target_defined_modules = true)` reports no
  dispatch errors.
- CI passes on all matrix entries (Julia 1.10, 1.12, pre).

### Acceptance criteria

- [ ] Given every `lineageunits` value, when `lineageplot!` is called on a
  `CairoMakie` figure, then the figure is non-empty and no error is raised.
- [ ] Given each of the four `axis_polarity` × `display_polarity` combinations,
  when `LineageAxis` is rendered, then no error is raised.
- [ ] Given a viewport resize event, when marker pixel sizes are measured,
  then they match the pre-resize sizes within rounding tolerance.
- [ ] Given `Aqua.test_all(LineagesMakie)` and `JET.test_package(LineagesMakie)`,
  then both pass without violations.
- [ ] Given CI running on Julia 1.10, 1.12, and pre, then all jobs pass.

### User stories addressed

- User story 49: Every exported function has unit tests (covered cumulatively
  across Issues 2–11; this issue verifies nothing slipped through).
- User story 50: Integration tests render end-to-end via CairoMakie.
- User story 51: Aqua.jl and JET.jl checks pass in CI.
