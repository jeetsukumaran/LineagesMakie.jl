---
date-created: 2026-05-07T03:02:16-07:00
date-revised: 2026-05-07T03:02:16-07:00
status: approved
---

# Tasks for Tranche 2: DAG-safe geometry owner and explicit weighted full-network policy

Tasking identifier: `20260507T030216--tranche-2-dag-geometry-tasking`

This file is the authoritative tranche-2 handoff after the tranche-1 topology
owner work and tranche-1 remediation boundary landed. A fresh implementation
agent should use this file, together with the parent PRD, tranche file,
tranche-1 tasking, and tranche-1 remediation tasking, as the governing
execution packet for DAG-safe geometry and explicit weighted full-network
policy work.

Parent tranche: Tranche 2
Parent PRD: `01_prd.md`
Prerequisite tranche tasking: `03_tranche-1--tasking.md`
Prerequisite remediation tasking: `03_tranche-1a--remediation-tasking.md`

## Settled user decisions and environment baseline

- DAG lineage graphs remain first-class in the core owner model. Rooted trees
  remain the single-parent special case inside that same owner path.
- `src/Topology.jl` remains the settled topology owner file. `src/Geometry.jl`
  remains the settled geometry owner file for this tranche. Do not split real
  geometry ownership across several new core files unless an explicit
  `REVIEW` gate reopens that decision.
- `LineageGraphGeometry` remains the existing geometry carrier. No field
  removal, field rename, exported API removal, signature break, or hidden
  public contract break is authorized in this tranche.
- The tranche file's `lineageunits` decisions remain authoritative:
  `:nodelevels`, `:nodedepths`, `:nodeheights`, `:nodecoordinates`, and
  `:nodepos` are tranche-2 DAG-safe units. `:edgeweights`,
  `:branchingtime`, and `:coalescenceage` require explicit full-network
  consistency and must not silently fall back to a hidden tree projection.
- `LineagesMakie.leaves` and `LineagesMakie.preorder` remain exported
  compatibility wrappers. Do not reopen tranche-1 topology-owner work in this
  tranche except for a minimal consistency repair that is strictly required by
  a listed verification artifact.
- `PhyloNetworks.jl` must remain an optional package extension. Do not add it
  to `[deps]`, do not move geometry ownership into `ext/`, and do not make
  source-specific network-view decisions the hidden owner of core layout
  semantics.
- No repo-owned public projection-selection API is authorized in this
  tranche. If honest implementation requires a new public view-mode or
  projection keyword, stop for explicit review instead of improvising one.
- No Tier 3 work is authorized here. Do not implement hybrid markers, gamma
  labels, major or minor reticulation styling, network view modes, or
  network-specific rendering primitives in this tranche.
- README, roadmap, and docs-site cleanup remain out of scope except for
  minimal touched-surface honesty and scoped example or proof-artifact updates
  required by task 4.
- Use the repository root project as the owning environment for core code.
- Use `test/Project.toml` and `docs/Project.toml` as the canonical test and
  docs environments.
- Do not rely on network access or registry downloads. Use the approved local
  upstream checkout root
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/`.
- No explicit `REVIEW` task is required at the current diagnosis. Stop for
  review only if a public `LineageGraphGeometry` break becomes necessary, if a
  new public projection-selection API becomes necessary, or if a derivable
  design decision in this file no longer matches the live codebase.

## Governance

Explicit line-by-line reading is mandatory before implementation. All
downstream work must read and conform to:

- `AGENTS.md`
- `CONTRIBUTING.md`
- `STYLE-agent-handoffs.md`
- `STYLE-architecture.md`
- `STYLE-docs.md`
- `STYLE-git.md`
- `STYLE-julia.md`
- `STYLE-makie.md`
- `STYLE-upstream-contracts.md`
- `STYLE-verification.md`
- `STYLE-vocabulary.md`
- `STYLE-workflow-docs.md`
- `STYLE-writing.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1a--remediation-tasking.md`
- this tasking file
- `design/design.md`
- `design/target-reference-capacities.md`
- `design/requirements-landscape-gap.md`
- `design/api-landscape.md`

The bundled style baseline under
`/home/jeetsukumaran/site/service/env/start/workhost/resources/packages/shared/workhost-resources/configure/coding-agent-skills/development-policies/references/`
was also read during this tasking run and remains byte-identical to the
repo-local `STYLE*.md` files above. Bundled `CONTRIBUTING.md` was not present
there, so repo-local `CONTRIBUTING.md` remains authoritative for contribution
guidance.

Workflow authorities used to produce this tasking were `development-policies`
and `devflow-architecture-03--tranche-to-tasks`. Downstream implementation
must preserve their pass-forward mandates, especially active-authority
restatement, exact upstream-source naming, exact authorization boundaries,
controlled vocabulary, primary-goal lock items, direct red-state repros, and
failure-oriented verification.

Upstream primary sources that must be read line by line for this tranche are:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/types.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/auxiliary.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/recursion_routines.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/compareNetworks.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/generic/space.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/makielayout/types.jl`

