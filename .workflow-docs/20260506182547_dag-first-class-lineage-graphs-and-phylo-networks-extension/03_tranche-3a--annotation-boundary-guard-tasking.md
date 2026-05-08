---
date-created: 2026-05-07T19:18:48-07:00
date-revised: 2026-05-07T19:18:48-07:00
status: approved
---

# Tasks for Tranche 3A Immediate Action: tree-only annotation boundary guards and honest public contract

Tasking identifier: `20260507T191848--tranche-3a-annotation-boundary-guard-tasking`

This file is a special immediate-action packet pulled forward from tranche 3
after the tranche-2 final audit. It does not replace the full tranche-3
contract in
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`.
It closes only the currently active truth-boundary gap:

- generic annotation surfaces still accept DAG-capable full-network views under
  tree-only ownership
- public docs and docstrings still over-generalize those surfaces

After this packet lands, the broader graph-capable annotation-owner split,
group or projection contracts, and full docs cleanup still remain tranche-3
work.

Parent tranche: Tranche 3  
Parent PRD: `01_prd.md`  
Completed prerequisites: Tranche 1, Tranche 2, and
`04_tranche-2--final-audit.md`

## Settled decisions and immediate scope

- This packet is an honesty and boundary-repair action, not the full
  annotation-owner redesign.
- `src/Layers.jl` remains the owner under repair. Do not reopen tranche-2
  topology or geometry ownership.
- No public `LineageGraphGeometry` field change, no new projection or group
  API, no network rendering primitives, and no `PhyloNetworks.jl` extension
  work are authorized here.
- Tree-only annotation semantics may survive, but only where they are honest.
  On a displayed full-network view that is not a tree, the current generic
  annotation surfaces must fail directly instead of silently choosing one
  parent or pretending a group is one subtree.
- The immediate truth boundary is settled as follows:
  - `LeafLabelLayer` remains graph-safe and is not under repair here.
  - `NodeLabelLayer(position = :toward_parent)` is tree-only until tranche 3
    introduces an explicit graph-capable parent or projection contract.
  - `CladeHighlightLayer` and `CladeLabelLayer` with `clade_nodes` are
    tree-only MRCA or subtree surfaces until tranche 3 introduces explicit
    graph-capable group or projection contracts.
- Minimal touched-surface docs honesty is authorized in `README.md`,
  `docs/src/index.md`, and affected source docstrings. Broad docs-site,
  roadmap, or workflow cleanup is still out of scope.
- Rooted-tree annotation behavior must remain green.
- If honest implementation appears to require a new public annotation keyword,
  new public group type, or a geometry-carrier expansion to encode annotation
  projection metadata, stop and hand off to the full tranche-3 tasking rather
  than improvising a hidden partial design.

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
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2a--remediation-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2b--remediation-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/04_tranche-2--final-audit.md`
- this tasking file
- `design/design.md`
- `design/target-reference-capacities.md`
- `design/requirements-landscape-gap.md`
- `design/api-landscape.md`

Bundled development-policies references were rechecked for this packet. The
bundled `STYLE*.md` baseline remains aligned with the repo-local stack above.
Bundled `CONTRIBUTING.md` remains absent, so repo-local `CONTRIBUTING.md`
remains authoritative.

