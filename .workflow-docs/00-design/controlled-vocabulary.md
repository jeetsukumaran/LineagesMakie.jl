---
date-created: 2026-04-18T23:01:00
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

### `age`

**Part of speech:** noun (data concept)

**Definition:** The time value associated with a vertex. Represents when the
evolutionary or coalescent event at that vertex occurred. Age is non-negative:
`age = 0` conventionally means the present day (a leaf sampled in the present);
`age > 0` means the event occurred in the past (a fossil leaf or an internal
divergence). Edge length under the `:vertexages` positioning mode is derived as
`age(fromvertex) − age(tovertex)`.

**Accessor name:** `vertexage` (the callable that returns a vertex's age).

**Proscribed alternates:** `time`, `divergence_time` (acceptable in prose only),
`node_age`.

---

### `boundingbox`

**Part of speech:** noun (geometry concept); identifier

**Definition:** The smallest axis-aligned rectangle that encloses all
`vertex_positions` in a layout. Returned by `boundingbox(::TreeGeometry)`.
Written as one word without underscore.

**Proscribed alternates:** `bounding_box`, `extent`, `limits`, `bounds`.

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

### `color`

**Part of speech:** noun / attribute name

**Definition:** The color of any rendered element (edge, marker, text, etc.).
US spelling `color` is used throughout, matching Makie's API convention.

**Proscribed alternates:** `colour` (in any identifier, attribute name, or code
comment; acceptable in display-facing prose text only if the project owner
explicitly approves).

---

### `depth`

**Part of speech:** noun (measure)

**Definition:** The cumulative sum of `edgelength` values on the path from
`rootvertex` to a given vertex. For a vertex at the root, depth = 0. In the
`:edgelengths` positioning mode, a vertex's x-coordinate equals its depth.

Not to be confused with `height`, which measures distance downward toward
leaves.

**Proscribed alternates:** `distance_from_root`, `age` (different concept).

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

**Definition (tree-level):** The maximum `depth` of any vertex in the tree,
equivalently the depth of the deepest leaf.

**Definition (per-vertex):** The topological distance from a given vertex to
its farthest descendant leaf, measured in edge count (ignoring `edgelength`
values). Used by the `:vertexheights` positioning mode: all leaves have
height = 0, and each internal vertex has height = max(heights of children) + 1.
This naturally aligns all leaves at the same x-coordinate (the classic
cladogram appearance).

**Proscribed alternates:** `max_depth` (for tree-level height), `depth` (for
per-vertex height — these are different concepts).

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

### `vertexage`

**Part of speech:** noun (accessor name)

**Definition:** The callable `vertexage(vertex) -> Float64` returning the age
of a vertex (see `age`). Supplied as a keyword argument to layout functions when
using the `:vertexages` positioning mode. Written as one word without
underscore.

**Proscribed alternates:** `node_age`, `vertex_age`, `age_func`.

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

| Symbol | Accessor required | x-coordinate source |
|---|---|---|
| `:edgelengths` | `edgelength` | Cumulative `edgelength(fromvertex, tovertex)` from `rootvertex` |
| `:vertexages` | `vertexage` | `vertexage(vertex)`; edge extent = `vertexage(fromvertex) − vertexage(tovertex)` |
| `:vertexdepths` | none | Cumulative topological edge count from `rootvertex` (all edge weights = 1) |
| `:vertexheights` | none | Per-vertex height (edges to farthest leaf); all leaves at x = 0; produces leaf-aligned "cladogram" appearance |
| `:vertexlevels` | none | Integer level = edge count from `rootvertex`; equal spacing between levels; produces "dendrogram" appearance |
| `:vertexcoords` | `vertexcoords` | User-supplied `(x, y)` in data coordinates |
| `:vertexpos` | `vertexpos` | User-supplied `(x, y)` in pixel coordinates |

Default mode: `:edgelengths` if an `edgelength` accessor is supplied;
`:vertexheights` otherwise.

---

## Compound-word naming convention

Compound accessor names and domain-specific identifiers in this package are
written without underscores when the compound reads naturally as a single
concept: `edgelength`, `vertexvalue`, `vertexage`, `fromvertex`, `tovertex`,
`rootvertex`, `boundingbox`. This is consistent with STYLE-julia.md §2.1,
which permits omitting underscores when the name is not hard to read.

Multi-word field names on structs retain underscores: `vertex_positions`,
`edge_paths`, `leaf_order`, `leaf_spacing`.
