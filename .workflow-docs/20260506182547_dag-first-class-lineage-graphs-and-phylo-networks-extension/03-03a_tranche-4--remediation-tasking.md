---
date-created: 2026-05-08T19:05:00-07:00
status: approved
---

# Remediation Tasks for Tranche 4: Stable edge identity for rooted full-network `PhyloNetworks` support

Parent tranche: Tranche 4  
Parent PRD:
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`  
Superseded tranche-4 tasking for remaining work:
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-03_tranche-4--tasking.md`

Tasking identifier:
`20260508T190500--tranche-4-remediation-stable-edge-identity`

This file remediates the surviving tranche-4 defects after implementation
commit `395c73d`.

Revalidation against current `HEAD` on 2026-05-08 shows that the tranche-4
implementation is partially landed and the repo worktree is clean:

- the optional `PhyloNetworks.jl` extension boundary is live
- direct rooted full-network `HybridNetwork` plotting methods exist
- rooted-scope rejection exists
- vocabulary, README, docs, roadmap, and example migration already landed
- the remaining failure is not "missing tranche 4" but a contract bug in edge
  identity plus an incomplete proof surface

This remediation is intentionally narrower than the superseded tasking file. It
does not reopen already-landed vocabulary, docs, roadmap, or example migration
unless a source-level truth correction becomes unavoidable during the repair.

## Diagnosis of the prior failure

The implementation did not primarily fail because the earlier tasking was vague.
The earlier tasking was detailed, but it was incomplete and too restrictive in
one critical place:

- It required upstream `PhyloNetworks.jl` source rereading, including
  `auxiliary.jl`, but it did not convert the upstream 2-cycle contract into a
  tranche-4 lock item or a failing proof obligation.
- It explicitly kept `src/Geometry.jl` out of scope and explicitly blessed
  extension metadata keyed by exact upstream parent and child node objects.
  That pushed the implementer toward endpoint-pair identity even though valid
  rooted `HybridNetwork` inputs may contain two distinct hybrid edges with the
  same parent and the same child.
- It required `net1.out`, which is still a good rooted full-network fixture,
  but it did not require a duplicate-endpoint or 2-cycle fixture. That let the
  suite stay green while the implementation still merged parallel reticulation
  edges.
- It did not surface the second-order truth boundary that the current public
  accessor contract for `edgeweight(src, dst)` cannot distinguish two parallel
  edges with the same endpoints. That means duplicate-endpoint
  `lineageunits = :edgeweights` requests cannot be handled honestly by simply
  "looking up the right tuple" under the current accessor API.

Secondary execution miss:

- The implementing agent also failed to stop and escalate when the required
  upstream 2-cycle semantics conflicted with tuple-keyed runtime identity.
  This remediation removes that ambiguity by making the stop conditions and the
  surviving contract explicit.

## Corrections to the superseded tranche-4 tasking

