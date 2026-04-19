# API Landscape: Phylogenetic Tree Packages

Terminology, data models, and access patterns across all surveyed packages.
Covers: PhyloNetworks.jl, Phylo.jl, Phylogenies.jl, AbstractTrees.jl,
D3Trees.jl, DendroPy.jl.

---

## Part 1 — Terminology

### 1.1 Core Concepts

| Concept | PhyloNetworks.jl | Phylo.jl | Phylogenies.jl | AbstractTrees.jl | D3Trees.jl | DendroPy.jl |
|---|---|---|---|---|---|---|
| **Tree / network object** | `HybridNetwork` (`<: Network`) | `BinaryTree`, `PolytomousTree`, `LinkTree`, `RecursiveTree` (all `<: AbstractTree`) | `Phylogeny{C,B}` | Any object implementing `children()` — no tree container type | `D3Tree` (wraps any AbstractTrees object) | `TreeNode{T}` (thin Julia wrapper around Python DendroPy tree) |
| **Internal node** | `Node` | `BinaryNode`, `Node`, `LinkNode`, `RecursiveNode` (all `<: AbstractNode`) | "clade" or "vertex" (plain `Int` index into LightGraphs DiGraph) | "node" (any Julia object; no dedicated type) | `D3TreeNode` (wrapper for index into `D3Tree`) | `TreeNode{T}` (same type as tree; distinguished by context) |
| **Leaf / tip** | `Node` with `.leaf = true`; collected in `net.leaf::Vector{Node}` | `Node`/`BinaryNode` with no outbound branches; tested with `isleaf(tree, name)` | vertex index in `1:tree.ntaxa`; tested with `isleaf(tree, v)` | Node for which `children(node)` returns empty; tested with `isempty(children(n))` | Node for which `children(n)` returns empty iterator | `TreeNode` for which `is_internal(node)` returns `false` |
| **Branch / edge** | `Edge` (alias for `EdgeT{Node}`); stored in `net.edge::Vector{Edge}` | `Branch{RT, NL}` (`<: AbstractBranch`); identified by integer name | `Edge` from LightGraphs (a `(src,dst)` pair); accessed via `child_branches`, `parent_branch` | Implicit — the parent→child link; no edge object | Implicit — index pair in `tree.children::Vector{Vector{Int}}` | Implicit — accessed as `node.data.edge` (Python DendroPy edge object) |
| **Branch length** | `Edge.length::Float64` (−1.0 = missing) | `Branch.length::Union{Float64,Missing}` | `branchlength(tree, edge)` via `branchlength(branchdata(tree, edge))`; stored in `tree.edgedata::Dict{Edge,B}` | Not part of interface (domain-agnostic) | Not applicable (display-only package) | `edge_length(node::TreeNode)` → `node.data.edge.length::Float64` |
| **Root node** | `net.node[net.rooti]`; accessor `getroot(net)` | Node with no inbound branch; `getroot(tree)` / `getroots(tree)` | `root(tree)` → `tree.ntaxa + 1` (fixed index convention) | Node for which `parent(node) === nothing`; `isroot(x)` | Index 1 (`D3TreeNode(t, 1)`) | `tree.data.seed_node` (Python attribute); no Julia wrapper |
| **Parent relationship** | `getparent(node)` (major parent); `getparents(node)` (all, for hybrids); direction encoded in `Edge.ischild1` | `getparent(tree, nodename)` → parent name; `getinbound(tree, nodename)` → inbound `Branch` | `parent(tree, vertex::Int)` → `in_neighbors(graph, v)[1]` | `parent(node)` (requires `StoredParents` trait declared); default returns `nothing` | Via AbstractTrees `parent()` (not native to D3Tree) | `node.data.parent_node` (raw Python); no Julia wrapper function |
| **Children relationship** | `getchildren(node)` → `Vector{Node}`; `getchild(node)` (single, with check) | `getoutbounds(tree, nodename)` → outbound `Branch`es; `dst(tree, branch)` for child name | `children(tree, vertex::Int)` → `out_neighbors(graph, v)` | `children(node)` — the one required method; returns any iterable | `children(n::D3TreeNode)` → iterator of `D3TreeNode`; `tree.children[i]::Vector{Int}` for raw indices | `node.children::Vector{TreeNode}` (Julia field); `node.data.child_nodes()` (Python method) |
| **Edge / branch identifier** | `Edge.number::Int` (stable unique id) | `Branch.name::Int` (integer key in branch dict) | `LightGraphs.Edge(src, dst)` struct | None (edges are implicit parent→child pairs) | Integer index pair (parent index → child index in `tree.children`) | No identifier; accessed only via node reference |
| **Support / bootstrap** | `Edge.y::Float64` (−1.0 = missing; stores support) | Stored in node data `Dict` via `getnodedata` / `setnodedata!` | Not built-in; user-managed in `C` annotation type | Not part of interface | Not applicable | `node.data.label` (string); numerical value not separately typed |
| **Hybrid / reticulation node** | `Node.hybrid::Bool`; collected in `net.hybrid::Vector{Node}` | Not supported | Not supported | Not supported | Not supported | Not supported |
| **Hybrid / reticulation edge** | `Edge.hybrid::Bool`; `Edge.gamma::Float64` (inheritance weight); `Edge.ismajor::Bool` | Not supported | Not supported | Not supported | Not supported | Not supported |
| **Node name / label** | `Node.name::AbstractString` | Node identified by `String` name (used as dict key); `getnodename(tree, node)` | Vertex index only; leaf labels stored in `tree.taxa::Vector{Symbol}` | `nodevalue(node)` (default: identity); `printnode(io, node)` for display | `tree.text[i]::String` (display label per index) | `label(node)` → `node.data.label` |
| **Node numeric id** | `Node.number::Int` | No numeric id; nodes keyed by String name | Vertex index (`Int`) IS the id | Not part of interface | Integer index (1-based position in `tree.children`) | `node.data` Python object reference |

