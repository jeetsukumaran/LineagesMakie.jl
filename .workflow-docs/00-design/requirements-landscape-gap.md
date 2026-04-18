# Requirements Landscape and Gap Analysis

## Phylogenetic Tree / Network Data Packages

| Package | Primary Tree Data Structure | Implements AbstractTrees.jl Interface? | Uses / Extends Graphs.jl `AbstractGraph`? |
|---|---|---|---|
| **PhyloNetworks.jl** | `HybridNetwork <: Network` — flat `Vector{Node}` + `Vector{Edge}` with cross-references; `rooti::Int` for root; explicit `hybrid::Vector{Node}` and `leaf::Vector{Node}` lists | No | No — bespoke adjacency structure; no Graphs.jl dependency |
| **Phylo.jl** | `LinkTree`, `RecursiveTree`, `BinaryTree`, `PolytomousTree` (all `<: AbstractTree{...}`); also `TreeSet` | No — defines own traversal API (`getchildren`, `getparent`, `getancestors`) | Partial — imports `src`, `dst`, `indegree`, `outdegree`, `degree` from Graphs.jl but does **not** extend `AbstractGraph` |
| **Phylogenies.jl** | `Phylogeny{C,B}` — wraps a `LightGraphs.DiGraph` internally | No | No — uses LightGraphs (not Graphs.jl); targets Julia 0.5; likely unmaintained |
| **D3Trees.jl** | `D3Tree` — transparent wrapper around any AbstractTrees.jl-compatible object, or a `Vector{Vector{Int}}` of child-index lists | Yes — consumes the interface (requires `children`, `printnode`); also implements it for its own `D3TreeNode` | No |

### PhyloNetworks.jl Data Model Detail

`HybridNetwork` is a flat adjacency structure, not a recursive or pointer-tree:

- `Node`: `number::Int`, `leaf::Bool`, `hybrid::Bool`, `name::AbstractString`,
  `edge::Vector{Edge}` (incident edges)
- `EdgeT{Node}` / `Edge`: `number::Int`, `length::Float64`, `hybrid::Bool`,
  `gamma::Float64` (inheritance proportion on hybrid edges; 1.0 for tree edges),
  `ischild1::Bool` (which of the two endpoint nodes is the child),
  `ismajor::Bool` (major vs. minor hybrid edge), `containroot::Bool`
- `HybridNetwork`: `node::Vector{Node}`, `edge::Vector{Edge}`, `rooti::Int`,
  `hybrid::Vector{Node}`, `leaf::Vector{Node}`, `partition::Vector{Partition}`
  (biconnected components)

The model supports reticulate evolution: a hybrid node has two or more parent edges,
each carrying a `gamma` inheritance weight summing to 1.0 across parents.

### Interface Reference: AbstractTrees.jl

Minimum required to satisfy the AbstractTrees.jl interface:

| Method | Required? | Notes |
|---|---|---|
| `children(node)` | **Yes** | Must return iterable of children; default returns `()` |
| `parent(node)` | Only if declaring `StoredParents` trait | Default returns `nothing` |
| `nodevalue(node)` | No | Default is identity |
| `printnode(io, node)` | No | Used for display |
| `nextsibling(node)` | Only if declaring `StoredSiblings` trait | |

Trait system (all optional): `ParentLinks` (`StoredParents` / `ImplicitParents`),
`SiblingLinks` (`StoredSiblings` / `ImplicitSiblings`), `ChildIndexing`
(`IndexedChildren` / `NonIndexedChildren`), `NodeType` (`HasNodeType` /
`NodeTypeUnknown`).

### Interface Reference: Graphs.jl `AbstractGraph`

Minimum required:

| Method | Notes |
|---|---|
| `nv(g)` | Number of vertices |
| `ne(g)` | Number of edges |
| `vertices(g)` | Iterable of vertices |
| `edges(g)` | Iterable of edges |
| `is_directed(::Type{G})` | Trait (static dispatch) |
| `has_vertex(g, v)` | Membership test |
| `has_edge(g, s, d)` | Edge existence |
| `inneighbors(g, v)` | Incoming neighbours |
| `outneighbors(g, v)` | Outgoing neighbours |
| `eltype(::Type{G})` | Vertex integer type |
| `edgetype(g)` | Edge type |
| `zero(::Type{G})` | Empty graph constructor |

