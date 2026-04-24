---
date-created: 2026-04-18T16:00:00
date-revised: 2026-04-19T00:00:00
---

# Design

## Purpose

LineagesMakie.jl is a general framework for visualization of evolutionary
(phylogenetic, coalescent, cladistic, ancestral) graphs and associated
biological data in the Makie ecosystem.

The package accepts any Julia value that exposes a `children` function — or any
object satisfying the AbstractTrees.jl interface — and renders it as a
lineage graph in a Makie figure. No internet access, no R installation, no
package-specific conversion, and no constraint on the Makie backend (CairoMakie,
GLMakie, WGLMakie) are required.

## Conceptual architecture

Three perspectives on the same lineage graph must be cleanly separated throughout
the design.

### Lineage graph-centric view

The lineage graph-centric view concerns the combinatorial and geometric structure
of the lineage graph itself. It answers: which direction is root-to-leaf? What
scalar is attached to each node along its primary dimension? What branching
structure (clade graph) connects the nodes?

This view is captured by the **`lineageunits`** selection and **accessor callables**:
`edgelength`, `branchingtime`, `coalescenceage`, `children`. The resulting
`process_coordinate` values (see controlled vocabulary) determine the position
of each node along the lineage axis.

Two canonical process-coordinate types exist with opposite polarity:
- `branchingtime` — cumulative edge length from rootnode; root = 0, increases
  toward leaves. The process moves forward from root to leaf.
- `coalescenceage` — cumulative edge length from node to leaf; leaf = 0,
  increases toward root. The process moves backward from leaf to root
  (coalescent model). Requires an ultrametric tree.

### User-centric view

The user-centric view concerns the semantic interpretation of the process. Is
the researcher thinking in forward evolutionary time (diversification) or
backward coalescent time (coalescence)? Is the axis measured in substitutions,
millions of years, or event ranks? Is a larger value "more recent" or "more
ancient"?

The package makes no assumption about semantic interpretation. The `axis_polarity`
attribute in `LineageAxis` records which direction increasing process-coordinate
values point; its value is inferred from the active `lineageunits`. No further
biological meaning is imposed.

### Plotting-centric view

The plotting-centric view concerns how the lineage graph appears on screen. It
answers: which physical screen axis carries the process coordinate
(`lineage_orientation`)? Does increasing process-coordinate value map to
rightward or leftward on screen (`display_polarity`)? Are tick marks shown?
What is the axis label?

This view is governed by `LineageAxis` attributes and is **independent of the
lineage graph-centric and user-centric views**. A researcher may have a
forward-time lineage graph but prefer a root-at-right layout (common in
paleontology). A coalescent lineage graph with leaf-relative process coordinates
can be displayed either way.

The separation of these three views is a design invariant. No module may assume
that any one view implies another.

## Input contract

All input routes pass through a common set of callable keyword arguments
(`children`, `edgelength`, `nodevalue`, `branchingtime`, `coalescenceage`,
`nodecoords`, `nodepos`). Adapters (AbstractTrees.jl, future Graphs.jl,
etc.) are thin shims that translate their source objects into these callables.
The geometry and rendering modules depend only on the callables, never on the
source type.

This is dependency inversion applied at the input boundary: the package's core
does not depend on any external lineage graph type.

## Minimum working examples

### Clade graph layout (default)

When no edge-length data is available, the default `lineageunits`
(`:nodeheights`) produces a **clade graph layout** — the lineage graph
rendered as a graph up to label-preserving isomorphism (the phylogenetic
"topology"), with all
leaves at x = 0 and internal nodes spaced by path distance (unweighted path
distance from root; number of edges). This requires only a `children` function.

```julia
using LineagesMakie, CairoMakie

# Any struct with a children field
struct MyNode
    name::String
    children::Vector{MyNode}
end

root = MyNode("root", [
    MyNode("A", [MyNode("A1", []), MyNode("A2", [])]),
    MyNode("B", [MyNode("B1", []), MyNode("B2", [])]),
])

fig, ax, plt = lineageplot(
    root;
    children = node -> node.children,
)
save("cladegraph.pdf", fig)
```

### Edge-length proportional layout

Supply `edgelength` and the default `lineageunits` shifts to `:edgelengths`,
placing nodes at x = cumulative edge length from the rootnode
(`branchingtime`).

```julia
struct PhyloNode
    name::String
    children::Vector{PhyloNode}
    branch_length::Float64
end

fig, ax, plt = lineageplot(
    root;
    children   = node -> node.children,
    edgelength = (src, dst) -> dst.branch_length,
    nodevalue  = node -> node.name,
)
```