Upstream primary sources that must be read line by line for this packet are:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/generic/space.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/plots/text.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/makielayout/types.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/net_plot.md`

These sources matter here because:

- Makie recipe and text behavior constrain where direct diagnostics must be
  raised and how layer-level public contracts are described.
- Makie scene-space guidance constrains any owner attempt to fake annotation
  semantics downstream in layout or rendering instead of naming the boundary
  explicitly.
- `PhyloNetworks.jl` network plotting docs reinforce the project-level
  distinction between full-network views and explicit tree or projection views.

## Revalidated current state

- Tranche-2 geometry ownership is now DAG-safe and weighted-full-network
  honest. This packet must not reopen that work.
- The tranche-2 final audit found no surviving geometry-owner defect, but it
  did confirm that generic annotation surfaces are still tree-only:
  - `src/Layers.jl:395-430` resolves `position = :toward_parent` via
    `Dict(dst => src for (src, dst) in geom.edges)`, which silently picks one
    parent in a multi-parent view.
  - `src/Layers.jl:564-656`, `848-907`, and `976-1060` still drive clade
    highlight and clade label ownership through `_subtree_leaf_positions(...)`.
- `README.md:321-357` still lists node-label and clade surfaces as generic
  `LineagePlot` feature groups and shows `node_label_position = :toward_parent`
  without naming the tree-only boundary.
- `docs/src/index.md` still describes vertical rectangular support as including
  "shared annotations" without distinguishing the tree-only annotation owner.
- Current tests prove rooted-tree annotation behavior well, but they do not yet
  force direct failure on DAG-capable full-network views that request
  tree-only annotation semantics.

## Why this is not a tranche-2 ownership failure

- The parent PRD diagnosed this exact owner gap up front.
- The tranche file explicitly assigned annotation-owner repair and contract
  cleanup to tranche 3, not tranche 2.
- The tranche-2 tasking chain correctly focused on topology, geometry,
  weighted honesty, `leaf_order`, plot-envelope ownership, and `LineageAxis`
  displayed-extent semantics.

So this is not a missed tranche-2 implementation obligation. It is the first
now-active tranche-3 blocker. This packet pulls forward only the minimal
truth-boundary repair needed so full tranche-3 execution does not begin from a
misleading public state.

## Primary-goal lock

### Lock 1: `position = :toward_parent` must not silently choose one parent on a non-tree displayed view

- The work is not complete if `NodeLabelLayer(position = :toward_parent)` can
  still render a DAG-capable full-network view by silently collapsing several
  parents to one.
- Direct red-state repro: `src/Layers.jl` currently builds
  `parent_of = Dict(dst => src ...)` from `geom.edges`, which overwrites prior
  parents and makes the chosen parent traversal-order dependent.
- Closing tasks: 1 and 2.
- Verification artifact: direct layer-level and public-entrypoint regressions
  on the shared-descendant DAG must fail with an explicit tree-only annotation
  diagnostic. A fake fix that keeps `Dict(dst => src ...)` and merely updates
  docs must fail.

### Lock 2: `clade_nodes` tree-only surfaces must not silently pretend a non-tree displayed view is one subtree

- The work is not complete if `CladeHighlightLayer` or `CladeLabelLayer` can
  still accept `clade_nodes` on a DAG-capable full-network view and render a
  subtree-shaped annotation as though that view were a tree.
- Direct red-state repro: the current owner still drives those surfaces through
  `_subtree_leaf_positions(...)`, which is an MRCA-subtree contract.
- Closing tasks: 1 and 2.
- Verification artifact: direct layer-level and public plotting regressions on
  the shared-descendant DAG must fail explicitly when `clade_nodes` is used. A
  fake fix that silently keeps subtree leaf collection on the DAG must fail.

### Lock 3: touched public docs and docstrings must name the tree-only boundary explicitly

- The work is not complete if `README.md`, `docs/src/index.md`, or affected
  source docstrings still describe these annotation surfaces as generic
  DAG-capable plot features.
- Direct red-state repro: `README.md` currently presents node labels and clade
  annotations generically, and `docs/src/index.md` still implies shared
  annotations under current vertical support without naming the owner limit.
- Closing tasks: 1 and 3.
- Verification artifact: touched docs and docstrings must explicitly bound
  `:toward_parent` and `clade_nodes` semantics to rooted-tree or explicit
  tree-view usage until graph-capable annotation contracts exist. A docs-only
  cleanup that leaves the runtime owner unchanged is not sufficient for this
  packet, but a code-only guard that leaves the touched docs misleading is also
  incomplete.

### Lock 4: rooted-tree annotation behavior must remain green while the DAG truth boundary tightens

- The work is not complete if the new guards break existing rooted-tree node
  labels, clade highlights, clade labels, `LineageAxis` annotation layout, or
  representative tree examples.
- Direct red-state equivalent: over-broad guarding could accidentally reject
  honest tree views or regress tree-owned annotation layout while fixing the
  DAG truth boundary.
- Closing tasks: 1 through 3.
- Verification artifact: existing rooted-tree annotation proofs remain green,
  and at least one representative rooted-tree node-label and clade-annotation
  path is reasserted in the touched test surfaces.

## Handoff packet

- Active authorities:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the four design
  documents, the parent PRD, the tranche file, the tranche-2 tasking chain,
  the tranche-2 final audit, and this file.
- Parent documents:
  `01_prd.md`, `02_tranches.md`, the tranche-2 tasking chain, and
  `04_tranche-2--final-audit.md`.
- Settled decisions and non-negotiables:
  tree-only annotation semantics may survive only where honest; this packet is
  a direct-guard and docs-boundary repair, not the full graph-capable owner
  split; no new public projection or group API is authorized; no tranche-2
  geometry work is to be reopened.
- Authorization boundary:
  deep repair is authorized in annotation layers, touched docstrings, touched
  docs, and related tests; no public geometry-carrier break or new public
  annotation API is authorized here.
- Current-state diagnosis:
  generic annotation surfaces still accept DAG-capable full-network views under
  tree-only ownership assumptions, and touched public docs still overstate
  their scope.
- Primary-goal lock:
  locks 1 through 4 above.
- Direct red-state repros:
  `Dict(dst => src ...)` for `:toward_parent`; subtree leaf collection for
  `clade_nodes`; generic README and docs wording.
- Owner and invariant under repair:
  annotation and docs truth boundary; invariant that unsupported graph-capable
  annotation cases fail directly instead of silently using tree-only semantics.
- Exact files or surfaces in scope:
  `src/Layers.jl`, `README.md`, `docs/src/index.md`, touched source docstrings,
  `test/test_Layers.jl`, `test/test_Integration.jl`, and
  `test/test_LineageAxis.jl` only if public-entrypoint or `LineageAxis`
  surface proof requires it.
- Exact files or surfaces out of scope:
  `src/Geometry.jl`, `src/Topology.jl`, `ext/`, `Project.toml`, broad docs-site
  cleanup, `ROADMAP.md`, vocabulary expansion for future graph-capable terms,
  and the full tranche-3 graph-capable owner split.
- Required upstream primary sources:
  the Makie and `PhyloNetworks.jl` files listed above.
- Green-state gates:
  `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, and failure-oriented DAG annotation
  regressions.