---

## Phylogenetic / Tree Visualization Packages

| Package | Julia Graphics Ecosystem | Requires Internet? | Input Type Required | Notes |
|---|---|---|---|---|
| **Phylo.jl** (built-in) | Plots.jl (RecipesBase; backend-agnostic within Plots) | No | Phylo.jl `AbstractTree` subtypes only (`LinkTree`, `BinaryTree`, etc.) — must construct natively | Julia-native rendering |
| **PhyloPlots.jl** | Non-native: R base graphics via RCall.jl | No (R must be installed locally) | `HybridNetwork` (PhyloNetworks.jl) — must construct natively | Sends network data to R; all layout and rendering happen in R; user interleaves `R"..."` macros for styling |
| **D3Trees.jl** | Non-native: D3.js / JavaScript (browser, IJulia, VSCode) | **Yes** — fetches `d3js.org/d3.v3.js` and `code.jquery.com/jquery.min.js` from CDN at render time | Any object satisfying AbstractTrees.jl `children()` + `printnode()`, wrapped via `D3Tree(obj)` | Explicitly documented: "will not work offline" (`README.md`); warning shown in rendered HTML (`show.jl`) |
| **ggtree** | Non-native: R / ggplot2 (grammar-of-graphics) | No (R must be installed locally) | R `phylo` (ape), `treedata` (treeio), `tidytree` | R package; not callable from Julia |
| **GraphMakie.jl** | Makie (GLMakie / CairoMakie / WGLMakie — backend-agnostic) | No | Graphs.jl `AbstractGraph`; layout via NetworkLayout.jl | General graph viz; no phylogenetic layouts |

### Notes on AbstractTrees.jl Compatibility

Only **D3Trees.jl** accepts any object satisfying the AbstractTrees.jl interface
for rendering — via the `D3Tree(node; ...)` transparent wrapper constructor.
No Julia-native (Plots.jl or Makie) visualization package accepts
AbstractTrees-compliant objects directly.

### Notes on Input Type Requirements

Every Julia-native or Julia-callable visualization path requires constructing a
package-specific type before plotting:

- Phylo.jl plot recipes: must have a `LinkTree`, `BinaryTree`, etc.
- PhyloPlots.jl: must have a `HybridNetwork`
- D3Trees.jl: must satisfy AbstractTrees interface (lowest barrier), but output
  is JavaScript/browser-only and requires internet access

There is no path from a generic Julia tree representation (e.g., a plain struct
with children pointers, an AbstractTrees-compliant object, or a Graphs.jl graph)
into a Julia-native graphical rendering of a phylogenetic tree.

---

## Gap

**No native Makie-based phylogenetic tree visualization package exists.**

Specifically:

- The only Julia-native phylogenetic visualization (Phylo.jl / Plots.jl) requires
  constructing Phylo-specific types; it has no Makie backend.
- The only visualization that accepts a generic AbstractTrees-compliant object
  (D3Trees.jl) is non-native JavaScript and requires an internet connection.
- PhyloPlots.jl (companion to PhyloNetworks.jl) delegates all rendering to R via
  RCall; it is non-native and requires a local R installation.
- The one Makie-native graph visualization package (GraphMakie.jl) is
  general-purpose, requires a Graphs.jl `AbstractGraph`, and provides no
  phylogenetic-specific layouts (cladogram, dendrogram, fan, radial) or
  annotation conventions (branch lengths, bootstrap values, hybrid edges).
- None of the phylogenetic tree data packages (PhyloNetworks.jl, Phylo.jl,
  Phylogenies.jl) implement Graphs.jl `AbstractGraph`, so GraphMakie cannot
  accept them directly.

**PhyloMakie.jl** addresses this gap: Makie-native recipes for phylogenetic tree
visualization, targeting the AbstractTrees.jl interface as the minimal input
contract — accepting any conforming tree type without requiring package-specific
deserialization.
