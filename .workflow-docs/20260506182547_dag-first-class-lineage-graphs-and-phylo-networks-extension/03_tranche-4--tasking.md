---
date-created: 2026-05-08T12:58:06-07:00
date-revised: 2026-05-08T12:58:06-07:00
status: approved
---

# Tasks for tranche 4: PhyloNetworks.jl extension and rooted full-network rendering primitives

Tasking identifier:
`20260508T125806--tranche-4-phylonetworks-extension-and-rooted-full-network-rendering-tasking`

This file operationalizes tranche 4 from
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
against current `HEAD`.

It preserves the parent PRD and tranche intent, but it does not inherit their
original start-state diagnosis blindly. Revalidation against current `HEAD`
commit `fe7e213` shows that tranche 1 through tranche 3 owner work has already
landed, `Project.toml` already carries the optional extension boundary, and
`ext/PhyloNetworksExt.jl` is still only a stub. Planning-time revalidation on
2026-05-08 also confirmed that current `HEAD` is green under:

- `julia --project=test test/runtests.jl`
- `julia --project=docs docs/make.jl`

The remaining tranche-4 work is the real `HybridNetwork` adaptation path, the
rooted full-network rendering primitives layered on top of the settled core
owners, the optional-extension proof hardening for the live environment, and
the touched public contract updates that follow from that support.

Parent tranche: Tranche 4  
Parent PRD:
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`  
Completed prerequisite workflow artifacts:

- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1a--remediation-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2c--final-audit.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2e--annotation-boundary-guard-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01--tranche3--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01a--tranche3--annotation-contract-ratification.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-02--tranche3-remediation-tasking.md`

## Settled decisions and environment baseline

- DAG lineage graphs remain first-class in the core owner model. Rooted trees
  remain the single-parent special case inside that same owner path.
- `src/Topology.jl` remains the settled topology owner, `src/Geometry.jl`
  remains the settled geometry owner, and the tranche-3 tree-only versus
  graph-capable annotation split remains settled. Do not reopen those owner
  boundaries in this tranche.
- The tranche-3 annotation contract remains authoritative. `clade_nodes`
  subtree surfaces and `NodeLabelLayer(position = :toward_parent)` remain
  tree-only surfaces. `group_nodes`, `NodeGroupHighlightLayer`, and
  `NodeGroupLabelLayer` remain the graph-capable annotation surface family.
- `PhyloNetworks.jl` remains an optional package extension. Do not add it to
  `[deps]`. Do not move traversal, topology, geometry, or annotation ownership
  into `ext/`.
- Revalidated environment decision: the extension-absence proof does not rely
  on the checked-in `test/Project.toml`, because that environment already
  declares a local `PhyloNetworks.jl` path in `[sources]`. The absence case
  remains an isolated temporary-project or subprocess probe. The activation
  case remains the checked-in `test/Project.toml` environment.
- Settled tranche-4 scope decision: this tranche implements one explicit
  network display contract only, rooted full-network view on
  `PhyloNetworks.HybridNetwork`.
- Settled tranche-4 surface decision: direct public extension entrypoints in
  this tranche are:
  - `lineageplot(net::PhyloNetworks.HybridNetwork; kwargs...)`
  - `lineageplot!(ax, net::PhyloNetworks.HybridNetwork; kwargs...)`
  on the same axis surfaces already supported by the core package.
- Settled non-surface decision: do not add public
  `lineagegraph_accessor(::PhyloNetworks.HybridNetwork)`,
  `rectangular_layout(::PhyloNetworks.HybridNetwork)`,
  `circular_layout(::PhyloNetworks.HybridNetwork)`, projection selectors, or
  new view-mode keywords in tranche 4.
- Settled default-contract decision: direct `HybridNetwork` plotting defaults
  to `lineageunits = :nodelevels` unless the caller explicitly supplies
  `lineageunits`. This keeps the convenience path honest on rooted
  full-network inputs without smuggling a hidden time-consistency or projected
  tree contract into the default.
