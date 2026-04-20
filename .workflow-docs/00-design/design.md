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
phylogenetic tree in a Makie figure. No internet access, no R installation, no
package-specific conversion, and no constraint on the Makie backend (CairoMakie,
GLMakie, WGLMakie) are required.

## Conceptual architecture

Three perspectives on the same tree object must be cleanly separated throughout
the design.

### Tree-centric view

The tree-centric view concerns the combinatorial and geometric structure of the
tree itself. It answers: which direction is root-to-leaf? What scalar is
attached to each vertex along its primary dimension? What branching structure
(clade graph) connects the vertices?

This view is captured by the **`lineageunits`** selection and **accessor callables**:
`edgelength`, `branchingtime`, `coalescenceage`, `children`. The resulting
`process_coordinate` values (see controlled vocabulary) determine the position
of each vertex along the lineage axis.

Two canonical process-coordinate types exist with opposite polarity:
- `branchingtime` — cumulative edge length from rootvertex; root = 0, increases
  toward leaves. The process moves forward from root to leaf.
- `coalescenceage` — cumulative edge length from vertex to leaf; leaf = 0,
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

The plotting-centric view concerns how the tree appears on screen. It answers:
which physical screen axis carries the process coordinate (`lineage_orientation`)?
Does increasing process-coordinate value map to rightward or leftward on screen
(`display_polarity`)? Are tick marks shown? What is the axis label?

This view is governed by `LineageAxis` attributes and is **independent of the
tree-centric and user-centric views**. A researcher may have a forward-time
tree but prefer a root-at-right layout (common in paleontology). A coalescent
tree with leaf-relative process coordinates can be displayed either way.

The separation of these three views is a design invariant. No module may assume
that any one view implies another.

## Input contract

All input routes pass through a common set of callable keyword arguments
(`children`, `edgelength`, `vertexvalue`, `branchingtime`, `coalescenceage`,
`vertexcoords`, `vertexpos`). Adapters (AbstractTrees.jl, future Graphs.jl,
etc.) are thin shims that translate their source objects into these callables.
The geometry and rendering modules depend only on the callables, never on the
source type.

This is dependency inversion applied at the input boundary: the package's core
does not depend on any external tree type.

## Minimum working examples

### Clade graph layout (default)

When no edge-length data is available, the default `lineageunits`
(`:vertexheights`) produces a **clade graph layout** — the tree rendered as a
graph up to label-preserving isomorphism (the phylogenetic "topology"), with all
leaves at x = 0 and internal vertices spaced by path distance (unweighted path
distance from root; number of edges). This requires only a `children` function.

```julia
using LineagesMakie, CairoMakie

# Any tree-like struct with a children field
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
    children = v -> v.children,
)
save("cladegraph.pdf", fig)
```

### Edge-length proportional layout

Supply `edgelength` and the default `lineageunits` shifts to `:edgelengths`,
placing vertices at x = cumulative edge length from the rootvertex
(`branchingtime`).

```julia
struct PhyloNode
    name::String
    children::Vector{PhyloNode}
    branch_length::Float64
end

fig, ax, plt = lineageplot(
    root;
    children       = v -> v.children,
    edgelength     = (u, v) -> v.branch_length,
    vertexvalue    = v -> v.name,
)
```

The resulting layout places each vertex at its cumulative branch length from the
root. The `vertexvalue` accessor drives the `LeafLabelLayer` text by default.

### Pre-computed branching times

When the user has a dictionary of divergence times (e.g. from a Bayesian dating
analysis) and does not want to re-derive them from per-edge lengths, supply
`branchingtime` directly and set `lineageunits = :branchingtime`.

```julia
divergence_times = Dict(node_id => time_ma for ...)   # millions of years

fig, ax, plt = lineageplot(
    root;
    children       = v -> v.children,
    branchingtime  = v -> divergence_times[v.id],
    lineageunits   = :branchingtime,
)
```

The resulting x-coordinates are read directly from `divergence_times` with no
per-edge summation.

### Coalescent tree (backward time)

A coalescent tree has process coordinates measured from the leaves backward
to the root. Supply `coalescenceage` and set `lineageunits = :coalescenceage`.
The tree must be ultrametric (all root-to-leaf path lengths equal) or a
`nonultrametric` policy must be specified.

```julia
# Ultrametric coalescent tree
fig, ax, plt = lineageplot(
    root;
    children       = v -> v.children,
    coalescenceage = v -> v.coalescent_age,   # leaf = 0, root = maximum
    lineageunits   = :coalescenceage,
)

# Non-ultrametric with fallback policy
fig, ax, plt = lineageplot(
    root;
    children          = v -> v.children,
    coalescenceage    = v -> v.coalescent_age,
    lineageunits      = :coalescenceage,
    nonultrametric    = :maximum,             # use max over leaf paths
)
```

In the default `LineageAxis` configuration (`:left_to_right` orientation,
`:standard` display polarity), leaves appear at x = 0 on the left and the
rootvertex appears at the right. This matches the standard coalescent tree
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
    tree_root;
    edgelength  = (u, v) -> AbstractTrees.nodevalue(v).brlen,
    vertexvalue = v -> AbstractTrees.nodevalue(v).name,
)
```

### Polarity and orientation control via LineageAxis

The three-view model is fully expressed through `LineageAxis` attributes. The
tree-centric polarity (which `lineageunits` was chosen) is inferred automatically,
but the screen polarity and orientation are independently controllable.

```julia
using GLMakie

