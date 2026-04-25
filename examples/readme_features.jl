# README feature example.
#
# Run:
#   julia --project=examples examples/readme_features.jl
#
# Output: readme_features.png in this directory.

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
beta = node(
    "beta",
    0.9,
    leaf("beta_1", 1.4),
    leaf("beta_2", 1.2),
)
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
    node_markersize = 7,
    leaf_color = :black,
    leaf_markersize = 7,
    leaf_label_func = node -> node.name,
    leaf_label_fontsize = 12,
    clade_nodes = [alpha],
    clade_label_func = node -> node.name,
    clade_highlight_color = (:lightskyblue, 0.25),
    clade_highlight_alpha = 0.18,
    scalebar_label = "1 unit",
    scalebar_auto_visible = true,
)

fig, _, _ = plot_result
save(joinpath(@__DIR__, "readme_features.png"), fig)
