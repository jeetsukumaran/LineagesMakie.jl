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

plot_result = lineageplot(basenode, accessor; axis = (; title = "Lineage plot"))
fig, ax, lp = plot_result
```

Use `lineageplot!(...)` when you already own the plotting context, such as an
existing `Axis`, `LineageAxis`, or multi-panel `Figure`.

Current `LineageAxis` orientation support includes `:left_to_right`,
`:right_to_left`, `:bottom_to_top`, `:top_to_bottom`, and `:radial`.
Vertical rectangular embeddings are supported end to end for tree geometry and
shared annotations.

Screen-axis controls are live: `show_x_axis` and `xlabel` govern the screen
x-axis, `show_y_axis` and `ylabel` govern the screen y-axis, and `show_grid`
draws grid lines for whichever screen axes are visible. In vertical
rectangular embeddings, the lineage process coordinate lives on the screen
y-axis.

```@index
```

```@autodocs
Modules = [LineagesMakie, LineagesMakie.Accessors, LineagesMakie.Geometry, LineagesMakie.CoordinateTransform, LineagesMakie.Layers]
```
