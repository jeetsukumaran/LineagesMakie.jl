---
date-created: 2026-04-18T16:00:00
date-revised: 2026-04-19T00:00:00
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
| `vertex` / `vertices` | Any graph element (rootvertex, internal, leaf) | `node` (as generic term) |
| `leaf` / `leaves` | Terminal vertex with no children | `tip` (proscribed everywhere) |
| `edge` | Directed connection between vertices | `branch` (in code) |
| `rootvertex` | Topmost vertex; has no parent | `root`, `root_vertex`, `seed` |
| `fromvertex` | Source vertex in an edge accessor | `parent`, `v1`, `src` |
| `tovertex` | Destination vertex in an edge accessor | `child`, `v2`, `dst` |
| `edgelength` | Scalar edge measure; also the accessor callable | `branch_length`, `edge_length`, `len` |
| `vertexvalue` | Callable: per-vertex data | `nodevalue`, `node_value` |
| `branchingtime` | Cumulative edge length from rootvertex; root = 0; forward polarity | `depth`, `distance_from_root`, `divergence_time` |
| `coalescenceage` | Cumulative edge length to leaf; leaf = 0; backward polarity; ultrametric | `age`, `vertexage`, `node_age` |
| `height` | Max branchingtime (tree-level); edge-count-to-farthest-leaf (per-vertex) | `max_depth`, `depth` |
| `boundingbox` | Smallest axis-aligned enclosing rectangle | `bounding_box`, `extent` |
| `vertex_positions` | Dict of 2D layout coordinates per vertex | `node_positions` |
| `edge_paths` | Geometric paths for edge rendering | `branch_paths` |
| `leaf_order` | Sequence of leaves along the transverse axis | `tip_order` |
| `leaf_spacing` | Inter-leaf spacing parameter | `tip_spacing`, `gap` |
| `color` | Color of any rendered element (Makie convention) | `colour` |
| `marker` | Visual symbol at a vertex | `glyph` (in code) |
| `axis_polarity` | Semantic direction of increasing process coordinates (`:forward` / `:backward`) | `time_direction`, `polarity` |
| `display_polarity` | Screen direction of increasing process coordinates (`:standard` / `:reversed`) | `flip`, `invert`, `reverse_axis` |
| `lineage_orientation` | How the lineage axis is embedded in the scene | `orientation`, `direction` |
| `process_coordinate` | Documentation term: the scalar that positions a vertex along the lineage axis | (not a code identifier) |
| `interval_schema` | Named bins on the lineage axis; Tier 4 | `time_scale`, `epoch_map` |
| `lineageunits` | Keyword arg selecting how vertex process coordinates are determined | `mode`, `positioning_mode`, `layout_mode` |

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
> explicit unit; converted to data units); leaf-aligned topology `lineageunits`
> value computes positions internally. Recipe architecture: separate composable layers, all
> Tier 1; Observable-native; `LineageAxis` custom Block is Tier 1. No bespoke
> operators — everything idiomatic Julia/Makie. Every public function gets full
> tests (unit, integration, smoke, Aqua, JET). The target reference capacities
> document is aspirational vision, not a fixed API dictate — design from the
> ground up per STYLE-julia.md and Makie best practices. Non-isotropic axes
> must be handled correctly throughout; robust pixel↔data coordinate mapping
> infrastructure is required.

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

A second, deeper problem: every existing tool conflates three independently
variable concerns — the tree's intrinsic process coordinate, the researcher's
semantic interpretation of that coordinate, and the plot's screen embedding.
This conflation makes it impossible to, for example, display a forward-time
tree root-at-right, or display a coalescent tree in a non-standard orientation,
without special-casing the tool itself. `LineageAxis` resolves this by making
the three concerns explicitly separable.

## Solution

When the Tier 1 MVP is complete, any Julia value that exposes a `children`
function (or any object satisfying the AbstractTrees.jl interface) can be
passed to `lineageplot` and rendered as a phylogenetic tree in a Makie figure,
with no internet access, no R, no package-specific conversion, and no
constraint on which Makie backend is used (CairoMakie, GLMakie, WGLMakie).

