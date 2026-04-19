---
date-created: 2026-04-18T16:00:00
vocabulary: .workflow-docs/00-design/controlled-vocabulary.md
---

# PRD: LineagesMakie.jl — Tier 1 MVP

## Controlled vocabulary

All identifiers, type names, keyword arguments, symbols, and documentation in
this project use the terms defined in
`.workflow-docs/00-design/controlled-vocabulary.md`. That file is the
authoritative reference; this section provides a quick-reference summary.

| Canonical | Brief definition | Proscribed alternates |
|---|---|---|
| `vertex` / `vertices` | Any graph element (root, internal, leaf) | `node` (as generic term) |
| `leaf` / `leaves` | Terminal vertex with no children | `tip` (proscribed everywhere) |
| `edge` | Directed connection between vertices | `branch` (code); prose: acceptable |
| `rootvertex` | Topmost vertex; has no parent | `root`, `root_vertex`, `seed` |
| `fromvertex` | Source vertex in an edge accessor | `parent`, `v1`, `src` |
| `tovertex` | Destination vertex in an edge accessor | `child`, `v2`, `dst` |
| `edgelength` | Scalar edge measure; also the accessor callable | `branch_length`, `edge_length`, `len` |
| `vertexvalue` | Callable: per-vertex data | `nodevalue`, `node_value` |
| `vertexage` | Callable: vertex age (≥ 0) | `node_age`, `vertex_age` |
| `age` | Time value of a vertex; 0 = present, > 0 = past | `time`, `divergence_time` |
| `depth` | Cumulative edge length from rootvertex | `distance_from_root` |
| `height` | Max depth (tree); edges-to-farthest-leaf (vertex) | `max_depth` |
| `boundingbox` | Smallest axis-aligned enclosing rectangle | `bounding_box`, `extent` |
| `vertex_positions` | Dict of 2D layout coordinates per vertex | `node_positions` |
| `edge_paths` | Geometric paths for edge rendering | `branch_paths` |
| `leaf_order` | Sequence of leaves along the transverse axis | `tip_order` |
| `leaf_spacing` | Inter-leaf spacing parameter | `tip_spacing`, `gap` |
| `color` | Color of any rendered element (Makie convention) | `colour` |
| `marker` | Visual symbol at a vertex | `glyph` (code) |

---

## User statement

> A general framework for visualization of evolutionary (phylogenetic,
> coalescent, cladistic, ancestral) graphs and associated biological data in
> the Makie ecosystem. Scope for this PRD: Tier 1 MVP only. The PRD should be
> based on the design docs and take into account the big picture.
>
> Input architecture: keyword-based accessors are the fundamental
> implementation; all adapters (AbstractTrees, Graphs.jl, etc.) are built on
> top of that layer. Layout decisions: all three layouts (rectangular cladogram,
> rectangular phylogram, circular) are required for Tier 1. Leaf spacing is
> keyword-arg controlled with equal spacing as default. Edge lengths are
> supplied via an accessor `edgelength(fromvertex, tovertex) -> value` (data
> units) or `edgelength(fromvertex, tovertex) -> (; value, units)` (with
> explicit unit; converted to data units); leaf-aligned topology mode computes
> positions internally. Recipe architecture: separate composable layers, all
> Tier 1; Observable-native; `LineageAxis` custom Block is Tier 1. No bespoke
> operators — everything idiomatic Julia/Makie. Every public function gets full
> tests (unit, integration, smoke, Aqua, JET). The target reference capacities
> document is aspirational vision, not a fixed API dictate — design from the
> ground up per STYLE-julia.md and Makie best practices. Non-isotropic axes
> must be handled correctly throughout; robust pixel↔data coordinate mapping
> infrastructure is required.

---

## Problem statement

Julia has no native Makie-based phylogenetic tree visualization package. The
existing landscape forces a choice between three inadequate options:

1. **Phylo.jl + Plots.jl** — Julia-native rendering, but requires constructing
   Phylo-specific types and has no Makie backend; cannot accept a
   generic AbstractTrees-compliant object.

2. **PhyloPlots.jl** — delegates all layout and rendering to R via RCall;
   requires a local R installation; non-native and non-interactive.

