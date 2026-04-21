---
date-created: 2026-04-18T23:01:00
type: decision-log
subject: Controlled vocabulary — initial ratification
---

# Vocabulary decision log — 2026-04-18

This file records the full question table presented for ratification and the
user's responses verbatim. The resulting canonical terms are codified in
`VOCABULARY.md`, which is the authoritative
reference. The PRD at `.workflow-docs/202604181600_tier1/01_prd.md` has been
updated to reflect all ratified decisions.

---

## Controlled vocabulary — key terms

The table below summarises the ratified vocabulary. For full definitions,
forbidden alternates, and usage notes, see
`VOCABULARY.md`.

| Canonical | Definition (brief) | Proscribed alternates |
|---|---|---|
| `vertex` | Any element of the graph (root, internal, leaf) | `node` (as generic term) |
| `leaf` / `leaves` | Terminal vertex with no children | `tip` (proscribed), `terminal` |
| `edge` | Directed connection between two vertices | `branch` (code; prose acceptable) |
| `rootvertex` | Topmost vertex; has no parent | `root`, `root_vertex`, `seed` |
| `fromvertex` | Source/parent vertex in an edge | `parent`, `v1`, `src` |
| `tovertex` | Destination/child vertex in an edge | `child`, `v2`, `dst` |
| `edgelength` | Scalar measure on an edge; also the accessor callable | `branch_length`, `weight`, `len`, `edge_length` |
| `vertexvalue` | Callable: per-vertex data (bootstrap, name, etc.) | `nodevalue`, `node_value` |
| `vertexage` | Callable: vertex time value (age ≥ 0); used with `:vertexages` mode | — |
| `age` | Time value of a vertex; age = 0 is present; age > 0 is past | `time`, `divergence_time` |
| `depth` | Cumulative edge length from rootvertex to a given vertex | `distance_from_root` |
| `height` | Max depth of the tree; per-vertex: length to farthest leaf | `max_depth` |
| `boundingbox` | Smallest axis-aligned rectangle enclosing all vertex positions | `bounding_box`, `extent`, `limits` |
| `vertex_positions` | Dict mapping each vertex to its 2D layout coordinate | `node_positions` |
| `edge_shapes` | Geometric shapes for rendering edges | `edge_paths`, `branch_paths`, `segments` |
| `leaf_order` | Sequence of leaves along the transverse axis | `tip_order` |
| `leaf_spacing` | Inter-leaf spacing parameter; default `:equal` | `tip_spacing`, `gap` |
| `color` | Color of any rendered element (Makie convention) | `colour` |
| `marker` | Visual symbol placed at a vertex | `glyph` (code) |

---

## Original ratification table and user responses

### Group A — Core structural concepts

**Presented:**

| # | Concept | Proposed canonical | Reject / avoid | Decision needed? |
|---|---|---|---|---|
| A1 | Generic graph element | `vertex` | `node` (generic) | — |
| A2 | Outermost vertex | `tip` (proposed); `leaf` (AbstractTrees) | — | — |
| A3 | Internal (non-root, non-leaf) vertex | `internal vertex`; `node` in compound names? | `ancestor`, `clade` | Is `node` acceptable in compound names? |
| A4 | Root vertex | `root` | `root node`, `seed_vertex` | — |
| A5 | Directed connection | `edge` | `branch` (prose ok) | — |

**User responses:**

> A1/ OK
> A2/ OK
> A3/ No
> A4/ Use `rootvertex`

*Notes:* A3 "No" means `node` is not acceptable even in compound names — all
layer recipe names and struct field names must use `vertex` or `leaf` forms.
A2 "OK" was superseded by the explicit choices in E3/F3 (see below), which
confirmed `leaf` as the canonical term; `tip` is proscribed.

---

### Group B — Lengths and measures

**Presented:**

| # | Concept | Proposed canonical | Reject |
|---|---|---|---|
| B1 | Scalar quantity on an edge | `edge_length` | `branch_length`, `weight`, `len` |
| B2 | Accessor function name | `edge_length` | `edgelength`, `branch_length` |
| B3 | Cumulative root-to-vertex distance | `depth` | `distance_from_root`, `height` |
| B4 | Max depth | `height` | `depth`, `max_depth` |

**User responses:**

> B1/ Use `edgelength`
> B2/ Use `edgelength`
> B3/ OK
> B4/ OK