The plot will support three layout algorithms (rectangular leaf-aligned
topology, rectangular edge-length proportional, circular), all eight
`lineageunits` values (`:edgelengths`, `:branchingtime`, `:coalescenceage`,
`:vertexdepths`, `:vertexheights`, `:vertexlevels`, `:vertexcoords`,
`:vertexpos`), independently togglable visual layers (edges, internal vertex
markers, leaf markers, leaf labels, vertex labels, clade highlight, clade
label, scale bar), a `LineageAxis` custom block that separates process
coordinates from screen embedding, and full Observable reactivity for
interactive use.

All geometry is computed in a pure functional core that is independently
testable. All rendering uses idiomatic Makie `@recipe` constructs.
`LineageAxis` exposes `axis_polarity`, `display_polarity`, and
`lineage_orientation` as independent attributes so that the tree-centric,
user-centric, and plotting-centric views of the same tree are always
independently controllable. Every public function has full test coverage.

## Foundational design principle: the three-view model

Every design decision in this PRD is governed by a three-view model of any
tree plot. The three views are independent and must remain separately
addressable throughout the implementation.

**Tree-centric view** — What is the structure? What scalar positions each
vertex along the primary dimension? This is determined by the data and the
`lineageunits` value. The result is a set of `process_coordinate` values for
each vertex.

**User-centric view** — What does the researcher mean by those scalar values?
Are they forward evolutionary time (diversification), backward coalescent time,
substitutions per site, event ranks? The package records the `axis_polarity`
of the active `lineageunits` value (`:forward` for root-relative values,
`:backward` for leaf-relative values) but imposes no further biological
interpretation.

**Plotting-centric view** — How does the tree appear on screen? Which physical
axis carries the process coordinate (`lineage_orientation`)? Does increasing
process-coordinate value map to rightward or leftward (`display_polarity`)?

These three views are independent. A tree with leaf-relative process
coordinates (`:backward` axis polarity) can be displayed in either screen
direction. A forward-time tree can be displayed root-at-right (common in
paleontology) by setting `display_polarity = :reversed`. The combination of
`axis_polarity` and `display_polarity` unambiguously records what the user
will see, with no implicit conventions.

No module in this package may assume that any one of these three views implies
another. The `Geometry` module computes positions from process coordinates
without any knowledge of the screen embedding. `CoordTransform` handles
pixel↔data conversion without knowledge of semantic polarity. `LineageAxis`
carries the screen attributes without encoding any biological meaning.

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
   topology plot (`lineageunits = :vertexheights`) with all leaves at the same
   x-coordinate, so that I can visualize topology without requiring
   edge-length data.

7. As a researcher, if I supply `edgelength` but some edges return `nothing` or
   `missing`, I want those edges rendered with a unit-length fallback and a
   warning, not a silent error, so that partial data does not silently corrupt
   the layout.

8. As a researcher, I want to supply `vertexvalue` as a function
   `vertex -> any_value` to attach arbitrary data (bootstrap, posterior, name)
   to vertices, so that I can drive label and color layers from my own data.

9. As a researcher, I want to supply `coalescenceage` as a function
   `vertex -> Float64` (leaf = 0, increases toward root) and use the
   `lineageunits = :coalescenceage`, so that coalescent trees are laid out
   with leaves at one end and the rootvertex at the other.

10. As a researcher, I want to supply `branchingtime` as a function
    `vertex -> Float64` and use `lineageunits = :branchingtime`, so that
    I can provide pre-computed divergence times directly without re-deriving
    them from per-edge lengths.

### Layout

11. As a researcher, I want to choose a `lineageunits` value via the
    `lineageunits` keyword (`:edgelengths`, `:branchingtime`, `:coalescenceage`,
    `:vertexheights`, `:vertexlevels`, `:vertexdepths`, `:vertexcoords`,
    `:vertexpos`), so that I can control how vertex process coordinates are
    determined independently of the tree data type.