- Explicit weighted-unit requests remain available. If the caller supplies
  `lineageunits = :edgeweights`, `:branchingtime`, or `:coalescenceage`, the
  settled tranche-2 full-network consistency rules remain in force unchanged.
- Settled rendering-primitive decision: rooted full-network support in this
  tranche must render all normalized edges, visibly distinguish major and
  minor hybrid parent edges, overlay a hybrid-node marker on hybrid nodes, and
  render gamma labels from upstream edge fields on the rooted full-network
  contract.
- Settled styling-boundary decision: extension-local defaults may choose the
  exact reticulation accent styling and hybrid-node marker styling, but no new
  public styling controls or user-visible view-policy controls are authorized
  in this tranche.
- `examples/Project.toml` and `docs/Project.toml` remain unchanged in this
  tranche. Any rooted full-network example script added here must run under
  `--project=test`, not by introducing `PhyloNetworks.jl` into the examples or
  docs environments.
- No public API removal, export removal, signature break, or silent external
  migration is authorized here.
- No explicit `REVIEW` task is required at the current diagnosis. Stop for
  review only if honest tranche-4 work would require a public view-mode API, a
  semidirected or unrooted display policy, a projected-tree or major-tree
  contract, or a reopening of the settled tranche-1 through tranche-3 owners.

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
- `design/design.md`
- `design/target-reference-capacities.md`
- `design/requirements-landscape-gap.md`
- `design/api-landscape.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- the tranche-1 through tranche-3 workflow artifacts listed at the top of this
  file
- this tasking file

The bundled style baseline under
`/home/jeetsukumaran/site/service/env/start/workhost/resources/packages/shared/workhost-resources/configure/coding-agent-skills/development-policies/references/`
was rechecked during this tasking run and remains aligned with the repo-local
governance stack above. Bundled `CONTRIBUTING.md` was not present there, so
repo-local `CONTRIBUTING.md` remains authoritative for contribution guidance.

Workflow authorities used to produce this tasking were
`development-policies` and
`devflow-architecture-03--tranche-to-tasks`. Downstream implementation must
preserve their pass-forward mandates, especially active-authority restatement,
exact upstream-source naming, exact authorization boundaries, controlled
vocabulary, primary-goal lock items, direct red-state repros, and
failure-oriented verification.

## Controlled vocabulary

- Continue using the parent PRD vocabulary that treats DAG lineage graphs as
  the core case and rooted trees as the single-parent special case.
- The existing tranche-3 terms `tree view`, `full-network view`, `node group`,
  `group annotation`, `tree-only annotation surface`, and
  `graph-capable annotation surface` remain settled and must not be reopened.
- This tranche adds or finalizes the missing network-specific reader-facing
  terms:
  - `hybrid node`
  - `reticulation edge`
  - `major edge`
  - `minor edge`
  - `gamma label`
  - `major-tree projection`
- Task 1 owns adding those missing entries to `STYLE-vocabulary.md` before the
  extension implementation or touched docs start using them.
- Do not describe this tranche as an `adapter` project. The extension adapts
  upstream objects into package-owned core owners, but it is not the owner of
  DAG support itself.
- Do not call a rooted full-network display a `tree` or `major tree`. Reserve
  `major-tree projection` and other projected-tree terms for the tranche-5
  work they actually name.
- Do not describe a major-edge-only rendering as `network support`.

## Upstream primary sources

Read these primary sources line by line before implementation:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/types.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/auxiliary.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/interop.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/netmanipulation.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/net_plot.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/generic/space.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/plots/text.md`

These sources constrain the tranche as follows:

- `types.jl` defines the real upstream owner data for `HybridNetwork`,
  `Node`, `EdgeT`, `length`, `gamma`, `ismajor`, and `ischild1`.
- `auxiliary.jl` defines the rooted parent and child access contracts used by
  the extension adaptation layer, especially `getroot`, `getchildren`,
  `getparent`, `getparents`, `getparentedge`, and `getparentedgeminor`.
- `interop.jl` defines major-edge and minor-reticulation helper matrices and
  gamma helper vectors. In this tranche, those helpers are verification
  references on real fixtures, not the runtime owner of adaptation.
