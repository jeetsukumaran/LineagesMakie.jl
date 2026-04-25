# LineagesMakie

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jeetsukumaran.github.io/LineagesMakie.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jeetsukumaran.github.io/LineagesMakie.jl/dev/)
[![Build Status](https://github.com/jeetsukumaran/LineagesMakie.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jeetsukumaran/LineagesMakie.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

LineagesMakie.jl provides Makie-native plotting for lineage graphs in Julia.
It accepts ordinary Julia objects through a small accessor interface, or any
object that implements the AbstractTrees.jl `children` interface. It does not
require a package-specific tree type, an R bridge, or a web service.

Use LineagesMakie.jl when you want to draw rooted branching structures with
Makie composition: clade graph layouts, edgelength-proportional layouts,
radial layouts, labels, clade annotations, scale bars, `LineageAxis`
decorations, and Observable-backed updates.

Full reference documentation lives in the [stable docs](https://jeetsukumaran.github.io/LineagesMakie.jl/stable/)
and [development docs](https://jeetsukumaran.github.io/LineagesMakie.jl/dev/).
This README is a self-contained quick start and recipe guide.

## Installation

### General registry

After registration in the Julia General registry, the standard installation
command will be:

```julia
using Pkg
Pkg.add("LineagesMakie")
```

LineagesMakie.jl is not registered yet. Use the GitHub development version for
now.

### GitHub development version

```julia
using Pkg
Pkg.add(url = "https://github.com/jeetsukumaran/LineagesMakie.jl")
```

For local development from a checkout, activate this repository or the
`examples` project:

```julia
using Pkg
Pkg.develop(path = ".")
```

## Quick start

The only required input is a rootnode and a callable `children(node)` accessor.
When no `edgelength` accessor is supplied, LineagesMakie.jl defaults to
`lineageunits = :nodeheights`, which gives a leaf-aligned clade graph layout.

The following example is available as
[`examples/readme_quickstart.jl`](examples/readme_quickstart.jl).

```julia
using CairoMakie
using LineagesMakie

struct Node
    name::String
    edgelength::Float64
    children::Vector{Node}
end

leaf(name, edgelength) = Node(name, edgelength, Node[])
node(name, edgelength, children::Node...) = Node(name, edgelength, Node[children...])

rootnode = node(
    "rootnode",
    0.0,
    node("alpha", 0.0, leaf("alpha_1", 0.0), leaf("alpha_2", 0.0)),
    node("beta", 0.0, leaf("beta_1", 0.0), leaf("beta_2", 0.0)),
)

accessor = lineagegraph_accessor(rootnode; children = node -> node.children)

plot_result = lineageplot(
    rootnode,
    accessor;
    figure = (; size = (640, 360)),
    axis = (; title = "Default clade graph layout"),
    leaf_label_func = node -> node.name,
    node_color = :white,
    node_strokecolor = :gray35,
    leaf_color = :gray10,
    edge_color = :gray35,
)

fig, lax, lp = plot_result
save("readme_quickstart.png", fig)
```

![Default clade graph layout](examples/readme_quickstart.png)

## Edgelengths and annotations

Add an `edgelength(src, dst)` accessor when horizontal distance should reflect
process-coordinate distance. The example below also shows leaf labels, clade
highlighting, a clade bracket label, a quantitative x-axis, and a scale bar.

The full script is available as
[`examples/readme_features.jl`](examples/readme_features.jl).

```julia
using CairoMakie
using LineagesMakie

struct Node
    name::String
    edgelength::Float64
    children::Vector{Node}
end

leaf(name, edgelength) = Node(name, edgelength, Node[])
node(name, edgelength, children::Node...) = Node(name, edgelength, Node[children...])

alpha = node(
    "alpha",
    1.0,
    leaf("alpha_1", 1.5),
    node("alpha_2", 0.8, leaf("alpha_2a", 0.7), leaf("alpha_2b", 0.7)),
)
beta = node("beta", 0.9, leaf("beta_1", 1.4), leaf("beta_2", 1.2))
rootnode = node("rootnode", 0.0, alpha, beta)

accessor = lineagegraph_accessor(
    rootnode;
    children = node -> node.children,
    edgelength = (src, dst) -> dst.edgelength,
    nodevalue = node -> node.name,
)

plot_result = lineageplot(
    rootnode,
    accessor;
    lineageunits = :edgelengths,
    figure = (; size = (760, 420)),
    axis = (;
        title = "Edgelengths, labels, clade annotation, and scale bar",
        show_x_axis = true,
        xlabel = "cumulative edgelength",
    ),
    edge_color = :slategray,
    edge_linewidth = 1.6,
    node_color = :white,
    node_strokecolor = :slategray,
    leaf_color = :black,
    leaf_label_func = node -> node.name,
    clade_nodes = [alpha],
    clade_label_func = node -> node.name,
    clade_highlight_color = (:lightskyblue, 0.25),
    scalebar_label = "1 unit",
    scalebar_auto_visible = true,
)

fig, lax, lp = plot_result
save("readme_features.png", fig)
```

![Edgelengths, labels, clade annotation, and scale bar](examples/readme_features.png)

## Input contract

LineagesMakie.jl uses `LineageGraphAccessor` as its input boundary. The
accessor stores callables that describe how to traverse and query your
lineage graph.

| Accessor | Required | Meaning |
|---|---:|---|
| `children(node)` | Yes | Return zero or more child nodes. A node with no children is a leaf. |
| `edgelength(src, dst)` | No | Return the edgelength from source node `src` to destination node `dst`. |
| `nodevalue(node)` | No | Return per-node data used by labels or mappings. |
| `branchingtime(node)` | No | Return a precomputed rootnode-relative process coordinate. |
| `coalescenceage(node)` | No | Return a precomputed leaf-relative process coordinate. |
| `nodecoordinates(node)` | No | Return a user-supplied data-space `Point2f`. |
| `nodepos(node)` | No | Return a user-supplied pixel-space `Point2f`. |

Create an accessor from explicit callables:

```julia
accessor = lineagegraph_accessor(
    rootnode;
    children = node -> node.children,
    edgelength = (src, dst) -> dst.edgelength,
    nodevalue = node -> node.name,
)
```

Use `abstracttrees_accessor` when your node type implements
`AbstractTrees.children`:

```julia
using AbstractTrees
using LineagesMakie

AbstractTrees.children(node::Node) = node.children

accessor = abstracttrees_accessor(
    rootnode;
    edgelength = (src, dst) -> dst.edgelength,
    nodevalue = node -> node.name,
)
```

AbstractTrees.jl defines a fallback `children` method that returns `()` for
ordinary objects. If your type has no explicit `AbstractTrees.children` method,
`abstracttrees_accessor` treats the value as a single-leaf lineage graph.

## Plotting entry points

Use `lineageplot` when you want LineagesMakie.jl to create the `Figure` and
`LineageAxis`:

```julia
plot_result = lineageplot(rootnode, accessor; axis = (; title = "Lineage plot"))
fig, lax, lp = plot_result
```

Use `lineageplot!` when you already own the plotting context:

```julia
fig = Figure()
lax = LineageAxis(fig[1, 1]; show_x_axis = true, xlabel = "edgelength")
lp = lineageplot!(lax, rootnode, accessor; lineageunits = :edgelengths)
```

You can also target a standard Makie `Axis` when you do not need
`LineageAxis` decorations:

```julia
fig = Figure()
ax = Axis(fig[1, 1])
lp = lineageplot!(ax, rootnode, accessor; leaf_label_func = node -> node.name)
```

The returned `lp` is a Makie plot object. Its derived attributes include:

```julia
geom = lp[:computed_geom][]
lineageunits = lp[:resolved_lineageunits][]
```

## Lineageunits

`lineageunits` selects how LineagesMakie.jl computes the process coordinate of
each node. If `lineageunits` is omitted, the default is `:edgelengths` when an
`edgelength` accessor exists, and `:nodeheights` otherwise.

| `lineageunits` | Required accessor | Process coordinate | Axis polarity |
|---|---|---|---|
| `:edgelengths` | `edgelength` | Cumulative `edgelength(src, dst)` from `rootnode`. | `:forward` |
| `:branchingtime` | `branchingtime` | Precomputed rootnode-relative coordinate. | `:forward` |
| `:coalescenceage` | `coalescenceage` | Leaf-relative coordinate; leaves have value 0. | `:backward` |
| `:nodedepths` | None | Edge count from `rootnode`. | `:forward` |
| `:nodeheights` | None | Edge count to farthest descendant leaf; leaves have value 0. | `:backward` |
| `:nodelevels` | None | Integer level from `rootnode`. | `:forward` |
| `:nodecoordinates` | `nodecoordinates` | User-supplied data coordinates. | User-defined |
| `:nodepos` | `nodepos` | User-supplied pixel coordinates. | User-defined |

Use the layout functions directly when you need geometry before plotting:

```julia
geom = rectangular_layout(rootnode, accessor; lineageunits = :edgelengths)
bb = boundingbox(geom)
leaf_order = geom.leaf_order
node_positions = geom.node_positions
```

## Orientation and polarity

The plotting contract has 4 related pieces:

- `lineageunits` chooses the process coordinate for each node.
- `axis_polarity` records whether the coordinate increases in the
  rootnode-to-leaf direction or the leaf-to-root direction.
- `display_polarity` controls whether increasing coordinates map to increasing
  screen position.
- `lineage_orientation` chooses which screen axis carries the process
  coordinate.

Supported `lineage_orientation` values are `:left_to_right`,
`:right_to_left`, `:bottom_to_top`, `:top_to_bottom`, and `:radial`.

```julia
fig = Figure()
lax = LineageAxis(
    fig[1, 1];
    lineage_orientation = :top_to_bottom,
    show_y_axis = true,
    show_grid = true,
    ylabel = "cumulative edgelength",
)
lineageplot!(lax, rootnode, accessor; lineageunits = :edgelengths)
```

Use `display_polarity = :reversed` when the same process coordinates should
run in the opposite screen direction:

```julia
lax = LineageAxis(fig[1, 1]; display_polarity = :reversed)
lineageplot!(lax, rootnode, accessor; lineageunits = :edgelengths)
```

Use `:radial` for circular layouts:

```julia
plot_result = lineageplot(
    rootnode,
    accessor;
    axis = (; lineage_orientation = :radial, title = "Radial layout"),
    lineage_orientation = :radial,
    lineageunits = :edgelengths,
    leaf_label_func = node -> node.name,
)
```

## Styling and layers

The composite `LineagePlot` recipe forwards namespaced keyword arguments to
its layers.

| Layer | Common keywords |
|---|---|
| Edges | `edge_color`, `edge_linewidth`, `edge_linestyle`, `edge_alpha`, `edge_visible`. |
| Internal nodes | `node_marker`, `node_color`, `node_markersize`, `node_strokecolor`, `node_visible`. |
| Leaves | `leaf_marker`, `leaf_color`, `leaf_markersize`, `leaf_strokecolor`, `leaf_visible`. |
| Leaf labels | `leaf_label_func`, `leaf_label_fontsize`, `leaf_label_color`, `leaf_label_italic`, `leaf_label_visible`. |
| Node labels | `node_label_func`, `node_label_threshold`, `node_label_position`, `node_label_fontsize`. |
| Clade highlights | `clade_nodes`, `clade_highlight_color`, `clade_highlight_alpha`, `clade_highlight_padding`. |
| Clade labels | `clade_nodes`, `clade_label_func`, `clade_label_color`, `clade_label_fontsize`, `clade_label_side`. |
| Scale bars | `scalebar_label`, `scalebar_length`, `scalebar_position`, `scalebar_auto_visible`. |

`edge_color` may be a uniform color or a function of `(src, dst)`:

```julia
lineageplot!(
    lax,
    rootnode,
    accessor;
    edge_color = (src, dst) -> dst.edgelength > 1.0 ? :tomato : :gray50,
    leaf_label_func = node -> node.name,
)
```

Node labels are opt-in. Enable them with `node_label_threshold`:

```julia
lineageplot!(
    lax,
    rootnode,
    accessor;
    node_label_func = node -> node.name,
    node_label_threshold = node -> !isempty(node.children),
    node_label_position = :toward_parent,
)
```

## Manual layer composition

Use lower-level layout and layer recipes when you want to compose the plot
yourself.

```julia
geom = rectangular_layout(rootnode, accessor; lineageunits = :edgelengths)

fig = Figure()
ax = Axis(fig[1, 1])
hidedecorations!(ax)
hidespines!(ax)

edgelayer!(ax, geom; color = :gray40, linewidth = 1.5)
nodelayer!(ax, geom, accessor; color = :white, strokecolor = :gray40)
leaflayer!(ax, geom, accessor; color = :black)
leaflabellayer!(ax, geom, accessor; text_func = node -> node.name)
```

Manual layer composition uses public layer functions. Prefer `lineageplot` or
`lineageplot!` unless you need direct layer control.

## Observable updates

`rootnode` and plot attributes can be Observables. This follows standard Makie
reactivity.

```julia
rootnode_observable = Observable(rootnode)

plot_result = lineageplot(
    rootnode_observable,
    accessor;
    lineageunits = :edgelengths,
    leaf_label_func = node -> node.name,
)

fig, lax, lp = plot_result

lp.edge_color = :steelblue
rootnode_observable[] = another_rootnode
```

Use the same accessor contract for every rootnode value assigned to the
Observable.

## Examples

The `examples` project contains runnable scripts:

- [`examples/readme_quickstart.jl`](examples/readme_quickstart.jl) generates the first README image.
- [`examples/readme_features.jl`](examples/readme_features.jl) generates the annotated README image.
- [`examples/lineageplot_ex1.jl`](examples/lineageplot_ex1.jl) is a compact starter example.
- [`examples/lineageplot_ex2.jl`](examples/lineageplot_ex2.jl) is a denser multi-panel feature smoke example.

Run an example from the repository root:

```sh
julia --project=examples examples/readme_quickstart.jl
```

## Development checks

The package uses separate projects for tests, examples, and documentation.

```sh
julia --project=test test/runtests.jl
julia --project=examples examples/readme_quickstart.jl
julia --project=examples examples/readme_features.jl
julia --project=docs docs/make.jl
```

## Planned capacities

See [`ROADMAP.md`](ROADMAP.md) for planned capacities. The roadmap separates
future work from the current public API.

## License

LineagesMakie.jl is distributed under the license in [`LICENSE.md`](LICENSE.md).