These sources constrain the tranche as follows:

- `PhyloNetworks.jl` confirms that nodes and edges are first-class upstream
  entities, that hybrid nodes may own several parent edges, and that
  full-network semantics must keep multi-parent incidence explicit rather than
  pretending one traversal path is the real owner.
- `PhyloNetworks.jl` traversal utilities use topological node order, parent
  vectors, and explicit hybrid handling. That reinforces the tranche
  requirement that shared ancestry is not a cycle and that any hidden
  single-parent projection must be an explicit policy choice rather than an
  owner-side accident.
- `PhyloNetworks.jl` comparison and major-tree utilities demonstrate that
  projected tree views are explicit upstream operations. This tranche may not
  smuggle an equivalent projection into core geometry as an unstated fallback.
- Makie layout and space guidance confirms that geometry handed to plotting and
  axis surfaces must keep its coordinate semantics explicit and stable.
  Recipes, layout wrappers, or plot composition do not justify hiding
  lineage-unit policy or edge identity drift behind downstream plotting code.

Controlled vocabulary from `STYLE-vocabulary.md` is mandatory. Use
`lineage graph`, `basenode`, `node`, `edge`, `topology owner`, `geometry
owner`, `compatibility wrapper`, `ownership boundary`, `package extension`,
`lock item`, `red-state repro`, `verification artifact`, `normalized
topology`, and `full-network view` consistently. Do not describe a hidden tree
projection as if it were DAG support.

Read-only git and shell commands may be used freely. Mutating git operations
such as commit, merge, push, rebase, reset, and branch creation remain the
human project owner's responsibility unless the user explicitly instructs
otherwise.

## Revalidated current state

- `src/Topology.jl` now exists and normalizes shared-descendant DAGs while
  retaining stable node order, parent incidence, child incidence, and edge
  order.
- `src/Accessors.jl` now routes `leaves` and `preorder` through the normalized
  topology owner, and those exported compatibility wrappers accept valid
  shared-descendant DAGs.
- `src/Geometry.jl` still routes generic layout through
  `require_tree_topology(...)` after normalization and still owns process,
  transverse, angular, and edge-shape construction through tree-native helper
  paths such as `_cumulative_preorder`, `_nodeheights`, `_nodelevels`,
  `_node_depths`, `_assign_transverse`, `_angular_positions`,
  `_build_edge_list`, and `_build_edge_shapes`.
- The current tranche-2 red state is no longer the old visited-set topology
  failure. It is that a shared-descendant DAG that already passes
  `normalize_topology` still fails `rectangular_layout` and `circular_layout`
  at the tree-only geometry guard even for DAG-safe units such as
  `:nodelevels`, `:nodedepths`, `:nodeheights`, `:nodecoordinates`, and
  `:nodepos`.
- The tranche-1 remediation repro also identified the anti-fix shape that must
  stay forbidden here: if the tree guard is merely removed without replacing
  the owner logic, asymmetric weighted shared-parent DAGs can fall into a
  last-parent overwrite path inside the tree-only accumulators.
- `LineageGraphGeometry.edges` remains a compatibility surface consumed by
  `Layers` as `(src, dst)` pairs. A DAG-safe owner rewrite must therefore keep
  stable edge identity and stable compatibility projection rather than letting
  edge order drift.
