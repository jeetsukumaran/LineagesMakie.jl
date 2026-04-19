---
date-created: 2026-04-18T23:01:00
date-revised: 2026-04-19T00:00:00
status: ratified
---

# Controlled vocabulary

This file is the authoritative terminology reference for LineagesMakie.jl.
All code, documentation, tests, issues, and pull requests must use the canonical
terms defined here. Proscribed terms must not appear in any identifier, type
name, function name, keyword argument, symbol, or field name.

**This list is not exhaustive and is not final.** Any agent, contributor, or
automated tool that needs to coin a new term, or is uncertain whether an
existing term applies, must raise the question with the project owner before
implementing anything. If a decision is made, this file must be updated with
explicit approval. No amendment or exception may be made unilaterally.

For the decision log and ratification history, see
`.workflow-docs/log.20260418T2301--vocabulary.md`.

---

## Entries

---

### `boundingbox`

**Part of speech:** noun (geometry concept); identifier

**Definition:** The smallest axis-aligned rectangle that encloses all
`vertex_positions` in a layout. Returned by `boundingbox(::TreeGeometry)`.
Written as one word without underscore.

**Proscribed alternates:** `bounding_box`, `extent`, `limits`, `bounds`.

---

### `branchingtime`

**Part of speech:** noun (data concept); accessor name

**Definition (concept):** The cumulative sum of `edgelength` values on the
directed path from `rootvertex` to a given vertex. Represents the total
evolutionary or temporal distance accumulated since the root. Also called
"divergence time" in phylogenetic prose.

- `branchingtime(rootvertex) = 0` by definition.
- `branchingtime(child) = branchingtime(parent) + edgelength(parent, child)`.
- Polarity: increases in the forward-time direction (root → leaves), i.e., the
  x-axis reads left = past, right = present for a standard chronogram.

**Definition (as accessor):** The callable `branchingtime(vertex) -> Float64`
returning a pre-computed branching time for a vertex. Supplied as a keyword
argument when using the `:branchingtime` positioning mode, for cases where the
user has a vector of pre-computed divergence times and does not want to
re-derive them from per-edge lengths.

**Relationship to `:edgelengths` mode:** The `:edgelengths` positioning mode
computes `branchingtime` on the fly by summing the `edgelength` accessor along
the path from `rootvertex`. The `:branchingtime` mode bypasses that traversal
and reads the value directly from the `branchingtime` accessor. Both modes
produce identical vertex x-coordinates when the supplied times are consistent
with the edge lengths.

**Relationship to `coalescenceage`:** `branchingtime` and `coalescenceage` have
opposite polarity. For a strictly ultrametric tree:
`branchingtime(v) + coalescenceage(v) = branchingtime(deepest_leaf)`.

**Proscribed alternates:** `depth`, `distance_from_root`, `divergence_time`
(acceptable in prose only), `node_age` (different concept).

---

### `children`

**Part of speech:** noun (accessor name)

**Definition:** The callable accessor `children(vertex) -> iterable` that
returns zero or more child vertices of the given vertex. The only required
accessor in the LineagesMakie input contract. A vertex for which `children`
returns an empty iterable is a leaf.

**Proscribed alternates:** `child_func`, `get_children`, `offspring`,
`descendants` (when meaning immediate children).

---

### `coalescenceage`

**Part of speech:** noun (data concept); accessor name

**Definition (concept):** The distance from a given vertex to the leaves,
measured in cumulative `edgelength` units. Represents the elapsed time since
the evolutionary or coalescent event at that vertex. Also called "coalescent
age" or "backward time" in phylogenetic prose.

- `coalescenceage(leaf) = 0` by definition; a leaf at the present has age zero.
- `coalescenceage(parent) = edgelength(parent, child) + coalescenceage(child)`
  for any direct child (ultrametric guarantee: all children give the same
  value).
- Polarity: increases in the backward-time direction (leaves → root), i.e., the
  x-axis reads left = distant past, right = present for a standard chronogram
  using `:coalescenceage` mode.

**Ultrametricity assumption:** `coalescenceage` is well-defined only for
ultrametric trees (all paths from any vertex to any of its leaf descendants have
equal total `edgelength`). For non-ultrametric trees, three policies are
available via a `nonultrametric` keyword argument:
- `:minimum` — use the minimum over all descendant paths to a leaf.
- `:maximum` — use the maximum over all descendant paths to a leaf.
- `:error` (default) — raise `ArgumentError` if any two children yield
  inconsistent values.

**Computation from edge lengths:** Can be computed in a post-order traversal:
leaves are assigned 0; each internal vertex is assigned
`edgelength(v, c) + coalescenceage(c)` for any child `c` (or resolved via
the `nonultrametric` policy).

**Definition (as accessor):** The callable `coalescenceage(vertex) -> Float64`
returning the pre-computed coalescence age for a vertex. Supplied as a keyword
argument when using the `:coalescenceage` positioning mode.

**Relationship to `branchingtime`:** See the `branchingtime` entry.

**Proscribed alternates:** `age` (as an identifier), `vertexage`,
`node_age`, `vertex_age`, `age_func`, `divergence_time` (different concept).

