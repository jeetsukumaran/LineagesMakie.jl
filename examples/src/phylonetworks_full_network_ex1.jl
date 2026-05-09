# Rooted full-network PhyloNetworks example for tranche 4.
#
# Run:
#   julia --project=test examples/src/phylonetworks_full_network_ex1.jl
#
# Output: examples/build/phylonetworks_full_network_ex1.png
#
# Demonstrates:
#   - optional extension activation when PhyloNetworks.jl is present
#   - direct rooted full-network HybridNetwork plotting
#   - hybrid-node markers
#   - major/minor reticulation edge distinction
#   - gamma labels sourced from upstream edge fields

using CairoMakie
using LineagesMakie
using PhyloNetworks

net = readnewick(joinpath(dirname(pathof(PhyloNetworks)), "..", "examples", "net1.out"))

plot_result = lineageplot(
    net;
    figure = (; size = (900, 520)),
    axis = (; title = "Rooted full-network PhyloNetworks fixture", show_x_axis = true, xlabel = "node levels"),
    edge_color = :gray45,
    edge_linewidth = 1.0,
)

fig, lax, lp = plot_result

outdir = joinpath(@__DIR__, "..", "build")
mkpath(outdir)
save(joinpath(outdir, "phylonetworks_full_network_ex1.png"), fig)
