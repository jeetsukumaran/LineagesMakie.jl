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

```@index
```

```@autodocs
Modules = [LineagesMakie, LineagesMakie.Accessors, LineagesMakie.Geometry, LineagesMakie.CoordTransform, LineagesMakie.Layers]
```
