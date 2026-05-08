---
date-created: 2026-05-08T01:38:13-07:00
date-revised: 2026-05-08T01:38:13-07:00
status: approved
---

# Tasks for Tranche 3 remediation: independent composite node-group activation and roadmap truth

Tasking identifier: `20260508T013813--tranche-3-remediation-tasking`

This file supplements and partially supersedes
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01--tranche3--tasking.md`
for the remaining tranche-3 work after review of commit `23ba7ea`.

If this file is executed honestly, no further tranche-3 remediation tasking
should be required. A fresh implementation agent should use this file,
together with the parent PRD, tranche file, tranche-3 contract ratification,
and the original tranche-3 tasking file, as the authoritative handoff for the
remaining tranche-3 repair.

Parent tranche: Tranche 3  
Parent PRD: `01_prd.md`  
Parent tranche tasking under repair: `03-01--tranche3--tasking.md`  
Ratified tranche-3 contract artifact:
`03-01a--tranche3--annotation-contract-ratification.md`  
Current implementation under repair: commit `23ba7ea`

## Settled decisions and environment baseline

- DAG lineage graphs remain first-class in the core owner model. Rooted trees
  remain the single-parent special case inside that same owner path.
- The tranche-3A tree-only boundary guards remain settled baseline behavior.
  `CladeHighlightLayer(clade_nodes = ...)`,
  `CladeLabelLayer(clade_nodes = ...)`, and
  `NodeLabelLayer(position = :toward_parent)` remain tree-only surfaces and
  must continue to fail directly on shared-parent DAG full-network views.
- The tranche-3 ratified public split remains settled. Do not rename,
  repurpose, batch, or otherwise reopen `NodeGroupHighlightLayer`,
  `nodegrouphighlightlayer!`, `NodeGroupLabelLayer`,
  `nodegrouplabellayer!`, `group_nodes`, `nodegroup_highlight_*`, or
  `nodegroup_label_*`.
- The tranche-3 vocabulary work is already landed in `STYLE-vocabulary.md`.
  This remediation does not authorize reopening or replacing those entries
  except for a strictly necessary touched-surface consistency fix.
- New resolved remediation decision:
  on the composite `LineagePlot` / `lineageplot!` / `lineageplot` surface,
  `group_nodes` is a selector only. It does not by itself request either the
  highlight surface or the label surface.
- New resolved remediation decision:
  on the composite `LineagePlot` family only,
  `nodegroup_highlight_visible` and `nodegroup_label_visible` default to
  `false`. A caller that wants a node-group highlight, a node-group bracket
  label, or both must opt into each surface independently.
- New resolved remediation decision:
  the direct-layer owners remain separate surfaces. Direct
  `NodeGroupHighlightLayer` and direct `NodeGroupLabelLayer` calls do not need
  to inherit the composite `visible = false` defaults merely because the
  composite path now requires explicit opt-in.
- New resolved remediation decision:
  an empty string from `nodegroup_label_func` means "no node-group label". In
  both direct-layer and composite paths, that must produce no bracket, no
  label text, and no `LineageAxis` shared-annotation-lane reservation.
- New resolved remediation decision:
  `LineageAxis` node-group label participation is based on actual active
  node-group label content, not merely on `group_nodes` being nonempty.
- No public API rename, export removal, signature break, topology-owner
  redesign, geometry-owner redesign, or tranche-4 rendering-policy work is
  authorized here.
- Because this remediation resolves a previously unspecified composite
  activation detail inside an unaccepted tranche implementation, it does not
  count as reopening the ratified Option A split or as authorizing a broader
  public-contract redesign.
- No explicit `REVIEW` task is required at the current diagnosis. Stop for
  review only if honest remediation would require changing the ratified names,
  changing the one-group-per-invocation rule, reopening tree-only boundary
  policy, or introducing a new public projection or batching contract.

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
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2e--annotation-boundary-guard-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01--tranche3--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01a--tranche3--annotation-contract-ratification.md`
- this remediation file
- `design/design.md`
- `design/target-reference-capacities.md`
- `design/requirements-landscape-gap.md`
- `design/api-landscape.md`