12. As a researcher, I want the `lineageunits` to default to `:edgelengths`
    when an `edgelength` accessor is supplied, and to `:vertexheights` otherwise,
    so that I get a sensible plot with no configuration.

13. As a researcher, using any rectangular layout, I want leaves to be equally
    spaced on the transverse axis by default, so that the tree is legible
    without any configuration.

14. As a researcher, I want to control leaf spacing via the `leaf_spacing`
    keyword argument, so that I can adjust density for trees of different sizes.

15. As a researcher, using the circular layout, I want leaves equally spaced
    angularly by default, so that the tree is legible without configuration.

16. As a researcher, I want the layout to be recomputed reactively when the
    input tree Observable is updated, so that animated or interactive updates
    work correctly.

17. As a researcher, when I resize the figure, I want marker sizes and label
    sizes to remain correct in pixel space even though the data coordinate range
    changes, so that resizing does not distort the appearance.

### The three-view model in use

18. As a researcher, I want `LineageAxis` to infer `axis_polarity` automatically
    from the active `lineageunits` value, so that I do not need to specify it
    manually for standard use cases.

19. As a researcher, I want to override `axis_polarity` on `LineageAxis`, so
    that I can control how the x-axis tick labels and annotations describe the
    process direction when the default inference is wrong for my use case.

20. As a researcher, I want to set `display_polarity = :reversed` on
    `LineageAxis` so that I can display a forward-time tree with the rootvertex
    at the right and leaves at the left (paleontological convention), without
    changing the data or the `lineageunits` value.

21. As a researcher, I want to set `display_polarity = :reversed` on
    `LineageAxis` so that I can display a coalescent tree
    (`lineageunits = :coalescenceage`, backward polarity) with the rootvertex
    at the left and leaves at the right, if my context requires that orientation.

22. As a researcher, I want to set `lineage_orientation` on `LineageAxis` to
    control which screen axis carries the process coordinate, so that I can
    produce left-to-right, right-to-left, or (in Tier 2) top-to-bottom and
    bottom-to-top layouts from the same `lineageunits` value.

### Visual layers

23. As a researcher, I want edges rendered as right-angle segments (horizontal
    + vertical) for the rectangular layout, so that the tree has the standard
    phylogenetic appearance.

24. As a researcher, I want to set edge color, line width, line style, and alpha
    either uniformly or via a function `(fromvertex, tovertex) -> value` mapped
    over edges, so that I can encode continuous or categorical data on edges.

25. As a researcher, I want to toggle the edge layer independently of other
    layers, so that I can build the figure incrementally.

26. As a researcher, I want internal vertex markers (marker shape, color, fill,
    size, alpha) independently controllable, so that I can show or hide them or
    map data to their appearance.

27. As a researcher, I want leaf markers independently controllable with the
    same properties as internal vertex markers, so that I can distinguish
    leaves from internal vertices visually.

28. As a researcher, I want leaf labels rendered as text with controllable font,
    size, color, offset from the leaf, and an italic option, so that taxon names
    can be displayed in conventional style.

29. As a researcher, I want vertex labels rendered as text showing any vertex
    attribute (bootstrap, posterior, name) with a threshold filter, so that I
    can display only high-confidence support values without cluttering the
    figure.

30. As a researcher, if I provide a threshold for vertex labels, I want only
    vertices meeting the threshold to be labelled, and the threshold predicate
    to default to "show all", so that filtering is opt-in.

31. As a researcher, I want to highlight one or more clades by drawing a colored
    rectangle behind their edges and leaves, so that I can visually emphasize
    monophyletic groups.

32. As a researcher, I want to annotate a clade with a labelled bracket (vertical
    bar + text) placed outside the leaf labels, so that I can name taxonomic
    groups.

33. As a researcher, I want a scale bar showing edge-length units placed at a
    configurable position on the figure, so that readers can interpret
    edge-length proportional layouts.

34. As a researcher, when no edge lengths are encoded
    (`lineageunits = :vertexheights` or `:vertexlevels`), I want the scale bar
    omitted by default, so that the
    figure does not display meaningless scale information.