3. **D3Trees.jl** — accepts AbstractTrees-compliant objects (lowest barrier),
   but renders to JavaScript/browser only and requires an internet connection
   at render time to fetch D3.js and jQuery from CDN.

**GraphMakie.jl** is Makie-native and accepts `Graphs.jl` types, but it
provides no phylogenetic layouts (cladogram, dendrogram, circular, radial), no
annotation conventions (edge lengths, bootstrap values, clade labels), and none
of the tree data packages implement `Graphs.AbstractGraph`, so it cannot accept
them directly.

The result: a researcher with a tree in any Julia representation — a plain
struct with a `children` function, an AbstractTrees-compliant object, a
PhyloNetworks `HybridNetwork`, a Phylo.jl tree — has no path to a
publication-quality, interactive, Makie-native visualization without first
converting to a package-specific type and accepting the limitations above.

There is no path from a generic Julia tree to a Makie figure.

---

## Solution

When the Tier 1 MVP is complete, any Julia value that exposes a `children`
function (or any object satisfying the AbstractTrees.jl interface) can be
passed to `lineageplot` and rendered as a phylogenetic tree in a Makie figure,
with no internet access, no R, no package-specific conversion, and no
constraint on which Makie backend is used (CairoMakie, GLMakie, WGLMakie).

The plot will support three layout algorithms (rectangular leaf-aligned topology,
rectangular edge-length proportional, circular), independently togglable visual
layers (edges, internal vertex markers, leaf markers, leaf labels, vertex
labels, clade highlight, clade label, scale bar), a custom `LineageAxis` block
providing tree-aware coordinate context, and full Observable reactivity for
interactive use.

All geometry is computed in a pure functional core that is independently
testable. All rendering uses idiomatic Makie `@recipe` constructs. All
coordinate conversion between data space and pixel space is handled correctly
for non-isotropic axes. Every public function has full test coverage.

---

## User stories

### Input and data model

1. As a researcher, I want to pass any AbstractTrees.jl-compliant rootvertex to
   `lineageplot` and get a rendered tree, so that I can visualize trees from
   any Julia package without conversion.

2. As a researcher, I want to pass explicit `children`, `edgelength`, and
   `vertexvalue` keyword functions to `lineageplot`, so that I can visualize
   any tree-like data structure that does not implement AbstractTrees.jl.

3. As a researcher, I want the package to work with no internet connection and
   no R installation, so that it is usable in offline and non-R environments.

4. As a researcher, I want the package to work with CairoMakie, GLMakie, and
   WGLMakie without requiring changes to my plotting code, so that I can render
   to vector files, interactive windows, and notebooks with the same code.

5. As a researcher, I want to pass edge lengths as
   `edgelength(fromvertex, tovertex) -> Float64` (data units) or as
   `edgelength(fromvertex, tovertex) -> (; value, units)` (with explicit unit
   specification), so that I can control whether unit conversion is applied.

6. As a researcher, I want to omit `edgelength` entirely and get a leaf-aligned
   topology plot with equal-length edges, so that I can visualize topology
   without requiring edge-length data.

7. As a researcher, if I supply `edgelength` but some edges return `nothing` or
   `missing`, I want those edges rendered with a clear fallback (e.g., equal
   length) and a warning, not a silent error, so that partial data does not
   silently corrupt the layout.

8. As a researcher, I want to supply `vertexvalue` as a function
   `vertex -> any_value` to attach arbitrary data (bootstrap, posterior, name)
   to vertices, so that I can drive label and color layers from my own data.

9. As a researcher, I want to supply `vertexage` as a function
   `vertex -> Float64` (age ≥ 0) and use the `:vertexages` positioning mode,
   so that time-calibrated and coalescent trees are laid out with the correct
   temporal x-axis.

### Layout

10. As a researcher, I want to choose a positioning mode via the `mode` keyword
    (`:edgelengths`, `:vertexages`, `:vertexheights`, `:vertexlevels`,
    `:vertexdepths`, `:vertexcoords`, `:vertexpos`), so that I can control how
    vertex x-coordinates are determined independently of the tree data type.

