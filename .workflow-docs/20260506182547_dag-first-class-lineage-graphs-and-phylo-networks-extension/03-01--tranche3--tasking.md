---
date-created: 2026-05-07T23:20:43-07:00
date-revised: 2026-05-08T00:10:30-07:00
status: approved
---

# Tasks for Tranche 3: graph-capable annotation owner and DAG-first contract cleanup

Tasking identifier:
`20260507T232043--tranche-3-annotation-owner-and-contract-cleanup-tasking`

This file operationalizes tranche 3 from
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
against current `HEAD`.

It preserves the parent PRD and tranche decisions, but it does not inherit
their original start-state diagnosis blindly. Revalidation against the current
repository shows that the tranche-3A immediate-action packet has already
landed: tree-only annotation boundary guards and the minimal touched-surface
docs honesty are now baseline, not remaining tranche-3 work.

The remaining tranche-3 work is the actual graph-capable annotation-owner
split, the shared annotation-layout integration for that owner, and the
broader public contract, vocabulary, roadmap, docs, and example cleanup that
must follow from a DAG-first core.

The former public-contract `REVIEW` gate is now closed by the ratified
sidecar artifact
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01a--tranche3--annotation-contract-ratification.md`.
This tasking file now assumes that ratified split directly.

Parent tranche: Tranche 3  
Parent PRD:
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`  
Ratified contract artifact:
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01a--tranche3--annotation-contract-ratification.md`  
Completed prerequisites: Tranche 1, Tranche 2, and
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2e--annotation-boundary-guard-tasking.md`

## Settled decisions and tranche baseline

- DAG lineage graphs remain first-class in the core owner model.
- Rooted trees remain the single-parent special case within the same owner
  path.
- The tranche-3A tree-only boundary guards in `src/Layers.jl` are current
  baseline behavior. Do not reopen, weaken, or silently bypass them.
- Ratified tree-only surfaces remain unchanged and permanently bounded:
  `CladeHighlightLayer(clade_nodes = [...])`,
  `CladeLabelLayer(clade_nodes = [...])`, and
  `NodeLabelLayer(position = :toward_parent)` remain explicit tree-only
  surfaces and must continue to throw on DAG displays.
- Ratified already-graph-safe surfaces remain unchanged:
  `NodeLabelLayer(position = :node)` and `LeafLabelLayer`.
- Ratified Option A graph-capable surfaces are:
  `NodeGroupHighlightLayer`,
  `nodegrouphighlightlayer!(ax, geom, accessor; group_nodes = [...], kwargs...)`,
  `NodeGroupLabelLayer`, and
  `nodegrouplabellayer!(ax, geom, accessor; group_nodes = [...], label_func = ..., kwargs...)`.
- The ratified additive `LineagePlot` keyword family uses shared selector
  `group_nodes`, plus `nodegroup_highlight_*` and `nodegroup_label_*`
  namespaced keywords.
- No source-specific `PhyloNetworks.jl` shadow owner is allowed. DAG-capable
  annotation ownership must remain package-owned and source-agnostic.
- No hidden projection default, arbitrary-parent fallback, subtree-shaped
  expansion, or nested `group_nodes` reinterpretation may stand in for the
  ratified graph-capable annotation contract.
- Any externally visible breaking change still requires explicit user approval
  and a migration note in the same tranche.
- No explicit `REVIEW` task remains at the current diagnosis. Stop only if
  honest implementation would require reopening the ratified Option A split.

## Governance and required reading

