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

## Entries

### `axis_polarity`

**Part of speech:** noun (semantic concept); `LineageAxis` attribute name

**Definition:** The relationship between increasing process-coordinate values
and the direction of the modeled process. Has two values:

- `:forward` — increasing process coordinates move in the root-to-leaf
  direction (forward time). `lineageunits` values `:edgelengths`,
  `:branchingtime`, `:vertexdepths`, and `:vertexlevels` produce forward
  process coordinates (rootvertex = 0, increases toward leaves).
- `:backward` — increasing process coordinates move in the leaf-to-root
  direction (backward time, as in coalescent models). `lineageunits` values
  `:coalescenceage` and `:vertexheights` produce backward process coordinates
  (leaves = 0, increases toward root).

`axis_polarity` is a property of the data and the active `lineageunits` value,
not of the screen. It is distinct from `display_polarity`, which governs the
screen direction. A `:backward` process coordinate does not imply a reversed
plot; the two are independently settable.

`LineageAxis` infers a default `axis_polarity` from the active `lineageunits`
value and exposes it as an overridable attribute for axis labeling and
semantic documentation.

**Proscribed alternates:** conflating with `display_polarity`; `time_direction`,
`polarity`, `orientation`.

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
argument when `lineageunits = :branchingtime`, for cases where the user has a
vector of pre-computed divergence times and does not want to re-derive them
from per-edge lengths.

**Relationship to `lineageunits = :edgelengths`:** The `:edgelengths`
`lineageunits` value computes `branchingtime` on the fly by summing the
`edgelength` accessor along the path from `rootvertex`. The `:branchingtime`
`lineageunits` value bypasses that traversal and reads the value directly from
the `branchingtime` accessor. Both `lineageunits` values produce identical
vertex x-coordinates when the supplied times are consistent with the edge
lengths.

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
  when `lineageunits = :coalescenceage`.

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
argument when `lineageunits = :coalescenceage`.

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

### `display_polarity`

**Part of speech:** noun (rendering concept); `LineageAxis` attribute name

**Definition:** The mapping from process-coordinate values to screen direction
along the lineage axis. Has two values:

- `:standard` (default) — increasing process coordinates map to increasing
  screen position along `lineage_orientation` (right in `:left_to_right`
  orientation, up in `:bottom_to_top`). With forward axis polarity, this places
  the rootvertex at the left and leaves at the right.
- `:reversed` — increasing process coordinates map to decreasing screen
  position. Allows, for example, a forward-time tree to be drawn root-at-right
  (paleontological or stratigraphic convention), or a `:coalescenceage` tree to
  be drawn with the rootvertex at the left and leaves at the right.

`display_polarity` is independent of `axis_polarity`. The combination of the
two determines how the biological direction of the process maps to the screen.

**Proscribed alternates:** conflating with `axis_polarity`; `flip`, `invert`,
`reverse`, `reverse_axis`.

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

When `edgelength` is not supplied, layout defaults to
`lineageunits = :vertexheights` (leaf-aligned topology plot).

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
values). Used by the `:vertexheights` `lineageunits` value: all leaves have
height = 0, and each internal vertex has height = max(heights of children) + 1.
This naturally aligns all leaves at the same x-coordinate (the classic
cladogram appearance). `height` is the topological, unweighted analogue of
`coalescenceage`.

**Proscribed alternates:** `max_depth` (for tree-level height), `depth` (for
per-vertex height — these are now different concepts and `depth` is proscribed
entirely).

---

### `interval_schema`

**Part of speech:** noun (future capability); field name

**Definition:** A mapping from named intervals to axis coordinate ranges,
enabling visual elements to be placed by interval name rather than raw
coordinate. Geological timescales (epochs, periods, eras) are the motivating
example, but any named partition of the primary lineage axis qualifies.

An `interval_schema` value would map a symbol such as `:eocene` to a numeric
range on the `process_coordinate` axis, allowing annotations, background fills,
and overlays to be addressed by interval key. With two or more transverse
dimensions, intervals define cells in a coordinate lattice that can hold
arbitrary visual layers.