- `test/test_Geometry.jl` and `test/test_Integration.jl` still encode the
  tranche-1 honest-rejection boundary for shared-descendant DAG geometry and
  public plotting.
- No public projection-selection API, alternate geometry carrier, or scoped
  DAG example currently proves the tranche-2 contract.
- `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl` must be rerun at tranche start and
  tranche end. This tasking file does not claim a fresh green baseline on the
  basis of planning-time exploration alone.

## Primary-goal lock

### Lock 1: the generic geometry owner must stop being tree-only for DAG-safe units

- The work is not complete if a valid shared-descendant DAG still hits
  `require_tree_topology` or any equivalent tree-only guard when
  `lineageunits` is one of the DAG-safe units.
- Direct red-state repro: today the same shared-descendant DAG can normalize
  successfully and pass `leaves` or `preorder`, but
  `rectangular_layout(...; lineageunits = :nodelevels)` and
  `circular_layout(...; lineageunits = :nodepos)` still reject it at the
  geometry owner boundary before returning any layout.
- Closing tasks: 1 and 2.
- Verification artifact: direct geometry-owner tests must prove that those
  DAG-safe units now return geometry on a shared-descendant DAG, produce one
  geometry node per normalized node, and build one edge shape per normalized
  edge. A fake fix that merely bypasses the guard but still reconstructs
  authoritative geometry from raw traversal must fail because edge count, edge
  order, or shared-node placement drifts from normalized topology.

### Lock 2: DAG-safe lineage units must use explicit multi-parent semantics

- The work is not complete if `:nodelevels`, `:nodedepths`, `:nodeheights`,
  `:nodecoordinates`, or `:nodepos` still rely on one-parent or one-subtree
  assumptions when given a normalized DAG lineage graph.
- Direct red-state repro: today the tree-only guard prevents any proof that
  longest-path `:nodelevels`, shortest-path `:nodedepths`,
  farthest-descendant `:nodeheights`, or explicit coordinate passthrough for
  `:nodecoordinates` and `:nodepos` work on a shared-descendant DAG at all.
- Closing tasks: 1 and 2.
- Verification artifact: tests must prove exact semantics for those units on
  shared-descendant DAG fixtures and must fail a fake fix that arbitrarily
  chooses one parent path, double-counts a shared sink, or omits one of the
  normalized edges from rectangular or radial geometry.

### Lock 3: weighted full-network units must be explicit and honest

- The work is not complete if `:edgeweights`, `:branchingtime`, or
  `:coalescenceage` silently choose one parent path, silently invent a
  projected tree, or otherwise return weighted DAG geometry without proving
  full-network consistency.
- Direct red-state repro: today the current owner still lacks an explicit
  weighted DAG policy, so the same shared-descendant DAG cannot render under
  those units at all. The tranche-1 remediation history also proves the
  forbidden anti-fix shape: merely stripping the tree guard lets the later
  parent overwrite the shared node coordinate inside a tree-only accumulator.
- Closing tasks: 3 and 4.
- Verification artifact: direct weighted regressions must prove that
  consistent weighted DAG fixtures render through the normalized geometry owner
  while inconsistent `:edgeweights`, `:branchingtime`, and
  `:coalescenceage` fixtures fail with explicit full-network-view diagnostics.
  A fake fix that chooses one parent path or hides a tree projection must fail
  these proofs.

### Lock 4: rooted-tree behavior and public plotting surfaces must remain green

- The work is not complete if rooted-tree layout or plotting regresses while
  DAG-safe geometry support is added, or if public plotting surfaces keep
  lagging behind the core geometry contract.
- Direct red-state repro equivalent: this tranche touches the main geometry and
  plotting path, so an over-broad owner rewrite could easily break
  representative tree layout, `lineageplot!`, `lineageplot`, `Axis`
  integration, or `LineageAxis` integration even if DAG fixtures start
  passing.
- Closing tasks: 1 through 4.
- Verification artifact: existing representative rooted-tree geometry and
  plotting tests must remain green, and new DAG-safe plotting proofs must
  cover both mutating and non-mutating entrypoints on `Axis` and
  `LineageAxis`.

### Lock 5: stable edge identity must remain tied to normalized topology order