- `netmanipulation.md` and `net_plot.md` confirm the upstream distinction
  between rooted, semidirected, and projected displays, and they confirm the
  public semantics of major and minor hybrid edges plus gamma display.
- Makie recipe, space, and text documentation constrains where the extension
  may compose overlays, how it may place gamma labels, and how decoration-like
  versus data-space artifacts must remain honest.

## Revalidated current state

- Tranche 1 and tranche 2 foundational owner work is present in current
  `HEAD`. `src/Topology.jl` normalizes shared-parent DAGs, and
  `src/Geometry.jl` now owns DAG-safe rectangular and radial geometry.
- Tranche 3 annotation-owner work is present in current `HEAD`.
  `NodeGroupHighlightLayer`, `NodeGroupLabelLayer`, and the settled
  `group_nodes` contract are already live. Tree-only `clade_nodes` and
  `NodeLabelLayer(position = :toward_parent)` boundaries are already enforced.
- `Project.toml` already declares `[weakdeps]` and `[extensions]`, and
  `ext/PhyloNetworksExt.jl` already exists. The surviving red state is that the
  file is still a stub and contributes no real `HybridNetwork` integration.
- `test/Project.toml` already declares the reviewed local `PhyloNetworks.jl`
  checkout in `[sources]`, and current `test/test_ExtensionBoundary.jl`
  already proves the isolated absence case plus the activation case.
- `examples/Project.toml` and `docs/Project.toml` do not declare
  `PhyloNetworks.jl`. That is current baseline and must remain so in this
  tranche.
- Current public plotting still requires `basenode` plus
  `LineageGraphAccessor` for generic use. No direct `HybridNetwork` convenience
  methods exist yet.
- No current source file adapts `PhyloNetworks.HybridNetwork` into the core
  owner path.
- No current test file proves direct rooted full-network `HybridNetwork`
  plotting, no current render proof checks hybrid markers or gamma labels, and
  no current negative regression proves that a supposed full-network render did
  not silently drop minor reticulation edges.
- Current `STYLE-vocabulary.md` still lacks canonical entries for
  `hybrid node`, `reticulation edge`, `major edge`, `minor edge`,
  `gamma label`, and `major-tree projection`.
- Current `README.md`, `docs/src/index.md`, and `ROADMAP.md` already reflect
  the tranche-3 DAG-first contract, but they do not yet document a live
  rooted full-network `PhyloNetworks.jl` support surface.
- Current `src/Layers.jl` can vary edge color per edge, but it does not
  currently expose a reusable helper for edge-subset overlays or edge-label
  anchor derivation from existing `LineageGraphGeometry`. Tranche 4 should add
  that generic helper boundary rather than letting the extension reconstruct
  path geometry or edge anchors ad hoc.
- Planning-time revalidation on 2026-05-08 confirmed a green baseline at
  current `HEAD`:
  - `julia --project=test test/runtests.jl` passed with 1136 of 1136 tests
  - `julia --project=docs docs/make.jl` completed successfully

## Ownership and invariant framing

The owner under repair is the optional upstream integration and network-primitive
overlay path spanning:

- `ext/PhyloNetworksExt.jl`
- any exact generic overlay helper additions required in `src/Layers.jl`
- extension-aware tests
- touched docs, vocabulary, roadmap, and example surfaces

The invariant being repaired is:

- `PhyloNetworks.jl` support must adapt upstream rooted network semantics into
  the settled core owners instead of becoming a shadow owner of traversal,
  geometry, or annotation
- rooted full-network support must render all normalized edges, not just the
  major tree
- hybrid-node, major-edge, minor-edge, and gamma-label semantics must come
  from upstream node and edge fields, not from labels, numbering conventions,
  or plotting accidents
- direct plotting convenience, rooted-scope diagnostics, tree non-regression,
  and touched docs must all describe and prove the same contract

The supported public surfaces affected by this tranche are:

- `lineageplot(::PhyloNetworks.HybridNetwork; kwargs...)`
- `lineageplot!(::Axis, ::PhyloNetworks.HybridNetwork; kwargs...)`
- `lineageplot!(::LineageAxis, ::PhyloNetworks.HybridNetwork; kwargs...)`
- touched README, docs, roadmap, example, and controlled-vocabulary surfaces
  that claim or describe optional rooted full-network support

## Authorization boundary

Authorized for this tranche:

- deep work in `ext/PhyloNetworksExt.jl`
- exact generic helper additions in `src/Layers.jl` if they are needed to keep
  core edge order and geometry ownership centralized
- extension-aware tests in `test/`
- touched source docstrings
- `STYLE-vocabulary.md`
- `README.md`
- `ROADMAP.md`
- `docs/src/index.md`
- one rooted full-network example script under `examples/src/`

Not authorized for this tranche:

- reopening topology ownership in `src/Topology.jl`
- reopening geometry ownership in `src/Geometry.jl`
- reopening tranche-3 annotation-boundary policy
- introducing public projection-selection or view-mode controls
- implementing major-tree projection or any other projected-tree surface
- implementing semidirected or unrooted display policy
- adding `PhyloNetworks.jl` to the root, docs, or examples environments
- arbitrary public breaks without explicit user approval and migration notes

## Primary-goal lock

### Lock 1: PhyloNetworks.jl remains an optional package extension

- The work is not complete if `PhyloNetworks.jl` becomes a hard dependency, or
  if the absence-case proof regresses back to "extension not yet loaded" inside
  an environment that already declares `PhyloNetworks.jl`.
- Direct red-state repro:
  current `HEAD` has the weak-dependency boundary in place, but the extension
  file is still a stub and there is still no tranche-4 public support surface
  beyond the existing activation probe.
- Closing tasks: 3 and 4.
- Verification artifact:
  isolated temporary-project import without `PhyloNetworks.jl` must still
  succeed, the extension must still remain absent in that case, activation in
  `test/Project.toml` must still succeed, and the root `Project.toml` must
  still keep `PhyloNetworks.jl` out of `[deps]`.

### Lock 2: the extension remains an adapter into the core owners rather than a shadow owner

- The work is not complete if the extension duplicates topology normalization,
  geometry construction, or tree-only annotation ownership instead of feeding
  the settled core owner path.
- Direct red-state repro:
  current `ext/PhyloNetworksExt.jl` is still only a stub, so the real adapter
  boundary does not exist yet and could still drift into a shadow owner when
  first implemented.
- Closing tasks: 2 and 3.
- Verification artifact:
  generic overlay helpers must stay source-agnostic in `src/Layers.jl`, and
  extension implementation plus tests must prove that edge order, edge shapes,
  and node positions still come from `LineageGraphGeometry` rather than from a
  second extension-local geometry owner.

### Lock 3: rooted full-network HybridNetwork plotting is a real public surface

- The work is not complete if a user still cannot directly call
  `lineageplot(net::HybridNetwork; ...)` or `lineageplot!(ax, net; ...)` on a
  rooted network without manually building a source-specific accessor.
- Direct red-state repro:
  current `HEAD` has no direct `HybridNetwork` plotting method at all.
- Closing tasks: 3 and 4.
- Verification artifact:
  direct plotting regressions on a real upstream fixture must succeed through
  both non-mutating and mutating entrypoints on both `Axis` and `LineageAxis`,
  with the settled rooted full-network default contract.

### Lock 4: rooted full-network rendering shows honest hybrid and reticulation primitives

- The work is not complete if rooted full-network support still lacks hybrid
  markers, major/minor reticulation edge distinction, or gamma labels on real
  upstream fixtures.
- Direct red-state repro:
  current `HEAD` has no render path at all for hybrid-node markers, major or
  minor edge distinction, or gamma labels on `HybridNetwork`.
- Closing tasks: 2, 3, and 4.
- Verification artifact:
  render-level and integration-level regressions on
  `PhyloNetworks.jl/examples/net1.out` must fail a fake fix that silently drops
  minor edges, renders only the major tree, or sources gamma from anything
  other than upstream edge fields.

### Lock 5: unsupported policy work is deferred honestly instead of hidden behind defaults

