---
date-created: 2026-05-08T23:46:33-07:00
date-revised: 2026-05-08T23:46:33-07:00
status: approved
---

# Tasks for tranche 5: network view modes, display policy completion, and extension hardening

Tasking identifier:
`20260508T234633--tranche-5-network-view-modes-display-policy-completion`

This file operationalizes tranche 5 from
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
against current `HEAD`.

It preserves the parent PRD and tranche intent, but it does not inherit the
parent tranche diagnosis blindly. Revalidation against current `HEAD` commit
`22b8bcd` shows that tranche 4 is now materially landed:

- the optional `PhyloNetworks.jl` extension boundary is live
- direct rooted full-network `HybridNetwork` plotting is live
- hybrid-node markers, major and minor reticulation-edge distinction, and
  gamma labels are live on the rooted full-network path
- README, docs, roadmap, tests, and the tranche-4 example now describe that
  rooted full-network contract honestly

The remaining tranche-5 work is therefore not "add network rendering" in the
abstract. The remaining work is the explicit public contract layered above the
already-landed rooted full-network foundation:

- one named public network-view selection surface
- one honest projected-tree contract rather than silent projection
- one explicit display-policy contract for any rooted, semidirected, or
  unrooted cases that the final product actually admits
- the final proof, docs, example, and workflow hardening that prevents silent
  projection, silent fallback, or stale tranche guidance from surviving behind
  a green suite

This tranche remains HITL. Current upstream and local sources are strong enough
to derive the projected-tree implementation direction, but they do not fully
derive the final public naming and value surface for display-policy control.
This tasking therefore begins with a mandatory `REVIEW` task that freezes that
contract before code work continues. Downstream AFK implementation is not
authorized until that review task is closed with a ratified artifact.

Parent tranche: Tranche 5  
Parent PRD:
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`  
Completed prerequisite workflow artifacts:

- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1a--remediation-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2a--remediation-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2b--remediation-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2c--final-audit.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2e--annotation-boundary-guard-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01--tranche3--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01a--tranche3--annotation-contract-ratification.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-02--tranche3-remediation-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-03_tranche-4--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-03a_tranche-4--remediation-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-03b_tranche-4--completion-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/04_final-audit--tranche-5-readiness.md`

## Settled decisions and environment baseline

- DAG lineage graphs remain first-class in the core owner model. Rooted trees
  remain the single-parent special case inside that same owner path.
- `src/Topology.jl`, `src/Geometry.jl`, and `src/Layers.jl` remain the settled
  core owners. Tranche 5 must build on those owners. It must not reopen them
  or regrow a source-specific shadow view owner in `ext/`.
- The tranche-3 annotation split remains fixed. `clade_nodes` and
  `NodeLabelLayer(position = :toward_parent)` remain tree-only surfaces.
  `group_nodes`, `NodeGroupHighlightLayer`, and `NodeGroupLabelLayer` remain
  the graph-capable annotation family.
- `PhyloNetworks.jl` remains an optional package extension. Do not add it to
  root `[deps]`, `docs/Project.toml`, or `examples/Project.toml`.
- The ratified accessor vocabulary uses `nodecoordinates` and
  `:nodecoordinates`. Do not reopen the spelling to `node_coordinates`.
- Revalidated environment decision: extension-absence verification does not run
  inside the checked-in `test/Project.toml` environment, because that
  environment already declares the reviewed local `PhyloNetworks.jl` checkout
  in both `[deps]` and `[sources]`. The absence case remains an isolated
  temporary-project or subprocess probe. The activation case remains
  `test/Project.toml`. This tasking supersedes the stale tranche-5 parent
  sentence that still says otherwise.
- The settled tranche-4 default contract remains preserved:
  direct `lineageplot(net::PhyloNetworks.HybridNetwork; ...)` and
  `lineageplot!(ax, net::PhyloNetworks.HybridNetwork; ...)` continue to mean
  rooted full-network view if the new tranche-5 control surface is not
  supplied explicitly.
- The tranche-5 projected-tree contract is narrowed here to
  `major-tree projection`. Do not expose arbitrary `displayedtrees(...)`
  enumeration, gamma-threshold tree selection, or custom per-hybrid
  projection policy in this tranche unless Task 1 review explicitly ratifies
  such a surface and the tasking is amended accordingly.
- Weighted-unit semantics must stay split by named contract:
  full-network view continues to obey the settled tranche-2 and tranche-4
  full-network consistency rules, while any projected-tree weighted request
  must run on the named projected-tree contract rather than by silently
  coercing the full-network path.
