---
date-created: 2026-05-08T00:10:30-07:00
date-revised: 2026-05-08T00:10:30-07:00
status: ratified
---

# Tranche 3 ratified public contract: graph-capable node-group annotation

Contract identifier:
`20260508T001030--tranche-3-node-group-annotation-contract`

This artifact closes the former `REVIEW` task in
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01--tranche3--tasking.md`.
It records the user-ratified public split for tranche 3 so downstream work can
implement the graph-capable annotation owner without reopening API naming,
surface-boundary, or tree-only-contract questions.

Parent tranche: Tranche 3  
Parent PRD:
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`  
Parent tranche tasking:
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01--tranche3--tasking.md`

## Governance and required reading

Read line by line before implementing or rewriting downstream tranche-3 work:

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
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01--tranche3--tasking.md`
- this ratification file

Upstream primary sources that remain mandatory for the downstream tranche-3
work are:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/generic/space.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/plots/text.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/makielayout/types.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/net_plot.md`

## Current-state diagnosis

- The tranche-3A truth-boundary repair is already landed in current `HEAD`.
  `CladeHighlightLayer(clade_nodes = ...)`,
  `CladeLabelLayer(clade_nodes = ...)`, and
  `NodeLabelLayer(position = :toward_parent)` already fail directly on
  shared-parent DAG displays rather than silently choosing one subtree or one
  parent.
- `NodeLabelLayer(position = :node)` and `LeafLabelLayer` are already graph-safe
  and do not require public-contract redesign in tranche 3.
- Current `HEAD` still has no explicit graph-capable annotation owner and no
  conflicting `NodeGroupHighlightLayer` or `NodeGroupLabelLayer` surfaces.
- This ratification therefore resolves a real remaining public-contract choice,
  but it does not conflict with current code or with the parent PRD or tranche
  file.

## Ratified public split

Tree-only surfaces remain unchanged and permanently bounded:

- `CladeHighlightLayer(clade_nodes = [...])`:
  MRCA-subtree highlight; throws on DAGs.
- `CladeLabelLayer(clade_nodes = [...])`:
  MRCA-subtree bracket label; throws on DAGs.
- `NodeLabelLayer(position = :toward_parent)`:
  toward-parent labels; throws on DAGs.

Already graph-safe surfaces remain unchanged:

- `NodeLabelLayer(position = :node)`:
  labels any node set via `threshold`.
- `LeafLabelLayer`:
  leaf labels.

New graph-capable surfaces for tranche 3 are Option A:

- `NodeGroupHighlightLayer`
- `nodegrouphighlightlayer!(ax, geom, accessor; group_nodes = [...], kwargs...)`
  - highlights one explicit displayed node set
  - performs no MRCA expansion
  - is DAG-safe
  - must integrate honestly with the `LineageAxis` owner path rather than
    becoming a detached rendering side path
- `NodeGroupLabelLayer`
- `nodegrouplabellayer!(ax, geom, accessor; group_nodes = [...], label_func = ..., kwargs...)`
  - bracket-labels one explicit displayed node set
  - performs no MRCA expansion
  - is DAG-safe
  - uses the same annotation-lane mechanism as `CladeLabelLayer`

## Derived downstream contract that is now settled

- `group_nodes` is the ratified explicit selector for the new graph-capable
  surfaces.
- In the `LineagePlot` composite surface and `lineageplot!` keyword family, the
  ratified additive names are:
  - `group_nodes`
  - `nodegroup_highlight_color`, `nodegroup_highlight_alpha`,
    `nodegroup_highlight_padding`, `nodegroup_highlight_visible`
  - `nodegroup_label_func`, `nodegroup_label_color`,
    `nodegroup_label_fontsize`, `nodegroup_label_offset`,
    `nodegroup_label_side`, `nodegroup_label_visible`
- `group_nodes` denotes one explicit node group per layer or composite
  invocation. If more than one distinct explicit group is needed in the same
  figure during tranche 3, compose multiple `NodeGroupHighlightLayer` or
  `NodeGroupLabelLayer` instances additively rather than overloading
  `group_nodes` into a nested structure or silently reusing `clade_nodes`.
- This ratification does not authorize a projection-based public annotation
  surface in tranche 3. Projection-mode annotation contracts remain outside the
  settled Option A split unless separately ratified.
- This ratification does not weaken the current tree-only diagnostics and does
  not authorize renaming the bounded tree-only surfaces.

## Ownership and invariant framing

- Owner under repair:
  annotation and public-contract ownership in `src/Layers.jl`,
  `src/LineageAxis.jl`, `src/LineagesMakie.jl`, and touched docs/examples.
- Shared invariant:
  graph-capable annotation enters through explicit node-group ownership;
  tree-only subtree surfaces remain explicit tree-only surfaces; no hidden
  parent, subtree, or projection fallback may stand in for the new owner.

## Handoff note

- This artifact closes former task 1 in
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-01--tranche3--tasking.md`.
- Downstream tranche-3 tasking and implementation must treat this contract as
  settled and must not reopen names, selector semantics, or the bounded
  tree-only split without explicit user approval.
- Required verification continues to include:
  - DAG success through `NodeGroupHighlightLayer` and `NodeGroupLabelLayer`
  - DAG failure for `clade_nodes` and `:toward_parent`
  - rooted-tree non-regressions
  - vocabulary, docs, roadmap, and example alignment with the ratified split