- Stop conditions:
  any need for a new public annotation or projection API, any need to reopen
  geometry ownership, or any design pressure to silently project a DAG to a
  tree rather than fail directly.

## Required revalidation before implementation

- Re-read the PRD sections that diagnose annotation-owner drift and the tranche
  3 section in `02_tranches.md`.
- Re-read `src/Layers.jl`, `README.md`, `docs/src/index.md`,
  `test/test_Layers.jl`, `test/test_Integration.jl`, and
  `test/test_LineageAxis.jl` in full.
- Re-run the shared-descendant DAG public plotting path with
  `node_label_position = :toward_parent` and with `clade_nodes = [...]` before
  editing so the current red-state failure mode is confirmed against `HEAD`.
- Re-run `julia --project=test test/runtests.jl` at packet start. If baseline
  is already red for unrelated reasons, stop and raise that first.
- Re-run `julia --project=docs docs/make.jl` at packet start if no fresher
  green evidence exists in the implementing session.
- If honest implementation seems to require a new graph-capable annotation API,
  stop and roll into full tranche-3 tasking instead of partially inventing it
  here.

## Non-negotiable execution rules

- Do not keep silent parent selection for `:toward_parent`.
- Do not keep silent subtree semantics for `clade_nodes` on non-tree displayed
  views.
- Do not hide the problem by silently ignoring annotation requests on DAG views.
  Fail directly with an explicit tree-only annotation diagnostic.
- Do not invent a hidden tree projection, major-tree fallback, or view rewrite
  inside `Layers.jl`.
- Do not broaden this packet into the full graph-capable annotation-owner split.
- Do not change `LineageGraphGeometry`, topology ownership, or geometry
  ownership.