### 1.2 Tree-Level Properties

| Property | PhyloNetworks.jl | Phylo.jl | Phylogenies.jl | AbstractTrees.jl | DendroPy.jl |
|---|---|---|---|---|---|
| Node count | `net.numnodes::Int` | `nnodes(tree)` | `nv(tree.graph)` (LightGraphs) | `treesize(root)` (recursive) | iterate and count |
| Leaf / tip count | `net.numtaxa::Int` | `nleaves(tree)` | `tree.ntaxa::Int` | `treebreadth(root)` (recursive) | iterate and count |
| Edge count | `net.numedges::Int` | `nbranches(tree)` | `ne(tree.graph)` | not built-in | not built-in |
| Is rooted | `net.isrooted::Bool` | `nroots(tree) == 1` (or type param `OneRoot`) | `isrooted(tree)` | `isroot(root)` (per-node) | not wrapped |
| Hybrid count | `net.numhybrids::Int` | n/a | n/a | n/a | n/a |
| Tree height | not built-in | not built-in | not built-in | `treeheight(root)` | not built-in |
| Total branch length | not built-in | not built-in | not built-in | not built-in | `sum(edge_length, preorder_iter(tree))` |
| Node age / depth | not built-in | not built-in | not built-in | not built-in | `age(node)`, `depth(node)` |

---

## Part 2 — API: Minimal Working Examples

### PhyloNetworks.jl

```julia
using PhyloNetworks

# ── Load from file / Newick string ──────────────────────────────────────────
net = readnewick("path/to/tree.nwk")
net = readnewick("((A,B),(C,D));")
# readnexus_treeblock("path/to/file.nex") for Nexus

# ── Tree-level properties ────────────────────────────────────────────────────
net.numnodes    # total node count
net.numtaxa     # tip count
net.numedges    # edge count
net.numhybrids  # reticulation count
net.isrooted    # Bool

# ── Iterate all nodes ────────────────────────────────────────────────────────
for n in net.node
    println(n.number, " ", n.name, " leaf=", n.leaf, " hybrid=", n.hybrid)
end

# ── Iterate leaves only ──────────────────────────────────────────────────────
for n in net.leaf          # pre-filtered Vector{Node}
    println(n.name)
end

# ── Iterate all edges ────────────────────────────────────────────────────────
for e in net.edge
    println(e.number, " len=", e.length, " hybrid=", e.hybrid, " γ=", e.gamma)
end

# ── Parent / children of a node ─────────────────────────────────────────────
n  = net.node[5]
p  = getparent(n)          # major parent Node (errors if root)
ps = getparents(n)         # all parents (Vector{Node}; >1 for hybrid nodes)
cs = getchildren(n)        # Vector{Node}

# ── Edge endpoints ───────────────────────────────────────────────────────────
e           = net.edge[3]
child_node  = getchild(e)      # Node on child side
parent_node = getparent(e)     # Node on parent side
# direction: e.ischild1 == true means e.node[1] is child

# ── Edge length ──────────────────────────────────────────────────────────────
e.length           # Float64; -1.0 if missing

# ── Hybrid edge properties ───────────────────────────────────────────────────
e.hybrid           # Bool
e.gamma            # Float64 inheritance weight (1.0 for tree edges)
e.ismajor          # Bool

# ── Mutation ────────────────────────────────────────────────────────────────
n.name = "Taxon_X"
setlengths!(net.edge[1:3], [0.1, 0.2, 0.3])
net.node[2].hybrid = false
```