11. As a researcher, I want the positioning mode to default to `:edgelengths`
    when an `edgelength` accessor is supplied, and to `:vertexheights` otherwise
    (leaf-aligned, equal topology spacing), so that I get a sensible plot with
    no configuration.

12. As a researcher, using any rectangular layout, I want leaves to be equally
    spaced on the y-axis by default, so that the tree is legible without any
    configuration.

13. As a researcher, I want to control leaf spacing via the `leaf_spacing`
    keyword argument, so that I can adjust density for trees of different sizes.

14. As a researcher, using the circular layout, I want leaves equally spaced
    angularly by default, so that the tree is legible without configuration.

15. As a researcher, I want the layout to be recomputed reactively when the
    input tree Observable is updated, so that animated or interactive updates
    work correctly.

16. As a researcher, when I resize the figure, I want marker sizes and label
    sizes to remain correct in pixel space even though the data coordinate range
    changes, so that resizing does not distort the appearance.

### Visual layers

17. As a researcher, I want edges rendered as right-angle segments (horizontal +
    vertical) for the rectangular layout, so that the tree has the standard
    phylogenetic appearance.

18. As a researcher, I want edges rendered as straight diagonal lines for an
    optional slanted variant in the rectangular layout, so that I can match
    publication conventions that use this style.

19. As a researcher, I want to set edge color, line width, line style, and alpha
    either uniformly or via a function `edge -> value` mapped over edges,
    so that I can encode continuous or categorical data on edges.

20. As a researcher, I want to toggle the edge layer independently of other
    layers, so that I can build the figure incrementally.

21. As a researcher, I want internal vertex markers (marker shape, color, fill,
    size, alpha) independently controllable, so that I can show or hide them or
    map data to their appearance.

22. As a researcher, I want leaf markers independently controllable with the
    same properties as internal vertex markers, so that I can distinguish
    leaves from internal vertices visually.

23. As a researcher, I want leaf labels rendered as text with controllable font,
    size, color, offset from the leaf, and an italic option, so that taxon names
    can be displayed in conventional style.

24. As a researcher, I want vertex labels rendered as text showing any vertex
    attribute (bootstrap, posterior, name) with a threshold filter, so that I
    can display only high-confidence support values without cluttering the
    figure.

25. As a researcher, if I provide a threshold for vertex labels, I want only
    vertices meeting the threshold to be labelled, and the threshold predicate
    to default to "show all", so that filtering is opt-in.

26. As a researcher, I want to highlight one or more clades by drawing a colored
    rectangle behind their edges and leaves, so that I can visually emphasize
    monophyletic groups.

27. As a researcher, I want to annotate a clade with a labelled bracket (vertical
    bar + text) placed outside the leaf labels, so that I can name taxonomic
    groups.

28. As a researcher, I want a scale bar showing edge-length units placed at a
    configurable position on the figure, so that readers can interpret
    edge-length proportional layouts.

29. As a researcher, when no edge lengths are encoded (`:vertexheights` or
    `:vertexlevels` mode), I want the scale bar omitted by default, so that the
    figure does not display meaningless scale information.

30. As a researcher, I want each visual layer to be independently composable via
    separate `layer!` calls on an axis, so that I can include exactly the layers
    I need without triggering unwanted defaults.

### LineageAxis

31. As a researcher, I want a `LineageAxis` block that I can place in a Makie
    `Figure` layout, so that I have a tree-aware axis with sensible defaults
    (no tick marks, no grid lines, optional x-axis for edge-length modes).

32. As a researcher, I want `LineageAxis` to suppress tick marks, grid lines,
    and axis spines by default (classic naked-tree appearance), so that the
    figure matches phylogenetic publication conventions without manual
    configuration.

33. As a researcher, I want `LineageAxis` to optionally display an x-axis with
    edge-length scale when using `:edgelengths` or `:vertexages` mode, so that
    quantitative positions are interpretable.

34. As a researcher, I want `LineageAxis` to correctly manage pixel↔data
    coordinate conversion for non-isotropic axes, so that circular markers
    appear circular even when x and y scales differ.

35. As a researcher, I want `lineageplot!` to work directly on both
    `LineageAxis` and standard Makie `Axis`, so that I can use the convenience
    of `LineageAxis` or integrate with existing figure layouts.