- Do not perform docs-only cleanup without the runtime guard, and do not ship a
  runtime guard without touched-surface docs honesty.

## Tasks

1. **Title**: Install explicit tree-only guards for current generic annotation owners
   **Type**: `WRITE`
   **Output**: `NodeLabelLayer(position = :toward_parent)`,
   `CladeHighlightLayer`, `CladeLabelLayer`, and the corresponding composite
   `lineageplot!` surfaces fail directly on displayed views whose `geom.edges`
   do not form a rooted tree, while rooted-tree annotation behavior remains
   unchanged.
   **Depends on**: `none`
   **Positive contract**:
   the current tree-only annotation surfaces become honest: they still work on
   rooted-tree views and fail directly on non-tree full-network views with
   explicit diagnostics that name the tree-only boundary and the need for a
   later graph-capable owner.
   **Negative contract**:
   no silent `Dict(dst => src ...)` parent collapse may survive for DAG views;
   no subtree annotation may continue silently on a non-tree displayed view; no
   hidden tree projection may be introduced; no tranche-2 geometry code may be
   reopened.
   **Files**:
   `src/Layers.jl`; touched source docstrings in the same file
   **Out of scope**:
   new public annotation APIs, graph-capable group contracts, projection
   keywords, `src/Geometry.jl`, `src/Topology.jl`, and `ext/`
   **Verification**:
   direct shared-descendant DAG layer calls and public plotting calls using
   `node_label_position = :toward_parent` or `clade_nodes` must now fail with
   explicit diagnostics; existing rooted-tree annotation paths must still
   render; `julia --project=test test/runtests.jl`; `julia --project=docs
   docs/make.jl`.

2. **Title**: Add failure-oriented DAG annotation regressions and rooted-tree non-regression proofs
   **Type**: `TEST`
   **Output**: the suite proves that unsupported DAG-capable annotation cases
   fail directly and that honest rooted-tree annotation surfaces remain green.
   **Depends on**: `1`
   **Positive contract**:
   there are direct tests for layer-level calls and public plotting entrypoints
   that reject tree-only annotation semantics on the shared-descendant DAG, and
   at least one representative rooted-tree node-label and clade-annotation path
   remains explicitly green.
   **Negative contract**:
   no proof may accept a fake fix that keeps the silent parent pick, keeps
   subtree annotation on a DAG, or merely asserts render-no-error on tree
   fixtures.
   **Files**:
   `test/test_Layers.jl`, `test/test_Integration.jl`; `test/test_LineageAxis.jl`
   only if a `LineageAxis` public surface needs a direct proof
   **Out of scope**:
   graph-capable annotation success cases, new example families, and full
   tranche-3 group or projection contracts
   **Verification**:
   add negative tests that fail the current implementation and fail docs-only
   fake fixes; keep representative tree tests green; run `julia --project=test
   test/runtests.jl`.

3. **Title**: Tighten touched public docs and docstrings to the current tree-only annotation truth boundary
   **Type**: `MIGRATE`
   **Output**: touched public docs and affected layer docstrings explicitly name
   `:toward_parent` and `clade_nodes` annotation semantics as rooted-tree or
   explicit tree-view surfaces until tranche 3 introduces graph-capable
   contracts.
   **Depends on**: `2`
   **Positive contract**:
   touched docs and docstrings no longer imply that current generic annotation
   surfaces are DAG-capable; examples that remain in place are honest because
   they are tree examples, not silent graph-capable promises.
   **Negative contract**:
   no docs text may claim graph-capable annotation support that the runtime does
   not yet implement; no scope creep into broad docs-site or roadmap cleanup.
   **Files**:
   `README.md`, `docs/src/index.md`, touched source docstrings in
   `src/Layers.jl`
   **Out of scope**:
   `ROADMAP.md`, full docs-site rewrite, full tranche-3 vocabulary and example
   overhaul, and graph-capable annotation API documentation
   **Verification**:
   touched docs and docstrings explicitly state the tree-only boundary;
   `julia --project=docs docs/make.jl`; `julia --project=test test/runtests.jl`.