---

### `color`

**Part of speech:** noun / attribute name

**Definition:** The color of any rendered element (edge, marker, text, etc.).
US spelling `color` is used throughout, matching Makie's API convention.

**Proscribed alternates:** `colour` (in any identifier, attribute name, or code
comment; acceptable in display-facing prose text only if the project owner
explicitly approves).

---

### `edge`

**Part of speech:** noun (structural concept)

**Definition:** A directed connection from `fromvertex` to `tovertex`. In all
code identifiers, the term `edge` is used exclusively. In biological prose,
"branch" is acceptable but should not appear in any identifier, keyword
argument, type name, or symbol.

**Proscribed alternates (in code):** `branch`, `arc`, `link`, `connection`.

---

### `edgelength`

**Part of speech:** noun / accessor name

**Definition (as measure):** The scalar quantity associated with a directed
edge. Represents evolutionary distance, time span, or any analogous
non-negative quantity. Written as one word without underscore.

**Definition (as accessor):** The callable `edgelength(fromvertex, tovertex)`,
which returns either:
- a `Float64` value in data units, or
- a named tuple `(; value::Float64, units::Symbol)` with an explicit unit
  for conversion.

When `edgelength` is not supplied, layout defaults to the `:vertexheights` mode
(leaf-aligned topology plot).

**Proscribed alternates:** `branch_length`, `edge_length` (underscored),
`weight`, `len`, `w`.

---

### `edge_paths`

**Part of speech:** noun (geometry)

**Definition:** The collection of geometric paths (polylines, arcs, or segments)
that represent the visual shape of edges in a rendered layout. A field of
`TreeGeometry`. Written with underscore (a multi-word field name, not a
compound accessor name).

**Proscribed alternates:** `branch_paths`, `segments`, `paths`, `edge_segments`.

---

### `fromvertex`

**Part of speech:** noun (accessor argument)

**Definition:** The source (parent) vertex in a directed edge. First positional
argument of `edgelength(fromvertex, tovertex)` and any other edge-level
accessor. Written as one word without underscore.

**Proscribed alternates:** `parent`, `v1`, `src`, `from_vertex`.

---

### `height`

**Part of speech:** noun (measure); two related uses

**Definition (tree-level):** The maximum `branchingtime` of any vertex in the
tree, equivalently the `branchingtime` of the deepest leaf. For an ultrametric
tree, equals the `coalescenceage` of the `rootvertex`.

**Definition (per-vertex):** The topological distance from a given vertex to
its farthest descendant leaf, measured in edge count (ignoring `edgelength`
values). Used by the `:vertexheights` positioning mode: all leaves have
height = 0, and each internal vertex has height = max(heights of children) + 1.
This naturally aligns all leaves at the same x-coordinate (the classic
cladogram appearance). `height` is the topological, unweighted analogue of
`coalescenceage`.

**Proscribed alternates:** `max_depth` (for tree-level height), `depth` (for
per-vertex height — these are now different concepts and `depth` is proscribed
entirely).

---

### `leaf` / `leaves`

**Part of speech:** noun (role)

**Definition:** A vertex for which `children` returns an empty iterable. The
terminal/outermost vertex in a tree. In code, `leaf` (singular) and `leaves`
(plural or iterator). The AbstractTrees.jl interface uses the same term
(`Leaves`, `isleaf`), which confirms this choice.

There is no assumed biological sense. A "leaf" is simply a vertex with no
children.

**Proscribed alternates:** `tip` (proscribed in all contexts — code,
identifiers, comments, and documentation), `terminal`, `taxa` (plural),
`leaf_node`.

---

### `leaf_order`

**Part of speech:** noun (geometry)

**Definition:** The ordered sequence of leaves as they appear along the
transverse axis of a layout (y-axis in rectangular layouts; angular position
in circular layouts). A field of `TreeGeometry`.

**Proscribed alternates:** `tip_order`, `leaf_sequence`, `leaf_rank`.

---

### `leaf_spacing`

**Part of speech:** noun / keyword argument

**Definition:** The spacing between adjacent leaves along the transverse axis.
Keyword argument to layout functions. Default value `:equal` distributes leaves
evenly. A positive `Float64` value sets an explicit inter-leaf distance in
layout units.

**Proscribed alternates:** `tip_spacing`, `gap`, `interval`, `spacing`
(unqualified).

---

### `marker`

**Part of speech:** noun (visual concept)

**Definition:** The visual symbol rendered at a vertex position (circle, square,
diamond, etc.). Follows Makie's naming convention. In prose, "glyph" is an
acceptable synonym; in code, `marker` is the only permitted term.

**Proscribed alternates (in code):** `glyph`, `symbol`, `shape`.

---

### `rootvertex`

**Part of speech:** noun (role); keyword argument name

**Definition:** The unique vertex with no parent; the starting point of tree
traversal. Passed as the first positional argument to `lineageplot`,
`rectangular_layout`, `circular_layout`, and related functions. Written as one
word without underscore.

**Proscribed alternates:** `root`, `root_vertex`, `seed`, `seed_vertex`,
`source`, `origin`.