### Observables and reactivity

36. As a researcher, I want to wrap my tree in an `Observable` and pass it to
    `lineageplot!`, so that updating the Observable triggers a full re-layout
    and re-render reactively.

37. As a researcher, I want to pass `Observable`-valued attributes (color,
    linewidth, alpha) that update live when the Observable changes, so that I
    can animate or interactively update the visual appearance without
    re-calling `lineageplot!`.

38. As a researcher, I want to use Makie's `lift` to derive plot attributes from
    Observables I control, so that I can wire tree visualization to sliders,
    buttons, or other interactive elements using standard Makie idioms.

### Error handling

39. As a researcher, if `children` returns a cycle (not a tree), I want an
    informative error before layout begins, so that I do not receive a cryptic
    stack overflow or silent infinite loop.

40. As a researcher, if `edgelength` returns a negative value, I want an
    `ArgumentError` with a message identifying which edge is problematic, so
    that data errors are surfaced immediately.

41. As a researcher, if `vertexvalue` returns a value of an unexpected type for
    a label layer, I want an informative error at plot time, not a silent
    rendering failure.

42. As a researcher, if the tree has zero leaves, I want a clear error rather
    than an empty or broken figure, so that I can diagnose the data problem.

### Testing

43. As a developer, I want every exported function and type to have unit tests
    covering the documented contract, edge cases, and failure modes, so that
    regressions are caught immediately.

44. As a developer, I want integration tests that render a tree end-to-end with
    CairoMakie (non-interactive backend) and verify that the output is
    non-empty, so that the full pipeline is exercised in CI.

45. As a developer, I want Aqua.jl and JET.jl checks in CI, so that code
    quality and type inference issues are caught automatically.

---

## Implementation decisions

### Input contract: accessor-first design

The fundamental input contract is a set of callable keyword arguments passed
directly to `lineageplot`:

- `children`: `vertex -> iterable-of-children`; required
- `edgelength`: `(fromvertex, tovertex) -> Float64` or
  `(fromvertex, tovertex) -> (; value::Float64, units::Symbol)`; optional
- `vertexvalue`: `vertex -> Any`; optional; used by label and color layers
- `vertexage`: `vertex -> Float64`; optional; required when `mode = :vertexages`
- `vertexcoords`: `vertex -> Point2f`; optional; required when
  `mode = :vertexcoords`
- `vertexpos`: `vertex -> Point2f`; optional; required when `mode = :vertexpos`

All adapters — including the AbstractTrees.jl adapter — translate their source
objects into these callables. The recipe's internal geometry and rendering code
depends only on these callables, never on the source tree type. This is the
dependency inversion principle applied to the input boundary.

The AbstractTrees adapter is a thin shim: it wraps `AbstractTrees.children` and
optionally reads from `AbstractTrees.nodevalue` or user-supplied mappings, then
forwards to the accessor interface.

### Edge length modes and positioning mode stack

The `mode` keyword of layout functions selects how vertex x-coordinates are
determined. All modes ultimately populate `vertex_positions`. The modes form a
layered stack — each higher-level mode delegates to shared lower-level
traversal infrastructure, which is the architectural expression of DRY for
layout computation.

| Mode | Accessor required | x-coordinate source |
|---|---|---|
| `:edgelengths` | `edgelength` | Cumulative `edgelength(fromvertex, tovertex)` from `rootvertex` |
| `:vertexages` | `vertexage` | `vertexage(vertex)`; edge extent = `vertexage(fromvertex) − vertexage(tovertex)` |
| `:vertexdepths` | none | Cumulative topological edge count from `rootvertex` (all weights = 1) |
| `:vertexheights` | none | Per-vertex height (edges to farthest leaf); all leaves at x = 0; produces leaf-aligned cladogram appearance |
| `:vertexlevels` | none | Integer level = edge count from `rootvertex`; equal inter-level spacing; produces dendrogram appearance |
| `:vertexcoords` | `vertexcoords` | User-supplied `(x, y)` in data coordinates |
| `:vertexpos` | `vertexpos` | User-supplied `(x, y)` in pixel coordinates |