The following parts of
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-03_tranche-4--tasking.md`
are superseded for the remaining work:

- The previous instruction that extension-local metadata may be keyed by exact
  upstream `(parent_node, child_node)` pairs is withdrawn. Endpoint-pair
  equality is not sufficient edge identity for rooted 2-cycles.
- The previous out-of-scope ban on `src/Geometry.jl` is withdrawn narrowly.
  `src/Geometry.jl` is now in scope for internal edge-order and docstring
  repair that keeps duplicate endpoint pairs honest. This is not authorization
  to redesign topology ownership or widen the public API.
- The previous assumption that direct `HybridNetwork`
  `lineageunits = :edgeweights` requests remain available unchanged is
  withdrawn for duplicate-endpoint networks. Under the current public accessor
  contract, those requests must either be proven unambiguous or must fail
  directly with an honest diagnostic.
- The previous `net1.out`-only render proof is withdrawn as sufficient
  verification. `net1.out` remains required, but it must be paired with a
  rooted 2-cycle regression.

## Settled decisions and environment baseline

- Current `HEAD` is commit `395c73d`.
- `src/Topology.jl` remains the owner of stable normalized edge identity via
  `NormalizedEdge.index`. This remediation must not redesign that owner.
- `src/Geometry.jl` remains the owner of geometry order. The repair may adjust
  internal geometry comments, helper inputs, or internal alignment surfaces so
  duplicate endpoint pairs remain selectable as distinct edges, but it must not
  reopen the topology owner or invent a second geometry owner.
- Existing public endpoint-pair surfaces remain preserved:
  `LineageGraphGeometry.edges` may continue to expose `(src, dst)` pairs, and
  existing endpoint-pair callback surfaces such as public per-edge color
  functions must not be replaced with opaque source-specific edge objects in
  this remediation.
- New settled clarification: for overlay and proof work, geometry-order edge
  position is authoritative when endpoint pairs repeat. Endpoint-pair equality
  is no longer allowed as the sole runtime edge identity for internal overlay
  selection.
- The tranche-3 annotation boundary remains fixed:
  `clade_nodes` and `NodeLabelLayer(position = :toward_parent)` stay tree-only;
  `group_nodes` and the `NodeGroup*` layers stay graph-capable.
- `PhyloNetworks.jl` remains an optional extension only. Do not add it to root
  `[deps]`, `docs/Project.toml`, or `examples/Project.toml`.
- Rooted full-network view remains the only tranche-4 `HybridNetwork` display
  contract. Major-tree projection, projected-tree view, semidirected display,
  and unrooted display remain deferred.
- Rooted default plotting remains `lineageunits = :nodelevels`.
- Node-based or explicit-coordinate direct requests remain available:
  `:nodelevels`, `:nodeheights`, `:nodedepths`, `:branchingtime`,
  `:coalescenceage`, `:nodecoordinates`, and `:nodepos` keep their settled core
  meanings.
- Corrected direct-weighted decision:
  direct `HybridNetwork` `lineageunits = :edgeweights` requests remain
  available only when the current public accessor boundary can represent the
  network honestly. Duplicate-endpoint rooted networks must fail directly with
  a diagnostic rather than collapsing two upstream edges into one tuple lookup.
- Vocabulary, README, docs, roadmap, and the tranche-4 example already landed.
  They are out of scope for this remediation unless the implementation cannot
  satisfy the existing public truth boundary honestly.

## Governance

Explicit line-by-line rereading remains mandatory before implementation. The
implementing agent must read and conform to:

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
- `design/design.md`
- `design/target-reference-capacities.md`
- `design/requirements-landscape-gap.md`
- `design/api-landscape.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-03_tranche-4--tasking.md`
- this remediation tasking file

Workflow authorities used for this remediation are `development-policies` and
`devflow-architecture-03--tranche-to-tasks`. Downstream implementation must
preserve their pass-forward requirements, especially explicit authority lists,
upstream-source naming, authorization boundaries, lock items, direct red-state
repros, and failure-oriented verification.

## Controlled vocabulary

- Keep the landed tranche-4 vocabulary in `STYLE-vocabulary.md`, including
  `hybrid node`, `reticulation edge`, `major edge`, `minor edge`,
  `gamma label`, and `major-tree projection`.
- Use `2-cycle` exactly as upstream defines it: two parallel hybrid edges from
  the same parent node to the same hybrid child node.
- Use `duplicate-endpoint edge` for the local implementation concern that two
  distinct normalized edges share the same `(src, dst)` endpoint pair.
- Do not call a merged duplicate-endpoint render "full-network support".

## Upstream primary sources and required local sources

Read these upstream sources line by line before implementation:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/types.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/auxiliary.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/readwrite.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/net_plot.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/plots/text.md`

Read these local owner and proof files line by line before implementation:

- `src/Topology.jl`
- `src/Geometry.jl`
- `src/Layers.jl`
- `ext/PhyloNetworksExt.jl`
- `test/test_Layers.jl`
- `test/test_PhyloNetworksExt.jl`
- `test/test_Integration.jl`
- `test/test_ExtensionBoundary.jl`

These sources settle the remaining truth boundary:

- `src/Topology.jl` already owns stable normalized edge identity.
- `src/Geometry.jl` currently preserves duplicate edges in order, but its
  public field documentation and downstream helper usage still encourage
  endpoint-pair equality as if it were unique identity.
- `PhyloNetworks.jl/src/auxiliary.jl` explicitly defines rooted 2-cycles as
  two parallel hybrid edges with the same parent and the same child.
- `PhyloNetworks.jl/src/readwrite.jl` and `getchildren(node)` semantics show
  that duplicate child nodes may appear once per incident edge, so the core
  topology owner can legitimately carry duplicate-endpoint edges.