- The work is not complete if tranche 4 silently chooses major-tree,
  projected-tree, semidirected, or unrooted policy while claiming only rooted
  full-network support.
- Direct red-state repro:
  there is no current tranche-4 support surface, so an implementation agent
  could otherwise smuggle tranche-5 policy into the first live extension path.
- Closing tasks: 1, 3, 4, and 5.
- Verification artifact:
  direct rooted-scope diagnostics must reject non-rooted inputs, docs and
  vocabulary must name rooted full-network view explicitly, and no direct
  plotting regression may pass if only the major tree is shown.

### Lock 6: tree behavior, tranche-3 annotation boundaries, and public truth remain green

- The work is not complete if the extension regresses existing tree behavior,
  reopens tranche-3 annotation boundaries, or leaves public docs and
  vocabulary unable to describe the live support surface honestly.
- Direct red-state repro:
  current `HEAD` is green on tree and tranche-3 behavior, but it still lacks
  the vocabulary entries and rooted full-network docs that tranche 4 now needs.
- Closing tasks: 1, 4, and 5.
- Verification artifact:
  the existing full suite stays green, tranche-3 DAG guard regressions remain
  intact, touched docs build successfully, and one rooted full-network example
  renders from a real upstream fixture under the test environment.

## Handoff packet

- Active authorities:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the bundled
  development-policies baseline, the four design documents, the parent PRD,
  the tranche file, the completed tranche-1 through tranche-3 workflow
  artifacts listed above, and this tasking file
- Parent documents:
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
  and
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- Settled decisions and non-negotiables:
  rooted full-network view only in tranche 4; no shadow owner in `ext/`;
  tree-only annotation boundaries remain fixed; `PhyloNetworks.jl` remains a
  weak dependency; no docs or examples environment dependency changes
- Authorization boundary:
  deep work in `ext/`, tests, touched docs, vocabulary, example, and exact
  generic helper additions in `src/Layers.jl`; no topology or geometry owner
  redesign; no tranche-5 policy work
- Current-state diagnosis:
  the optional extension boundary exists and current `HEAD` is green, but the
  extension file is still a stub and no real `HybridNetwork` plotting or
  network primitives exist yet
- Primary-goal lock:
  lock items 1 through 6 above
- Direct red-state repros:
  `ext/PhyloNetworksExt.jl` is still a stub; direct `HybridNetwork` plotting
  methods are absent; no hybrid-marker or major/minor/gamma render path exists;
  the missing network vocabulary entries in `STYLE-vocabulary.md` still prevent
  a fully honest public truth boundary
- Owner and invariant under repair:
  extension-boundary ownership plus rooted full-network primitive ownership;
  invariant that the extension adapts upstream semantics into settled core
  owners rather than replacing them
- Exact files or surfaces in scope:
  `STYLE-vocabulary.md`, `src/Layers.jl` if strictly required,
  `ext/PhyloNetworksExt.jl`, `test/test_PhyloNetworksExt.jl`,
  `test/test_ExtensionBoundary.jl`, `test/test_Integration.jl`,
  `test/test_render_helpers.jl`, `test/runtests.jl`, `README.md`,
  `docs/src/index.md`, `ROADMAP.md`, and one rooted full-network example under
  `examples/src/`
- Exact files or surfaces out of scope:
  `src/Topology.jl`, `src/Geometry.jl`, `src/CoordinateTransform.jl`,
  public projection-selection API, major-tree or projected-tree view modes,
  semidirected or unrooted policy, docs or examples environment dependency
  changes, and unrelated ecosystem integrations
- Required upstream primary sources:
  the `PhyloNetworks.jl` and Makie files named above for this tranche
- Green-state gates:
  `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`,
  rooted full-network real-fixture regressions,
  optional-extension absence and activation proof,
  and one rooted full-network example render under `--project=test`
- Stop conditions:
  any requirement to move traversal or geometry ownership into `ext/`,
  any requirement for a new public projection or policy API,
  any need to accept semidirected or unrooted networks in tranche 4,
  any required public break, or any conflict between upstream rooted semantics
  and the settled rooted full-network scope