**Default mode detection:** If `edgelength` is supplied and `mode` is not set,
the default is `:edgelengths`. If neither `edgelength` nor `mode` is supplied,
the default is `:vertexheights` (leaf-aligned topology plot with all leaves at
the same x-coordinate).

**Missing edge lengths:** In `:edgelengths` mode, if `edgelength` returns
`nothing` or `missing` for an edge, that edge falls back to unit length with a
warning identifying the edge. Negative edge lengths raise `ArgumentError`
immediately.

**Shared implementation (deep stack):** `:vertexages` uses the same cumulative-
sum traversal as `:edgelengths`, with edge extent computed from age differences.
`:vertexdepths`, `:vertexheights`, and `:vertexlevels` all traverse the tree
via the `children` accessor using a shared depth-first pass, computing their
respective quantities in a single traversal. `:vertexcoords` and `:vertexpos`
bypass layout computation entirely, injecting pre-computed coordinates. This
stack means that adding a new mode rarely requires new traversal logic — it
reuses the existing infrastructure.

### Layout algorithms

Layout is computed by pure functions in the `Geometry` module. Each function
takes a `rootvertex`, accessor functions, and options; returns a `TreeGeometry`
value (immutable struct). No Makie dependency in this module.

Three layout geometries for Tier 1:

- **Rectangular**: leaves placed on the y-axis at equal spacing (default) or
  user-specified `leaf_spacing`; x-coordinate determined by the active
  positioning mode; right-angle edge segments connect parent y to child y then
  horizontally to child x.

- **Circular**: leaves placed at equal angular spacing (default) on a circle;
  radial position determined by the active positioning mode; edges are straight
  radial segments with arc connectors between sibling groups.

Leaf spacing is controlled via `leaf_spacing`. Default is `:equal`. A positive
`Float64` sets an explicit inter-leaf distance in layout units.

### Non-isotropic axis handling

The data coordinate system is not assumed to be isotropic. Axes may have very
different scales on x and y. All fixed-size elements — internal vertex and leaf
markers, label text, clade-highlight rectangles with fixed padding — must be
sized and positioned in pixel space and mapped back to data space for rendering,
or rendered with `space = :pixel` or `markerspace = :pixel` as appropriate.

The `CoordTransform` module provides tested utility functions for:

- projecting a data-space point to pixel coordinates using the current scene
  camera matrices
- converting a pixel-space offset to a data-space delta at a given data point
- registering viewport and projectionview Observables so that pixel↔data
  mappings update reactively when the figure is resized

These utilities are used by every layer that places elements with fixed pixel
sizes (markers, labels, padding). No layer may assume `x_scale == y_scale`.

### Makie recipe architecture

Each visual layer is an independent `@recipe`. The top-level `lineageplot` /
`lineageplot!` is a composite recipe that assembles the layers below, each
independently controllable via keyword arguments and Observables.

| Recipe type | Function | Responsibility |
|---|---|---|
| `EdgeLayer` | `edgelayer!` | Draws edges as right-angle or diagonal segments |
| `VertexLayer` | `vertexlayer!` | Draws markers at internal vertices |
| `LeafLayer` | `leaflayer!` | Draws markers at leaf vertices |
| `LeafLabelLayer` | `leaflabellayer!` | Renders text labels at leaves |
| `VertexLabelLayer` | `vertexlabellayer!` | Renders per-vertex values with threshold filter |
| `CladeHighlightLayer` | `cladehighlightlayer!` | Draws colored rectangles behind named clades |
| `CladeLabelLayer` | `cladelabellayer!` | Draws bracket + text for clade annotation |
| `ScaleBarLayer` | `scalebarlayer!` | Draws an edge-length reference bar |
| `LineagePlot` | `lineageplot!` | Composite: composes all layers above |

All recipes use Makie's ComputeGraph (`map!` / `register_computation!`) for
reactive attribute derivation, per the Makie 0.24+ recommended pattern.

### LineageAxis block

`LineageAxis` is defined with `Makie.@Block LineageAxis <: AbstractAxis`.
It wraps an internal `Scene` and provides:

- Default theme: no tick marks, no grid lines, no spines (classic naked-tree
  appearance)