---

### Phylo.jl

```julia
using Phylo

# ── Load from Newick file ────────────────────────────────────────────────────
tree = open(f -> parsenewick(f, NamedPolytomousTree), "path/to/tree.nwk")
tree = parsenewick("((A:1.0,B:2.0)AB:0.5,C:3.0);")  # from string

# ── Tree-level properties ────────────────────────────────────────────────────
nnodes(tree)
nleaves(tree)
nbranches(tree)
nroots(tree)      # 1 if rooted

# ── Iterate all nodes ────────────────────────────────────────────────────────
for name in nodenameiter(tree)
    node = getnode(tree, name)
end
for node in nodeiter(tree)
    println(getnodename(tree, node))
end

# ── Iterate leaves only ──────────────────────────────────────────────────────
for name in getleafnames(tree)       end
for name in nodenamefilter(isleaf, tree)  end

# ── Iterate branches ─────────────────────────────────────────────────────────
for branch in branchiter(tree)
    println(getlength(tree, branch))
end
for name in branchnameiter(tree)
    b = getbranch(tree, name)
    println(src(tree, b), " → ", dst(tree, b), " len=", getlength(tree, b))
end

# ── Parent / children ───────────────────────────────────────────────────────
parent_name       = getparent(tree, "A")
inbound_branch    = getinbound(tree, "A")
outbound_branches = getoutbounds(tree, "AB")
child_names       = [dst(tree, b) for b in getoutbounds(tree, "AB")]

# ── Edge length ──────────────────────────────────────────────────────────────
branch = getinbound(tree, "A")
getlength(tree, branch)    # Float64 or Missing

# ── Node data (bootstrap, traits, etc.) ─────────────────────────────────────
setnodedata!(tree, "AB", Dict("bootstrap" => 95.0))
data = getnodedata(tree, "AB")
data["bootstrap"]          # 95.0

# ── Mutation ────────────────────────────────────────────────────────────────
setbranchlength!(tree, branch, 1.5)
setnodedata!(tree, "A", Dict("trait" => 3.14))
```

---

### Phylogenies.jl

> **Status: likely unmaintained** — targets Julia 0.5; uses LightGraphs (deprecated).
> Nodes are plain integer indices; leaves are `1:ntaxa`, root is `ntaxa+1`.

```julia
using Phylogenies

# ── Construct (no file I/O in current codebase) ──────────────────────────────
tree = Phylogeny([:A, :B, :C])
tree = Phylogeny{MyNodeType, Float64}([:A, :B, :C])

# ── Tree-level properties ────────────────────────────────────────────────────
isrooted(tree)
tree.ntaxa
nv(tree.graph)    # LightGraphs total vertex count
ne(tree.graph)    # LightGraphs edge count

# ── Iterate leaves (vertex indices 1:ntaxa) ──────────────────────────────────
for v in leaves(tree)
    println(tree.taxa[v])
end

# ── Iterate internal clades (vertex indices > ntaxa) ─────────────────────────
for v in clades(tree)
    println(v)
end

# ── Iterate edges from a vertex ──────────────────────────────────────────────
for e in child_branches(tree, v)
    println(branchlength(tree, e))
end
parent_edge = parent_branch(tree, v)

# ── Parent / children ───────────────────────────────────────────────────────
Phylogenies.parent(tree, v)    # Int vertex index
children(tree, v)              # Vector{Int}
nchildren(tree, v)
haschildren(tree, v)
hasparent(tree, v)

# ── Branch length ────────────────────────────────────────────────────────────
e = parent_branch(tree, v)
branchlength(tree, e)          # Float64

# ── Mutation ────────────────────────────────────────────────────────────────
branchlength!(tree, e, 0.237)
branchdata!(tree, e, mydata)
# node data: tree.vertexdata[v] (direct field access)
```

---

### AbstractTrees.jl

> AbstractTrees is an **interface**, not a data package. The examples below
> show what to implement and what you then get for free.