The bundled style baseline under
`/home/jeetsukumaran/site/service/env/start/workhost/resources/packages/shared/workhost-resources/configure/coding-agent-skills/development-policies/references/`
was rechecked for this remediation rewrite and remains aligned with the
repo-local `STYLE*.md` stack above. Bundled `CONTRIBUTING.md` was not present
there, so repo-local `CONTRIBUTING.md` remains authoritative for contribution
guidance.

Workflow authorities used to produce this remediation were
`development-policies`, `devflow-architecture-03--tranche-to-tasks`, and the
tranche-3 review findings generated against commit `23ba7ea`. Downstream
implementation must preserve their pass-forward mandates, especially
active-authority restatement, exact upstream-source naming, exact
authorization boundaries, controlled vocabulary, primary-goal lock items,
direct red-state repros, and failure-oriented verification.

Upstream primary sources that must be read line by line for this remediation
are:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/generic/space.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/plots/text.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/makielayout/types.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/net_plot.md`

These sources constrain the remediation as follows:

- Makie recipe guidance still governs the mutating and non-mutating composite
  surface boundary and where composite attribute normalization should happen.
- Makie text and layout guidance still governs when annotation extents may
  reserve panel-owned space and when empty label content must not pretend to
  be a real annotation request.
- Makie block ownership still keeps shared annotation-lane reservation in
  `LineageAxis`, not in ad hoc sibling-layer spacing.
- `PhyloNetworks.jl` network plotting docs still preserve the distinction
  between full-network views and tree-only annotation semantics. This
  remediation may not collapse that distinction while fixing the composite
  node-group path.

Controlled vocabulary from `STYLE-vocabulary.md` is mandatory. Use
`full-network view`, `tree view`, `node group`, `group annotation`,
`tree-only annotation surface`, `graph-capable annotation surface`,
`lock item`, `red-state repro`, and `verification artifact` consistently. Do
not describe `group_nodes` as an MRCA, subtree, or implicit multi-surface
activation request.

Read-only git and shell commands may be used freely. Mutating git operations
such as commit, merge, push, rebase, reset, and branch creation remain the
human project owner's responsibility unless the user explicitly instructs
otherwise.

## Revalidated current state

- The tranche-3 vocabulary and export-surface work is already landed.
  `STYLE-vocabulary.md` now contains entries for `full-network view`,
  `node group`, `group annotation`, `tree-only annotation surface`,
  `graph-capable annotation surface`, `NodeGroupHighlightLayer`, and
  `NodeGroupLabelLayer`. This remediation must not redo that work.
- `README.md` and `docs/src/index.md` already acknowledge the node-group
  surface family and the tree-only boundary guards. The surviving docs drift is
  narrower than the original tranche-3 start state.
- The surviving runtime red state is in the composite public owner, not in the
  direct layer owners and not in the ratified names.
- Direct repro on commit `23ba7ea` for the highlight-only composite case:
  `lineageplot!(ax, root, acc; lineageunits = :nodelevels, group_nodes = [left, right], nodegroup_highlight_alpha = 0.22)`
  still produces `NodeGroupLabelLayer[:bracket_label_strings][] == [""]` and
  `length(NodeGroupLabelLayer[:bracket_pixel_shapes][]) == 9` after render.
  So the highlight-only composite path still instantiates an empty bracket
  label surface and bracket geometry instead of remaining highlight-only.
- Direct repro on commit `23ba7ea` for the label-function-only composite case:
  `lineageplot!(ax, root, acc; lineageunits = :nodelevels, group_nodes = [left, right], nodegroup_label_func = nodes -> "left + right")`
  still leaves both `NodeGroupHighlightLayer.visible[] == true` and
  `NodeGroupLabelLayer.visible[] == true`. So the label-only composite path
  still turns on the highlight surface unless the caller knows to disable it
  manually.
- `src/LineageAxis.jl` still treats node-group label participation as
  `nodegroup_label_visible && !isempty(group_nodes)`, so the shared annotation
  lane can be activated merely by a nonempty selector even when the resolved
  label text is empty.
- Existing tests prove the exact-node-group extent and the combined
  highlight-plus-label success path, but they do not yet force:
  - highlight-only composite usage
  - label-only composite usage
  - empty-label suppression at the `NodeGroupLabelLayer` owner
  - empty-label suppression at the `LineageAxis` shared-annotation-lane owner
- `ROADMAP.md` no longer says `PhyloNetworks.jl adapter`, but the tranche-3
  migration is still incomplete. Its `Current foundation` section still reads
  like a tree-first current surface and omits the live DAG/shared-ancestry
  foundation and the new node-group annotation surfaces.
- This remediation file does not claim a fresh full-suite green baseline.
  `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl` must be rerun at remediation start and
  remediation end.

## Drift diagnosis

### Why the implementation drifted

- The drift was mixed. One part was a genuinely unspecified composite behavior,
  and one part was task wording that was not tight enough.
- The prior tranche-3 ratification and tasking settled the public split,
  additive names, one-group-per-invocation rule, tree-only boundaries, and
  the requirement that the new owner be graph-capable. They did not settle the
  composite activation rule for the shared `group_nodes` selector.
- Specifically, the prior documents did not say whether:
  - `group_nodes` alone activates both `NodeGroup*` surfaces
  - composite `nodegroup_highlight_visible` and `nodegroup_label_visible`
    default to `true`, `false`, or some derived policy
  - an empty string from `nodegroup_label_func` counts as a real annotation
    request
  - `LineageAxis` lane reservation should key off selector presence or off
    actual nonempty label content
- Because those derivable details were left unstated, the implementation agent
  chose the coupled default: both composite `NodeGroup*` surfaces are always
  instantiated and both composite `visible` flags default to `true`.
- The roadmap migration finding was a looser-language problem. The original
  tranche-3 migration task named README, docs, examples, and roadmap cleanup,
  but its roadmap-specific negative contract was only "roadmap no longer says
  `PhyloNetworks.jl` adapter." That let the implementation agent fix the most
  obvious stale phrase while leaving the `Current foundation` section behind.
- The prior verification plan also allowed the coupling bug to survive. It
  proved combined highlight-plus-label success, but it did not create separate
  composite proofs for highlight-only use, label-only use, or empty-label lane
  suppression. A fresh agent could therefore satisfy the earlier tests while
  keeping both surfaces coupled.

### What is now baked in

- The composite activation rule is now explicit and must not be rediscovered
  during implementation:
  `group_nodes` selects a target; each composite node-group surface must be
  opted into independently.
- The empty-label rule is now explicit and must not be rediscovered during
  implementation:
  empty node-group label text means no node-group label surface is active.
- The roadmap migration rule is now explicit and must not be rediscovered
  during implementation:
  `ROADMAP.md` `Current foundation` must describe the live DAG/shared-ancestry
  core and the live node-group annotation surfaces, not merely remove the old
  adapter phrasing elsewhere.
- The verification gap is now closed at the tasking level:
  highlight-only composite, label-only composite, and empty-label
  non-participation all receive their own proof obligations.

## Primary-goal lock

### Lock 1: composite node-group highlights and node-group labels must remain independently activatable

- The work is not complete if a composite highlight-only call still turns on
  the node-group label surface, or if a composite label-only call still turns
  on the node-group highlight surface.
- Direct red-state repros:
  the highlight-only call still yields `[""]` label strings and bracket
  geometry; the label-function-only call still leaves both composite
  `NodeGroup*` surfaces visible.
- Closing tasks: 1 and 2.
- Verification artifact:
  one composite regression must prove highlight-only usage leaves the
  node-group label surface inactive, and one composite regression must prove
  label-only usage leaves the node-group highlight surface inactive. The old
  implementation must fail both.

### Lock 2: empty node-group label text must not render a bracket or reserve the shared annotation lane

- The work is not complete if an empty node-group label string can still
  produce bracket geometry, label geometry, or `LineageAxis` shared-lane
  reservation.
- Direct red-state repro:
  the highlight-only composite call still yields
  `NodeGroupLabelLayer[:bracket_label_strings][] == [""]` and 9 bracket
  points after render.
- Closing tasks: 1 and 2.
- Verification artifact:
  at least one direct or integration regression must prove empty label text
  produces no node-group bracket geometry and no node-group contribution to
  shared annotation-lane activation. The old implementation must fail that
  proof.

### Lock 3: the roadmap current-foundation section must describe the live DAG-first current surface

- The work is not complete if `ROADMAP.md` still lets a fresh reader conclude
  that the current foundation stops at tree-first layers and does not include
  DAG/shared-ancestry support or the live node-group annotation surfaces.
- Direct red-state repro:
  commit `23ba7ea` has node-group owners in `src/` and in README/docs, but
  `ROADMAP.md` `Current foundation` still lists only the older tree-first
  inventory.
- Closing task: 3.
- Verification artifact:
  manual contract review plus docs build must show `ROADMAP.md` `Current
  foundation` explicitly names the DAG/shared-ancestry core and the current
  node-group highlight and label surfaces. A docs-only cleanup elsewhere in the
  roadmap does not close this lock.

### Lock 4: the ratified tranche-3 contract and tree-only truth boundary must remain intact during remediation

- The work is not complete if fixing locks 1 through 3 reopens tree-only
  surface names, weakens the DAG rejection guards, reinterprets `group_nodes`
  as subtree or batch input, or reopens the ratified `NodeGroup*` naming
  family.
- Direct red-state equivalent:
  an over-broad remediation could make the coupled composite bug disappear by
  broadening the wrong public contract instead of repairing the composite
  owner.
- Closing tasks: 1 through 3.
- Verification artifact:
  existing DAG rejection tests for tree-only surfaces stay green, the
  one-group-per-invocation contract stays documented, and touched docs/examples
  continue to use the ratified names exactly.

## Handoff packet

- Active authorities:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the bundled
  development-policies baseline, `design/design.md`,
  `design/target-reference-capacities.md`,
  `design/requirements-landscape-gap.md`, `design/api-landscape.md`, the
  parent PRD, the tranche file, the tranche-3A immediate-action packet, the
  tranche-3 contract ratification artifact, the original tranche-3 tasking,
  and this remediation file.
- Parent documents:
  `01_prd.md`, `02_tranches.md`, `03_tranche-2e--annotation-boundary-guard-tasking.md`,
  `03-01--tranche3--tasking.md`, and
  `03-01a--tranche3--annotation-contract-ratification.md`.
- Settled decisions and non-negotiables:
  DAG-first core, rooted trees as the single-parent special case, no
  source-specific shadow owner, tree-only guards stay in place, ratified
  `NodeGroup*` names stay in place, one explicit `group_nodes` set per
  invocation stays in place, composite `group_nodes` is selector-only, and
  composite node-group surfaces are opt-in independently.
- Authorization boundary:
  deep repair is authorized in the composite layer owner path, shared
  annotation-lane owner path, touched tests, touched docs, and touched
  examples; topology, geometry, extension ownership, vocabulary redesign, and
  tranche-4 rendering policy remain out of scope.
- Current-state diagnosis:
  the surviving runtime defect is coupled composite node-group activation and
  empty-label lane participation; the surviving migration defect is roadmap
  current-foundation drift.
- Primary-goal lock:
  locks 1 through 4 above.
- Direct red-state repros:
  highlight-only composite still emits empty label geometry; label-function-
  only composite still leaves the highlight surface visible; roadmap current
  foundation still omits the live DAG/node-group current surface.
- Owner and invariant under repair:
  composite node-group activation normalization in `src/Layers.jl` and
  shared-annotation-lane participation in `src/LineageAxis.jl`; invariant that
  each graph-capable node-group surface can be requested independently and that
  empty label content is not a real annotation request.
- Exact files or surfaces in scope:
  `src/Layers.jl`, `src/LineageAxis.jl`, `test/test_Layers.jl`,
  `test/test_Integration.jl`, `test/test_LineageAxis.jl`, `README.md`,
  `ROADMAP.md`, `docs/src/index.md`,
  `examples/src/shared_descendant_dag_ex1.jl`,
  `examples/src/readme_features.jl`, and touched node-group docstrings in
  `src/Layers.jl`.
- Exact files or surfaces out of scope:
  `src/Topology.jl`, `src/Geometry.jl`, `src/CoordinateTransform.jl`,
  `src/LineagesMakie.jl`, `STYLE-vocabulary.md`, `ext/PhyloNetworksExt.jl`,
  `Project.toml`, tranche-4 view-mode controls, hybrid markers, gamma labels,
  and unrelated docs-site information architecture work.
- Required upstream primary sources:
  the Makie and `PhyloNetworks.jl` files listed above.
- Green-state gates:
  `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, rerun touched examples, and the new
  failure-oriented composite-node-group proofs.