The resulting layout places each node at its cumulative branch length from the
root. The `nodevalue` accessor drives the `LeafLabelLayer` text by default.

### Pre-computed branching times

When the user has a dictionary of divergence times (e.g. from a Bayesian dating
analysis) and does not want to re-derive them from per-edge lengths, supply
`branchingtime` directly and set `lineageunits = :branchingtime`.

```julia
divergence_times = Dict(node_id => time_ma for ...)   # millions of years

fig, ax, plt = lineageplot(
    root;
    children       = node -> node.children,
    branchingtime  = node -> divergence_times[node.id],
    lineageunits   = :branchingtime,
)
```

The resulting x-coordinates are read directly from `divergence_times` with no
per-edge summation.

### Coalescent lineage graph (backward time)

A coalescent lineage graph has process coordinates measured from the leaves
backward to the root. Supply `coalescenceage` and set
`lineageunits = :coalescenceage`. The lineage graph must be ultrametric (all
root-to-leaf path lengths equal) or a `nonultrametric` policy must be specified.

```julia
# Ultrametric coalescent lineage graph
fig, ax, plt = lineageplot(
    root;
    children       = node -> node.children,
    coalescenceage = node -> node.coalescent_age,   # leaf = 0, root = maximum
    lineageunits   = :coalescenceage,
)

# Non-ultrametric with fallback policy
fig, ax, plt = lineageplot(
    root;
    children          = node -> node.children,
    coalescenceage    = node -> node.coalescent_age,
    lineageunits      = :coalescenceage,
    nonultrametric    = :maximum,             # use max over leaf paths
)
```

In the default `LineageAxis` configuration (`:left_to_right` orientation,
`:standard` display polarity), leaves appear at x = 0 on the left and the
rootnode appears at the right. This matches the standard coalescent tree
convention where the present is at the left and the past is at the right.

### AbstractTrees.jl input

Any object implementing the AbstractTrees.jl interface can be passed directly.
The package wraps `AbstractTrees.children` automatically.

```julia
using AbstractTrees

# Any AbstractTrees-compliant object — no conversion needed
struct NewickTree
    label::String
    branch_length::Float64
    children::Vector{NewickTree}
end
AbstractTrees.children(t::NewickTree) = t.children
AbstractTrees.nodevalue(t::NewickTree) = (name = t.label, brlen = t.branch_length)

fig, ax, plt = lineageplot(
    lineagegraph_root;
    edgelength = (src, dst) -> AbstractTrees.nodevalue(dst).brlen,
    nodevalue  = node -> AbstractTrees.nodevalue(node).name,
)
```

### Polarity and orientation control via LineageAxis

The three-view model is fully expressed through `LineageAxis` attributes. The
lineage graph-centric polarity (which `lineageunits` was chosen) is inferred
automatically,
but the screen polarity and orientation are independently controllable.

```julia
using GLMakie

fig = Figure()

# Forward-time lineage graph, displayed left-to-right (standard)
ax1 = LineageAxis(fig[1, 1];
    lineage_orientation = :left_to_right,
    display_polarity    = :standard,
    show_x_axis         = true,
    xlabel              = "Divergence time (Ma)",
)
lineageplot!(ax1, root; edgelength = (src, dst) -> dst.branch_length)

# Same lineage graph, displayed right-to-left (paleontological convention: root at right)
ax2 = LineageAxis(fig[1, 2];
    lineage_orientation = :left_to_right,
    display_polarity    = :reversed,
    show_x_axis         = true,
    xlabel              = "Time before present (Ma)",
)
lineageplot!(ax2, root; edgelength = (src, dst) -> dst.branch_length)

# Coalescent lineage graph: axis_polarity = :backward; leaves appear at left by default
ax3 = LineageAxis(fig[2, 1];
    lineage_orientation = :left_to_right,
    show_x_axis         = true,
    xlabel              = "Coalescence age",
)
lineageplot!(ax3, root;
    coalescenceage = node -> node.coal_age,
    lineageunits   = :coalescenceage,
)

# Coalescent lineage graph, displayed reversed: root at left, leaves at right
# (non-standard but user-requested)
ax4 = LineageAxis(fig[2, 2];
    lineage_orientation = :left_to_right,
    display_polarity    = :reversed,
    show_x_axis         = true,
)
lineageplot!(ax4, root;
    coalescenceage = node -> node.coal_age,
    lineageunits   = :coalescenceage,
)

fig
```

### Dendrogram orientation