**Scope:** `interval_schema` is explicitly **Tier 4**. The term is recorded
here to reserve it and prevent incompatible uses in earlier tiers.

**Proscribed alternates:** `time_scale`, `epoch_map`, `interval_map`.

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

### `lineageunits`

**Part of speech:** noun (positioning concept); keyword argument name

**Definition:** The keyword argument that selects how vertex process coordinates
are determined during layout. Formerly referred to as `mode` in early design
drafts; renamed to `lineageunits` because `mode` is too generic to convey that
this keyword selects the unit and direction of the primary lineage axis.

The value of `lineageunits` determines which accessor is consulted to compute
the process coordinate (x in rectangular layouts, radial in circular) of each
vertex, and what `axis_polarity` `LineageAxis` infers:

- `:edgelengths` — cumulative edge lengths from rootvertex; requires `edgelength`
  accessor; `:forward` polarity.
- `:branchingtime` — pre-supplied branching times; requires `branchingtime`
  accessor; `:forward` polarity.
- `:coalescenceage` — pre-supplied coalescence ages; requires `coalescenceage`
  accessor; leaf = 0, increases toward root; `:backward` polarity.
- `:vertexdepths` — cumulative topological edge count from rootvertex; no
  accessor required; `:forward` polarity.
- `:vertexheights` — edge count to farthest leaf; leaves at 0; default when no
  `edgelength` accessor is supplied; `:backward` polarity.
- `:vertexlevels` — integer level from rootvertex; equal inter-level spacing;
  no accessor required; `:forward` polarity.
- `:vertexcoords` — user-supplied data coordinates; requires `vertexcoords`
  accessor; polarity is user-defined.
- `:vertexpos` — user-supplied pixel coordinates; requires `vertexpos` accessor;
  polarity is user-defined.

Default selection: `:edgelengths` if an `edgelength` accessor is supplied;
`:vertexheights` otherwise.

Written as one word without underscore, consistent with `edgelength`,
`coalescenceage`, `branchingtime`.

**Proscribed alternates:** `mode`, `positioning_mode`, `layout_mode`,
`layout_type`, `tree_mode`.

---

### `lineage_orientation`

**Part of speech:** noun (rendering concept); `LineageAxis` attribute name

**Definition:** How the primary lineage axis is embedded in the 2D scene.
Controls which screen axis corresponds to lineage progression and which
corresponds to the transverse (leaf-spacing) dimension.

Values:
- `:left_to_right` (default for rectangular layouts) — the lineage axis runs
  along the x-axis; the transverse axis is y; rootvertex is at the left by
  default.
- `:right_to_left` — lineage axis runs along x, transverse is y; rootvertex
  is at the right by default (use with `:standard` `display_polarity` and a
  leaf-relative `lineageunits` such as `:coalescenceage`, or with `:reversed`
  `display_polarity` and a root-relative `lineageunits` value).
- `:bottom_to_top` — lineage axis runs along y; transverse is x.
- `:top_to_bottom` — lineage axis runs along y inverted; classic dendrogram
  orientation.
- `:radial` (default for circular layouts) — lineage axis is the radial
  dimension; transverse axis is angular.

`lineage_orientation` defines which physical screen axis carries the process
coordinate. `display_polarity` then controls which end of that axis has the
smaller values.

**Proscribed alternates:** `orientation`, `direction`, `tree_direction`,
`axis_orientation`.

---

### `marker`

**Part of speech:** noun (visual concept)

**Definition:** The visual symbol rendered at a vertex position (circle, square,
diamond, etc.). Follows Makie's naming convention. In prose, "glyph" is an
acceptable synonym; in code, `marker` is the only permitted term.

**Proscribed alternates (in code):** `glyph`, `symbol`, `shape`.

---

### `process_coordinate`

**Part of speech:** noun (conceptual / documentation term)

**Definition:** The scalar value that positions a vertex along the lineage axis.
In any given plot, the process coordinate is determined by the active
`lineageunits` value: `branchingtime` values for `lineageunits = :branchingtime`
or `:edgelengths`, `coalescenceage` values for `lineageunits = :coalescenceage`,
topological edge counts for `:vertexlevels` / `:vertexdepths` / `:vertexheights`,
or user-supplied coordinates for `:vertexcoords` / `:vertexpos`.