35. As a researcher, I want each visual layer to be independently composable via
    separate `layer!` calls on an axis, so that I can include exactly the layers
    I need without triggering unwanted defaults.

### LineageAxis

36. As a researcher, I want a `LineageAxis` block that I can place in a Makie
    `Figure` layout, so that I have a tree-aware axis with sensible defaults
    (no tick marks, no grid lines, optional x-axis for quantitative `lineageunits` values).

37. As a researcher, I want `LineageAxis` to suppress tick marks, grid lines,
    and axis spines by default (classic naked-tree appearance), so that the
    figure matches phylogenetic publication conventions without manual
    configuration.

38. As a researcher, I want `LineageAxis` to optionally display an x-axis with
    quantitative scale when `lineageunits` is `:edgelengths`, `:branchingtime`,
    or `:coalescenceage`, so that calibrated positions are interpretable.

39. As a researcher, I want `LineageAxis` to correctly manage pixel↔data
    coordinate conversion for non-isotropic axes, so that circular markers
    appear circular even when x and y scales differ.

40. As a researcher, I want `lineageplot!` to work directly on both
    `LineageAxis` and standard Makie `Axis`, so that I can use the convenience
    of `LineageAxis` or integrate with existing figure layouts.

### Observables and reactivity

41. As a researcher, I want to wrap my tree in an `Observable` and pass it to
    `lineageplot!`, so that updating the Observable triggers a full re-layout
    and re-render reactively.

42. As a researcher, I want to pass `Observable`-valued attributes (color,
    linewidth, alpha) that update live when the Observable changes, so that I
    can animate or interactively update the visual appearance without
    re-calling `lineageplot!`.

43. As a researcher, I want to use Makie's `lift` to derive plot attributes from
    Observables I control, so that I can wire tree visualization to sliders,
    buttons, or other interactive elements using standard Makie idioms.

### Error handling

44. As a researcher, if `children` returns a cycle (not a tree), I want an
    informative error before layout begins, so that I do not receive a cryptic
    stack overflow or silent infinite loop.

45. As a researcher, if `edgelength` returns a negative value, I want an
    `ArgumentError` with a message identifying which edge is problematic, so
    that data errors are surfaced immediately.

46. As a researcher, if `coalescenceage` is used with
    `lineageunits = :coalescenceage` and the tree is not ultrametric, I want an
    `ArgumentError` by default, and
    control over the fallback policy via a `nonultrametric` keyword
    (`:minimum`, `:maximum`, `:error`), so that non-ultrametric trees are
    handled explicitly rather than silently.

47. As a researcher, if `vertexvalue` returns a value of an unexpected type for
    a label layer, I want an informative error at plot time, not a silent
    rendering failure.

48. As a researcher, if the tree has zero leaves, I want a clear error rather
    than an empty or broken figure, so that I can diagnose the data problem.

### Testing

49. As a developer, I want every exported function and type to have unit tests
    covering the documented contract, edge cases, and failure modes, so that
    regressions are caught immediately.

50. As a developer, I want integration tests that render a tree end-to-end with
    CairoMakie (non-interactive backend) and verify that the output is
    non-empty, so that the full pipeline is exercised in CI.

51. As a developer, I want Aqua.jl and JET.jl checks in CI, so that code
    quality and type inference issues are caught automatically.

## Implementation decisions

### Input contract: accessor-first design

The fundamental input contract is a set of callable keyword arguments passed
directly to `lineageplot`:

- `children`: `vertex -> iterable-of-children`; required
- `edgelength`: `(fromvertex, tovertex) -> Float64` or
  `(fromvertex, tovertex) -> (; value::Float64, units::Symbol)`; optional
- `vertexvalue`: `vertex -> Any`; optional; used by label and color layers
- `branchingtime`: `vertex -> Float64`; optional; required when
  `lineageunits = :branchingtime`; returns pre-computed cumulative edge-length
  sum from `rootvertex`
- `coalescenceage`: `vertex -> Float64`; optional; required when
  `lineageunits = :coalescenceage`; leaf = 0, increases toward rootvertex;
  ultrametric tree required by default