- Optional x-axis for edge-length positioning modes (controllable via attribute)
- Viewport-aware pixel↔data coordinate infrastructure using the
  `CoordTransform` module
- Implements `reset_limits!` and `autolimits` for the tree's bounding box

`lineageplot!` dispatches on both `LineageAxis` and standard `Axis`, so both
work without user changes.

### Observables and reactivity

The `rootvertex` passed to `lineageplot` may be a plain value or an
`Observable`. The recipe exposes all attributes as Observables (standard Makie
contract). Layout recomputation is triggered reactively via the ComputeGraph
when any input Observable changes.

Users wire interactivity using standard Makie idioms: `lift`, `on`, `connect!`,
`Slider`, etc. No LineagesMakie-specific interaction API is introduced.

### Style and conventions

All code follows STYLE-julia.md exactly:

- Accessor-pattern functions are unannotated higher-order arguments (§1.13.1
  exception: annotation harms composability)
- All other public functions have argument annotations at the correct abstract
  level and explicit return type annotations (§1.13.1, §1.13.2)
- `struct` is default; `mutable struct` only with justification
- `@recipe` macro follows Makie conventions; its generated code is not
  overridden
- File-per-module structure; 400–600 LOC per file (§8)
- `using Package: name` only; never bare `using Package` (§1.16.6)
- Runic.jl formatting (§3.1)

The target-reference-capacities document defines the capability space; it does
not dictate API names or signatures. Every API decision is made from first
principles per STYLE-julia.md, the controlled vocabulary, and current Makie
idioms.

---

## Module design

### Module 1 — `Accessors`

**Responsibility:** Define the fundamental accessor protocol and provide the
AbstractTrees.jl adapter.

**Interface:**

- `TreeAccessor` struct: holds `children`, `edgelength`, `vertexvalue`,
  `vertexage`, `vertexcoords`, `vertexpos` callables (all except `children`
  optional, defaulting to `nothing`)
- `tree_accessor(rootvertex; children, edgelength=nothing, vertexvalue=nothing,
  vertexage=nothing, vertexcoords=nothing, vertexpos=nothing)`: constructs a
  `TreeAccessor` from explicit keyword functions; validates that `children` is
  callable
- `abstracttrees_accessor(rootvertex; edgelength=nothing, vertexvalue=nothing,
  vertexage=nothing)`: constructs a `TreeAccessor` by wrapping
  `AbstractTrees.children`; requires AbstractTrees.jl to be loaded
- Predicate utilities: `is_leaf(accessor, vertex) -> Bool`,
  `leaves(accessor, rootvertex) -> iterator`,
  `preorder(accessor, rootvertex) -> iterator`

**Failure modes:** `children` not callable → `ArgumentError` at construction;
cycle detected during traversal → `ArgumentError` before layout.

**Tested:** Yes

---

### Module 2 — `Geometry`

**Responsibility:** Compute 2D layout coordinates from tree topology and
positioning mode. Pure functional; no Makie dependency.

**Interface:**

- `TreeGeometry` struct (immutable): `vertex_positions::Dict`,
  `edge_paths`, `leaf_order`, `boundingbox`
- `rectangular_layout(rootvertex, accessor; leaf_spacing=:equal,
  mode=:vertexheights) -> TreeGeometry`
- `circular_layout(rootvertex, accessor; leaf_spacing=:equal,
  mode=:vertexheights) -> TreeGeometry`
- `boundingbox(geom::TreeGeometry) -> Rect2f`

Positioning modes implemented: `:edgelengths`, `:vertexages`, `:vertexdepths`,
`:vertexheights`, `:vertexlevels`, `:vertexcoords`, `:vertexpos`. All
topology-computed modes (`:vertexdepths`, `:vertexheights`, `:vertexlevels`)
share a single depth-first traversal implementation.

**Failure modes:** negative edge length → `ArgumentError` with offending edge
identified; zero-leaf tree → `ArgumentError`; missing edge length in
`:edgelengths` mode → warning + unit-length fallback for that edge.

**Tested:** Yes

---

### Module 3 — `CoordTransform`