- Examples and docs environments remain unchanged in this tranche. New example
  scripts must run under `--project=test`.
- No generic DAG-wide view-mode API is authorized here. The new public control
  surface, if approved, applies only to the direct `HybridNetwork` extension
  entrypoints in tranche 5.

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
- the prerequisite tranche and audit artifacts listed above
- this tasking file
- the ratification artifact created by task 1 once it exists

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
- The existing tranche-3 and tranche-4 terms `tree view`, `full-network view`,
  `hybrid node`, `reticulation edge`, `major edge`, `minor edge`,
  `gamma label`, `major-tree projection`, `node group`,
  `group annotation`, `tree-only annotation surface`, and
  `graph-capable annotation surface` remain settled and must not be reopened.
- Tranche 5 must add the missing public-contract terms before code, docs, or
  examples use them as settled vocabulary:
  - `projected-tree view`
  - `display policy`
  - any approved `rooted`, `semidirected`, or `unrooted` display-policy terms
  - any approved exact API-name cross-references for the ratified public
    keyword surface
- Do not call a `major-tree projection` a `full-network view`.
- Do not call a `full-network view` a `major tree`.
- Do not describe a hidden fallback from full-network to major-tree as
  `network support`.
- If Task 1 ratifies the spelling `semidirected`, use that exact spelling
  consistently and do not switch between `semidirected` and `semi-directed`
  inside local workflow or public docs.

## Upstream primary sources and required local sources

Read these upstream primary sources line by line before implementation:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/compareNetworks.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/graph_components.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/auxiliary.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/netmanipulation.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/net_plot.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/dist_reroot.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/generic/space.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/plots/text.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/makielayout/types.jl`

Read these local owner and proof files line by line before implementation:

- `src/Topology.jl`
- `src/Geometry.jl`
- `src/Layers.jl`
- `ext/PhyloNetworksExt.jl`
- `test/Project.toml`
- `test/test_PhyloNetworksExt.jl`
- `test/test_ExtensionBoundary.jl`
- `test/test_Integration.jl`
- `README.md`
- `docs/src/index.md`
- `ROADMAP.md`
- `examples/src/phylonetworks_full_network_ex1.jl`

These sources constrain tranche 5 as follows:

- `compareNetworks.jl` defines `displayedtrees(...)`, `majortree(...)`,
  `minortreeat(...)`, and the `unroot` behavior that matters for any named
  projected-tree contract.
- `graph_components.jl` defines `checkroot!` and the upstream validity check
  for semidirected root placement.
- `auxiliary.jl` defines the rooted parent and child access contracts and the
  major-tree node-height helpers that matter for weighted projection behavior.
- `net_plot.md` verifies that upstream distinguishes full-tree and major-tree
  plotting styles and that gamma annotations belong to the full-network path.
- `netmanipulation.md` and `dist_reroot.md` verify that rooted and
  semidirected or unrooted readings are distinct upstream concepts rather than
  one silent plotting default.
- Makie space, text, and block-owner sources constrain how the extension may
  place gamma labels, omit them on projected trees, and preserve the existing
  `Axis` versus `LineageAxis` ownership split.

## Revalidated current state

- Tranche 1 through tranche 4 foundational owner work is present in current
  `HEAD`. `src/Topology.jl`, `src/Geometry.jl`, and `src/Layers.jl` already
  own DAG-safe topology, geometry, and the tree-only versus graph-capable
  annotation split.
- `ext/PhyloNetworksExt.jl` already adapts rooted `HybridNetwork` inputs into
  the settled core path and adds full-network overlays for hybrid markers,
  major and minor reticulation edges, and gamma labels.
- Current direct extension entrypoints still hard-code one scope only:
  rooted full-network view. There is no explicit public view selector and no
  named projected-tree surface yet.
- Current `README.md`, `docs/src/index.md`, and `ROADMAP.md` now describe the
  live rooted full-network extension honestly and still defer major-tree or
  projected-tree view, semidirected display, and unrooted display.
- Current `STYLE-vocabulary.md` now reflects the ratified `nodecoordinates`
  spelling and includes `major-tree projection`, but it still lacks canonical
  entries for `projected-tree view`, `display policy`, and any approved
  rooted, semidirected, or unrooted display-policy terms.
- Current `test/test_ExtensionBoundary.jl` already proves the isolated
  absence-case probe and the checked-in activation case. Current
  `test/Project.toml` already declares the reviewed local `PhyloNetworks.jl`
  checkout in `[deps]` and `[sources]`.
- Current `src/Geometry.jl`, `test/test_Geometry.jl`, and
  `test/test_Integration.jl` already reject ambiguous weighted full-network
  requests and explicitly tell the user to select a projected-tree or other
  named resolution contract instead. Tranche 5 must land that missing named
  contract rather than weakening the rejection.
- Current `test/test_PhyloNetworksExt.jl` already contains the real upstream
  rooted fixture `net1.out` and the rooted 2-cycle fixtures that can serve as
  the tranche-5 proof baseline for full-network versus projected-tree
  distinction.
- Current tranche-5 parent text in `02_tranches.md` still contains one stale
  environment sentence saying that the absence case should run in the
  checked-in `test/Project.toml` environment without `PhyloNetworks.jl`
  present there. This tasking corrects that diagnosis and passes the corrected
  environment rule forward explicitly.
- Planning-time revalidation on 2026-05-08 reconfirmed that
  `julia --project=docs docs/make.jl` succeeds with the existing
  `index.md` size warning. A fresh `julia --project=test test/runtests.jl`
  baseline run was started during this tasking pass but had not finished at
  save time, so downstream execution must rerun and record the full test
  baseline before substantial code edits.

## Ownership and invariant framing

The owner under repair is the explicit network-view and display-policy
normalization surface spanning:

- `ext/PhyloNetworksExt.jl`
- any exact core helper touch needed to preserve one canonical owner path
- extension-aware tests
- touched docs, examples, roadmap, vocabulary, and workflow surfaces

The invariant being repaired is:

- one explicit public control surface must choose the display contract once
- rooted full-network view must remain the default direct `HybridNetwork`
  contract unless the user explicitly selects another named view
- major-tree projection must be a real named projected-tree contract, not a
  silent fallback or a fake fix for weighted ambiguity
- any rooted, semidirected, or unrooted display policy admitted by the final
  product must be explicit, documented, and consistently verified
- full-network and projected-tree paths must continue to build on the settled
  core topology and geometry owners rather than spawning a second owner in
  `ext/`

The supported public surfaces affected by this tranche are:

- `lineageplot(::PhyloNetworks.HybridNetwork; kwargs...)`
- `lineageplot!(::Axis, ::PhyloNetworks.HybridNetwork; kwargs...)`
- `lineageplot!(::LineageAxis, ::PhyloNetworks.HybridNetwork; kwargs...)`
- touched README, docs, roadmap, example, and controlled-vocabulary surfaces
  that claim or describe final `PhyloNetworks.jl` network support

## Authorization boundary

Authorized for this tranche:

- deep work in `ext/PhyloNetworksExt.jl`
- exact generic helper additions in `src/Layers.jl` or other settled core
  files only if they are strictly required to keep one owner path and the
  change remains source-agnostic
- extension-aware tests in `test/`
- touched source docstrings
- `STYLE-vocabulary.md`
- `README.md`
- `ROADMAP.md`
- `docs/src/index.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- one new tranche-5 example script under `examples/src/`