The `lineage_orientation` attribute controls which screen axis carries the
process coordinate. A top-down dendrogram is a vertical rectangular embedding
that places the rootnode at the top with leaves descending:

```julia
fig = Figure()
ax = LineageAxis(fig[1, 1];
    lineage_orientation = :top_to_bottom,
    show_y_axis         = true,
    show_grid           = true,
    ylabel              = "Branch length",
)
lineageplot!(ax, root; children = node -> node.children)
```

`show_x_axis` and `xlabel` are screen x-axis controls. `show_y_axis` and
`ylabel` are screen y-axis controls. In vertical rectangular embeddings, the
lineage process coordinate lives on the screen y-axis, so `show_y_axis = true`
and `show_grid = true` provide a direct quantitative readout for the dendrogram
direction.

### Manual layer composition

Each visual layer is independently composable. The composite `lineageplot!`
is convenient but not required; layers can be combined à la carte.

```julia
using CairoMakie

# Compute geometry once; reuse across layers
geom = rectangular_layout(
    root;
    children     = node -> node.children,
    edgelength   = (src, dst) -> dst.branch_length,
    lineageunits = :edgelengths,
)

fig = Figure()
ax  = LineageAxis(fig[1, 1]; show_x_axis = true)

edgelayer!(ax, geom;
    color     = :gray40,
    linewidth = 1.5,
)
leaflayer!(ax, geom;
    color      = :steelblue,
    markersize = 6,
)
leaflabellayer!(ax, geom;
    text_func = node -> node.name,
    italic    = true,
    offset    = 4.0,
)
nodelabellayer!(ax, geom;
    value_func = node -> node.bootstrap,
    threshold  = x -> x >= 70,
    position   = :toward_parent,
)
cladehighlightlayer!(ax, geom;
    clade_nodes = [mrca_node],
    color       = (:tomato, 0.2),
    padding     = 0.05,
)
cladelabellayer!(ax, geom;
    clade_nodes = [mrca_node],
    label_func  = node -> "Clade A",
    offset      = 0.1,
)
scalebarlayer!(ax, geom;
    length   = 10.0,
    label    = "10 Ma",
    position = :bottom_right,
)

fig
```

### Per-element aesthetic mapping

Any attribute that varies per-edge or per-node accepts a callable as well as
a scalar. The callable is applied element-wise at render time and participates
in Observable reactivity.

```julia
# Edges colored by evolutionary rate; width by bootstrap support
lineageplot!(ax, root;
    edgelength         = (src, dst) -> dst.branch_length,
    nodevalue          = node -> node.bootstrap,
    edge_color         = (src, dst) -> rate_colormap(dst.rate),
    edge_linewidth     = (src, dst) -> dst.support_weight,
    node_color         = node -> support_colormap(node.bootstrap),
    node_markersize    = node -> clamp(node.bootstrap / 10.0, 2.0, 12.0),
)
```

### Observable-reactive interactive plot

All recipe attributes are Observable-native. Wrapping the tree in an
`Observable` enables full reactive re-layout and re-render via standard Makie
idioms.

```julia
using GLMakie

lineagegraph_obs = Observable(initial_lineagegraph)
scale_obs        = Observable(1.0)
highlight_obs    = Observable(Set{Any}())

fig = Figure()
ax  = LineageAxis(fig[1, 1]; show_x_axis = true)

lineageplot!(ax, lineagegraph_obs;
    edgelength = (src, dst) -> dst.branch_length,
    edge_color = lift(highlight_obs) do hs
        (src, dst) -> dst ∈ hs ? :red : :gray40
    end,
)

# Slider controls display scale
slider = Slider(fig[2, 1], range = 0.5:0.1:3.0)
connect!(scale_obs, slider.value)

# Mouse click toggles highlight
on(events(fig).mouseclick) do event
    node = pick_node(ax, event)
    node === nothing && return
    s = copy(highlight_obs[])
    node ∈ s ? delete!(s, node) : push!(s, node)
    highlight_obs[] = s
end

# Swapping the tree triggers full re-layout
on(button_next.clicks) do _
    lineagegraph_obs[] = load_next_lineagegraph()
end

fig
```

### Circular layout

The `layout` keyword selects the geometric embedding. All `lineageunits` values
work with all layout geometries.

```julia
fig, ax, plt = lineageplot(
    root;
    layout     = :circular,
    edgelength = (src, dst) -> dst.branch_length,
    nodevalue  = node -> node.name,
)
```

For circular layouts the `LineageAxis` defaults to `lineage_orientation = :radial`
and the radial axis carries the process coordinate.