**Responsibility:** Provide correct, tested, Observable-aware utilities for
converting between data coordinates and pixel coordinates for non-isotropic
axes.

**Interface:**

- `data_to_pixel(scene, point::Point2f) -> Point2f`
- `pixel_to_data(scene, point::Point2f) -> Point2f`
- `pixel_offset_to_data_delta(scene, data_point::Point2f, pixel_offset::Vec2f) -> Vec2f`
- `register_pixel_projection!(plot_attrs, scene)`: registers `viewport` and
  `projectionview` as ComputeGraph inputs so pixel↔data mappings update
  reactively on viewport change

**Failure modes:** degenerate viewport (zero size) → identity transform with
warning.

**Tested:** Yes

---

### Module 4 — `Layers`

**Responsibility:** Define all composable `@recipe` plot types for individual
visual layers, and the composite `LineagePlot` recipe.

**Interface** (each recipe follows Makie `@recipe` conventions):

- `EdgeLayer` / `edgelayer!`: attributes — `color`, `linewidth`, `linestyle`,
  `alpha`, `edge_style` (`:right_angle` | `:diagonal`)
- `VertexLayer` / `vertexlayer!`: attributes — `marker`, `color`, `markersize`,
  `strokecolor`, `alpha`, `visible`
- `LeafLayer` / `leaflayer!`: same attributes as `VertexLayer`
- `LeafLabelLayer` / `leaflabellayer!`: attributes — `text_func` (vertex →
  String), `font`, `fontsize`, `color`, `offset`, `italic`, `align`
- `VertexLabelLayer` / `vertexlabellayer!`: attributes — `value_func`,
  `threshold`, `position` (`:vertex` | `:toward_parent`)
- `CladeHighlightLayer` / `cladehighlightlayer!`: attributes —
  `clade_vertices` (vector of MRCA vertices), `color`, `alpha`, `padding`
- `CladeLabelLayer` / `cladelabellayer!`: attributes — `clade_vertices`,
  `label_func`, `color`, `fontsize`, `offset`
- `ScaleBarLayer` / `scalebarlayer!`: attributes — `position`, `length`,
  `label`, `color`, `linewidth`
- `LineagePlot` / `lineageplot!`: composite; accepts `rootvertex` + accessor
  keywords; delegates to all layers above

All layer recipes use `CoordTransform.register_pixel_projection!` for
non-isotropic-safe coordinate handling.

**Tested:** Yes

---

### Module 5 — `LineageAxis`

**Responsibility:** Custom Makie `Block` providing a tree-aware axis with
sensible defaults and viewport-managed pixel↔data coordinate infrastructure.

**Interface:**

- `LineageAxis(figure_position; kwargs...)`: standard Block constructor
- Attributes: `show_x_axis` (default `false`), `show_y_axis` (default
  `false`), `show_grid` (default `false`), `title`, `xlabel`
- `reset_limits!(ax::LineageAxis)`: fits axis to tree boundingbox
- `autolimits!(ax::LineageAxis)`: equivalent to `reset_limits!`

`lineageplot!` dispatches on `Union{LineageAxis, Axis}` so both work;
`LineageAxis` provides tree-specific defaults.

**Tested:** Yes (including visual smoke test via CairoMakie)

---

## Testing decisions

### What constitutes a good test

Tests exercise the documented public contract, not implementation internals.
A test for `rectangular_layout` checks that all vertices have positions, leaves
are at correct x-coordinate for the active mode, y-positions are evenly spaced
when `leaf_spacing = :equal`, and the boundingbox contains all positions — not
that a specific private variable holds a given value.

Tests are deterministic. No wall-clock time, no external network. Tree fixtures
are constructed inline using simple topologies: 4-leaf balanced, 6-leaf
unbalanced, polytomy, single-leaf.

### Test file structure

```
test/
  runtests.jl              # top-level: Aqua, JET, includes all test_*.jl
  test_Accessors.jl
  test_Geometry.jl
  test_CoordTransform.jl
  test_Layers.jl
  test_LineageAxis.jl
  test_Integration.jl      # end-to-end smoke tests via CairoMakie
```

### Reference patterns

