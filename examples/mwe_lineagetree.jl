# Minimal working example: render a 4-leaf tree with LineagesMakie.jl
#
# Run from repo root:
#   julia --project examples/mwe_tree.jl
# Output: examples/mwe_tree.png

import CairoMakie
using CairoMakie: Figure, Axis, save
using LineagesMakie

struct Vertex
    name::String
    children::Vector{Vertex}
end

#   root
#   ├── ab
#   │   ├── a
#   │   └── b
#   └── cd
#       ├── c
#       └── d
root = Vertex("root", [
    Vertex("ab", [Vertex("a", Vertex[]), Vertex("b", Vertex[])]),
    Vertex("cd", [Vertex("c", Vertex[]), Vertex("d", Vertex[])]),
])

acc = lineagegraph_accessor(root; children = n -> n.children)

fig = Figure(; size = (600, 400))
ax  = Axis(fig[1, 1]; title = "MWE — 4-leaf tree (edges only, Tier 1)")
lineageplot!(ax, root, acc)
fig