- The current `LineageGraphAccessor.edgeweight(src, dst)` public contract is a
  node-pair accessor, not an edge-identity accessor. Duplicate-endpoint
  `:edgeweights` cannot be faked honestly under that contract.

## Revalidated current state and direct red-state repros

Current `HEAD` already contains the tranche-4 implementation surfaces, but the
remaining red state is specific and reproducible:

- `ext/PhyloNetworksExt.jl` currently stores runtime overlay metadata in
  `Dict{Tuple{PhyloNetworks.Node, PhyloNetworks.Node}, ...}`. Distinct parallel
  hybrid edges overwrite each other there.
- `ext/PhyloNetworksExt.jl` currently resolves `edgeweight(src, dst)` from that
  same tuple-keyed map, so duplicate-endpoint weighted requests silently lose
  one upstream edge.
- `src/Layers.jl` currently converts selected edges to `Set(selected_edges)` in
  `_edge_shape_subset` and `_edge_label_anchor_positions`, which collapses
  duplicate endpoint pairs during overlay selection and gamma-anchor lookup.
- `test/test_PhyloNetworksExt.jl` currently proves only the unique-endpoint
  `net1.out` fixture and derives expected overlay data from `geom` itself, so
  the tuple-collapse bug can survive with a green suite.

The most direct surviving bad behavior is:

- a valid rooted `HybridNetwork` with a 2-cycle will merge two distinct
  reticulation edges into one runtime identity for overlay metadata and
  edge-weight lookup
- a current green suite will not fail that implementation because `net1.out`
  does not exercise duplicate endpoint pairs

## Ownership and invariant framing

The owner under repair is the internal edge-identity contract spanning:

- geometry-order edge selection in `src/Layers.jl`
- geometry documentation and any narrow edge-order clarifications in
  `src/Geometry.jl`
- `PhyloNetworks` extension metadata and direct-entrypoint diagnostics in
  `ext/PhyloNetworksExt.jl`
- the tranche-4 proof surface in `test/`

The invariant being repaired is:

- every normalized edge that survives topology normalization must remain
  separately addressable by downstream overlay logic even when another edge has
  the same `(src, dst)` endpoints
- rooted full-network reticulation styling, gamma labels, and hybrid markers
  must reflect distinct upstream edges, not deduplicated endpoint tuples
- duplicate-endpoint `:edgeweights` requests must not pretend the current
  public accessor contract can distinguish both edges when it cannot

Supported public surfaces affected by this remediation are:

- `lineageplot(::PhyloNetworks.HybridNetwork; kwargs...)`
- `lineageplot!(::Axis, ::PhyloNetworks.HybridNetwork; kwargs...)`
- `lineageplot!(::LineageAxis, ::PhyloNetworks.HybridNetwork; kwargs...)`
- the existing public meaning of `LineageGraphGeometry.edges` and public
  endpoint-pair edge callbacks, which must remain preserved while the internal
  overlay path becomes duplicate-endpoint-safe

## Authorization boundary

Authorized for this remediation:

- `src/Layers.jl`
- narrow internal and docstring repair in `src/Geometry.jl`
- `ext/PhyloNetworksExt.jl`
- extension-aware and helper-aware tests in `test/`
- touched source docstrings if they are needed to keep the internal truth
  boundary honest

Not authorized for this remediation:

- redesigning `src/Topology.jl`
- changing the public `LineageGraphAccessor` callable shapes
- adding public plotting keywords or public view-mode selectors
- widening support to major-tree projection, projected-tree view,
  semidirected display, or unrooted display
- adding `PhyloNetworks.jl` to root, docs, or examples environments
- reopening already-landed tranche-4 README, docs, roadmap, vocabulary, or
  example surfaces unless the implementation cannot satisfy their current truth
  boundary honestly

## Primary-goal lock

### Lock 1: the extension remains optional and rooted-scope honest

- The work is not complete if the remediation hard-depends on
  `PhyloNetworks.jl`, weakens the extension-absence proof, or silently widens
  `HybridNetwork` support beyond rooted full-network view.
- Direct red-state repro:
  current `HEAD` already has the optional extension and rooted-scope rejection,
  and the repair must not regress them while fixing edge identity.