- The work is not complete if `LineageGraphGeometry.edges` stops corresponding
  to normalized-topology edge order or if layer consumers must infer hidden
  edge identity from a new traversal-side reconstruction.
- Direct red-state repro equivalent: today `Layers` consumes `geom.edges` as
  `(src, dst)` compatibility tuples. A naive DAG-safe rewrite could still
  return visually plausible output while silently reordering, duplicating, or
  dropping shared-descendant edges.
- Closing tasks: 1, 2, and 4.
- Verification artifact: geometry or layer-level tests must prove that
  `LineageGraphGeometry.edges` remains aligned to normalized topology edge
  order, that each normalized edge produces exactly one compatibility tuple and
  one shape, and that rooted-tree consumers continue to see stable edge tuples.

## Handoff packet

- Active authorities:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the four design
  documents, the parent PRD, the tranche file, the tranche-1 tasking, the
  tranche-1 remediation tasking, and this tranche-2 tasking file.
- Parent documents:
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`,
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`,
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1--tasking.md`,
  and
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1a--remediation-tasking.md`.
- Settled decisions and non-negotiables:
  core DAG topology ownership stays in `src/Topology.jl`; rooted trees remain
  the single-parent special case; tranche-2 DAG-safe units are
  `:nodelevels`, `:nodedepths`, `:nodeheights`, `:nodecoordinates`, and
  `:nodepos`; weighted full-network units must be explicit; `LineageGraphGeometry`
  may not break; `PhyloNetworks.jl` stays optional; no Tier 3 rendering or new
  public projection API is allowed here.
- Authorization boundary:
  deep internal redesign is authorized inside the geometry owner and tightly
  related compatibility surfaces named below, but public breaks, hidden
  projection policy, and tranche expansion remain out of bounds.
- Current-state diagnosis:
  topology normalization and compatibility wrappers are repaired, but the
  geometry owner still rejects DAG-safe units wholesale through a tree-only
  guard, weighted DAG policy is still absent, and public proofs still assert
  tranche-1 DAG rejection.
- Primary-goal lock:
  locks 1 through 5 above.
- Direct red-state repros:
  shared-descendant DAG succeeds through `normalize_topology` but
  `rectangular_layout(...; lineageunits = :nodelevels)` and
  `circular_layout(...; lineageunits = :nodepos)` still reject at the geometry
  owner boundary; if the guard is merely removed, the tranche-1 remediation
  repro shows the weighted anti-fix shape where a later parent overwrites the
  shared node coordinate; public tests still prove only DAG rejection.
- Owner and invariant under repair:
  the geometry owner must consume normalized topology as its authority for node
  order, edge order, and DAG-safe lineage-unit semantics, while weighted units
  must either prove full-network consistency or fail directly without hidden
  projection.
- Exact files or surfaces in scope:
  `src/Geometry.jl`, `src/Topology.jl`, `src/Layers.jl` and
  `src/LineageAxis.jl` only if compatibility plumbing or proof surfaces demand
  it, `test/test_Geometry.jl`, `test/test_Integration.jl`,
  `test/test_LineageAxis.jl`, `test/test_Layers.jl` only if edge-order proof
  is needed, and the scoped example files named in task 4.
- Exact files or surfaces out of scope:
  `ext/`, `Project.toml`, `src/Accessors.jl` except for a strictly required
  minimal consistency repair, `README.md`, `ROADMAP.md`, docs-site contract
  cleanup, annotation-owner redesign, Tier 3 rendering surfaces, and any new
  public projection-selection API.
- Required upstream primary sources:
  the `PhyloNetworks.jl` and Makie files listed in the governance section.
- Green-state gates:
  `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl`.
- Stop conditions:
  any required public break to `LineageGraphGeometry`, any need for a new
  public projection-selection API, any attempt to hide weighted DAG support
  behind a tree projection, any attempt to move geometry ownership into `ext/`
  or `PhyloNetworks`, any attempt to weaken tranche-1 topology proofs, or any
  material conflict between this tasking file and the live codebase.

## Required revalidation before implementation

- Read the parent PRD, the tranche file, the tranche-1 tasking, the tranche-1
  remediation tasking, and this tranche-2 tasking file in full.