- Stop conditions:
  any need to rename or reinterpret the ratified `NodeGroup*` family, any need
  to reopen topology or geometry ownership, any need for a new public
  projection or batching API, or any attempt to fix the coupled composite bug
  by broadening tree-only semantics.

## Required revalidation before implementation

- Re-read the tranche-3 section of `02_tranches.md`, the relevant tranche-3
  lock items in `01_prd.md`, the tranche-3A immediate-action packet, the
  tranche-3 contract ratification, and the original tranche-3 tasking.
- Re-read `src/Layers.jl`, `src/LineageAxis.jl`, `README.md`, `ROADMAP.md`,
  `docs/src/index.md`, `examples/src/shared_descendant_dag_ex1.jl`,
  `examples/src/readme_features.jl`, `test/test_Layers.jl`,
  `test/test_Integration.jl`, and `test/test_LineageAxis.jl` in full.
- Reproduce the two current composite red states before editing:
  - highlight-only composite still emits empty label geometry
  - label-function-only composite still leaves the highlight surface active
- Reconfirm that the tree-only DAG guards remain green before touching the
  remediation work.
- Re-run `julia --project=test test/runtests.jl` at remediation start. If
  baseline is already red for unrelated reasons, stop and raise that first.
- Re-run `julia --project=docs docs/make.jl` at remediation start if no fresher
  green evidence exists in the implementing session.
