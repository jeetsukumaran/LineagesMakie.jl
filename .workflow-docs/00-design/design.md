
## Purpose 

A general framework for visualization of evolutionary (phylogenetic, coalescent, cladistic, ancestral) graphs and associated biological data in the Makie ecosystem.

## Proposed concepts

Functions take accessors as arguments

```julia
lineageplot(x; kw...)
```

and support inputs through these routes:

- native support for `AbstractTrees`-style objects
- native support for `Graphs.AbstractGraph`
- explicit keyword-based accessors for arbitrary foreign objects


```julia
using LineagesMakie, CairoMakie

fig, ax, plt = lineageplot(
    seedvertex;
    children = vertex -> ..., # or: children = AbstractTrees.children,
    edgelength = (vertex1, vertex2) -> ...
    ...styling,
    ...allow muliple images/labels in different positions around vertices/edges?
)
```


```julia
using LineagesMakie, GLMakie

tree_obs = Observable(tree)
scale_obs = Observable(1.0)
highlight_obs = Observable(Set{Int}())

fig = Figure()
ax = LineageAxis(fig[1, 1])

lineageplot!(ax, tree_obs;
    edgelength_scale = scale_obs,
    color = lift(highlight_obs) do hs
        edgecolor_by_vertex(hs)
    end
)

slider = Slider(fig[2, 1], range = 0.1:0.1:5.0)
connect!(scale_obs, slider.value)

on(events(fig).mouseclick) do event
    vertex = pick_vertex(ax, event)
    highlight_obs[] = toggle(highlight_obs[], vertex)
end

fig
```