- Read `src/Topology.jl`, `src/Geometry.jl`, `src/Layers.jl`,
  `src/LineageAxis.jl`, `test/test_Geometry.jl`, `test/test_Integration.jl`,
  `test/test_LineageAxis.jl`, `test/test_Layers.jl`, and the scoped example
  files named in task 4 in full.
- Re-read the `PhyloNetworks.jl` and Makie upstream primary sources named in
  the governance section before changing geometry or plotting-owner code.
- Re-run the shared-descendant DAG repro against current `HEAD` before
  editing. Confirm that topology normalization succeeds, that DAG-safe units
  still reject at the tree-only geometry boundary, and that the weighted
  last-parent-overwrite anti-fix is still only a forbidden historical shape
  rather than live supported behavior.
- Re-run `julia --project=test test/runtests.jl` at tranche start. If the live
  baseline is not green, stop and raise that before changing code.
- Re-run `julia --project=docs docs/make.jl` at tranche start if no fresher
  green evidence exists in the working session.
- Inspect `LineageGraphGeometry` consumer expectations in `Layers` and
  `LineageAxis` before changing edge ordering or geometry fields.
- Re-check the user-authorized disruption boundary before making deep
  geometry-owner changes.
- If a public break or new public projection-selection API seems necessary,
  stop for explicit review instead of proceeding.

## Tranche execution rule

This tranche may redesign, replace, or deeply refactor internal geometry
ownership where needed, but it must begin and end in a green, policy-compliant
state. It must convert the generic geometry owner from tree-only traversal
logic to normalized-topology-backed ownership for DAG-safe units, preserve the
rooted-tree success path through that same owner boundary, and add explicit
weighted full-network policy rather than a hidden tree projection.

When Tranche 2 is complete:

- `src/Geometry.jl` no longer treats `require_tree_topology` as the generic
  owner boundary for DAG-safe units
- the geometry owner consumes normalized node order, parent incidence, child
  incidence, sink order, and edge order from `src/Topology.jl`
- `:nodelevels`, `:nodedepths`, `:nodeheights`, `:nodecoordinates`, and
  `:nodepos` render valid shared-descendant DAGs without dropping or
  duplicating normalized edges
- `:edgeweights`, `:branchingtime`, and `:coalescenceage` either prove
  full-network consistency or fail directly with explicit diagnostics
- public plotting proofs and scoped examples reflect the tranche-2 contract
  instead of the tranche-1 rejection boundary

This tranche does not authorize a new public projection-selection API,
annotation-owner split, docs-site repositioning, or Tier 3 network rendering
features.

## Non-negotiable execution rules

- Do not keep `require_tree_topology` or an equivalent tree-only guard as the
  generic owner boundary for DAG-safe units.
- Do not reintroduce raw `preorder(accessor, basenode)` or
  `accessor.children(node)` traversal as the authoritative geometry owner once
  normalized topology is available.
- Do not solve DAG geometry by silently choosing one parent path, averaging
  inconsistent weighted paths, or hiding a major-tree fallback inside the
  owner.
- Do not break `LineageGraphGeometry`, `rectangular_layout`,
  `circular_layout`, `lineageplot!`, `lineageplot`, `Axis` integration, or
  `LineageAxis` integration without explicit review.
- Do not move geometry or weighted full-network policy into `ext/` or any
  `PhyloNetworks`-specific helper.
- Do not reopen the tranche-1 topology-owner repair except for a strictly
  necessary consistency touch.
- Do not implement hybrid markers, gamma labels, major or minor reticulation
  styling, network view modes, or source-specific network rendering primitives.
- Do not rewrite README, roadmap, or docs-site pages as if the later
  documentation tranche had already landed.
- Do not weaken rooted-tree behavior merely to make new DAG tests pass.

## Concrete anti-patterns or removal targets

- `require_tree_topology` as the real generic geometry owner for DAG-safe
  lineage units
- `_cumulative_preorder` or equivalent tree-only cumulative traversal as the
  weighted full-network owner for a normalized DAG lineage graph
- reverse-preorder-as-postorder logic or child-mean angular placement as an
  unstated DAG owner
- direct recursive child-walking as the owner of stable node identity or stable
  edge identity once normalized topology exists
