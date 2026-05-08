---
date-created: 2026-05-07T19:10:49-07:00
date-revised: 2026-05-07T19:10:49-07:00
status: approved
---

# Audit Report: DAG-first-class lineage graphs and `PhyloNetworks.jl` extension

Parent PRD: `01_prd.md`  
Date: 2026-05-07  
Files in scope: 25

## Summary

Against the full tranche-2 tasking chain, the current implementation is
structurally sound. I did not find a surviving tranche-2 contract violation:
the geometry owner now consumes normalized topology, stable edge identity is
preserved, DAG-safe units render through both rectangular and radial owners,
weighted full-network units are explicit and honest, and the tranche-2a and
tranche-2b compatibility repairs are present in code and tests.

The main remaining gap is the one already deferred to tranche 3. Generic
annotation surfaces still carry tree-only ownership assumptions, and the
public docs have not yet been tightened around that boundary. So tranche 2 now
looks deliverable, but the parent PRD is not yet complete until the
annotation-owner split and contract cleanup land.

Audit-time verification evidence:

- `julia --project=docs docs/make.jl` passed
- `test/test_LineageAxis.jl` passed in isolation
- `test/test_Integration.jl` passed in isolation
- `julia --project=examples examples/src/shared_descendant_dag_ex1.jl`
  completed and produced `examples/build/shared_descendant_dag_ex1.png`
- `julia --project=test test/runtests.jl` was still running at audit close, so
  this report does not claim a completed full-suite result

## Handoff integrity

The surviving workflow chain is now materially honest. The tranche file,
tranche-2 tasking, tranche-2a remediation, and tranche-2b remediation all name
the real owners, preserve the user-settled no-break and no-hidden-projection
boundaries, and record the actual red-state repros that drove the repair.
Current code matches the latest tranche-2b lock items.

The one caution is historical rather than current: the original tranche-2 and
tranche-2a packets each claimed they might be the last remediation pass, and
that proved false. The latest packet fixes that drift by enumerating the
remaining `LineageAxis` sibling surfaces explicitly. A fresh maintainer should
treat `03_tranche-2b--remediation-tasking.md` as the authoritative end-state
handoff for tranche 2, with the earlier tranche-2 documents read as prior
history rather than as equally current contracts.

## Critical findings

None.

## High findings

None.

## Medium findings

### 1. Generic annotation surfaces still accept DAG-capable views under tree-only ownership

**Location**:
`src/Layers.jl:395-430`,
`src/Layers.jl:564-656`,
`src/Layers.jl:848-907`,
`src/Layers.jl:976-1060`

**Category**: Architecture

**Problem**:
The tranche-2 geometry owner is now DAG-safe, but the generic annotation owner
is not yet graph-capable. `NodeLabelLayer` still resolves
`position = :toward_parent` by collapsing `geom.edges` into
`Dict(dst => src ...)`, which silently picks one parent for a multi-parent
node. `CladeHighlightLayer` and `CladeLabelLayer` still derive their spans from
`_subtree_leaf_positions(...)`, which is an MRCA-subtree owner, not a
full-network group or projection owner. That matches the parent PRD and
tranche file diagnosis for tranche 3, but it means the current codebase is not
yet PRD-complete, and these public surfaces can still give tree-biased results
on DAG-capable views instead of failing directly or using an explicit
graph-capable contract.

**Suggestion**:
Treat this as the first tranche-3 blocker. Either:

- guard `position = :toward_parent`, `clade_nodes`, and related subtree owners
  on full-network DAG views with direct diagnostics, or
- introduce explicit graph-capable parent/group/projection owners and migrate
  the public surfaces onto them in tranche 3

Add negative tests that fail if DAG annotation silently falls back to unique
parent or unique subtree semantics.

## Low findings

### 1. Public docs still describe tree-only annotation surfaces as generic plot features

**Location**:
`README.md:321-357`

**Category**: Consistency

**Problem**:
The README still lists node labels and clade annotations as ordinary
`LineagePlot` feature groups and shows `node_label_position = :toward_parent`
without naming the tree-only ownership boundary behind those surfaces. That was
left out of tranche 2 on purpose, so this is not a tranche-2 failure, but
once DAG plotting is now a first-class public capability it becomes part of
the tranche-3 contract cleanup burden. Until that cleanup lands, the public
docs still over-generalize annotation support relative to the actual owner
model.

**Suggestion**:
In tranche 3, either bound these surfaces explicitly as tree-only in README and
docs, or broaden the implementation first and then document the graph-capable
contract with matching examples and negative proofs.

## No findings

- No security problems were found in the tranche-2 implementation surfaces.
- No surviving tranche-2 geometry-owner anti-fix was found: the code no longer
  depends on `require_tree_topology` for DAG-safe units, does not silently
  choose one weighted parent path, and keeps stable normalized edge order.
- No surviving tranche-2a or tranche-2b contract violation was found: explicit
  coordinate `leaf_order`, the node-envelope `boundingbox` contract, the
  full-geometry plot envelope, and the `LineageAxis` displayed-extent owner are
  all aligned with the current tests and live repros.
- No rooted-tree regression was found in the touched public plotting surfaces
  reviewed here.