fig = Figure()

# Forward-time tree, displayed left-to-right (standard)
ax1 = LineageAxis(fig[1, 1];
    lineage_orientation = :left_to_right,
    display_polarity    = :standard,
    show_x_axis         = true,
    xlabel              = "Divergence time (Ma)",
)
lineageplot!(ax1, root; edgelength = (u, v) -> v.branch_length)

# Same tree, displayed right-to-left (paleontological convention: root at right)
ax2 = LineageAxis(fig[1, 2];
    lineage_orientation = :left_to_right,
    display_polarity    = :reversed,
    show_x_axis         = true,
    xlabel              = "Time before present (Ma)",
)
lineageplot!(ax2, root; edgelength = (u, v) -> v.branch_length)

# Coalescent tree: axis_polarity = :backward; leaves appear at left by default
ax3 = LineageAxis(fig[2, 1];
    lineage_orientation = :left_to_right,
    show_x_axis         = true,
    xlabel              = "Coalescence age",
)
lineageplot!(ax3, root;
    coalescenceage = v -> v.coal_age,
    lineageunits   = :coalescenceage,
)

# Coalescent tree, displayed reversed: root at left, leaves at right
# (non-standard but user-requested)
ax4 = LineageAxis(fig[2, 2];
    lineage_orientation = :left_to_right,
    display_polarity    = :reversed,
    show_x_axis         = true,
)
lineageplot!(ax4, root;
    coalescenceage = v -> v.coal_age,
    lineageunits   = :coalescenceage,
)

fig
```

### Dendrogram orientation

The `lineage_orientation` attribute controls which screen axis carries the
process coordinate. A dendrogram places the rootvertex at the top with leaves
descending:

```julia
fig = Figure()
ax = LineageAxis(fig[1, 1];
    lineage_orientation = :top_to_bottom,
    show_y_axis         = true,
)
lineageplot!(ax, root; children = v -> v.children)
```

### Manual layer composition

Each visual layer is independently composable. The composite `lineageplot!`
is convenient but not required; layers can be combined à la carte.

```julia
using CairoMakie

# Compute geometry once; reuse across layers
geom = rectangular_layout(
    root;
    children   = v -> v.children,
    edgelength   = (u, v) -> v.branch_length,
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
    text_func = v -> v.name,
    italic    = true,
    offset    = 4.0,
)
vertexlabellayer!(ax, geom;
    value_func = v -> v.bootstrap,
    threshold  = x -> x >= 70,
    position   = :toward_parent,
)
cladehighlightlayer!(ax, geom;
    clade_vertices = [mrca_node],
    color          = (:tomato, 0.2),
    padding        = 0.05,
)
cladelabellayer!(ax, geom;
    clade_vertices = [mrca_node],
    label_func     = v -> "Clade A",
    offset         = 0.1,
)
scalebarlayer!(ax, geom;
    length   = 10.0,
    label    = "10 Ma",
    position = :bottom_right,
)

fig
```

### Per-element aesthetic mapping

Any attribute that varies per-edge or per-vertex accepts a callable as well as
a scalar. The callable is applied element-wise at render time and participates
in Observable reactivity.

```julia
# Edges colored by evolutionary rate; width by bootstrap support
lineageplot!(ax, root;
    edgelength    = (u, v) -> v.branch_length,
    vertexvalue   = v -> v.bootstrap,
    edge_color    = (u, v) -> rate_colormap(v.rate),
    edge_linewidth = (u, v) -> v.support_weight,
    vertex_color  = v -> support_colormap(v.bootstrap),
    vertex_marker_size = v -> clamp(v.bootstrap / 10.0, 2.0, 12.0),
)
```

### Observable-reactive interactive plot

All recipe attributes are Observable-native. Wrapping the tree in an
`Observable` enables full reactive re-layout and re-render via standard Makie
idioms.

```julia
using GLMakie

tree_obs    = Observable(initial_tree)
scale_obs   = Observable(1.0)
highlight_obs = Observable(Set{Any}())

fig = Figure()
ax  = LineageAxis(fig[1, 1]; show_x_axis = true)

lineageplot!(ax, tree_obs;
    edgelength = (u, v) -> v.branch_length,
    edge_color = lift(highlight_obs) do hs
        (u, v) -> v ∈ hs ? :red : :gray40
    end,
)

# Slider controls display scale
slider = Slider(fig[2, 1], range = 0.5:0.1:3.0)
connect!(scale_obs, slider.value)

# Mouse click toggles highlight
on(events(fig).mouseclick) do event
    v = pick_vertex(ax, event)
    v === nothing && return
    s = copy(highlight_obs[])
    v ∈ s ? delete!(s, v) : push!(s, v)
    highlight_obs[] = s
end

# Swapping the tree triggers full re-layout
on(button_next.clicks) do _
    tree_obs[] = load_next_tree()
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
    edgelength = (u, v) -> v.branch_length,
    vertexvalue = v -> v.name,
)
```

For circular layouts the `LineageAxis` defaults to `lineage_orientation = :radial`
and the radial axis carries the process coordinate.