- any surviving path that reconstructs edge order from raw traversal instead of
  consuming normalized-topology edge order
- any surviving public proof surface that only asserts "DAG rejected honestly"
  for tranche-2 DAG-safe units
- any hidden fallback from weighted DAG input to a projected tree or major-tree
  view

## Failure-oriented verification

- Add a direct shared-descendant DAG geometry regression for each DAG-safe
  lineage-unit family so the old `require_tree_topology` boundary fails
  immediately.
- Add explicit semantic proofs for longest-path `:nodelevels`, shortest-path
  `:nodedepths`, farthest-descendant `:nodeheights`, and explicit coordinate
  passthrough for `:nodecoordinates` and `:nodepos`.
- Add at least one negative weighted proof for each of `:edgeweights`,
  `:branchingtime`, and `:coalescenceage` that fails a fake fix choosing one
  parent path or hiding a tree projection.
- Add at least one positive weighted full-network proof that a consistent DAG
  fixture renders and preserves all normalized edges.
- Add explicit edge-order or edge-count proof that each normalized edge
  produces exactly one compatibility tuple and one geometry shape.
- Add public plotting proofs for both mutating and non-mutating entrypoints on
  `Axis` and `LineageAxis`.
- Keep at least one representative rooted-tree non-regression alongside the new
  DAG-safe proofs in the touched test surfaces.
- Use helper-level or metadata assertions only as supplementary proof. They do
  not replace behavior-level geometry, plotting, and weighted-consistency
  tests.
- Run `julia --project=test test/runtests.jl`.
- Run `julia --project=docs docs/make.jl`.

## Tasks

1. **Title**: Replace the tree-only geometry owner with a topology-backed DAG-safe owner for unweighted and explicit-coordinate units
   **Type**: `WRITE`
   **Output**: `rectangular_layout` and `circular_layout` consume
   `Topology.NormalizedTopology` as their authority for node order, sink order,
   parent incidence, child incidence, and edge order; they build one edge
   shape per normalized edge in normalized edge order; and they support
   DAG-safe `:nodelevels`, `:nodedepths`, `:nodeheights`,
   `:nodecoordinates`, and `:nodepos` without breaking rooted-tree behavior.
   **Depends on**: `none`
   **Positive contract**:
   the generic geometry path uses normalized topology as its authoritative
   owner, rooted trees remain the single-parent special case through that same
   owner path, and `LineageGraphGeometry.edges` stays aligned to normalized
   edge order while remaining a stable `(src, dst)` compatibility projection
   for existing layer consumers.
   **Negative contract**:
   no generic geometry path may still rely on `require_tree_topology`,
   `preorder(accessor, basenode)`, reverse-preorder-as-postorder logic, or raw
   `accessor.children(node)` loops as the authoritative owner for DAG-safe
   units; do not introduce a public `LineageGraphGeometry` break.
   **Files**:
   `src/Geometry.jl`, `src/Topology.jl`; `src/Layers.jl` and
   `src/LineageAxis.jl` only if compatibility plumbing is strictly required
   **Out of scope**:
   `ext/`, network-specific rendering primitives, annotation-owner redesign,
   README or docs-site cleanup, and any new public projection-selection API
   **Verification**:
   add shared-descendant DAG regressions that fail under the current tree-only
   guard and also fail a fake fix that reconstructs edges from raw traversal
   instead of normalized topology; prove that all normalized edges appear once
   in rectangular and radial geometry; run `julia --project=test
   test/runtests.jl`; run `julia --project=docs docs/make.jl`.