- Closing tasks: 2 and 3.
- Verification artifact:
  isolated extension-absence probe, activation in `--project=test`, and
  non-rooted direct-entrypoint rejection tests remain green.

### Lock 2: duplicate-endpoint normalized edges remain separately addressable

- The work is not complete if any runtime helper or overlay path still treats
  endpoint-pair equality as the sole identity for edge selection.
- Direct red-state repro:
  current `_edge_shape_subset` and `_edge_label_anchor_positions` collapse
  duplicate endpoint pairs through `Set(...)`, and current extension metadata
  collapses them through tuple-keyed dictionary overwrite.
- Closing tasks: 1 and 2.
- Verification artifact:
  a synthetic helper regression with duplicate `(src, dst)` entries and a
  rooted 2-cycle render regression must both fail the current `Set` and
  tuple-key implementation shape.

### Lock 3: direct rooted full-network `HybridNetwork` plotting stays real on all routed entrypoints

- The work is not complete if the implementation only patches helper internals
  but direct plotting still merges parallel reticulation edges or only works on
  one plotting surface.
- Direct red-state repro:
  current `lineageplot` and `lineageplot!` methods exist, but they are only
  proven on a unique-endpoint fixture and their overlay metadata is not
  duplicate-endpoint-safe.
- Closing tasks: 2 and 3.
- Verification artifact:
  direct plotting regressions on both `Axis` and `LineageAxis`, using both the
  rooted `net1.out` fixture and a rooted 2-cycle fixture, must stay green for
  the supported units.

### Lock 4: duplicate-endpoint weighted requests are handled honestly

- The work is not complete if `lineageunits = :edgeweights` on a rooted
  duplicate-endpoint network still silently chooses one partner edge, silently
  merges both partner edges, or pretends the current `edgeweight(src, dst)`
  boundary is sufficient.
- Direct red-state repro:
  current `_hybridnetwork_accessor` resolves `edgeweight(src, dst)` from a
  tuple-keyed edge map, so a rooted 2-cycle cannot be weighted honestly.
- Closing tasks: 2 and 3.
- Verification artifact:
  a rooted 2-cycle direct-entrypoint regression must fail with a direct
  ambiguity diagnostic for `:edgeweights`, while the existing unique-endpoint
  `net1.out` weighted-consistency proof remains green.

### Lock 5: reticulation styling and gamma semantics remain per-edge, not per-endpoint tuple

- The work is not complete if one parallel hybrid edge can overwrite the other
  edge's `gamma`, `ismajor`, or length-driven styling semantics.
- Direct red-state repro:
  current tuple-keyed metadata overwrite can collapse major/minor and gamma
  payloads for two different upstream edges that share one parent and one child.
- Closing tasks: 2 and 3.
- Verification artifact:
  rooted 2-cycle regressions must prove that both partner edges remain
  separately styled and separately label-addressable; a fake fix that reuses
  one edge's metadata for both partners must fail.

### Lock 6: the proof surface must fail the previously green-but-bad implementation

- The work is not complete if the suite still proves correctness only from
  `net1.out` or by deriving expectations from `geom` alone.
- Direct red-state repro:
  current tests can stay green while the duplicate-endpoint bug survives.
- Closing tasks: 1 and 3.
- Verification artifact:
  at least one regression must compare against direct upstream edge facts or an
  explicitly constructed expected per-edge sequence for a duplicate-endpoint
  fixture, not only against values produced by the same broken runtime helper.

### Lock 7: tree behavior, tranche-3 boundaries, and current docs truth stay green

- The work is not complete if the remediation regresses tree behavior, reopens
  tranche-3 annotation policy, or forces public docs truth changes because the
  code fix could not satisfy the already-landed tranche-4 contract.
- Direct red-state repro:
  current `HEAD` already has landed docs and a green tree or tranche-3 surface.
- Closing tasks: 1, 2, and 3.
- Verification artifact:
  `julia --project=test test/runtests.jl` stays green; existing weighted
  full-network rejections for non-duplicate DAGs remain green; public docs and
  example files stay untouched unless a truth-boundary rewrite becomes
  unavoidable, which is a stop condition for this remediation.

## Handoff packet

- Active authorities:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the bundled
  development-policies baseline, the four design documents, the parent PRD,
  the tranche file, the superseded tranche-4 tasking, and this remediation file
