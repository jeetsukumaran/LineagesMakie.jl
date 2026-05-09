---
date-created: 2026-05-09T00:00:00-07:00
status: ratified
parent-tasking: .workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04_tranche-5--tasking.md
---

# Ratification for tranche 5 view and display policy contract

## Review outcome

Task 1 is closed.

The tranche-5 direct `PhyloNetworks.HybridNetwork` control surface is ratified
as the recommended split family:

- `networkview` with supported values `:fullnetwork` and `:majortree`
- `displaypolicy` with the single supported value `:rooted`

The default direct plotting contract is:

- `networkview = :fullnetwork`
- `displaypolicy = :rooted`

No semidirected or unrooted direct plotting contract is ratified in tranche 5.
Those terms remain vocabulary and future-planning concepts only. They are not
approved supported combinations for the direct `HybridNetwork` entrypoints in
this tranche.

## Active authorities

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
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/04_final-audit--tranche-5-readiness.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04_tranche-5--tasking.md`
- the tranche-5 upstream and local source files named by the tranche-5 tasking

## Parent documents

- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04_tranche-5--tasking.md`

## Settled decisions and non-negotiables

- DAG lineage graphs remain first-class in the core owner model.
- Rooted trees remain the single-parent special case on the same owner path.
- `PhyloNetworks.jl` remains an optional package extension.
- Tranche 5 does not reopen `src/Topology.jl`, `src/Geometry.jl`, or the
  tranche-3 annotation split.
- Rooted full-network direct plotting remains the default direct
  `HybridNetwork` contract unless the user explicitly selects another named
  contract.
- The tranche-5 projected-tree contract is exactly `major-tree projection`.
- No arbitrary `displayedtrees(...)` enumeration, gamma-threshold tree
  selection, or custom per-reticulation projection policy is authorized.
- No semidirected or unrooted direct plotting claim is allowed without exact
  implementation and direct verification.

## Authorization boundary

Authorized after this ratification:

- `ext/PhyloNetworksExt.jl`
- extension-aware tests
- `STYLE-vocabulary.md`
- touched README, docs, roadmap, workflow, and example surfaces

Not authorized by this ratification:

- generic DAG-wide view-mode APIs
- arbitrary displayed-tree enumeration
- public breaks outside the tranche-5 tasking boundary
- silent expansion of supported display-policy combinations

## Current-state diagnosis

Current `HEAD` already lands rooted full-network direct plotting for
`PhyloNetworks.HybridNetwork` with hybrid-node markers, major and minor
reticulation-edge distinction, and gamma labels.

The missing product surface is the explicit public contract above that
foundation:

- one named public view selector
- one honest major-tree projection path
- one exact display-policy rule for what is and is not supported now
- the proof and docs surface that makes those choices explicit

## Upstream-source conclusions

The following upstream conclusions are verified from the named tranche-5
primary sources.

- `PhyloNetworks.majortree(net; ...)` is a first-class upstream helper for the
  major-tree projection contract.
- `PhyloNetworks.displayedtrees(net, gamma; ...)` and `minortreeat(...)` prove
  that broader displayed-tree enumeration exists upstream, but tranche 5 does
  not need or authorize exposing that broader surface.
- `net_plot.md` explicitly distinguishes full-network plotting from
  `:majortree` plotting style and ties gamma annotation to hybrid-edge network
  rendering.
- `checkroot!(...)` and the semidirected or unrooted documentation prove that
  semidirected validity and unrooted interpretation exist upstream, but they do
  not by themselves provide a directly verified LineagesMakie display contract
  for the tranche-5 direct plotting API.

The semidirected or unrooted non-support decision below is therefore a
review-governed narrowing from verified sources, not an unsupported guess.

## Exact approved public surface

The direct extension entrypoints for `PhyloNetworks.HybridNetwork` gain two new
keywords:

- `networkview`
- `displaypolicy`

The ratified supported combinations are:

| `networkview` | `displaypolicy` | Supported | Meaning |
|---|---|---:|---|
| `:fullnetwork` | `:rooted` | yes | Render the rooted full-network contract with all displayed edges plus tranche-4 reticulation overlays |
| `:majortree` | `:rooted` | yes | Render the rooted major-tree projection produced from the upstream major-tree helper |

All other combinations are unsupported in tranche 5.

## Exact defaults

If the user does not supply either keyword on the direct `HybridNetwork`
entrypoints, the implementation must behave exactly as:

```julia
networkview = :fullnetwork
displaypolicy = :rooted
```

This preserves the settled tranche-4 direct contract unchanged.

## Exact major-tree route

The named projected-tree path must use the upstream major-tree helper route:

```julia
PhyloNetworks.majortree(net; unroot = false)
```

Use upstream default behavior for other helper keywords unless a directly
needed implementation detail requires an explicit override that preserves the
same rooted major-tree contract.

The projected tree must then enter the settled LineagesMakie core owners
through the same canonical owner path used by ordinary tree-like accessors.

The projected-tree path must not:

- hide minor reticulation edges on the full-network path and call that a
  projection
- rebuild a second topology or geometry owner inside `ext/`
- silently appear only as a weighted-unit fallback

## Exact unsupported-combination diagnostics

The direct `HybridNetwork` API must fail unsupported combinations with exact,
named diagnostics rather than generic accidents.