- If current `HEAD` already differs materially from the red-state repros above,
  stop and rewrite this remediation file rather than operationalizing stale
  guidance.

## Tranche execution rule

- This remediation begins green and must end green.
- Execute tasks in order.
- Do not redo already-landed tranche-3 vocabulary/export work merely because
  this remediation touches the same area of the codebase.
- Report completion by lock item and green-state gate, not by file inventory
  alone.

## Non-negotiable execution rules

- Do not broaden `clade_nodes` into a graph-capable contract.
- Do not broaden `NodeLabelLayer(position = :toward_parent)` into a
  graph-capable contract.
- Do not rename or repurpose the ratified `NodeGroup*` names.
- Do not reinterpret `group_nodes` as subtree selection, nested batching, or
  projection input.
- Do not keep composite node-group surfaces coupled behind a green suite by
  merely suppressing text draw calls while still reserving annotation space.
- Do not leave node-group label participation keyed only off nonempty
  `group_nodes`.
- Do not "fix" the roadmap finding by editing only the planned-capacities
  sections while leaving `Current foundation` stale.
- Do not reopen `STYLE-vocabulary.md` unless a strictly necessary consistency
  touch becomes unavoidable.
- Do not bypass `LineageAxis` shared annotation ownership just because a direct
  layer render works.