Read line by line before implementation:

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
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2c--final-audit.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2e--annotation-boundary-guard-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01a--tranche3--annotation-contract-ratification.md`
- this tasking file

Re-read in full as part of current-state revalidation:

- `src/Layers.jl`
- `src/LineageAxis.jl`
- `src/LineagesMakie.jl`
- `README.md`
- `ROADMAP.md`
- `docs/src/index.md`
- `examples/src/shared_descendant_dag_ex1.jl`
- `examples/src/readme_features.jl`
- `test/test_Layers.jl`
- `test/test_Integration.jl`
- `test/test_LineageAxis.jl`

Bundled development-policies references were rechecked for this tasking run.
The bundled `STYLE*.md` baseline remains aligned with the repo-local stack
above. Bundled `CONTRIBUTING.md` remains absent, so repo-local
`CONTRIBUTING.md` remains authoritative.

## Controlled vocabulary

- Continue using the parent PRD vocabulary that treats DAG as the core case and
  rooted tree as the single-parent special case.
- For tranche 3, the public contract now fixes the exact graph-capable API
  names `NodeGroupHighlightLayer`, `NodeGroupLabelLayer`, `group_nodes`,
  `nodegroup_highlight_*`, and `nodegroup_label_*`.
- The reader-facing vocabulary must distinguish at least:
  `tree view`, `full-network view`, `tree-only annotation surface`,
  `graph-capable annotation surface`, `node group`, and `group annotation`.
- Do not describe tranche-4 or extension work as an `adapter` project. The
  extension adapts upstream types into a package-owned core; it is not the
  owner of DAG support.
- `STYLE-vocabulary.md` does not yet canonically define the graph-capable
  annotation vocabulary above. Revised task 1 owns codifying that vocabulary
  under the ratified split.

## Upstream primary sources

Read these primary sources line by line before implementation:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/generic/space.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/plots/text.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/makielayout/types.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/net_plot.md`

These sources remain mandatory here because:

- Makie recipe guidance constrains where the graph-capable annotation owner
  should normalize its semantics and how public recipe contracts are expressed.
- Makie `space` and text behavior constrain highlight and label placement
  semantics, especially where annotation extents must cooperate with shared
  layout.
- Makie layout ownership constrains how `LineageAxis` should continue owning
  annotation lanes and decorative extents.
- `PhyloNetworks.jl` network plotting docs remain the relevant upstream
  authority for the distinction between full-network displays and explicit tree
  or projection views.

## Revalidated current state

- Tranche 1 and tranche 2 foundational work is present in current `HEAD`.
  Topology normalization, DAG-safe geometry ownership, weighted full-network
  honesty, `leaf_order`, and the package-extension boundary are not the work
  of this tranche anymore.
- The tranche-3A truth-boundary repair has also landed. Current `src/Layers.jl`
  rejects `NodeLabelLayer(position = :toward_parent)` and `clade_nodes`
  subtree surfaces on shared-parent DAG displays, and current tests in
  `test/test_Layers.jl` and `test/test_Integration.jl` cover those direct
  failures.
- Current `NodeLabelLayer(position = :node)` and `LeafLabelLayer` are already
  graph-safe and align with the ratified unchanged surfaces.
- Because those guards are now present, tranche 3 no longer begins from the
  original red state described in the parent tranche file. It begins from an
  honest but incomplete state: tree-only surfaces are now bounded correctly,
  but no graph-capable annotation owner has been added yet.
- There is still no explicit graph-capable `NodeGroupHighlightLayer` or
  `NodeGroupLabelLayer` in the public layer inventory, no canonical vocabulary
  for those surfaces in `STYLE-vocabulary.md`, and no public example that
  demonstrates DAG-capable annotation honestly.
- No conflicting `NodeGroup*` public names or `group_nodes` composite surface
  currently exist in `HEAD`, so the ratified split is additive and does not
  collide with live code.
- `src/LineageAxis.jl` still coordinates shared annotation layout around the
  existing tree-oriented label and scale-bar owners. Tranche 3 must integrate
  the new `NodeGroupLabelLayer` lane owner there, and keep
  `NodeGroupHighlightLayer` on the same honest owner path instead of letting
  it bypass the shared layout contract.
- `README.md`, `docs/src/index.md`, and especially `ROADMAP.md` still lag the
  DAG-first public framing. In particular, `ROADMAP.md` still uses
  `PhyloNetworks.jl` adapter language that the parent PRD and tranche file no
  longer permit.

## Ownership and invariant framing

The owner under repair is the annotation contract in `src/Layers.jl` together
with its public-entry integration through `src/LineageAxis.jl`,
`src/LineagesMakie.jl`, and touched docs and examples.

The invariant being repaired is:

- graph-capable annotation in tranche 3 must operate on the ratified explicit
  displayed node-group contract
- tree-only annotation surfaces must remain explicit tree surfaces
- DAG displays must never be annotated by pretending they are one subtree or
  by silently choosing one parent
- direct layer usage, `lineageplot!` composite usage, `LineageAxis` layout, and
  touched public docs must all describe and prove the same owner boundary

The public entry surfaces that must be covered by verification are:

- direct layer constructors and layer application paths in `src/Layers.jl`
- `nodegrouphighlightlayer!` and `nodegrouplabellayer!`
- composite `LineagePlot` or `lineageplot!` surfaces that expose the ratified
  `group_nodes`, `nodegroup_highlight_*`, and `nodegroup_label_*` owner path
- shared layout behavior through `LineageAxis`
- public docs and examples that describe DAG annotation support

## Authorization boundary

Authorized for this tranche:

- deep repair and additive public-surface work in `src/Layers.jl`,
  `src/LineageAxis.jl`, and `src/LineagesMakie.jl`
- related tests in `test/`
- touched source docstrings
- `STYLE-vocabulary.md`
- `README.md`
- `ROADMAP.md`
- `docs/src/index.md`
- directly affected examples

Not authorized for this tranche:

- reopening topology ownership in `src/Topology.jl`
- reopening geometry ownership in `src/Geometry.jl`
- changing `src/CoordinateTransform.jl` ownership
- source-specific ownership in `ext/PhyloNetworksExt.jl`
- network view-mode controls, major-tree or minor-tree display policy, hybrid
  markers, gamma-label rendering, or unrelated tranche-4 work
- arbitrary public breaks without explicit user approval and migration notes

## Primary-goal lock

### Lock 1: graph-capable annotation must land through an explicit owner rather than by broadening tree-only surfaces

- The work is not complete if DAG-capable annotation still enters only through
  `clade_nodes`, `NodeLabelLayer(position = :toward_parent)`, or another
  surface that preserves tree-only semantics behind a broader label.
- The work is also not complete if graph-capable annotation lands under public
  names other than the ratified `NodeGroupHighlightLayer`,
  `NodeGroupLabelLayer`, `group_nodes`, `nodegroup_highlight_*`, and
  `nodegroup_label_*` family.
- Direct red-state equivalent:
  current `HEAD` has only the guarded tree-only surfaces and no explicit
  graph-capable node-group owner at all.
- Closing artifact and tasks:
  the ratified contract artifact plus tasks 1, 2, and 3 below.
- Verification artifact:
  at least one shared-descendant DAG test must succeed only through the new
  ratified `NodeGroup*` surface family and must fail a fake implementation
  that silently reuses subtree expansion or parent collapse.

### Lock 2: tree-only annotation surfaces must remain honest and explicit after graph-capable support lands

- The work is not complete if tranche-3 implementation weakens the current
  tranche-3A guards, silently reopens DAG acceptance through tree-only names,
  or documents the old surfaces as generic DAG annotations.
- Direct red-state repro:
  the pre-3A code silently chose one parent or one subtree; the current guard
  behavior exists specifically to prevent that regression from returning.
- Closing tasks: 2, 3, and 4.
- Verification artifact:
  DAG rejection proofs for tree-only surfaces must remain in the suite while
  the new graph-capable success cases are added separately.

### Lock 3: shared annotation layout must remain a real owner contract rather than an ad hoc rendering side path

- The work is not complete if the new graph-capable annotation owner can render
  on a DAG display but bypasses `LineageAxis` shared annotation layout,
  decorative extents, or public composite entry surfaces.
- Direct red-state equivalent:
  current `LineageAxis` layout coordination only knows the existing annotation
  owners and has no graph-capable annotation surface to integrate.
- Closing tasks: 2 and 3.
- Verification artifact:
  at least one integration proof must exercise the new owner through a public
  `LineageAxis` or `lineageplot!` path and fail if the implementation only
  works as a direct internal layer call.

### Lock 4: public vocabulary, roadmap, docs, and examples must move into DAG-first truth

- The work is not complete if touched vocabulary, roadmap, docs, or examples
  still imply that DAG-capable annotation is provided by tree-only surfaces or
  still describe the extension story as a `PhyloNetworks.jl` adapter project.
- Direct red-state repro:
  current `STYLE-vocabulary.md` has no canonical graph-capable annotation
  vocabulary, and current public prose still contains DAG-first contract drift.
- Closing artifact and tasks:
  the ratified contract artifact plus tasks 1 and 4 below.
- Verification artifact:
  touched docs build successfully, use the ratified vocabulary consistently,
  and include at least one honest DAG annotation example through the new public
  surface.

## Handoff packet

- Active authorities:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the bundled
  development-policies baseline, `design/design.md`,
  `design/target-reference-capacities.md`,
  `design/requirements-landscape-gap.md`, `design/api-landscape.md`, the
  parent PRD, the parent tranche file, the tranche-2 final audit,
  the tranche-3A immediate-action packet, the tranche-3 contract ratification
  artifact, and this tasking file.