- Existing Aqua + JET setup in `test/runtests.jl` (already present in repo)
- GraphMakie.jl recipe at
  `00_resources/codebases-and-documentation/GraphMakie.jl/src/recipes.jl`
  as reference for per-element attribute handling and ComputeGraph usage

---

## Out of scope

The following are explicitly deferred to later tiers:

- **Graphs.jl adapter** — Tier 2
- **PhyloNetworks.jl adapter**, hybrid/reticulation vertices and edges — Tier 3
- **Fan layout**, slanted layout, unrooted layouts (equal-angle, daylight) — Tier 2
- **Clade collapse** (triangle glyph), clade zoom/inset — Tier 2
- **Continuous color/width gradient along edges** — Tier 2
- **Aligned heatmap panel**, tanglegram layout — Tier 2
- **Vertex pie/bar chart insets**, MSA panel, faceted data panel — Tier 4
- **Tree density overlay** — Tier 4
- **Time-scale axis with geological periods** — Tier 4
- **Interactive features** (tooltip, click-to-collapse, lazy expand) — Tier 4
- **External data join operator** (no bespoke operators; users join data to the
  tree before calling `lineageplot`)
- **File I/O** (Newick, Nexus parsing) — not in scope for this package
- **Layout transformation operations** (flip, rotate, ladderise) — Tier 2

---

## Open questions

1. **Makie version floor:** ComputeGraph (`map!` / `register_computation!`) is
   Makie 0.24+. The minimum supported Makie version must be established before
   implementation begins. If older versions must be supported, the
   `Observable`-based (`onany`) pattern is the fallback.
   *Owner:* implementation phase. *Resolution:* check Makie changelog; set
   `[compat]` accordingly.

2. **Runic.jl CI integration:** STYLE-julia.md §3.1 requires Runic.jl
   formatting enforced in CI. A formatting check step must be added to
   `.github/workflows/CI.yml`.
   *Owner:* implementation phase. *Resolution:* add `runic --check` to CI.

3. **Circular layout minimum angular spacing:** Equal angular spacing is the
   default, but a `min_leaf_angle` floor may be needed for very large trees.
   *Owner:* Geometry module implementation. *Resolution:* decide during
   `circular_layout` implementation; document the parameter.

---

## Further notes

### Governance documents

All implementation must follow:

- `STYLE-julia.md` — Julia functional design principles, naming, annotations,
  mutation contract, anti-patterns, codebase structure. Mandatory; every PR
  must comply. Forward this requirement to all downstream issues and tasks.
- `STYLE-git.md` — OneFlow branching, commit message conventions. Mandatory.
- `STYLE-docs.md` — Sentence case headings, punctuation, prose style. Applies
  to all documentation files. Mandatory.
- `CONTRIBUTING.md` — Community and PR process. Applies to all contributions.
- `.workflow-docs/00-design/controlled-vocabulary.md` — Authoritative term
  list. All identifiers, types, symbols, and prose must use canonical terms.
  No amendment without explicit project-owner approval.

Issues and tasks generated from this PRD must reference all of these documents
and require compliance.

### Makie documentation

Before and during implementation, consult the current Makie documentation at:
`/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/`

Key files:
- `docs/src/explanations/recipes.md` — `@recipe` macro and attribute system
- `docs/src/explanations/conversion_pipeline.md` — coordinate pipeline
- `docs/src/explanations/architecture.md` — Scene, Plot, Block hierarchy
- `GraphMakie.jl/src/recipes.jl` — reference for per-element attribute
  handling and ComputeGraph pixel-projection pattern

### Non-isotropic axis handling

No code anywhere in this package may assume that the x and y data-coordinate
scales are equal. Markers, labels, and padding that should be fixed in screen
size must use `CoordTransform` utilities or Makie's `markerspace = :pixel`.
This applies to all five modules. Violation is a correctness bug.

### Target reference capacities document status

`.workflow-docs/00-design/target-reference-capacities.md` is a vision document
describing the desired capability space and feature vocabulary. It is the
functional reference, not the API specification. Specific names, signatures,
and structures in that document are illustrative, not binding. All API
decisions are derived from first principles per STYLE-julia.md, the controlled
vocabulary, and current Makie best practices.