## Anti-patterns and removal targets

- Remove the coupled composite assumption that one shared `group_nodes`
  selector implies both node-group surfaces should turn on.
- Remove empty-string node-group brackets as a tolerated fake highlight-only
  state.
- Remove node-group shared-lane activation based only on selector presence.
- Remove roadmap prose that understates the live DAG-first current surface.
- Remove examples that rely on implicit composite node-group activation.

## Environment and dependency baseline

- Use the repository root project as the owner environment for core code.
- Use `test/` and `docs/` project environments for the canonical green gates.
- Treat `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation`
  as the authoritative upstream checkout root in this environment.
- Do not rely on network access, registry downloads, or undocumented
  dependency-resolution shortcuts to complete this remediation.
- Canonical green gates for the remediation are:
  `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl`.

## Failure-oriented verification

- At least one composite regression must prove highlight-only node-group usage
  does not activate a node-group label surface or shared annotation lane.
- At least one composite regression must prove label-only node-group usage does
  not activate a node-group highlight surface.
- At least one direct or integration regression must prove empty node-group
  label text produces no bracket geometry and no lane participation.
- Existing combined highlight-plus-label success coverage must remain green so
  the remediation does not solve the bug by breaking the intended combined use
  case.
- Existing DAG rejection proofs for tree-only `clade_nodes` and
  `:toward_parent` semantics must remain green.
- Touched docs and examples must show the new explicit composite opt-in rule
  rather than silently relying on the previous coupled default.

## Tasks