## Required revalidation before implementation

- Re-read the tranche and parent PRD in full.
- Re-read the completed tranche-1 through tranche-3 workflow artifacts listed
  above in full.
- Re-read `Project.toml`, `test/Project.toml`, `ext/PhyloNetworksExt.jl`,
  `src/Layers.jl`, touched tests, touched docs, and touched examples in full.
- Re-read the upstream primary sources listed above in full.
- Re-run or otherwise re-confirm the green baseline before substantial edits:
  - `julia --project=test test/runtests.jl`
  - `julia --project=docs docs/make.jl`
- Re-check that `test/Project.toml` still points at the reviewed local
  `PhyloNetworks.jl` checkout and that the root, docs, and examples
  environments still do not hard-depend on `PhyloNetworks.jl`.
- If current `HEAD` no longer matches this file's diagnosis, stop and rewrite
  the tasking rather than blindly executing it.

## Tranche execution rule

This tranche may refactor extension-local internals and add exact generic
overlay helpers where needed, but it must begin and end in the required green,
policy-compliant state.

The only supported network display contract authorized here is rooted
full-network view on `PhyloNetworks.HybridNetwork`.

When the tranche is complete:

- the extension boundary must remain optional
- rooted full-network `HybridNetwork` plotting must be live
- all reticulation edges must still be visible in that rooted full-network path
- major-tree or projected-tree support must still not exist unless explicitly
  named and approved in a later tranche
- semidirected and unrooted policy must still remain deferred

## Non-negotiable execution rules

- Do not add `PhyloNetworks.jl` to root `[deps]`.
- Do not add `PhyloNetworks.jl` to `docs/Project.toml` or
  `examples/Project.toml`.
- Do not put topology normalization, geometry construction, or tree-only
  annotation ownership into `ext/`.
- Do not reopen `NodeGroup*`, `group_nodes`, `clade_nodes`, or
  `NodeLabelLayer(position = :toward_parent)` policy.
- Do not silently coerce rooted full-network support into major-tree or any
  other projected-tree display.
- Do not accept `!net.isrooted` inputs as if rooted policy were already
  implemented.
- Do not derive hybrid semantics from labels, edge numbers alone, or plotting
  metadata when live upstream node and edge fields are available.
- Do not solve the tranche by moving product logic into tests, docs-string
  policing, or helper-only assertions that do not prove the rooted
  full-network render contract.

## Concrete anti-patterns or removal targets

- The stub-only `ext/PhyloNetworksExt.jl` state must disappear.
- Any extension-local traversal or geometry implementation that rebuilds the
  graph from `HybridNetwork.edge` independently of the settled core owner path
  is forbidden.
- Any supposed full-network implementation that silently drops minor
  reticulation edges and then calls the result `network support` is forbidden.
- Any use of `majoredgematrix`, `minorreticulationmatrix`, or
  `minorreticulationgamma` as the runtime adaptation owner is forbidden.
  Those helpers are verification references in this tranche, not the runtime
  owner.
- Any attempt to infer hybrid status from node names, labels, or string
  conventions is forbidden.
- Any partial migration that leaves direct plotting green only on `Axis` but
  not `LineageAxis`, or vice versa, is forbidden.
- Any docs claim that tranche-4 support already includes projected-tree,
  major-tree, semidirected, or unrooted policy is forbidden.

## Failure-oriented verification

- Keep the isolated extension-absence probe and ensure it still fails any fake
  fix that hard-depends on `PhyloNetworks.jl`.