Not authorized for this tranche:

- reopening topology ownership in `src/Topology.jl`
- reopening geometry ownership in `src/Geometry.jl`
- reopening tranche-3 annotation-boundary policy
- adding `PhyloNetworks.jl` to the root, docs, or examples environments
- exposing arbitrary displayed-tree enumeration, gamma-threshold projection
  controls, or custom reticulation-choice policy without an explicit amendment
  after Task 1 review
- changing generic non-`HybridNetwork` public plotting entrypoints
- arbitrary public breaks without explicit user approval and migration notes

## Primary-goal lock

### Lock 1: `PhyloNetworks.jl` remains an honest optional package extension

- The work is not complete if `PhyloNetworks.jl` becomes a hard dependency, or
  if the extension-absence proof regresses back to the stale parent-tranche
  story that assumes the checked-in `test/Project.toml` environment can prove
  absence.
- Direct red-state repro:
  current root `Project.toml` still keeps `PhyloNetworks.jl` out of `[deps]`,
  and current `test/test_ExtensionBoundary.jl` already uses an isolated
  absence probe, but the tranche-5 parent text still carries a stale
  contradictory sentence.
- Closing tasks: 5 and 6.
- Verification artifact:
  the isolated temporary-project absence probe must remain green, activation in
  `test/Project.toml` must remain green, root `[deps]` must still omit
  `PhyloNetworks.jl`, and touched docs or workflow artifacts must describe the
  same absence-versus-activation environment baseline.

### Lock 2: one explicit public network-view surface exists and no hidden projection survives

- The work is not complete if direct `HybridNetwork` plotting still silently
  chooses one projection, still hides the chosen contract behind internal
  defaults, or still lacks a named public control surface for view selection.