1. **Title**: Repair composite node-group activation and empty-label ownership
   **Type**: `WRITE`
   **Output**: the composite `LineagePlot` node-group path treats
   `group_nodes` as selector-only, requires independent opt-in for the
   highlight and label surfaces, and suppresses empty-label bracket and lane
   participation.
   **Depends on**: `none`
   **Positive contract**:
   on the composite public surface, `nodegroup_highlight_visible` and
   `nodegroup_label_visible` default to `false`; a highlight-only call can
   remain highlight-only; a label-only call can remain label-only; empty
   node-group label text produces no bracket geometry and no
   `LineageAxis` shared-lane participation; the direct layer owners remain
   separate graph-capable surfaces.
   **Negative contract**:
   no automatic dual-surface activation from shared `group_nodes`, no empty
   string bracket state, no selector-only lane reservation, no hidden subtree
   or parent fallback, and no reopening of the ratified names or tree-only
   guards.
   **Files**:
   `src/Layers.jl`, `src/LineageAxis.jl`
   **Out of scope**:
   `src/Topology.jl`, `src/Geometry.jl`, `src/CoordinateTransform.jl`,
   `src/LineagesMakie.jl`, `STYLE-vocabulary.md`, `ext/PhyloNetworksExt.jl`,
   and broad docs cleanup
   **Verification**:
   direct composite checks on the shared-descendant DAG show:
   - highlight-only usage leaves `NodeGroupLabelLayer` inactive and yields no
     node-group bracket geometry
   - label-only usage leaves `NodeGroupHighlightLayer` inactive
   - empty node-group label text yields no lane participation in
     `LineageAxis`

2. **Title**: Add decoupling regressions and empty-label lane proofs
   **Type**: `TEST`
   **Output**: test coverage proves highlight-only composite usage,
   label-only composite usage, empty-label suppression, combined use, and
   preserved tree-only guards.
   **Depends on**: `1`
   **Positive contract**:
   at least one integration or layer regression proves each of the following
   separately:
   highlight-only composite usage, label-only composite usage, empty-label
   non-participation, and combined highlight-plus-label success; at least one
   `LineageAxis` proof verifies that highlight-only node-group usage does not
   reserve the shared annotation lane while nonempty label usage does.
   **Negative contract**:
   the suite fails if composite `group_nodes` still activates both surfaces by
   default, if empty label strings still create bracket geometry or lane
   reservation, if the old combined use case breaks, or if the tree-only DAG
   rejection proofs regress.
   **Files**:
   `test/test_Layers.jl`, `test/test_Integration.jl`,
   `test/test_LineageAxis.jl`
   **Out of scope**:
   docs-only verification as a substitute for runtime proof, tranche-4
   network-view tests, and extension-boundary tests
   **Verification**:
   `julia --project=test test/runtests.jl`, with the two known red-state
   composite repros above failing the old implementation and passing only once
   the composite surfaces are truly decoupled.

3. **Title**: Bring README, examples, docs, and roadmap current-foundation truth into exact alignment
   **Type**: `MIGRATE`
   **Output**: composite node-group docs and examples use explicit per-surface
   opt-in, and `ROADMAP.md` `Current foundation` truthfully names the live
   DAG-first current surface and node-group annotation owners.
   **Depends on**: `1`, `2`
   **Positive contract**:
   touched docs and examples describe `group_nodes` as selector-only, show the
   explicit composite `nodegroup_*_visible` opt-in rule where needed, keep the
   ratified tree-only boundaries intact, and make `ROADMAP.md` `Current
   foundation` match the current runtime contract.
   **Negative contract**:
   no touched prose may imply that `group_nodes` alone activates both
   node-group surfaces, no touched example may rely on implicit activation, no
   touched roadmap section may remain tree-first about the current surface,
   and no touched surface may reopen the adapter framing or hidden projection
   story.
   **Files**:
   `README.md`, `ROADMAP.md`, `docs/src/index.md`,
   `examples/src/shared_descendant_dag_ex1.jl`,
   `examples/src/readme_features.jl`, and touched node-group docstrings in
   `src/Layers.jl`
   **Out of scope**:
   `STYLE-vocabulary.md`, tranche-4 extension docs, unrelated roadmap sections,
   and broad docs-site information architecture changes
   **Verification**:
   `julia --project=docs docs/make.jl`, rerun touched examples, and manual
   contract review confirming that `ROADMAP.md` `Current foundation` now names
   the live DAG/shared-ancestry core and the current node-group highlight and
   label surfaces explicitly.