- Add activation and integration tests in the checked-in `test/Project.toml`
  environment using the reviewed local upstream checkout at
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl`.
- Use a real upstream fixture. `PhyloNetworks.jl/examples/net1.out` is the
  canonical rooted full-network fixture for this tranche.
- Include at least one negative verification that fails if any minor
  reticulation edge from `net1.out` disappears from the supposed rooted
  full-network rendering.
- Include at least one negative verification that fails if hybrid markers are
  sourced from anything other than the real upstream hybrid-node set.
- Include at least one negative verification that fails if gamma labels are not
  sourced from upstream edge `gamma` values.
- Include at least one direct diagnostic regression for a non-rooted
  `HybridNetwork` input, proving the tranche-4 rooted-scope boundary is honest.
- Keep representative tree, node-group, clade, and `LineageAxis`
  non-regressions alongside the new extension work.
- End the tranche with:
  - `julia --project=test test/runtests.jl`
  - `julia --project=docs docs/make.jl`
  - `julia --project=test examples/src/phylonetworks_full_network_ex1.jl`

## Tasks

1. **Title**: Add tranche-4 network vocabulary and rooted full-network scope terms to `STYLE-vocabulary.md`
   **Type**: `MIGRATE`
   **Output**: `STYLE-vocabulary.md` contains canonical entries for
   `hybrid node`, `reticulation edge`, `major edge`, `minor edge`,
   `gamma label`, and `major-tree projection`, plus any needed cross-reference
   wording to the existing `tree view` and `full-network view` entries.
   **Depends on**: `none`
   **Positive contract**:
   downstream implementation, tests, docs, and examples can use one stable
   canonical term set for tranche-4 network semantics without reopening the
   settled tranche-3 vocabulary.
   **Negative contract**:
   do not rename or weaken the existing tranche-3 entries for `node group`,
   `group annotation`, `tree-only annotation surface`, or
   `graph-capable annotation surface`; do not claim tranche-5 support in the
   new entries.
   **Files**:
   `STYLE-vocabulary.md`
   **Out of scope**:
   any source code, tests, README, docs-site, roadmap, or example changes
   **Verification**:
   inspect the new entries for sentence-case heading compliance and stable
   prose; use `rg` to confirm the new canonical headings exist and that the
   existing `tree view`, `full-network view`, `node group`, and
   `group annotation` entries remain intact.

2. **Title**: Add source-agnostic edge-overlay and edge-label-anchor helpers to the core layer owner
   **Type**: `WRITE`
   **Output**: `src/Layers.jl` exposes internal helper functions that derive
   stable edge-shape subsets and edge-label anchor positions from
   `LineageGraphGeometry.edge_shapes` and `LineageGraphGeometry.edges` without
   re-traversing the source lineage graph.
   **Depends on**: `1`
   **Positive contract**:
   the core helper boundary remains source-agnostic, `LineageGraphGeometry`
   edge order remains the sole authority for overlay ordering, and the helpers
   are reusable by extension-local overlays without importing `PhyloNetworks.jl`
   into the core package.
   **Negative contract**:
   do not add `PhyloNetworks`-specific semantics or names to the core helper
   signatures; do not add a new public layer or exported API here; do not
   rebuild geometry from raw children traversal.
   **Files**:
   `src/Layers.jl`, `test/test_Layers.jl`
   **Out of scope**:
   `ext/PhyloNetworksExt.jl`, direct `HybridNetwork` plotting methods, docs,
   vocabulary beyond task 1, and any topology or geometry owner changes
   **Verification**:
   add helper regressions that prove subset edge order aligns to `geom.edges`
   on rectangular and radial layouts and that label anchors remain tied to the
   same edge groups; run `julia --project=test test/runtests.jl`.

3. **Title**: Implement rooted full-network `HybridNetwork` plotting and extension-local rendering primitives
   **Type**: `WRITE`
   **Output**: `ext/PhyloNetworksExt.jl` adds non-exported rooted adaptation
   helpers and metadata builders plus direct plotting methods for
   `HybridNetwork`; those methods default to rooted full-network
   `lineageunits = :nodelevels`, reject `!net.isrooted` directly, and compose
   extension-local overlays for hybrid-node markers, major and minor
   reticulation edges, and gamma labels on top of the settled core geometry
   and annotation owners.
   **Depends on**: `2`
   **Positive contract**:
   the extension uses `getroot`, `getchildren`, live upstream node and edge
   fields, and extension-local metadata keyed by the exact upstream parent and
   child node objects; direct plotting works through both `lineageplot` and
   `lineageplot!`; user-supplied `lineageunits` still route into the settled
   tranche-2 geometry rules unchanged.
   **Negative contract**:
   do not add public `lineagegraph_accessor(::HybridNetwork)` or geometry
   overloads; do not use `majoredgematrix` or `minorreticulationmatrix` as the
   runtime owner; do not implement a shadow geometry owner in `ext/`; do not
   accept semidirected or unrooted inputs; do not silently fallback to the
   major tree.
   **Files**:
   `ext/PhyloNetworksExt.jl`, `test/test_PhyloNetworksExt.jl`,
   `test/test_ExtensionBoundary.jl`, `test/runtests.jl`
   **Out of scope**:
   public styling controls, projected-tree or major-tree support, semidirected
   or unrooted display policy, README/docs/roadmap/example migration
   **Verification**:
   add minimal activation smoke tests that plot rooted
   `PhyloNetworks.jl/examples/net1.out` through both `lineageplot` and
   `lineageplot!`; keep the isolated absence-case probe green; keep the root
   `Project.toml` dependency boundary unchanged; run
   `julia --project=test test/runtests.jl`.

4. **Title**: Add the real-fixture extension proof surface and rooted-scope non-regression coverage
   **Type**: `TEST`
   **Output**: strong integration and render-level proof exists for rooted
   full-network `HybridNetwork` rendering, minor-edge presence, gamma-label
   content or placement, rooted-scope diagnostics, and tree or tranche-3
   non-regression.
   **Depends on**: `3`
   **Positive contract**:
   real upstream fixture tests prove that all normalized edges remain
   displayed, hybrid marker count matches the real hybrid-node set, major and
   minor reticulation edges remain distinguishable, gamma labels come from
   upstream edge `gamma` fields, and existing tree or node-group paths stay
   green.
   **Negative contract**:
   no test may accept a fake fix that drops minor edges, renders only the
   major tree, infers hybrid semantics from labels or node numbers alone, or
   silently treats `net.isrooted = false` as acceptable rooted input.
   **Files**:
   `test/test_PhyloNetworksExt.jl`, `test/test_Integration.jl`,
   `test/test_render_helpers.jl`, `test/test_ExtensionBoundary.jl`
   **Out of scope**:
   docs, roadmap, vocabulary, example scripts, and public styling controls
   **Verification**:
   run `julia --project=test test/runtests.jl`; include at least one negative
   regression that fails if a supposed full-network render omits any minor
   reticulation edge from `net1.out`, and one direct diagnostic regression for
   non-rooted `HybridNetwork` input.

5. **Title**: Migrate public docs, roadmap, and a rooted full-network example to the landed tranche-4 contract
   **Type**: `MIGRATE`
   **Output**: public docs and example surfaces truthfully describe optional
   rooted full-network `PhyloNetworks.jl` support, defer projected-tree and
   semidirected or unrooted policy to tranche 5, and include one runnable
   rooted full-network example based on a real upstream fixture.
   **Depends on**: `4`
   **Positive contract**:
   README, docs, and roadmap explain automatic extension activation when
   `PhyloNetworks.jl` is present, rooted full-network current scope, preserved
   tree behavior, and deferred tranche-5 policy work; the example saves one
   render artifact under a reproducible command.
   **Negative contract**:
   do not add `PhyloNetworks.jl` to root `[deps]`, `docs/Project.toml`, or
   `examples/Project.toml`; do not claim major-tree projection, projected-tree
   view, semidirected display, or unrooted display support; do not reopen the
   settled tranche-3 `group_nodes` versus `clade_nodes` contract.
   **Files**:
   `README.md`, `docs/src/index.md`, `ROADMAP.md`,
   `examples/src/phylonetworks_full_network_ex1.jl`
   **Out of scope**:
   core `src/` files, new view-mode API, docs environment dependency changes,
   examples environment dependency changes
   **Verification**:
   run `julia --project=docs docs/make.jl`; run
   `julia --project=test examples/src/phylonetworks_full_network_ex1.jl`;
   inspect the rendered artifact to confirm rooted full-network primitives are
   visible on a real fixture.
