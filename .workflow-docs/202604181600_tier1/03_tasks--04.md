# Tasks for Issue 4: `Geometry` — complete `lineageunits` stack and error modes

Parent issue: Issue 4
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `.workflow-docs/00-design/controlled-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

Canonical terms: `edgelength`, `branchingtime`, `coalescenceage`, `vertexdepths`,
`vertexheights`, `vertexlevels`, `vertexcoords`, `vertexpos`, `lineageunits`,
`fromvertex`, `tovertex`, `rootvertex`. Use these exactly in all identifiers and
documentation.

---

## Tasks

### 1. `:edgelengths` mode with missing and negative edge-length handling

**Type**: WRITE
**Output**: `rectangular_layout` with `lineageunits = :edgelengths` produces
correct cumulative-sum process coordinates; missing edges emit `@warn` and use
unit-length fallback; negative edges raise `ArgumentError`.
**Depends on**: none

Extend the `lineageunits` dispatch in `src/Geometry.jl` to handle `:edgelengths`.
For `:edgelengths`, perform a preorder traversal accumulating
`edgelength(fromvertex, tovertex)` from the rootvertex (rootvertex process
coordinate = 0.0). This computes `branchingtime` on the fly.

At each edge, evaluate `accessor.edgelength(fromvertex, tovertex)`. Handle three
cases: (1) the return value is `nothing` or `ismissing(v)` — emit `@warn` with a
message identifying the fromvertex and tovertex and use a fallback of 1.0 for
that edge; (2) the return value is negative — raise `ArgumentError` with a
message identifying the offending fromvertex, tovertex, and the negative value;
(3) normal positive `Float64` — use directly. The `(; value, units)` named-tuple
return form (PRD user story 5) must also be handled: if the return is a
`NamedTuple` with `value` and `units` fields, extract `value` (ignore `units` at
the geometry layer; unit conversion is not in scope for Tier 1 geometry).

Implement a private helper function for the preorder cumulative-sum traversal
that is shared between `:edgelengths` and `:branchingtime` (Task 2). Name it
something like `_cumulative_preorder` and make it accept a callable that maps
each vertex to its increment value, so the same traversal logic serves both
modes. Write a docstring on this helper explaining its contract.

---

### 2. `:branchingtime` and `:vertexdepths` modes, shared traversal

**Type**: WRITE
**Output**: `:branchingtime` and `:vertexdepths` modes produce correct process
coordinates; shared traversal helper is used by both `:edgelengths` (Task 1)
and `:branchingtime`.
**Depends on**: Task 1

Add `:branchingtime` to the `lineageunits` dispatch. For `:branchingtime`, the
process coordinate of each vertex is read directly from
`accessor.branchingtime(vertex)`. Raise `ArgumentError` if
`accessor.branchingtime` is `nothing` when this mode is requested. Use the
`_cumulative_preorder` helper from Task 1 by passing a callable that reads
`branchingtime` directly rather than summing edges.

Add `:vertexdepths` to the dispatch. For `:vertexdepths`, the process coordinate
is the integer edge count from the rootvertex (rootvertex = 0). This is a
preorder pass where each vertex's value is its parent's value plus one. This is
distinct from `:vertexlevels` (which uses equal inter-level spacing for display)
in that `:vertexdepths` is always integer-valued. Implement with a dedicated
private helper `_vertex_depths` that does a single preorder pass.

Confirm that `:vertexheights` (already implemented in Issue 3) and
`:vertexdepths` use distinct traversal helpers and are not accidentally aliased.
Both modes produce different results on non-binary trees: `:vertexheights` is the
path length to the farthest leaf; `:vertexdepths` is the path length from the
rootvertex.

---

### 3. `:coalescenceage` mode with `nonultrametric` keyword

**Type**: WRITE
**Output**: `:coalescenceage` mode produces correct leaf-relative process
coordinates on ultrametric trees; `nonultrametric = :error` raises
`ArgumentError`; `:minimum` and `:maximum` policies resolve inconsistency.
**Depends on**: Task 2

Add `:coalescenceage` to the `lineageunits` dispatch. For `:coalescenceage`, the
process coordinate of each vertex is read from
`accessor.coalescenceage(vertex)`, with leaves at 0 and internal vertices
increasing toward the rootvertex. Raise `ArgumentError` if
`accessor.coalescenceage` is `nothing` when this mode is requested.

Implement ultrametric validation: in a postorder traversal, for each internal
vertex, collect the `coalescenceage` values from all its children. If any two
children disagree (i.e., their `coalescenceage` values differ beyond a small
floating-point tolerance, say 1e-9), apply the `nonultrametric` policy: `:error`
(default) raises `ArgumentError` naming the vertex and the conflicting values;
`:minimum` uses the minimum of the child coalescence-age estimates; `:maximum`
uses the maximum. Add `nonultrametric` as a keyword argument to
`rectangular_layout` (and eventually `circular_layout`) with default `:error`.

Implement a private helper `_validate_ultrametric(accessor, rootvertex,
nonultrametric)` that performs this check and returns a `Dict` of resolved
process coordinates. Write a docstring on this helper. The `:minimum` and
`:maximum` policies must produce a consistent set of coordinates (no further
inconsistencies after resolution).

---

### 4. `:vertexcoords`, `:vertexpos` bypass modes and default `lineageunits` detection

**Type**: WRITE
**Output**: `:vertexcoords` and `:vertexpos` modes bypass layout and use
accessor-supplied coordinates directly; default `lineageunits` is inferred
correctly from accessor contents.
**Depends on**: Task 3

Add `:vertexcoords` to the dispatch. For `:vertexcoords`, the process coordinate
and transverse coordinate of each vertex are read directly from
`accessor.vertexcoords(vertex)` which returns a `Point2f`. No layout computation
is performed; `vertex_positions` is populated by iterating all vertices in
preorder and calling `vertexcoords`. The `edge_paths` are still constructed from
the positions using the right-angle segment logic. Raise `ArgumentError` if
`accessor.vertexcoords` is `nothing` when this mode is requested.

Add `:vertexpos` identically, but reading from `accessor.vertexpos`. The
difference is semantic (`:vertexcoords` is in data space; `:vertexpos` is in
pixel space); the geometry layer makes no distinction and stores both as
`vertex_positions` entries. Document this in the docstring.

Add default `lineageunits` detection at the entry point of `rectangular_layout`
(and `circular_layout` when that is implemented): if `lineageunits` is not
explicitly passed by the caller, check whether `accessor.edgelength` is not
`nothing`; if so, default to `:edgelengths`; otherwise default to
`:vertexheights`. This detection must happen before any traversal.

---

### 5. Extend `test/test_Geometry.jl` for all new modes and error paths

**Type**: TEST
**Output**: All new `test_Geometry` assertions green; no Aqua or JET regressions
introduced by any of Tasks 1–4.
**Depends on**: Task 4

Extend `test/test_Geometry.jl` with new `@testset` blocks for each mode added in
this issue. Use the same four tree fixtures as the initial slice.

Cover:
- `:edgelengths`: process coordinates equal cumulative sums from rootvertex on
  a tree with known edge lengths; leaves at expected values.
- `(; value, units)` return form: pass an `edgelength` function returning a
  named tuple and verify the `value` field is used.
- Missing edge length: use `@test_warn` to capture the warning and verify the
  fallback unit-length is used for that edge.
- Negative edge length: `@test_throws ArgumentError` with an `edgelength`
  function returning -1.0.
- `:branchingtime`: pass a `branchingtime` accessor returning known values and
  verify process coordinates match exactly.
- `:vertexdepths`: rootvertex at 0, leaves at max integer depth.
- `:coalescenceage` on an ultrametric tree: all leaves at 0.
- Non-ultrametric tree with `nonultrametric = :error`: `@test_throws
  ArgumentError`.
- Non-ultrametric tree with `nonultrametric = :minimum` and `:maximum`: no
  error; verify which estimate is chosen.
- `:vertexcoords`: `vertex_positions` matches the accessor output exactly.
- `:vertexpos`: same as `:vertexcoords` for the geometry layer.
- Default detection: construct an accessor with `edgelength` set; verify
  `rectangular_layout(root, acc)` (no `lineageunits` kwarg) uses `:edgelengths`.
- Default detection: accessor without `edgelength`; verify default is
  `:vertexheights`.

All tests deterministic. No external network.