```julia
using AbstractTrees

# ── Implement the interface ──────────────────────────────────────────────────
mutable struct MyNode{T}
    data::T
    parent::Union{Nothing, MyNode{T}}
    children::Vector{MyNode{T}}
end

# Minimum required:
AbstractTrees.children(n::MyNode) = n.children

# Optional — stored parents (enables upward traversal):
AbstractTrees.ParentLinks(::Type{<:MyNode}) = StoredParents()
AbstractTrees.parent(n::MyNode) = n.parent

# Optional — indexed children (O(1) child access):
AbstractTrees.ChildIndexing(::Type{<:MyNode}) = IndexedChildren()
AbstractTrees.childrentype(::Type{MyNode{T}}) where T = Vector{MyNode{T}}

# Optional — uniform node type:
AbstractTrees.NodeType(::Type{<:MyNode{T}}) where T = HasNodeType()
AbstractTrees.nodetype(::Type{MyNode{T}}) where T = MyNode{T}

# Optional — display:
AbstractTrees.printnode(io::IO, n::MyNode) = print(io, n.data)

# ── Traversal ────────────────────────────────────────────────────────────────
root = MyNode(1, nothing, [])

for node in PreOrderDFS(root)   end   # parent before children
for node in PostOrderDFS(root)  end   # children before parent
for node in Leaves(root)        end   # leaves only
for node in StatelessBFS(root)  end   # breadth-first (O(n²); avoid on large trees)

# ── Predicates ───────────────────────────────────────────────────────────────
isroot(node)
ischild(child, parent)
isdescendant(node, ancestor)
intree(node, root)

# ── Tree metrics ─────────────────────────────────────────────────────────────
treesize(root)      # total node count
treebreadth(root)   # leaf count
treeheight(root)    # max depth to any leaf

# ── Upward traversal (requires StoredParents) ────────────────────────────────
getroot(node)
ascend(f, node)     # call f at each ancestor until f returns nothing

# ── Functional transform ─────────────────────────────────────────────────────
new_tree = treemap(n -> (n.data * 2, children(n)), root)
```

---

### D3Trees.jl

> D3Trees is a **visualization** package, not a tree data package.
> Requires an internet connection at render time (fetches D3.js and jQuery from CDN).

```julia
using D3Trees

# ── Construct from AbstractTrees-compatible object ───────────────────────────
t = D3Tree(my_root_node)
t = D3Tree(my_root_node; detect_repeat=false, lazy_expand_after_depth=3)

# ── Construct from explicit children index structure ─────────────────────────
# children[i] = 1-based indices of children of node i
t = D3Tree([[2, 3], [], [4, 5], [], []];
           text    = ["root", "leaf1", "internal", "leaf2", "leaf3"],
           tooltip = ["tip: root", "", "", "", ""])

# ── Node display properties (mutable) ────────────────────────────────────────
t.text[1]        # display label
t.tooltip[1]     # hover tooltip
t.style[1]       # CSS style for node circle
t.link_style[1]  # CSS style for link to this node

# ── Render ───────────────────────────────────────────────────────────────────
inchrome(t)      # open in Chrome
inbrowser(t)     # open in default browser
# In IJulia / Pluto / VSCode: display(t)
# NOTE: requires internet — fetches d3js.org and code.jquery.com at render time

# ── AbstractTrees traversal ──────────────────────────────────────────────────
using AbstractTrees
for node in PreOrderDFS(D3TreeNode(t, 1))  end
for leaf in Leaves(D3TreeNode(t, 1))       end

# ── Lazy expansion ───────────────────────────────────────────────────────────
t = D3Tree(root; lazy_expand_after_depth=2)
# nodes beyond depth 2 collapsed; clicking in browser expands on demand
```

---

### DendroPy.jl

> Thin Julia wrapper around the Python DendroPy library (via PythonCall.jl).
> Status: pre-alpha / experimental. Parent access and mutation are not wrapped —
> use `node.data` to reach the raw Python object.