- Parent documents:
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
  and
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- Settled decisions and non-negotiables:
  rooted full-network only; optional extension only; duplicate-endpoint edges
  must remain distinct for overlays; duplicate-endpoint `:edgeweights` requests
  must fail honestly under the current accessor API; no new public controls; no
  topology-owner redesign
- Authorization boundary:
  `src/Layers.jl`, narrow `src/Geometry.jl`, `ext/PhyloNetworksExt.jl`, tests,
  and touched source docstrings only
- Current-state diagnosis:
  current tranche-4 code is largely landed, but it still merges parallel
  reticulation edges by tuple identity and lacks a proof surface that would
  catch that bug
- Primary-goal lock:
  lock items 1 through 7 above
- Direct red-state repros:
  tuple-keyed extension metadata; tuple-keyed `edgeweight(src, dst)` lookup;
  `Set(...)`-based helper selection; `net1.out`-only proof surface
- Owner and invariant under repair:
  internal edge-identity contract from normalized geometry order to extension
  overlays and diagnostics
- Exact files or surfaces in scope:
  `src/Layers.jl`, `src/Geometry.jl`, `ext/PhyloNetworksExt.jl`,
  `test/test_Layers.jl`, `test/test_PhyloNetworksExt.jl`,
  `test/test_Integration.jl`, `test/test_ExtensionBoundary.jl`,
  and touched source docstrings if necessary
- Exact files or surfaces out of scope:
  `src/Topology.jl`, public accessor signature redesign, public view-mode API,
  README/docs/ROADMAP/example rewrites, environment dependency changes, and
  unrelated integrations
- Required upstream primary sources:
  the `PhyloNetworks.jl` and Makie files named above
- Green-state gates:
  direct duplicate-endpoint helper regressions, rooted 2-cycle contract-level
  plotting regressions, existing extension-absence proof, non-rooted rejection,
  and `julia --project=test test/runtests.jl`
- Stop conditions:
  any honest fix that requires changing the public `LineageGraphAccessor`
  callable shapes, any need to widen docs truth beyond currently landed scope,
  any attempt to solve the bug by shrinking or deleting 2-cycles, or any need
  to reopen projection or unrooted policy

## Required revalidation before implementation

- Re-read the parent PRD, tranche file, superseded tranche-4 tasking, and this
  remediation tasking in full.
- Re-read the local owner files and test files listed above in full.
- Re-read the upstream primary sources listed above in full.
- Reconfirm from upstream source that:
  `getchildren(node)` emits one child entry per incident edge, and
  `auxiliary.jl` defines a 2-cycle as two parallel hybrid edges from the same
  parent to the same child.
- Reconfirm in the live code that current tuple-keyed extension metadata and
  `Set(...)`-based helper selection are still the active bug shape.
- Reconfirm that the current public accessor contract for `edgeweight` is still
  `(src, dst) -> ...`, so duplicate-endpoint `:edgeweights` cannot be patched
  honestly without either a direct diagnostic or an out-of-scope public API
  redesign.
- Re-run the code baseline before substantial edits:
  `julia --project=test test/runtests.jl`
- Do not widen scope to docs or examples unless the implementation proves the
  already-landed truth boundary cannot be satisfied, in which case stop and
  rewrite the tasking instead of improvising.

## Tranche execution rule

This remediation must begin from the already-landed tranche-4 code and finish
by removing the surviving edge-identity bug honestly.

When the remediation is complete:

- duplicate-endpoint rooted full-network overlays must remain per-edge, not
  per-endpoint tuple
- duplicate-endpoint rooted `:edgeweights` requests must fail honestly under
  the current accessor API instead of silently collapsing one edge into another
- the extension must still remain optional
- rooted full-network plotting must still work for supported units on both
  `Axis` and `LineageAxis`
- tree and tranche-3 behavior must still remain green

## Non-negotiable execution rules

- Do not add `PhyloNetworks.jl` to root `[deps]`, `docs/Project.toml`, or
  `examples/Project.toml`.
- Do not redesign `src/Topology.jl`.
- Do not change the public `LineageGraphAccessor.edgeweight` callable shape in
  this remediation.
- Do not replace public endpoint-pair callback surfaces with source-specific
  edge objects.
- Do not deduplicate `getchildren` results, shrink 2-cycles, delete minor
  edges, or otherwise "fix" the bug by simplifying the network before plotting.