- Direct red-state repro:
  current direct extension methods only implement rooted full-network view and
  provide no named projected-tree surface at all.
- Closing tasks: 1, 3, 5, and 6.
- Verification artifact:
  direct API tests on `lineageplot`, `lineageplot!(::Axis, ...)`, and
  `lineageplot!(::LineageAxis, ...)` must prove that the final supported view
  surface is named explicitly, that the default remains rooted full-network,
  and that projected-tree selection does not appear only as undocumented
  behavior.

### Lock 3: major-tree projection is a real named projected-tree contract

- The work is not complete if the package still cannot render the same real
  network fixture in both full-network view and major-tree projection, or if a
  supposed projected-tree render is still just the full-network path with some
  overlays hidden.
- Direct red-state repro:
  current `HEAD` has full-network primitives only and still defers all
  projected-tree support to tranche 5.
- Closing tasks: 1, 3, 5, and 6.
- Verification artifact:
  render-level and integration-level regressions on the same rooted upstream
  fixture must distinguish the full-network and major-tree paths directly and
  fail a fake fix that makes both modes produce the same displayed contract.

### Lock 4: rooted, semidirected, and unrooted policy questions are explicit and review-governed

- The work is not complete if rooted, semidirected, or unrooted behavior
  remains guessed, hidden, or inconsistent across public entrypoints, or if
  unsupported combinations still fail only through generic accidents.
- Direct red-state repro:
  current `ext/PhyloNetworksExt.jl` hard-rejects `!net.isrooted`, while the
  parent PRD and tranche file still reserve a tranche-5 decision point for any
  semidirected or unrooted display policy that the final product actually
  admits.
- Closing tasks: 1, 4, 5, and 6.
- Verification artifact:
  Task 1 must produce a ratified contract artifact; the landed code and tests
  must then prove every approved combination directly and must fail every
  unsupported combination with an exact contract-level diagnostic.

### Lock 5: weighted coordinate semantics remain honest across named view contracts

- The work is not complete if ambiguous weighted full-network requests are now
  silently coerced into the major tree, or if the new projected-tree contract
  still routes weighted requests through the full-network validator and fails
  only because the projection was never actually applied.
- Direct red-state repro:
  current `src/Geometry.jl` and tests already name projected-tree selection as
  the honest escape hatch for weighted ambiguity, but no named projected-tree
  path exists yet in the direct `HybridNetwork` API.
- Closing tasks: 3 and 5.
- Verification artifact:
  negative regressions must show that full-network weighted ambiguity still
  fails directly, and positive regressions must show that the same network
  succeeds when the user selects the named projected-tree contract.

### Lock 6: docs, examples, roadmap, and workflow truth match the final product

- The work is not complete if README, docs, roadmap, examples, or touched
  workflow documents still say that projected-tree view or display policy is
  deferred after the tranche has landed, or if they claim support that the
  tests do not actually prove.
- Direct red-state repro:
  current `README.md`, `docs/src/index.md`, and `ROADMAP.md` still describe
  projected-tree and semidirected or unrooted work as deferred, because that
  is true at current `HEAD`.
- Closing tasks: 2, 5, and 6.
- Verification artifact:
  touched docs build successfully, examples render successfully under
  `--project=test`, and a contract-alignment review of README, docs, roadmap,
  example comments, and touched workflow text finds no surviving stale
  tranche-4-only truth boundary.

### Lock 7: tree behavior and the settled DAG core remain green beside the new network modes

- The work is not complete if tranche-5 network-view work regresses existing
  tree, DAG, node-group, clade, or `LineageAxis` behavior.
- Direct red-state repro:
  current `HEAD` is already green on the settled tree and DAG owner paths, so
  tranche-5 work could still overfit to network-specific logic and regress the
  special-case tree path.
- Closing tasks: 3, 4, 5, and 6.
- Verification artifact:
  the full suite remains green, tree and tranche-3 DAG boundary regressions
  remain intact, and no new direct `HybridNetwork` path bypasses the settled
  core owners.

## Handoff packet

- Active authorities:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the bundled
  development-policies baseline, the four design documents, the parent PRD,
  the tranche file, the prerequisite workflow artifacts listed above, this
  tasking file, and the ratification artifact created by task 1 once it
  exists
- Parent documents:
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
  and
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- Settled decisions and non-negotiables:
  core DAG owners stay closed; rooted full-network direct plotting remains the
  default; major-tree projection is the tranche-5 projected-tree target; the
  absence-case proof remains isolated from `test/Project.toml`; any remaining
  public-control ambiguity must stop for review before code proceeds
