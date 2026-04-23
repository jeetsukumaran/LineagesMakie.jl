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

const ROOT = MWENode("root", [
    MWENode("A", [MWENode("a1", MWENode[]), MWENode("a2", MWENode[])]),
    MWENode("B", [MWENode("b1", MWENode[]), MWENode("b2", MWENode[])]),
])

# ── Accessor ──────────────────────────────────────────────────────────────────

const ACC = lineagegraph_accessor(ROOT; children = n -> n.children)

# ── Figure ────────────────────────────────────────────────────────────────────

plot_result = lineageplot(
    ROOT,
    ACC;
    figure = (; size = (600, 400)),
    axis = (; title = "Lineage tree (MWE)"),
    leaf_label_func = n -> n.label,
)
fig, lax, lp = plot_result

outfile = joinpath(dirname(@__FILE__), "lineageplot_ex1.png")
save(outfile, fig)
@info "Saved $outfile"