- `vertexcoords`: `vertex -> Point2f`; optional; required when
  `lineageunits = :vertexcoords`
- `vertexpos`: `vertex -> Point2f`; optional; required when
  `lineageunits = :vertexpos`

All adapters — including the AbstractTrees.jl adapter — translate their source
objects into these callables. The recipe's internal geometry and rendering code
depends only on these callables, never on the source tree type. This is the
dependency inversion principle applied to the input boundary.

The AbstractTrees adapter wraps `AbstractTrees.children` and optionally reads
from `AbstractTrees.nodevalue` or user-supplied mappings, then forwards to the
accessor interface.

### The `lineageunits` keyword

The `lineageunits` keyword selects how vertex process coordinates are
determined. All `lineageunits` values ultimately populate `vertex_positions`.
The `lineageunits` values form a layered stack: each higher-level value
delegates to shared traversal infrastructure.

| `lineageunits` value | Accessor required | Process coordinate source | `axis_polarity` |
|---|---|---|---|
| `:edgelengths` | `edgelength` | Cumulative `edgelength(fromvertex, tovertex)` from rootvertex; computes `branchingtime` on the fly | `:forward` |
| `:branchingtime` | `branchingtime` | `branchingtime(vertex)` directly; user pre-supplies divergence times | `:forward` |
| `:coalescenceage` | `coalescenceage` | `coalescenceage(vertex)`; leaf = 0; requires ultrametric tree (see `nonultrametric`) | `:backward` |
| `:vertexdepths` | none | Cumulative topological edge count from rootvertex (all weights = 1) | `:forward` |
| `:vertexheights` | none | Per-vertex height (edge count to farthest leaf); topology-only analogue of `:coalescenceage` | `:backward` |
| `:vertexlevels` | none | Integer level = edge count from rootvertex; equal inter-level spacing; topology-only analogue of `:branchingtime` | `:forward` |
| `:vertexcoords` | `vertexcoords` | User-supplied `(x, y)` in data coordinates | User-defined |
| `:vertexpos` | `vertexpos` | User-supplied `(x, y)` in pixel coordinates | User-defined |

**Default `lineageunits` detection:** If `edgelength` is supplied and
`lineageunits` is not set, the default is `:edgelengths`. If neither
`edgelength` nor `lineageunits` is supplied, the default is `:vertexheights`.

**Polarity:** Forward `lineageunits` values (`:edgelengths`, `:branchingtime`,
`:vertexdepths`, `:vertexlevels`) assign rootvertex process coordinate = 0 and
increase toward leaves. Backward `lineageunits` values (`:coalescenceage`,
`:vertexheights`) assign leaves process coordinate = 0 and increase toward
root. With the default `display_polarity = :standard` and
`lineage_orientation = :left_to_right`, forward `lineageunits` values place
leaves at the right; backward `lineageunits` values place the rootvertex at
the right.

**Missing edge lengths:** When `lineageunits = :edgelengths`, if `edgelength`
returns
`nothing` or `missing` for an edge, that edge falls back to unit length with a
warning identifying the edge. Negative edge lengths raise `ArgumentError`
immediately.

**Non-ultrametric trees with `lineageunits = :coalescenceage`:** If any two children of a
vertex yield inconsistent coalescence age estimates, the default raises
`ArgumentError`. Controlled by a `nonultrametric` keyword: `:error` (default),
`:minimum` (min over all leaf paths), `:maximum` (max over all leaf paths).

**Shared traversal infrastructure:** `:branchingtime` and `:edgelengths` share
a preorder cumulative-sum traversal; `:edgelengths` derives the sum from the
`edgelength` accessor, `:branchingtime` reads it directly. `:coalescenceage`
uses a postorder traversal. `:vertexdepths`, `:vertexheights`, and
`:vertexlevels` share a single depth-first pass via the `children` accessor.
`:vertexcoords` and `:vertexpos` bypass layout computation entirely.

### The three-view model in the implementation

The three-view model is not just a design principle — it has direct
implementation consequences that constrain module boundaries.