```julia
using DendroPy

# ── Load from Newick string ──────────────────────────────────────────────────
DendroPy.enumerate_map_tree_source(
    (idx, tree) -> process(tree),
    "((A,B),(C,D));",
    "string",      # "string" | "filepath" | "file"
    :newick
)

# ── Load from file ───────────────────────────────────────────────────────────
trees = TreeNode[]
DendroPy.enumerate_map_tree_source(
    (idx, tree) -> push!(trees, tree),
    "path/to/tree.nwk",
    "filepath",
    :newick
)

# ── Simulate (birth-death) ───────────────────────────────────────────────────
trees = DendroPy.birth_death_trees(
    rng,
    Dict(:birth_rate => 1.0, :death_rate => 0.5, :num_extant_tips => 10),
    n_replicates
)

# ── Iterate all nodes ────────────────────────────────────────────────────────
for node in DendroPy.preorder_iter(tree)
    println(DendroPy.label(node))
end
for node in DendroPy.postorder_iter(tree)
    println(DendroPy.edge_length(node))
end

# ── Iterate leaves only ──────────────────────────────────────────────────────
for node in DendroPy.preorder_iter(tree)
    DendroPy.is_internal(node) && continue
    println(DendroPy.label(node))
end

# ── Edge length (no dedicated edge iterator — access via node) ───────────────
for node in DendroPy.preorder_iter(tree)
    len = DendroPy.edge_length(node)   # Float64; NaN for root
end

# ── Node properties ──────────────────────────────────────────────────────────
DendroPy.label(node)        # String
DendroPy.is_internal(node)  # Bool
DendroPy.age(node)          # Float64 (time from present)
DendroPy.depth(node)        # Float64 (distance from root)
DendroPy.edge_length(node)  # Float64
node.children               # Vector{TreeNode} (Julia field)

# ── Parent access (not wrapped) ──────────────────────────────────────────────
node.data.parent_node        # raw Python DendroPy Node

# ── Mutation (not wrapped) ───────────────────────────────────────────────────
node.data.label = "NewName"
node.data.edge.length = 0.5

# ── Coalescence / divergence utilities ──────────────────────────────────────
DendroPy.coalescence_ages(tree)    # Vector{Float64} — ages of internal nodes
DendroPy.divergence_times(tree)    # Vector{Float64} — depths of internal nodes
```

---

## Part 3 — Comparative Summary

### Access pattern style

| Package | Node identity | Branch identity | Traversal style |
|---|---|---|---|
| **PhyloNetworks.jl** | Object reference (`Node`); also `.number::Int` | Object reference (`Edge`); also `.number::Int` | Direct `Vector` iteration (`net.node`, `net.edge`, `net.leaf`) |
| **Phylo.jl** | String name (dict key); node object via `getnode(tree, name)` | Integer name; branch object via `getbranch(tree, name)` | Named iterators (`nodeiter`, `branchiter`, `nodenamefilter`) |
| **Phylogenies.jl** | Integer index (`1:nv(graph)`); leaves `1:ntaxa`, root `ntaxa+1` | LightGraphs `Edge(src, dst)` struct | LightGraphs graph API (`in_neighbors`, `out_neighbors`) |
| **AbstractTrees.jl** | The object itself (any Julia value) | Implicit parent→child pair | Iterator types (`PreOrderDFS`, `PostOrderDFS`, `Leaves`, `StatelessBFS`) |
| **D3Trees.jl** | Integer index (1-based into `tree.children`) | Integer pair via `tree.children[i]` | Delegates to AbstractTrees iterators |
| **DendroPy.jl** | `TreeNode` wrapper; Python object via `.data` | Implicit — accessed via `node.data.edge` | `preorder_iter`, `postorder_iter`; leaves via `is_internal` filter |

### Branch length access

| Package | Read | Write |
|---|---|---|
| **PhyloNetworks.jl** | `edge.length` | `edge.length = v`; `setlengths!(edges, vals)` |
| **Phylo.jl** | `getlength(tree, branch)` | `setbranchlength!(tree, branch, v)` |
| **Phylogenies.jl** | `branchlength(tree, edge)` | `branchlength!(tree, edge, v)` |
| **AbstractTrees.jl** | not part of interface | not part of interface |
| **D3Trees.jl** | not applicable | not applicable |
| **DendroPy.jl** | `edge_length(node)` | `node.data.edge.length = v` (raw Python) |

### Leaf iteration

| Package | Expression |
|---|---|
| **PhyloNetworks.jl** | `for n in net.leaf` |
| **Phylo.jl** | `for name in getleafnames(tree)` / `nodenamefilter(isleaf, tree)` |
| **Phylogenies.jl** | `for v in leaves(tree)` (returns `1:ntaxa`) |
| **AbstractTrees.jl** | `for n in Leaves(root)` |
| **D3Trees.jl** | `for n in Leaves(D3TreeNode(t, 1))` |
| **DendroPy.jl** | `filter(!is_internal, collect(preorder_iter(tree)))` |

### File I/O

| Package | Newick in | Nexus in | Other |
|---|---|---|---|
| **PhyloNetworks.jl** | `readnewick(path_or_string)` | `readnexus_treeblock(path)` | Extended Newick (networks with reticulations) |
| **Phylo.jl** | `parsenewick(io_or_string[, TreeType])` | not built-in | — |
| **Phylogenies.jl** | not implemented | not implemented | construct only |
| **AbstractTrees.jl** | not applicable | not applicable | interface only |
| **D3Trees.jl** | not applicable | not applicable | wraps existing tree |
| **DendroPy.jl** | `enumerate_map_tree_source(..., :newick)` | `enumerate_map_tree_source(..., :nexus)` | via Python DendroPy |
