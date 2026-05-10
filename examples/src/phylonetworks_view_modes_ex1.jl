# Rooted PhyloNetworks view-modes example.
#
# Run:
#   julia --project=test examples/src/phylonetworks_view_modes_ex1.jl
#
# Output: examples/build/phylonetworks_view_modes_ex1.png
#
# Demonstrates:
#   - rooted full-network view as the default direct HybridNetwork contract
#   - rooted major-tree projection via `networkview = :majortree`
#   - the visual distinction between the full-network and projected-tree paths
#   - the direct `:majortree` surface using only non-identity-sensitive styling
#     kwargs; projected-tree custom callbacks belong on the generic tree path

using CairoMakie
using LineagesMakie
using PhyloNetworks

net = readnewick(joinpath(dirname(pathof(PhyloNetworks)), "..", "examples", "net1.out"))

fig = Figure(; size = (1500, 560))

lax_full = LineageAxis(
    fig[1, 1];
    title = "Rooted full-network view",
    show_x_axis = true,
    xlabel = "node levels",
)

lineageplot!(
    lax_full,
    net;
    edge_color = :gray45,
    edge_linewidth = 1.0,
)

lax_major = LineageAxis(
    fig[1, 2];
    title = "Rooted major-tree projection",
    show_x_axis = true,
    xlabel = "node levels",
)

lineageplot!(
    lax_major,
    net;
    networkview = :majortree,
    displaypolicy = :rooted,
    edge_color = :gray45,
    edge_linewidth = 1.0,
)

outdir = joinpath(@__DIR__, "..", "build")
mkpath(outdir)
save(joinpath(outdir, "phylonetworks_view_modes_ex1.png"), fig)