This is a documentation and design term that unifies all `lineageunits` values
under a single concept. It does not appear as a code identifier (there is no
function or struct field named `process_coordinate`). When writing code, use
the specific accessor or `lineageunits` value.

`process_coordinate` is the concept that `axis_polarity` and `display_polarity`
operate on: `axis_polarity` describes the semantic direction of increasing
process-coordinate values; `display_polarity` describes their screen direction.

**Proscribed alternates (as a code identifier):** use specific accessor names
(`branchingtime`, `coalescenceage`, etc.).

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

### `transverse_axis`

**Part of speech:** noun (conceptual / documentation term)

**Definition:** The dimension perpendicular to the primary lineage axis, along
which leaves are spaced. In rectangular layouts with `:left_to_right`
orientation, this is the y-axis; in circular layouts it is the angular
dimension. Transverse placement is determined by layout algorithms and
controlled primarily by `leaf_spacing`.

This is a documentation term providing a consistent name for the concept across
layout types. It does not appear as a code identifier.

**Proscribed alternates (as a code identifier):** use `leaf_spacing` and
`leaf_order`.

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

## Layout `lineageunits`

| Symbol | Accessor required | x-coordinate source | Polarity | `axis_polarity` |
|---|---|---|---|---|
| `:edgelengths` | `edgelength` | Cumulative `edgelength(fromvertex, tovertex)` from `rootvertex`; computes `branchingtime` on the fly | Root = 0, increases toward leaves | `:forward` |
| `:branchingtime` | `branchingtime` | `branchingtime(vertex)` directly; user pre-supplies divergence times | Root = 0, increases toward leaves | `:forward` |
| `:coalescenceage` | `coalescenceage` | `coalescenceage(vertex)`; requires ultrametric tree (or `nonultrametric` policy) | Leaf = 0, increases toward root | `:backward` |
| `:vertexdepths` | none | Cumulative topological edge count from `rootvertex` (all edge weights = 1) | Root = 0, increases toward leaves | `:forward` |
| `:vertexheights` | none | Per-vertex height (edge count to farthest leaf); all leaves at x = 0; topological analogue of `:coalescenceage` | Leaf = 0, increases toward root | `:backward` |
| `:vertexlevels` | none | Integer level = edge count from `rootvertex`; equal spacing between levels; topological analogue of `:branchingtime` | Root = 0, increases toward leaves | `:forward` |
| `:vertexcoords` | `vertexcoords` | User-supplied `(x, y)` in data coordinates | User-defined | User-defined |
| `:vertexpos` | `vertexpos` | User-supplied `(x, y)` in pixel coordinates | User-defined | User-defined |

**Default `lineageunits`:** `:edgelengths` if an `edgelength` accessor is
supplied; `:vertexheights` otherwise.

**Polarity summary:** `lineageunits` values that are root-relative
(`:edgelengths`, `:branchingtime`, `:vertexdepths`, `:vertexlevels`) have
`:forward` `axis_polarity` and assign the root x = 0 increasing toward the
leaves. `lineageunits` values that are leaf-relative (`:coalescenceage`,
`:vertexheights`) have `:backward` `axis_polarity` and assign leaves x = 0
increasing toward the root. With the default `display_polarity = :standard`
and `lineage_orientation = :left_to_right`, forward `lineageunits` values
place leaves at the right; backward `lineageunits` values place the
rootvertex at the right.

## Compound-word naming convention

Compound accessor names and domain-specific identifiers in this package are
written without underscores when the compound reads naturally as a single
concept: `edgelength`, `vertexvalue`, `coalescenceage`, `branchingtime`,
`fromvertex`, `tovertex`, `rootvertex`, `boundingbox`, `lineageunits`. This is
consistent with
STYLE-julia.md §2.1, which permits omitting underscores when the name is not
hard to read.

Multi-word field names on structs retain underscores: `vertex_positions`,
`edge_paths`, `leaf_order`, `leaf_spacing`, `axis_polarity`, `display_polarity`,
`lineage_orientation`, `interval_schema`.