- Do not use `Dict{Tuple{Node,Node}, ...}` or `Set{Tuple{Node,Node}}` as the
  sole runtime identity for duplicate-endpoint overlay selection.
- Do not silently keep `:edgeweights` green on duplicate-endpoint networks by
  picking one partner edge and ignoring the other.
- Do not reopen major-tree, projected-tree, semidirected, or unrooted policy.
- Do not move product logic into tests or replace the fix with proof-only
  assertions that still rely on the same broken tuple identity.

## Concrete anti-patterns or removal targets

- The tuple-keyed `_HybridNetworkOverlayMetadata.edge_metadata` shape must
  disappear or be demoted so it no longer overwrites parallel edges.
- The current `Set(selected_edges)` helper path must disappear or be demoted so
  duplicate endpoint pairs do not collapse during overlay selection.
- Any fake fix that makes the 2-cycle fixture "pass" by shrinking the cycle,
  deleting the minor edge, or uniquifying the child list is forbidden.
- Any fake fix that keeps `:edgeweights` available on duplicate-endpoint
  networks by returning one partner edge's length for both edges is forbidden.
- Any fake fix that keeps `net1.out` green while omitting a dedicated
  duplicate-endpoint proof is forbidden.

## Failure-oriented verification

- Keep the extension-absence proof green and the rooted-scope rejection green.
- Preserve the current unique-endpoint `net1.out` proof surface, but do not
  treat it as sufficient.
- Add a dedicated rooted 2-cycle fixture. Use the upstream-tested Newick string
  from `PhyloNetworks.jl/test/test_auxiliary.jl`:
  `((((((a:1)#H1:1::.9)#H2:1::.8)#H3:1::.7,#H3:0.5):1,#H2:1):1,(#H1:1,b:1):1,c:1);`
- Before relying on that fixture as a 2-cycle proof, add a regression that
  shows `PhyloNetworks.shrink2cycles!(deepcopy(net)) == true`, so the test
  fails if the fixture stops being a genuine 2-cycle in upstream semantics.
- Add at least one helper-level regression that uses a synthetic
  `LineageGraphGeometry` with duplicate `(src, dst)` entries and distinct edge
  shapes, so the old `Set(...)` helper would have collapsed them.
- Add at least one direct extension regression that proves a rooted 2-cycle
  keeps two distinct reticulation edges visible and separately styled.
- Add at least one direct extension regression that proves
  `lineageunits = :edgeweights` on the rooted 2-cycle fails with an ambiguity
  diagnostic instead of using one tuple lookup for both partner edges.
- Keep the existing unique-endpoint weighted-consistency failure path on
  `net1.out` or an equivalent unique-endpoint rooted network so the settled
  core validator still stays green.
- End the remediation with:
  `julia --project=test test/runtests.jl`

## Tasks

1. **Title**: Repair duplicate-endpoint helper selection to use geometry-order edge identity
   **Type**: `WRITE`
   **Output**: internal edge-selection helpers in `src/Layers.jl` consume
   geometry-order edge identity rather than endpoint-pair set membership, and
   `src/Geometry.jl` truthfully documents that duplicate endpoint pairs may
   occur while geometry-order position remains authoritative for internal
   overlay selection.
   **Depends on**: `none`
   **Positive contract**:
   `_edge_shape_subset` and `_edge_label_anchor_positions` become safe for
   duplicate `(src, dst)` entries; the helper boundary remains source-agnostic;
   existing public endpoint-pair callback surfaces remain preserved.
   **Negative contract**:
   do not redesign `src/Topology.jl`; do not change public plotting signatures;
   do not solve the problem by uniquifying `geom.edges`; do not keep
   `Set(selected_edges)` or any equivalent endpoint-only membership test on the
   duplicate-endpoint path.
   **Files**:
   `src/Layers.jl`, `src/Geometry.jl`, `test/test_Layers.jl`
   **Out of scope**:
   `ext/PhyloNetworksExt.jl`, README, docs, roadmap, examples, public view
   policy, and public accessor API redesign
   **Verification**:
   add a synthetic `LineageGraphGeometry` test with duplicate `(src, dst)`
   entries and distinct edge shapes or anchors that the old `Set(...)` helper
   would collapse; keep existing rectangular and radial helper regressions
   green; run `julia --project=test test/runtests.jl`.