*Note:* User explicitly chose `edgelength` (no underscore) for both the concept
and the accessor name. This establishes a compound-word-no-underscore convention
for accessor names (shared with `vertexvalue`, `fromvertex`, `tovertex`,
`rootvertex`, `boundingbox`).

---

### Group C — Accessor names

**Presented:**

| # | Concept | Proposed canonical | Reject |
|---|---|---|---|
| C1 | Callable: children | `children` | `child_func`, `get_children` |
| C2 | Callable: edge length | `edge_length` | `edgelength`, `branch_length` |
| C3 | Callable: per-vertex data | `vertex_value` | `nodevalue`, `node_value` |
| C4 | Root vertex argument | `root` | `seed`, `seed_vertex` |
| C5 | Parent vertex in accessor signature | `parent` | `v1`, `src` |
| C6 | Child vertex in accessor signature | `child` | `v2`, `dst` |

**User responses:**

> C1/ OK
> C2/ Use `edgelength`
> C3/ Use `vertexvalue`; update the PRD
> C4/ Use `fromvertex`
> C5/ Use `tovertex`

*Note:* C4 and C5 renamed the accessor argument positions, not just the root
argument. `fromvertex` and `tovertex` are the canonical names for the two
parameters in `edgelength(fromvertex, tovertex)`.

---

### Group D — Visual / rendering

**Presented:**

| # | Concept | Proposed canonical | Reject |
|---|---|---|---|
| D1 | Visual symbol at vertex | `marker` (code); `glyph` (prose) | — |
| D2 | Color in code | `color` | `colour` |
| D3 | Color in prose/docs | `colour` | `color` |
| D4 | Scale bar extent | `length` | `width`, `size`, `len` |

**User responses:**

> D1/ OK
> D2/ OK
> D3/ Use `color`
> D4/ OK

*Note:* D3 changes the project convention from UK spelling to US `color`
throughout, matching Makie's API.

---

### Group E — Layer recipe names

**Presented:**

| # | Proposed canonical | Alternative |
|---|---|---|
| E1 | `BranchLayer` / `branchlayer!` | `EdgeLayer` / `edgelayer!` |
| E2 | `NodeLayer` / `nodelayer!` | `InternalVertexLayer` |
| E3 | `TipLayer` / `tiplayer!` | `LeafLayer` / `leaflayer!` |
| E4 | `TipLabelLayer` / `tiplabellayer!` | `LeafLabelLayer` / `leaflabellayer!` |
| E5 | `NodeLabelLayer` / `nodelabellayer!` | `VertexLabelLayer` / `vertexlabellayer!` |
| E6 | `CladeHighlightLayer` / `cladehighlightlayer!` | `CladeBackgroundLayer` |
| E7 | `CladeLabelLayer` / `cladelabellayer!` | — |

**User responses:**

> E1/ EdgeLayer/edgelayer!
> E2/ VertexLayer/vertexlayer!
> E3/ LeafLayer/leaflayer!
> E4/ LeafLabelLayer/leaflabellayer!
> E5/ VertexLabelLayer/vertexlabellayer!
> E6/ OK
> E7/ OK

---

### Group F — Geometry module fields

**Presented:**

| # | Concept | Proposed canonical | Alternative |
|---|---|---|---|
| F1 | Dict of 2D vertex positions | `vertex_positions` | `node_positions` |
| F2 | Collection of edge geometry | `edge_shapes` | `edge_paths`, `branch_paths` |
| F3 | Leaf sequence for layout | `tip_order` | `leaf_order` |
| F4 | Bounding rectangle | `bounding_box` | `boundingbox` |
| F5 | Cladogram positioning mode | `:cladogram` | — |
| F6 | Phylogram positioning mode | `:phylogram` | — |

**User responses:**

> F1/ `vertex_positions`; update PRD
> F2/ `edge_shapes`
> F3/ `leaf_order` is canonical
> F4/ `boundingbox` is canonical
> F5/ see discussion below
> F6/ see discussion below

---

### F5/F6 follow-up — layout positioning modes

**Question presented:** The `:cladogram`/`:phylogram` split is too
domain-specific and does not cover the full range of positioning mechanisms.
Proposed a taxonomy of data-driven vs. topology-computed modes.

**User response (verbatim):**

