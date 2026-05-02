# README quick start example.
#
# Run:
#   julia --project=examples examples/readme_quickstart.jl
#
# Output: readme_quickstart.png in this directory.

using CairoMakie
using LineagesMakie

struct Node
    name::String
    edgeweight::Float64
    children::Vector{Node}
end

leaf(name, edgeweight) = Node(name, edgeweight, Node[])
node(name, edgeweight, children::Node...) = Node(name, edgeweight, Node[children...])

basenode = node(
    "root",
    0.0,
    node("alpha", 0.0, leaf("alpha_1", 0.0), leaf("alpha_2", 0.0)),
    node("beta", 0.0, leaf("beta_1", 0.0), leaf("beta_2", 0.0)),
)

accessor = lineagegraph_accessor(basenode; children = node -> node.children)

plot_result = lineageplot(
    basenode,
    accessor;
    figure = (; size = (640, 360)),
    axis = (; title = "Default leaf-aligned layout"),
    leaf_label_func = node -> node.name,
    node_color = :white,
    node_strokecolor = :gray35,
    leaf_color = :gray10,
    edge_color = :gray35,
)

fig, _, _ = plot_result
save(joinpath(@__DIR__, "readme_quickstart.png"), fig)
