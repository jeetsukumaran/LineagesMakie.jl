```@meta
CurrentModule = LineagesMakie
```

# LineagesMakie

Documentation for [LineagesMakie](https://github.com/jeetsukumaran/LineagesMakie.jl).

## Quick start

Use the non-mutating `lineageplot(...)` entry point for simple one-plot,
immediate-display workflows:

```julia
using CairoMakie
using LineagesMakie

plot_result = lineageplot(rootvertex, accessor; axis = (; title = "Lineage plot"))
fig, ax, lp = plot_result
```

Use `lineageplot!(...)` when you already own the plotting context, such as an
existing `Axis`, `LineageAxis`, or multi-panel `Figure`.

Current `LineageAxis` orientation support includes `:left_to_right`,
`:right_to_left`, `:bottom_to_top`, `:top_to_bottom`, and `:radial`.
Vertical rectangular embeddings are supported end to end for tree geometry and
shared annotations.

The current panel-decoration surface is intentionally narrower: `show_y_axis`,
`show_grid`, and `ylabel` remain reserved and are not rendered yet.

```@index
```

```@autodocs
Modules = [LineagesMakie, LineagesMakie.Accessors, LineagesMakie.Geometry, LineagesMakie.CoordTransform, LineagesMakie.Layers]
```