> 1/ Symbol: `:edgelengths`: (uses values from edgelength(vertex)
> 2/ Symbol: `:vertexages`; might need to think how this ties in with how the
>    values are communicated e.g. by using keyword arguments
>    f(...; ..., vertexage = vertex -> AbstractTrees.nodevalue(vertex).;
>    go ahead and support for `:vertexdepths`, `:vertexheights`, and
>    `:vertexlevels` as well, as these abstractions might have shared
>    implementation with :vertexage, but of course, these can be calculated
>    from the tree data.
> 3/ Is this needed or covered by :vertexdepths, :vertexheights, :vertexlevels
>    now?
> 4/ as (3) above?
> Also support `:vertexpos` and `:vertexcoords` for pixel and dataspace
> coordinates respectively: (I think these all work together so once DRY'd etc.
> they will all provide a deep stack supporting one and another as per
> STYLE-julia. I want this as concept to be reinforced in the PRD)

**Resolution:** Mode (3) ("topology level spacing") is subsumed by
`:vertexlevels`. Mode (4) ("cladogram staircase") is subsumed by
`:vertexheights`. No separate `:topology_*` modes required. Full ratified mode
set: `:edgelengths`, `:vertexages`, `:vertexdepths`, `:vertexheights`,
`:vertexlevels`, `:vertexcoords`, `:vertexpos`.

---

### Supplementary decisions (during follow-up)

**`tip` vs. `leaf`:**

> Canonical: `leaf`/`leaves`. NO `tip`. `Tip` is proscribed! There is no
> assumed "biological" sense.

**Compound accessor names without underscores:**

> Yes, these names are not hard to read for me

*Ratified convention:* Compound accessor names and domain-specific identifiers
in this codebase use no underscore: `edgelength`, `vertexvalue`, `coalescenceage`,
`branchingtime`, `fromvertex`, `tovertex`, `rootvertex`, `boundingbox`. This is
a deliberate style choice for this package, consistent with STYLE-julia.md §2.1
("underscores between words when the name would otherwise be hard to read").

---

## Vocabulary revision — 2026-04-19

### Background

The original ratification used `age` and `vertexage` for what was loosely
described as "the time value of a vertex". A follow-up discussion clarified
that two distinct concepts had been conflated, and that the prior term `depth`
was also imprecise. The revision below replaces both.

### Clarification of polarity and concept

**User statement:**

> When I say divergence time, I mean equivalent to sum of edge lengths in path
> to root, or "distance from root". When I say age, I mean "coalescent age",
> "distance from leaf" (only makes strictly defined if tree is ultrametric).

**Resolution:**

Two canonical concepts are now defined with unambiguous polarity:

| Canonical term | Accessor | Polarity | Definition |
|---|---|---|---|
| `branchingtime` | `branchingtime(v)` | Root = 0, increases toward leaves | Cumulative `edgelength` sum from `rootvertex` to `v`; "forward time" |
| `coalescenceage` | `coalescenceage(v)` | Leaf = 0, increases toward root | Cumulative `edgelength` sum from `v` down to leaf; "backward time"; requires ultrametric tree |

**Proscribed:** `age` (as identifier), `vertexage`, `depth`, `distance_from_root`,
`divergence_time` (as identifier; acceptable in prose only).

### Layout mode changes

`:vertexages` mode replaced by `:coalescenceage`.
`:branchingtime` added as a new mode (user supplies pre-computed divergence
times; the engine bypasses the on-the-fly summation that `:edgelengths` performs).

**Rationale for `:branchingtime` alongside `:edgelengths`:** Some users have a
vector of pre-computed divergence times and do not want to back-calculate edge
lengths. These are logically equivalent but sourced differently; having both
modes explicitly named makes the intent clear and avoids confusion.

### Relationship between modes

`:edgelengths` and `:branchingtime` produce identical vertex positions when the
supplied times are consistent with the edge lengths. `:coalescenceage` and
`:vertexheights` are leaf-relative counterparts: `:coalescenceage` is weighted
(requires ultrametric data), `:vertexheights` is topological (unweighted edge
counts).

For a strictly ultrametric tree:
`branchingtime(v) + coalescenceage(v) = branchingtime(deepest_leaf)`

### Non-ultrametric policy for `:coalescenceage`

`coalescenceage` is well-defined only for ultrametric trees. For non-ultrametric
trees, a `nonultrametric` keyword controls behavior: `:error` (default),
`:minimum`, `:maximum`.

Computation from edge lengths via post-order traversal:
`coalescenceage(v) = edgelength(v, c) + coalescenceage(c)` for any direct child
`c` (ultrametric guarantee: all children give the same value). For leaves,
`coalescenceage = 0`.