- Parent documents:
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`,
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`,
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2c--final-audit.md`,
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2e--annotation-boundary-guard-tasking.md`,
  and
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01a--tranche3--annotation-contract-ratification.md`.
- Settled decisions and non-negotiables:
  DAG-first core, rooted trees as the single-parent special case, no
  source-specific shadow owner, no hidden projection default, no broadening of
  `clade_nodes` or `:toward_parent` into silent DAG contracts, the ratified
  `NodeGroupHighlightLayer` / `NodeGroupLabelLayer` Option A split with
  `group_nodes`, and the current tree-only boundary guards remain baseline
  behavior.
- Authorization boundary:
  deep repair is authorized in the layer owner, public composite entry
  surfaces, shared annotation layout, touched tests, vocabulary, docs,
  roadmap, and examples; topology, geometry, and tranche-4 rendering-policy
  work are out of scope.
- Current-state diagnosis:
  the honesty repair is already landed, but the graph-capable annotation owner,
  its canonical vocabulary, and the DAG-first contract cleanup are still
  missing under the newly ratified Option A public split.
- Primary-goal lock:
  locks 1 through 4 above.
- Direct red-state repros:
  no explicit graph-capable `NodeGroup*` annotation owner exists yet;
  tree-only surfaces are rightly guarded; shared annotation layout has not
  been integrated with a new DAG-capable annotation owner; public vocabulary
  and roadmap prose still lag.
- Owner and invariant under repair:
  annotation-owner normalization and contract truth, with `LineageAxis`
  coordinating shared layout for both tree-only and graph-capable annotation
  surfaces.
- Exact files or surfaces in scope:
  `src/Layers.jl`, `src/LineageAxis.jl`, `src/LineagesMakie.jl`,
  `test/test_Layers.jl`, `test/test_Integration.jl`,
  `test/test_LineageAxis.jl`, `STYLE-vocabulary.md`, `README.md`,
  `ROADMAP.md`, `docs/src/index.md`, `examples/src/shared_descendant_dag_ex1.jl`,
  `examples/src/readme_features.jl`, and touched docstrings in
  `src/Layers.jl`.
- Exact files or surfaces out of scope:
  `src/Topology.jl`, `src/Geometry.jl`, `src/CoordinateTransform.jl`,
  `ext/PhyloNetworksExt.jl`, `Project.toml`, tranche-4 view-mode controls,
  hybrid markers, gamma labels, and unrelated docs-site information
  architecture work.
- Required upstream primary sources:
  the Makie and `PhyloNetworks.jl` files listed above.
- Green-state gates:
  `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, touched example reruns, and
  failure-oriented DAG annotation proofs that fail fake subtree or
  parent-collapse implementations.
- Stop conditions:
  any proposed implementation that departs from the ratified `NodeGroup*`
  Option A contract, any discovered need to reopen topology or geometry
  ownership, any public break without approval, or any pressure to reintroduce
  hidden projection semantics into tranche 3.

## Required revalidation before implementation

- Re-read the tranche-3 section of `02_tranches.md` and the relevant lock
  items in `01_prd.md`.
- Re-read the tranche-2 final audit and tranche-3A immediate-action packet to
  confirm exactly which truth-boundary work is already landed.