**`Geometry` module** (tree-centric): computes `TreeGeometry` (process
coordinates, edge paths, leaf order) from the tree structure and accessor
callables. Has no knowledge of screen layout, axis direction, or biological
semantics. It produces process coordinates in their natural direction: forward
`lineageunits` values produce values increasing from root to leaf; backward
`lineageunits` values produce
values increasing from leaf to root.

**`CoordTransform` module** (plotting-centric): handles pixel↔data conversions
for non-isotropic axes. Has no knowledge of which process coordinate type is in
use or what it means biologically. It operates purely on data-coordinate and
pixel-coordinate values.

**`LineageAxis` module** (interface between all three views): exposes
`axis_polarity`, `display_polarity`, and `lineage_orientation` as independently
settable attributes. It applies `display_polarity` and `lineage_orientation` at
axis setup time (via axis limits and direction), independently of what
`Geometry` computed. This is where the three views are joined.

No module may cross these boundaries. `Geometry` must not apply any screen
direction transformation. `CoordTransform` must not interpret process
coordinates. `LineageAxis` must not re-derive process coordinates.

### Layout algorithms

Layout is computed by pure functions in the `Geometry` module. Each function
takes a `rootvertex`, accessor functions, and options; returns a `TreeGeometry`
value (immutable struct). No Makie dependency in this module.

Three layout geometries for Tier 1:

- **Rectangular**: leaves placed on the transverse axis at equal spacing
  (default) or user-specified `leaf_spacing`; process coordinate determined by
  the active `lineageunits` value; right-angle edge segments connect parent
  transverse position to child transverse position then along the primary axis
  to the child's process coordinate.

- **Circular**: leaves placed at equal angular spacing (default) on a circle;
  radial position determined by the active `lineageunits` value; edges are straight
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
sizes. No layer may assume `x_scale == y_scale`.

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
It is the principal interface between the three-view model and the Makie
rendering system.

**Attributes (Tier 1):**

- `axis_polarity` — `:forward` | `:backward`; inferred from active `lineageunits`
  value; overridable. Records the semantic direction of increasing process
  coordinates. Used by axis labeling and by `display_polarity` resolution.
- `display_polarity` — `:standard` | `:reversed`; default `:standard`. Controls
  whether increasing process coordinates map to increasing or decreasing screen
  position. Applied at axis setup time by adjusting axis limits. Independent of
  `axis_polarity`.
- `lineage_orientation` — `:left_to_right` | `:right_to_left` | `:radial`;
  default `:left_to_right` for rectangular layouts, `:radial` for circular.
  Controls which screen axis carries the process coordinate. Additional values
  (`:top_to_bottom`, `:bottom_to_top`) are Tier 2.
- `show_x_axis` — `Bool`; default `false`. Enables quantitative x-axis for
  `lineageunits` values with meaningful process coordinates.
- `show_y_axis` — `Bool`; default `false`.
- `show_grid` — `Bool`; default `false`.
- `title` — standard Makie attribute.
- `xlabel`, `ylabel` — standard Makie attributes.

**Viewport-aware coordinate infrastructure:**
- Wraps a `CoordTransform`-backed pixel↔data infrastructure so that all layers
  receive correct pixel-to-data mappings after resize.
- Implements `reset_limits!` and `autolimits!` using `TreeGeometry.boundingbox`.

**Dispatch:** `lineageplot!` dispatches on `Union{LineageAxis, Axis}` so both
work; `LineageAxis` provides tree-specific defaults and the polarity/orientation
semantics.

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

## Module design

### Module 1 — `Accessors`

**Responsibility:** Define the fundamental accessor protocol and provide the
AbstractTrees.jl adapter.

**Interface:**

- `TreeAccessor` struct: holds `children`, `edgelength`, `vertexvalue`,
  `branchingtime`, `coalescenceage`, `vertexcoords`, `vertexpos` callables (all
  except `children` optional, defaulting to `nothing`)
- `tree_accessor(rootvertex; children, edgelength=nothing, vertexvalue=nothing,
  branchingtime=nothing, coalescenceage=nothing, vertexcoords=nothing,
  vertexpos=nothing)`: constructs a `TreeAccessor` from explicit keyword
  functions; validates that `children` is callable
