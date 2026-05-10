---
date-created: 2026-05-09T15:10:00-07:00
status: ratified
parent-tasking: .workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04b_tranche-5--projected-tree-identity-contract-remediation-tasking.md
parent-ratification: .workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04a_tranche-5--view-policy-ratification.md
reviewed-implementation: c8b0820
---

# Ratification for tranche 5 projected-tree identity contract

## Review outcome

Task 1 is closed.

The direct `PhyloNetworks.HybridNetwork` projected-tree surface is ratified as
an explicitly narrowed contract:

- the projected-tree route remains exactly
  `PhyloNetworks.majortree(net; unroot = false)`
- that upstream route is treated as producing a fresh projected tree with fresh
  node and edge identity, not as an identity-preserving view of the original
  network
- the direct `networkview = :majortree, displaypolicy = :rooted` surface keeps
  non-identity-sensitive styling and the built-in projected-tree defaults, but
  it does not accept user-supplied identity-sensitive accessor, callback, or
  node-collection families
- users who need projected-tree custom accessors, projected-tree callback
  behavior, or projected-tree node collections must call
  `PhyloNetworks.majortree(net; unroot = false)` themselves and then use the
  generic LineagesMakie tree entrypoint

This review rejects the tempting half-contract in which the direct
`HybridNetwork` surface would accept an original network as input while some
user-supplied kwargs secretly switch over to projected-tree node or edge
identity. That split contract would leave the owner boundary implicit and would
continue to invite late `KeyError`, empty-annotation accident, or silent drift
shapes.

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
- `STYLE-workflow-vocabulary.md`
- `STYLE-writing.md`
- `design/design.md`
- `design/target-reference-capacities.md`
- `design/requirements-landscape-gap.md`
- `design/api-landscape.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04_tranche-5--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04a_tranche-5--view-policy-ratification.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04b_tranche-5--projected-tree-identity-contract-remediation-tasking.md`

## Parent documents

- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04_tranche-5--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04a_tranche-5--view-policy-ratification.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04b_tranche-5--projected-tree-identity-contract-remediation-tasking.md`

## Settled decisions and non-negotiables

- The tranche-5 public control family remains `networkview` plus
  `displaypolicy`.
- The only ratified direct `displaypolicy` value remains `:rooted`.
- The only ratified projected-tree contract remains `major-tree projection`.
- The exact major-tree route remains
  `PhyloNetworks.majortree(net; unroot = false)`.
- This remediation does not reopen topology ownership, geometry ownership, the
  tranche-3 annotation split, optional-extension policy, or generic DAG-wide
  plotting APIs.
- This remediation must not change the major-tree route to `nofuse = true` or
  introduce any other hidden projection contract.
- Unsupported projected-tree identity-sensitive surfaces must fail before the
  Makie compute graph runs.

## Authorization boundary

Authorized after this ratification:

- `ext/PhyloNetworksExt.jl`
- exact source-agnostic helper additions in `src/Accessors.jl`,
  `src/Layers.jl`, or `src/LineageAxis.jl` only if required to preserve one
  honest owner path
- extension-aware tests in `test/`
- touched source docstrings
- touched docs, examples, and workflow truth surfaces named in the remediation
  tasking

Not authorized by this ratification:

- reopening `src/Topology.jl`
- reopening generic geometry ownership in `src/Geometry.jl`
- reopening the tranche-3 annotation-boundary policy
- changing the major-tree helper route to `nofuse = true` or any other
  different projection contract without explicit review plus user approval
- generic DAG-wide projected-tree or display-policy APIs
- arbitrary displayed-tree enumeration
- silent public breaks outside the projected-tree identity boundary

## Current-state diagnosis

The named remediation red state still exists on current `HEAD`.

The confirmed repro:

```julia
julia --project=test -e 'using LineagesMakie, PhyloNetworks, CairoMakie; net = readnewick(joinpath(dirname(pathof(PhyloNetworks)), "..", "examples", "net1.out")); bt = Dict(node => Float64(i) for (i, node) in enumerate(net.node)); fig = Figure(); ax = Axis(fig[1, 1]); lineageplot!(ax, net; networkview = :majortree, displaypolicy = :rooted, lineageunits = :branchingtime, branchingtime = node -> bt[node], leaf_label_visible = false); colorbuffer(fig)'
```

still fails late with `KeyError` during geometry construction.

Direct local revalidation also confirms the owner-level cause:

- `PhyloNetworks.majortree(net; unroot = false)` returns fresh projected-tree
  `Node` and `Edge` objects rather than reusing original-network identity
- some projected nodes keep familiar `number` values, but the object identity
  still changes
- projected edges may fuse nodes and therefore change endpoint ownership even
  when an edge number survives

Forwarding original-network keyed callables or node collections unchanged into
that projected-tree path is therefore dishonest.

## Upstream-source conclusions

The following contract points are verified from the named upstream primary
sources plus direct local runtime revalidation:

- `compareNetworks.jl` defines `majortree(net; nofuse = false, unroot = false)`
  as the displayed-tree helper that deletes minor hybrid edges and, by
  default, fuses edges and degree-2 nodes
- `compareNetworks.jl` documents that `nofuse = true` is the identity-retaining
  alternative, which this remediation is not authorized to adopt silently
- `net_plot.md` distinguishes full-network plotting from `:majortree` plotting
  style and keeps gamma annotation with the full-network rendering path
- direct local runtime inspection confirms the expected local inference from
  those upstream semantics: the routed major-tree helper changes node and edge
  identity in the exact way that breaks original-network keyed callables

The final sentence above is an inference from verified sources plus direct local
runtime observation, not a claim that upstream states the identity contract in
those exact words.

## Exact ratified direct projected-tree identity contract

### Supported direct `:majortree` surface

The direct `networkview = :majortree, displaypolicy = :rooted` surface keeps
the following support:

- built-in projected-tree defaults supplied by the extension itself
- non-identity-sensitive styling and visibility kwargs
- projected-tree layout modes that do not require a user-supplied
  node-keyed, edge-keyed, or node-collection contract from the direct
  `HybridNetwork` caller
- projected-tree weighted `:edgeweights` requests routed through the projected
  tree itself

### Rejected identity-sensitive surfaces

The following documented families are ratified as unsupported on the direct
`HybridNetwork` `:majortree` surface:

| Surface | Status | Ratified rule |
|---|---:|---|
| `nodevalue(node)` | rejected | explicit user-supplied callable rejected on the direct `:majortree` surface |
| `branchingtime(node)` | rejected | explicit user-supplied callable rejected on the direct `:majortree` surface |
| `coalescenceage(node)` | rejected | explicit user-supplied callable rejected on the direct `:majortree` surface |
| `nodecoordinates(node)` | rejected | explicit user-supplied callable rejected on the direct `:majortree` surface |
| `nodepos(node)` | rejected | explicit user-supplied callable rejected on the direct `:majortree` surface |
| `edge_color = (src, dst) -> ...` | rejected | callable edge-color contract rejected on the direct `:majortree` surface |
| `leaf_label_func` | rejected | explicit node-keyed leaf-label callback rejected on the direct `:majortree` surface |
| `node_label_func` | rejected | explicit node-keyed node-label callback rejected on the direct `:majortree` surface |
| `node_label_threshold` | rejected | explicit node-keyed node-label threshold callback rejected on the direct `:majortree` surface |
| `group_nodes` | rejected | non-empty projected-tree node-group collections rejected on the direct `:majortree` surface |
| `nodegroup_label_func` | rejected | rejected whenever paired with non-empty `group_nodes` on the direct `:majortree` surface |
| `clade_nodes` | rejected | non-empty projected-tree MRCA or subtree collections rejected on the direct `:majortree` surface |
| `clade_label_func` | rejected | rejected whenever paired with non-empty `clade_nodes` on the direct `:majortree` surface |

### Exact early diagnostic

The exact ratified diagnostic template is:

> `networkview = :majortree on direct PhyloNetworks.HybridNetwork plotting does not support the identity-sensitive surface(s) ... . The upstream route PhyloNetworks.majortree(net; unroot = false) returns fresh projected-tree nodes and edges, so original-network keyed callables and node collections are not accepted on this direct surface. For projected-tree custom accessors, callbacks, or node collections, call PhyloNetworks.majortree(net; unroot = false) yourself and plot the projected tree through the generic LineagesMakie tree entrypoint.`

The implementation must substitute the exact rejected surface label list into
that template. When `nodegroup_label_func` is rejected, the diagnostic must
name both `group_nodes` and `nodegroup_label_func`. When `clade_label_func` is
rejected, the diagnostic must name both `clade_nodes` and `clade_label_func`.

## Why direct projected-tree custom identity support is not ratified here

The generic projected-tree path already exists: users can call
`PhyloNetworks.majortree(net; unroot = false)` explicitly and then use the
ordinary LineagesMakie tree entrypoint with a contract they own honestly.

What is not ratified here is the narrower but much more confusing hybrid
surface where:

- the top-level input is still the original `HybridNetwork`
- some kwargs would secretly use original-network identity
- some kwargs would secretly use projected-tree identity
- and the boundary would only become visible once a callback crashes or drifts

Under the active authorities, that would be an implicit split owner model and a
bad pass-forward contract. This review therefore chooses explicit rejection on
the direct `HybridNetwork` `:majortree` surface instead.

## Primary-goal lock

- Lock 1 is satisfied by requiring early rejection of explicit projected-tree
  accessor families instead of late `KeyError`.
- Lock 2 is satisfied by classifying every named accessor, callback, and node
  or edge collection family as explicitly rejected rather than leaving gray
  areas.
- Lock 3 is satisfied by requiring the exact early `ArgumentError` template
  above.
- Lock 4 is satisfied by requiring a direct diagnostic regression for every
  rejected family.
- Lock 5 is satisfied by requiring docs, example text, and workflow truth to
  describe this narrowed direct projected-tree contract exactly.

## Direct red-state repros

- the confirmed `branchingtime` repro above fails late today
- current `ext/PhyloNetworksExt.jl` forwards remaining plot kwargs unchanged
  into the projected-tree path
- current docs describe rooted major-tree projection generally and do not yet
  name this narrowed projected-tree identity boundary

## Owner and invariant under repair

Owner under repair:

- the projected-tree identity boundary on the direct
  `PhyloNetworks.HybridNetwork` plotting entrypoints

Invariant under repair:

- every direct `networkview = :majortree` identity-sensitive surface must be
  either rejected up front with the exact diagnostic above or routed through a
  different explicit owner path outside this direct `HybridNetwork` surface

## Exact scope in

- `ext/PhyloNetworksExt.jl`
- `src/Accessors.jl`, `src/Layers.jl`, and `src/LineageAxis.jl` only if a
  source-agnostic helper touch is strictly required
- `test/test_PhyloNetworksExt.jl`
- `test/test_Integration.jl`
- `README.md`
- `docs/src/index.md`
- `examples/src/phylonetworks_view_modes_ex1.jl`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04b_tranche-5--projected-tree-identity-contract-remediation-tasking.md`
- this ratification artifact

## Exact scope out

- `src/Topology.jl`
- generic geometry redesign
- generic DAG plotting APIs
- new dependency policy
- arbitrary displayed-tree enumeration
- unrelated docs cleanup

## Green-state gates

- direct projected-tree identity regressions for every rejected family
- `julia --project=test test/runtests.jl`
- `julia --project=docs docs/make.jl`
- `julia --project=test examples/src/phylonetworks_view_modes_ex1.jl`

## Stop conditions

- honest support would require changing the ratified major-tree helper route
- honest support would require a broader public API than the authorization
  boundary permits
- honest support would require reopening a core owner outside the authorized
  file surface