- Re-read
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01a--tranche3--annotation-contract-ratification.md`
  and treat its Option A split as settled.
- Re-read `src/Layers.jl`, `src/LineageAxis.jl`, `src/LineagesMakie.jl`,
  `README.md`, `ROADMAP.md`, `docs/src/index.md`, the touched examples, and
  the touched tests in full.
- Reproduce the current baseline behavior on the shared-descendant DAG before
  editing:
  `clade_nodes` and `node_label_position = :toward_parent` should still fail
  directly on full-network DAG displays, because those surfaces remain
  tree-only.
- Re-run `julia --project=test test/runtests.jl` at tranche start. If baseline
  is already red for unrelated reasons, stop and raise that first.
- Re-run `julia --project=docs docs/make.jl` at tranche start if no fresher
  green evidence exists in the implementing session.
- If current `HEAD` already contains a graph-capable annotation owner or a
  settled public contract that differs materially from this file, stop and
  rewrite the tasking rather than operationalizing stale guidance.

## Tranche execution rule

- This tranche begins green and must end green.
- Execute tasks in order. Former task 1 is closed by the ratified contract
  artifact, so the revised task 1 begins immediately.
- Do not treat the former truth-boundary red state as still open. The current
  tree-only guards are baseline and must be preserved while the new owner is
  introduced.
- Report completion by lock item and green-state gate, not by file inventory
  alone.

## Non-negotiable execution rules

- Do not broaden `clade_nodes` into a graph-capable API.
- Do not broaden `NodeLabelLayer(position = :toward_parent)` into a
  graph-capable API.
- Do not rename the ratified `NodeGroupHighlightLayer`,
  `NodeGroupLabelLayer`, `group_nodes`, `nodegroup_highlight_*`, or
  `nodegroup_label_*` surfaces without explicit approval.
- Do not silently project a DAG to a tree, major tree, minor tree, or
  arbitrary-parent walk inside `Layers.jl`.
- Do not reinterpret `group_nodes` as subtree selection, nested group
  batching, or hidden projection input.
- Do not implement graph-capable annotation ownership only in
  `ext/PhyloNetworksExt.jl` or any source-specific path.
- Do not remove or weaken the tranche-3A negative tests or the direct
  diagnostics that enforce the current tree-only boundary.
- Do not bypass `LineageAxis` shared annotation layout just because a direct
  layer render works.
- Do not ship docs, roadmap, or vocabulary cleanup that outruns or contradicts
  the landed runtime owner.

## Anti-patterns and removal targets

- Remove public prose that still frames tranche-4 extension work as a
  `PhyloNetworks.jl` adapter.
- Remove the absence of canonical vocabulary for graph-capable group
  annotation, view types, and tree-only annotation surfaces.
- Remove any temptation to treat `NodeGroup*` as a thin rename over existing
  subtree helpers.
- Remove any implementation pressure to recover DAG annotation by subtree leaf
  expansion, hidden projection, or implicit parent selection.
- Remove examples that imply generic DAG annotation support through the old
  tree-only surfaces.

## Environment and dependency baseline

- Use the repository root project as the owner environment for core code.
- Use `test/` and `docs/` project environments for the canonical green gates.
- Treat `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation`
  as the authoritative upstream checkout root in this environment.
- Do not rely on network access, registry downloads, or undocumented
  dependency-resolution shortcuts to complete this tranche.
- Canonical green gates for the tranche are:
  `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl`.

## Failure-oriented verification

- At least one shared-descendant DAG proof must show the new graph-capable
  annotation owner succeeding through the ratified explicit node-group
  contract.
- That proof must fail a fake implementation that silently expands the target
  set by subtree ownership rather than by the exact displayed group contract.
- Negative proofs for tree-only `clade_nodes` and `:toward_parent` semantics on
  full-network DAG displays must remain in place.
- At least one rooted-tree proof must keep clade highlight, clade label, and
  `:toward_parent` behavior green.
- At least one public-entry integration proof must cover `LineageAxis` or
  `lineageplot!`, not only direct layer calls.
- Touched examples and docs must use the same public vocabulary and contract
  that the runtime actually implements.

## Tasks

1. **Title**: Add canonical vocabulary and public node-group surface definitions
   **Type**: `WRITE`
   **Output**: canonical DAG-first terminology in `STYLE-vocabulary.md`, plus
   exported or otherwise public layer, bang-entrypoint, and composite-surface
   names for the ratified `NodeGroupHighlightLayer` /
   `NodeGroupLabelLayer` split.
   **Depends on**: `none`
   **Positive contract**:
   the code and docs use one settled vocabulary for `group annotation`,
   `tree view`, `full-network view`, and `node group`, and the new
   graph-capable surface is additive and explicitly separate from
   `clade_nodes`.
   **Negative contract**:
   no naming drift, no adapter framing, no reuse of tree-only names for
   graph-capable semantics, and no deviation from the ratified
   `group_nodes`, `nodegroup_highlight_*`, or `nodegroup_label_*` family.
   **Files**:
   `STYLE-vocabulary.md`, `src/Layers.jl`, `src/LineagesMakie.jl`
   **Out of scope**:
   `src/Geometry.jl`, `src/Topology.jl`, `ext/PhyloNetworksExt.jl`,
   `Project.toml`, and broad README or roadmap cleanup
   **Verification**:
   vocabulary entries exist before deeper implementation, exports or otherwise
   public recipe names are in place, composite recipe attributes reflect the
   ratified names, and recipe docstrings distinguish tree-only and
   graph-capable contracts directly.

2. **Title**: Implement the ratified node-group annotation owner and shared layout integration
   **Type**: `WRITE`
   **Output**: `NodeGroupHighlightLayer` and `NodeGroupLabelLayer`, together
   with the corresponding `LineagePlot` keyword family, operate on explicit
   `group_nodes` with no MRCA expansion, while `LineageAxis` integrates the
   new owner through the same honest annotation-owner path used by existing
   decorative layers.
   **Depends on**: `1`
   **Positive contract**:
   DAG-capable displays can request highlight or label annotations from
   explicit node groups without subtree or unique-parent inference;
   `NodeGroupLabelLayer` uses the same annotation-lane mechanism as
   `CladeLabelLayer`; tree-only clade layers remain honest and unchanged on
   rooted-tree views.
   **Negative contract**:
   no `leaves(accessor, mrca)` or hidden subtree expansion inside the new
   owner, no arbitrary-parent fallback for DAG labels, no hidden projection
   contract, and no source-specific or `PhyloNetworks.jl`-only branch.
   **Files**:
   `src/Layers.jl`, `src/LineageAxis.jl`
   **Out of scope**:
   `src/Geometry.jl`, `src/Topology.jl`, `src/CoordinateTransform.jl`,
   `ext/PhyloNetworksExt.jl`, public projection toggles, and network view-mode
   policy
   **Verification**:
   manual DAG render plus direct layer and integration checks fail if a fake
   implementation expands `group_nodes` by subtree ownership, silently reuses
   tree-only parent semantics, or bypasses the shared annotation-owner path.

3. **Title**: Add failure-oriented DAG node-group proofs and rooted-tree non-regressions
   **Type**: `TEST`
   **Output**: tests prove `NodeGroupHighlightLayer` and
   `NodeGroupLabelLayer` work on shared-descendant DAGs, tree-only surfaces
   still reject non-tree views, and rooted-tree annotation behavior stays
   green.
   **Depends on**: `2`
   **Positive contract**:
   at least one DAG test exercises the new node-group surface through direct
   layers and `lineageplot!`, and at least one rooted-tree test reasserts
   clade highlight, clade label, and `:toward_parent` behavior.
   **Negative contract**:
   the suite fails if `group_nodes` silently uses subtree expansion, if DAG
   `clade_nodes` starts rendering again, or if `LineageAxis` shared annotation
   layout drifts behind a green geometry suite.
   **Files**:
   `test/test_Layers.jl`, `test/test_Integration.jl`,
   `test/test_LineageAxis.jl`
   **Out of scope**:
   full `PhyloNetworks.jl` extension tests, network view-mode tests, and
   docs-only checks as a substitute for runtime proof
   **Verification**:
   `julia --project=test test/runtests.jl` plus at least one regression whose
   expected extent differs between exact node-group ownership and fake subtree
   ownership.

4. **Title**: Bring README, roadmap, docs, examples, and docstrings into the ratified DAG-first truth
   **Type**: `MIGRATE`
   **Output**: public contract surfaces describe a DAG-capable core, tree-only
   clade surfaces as explicitly bounded, and the new `NodeGroup*` annotation
   path honestly; roadmap no longer says `PhyloNetworks.jl` adapter.
   **Depends on**: `1`, `2`, `3`
   **Positive contract**:
   touched prose names rooted trees as the single-parent special case, shows
   the new node-group surface in at least one DAG example, and keeps the
   tranche-3A guard language only where it is still true.
   **Negative contract**:
   no touched surface may claim generic DAG annotation via `clade_nodes` or
   `:toward_parent`; no adapter framing; no example silently relying on hidden
   projection or tree-only semantics.
   **Files**:
   `README.md`, `ROADMAP.md`, `docs/src/index.md`,
   `examples/src/shared_descendant_dag_ex1.jl`,
   `examples/src/readme_features.jl`, and touched docstrings in
   `src/Layers.jl`
   **Out of scope**:
   tranche-4 extension docs, unrelated design-note rewrites, and broad
   docs-site information architecture changes
   **Verification**:
   `julia --project=docs docs/make.jl`, rerun touched examples, and manual
   contract review of README, docs, roadmap, and examples against the
   implemented runtime surfaces.