- `abstracttrees_accessor(rootvertex; edgelength=nothing, vertexvalue=nothing,
  branchingtime=nothing, coalescenceage=nothing)`: constructs a `TreeAccessor`
  by wrapping `AbstractTrees.children`; requires AbstractTrees.jl to be loaded
- Predicate utilities: `is_leaf(accessor, vertex) -> Bool`,
  `leaves(accessor, rootvertex) -> iterator`,
  `preorder(accessor, rootvertex) -> iterator`

**Failure modes:** `children` not callable → `ArgumentError` at construction;
cycle detected during traversal → `ArgumentError` before layout.

**Tested:** Yes

### Module 2 — `Geometry`

**Responsibility:** Compute 2D layout coordinates (process coordinates and
transverse positions) from tree topology and the active `lineageunits` value. Pure
functional; no Makie dependency. Embodies the tree-centric view only: produces
process-coordinate values in their natural direction without any
screen-direction transformation.

**Interface:**

- `TreeGeometry` struct (immutable): `vertex_positions::Dict`,
  `edge_paths`, `leaf_order`, `boundingbox`
- `rectangular_layout(rootvertex, accessor; leaf_spacing=:equal,
  lineageunits=:vertexheights) -> TreeGeometry`
- `circular_layout(rootvertex, accessor; leaf_spacing=:equal,
  lineageunits=:vertexheights) -> TreeGeometry`
- `boundingbox(geom::TreeGeometry) -> Rect2f`

`lineageunits` values implemented: all eight listed in the `lineageunits`
section. Forward and backward `lineageunits` values produce `vertex_positions`
whose primary
axis values reflect the natural process-coordinate direction. Screen direction
is applied later by `LineageAxis` via `display_polarity`.

**Failure modes:** negative edge length → `ArgumentError` with offending edge
identified; zero-leaf tree → `ArgumentError`; missing edge length in
`lineageunits = :edgelengths` → warning + unit-length fallback for that edge;
non-ultrametric tree with `lineageunits = :coalescenceage` → `ArgumentError` by default,
controlled by `nonultrametric` keyword (`:error` | `:minimum` | `:maximum`).

**Tested:** Yes

### Module 3 — `CoordTransform`

**Responsibility:** Provide correct, tested, Observable-aware utilities for
converting between data coordinates and pixel coordinates for non-isotropic
axes. Embodies the plotting-centric view without any knowledge of process
coordinate semantics.

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

### Module 5 — `LineageAxis`

**Responsibility:** Custom Makie `Block` that joins the three-view model to
the Makie rendering system. Provides tree-specific axis defaults, viewport-
managed pixel↔data coordinate infrastructure, and the polarity/orientation
attributes that map tree-centric process coordinates to screen positions.

**Interface:**

- `LineageAxis(figure_position; kwargs...)`: standard Block constructor
- Attributes: `axis_polarity`, `display_polarity`, `lineage_orientation`,
  `show_x_axis` (default `false`), `show_y_axis` (default `false`),
  `show_grid` (default `false`), `title`, `xlabel`, `ylabel`
- `reset_limits!(ax::LineageAxis)`: fits axis to tree `boundingbox`, accounting
  for `display_polarity` when setting axis limits
- `autolimits!(ax::LineageAxis)`: equivalent to `reset_limits!`

`display_polarity` is applied by `reset_limits!` / `autolimits!`: when
`:reversed`, axis limits are set with max value at left (or bottom) and min at
right (or top), letting Makie's native axis direction handle the visual flip.
This ensures all downstream layers receive correct data-space coordinates with
no per-layer special-casing.

`lineageplot!` dispatches on `Union{LineageAxis, Axis}` so both work;
`LineageAxis` provides tree-specific defaults and the three-view attributes.

**Tested:** Yes (including visual smoke test via CairoMakie, with tests
covering each combination of `axis_polarity` and `display_polarity`)

## Testing decisions

### What constitutes a good test

