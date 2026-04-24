# Full-featured example: composite LineagePlot recipe with all major options.
#
# Run:
#   julia --project=examples examples/lineageplot_ex2.jl
#
# Output: lineageplot_ex2.png in the working directory.
#
# Demonstrates:
#   - Hand-coded phylogenetic tree with branch lengths
#   - lineagegraph_accessor with edgelength and nodevalue
#   - Four panels: forward-time (:edgelengths), backward-time (:nodeheights),
#     top-to-bottom orientation, and radial layout
#   - All major attribute groups: edge styling, node markers, leaf labels,
#     clade highlights, clade labels, scalebar

using CairoMakie
using LineagesMakie

# ── Node type ─────────────────────────────────────────────────────────────────

struct PhyloNode
    name::String
    branch_length::Float64  # edge length from parent to this node
    children::Vector{PhyloNode}
end

# ── Tree ──────────────────────────────────────────────────────────────────────

#   root (bl=0)
#   ├── clade_A (bl=4)
#   │   ├── sp_A1  (bl=6, leaf)
#   │   └── clade_A2 (bl=3)
#   │       ├── sp_A2a (bl=3, leaf)
#   │       └── sp_A2b (bl=3, leaf)
#   └── clade_B (bl=4)
#       ├── sp_B1 (bl=6, leaf)
#       ├── sp_B2 (bl=6, leaf)
#       └── sp_B3 (bl=6, leaf)

const PHYROOT = PhyloNode("root", 0.0, [
    PhyloNode("clade_A", 4.0, [
        PhyloNode("sp_A1",  6.0, PhyloNode[]),
        PhyloNode("clade_A2", 3.0, [
            PhyloNode("sp_A2a", 3.0, PhyloNode[]),
            PhyloNode("sp_A2b", 3.0, PhyloNode[]),
        ]),
    ]),
    PhyloNode("clade_B", 4.0, [
        PhyloNode("sp_B1", 6.0, PhyloNode[]),
        PhyloNode("sp_B2", 6.0, PhyloNode[]),
        PhyloNode("sp_B3", 6.0, PhyloNode[]),
    ]),
])

# ── Accessor ──────────────────────────────────────────────────────────────────

const PHYACC = lineagegraph_accessor(
    PHYROOT;
    children   = node -> node.children,
    edgelength = (src, dst) -> dst.branch_length,
    nodevalue  = node -> node.name,
)

# Clade roots for highlights and bracket labels.
const CLADE_A = PHYROOT.children[1]
const CLADE_B = PHYROOT.children[2]

# ── Shared style constants ─────────────────────────────────────────────────────

const EDGE_COLOR    = :slategray
const EDGE_LW       = 1.5f0
const LEAF_COLOR    = :black
const LEAF_SIZE     = 7
const NODE_COLOR    = :white
const NODE_STROKE   = :slategray
const NODE_SIZE     = 6

# ── Figure ────────────────────────────────────────────────────────────────────

fig = Figure(; size = (1200, 900))

# ── Panel 1 (top-left): forward time, all features ────────────────────────────

lax1 = LineageAxis(
    fig[1, 1];
    title = "Forward time — branch lengths",
    show_x_axis = true,
    xlabel = "cumulative branch length (Ma)",
)
lineageplot!(
    lax1, PHYROOT, PHYACC;
    lineageunits          = :edgelengths,
    edge_color            = EDGE_COLOR,
    edge_linewidth        = EDGE_LW,
    node_color            = NODE_COLOR,
    node_strokecolor      = NODE_STROKE,
    node_markersize       = NODE_SIZE,
    leaf_color            = LEAF_COLOR,
    leaf_markersize       = LEAF_SIZE,
    leaf_label_func       = node -> node.name,
    leaf_label_fontsize   = 11,
    clade_nodes           = [CLADE_A, CLADE_B],
    clade_label_func      = node -> node.name,
    clade_label_fontsize  = 10,
    clade_highlight_alpha = 0.08,
    scalebar_auto_visible = true,
    scalebar_label        = "1 Ma",
)

# ── Panel 2 (top-right): backward time, :nodeheights ──────────────────────────

lax2 = LineageAxis(
    fig[1, 2];
    title = "Backward time — node heights",
    show_x_axis = true,
    xlabel = "edge count to farthest leaf",
)
lineageplot!(
    lax2, PHYROOT, PHYACC;
    lineageunits        = :nodeheights,
    edge_color          = :steelblue,
    edge_linewidth      = EDGE_LW,
    node_color          = NODE_COLOR,
    node_strokecolor    = :steelblue,
    node_markersize     = NODE_SIZE,
    leaf_color          = :steelblue,
    leaf_markersize     = LEAF_SIZE,
    leaf_label_func     = node -> node.name,
    leaf_label_fontsize = 11,
    clade_nodes         = [CLADE_A, CLADE_B],
    clade_label_func    = node -> node.name,
    clade_highlight_alpha = 0.08,
)

# ── Panel 3 (bottom-left): top-to-bottom orientation with y-axis ─────────────

lax3 = LineageAxis(
    fig[2, 1];
    title = "Top-to-bottom orientation with y-axis",
    lineage_orientation = :top_to_bottom,
    show_y_axis = true,
    show_grid = true,
    ylabel = "cumulative branch length (Ma)",
)
lineageplot!(
    lax3, PHYROOT, PHYACC;
    lineageunits          = :edgelengths,
    edge_color            = EDGE_COLOR,
    edge_linewidth        = EDGE_LW,
    node_color            = NODE_COLOR,
    node_strokecolor      = NODE_STROKE,
    node_markersize       = NODE_SIZE,
    leaf_color            = LEAF_COLOR,
    leaf_markersize       = LEAF_SIZE,
    leaf_label_func       = node -> node.name,
    leaf_label_fontsize   = 11,
    clade_nodes           = [CLADE_A, CLADE_B],
    clade_label_func      = node -> node.name,
    clade_highlight_alpha = 0.08,
)

# ── Panel 4 (bottom-right): radial layout ─────────────────────────────────────

lax4 = LineageAxis(
    fig[2, 2];
    title = "Radial layout",
    lineage_orientation = :radial,
)
lineageplot!(
    lax4, PHYROOT, PHYACC;
    lineageunits        = :edgelengths,
    lineage_orientation = :radial,
    edge_color          = EDGE_COLOR,
    edge_linewidth      = EDGE_LW,
    node_color          = NODE_COLOR,
    node_strokecolor    = NODE_STROKE,
    node_markersize     = NODE_SIZE,
    leaf_color          = LEAF_COLOR,
    leaf_markersize     = LEAF_SIZE,
    leaf_label_func     = node -> node.name,
    leaf_label_fontsize = 11,
)

# ── Save ──────────────────────────────────────────────────────────────────────

outfile = joinpath(dirname(@__FILE__), "lineageplot_ex2.png")
save(outfile, fig)
@info "Saved $outfile"