- Authorization boundary:
  deep work in `ext/`, tests, touched docs, example, roadmap, vocabulary, and
  touched workflow truth surfaces; no topology or geometry redesign; no new
  generic DAG API; no arbitrary displayed-tree enumeration or public break
  without review
- Current-state diagnosis:
  rooted full-network support is landed and truthful, but there is still no
  explicit public network-view selector, no named projected-tree surface, no
  ratified final display-policy surface, and one stale environment sentence
  survives in the tranche-5 parent text
- Primary-goal lock:
  lock items 1 through 7 above
- Direct red-state repros:
  direct `HybridNetwork` plotting still offers rooted full-network only;
  `src/Geometry.jl` tells users to choose a projected-tree contract that does
  not yet exist; docs and roadmap still defer projected-tree and display
  policy; the parent tranche still misstates the absence-case environment
- Owner and invariant under repair:
  explicit network-view and display-policy normalization on the direct
  `HybridNetwork` entrypoints; invariant that view selection is named,
  explicit, and still layered over the settled DAG core owners
- Exact files or surfaces in scope:
  `STYLE-vocabulary.md`, `ext/PhyloNetworksExt.jl`,
  `test/test_PhyloNetworksExt.jl`, `test/test_ExtensionBoundary.jl`,
  `test/test_Integration.jl`, `test/runtests.jl`, `README.md`,
  `docs/src/index.md`, `ROADMAP.md`,
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`,
  `examples/src/phylonetworks_full_network_ex1.jl`, and
  `examples/src/phylonetworks_view_modes_ex1.jl`
- Exact files or surfaces out of scope:
  `src/Topology.jl`, `src/Geometry.jl`, `src/CoordinateTransform.jl`, generic
  DAG plotting APIs, arbitrary displayed-tree enumeration, unrelated layout
  families, docs or examples environment dependency changes, and unrelated
  ecosystem integrations
- Required upstream primary sources:
  the `PhyloNetworks.jl` and Makie files named above for this tranche
- Green-state gates:
  `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`,
  the isolated extension-absence probe,
  rooted full-network versus major-tree real-fixture regressions,
  and the tranche-5 examples under `--project=test`
- Stop conditions:
  no Task 1 ratification artifact exists;
  Task 1 requires a public break or a different file surface than this tasking
  authorizes;
  any proposed implementation moves foundational owner work back into tranche 5;
  any proposed implementation adds arbitrary displayed-tree enumeration or a
  hidden fallback instead of one named projected-tree contract;
  any conflict arises between the ratified review outcome and the current code,
  tests, or upstream sources

## Required revalidation before implementation

- Re-read the tranche and parent PRD in full.
- Re-read the prerequisite tranche and audit artifacts listed above in full.
- Complete Task 1 review first and do not proceed to code without the
  ratification artifact it creates.
- Re-read `Project.toml`, `test/Project.toml`, `ext/PhyloNetworksExt.jl`,
  `src/Geometry.jl`, `src/Layers.jl`, `test/test_Geometry.jl`,
  `test/test_Integration.jl`, `test/test_PhyloNetworksExt.jl`,
  `test/test_ExtensionBoundary.jl`, touched docs, and touched examples in
  full.
- Re-read the upstream primary sources listed above in full.
- Re-run or otherwise re-confirm the green baseline before substantial edits:
  - `julia --project=test test/runtests.jl`
  - `julia --project=docs docs/make.jl`
- Reconfirm that the isolated absence-case probe still proves extension absence
  outside the checked-in `test/Project.toml` environment.
- Reconfirm that `test/Project.toml` still points at the reviewed local
  `PhyloNetworks.jl` checkout and that the root, docs, and examples
  environments still do not hard-depend on `PhyloNetworks.jl`.
- If current `HEAD`, the Task 1 ratification artifact, or the upstream sources
  no longer match this file's diagnosis, stop and rewrite the tasking rather
  than blindly executing it.

## Tranche execution rule

This tranche begins with a required `REVIEW` task and may proceed AFK only
after that review is ratified in writing.

When the tranche is complete:

- the extension boundary must still remain optional
- rooted full-network direct plotting must still be live as the default direct
  `HybridNetwork` contract
- a named `major-tree projection` contract must be live beside that default
- any admitted rooted, semidirected, or unrooted display-policy combinations
  must be explicit, documented, and directly verified
- unsupported combinations must fail directly with exact named diagnostics
- hidden projection and hidden fallback must not survive anywhere in code,
  tests, docs, examples, or workflow truth surfaces

## Non-negotiable execution rules

- Do not add `PhyloNetworks.jl` to root `[deps]`.
- Do not add `PhyloNetworks.jl` to `docs/Project.toml` or
  `examples/Project.toml`.
- Do not reopen topology normalization, geometry construction, or the
  tranche-3 annotation split.
- Do not silently auto-switch from `full-network view` to
  `major-tree projection` because a weighted request would otherwise fail.
- Do not expose arbitrary `displayedtrees(...)` enumeration, gamma-threshold
  tree selection, or custom per-reticulation view policy unless Task 1 review
  explicitly ratifies that exact public contract and this tasking is amended.
- Do not claim semidirected or unrooted support unless the exact approved
  combinations are implemented and directly verified.
- Do not leave the absence-case proof coupled to the checked-in
  `test/Project.toml` environment.
- Do not solve the tranche by moving product logic into tests, docs-string
  policing, or helper-only assertions that do not prove the final display
  contract.

## Concrete anti-patterns or removal targets

- Any hidden fallback that renders only the major tree and then calls the
  result `network support` is forbidden.
- Any new public surface that uses a weighted full-network failure as an
  undocumented trigger to choose a tree projection is forbidden.
- Any full-network implementation that simply hides tranche-4 reticulation
  overlays and calls the result a projected-tree view is forbidden.
- Any projected-tree implementation that rebuilds a second topology or geometry
  owner in `ext/` is forbidden.
- Any docs or workflow text that still says the absence case runs in the
  checked-in `test/Project.toml` environment is forbidden.
- Any docs claim that still says projected-tree or display-policy work is
  deferred after this tranche lands is forbidden.
- Any semidirected or unrooted support claim that lives only in docs or only
  in tests without a matching public API and exact diagnostics is forbidden.

## Failure-oriented verification

- Preserve the isolated extension-absence probe and ensure it still fails any
  fake fix that hard-depends on `PhyloNetworks.jl`.
- Use one real upstream rooted fixture for full-network versus projected-tree
  distinction. `PhyloNetworks.jl/examples/net1.out` remains the canonical
  rooted full-network fixture.
- Use the existing rooted 2-cycle fixtures in `test/test_PhyloNetworksExt.jl`
  to prove the weighted semantic split:
  the full-network path must still fail on ambiguous weighted requests where
  appropriate, while the named `major-tree projection` path must succeed on
  the projected tree when that is the honest contract.
- Add at least one negative verification that fails if `full-network view`
  and `major-tree projection` produce the same displayed contract on a real
  fixture.
- Add at least one negative verification that fails if a full-network render
  silently drops any minor reticulation edge from `net1.out`.
- Add at least one positive verification that the named projected-tree path
  no longer shows hybrid markers or gamma labels that belong only to the
  full-network reticulation overlays.
- For every review-approved rooted, semidirected, or unrooted combination, add
  one direct API regression and one direct diagnostic regression for at least
  one unsupported neighboring combination.
- Keep representative tree, node-group, clade, and `LineageAxis`
  non-regressions beside the new extension work.
- End the tranche with:
  - `julia --project=test test/runtests.jl`
  - `julia --project=docs docs/make.jl`
  - `julia --project=test examples/src/phylonetworks_full_network_ex1.jl`
  - `julia --project=test examples/src/phylonetworks_view_modes_ex1.jl`

## Tasks

1. **Title**: Ratify the tranche-5 public network-view and display-policy contract
   **Type**: `REVIEW`
   **Output**: a ratified review artifact exists at
   `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04a_tranche-5--view-policy-ratification.md`
   and settles the exact public control surface for tranche 5 before code work
   proceeds.
   **Depends on**: `none`
   **Positive contract**:
   the review artifact must settle all of the following explicitly:
   - whether the public surface uses the recommended split control family of
     one view selector plus one display-policy selector, or a different exact
     approved family
   - the exact keyword names and exact symbol values
   - the exact default behavior for the direct `HybridNetwork` entrypoints
   - whether semidirected and unrooted support is in scope now, and if so,
     which exact view and policy combinations are admitted
   - whether the projected-tree contract in tranche 5 is exactly
     `major-tree projection`
   - the exact diagnostics for unsupported combinations
   The recommended contract family for review is:
   - `networkview` with values `:fullnetwork` and `:majortree`
   - `displaypolicy` with default `:rooted`
   - optional `:semidirected` and `:unrooted` only if the review ratifies
     exact meanings and verification
   - default direct plotting remains
     `networkview = :fullnetwork, displaypolicy = :rooted`
   **Negative contract**:
   do not let the implementing agent choose names, default values, or
   semidirected or unrooted semantics silently inside code; do not proceed to
   code if the review outcome would require a public break, a generic DAG API,
   or arbitrary displayed-tree enumeration not authorized by this tasking.
   **Files**:
   `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04a_tranche-5--view-policy-ratification.md`
   **Out of scope**:
   project source files, tests, README, docs site, roadmap, examples, and
   `STYLE-vocabulary.md`
   **Verification**:
   the review artifact must restate active authorities, parent documents, the
   exact approved keyword surface, approved or forbidden view and policy
   combinations, default behavior, unsupported-combination diagnostics,
   vocabulary implications, and any stop conditions. If the review does not
   resolve those items exactly, stop and rewrite the tasking rather than
   continuing.

2. **Title**: Ratify tranche-5 projected-tree and display-policy vocabulary
   **Type**: `MIGRATE`
   **Output**: `STYLE-vocabulary.md` contains canonical entries for
   `projected-tree view`, `display policy`, and the approved rooted,
   semidirected, or unrooted policy terms, plus any exact API-spelling
   cross-reference wording required by the Task 1 ratification artifact.
   **Depends on**: `1`
   **Positive contract**:
   downstream implementation, tests, docs, examples, and workflow text can use
   one stable canonical term set for tranche-5 network-view and display-policy
   semantics without reopening the settled tranche-3 or tranche-4 vocabulary.
   **Negative contract**:
   do not rename or weaken the existing `nodecoordinates`, `tree view`,
   `full-network view`, `major-tree projection`, `node group`,
   `group annotation`, `tree-only annotation surface`, or
   `graph-capable annotation surface` entries; do not mark unsupported display
   policies as live.
   **Files**:
   `STYLE-vocabulary.md`
   **Out of scope**:
   source code, tests, README, docs site, roadmap, examples, and workflow docs
   **Verification**:
   inspect the new entries for sentence-case heading compliance and stable
   prose; use `rg` to confirm that the new canonical headings exist and that
   the existing tranche-3 and tranche-4 entries named above remain intact;
   run `julia --project=test test/runtests.jl`.

3. **Title**: Implement one canonical direct `HybridNetwork` view selector and the `major-tree projection` path
   **Type**: `WRITE`
   **Output**: `ext/PhyloNetworksExt.jl` resolves the ratified tranche-5
   view-selection surface once for all direct `HybridNetwork` entrypoints,
   preserves rooted full-network view as the default direct contract, and adds
   the named `major-tree projection` path using the exact upstream helper route
   ratified in Task 1.
   **Depends on**: `1, 2`
   **Positive contract**:
   - one owner normalizes the ratified view selector once across
     `lineageplot`, `lineageplot!(::Axis, ...)`, and
     `lineageplot!(::LineageAxis, ...)`
   - the default direct `HybridNetwork` path remains rooted full-network view
   - the projected-tree path is a real named `major-tree projection`
   - full-network mode keeps the tranche-4 reticulation overlays
   - projected-tree mode routes through the settled core owners on the
     projected tree and does not inherit full-network-only overlays
   - weighted full-network requests continue to obey the settled full-network
     validators, while weighted projected-tree requests run on the projected
     tree contract
   **Negative contract**:
   do not silently fallback from full-network to major-tree on any error; do
   not expose arbitrary displayed-tree enumeration or gamma-threshold controls;
   do not build a second topology or geometry owner in `ext/`; do not change
   generic non-`HybridNetwork` plotting entrypoints.
   **Files**:
   `ext/PhyloNetworksExt.jl`, `test/test_PhyloNetworksExt.jl`
   **Out of scope**:
   README, docs site, roadmap, examples, workflow docs, and extension-boundary
   proof hardening beyond the minimum coverage needed to keep this task green
   **Verification**:
   add or update direct plotting regressions that prove the ratified selector
   exists and that the same rooted fixture can render in both full-network view
   and major-tree projection; keep the rooted full-network default green; run
   `julia --project=test test/runtests.jl`.

4. **Title**: Implement the ratified display-policy behavior and exact unsupported-combination diagnostics
   **Type**: `WRITE`
   **Output**: `ext/PhyloNetworksExt.jl` implements the exact rooted,
   semidirected, and unrooted combinations admitted by Task 1, or else
   replaces the current blanket `!net.isrooted` boundary with the exact
   ratified diagnostics that name the supported combinations honestly.
   **Depends on**: `1, 2, 3`
   **Positive contract**:
   every approved display-policy combination is explicit, consistently routed
   through the ratified owner path, and described by one stable contract across
   all direct `HybridNetwork` entrypoints; every unsupported neighboring
   combination fails directly with the exact named diagnostic ratified in
   Task 1.
   **Negative contract**:
   do not guess semidirected or unrooted semantics beyond the Task 1 artifact;
   do not allow `displaypolicy` to become a hidden fallback path; do not claim
   full-network unrooted or semidirected support unless that exact combination
   is ratified and implemented directly.
   **Files**:
   `ext/PhyloNetworksExt.jl`, `test/test_PhyloNetworksExt.jl`,
   `test/test_Integration.jl`
   **Out of scope**:
   README, docs site, roadmap, examples, workflow docs, and arbitrary
   projection-policy expansion beyond the Task 1 artifact
   **Verification**:
   add direct API regressions for every approved rooted, semidirected, or
   unrooted combination and at least one diagnostic regression for an
   unsupported neighboring combination; run
   `julia --project=test test/runtests.jl`.

5. **Title**: Add the real-fixture proof surface for full-network versus projected-tree behavior and extension-boundary hardening
   **Type**: `TEST`
   **Output**: strong integration and render-level proof exists for the final
   tranche-5 contract, including full-network versus major-tree distinction,
   weighted semantic split, approved display-policy combinations, unsupported
   combination diagnostics, and preserved optional-extension behavior.
   **Depends on**: `3, 4`
   **Positive contract**:
   - real upstream fixture tests distinguish full-network view from
     major-tree projection directly
   - full-network view still shows minor edges, hybrid markers, and gamma
     labels where the contract says it should
   - major-tree projection does not pretend to be a full-network render
   - ambiguous weighted full-network requests still fail directly
   - the same network can succeed under the named projected-tree contract
   - the isolated absence-case proof and checked-in activation case remain
     green and truthful
   - existing tree and DAG non-regressions remain green
   **Negative contract**:
   no test may accept a fake fix that drops minor edges in full-network mode,
   makes full-network and projected-tree renders identical, hides the
   projection choice behind weighted-unit fallbacks, or claims semidirected or
   unrooted support only through accidental behavior.
   **Files**:
   `test/test_PhyloNetworksExt.jl`, `test/test_ExtensionBoundary.jl`,
   `test/test_Integration.jl`, `test/test_render_helpers.jl`, `test/runtests.jl`
   **Out of scope**:
   public docs, roadmap, examples, and workflow docs
   **Verification**:
   run `julia --project=test test/runtests.jl`; include at least one negative
   regression that fails if a full-network render silently degenerates into the
   major tree, one positive regression that the named projected-tree path
   succeeds on a case where weighted full-network would remain ambiguous, and
   one direct boundary regression for an unsupported view and policy
   combination named by Task 1.

6. **Title**: Migrate public docs, examples, roadmap, and touched workflow truth to the final tranche-5 contract
   **Type**: `MIGRATE`
   **Output**: public docs, examples, roadmap, and touched workflow surfaces
   truthfully describe the landed network-view and display-policy contract and
   include one runnable tranche-5 example that proves the view distinction on a
   real upstream fixture.
   **Depends on**: `2, 5`
   **Positive contract**:
   README, docs, roadmap, and examples explain optional extension activation,
   rooted full-network default behavior, named `major-tree projection`, the
   exact approved display-policy combinations, preserved tree behavior, and the
   corrected absence-versus-activation environment baseline; the new example
   script renders a side-by-side or otherwise direct comparison of the named
   view contracts on one real fixture.
   **Negative contract**:
   do not add `PhyloNetworks.jl` to root `[deps]`, `docs/Project.toml`, or
   `examples/Project.toml`; do not claim arbitrary displayed-tree enumeration
   or unsupported display policies; do not leave the stale tranche-5
   `test/Project.toml` absence-case sentence alive in `02_tranches.md` if it
   still survives when this task lands.
   **Files**:
   `README.md`, `docs/src/index.md`, `ROADMAP.md`,
   `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`,
   `examples/src/phylonetworks_full_network_ex1.jl`,
   `examples/src/phylonetworks_view_modes_ex1.jl`
   **Out of scope**:
   core owner redesign, new dependencies, arbitrary new projected-tree modes,
   and unrelated docs cleanup
   **Verification**:
   run `julia --project=docs docs/make.jl`; run
   `julia --project=test examples/src/phylonetworks_full_network_ex1.jl`; run
   `julia --project=test examples/src/phylonetworks_view_modes_ex1.jl`;
   inspect the rendered artifact to confirm that the example shows the named
   view distinction honestly; run `julia --project=test test/runtests.jl`.