2. **Title**: Add the direct DAG geometry proof surface for topological and explicit-coordinate units
   **Type**: `TEST`
   **Output**: the current tranche-1 DAG-rejection tests are inverted for
   DAG-safe units, and the suite proves longest-path `:nodelevels`,
   shortest-path `:nodedepths`, farthest-descendant `:nodeheights`, plus
   full-edge rectangular and radial geometry for `:nodecoordinates` and
   `:nodepos`.
   **Depends on**: `1`
   **Positive contract**:
   shared-descendant DAG fixtures render all normalized edges for the DAG-safe
   units, rooted-tree fixtures keep their current geometry and orientation, and
   compatibility proofs show that edge tuples remain stable for downstream
   consumers.
   **Negative contract**:
   no tests may keep asserting generic DAG rejection after task 1 for those
   units; no proof may accept a fake fix that arbitrarily chooses one parent
   path, double-counts a shared sink, or omits one normalized edge.
   **Files**:
   `test/test_Geometry.jl`, `test/test_Integration.jl`,
   `test/test_LineageAxis.jl`; `test/test_Layers.jl` only if compatibility
   proof for edge ordering is needed
   **Out of scope**:
   weighted-unit failure semantics, annotation contract cleanup, Tier 3 view
   modes, and docs-site cleanup
   **Verification**:
   the updated tests must fail on the current `require_tree_topology`
   boundary, pass once task 1 is complete, and keep representative rooted-tree
   layout and plotting paths green; run `julia --project=test test/runtests.jl`.

3. **Title**: Implement explicit weighted full-network coordinate policy
   **Type**: `WRITE`
   **Output**: `:edgeweights` works only when additive path consistency is
   provable on the normalized topology; `:branchingtime` and
   `:coalescenceage` work only when the supplied node values are edgewise
   monotone and full-network consistent; otherwise geometry raises direct
   full-network-view diagnostics that name the missing explicit projection or
   consistency contract.
   **Depends on**: `2`
   **Positive contract**:
   consistent weighted DAG fixtures render through the same normalized geometry
   owner, rooted-tree weighted layouts remain green, and inconsistent fixtures
   fail before any silent last-parent overwrite or hidden projection can
   happen.
   **Negative contract**:
   do not reuse `_cumulative_preorder` as the weighted DAG owner; do not rely
   on tree-only ultrametric assumptions; do not invent a hidden major-tree
   fallback; do not reopen the tranche-resolved `lineageunits` semantics.
   **Files**:
   `src/Geometry.jl`, `src/Topology.jl` if weighted-consistency helpers belong
   there
   **Out of scope**:
   public projection-selection keywords, `PhyloNetworks` extension rendering,
   gamma labels, hybrid markers, annotation-owner changes, and docs-site
   cleanup
   **Verification**:
   add weighted regressions that fail the current no-policy boundary and fail
   the historical last-parent-overwrite anti-fix; prove that inconsistent
   `:edgeweights`, `:branchingtime`, and `:coalescenceage` DAG fixtures fail
   explicitly while consistent ones render; run `julia --project=test
   test/runtests.jl`; run `julia --project=docs docs/make.jl`.

4. **Title**: Migrate the public proof surfaces and scoped examples to the tranche-2 contract
   **Type**: `MIGRATE`
   **Output**: public plotting tests and scoped examples prove
   "DAG-safe units render; inconsistent weighted full-network units fail
   explicitly" instead of the tranche-1 honest-rejection boundary.
   **Depends on**: `3`
   **Positive contract**:
   `rectangular_layout`, `circular_layout`, `lineageplot!`, and `lineageplot`
   are covered on both `Axis` and `LineageAxis`; at least one DAG example or
   example-equivalent proof artifact shows full-edge rectangular and radial
   output; rooted-tree examples remain runnable.
   **Negative contract**:
   no example may claim full-network behavior while silently using a hidden
   tree projection; no stale tests may survive that only prove "DAG rejected
   honestly" for tranche-2 units; no scope creep into README, roadmap, or
   docs-site cleanup beyond touched-surface honesty.
   **Files**:
   `test/test_Geometry.jl`, `test/test_Integration.jl`,
   `test/test_LineageAxis.jl`, `examples/src/readme_quickstart.jl`,
   `examples/src/readme_features.jl`, `examples/src/lineageplot_ex2.jl`,
   and/or one new tranche-scoped DAG example file if that is the cleanest
   proof surface
   **Out of scope**:
   README or roadmap contract cleanup, tree-only annotation split, docs-site
   overhaul, and Tier 3 network primitives
   **Verification**:
   run `julia --project=test test/runtests.jl`; run
   `julia --project=docs docs/make.jl`; add failure-oriented tests that catch
   hidden projection and parent-path overwrite shapes; and prove through an
   example or render artifact that all normalized DAG edges are present in both
   rectangular and radial modes.