2. **Title**: Repair `PhyloNetworks` overlay metadata and add an honest duplicate-endpoint `:edgeweights` diagnostic
   **Type**: `WRITE`
   **Output**: `ext/PhyloNetworksExt.jl` preserves distinct upstream hybrid-edge
   identity for overlays and gamma labels, and direct `HybridNetwork`
   `:edgeweights` requests fail explicitly on duplicate-endpoint rooted
   networks under the current accessor API instead of collapsing one partner
   edge into another.
   **Depends on**: `1`
   **Positive contract**:
   rooted full-network overlays use per-edge identity that survives duplicate
   endpoints; direct plotting remains live on `Axis` and `LineageAxis`; node-
   based and explicit-coordinate units stay supported; unique-endpoint
   `:edgeweights` requests continue routing into the settled core validator.
   **Negative contract**:
   do not use tuple-keyed metadata overwrite for runtime overlay identity; do
   not keep duplicate-endpoint `:edgeweights` available by picking one partner
   edge; do not shrink 2-cycles; do not add public accessor overloads or new
   public plotting keywords.
   **Files**:
   `ext/PhyloNetworksExt.jl`, `test/test_PhyloNetworksExt.jl`,
   `test/test_ExtensionBoundary.jl`, `test/test_Integration.jl`
   **Out of scope**:
   `src/Topology.jl`, README, docs, roadmap, examples, vocabulary, public
   accessor signature changes, and projection-policy work
   **Verification**:
   add direct regressions proving that duplicate-endpoint partner edges remain
   separately styled and separately label-addressable on a rooted 2-cycle, and
   add a direct `:edgeweights` ambiguity regression for that same fixture; keep
   the extension-absence probe and unique-endpoint weighted-consistency proofs
   green; run `julia --project=test test/runtests.jl`.

3. **Title**: Harden the tranche-4 proof surface so the current bad implementation cannot pass
   **Type**: `TEST`
   **Output**: the suite proves both the unique-endpoint `net1.out` contract
   and the rooted 2-cycle contract, and at least one regression fails the exact
   tuple-collapse shape currently present at `395c73d`.
   **Depends on**: `2`
   **Positive contract**:
   test expectations come from direct upstream edge facts, duplicate-endpoint
   fixture semantics, or explicitly constructed expected per-edge sequences
   rather than only from `geom` echoes; all supported direct plotting routes
   stay green; tree and tranche-3 behavior stay green.
   **Negative contract**:
   do not leave `net1.out` as the only network fixture; do not rely solely on
   helper output to prove its own correctness; do not accept any suite that can
   still pass with tuple-key overwrite or duplicate-endpoint `Set(...)`
   collapse alive.
   **Files**:
   `test/test_Layers.jl`, `test/test_PhyloNetworksExt.jl`,
   `test/test_Integration.jl`, `test/test_ExtensionBoundary.jl`
   **Out of scope**:
   code outside the repair path, public docs rewrites, examples rewrites, and
   new public APIs
   **Verification**:
   run `julia --project=test test/runtests.jl`; verify that the rooted 2-cycle
   fixture proves both separate reticulation-edge rendering and explicit
   duplicate-endpoint `:edgeweights` failure, while `net1.out` and existing
   tree or tranche-3 regressions remain green.

## Fresh-agent durability check

This remediation is durable only if the implementing agent can succeed without
reopening derivable decisions. The file already settles the remaining answers:

- the surviving defect is incomplete edge identity, not missing tranche-4
  docs or missing activation wiring
- endpoint-pair equality is not valid edge identity for rooted 2-cycles
- the helper path must stop using endpoint-only membership
- the extension must stop using tuple-keyed overwrite for overlay identity
- duplicate-endpoint `:edgeweights` requests must fail honestly under the
  current accessor API rather than pretending that tuple lookup is sufficient
- the proof surface must include both `net1.out` and a rooted 2-cycle fixture
- docs, roadmap, vocabulary, and example files are not part of the remaining
  work unless a truth-boundary failure forces tasking rewrite

If implementation discovers that the code cannot satisfy these settled answers
without changing the public accessor callable shapes or reopening public docs
truth, stop and rewrite the tasking instead of improvising.

No project code is changed by this document alone. The next workflow phase is
`Tasks -> Execute`.