Tests exercise the documented public contract, not implementation internals.
A test for `rectangular_layout` checks that all vertices have positions, leaves
are at the expected process coordinate for the active `lineageunits` value, transverse positions
are evenly spaced when `leaf_spacing = :equal`, and the `boundingbox` contains
all positions — not that a specific private variable holds a given value.

Tests are deterministic. No wall-clock time, no external network. Tree fixtures
are constructed inline using simple topologies: 4-leaf balanced, 6-leaf
unbalanced, polytomy, single-leaf.

Tests for `LineageAxis` cover: default attribute values; correct axis limit
direction for each `display_polarity`; correct screen direction for each
`lineage_orientation`; pixel↔data correctness after resize.

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

## Out of scope

The following are explicitly deferred to later tiers:

- **Graphs.jl adapter** — Tier 2
- **PhyloNetworks.jl adapter**, hybrid/reticulation vertices and edges — Tier 3
- **Fan layout**, slanted layout, unrooted layouts (equal-angle, daylight) — Tier 2
- **Dendrogram orientation** (`:top_to_bottom`, `:bottom_to_top` for
  `lineage_orientation`) — Tier 2; the architecture supports it, but the
  coordinate transform infrastructure for vertical layout is deferred
- **Clade collapse** (triangle glyph), clade zoom/inset — Tier 2
- **Continuous color/width gradient along edges** — Tier 2
- **Aligned heatmap panel**, tanglegram layout — Tier 2
- **Vertex pie/bar chart insets**, MSA panel, faceted data panel — Tier 4
- **Tree density overlay** — Tier 4
- **Interval schemas and geological time scale** — Tier 4
- **3D lineage embeddings** (tubes, morphospace, trait space) — Tier 4
- **Geographic tip coordinate constraints** — Tier 3
- **Interactive features** (tooltip, click-to-collapse, lazy expand) — Tier 4
- **External data join operator** (no bespoke operators; users join data to
  the tree before calling `lineageplot`)
- **File I/O** (Newick, Nexus parsing) — not in scope for this package
- **Layout transformation operations** (flip, rotate, ladderise) — Tier 2

The architecture must not foreclose any of the above. In particular:
- The accessor-first input design already supports higher-dimensional
  coordinates via `vertexcoords` / `vertexpos`.
- The `axis_polarity` / `display_polarity` / `lineage_orientation` separation
  in `LineageAxis` must not be short-circuited to support Tier 1 layouts; the
  clean separation is required so Tier 2+ additions (dendrogram, fan, unrooted)
  work without architectural changes.
- `interval_schema` is reserved in the controlled vocabulary; no other term
  should be used for named axis bins in any tier.

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

4. **`display_polarity` and `reset_limits!` interaction:** When
   `display_polarity = :reversed`, `reset_limits!` must set axis limits so
   that the larger process-coordinate value is at the visual origin. The exact
   Makie idiom for this (reversed limits, or `xreversed = true`) must be
   confirmed against the Makie 0.24+ Block API before implementation.
   *Owner:* `LineageAxis` implementation. *Resolution:* check Makie Block docs
   and `Axis` `xreversed` attribute behavior.

5. **`lineage_orientation` and transverse axis for Tier 1:** For Tier 1 only
   `:left_to_right` and `:radial` are required. The `:right_to_left` value is
   achievable via `display_polarity = :reversed` with `:left_to_right`
   orientation, so it may be redundant in Tier 1. Confirm whether
   `lineage_orientation = :right_to_left` is needed as a distinct value in Tier
   1 or whether `display_polarity = :reversed` is sufficient.
   *Owner:* `LineageAxis` implementation.

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

`.workflow-docs/00-design/target-reference-capacities.md` is the comprehensive
vision document describing the desired capability space, feature vocabulary,
and tier classifications. It also contains the full authoritative description
of `LineageAxis` as a semantic axis abstraction in section 0. All API decisions
are derived from first principles per STYLE-julia.md, the controlled
vocabulary, and current Makie best practices; the target reference capacities
document is the functional reference, not the API specification.
