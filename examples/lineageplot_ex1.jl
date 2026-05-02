# Minimal working example: non-mutating lineageplot on a hand-coded tree.
#
# Run:
#   julia --project=examples examples/lineageplot_ex1.jl
#
# Output: lineageplot_ex1.png in the working directory.

using CairoMakie
using LineagesMakie

# ── Node type ─────────────────────────────────────────────────────────────────

struct MWENode
    label::String
    children::Vector{MWENode}
end

# ── Tree ──────────────────────────────────────────────────────────────────────

#   root
#   ├── A
#   │   ├── a1
#   │   └── a2
#   └── B
#       ├── b1
#       └── b2

const BASENODE = MWENode("root", [
    MWENode("A", [MWENode("a1", MWENode[]), MWENode("a2", MWENode[])]),
    MWENode("B", [MWENode("b1", MWENode[]), MWENode("b2", MWENode[])]),
])

# ── Accessor ──────────────────────────────────────────────────────────────────

const ACC = lineagegraph_accessor(BASENODE; children = node -> node.children)

# ── Figure ────────────────────────────────────────────────────────────────────

plot_result = lineageplot(
    BASENODE,
    ACC;
    figure = (; size = (600, 400)),
    axis = (; title = "Lineage tree (MWE)"),
    leaf_label_func = node -> node.label,
)
fig, lax, lp = plot_result

outfile = joinpath(dirname(@__FILE__), "lineageplot_ex1.png")
save(outfile, fig)
@info "Saved $outfile"
