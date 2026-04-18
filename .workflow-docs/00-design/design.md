
## Purpose 

A general framework for visualization of evolutionary (phylogenetic, coalescent, cladistic, ancestral) graphs and associated biological data in the Makie ecosystem.

A single top-level function:

```julia
lineageplot(x; kw...)
```

and support inputs through these routes:

- native support for `AbstractTrees`-style objects
- native support for `Graphs.AbstractGraph`
- explicit keyword-based accessors for arbitrary foreign objects

## Proposed concepts

```julia
using LineagesMakie, CairoMakie

fig, ax, plt = lineageplot(
    seednode;
    children = node -> ..., # or: children = AbstractTrees.children,
    edgelength = (node1, node2) -> ...
    ...styling,
    ...allow muliple images/labels in different positions around nodes/edges?
)
```


```julia
using LineagesMakie, GLMakie

tree_obs = Observable(tree)
scale_obs = Observable(1.0)
highlight_obs = Observable(Set{Int}())

fig = Figure()
ax = BranchingAxis(fig[1, 1])

lineageplot!(ax, tree_obs;
    branchlength_scale = scale_obs,
    color = lift(highlight_obs) do hs
        branchcolor_by_node(hs)
    end
)

slider = Slider(fig[2, 1], range = 0.1:0.1:5.0)
connect!(scale_obs, slider.value)

on(events(fig).mouseclick) do event
    node = pick_node(ax, event)
    highlight_obs[] = toggle(highlight_obs[], node)
end

fig
```
