# Shared-descendant DAG example for tranche-2 geometry and plotting support.
#
# Run:
#   julia --project=examples examples/src/shared_descendant_dag_ex1.jl
#
# Output: examples/build/shared_descendant_dag_ex1.png
#
# Demonstrates:
#   - DAG-safe rectangular layout with `:nodelevels`
#   - graph-capable node-group annotation through explicit `group_nodes`
#   - consistent weighted full-network radial layout with `:edgeweights`
#   - all normalized DAG edges rendered without a hidden tree projection

using CairoMakie
using LineagesMakie

mutable struct DagNode
    name::String
    children::Vector{DagNode}
end

shared = DagNode("shared", DagNode[])
left = DagNode("left", DagNode[shared])
right = DagNode("right", DagNode[shared])
basenode = DagNode("root", DagNode[left, right])

edgeweights = Dict(
    ("root", "left") => 1.0,
    ("root", "right") => 1.0,
    ("left", "shared") => 2.0,
    ("right", "shared") => 2.0,
)
group_nodes = DagNode[left, right]

accessor = lineagegraph_accessor(
    basenode;
    children = node -> node.children,
    edgeweight = (src, dst) -> edgeweights[(src.name, dst.name)],
)

fig = Figure(; size = (960, 420))

lax1 = LineageAxis(
    fig[1, 1];
    title = "Shared-descendant DAG — node levels",
    show_x_axis = true,
    xlabel = "longest path from basenode",
)
lineageplot!(
    lax1,
    basenode,
    accessor;
    lineageunits = :nodelevels,
    edge_color = :slategray,
    edge_linewidth = 2.0,
    node_color = :white,
    node_strokecolor = :slategray,
    node_markersize = 12,
    leaf_color = :black,
    leaf_markersize = 12,
    leaf_label_func = node -> node.name,
    group_nodes = group_nodes,
    nodegroup_highlight_color = (:goldenrod, 0.28),
    nodegroup_highlight_alpha = 0.28,
    nodegroup_label_func = nodes -> join(String[node.name for node in nodes], " + "),
)

lax2 = LineageAxis(
    fig[1, 2];
    title = "Shared-descendant DAG — consistent edge weights",
    lineage_orientation = :radial,
)
lineageplot!(
    lax2,
    basenode,
    accessor;
    lineageunits = :edgeweights,
    lineage_orientation = :radial,
    edge_color = :steelblue,
    edge_linewidth = 2.0,
    node_color = :white,
    node_strokecolor = :steelblue,
    node_markersize = 12,
    leaf_color = :steelblue,
    leaf_markersize = 12,
    leaf_label_func = node -> node.name,
)

outdir = joinpath(@__DIR__, "..", "build")
mkpath(outdir)
save(joinpath(outdir, "shared_descendant_dag_ex1.png"), fig)