---

### `tovertex`

**Part of speech:** noun (accessor argument)

**Definition:** The destination (child) vertex in a directed edge. Second
positional argument of `edgelength(fromvertex, tovertex)` and any other
edge-level accessor. Written as one word without underscore.

**Proscribed alternates:** `child`, `v2`, `dst`, `to_vertex`.

---

### `vertex` / `vertices`

**Part of speech:** noun (structural concept)

**Definition:** Any element of the graph: the `rootvertex`, any internal
vertex, or any `leaf`. The generic term for a graph element. `vertices` is
the plural. In compound role-specific names, use the role term directly
(`leaf`, `rootvertex`, `internal vertex` in prose) rather than `node`.

**Proscribed alternates (as a generic term):** `node`. The word `node` must not
appear as a generic synonym for `vertex` in any identifier, field name, keyword,
type name, or symbol.

---

### `vertex_positions`

**Part of speech:** noun (geometry)

**Definition:** A `Dict` (or equivalent) mapping each vertex to its 2D
coordinate `Point2f` in layout space. A field of `TreeGeometry`. Written with
underscore (multi-word field name).

**Proscribed alternates:** `node_positions`, `positions` (unqualified),
`coords`.

---

### `vertexvalue`

**Part of speech:** noun (accessor name)

**Definition:** The callable `vertexvalue(vertex) -> Any` returning arbitrary
per-vertex data: bootstrap support, posterior probability, taxon name, age, or
any domain value. Used by label and color-mapping layers. Written as one word
without underscore.

**Proscribed alternates:** `nodevalue`, `node_value`, `vertex_value`
(underscored), `get_node_data`.

---

## Layer recipe names

| Canonical recipe type | Canonical function | Former name (proscribed) |
|---|---|---|
| `EdgeLayer` | `edgelayer!` | `BranchLayer`, `branchlayer!` |
| `VertexLayer` | `vertexlayer!` | `NodeLayer`, `nodelayer!` |
| `LeafLayer` | `leaflayer!` | `TipLayer`, `tiplayer!` |
| `LeafLabelLayer` | `leaflabellayer!` | `TipLabelLayer`, `tiplabellayer!` |
| `VertexLabelLayer` | `vertexlabellayer!` | `NodeLabelLayer`, `nodelabellayer!` |
| `CladeHighlightLayer` | `cladehighlightlayer!` | — |
| `CladeLabelLayer` | `cladelabellayer!` | — |
| `ScaleBarLayer` | `scalebarlayer!` | — |
| `LineagePlot` | `lineageplot!` | — |

---

## Layout positioning modes

| Symbol | Accessor required | x-coordinate source | Polarity |
|---|---|---|---|
| `:edgelengths` | `edgelength` | Cumulative `edgelength(fromvertex, tovertex)` from `rootvertex`; computes `branchingtime` on the fly | Root = 0, increases toward leaves |
| `:branchingtime` | `branchingtime` | `branchingtime(vertex)` directly; user pre-supplies divergence times | Root = 0, increases toward leaves |
| `:coalescenceage` | `coalescenceage` | `coalescenceage(vertex)`; requires ultrametric tree (or `nonultrametric` policy) | Leaf = 0, increases toward root |
| `:vertexdepths` | none | Cumulative topological edge count from `rootvertex` (all edge weights = 1) | Root = 0, increases toward leaves |
| `:vertexheights` | none | Per-vertex height (edge count to farthest leaf); all leaves at x = 0; topological analogue of `:coalescenceage` | Leaf = 0, increases toward root |
| `:vertexlevels` | none | Integer level = edge count from `rootvertex`; equal spacing between levels; topological analogue of `:branchingtime` | Root = 0, increases toward leaves |
| `:vertexcoords` | `vertexcoords` | User-supplied `(x, y)` in data coordinates | User-defined |
| `:vertexpos` | `vertexpos` | User-supplied `(x, y)` in pixel coordinates | User-defined |

**Default mode:** `:edgelengths` if an `edgelength` accessor is supplied;
`:vertexheights` otherwise.

**Polarity summary:** Modes that are root-relative (`:edgelengths`,
`:branchingtime`, `:vertexdepths`, `:vertexlevels`) assign the root x = 0 and
increase toward the leaves, so leaves appear to the right. Modes that are
leaf-relative (`:coalescenceage`, `:vertexheights`) assign leaves x = 0 and
increase toward the root, so the root appears to the right. Both conventions
are standard in different phylogenetic contexts; the mode name makes the
polarity unambiguous.

---

## Compound-word naming convention

Compound accessor names and domain-specific identifiers in this package are
written without underscores when the compound reads naturally as a single
concept: `edgelength`, `vertexvalue`, `coalescenceage`, `branchingtime`,
`fromvertex`, `tovertex`, `rootvertex`, `boundingbox`. This is consistent with
STYLE-julia.md §2.1, which permits omitting underscores when the name is not
hard to read.

Multi-word field names on structs retain underscores: `vertex_positions`,
`edge_paths`, `leaf_order`, `leaf_spacing`.