Minimum required diagnostics:

1. Unsupported `networkview` value:

   `ArgumentError` naming the unsupported `networkview` value and stating that
   direct `HybridNetwork` plotting currently supports only
   `networkview = :fullnetwork` and `networkview = :majortree`.

2. Unsupported `displaypolicy` value:

   `ArgumentError` naming the unsupported `displaypolicy` value and stating
   that tranche 5 supports only `displaypolicy = :rooted` on the direct
   `HybridNetwork` entrypoints.

3. Non-rooted network with rooted display policy:

   `ArgumentError` stating that `displaypolicy = :rooted` requires a rooted
   `HybridNetwork` and that semidirected and unrooted direct display policies
   are not yet supported on this surface.

4. Unsupported rooted combination:

   If any future code path can still construct an unsupported rooted
   combination, the diagnostic must name the exact supported rooted
   combinations:
   `(networkview = :fullnetwork, displaypolicy = :rooted)` and
   `(networkview = :majortree, displaypolicy = :rooted)`.

## Why semidirected and unrooted are not ratified now

Semidirected and unrooted terms are real upstream concepts, but the active
sources do not yet derive one exact direct plotting contract for them in this
repository.

The upstream evidence available in tranche 5 proves:

- semidirected validity and rerooting semantics
- unrooted and semidirected comparison semantics
- major-tree projection as an explicit helper

It does not yet prove, for this repository and these direct entrypoints:

- one settled scene-embedding contract for semidirected network display
- one settled scene-embedding contract for unrooted network display
- one settled relation between those modes and the current rooted full-network
  overlay logic
- one settled verification surface for those combinations under the active
  tranche-5 scope

Under the active authorities, claiming those combinations now would be a
guessed public contract. That is forbidden. Therefore tranche 5 ratifies
explicit non-support with exact diagnostics instead.

## Primary-goal lock

- Lock 1 remains in force: the extension stays optional.
- Lock 2 is closed by introducing one explicit public network-view surface.
- Lock 3 is closed by making `major-tree projection` a real named contract.
- Lock 4 is narrowed honestly: supported display policy is `:rooted` only; the
  unsupported neighboring policies are named explicitly and fail directly.
- Lock 5 remains in force: weighted full-network ambiguity must still fail
  directly, while weighted major-tree requests must run on the named projected
  tree.
- Lock 6 remains in force: touched docs, examples, roadmap, vocabulary, and
  workflow truth must match the final contract.
- Lock 7 remains in force: existing tree and DAG behavior must remain green.

## Direct red-state repros

- direct `HybridNetwork` plotting currently exposes rooted full-network only
- no named projected-tree path exists yet
- `src/Geometry.jl` already instructs the user to choose a projected-tree
  contract for certain weighted ambiguities, but the direct extension API does
  not yet offer one
- docs and roadmap still state that projected-tree and display-policy work are
  deferred

## Owner and invariant under repair

Owner under repair:

- explicit network-view and display-policy normalization on the direct
  `PhyloNetworks.HybridNetwork` entrypoints

Invariant under repair:

- one named public control surface chooses the direct display contract once
- full-network view and major-tree projection remain distinct rendered
  contracts
- unsupported display-policy combinations fail directly instead of through
  hidden fallback

## Exact scope in

- `ext/PhyloNetworksExt.jl`
- `test/test_PhyloNetworksExt.jl`
- `test/test_ExtensionBoundary.jl`
- `test/test_Integration.jl`
- `test/runtests.jl`
- `STYLE-vocabulary.md`
- `README.md`
- `docs/src/index.md`
- `ROADMAP.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- `examples/src/phylonetworks_full_network_ex1.jl`
- `examples/src/phylonetworks_view_modes_ex1.jl`

## Exact scope out

- `src/Topology.jl`
- `src/Geometry.jl`
- generic DAG plotting entrypoints
- arbitrary displayed-tree enumeration
- semidirected or unrooted rendering claims beyond explicit non-support
- unrelated layout families

## Vocabulary implications

Before implementation and public docs migration, `STYLE-vocabulary.md` must add
canonical entries for:

- `projected-tree view`
- `display policy`
- `rooted display policy`
- `semidirected display policy`
- `unrooted display policy`

The vocabulary updates must say explicitly that tranche 5 lands rooted display
policy only on the direct `HybridNetwork` surface and that semidirected and
unrooted display-policy terms are not yet live supported direct contracts here.

## Green-state gates

- `julia --project=test test/runtests.jl`
- `julia --project=docs docs/make.jl`
- isolated extension-absence probe
- rooted full-network versus major-tree real-fixture regressions
- `julia --project=test examples/src/phylonetworks_full_network_ex1.jl`
- `julia --project=test examples/src/phylonetworks_view_modes_ex1.jl`

## Stop conditions

- implementation discovers that the ratified `networkview` and
  `displaypolicy` surface would require a public break not authorized by the
  tranche-5 tasking
- implementation cannot preserve the rooted full-network default direct
  contract
- implementation would need arbitrary displayed-tree enumeration or custom
  reticulation-choice policy to satisfy the tranche
- implementation would need to claim semidirected or unrooted support without
  new direct proof and an amended workflow artifact
- implementation would need to move topology or geometry ownership back into
  the extension
