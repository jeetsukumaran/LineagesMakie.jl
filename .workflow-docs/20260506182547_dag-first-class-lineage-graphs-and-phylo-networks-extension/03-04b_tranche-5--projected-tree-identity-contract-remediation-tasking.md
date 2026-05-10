---
date-created: 2026-05-09T11:15:00-07:00
status: approved
supersedes:
  - .workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04_tranche-5--tasking.md tasks 3-6 for projected-tree identity handling
parent-tasking: .workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04_tranche-5--tasking.md
parent-ratification: .workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04a_tranche-5--view-policy-ratification.md
reviewed-implementation: b315d1c
---

# Remediation tasking for tranche 5 projected-tree identity contract

This tasking remediates the tranche-5 implementation at current `HEAD`
`b315d1c`.

The tranche-5 public surface for `networkview` and `displaypolicy` is partially
landed, but the implementation did not complete honestly. The current
`networkview = :majortree` path calls the upstream major-tree helper route,
which by default may fuse edges and degree-2 nodes, and then forwards
original-network callables and node collections unchanged into the projected
tree path.

The result is a false green: simple projected-tree smoke plotting works, but
node-keyed and edge-keyed user surfaces can still fail at render time or drift
silently.

This remediation tasking exists because the prior tasking did not lock that
identity contract explicitly enough. It enumerated direct entrypoints and
view-policy controls, but it did not enumerate the downstream callback,
accessor, and node-collection surfaces that still consume original node or edge
identity after view selection.

## Why the prior tasking failed

The prior tasking failed in four concrete ways.

1. It enumerated only the three direct `HybridNetwork` entrypoints plus docs
   surfaces as the affected public surface family. It did not separately
   enumerate the documented accessor and callback surfaces that those
   entrypoints forward into the settled core owner path.
2. It required ratification of keyword names, defaults, supported view values,
   and display-policy combinations, but it did not require ratification of the
   projected-tree node-identity and edge-identity contract itself.
3. It required view-distinction and weighted-split verification, but it did
   not require any regression that would fail when original-node or
   original-edge callables were forwarded unchanged into the projected tree.
4. It authorized exact source-agnostic helper touches in the tranche boundary,
   but the WRITE task narrowed the file list back down to `ext/` plus one test
   file, which nudged implementation toward a local patch even if the honest
   repair required a deeper owner-level helper or an explicit rejection
   boundary.

This remediation tasking closes those holes explicitly.

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
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04_tranche-5--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04a_tranche-5--view-policy-ratification.md`
- this remediation tasking file
- the new ratification artifact created by Task 1 once it exists

Workflow authorities used to produce this remediation tasking were
`development-policies`, `devflow-architecture-05--code-review`, and the
governance stack above. Downstream implementation must preserve their
pass-forward mandates, especially:

- active-authority restatement
- exact upstream-source naming
- exact authorization boundaries
- controlled vocabulary
- primary-goal lock items
- direct red-state repros
- failure-oriented verification
- stop and escalate when a derivable decision was omitted or when the ratified
  tranche-5 route would need to change

## Parent documents

- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04_tranche-5--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04a_tranche-5--view-policy-ratification.md`

## Settled decisions and non-negotiables

- The tranche-5 public control family remains:
  `networkview` plus `displaypolicy`.
- The only ratified direct `displaypolicy` value remains `:rooted`.
- The only ratified projected-tree contract remains `major-tree projection`.
- The exact major-tree route remains:
  `PhyloNetworks.majortree(net; unroot = false)`.
- This remediation does not reopen topology ownership, geometry ownership, the
  tranche-3 annotation split, optional-extension policy, or generic DAG-wide
  APIs.
- This remediation must not change the ratified major-tree helper route to
  `nofuse = true` or any other different upstream helper contract unless Task 1
  review concludes that this is required and the user explicitly approves an
  amendment.
- Unsupported projected-tree callback or accessor families must fail before the
  Makie compute graph runs. A late `KeyError`, missing-label accident, or
  geometry-phase crash is not an acceptable diagnostic.

## Controlled vocabulary

- Continue using the settled tranche-5 vocabulary:
  `full-network view`, `major-tree projection`, `projected-tree view`,
  `display policy`, `networkview`, and `displaypolicy`.
- Use `nodecoordinates` and `:nodecoordinates`.
- Use `group_nodes` and `nodegroup_*` for graph-capable exact node-group
  surfaces.
- Use `clade_nodes` only for subtree or MRCA-based tree-view surfaces.
- Do not describe a narrowed projected-tree callback contract as
  "full support" if some documented callback or accessor families are
  intentionally rejected.

## Upstream primary sources and required local sources

Read these upstream primary sources line by line before implementation:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/compareNetworks.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/auxiliary.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/net_plot.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/generic/space.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/plots/text.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/makielayout/types.jl`

Read these local owner and proof files line by line before implementation:

- `src/Accessors.jl`
- `src/Geometry.jl`
- `src/Layers.jl`
- `src/LineageAxis.jl`
- `ext/PhyloNetworksExt.jl`
- `test/test_PhyloNetworksExt.jl`
- `test/test_Integration.jl`
- `README.md`
- `docs/src/index.md`
- `examples/src/phylonetworks_view_modes_ex1.jl`

These sources constrain the remediation as follows.

- Upstream `majortree(...; nofuse = false, unroot = false)` uses the displayed
  tree helper route that may fuse edges and degree-2 nodes.
- The local input contract explicitly documents callable accessor families:
  `edgeweight`, `nodevalue`, `branchingtime`, `coalescenceage`,
  `nodecoordinates`, and `nodepos`.
- The local composite plotting surface explicitly documents callback and
  collection families that consume node or edge identity:
  `edge_color` as a function of `(src, dst)`, `leaf_label_func`,
  `node_label_func`, `node_label_threshold`, `group_nodes`,
  `nodegroup_label_func`, `clade_nodes`, and `clade_label_func`.
- The current extension implementation forwards the accessor families through
  `_hybridnetwork_accessor(...)` and forwards the remaining plotting kwargs
  unchanged into `LineagesMakie.lineageplot!`.

## Revalidated current state

- Current `HEAD` already lands the public `networkview` and `displaypolicy`
  keyword family, the rooted full-network default, the rooted major-tree
  projection route, and the exact unsupported-value diagnostics for the named
  combinations.
- Current `HEAD` also documents the direct `HybridNetwork` surface as if
  rooted major-tree projection were broadly supported.
- Current `networkview = :majortree` implementation computes a projected tree
  via `PhyloNetworks.majortree(net; unroot = false)`, then forwards
  original-network accessor callables and the remaining plot kwargs unchanged
  into the projected tree path.
- Confirmed direct red-state repro:

```julia
julia --project=test -e 'using LineagesMakie, PhyloNetworks, CairoMakie; net = readnewick(joinpath(dirname(pathof(PhyloNetworks)), "..", "examples", "net1.out")); bt = Dict(node => Float64(i) for (i, node) in enumerate(net.node)); fig = Figure(); ax = Axis(fig[1, 1]); lineageplot!(ax, net; networkview = :majortree, displaypolicy = :rooted, lineageunits = :branchingtime, branchingtime = node -> bt[node], leaf_label_visible = false); colorbuffer(fig)'
```

This currently fails with `KeyError` on a projected `PhyloNetworks.Node` during
geometry construction.

- By direct source inspection and local inference from the same forwarding
  shape, the same bug class likely affects the other documented node-keyed and
  edge-keyed surfaces named above unless they are explicitly supported or
  rejected.
- Current test coverage distinguishes full-network versus major-tree geometry,
  weighted ambiguity behavior, and unsupported view or policy diagnostics, but
  it does not exercise the projected-tree path with original-node keyed
  accessor families or original-node or original-edge callback families.

## Ownership and invariant framing

The owner under repair is the projected-tree identity boundary on the direct
`HybridNetwork` extension entrypoints.

The invariant being repaired is:

- every supported `networkview = :majortree` surface must either receive an
  honest projected-tree node or edge contract, or fail up front with an exact
  diagnostic
- no supported projected-tree surface may depend on accidental reuse of
  original-network node or edge identity after upstream projection has fused or
  replaced nodes
- the major-tree route must remain the ratified upstream helper route unless
  review and user approval explicitly amend it
- docs, examples, and workflow truth must describe only the projected-tree
  surface that the tests and code actually support

## Supported public surfaces affected by this remediation

This remediation must treat the following as affected public surfaces rather
than leaving them implicit inside the entrypoints.

Accessor families:

- `nodevalue`
- `branchingtime`
- `coalescenceage`
- `nodecoordinates`
- `nodepos`

Callback and node or edge collection families:

- `edge_color` when supplied as `(src, dst) -> color`
- `leaf_label_func`
- `node_label_func`
- `node_label_threshold`
- `group_nodes`
- `nodegroup_label_func`
- `clade_nodes`
- `clade_label_func`

Entry surfaces that must stay aligned:

- `lineageplot(::PhyloNetworks.HybridNetwork; kwargs...)`
- `lineageplot!(::Axis, ::PhyloNetworks.HybridNetwork; kwargs...)`
- `lineageplot!(::LineageAxis, ::PhyloNetworks.HybridNetwork; kwargs...)`

Truth surfaces that must stay aligned:

- `README.md`
- `docs/src/index.md`
- `examples/src/phylonetworks_view_modes_ex1.jl`
- this remediation tasking and its Task 1 ratification artifact

## Authorization boundary

Authorized for this remediation:

- `ext/PhyloNetworksExt.jl`
- exact source-agnostic helper additions in `src/Accessors.jl`, `src/Layers.jl`,
  or `src/LineageAxis.jl` only if required to preserve one honest owner path
- extension-aware tests in `test/`
- touched source docstrings
- touched docs, examples, and workflow truth surfaces named here

Not authorized for this remediation:

- reopening `src/Topology.jl`
- reopening generic geometry ownership in `src/Geometry.jl`
- reopening the tranche-3 annotation-boundary policy
- changing the major-tree helper route to `nofuse = true` or another different
  projection contract without explicit review plus user approval
- generic DAG-wide projected-tree or display-policy APIs
- arbitrary displayed-tree enumeration
- silent public breaks outside the projected-tree identity boundary

## Primary-goal lock

### Lock 1: the projected major-tree path must not forward original-node accessor families unchanged

- The work is not complete if any documented node-keyed accessor family can
  still reach the projected tree unchanged and fail later during geometry or
  rendering.
- Direct red-state repro:
  the confirmed `branchingtime` command above fails with `KeyError` today.
- Closing tasks: 1, 2, and 3.
- Verification artifact:
  a direct regression corresponding to the confirmed `branchingtime` repro must
  either pass under a ratified supported contract or fail up front with the
  exact ratified diagnostic before Makie begins reactive geometry construction.

### Lock 2: every documented projected-tree callback and node or edge collection family must be explicitly supported or explicitly rejected

- The work is not complete if any documented node-keyed or edge-keyed callback
  family remains in an implicit gray area for `networkview = :majortree`.
- Direct red-state repro:
  current `ext/PhyloNetworksExt.jl` forwards remaining plot kwargs unchanged,
  while current docs advertise node and edge callback families without naming a
  projected-tree restriction boundary.
- Closing tasks: 1, 2, 3, and 4.
- Verification artifact:
  Task 1 must place each named surface above into a supported or rejected
  bucket; tests and docs must then prove the same bucket membership directly.

### Lock 3: projected-tree rejection boundaries must fail early and exactly

- The work is not complete if unsupported projected-tree surfaces still fail as
  late `KeyError`, missing-node accident, empty-annotation accident, or other
  generic compute-graph crash.
- Direct red-state repro:
  the confirmed `branchingtime` repro fails late inside `Geometry.jl` today.
- Closing tasks: 1, 2, and 3.
- Verification artifact:
  every rejected surface must have a direct regression asserting the exact
  `ArgumentError` text or the exact reviewed diagnostic type and wording.

### Lock 4: verification must fail the old forwarded-callback bug and its close cousins

- The work is not complete if the suite can stay green while any documented
  original-node or original-edge surface still drifts or crashes on the
  projected-tree path.
- Direct red-state repro:
  current tranche-5 tests prove view distinction and weighted semantics, but do
  not exercise projected-tree callback or accessor families.
- Closing tasks: 2 and 3.
- Verification artifact:
  the test surface must include at least one direct accessor-family regression,
  one direct callback-family regression, and one direct node-collection
  regression on `networkview = :majortree`.

### Lock 5: docs and examples must not overclaim projected-tree support

- The work is not complete if docs or examples still imply broader
  `:majortree` support than the ratified and verified callback contract.
- Direct red-state repro:
  current docs describe rooted major-tree projection generally while the
  confirmed callback repro still fails.
- Closing tasks: 1 and 4.
- Verification artifact:
  touched docs build successfully, the projected-tree example remains runnable,
  and a contract-alignment review finds no surviving overclaim.

## Handoff packet

- Active authorities:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the design
  documents, the tranche-5 parent tasking and ratification, and this
  remediation tasking
- Parent documents:
  the tranche-5 tasking and tranche-5 ratification named above
- Settled decisions and non-negotiables:
  `networkview` plus `displaypolicy` stays ratified; `:rooted` only;
  `:majortree` stays the only projected-tree contract; the major-tree helper
  route stays `PhyloNetworks.majortree(net; unroot = false)` unless explicit
  user-approved amendment says otherwise
- Authorization boundary:
  projected-tree identity handling in `ext/`, exact source-agnostic helper
  support if required, tests, docs, examples, and workflow truth; no topology
  redesign, no generic DAG API, no arbitrary displayed-tree enumeration
- Current-state diagnosis:
  public view-mode naming is landed, but the projected-tree identity contract
  is incomplete and currently allows late crashes or likely drift on
  documented node-keyed and edge-keyed surfaces
- Primary-goal lock:
  lock items 1 through 5 above
- Direct red-state repros:
  the exact `branchingtime` repro command above; the current callback-family
  and node-collection gap inferred from unchanged forwarding of remaining plot
  kwargs
- Owner and invariant under repair:
  the projected-tree identity boundary on direct `HybridNetwork` plotting
- Exact files or surfaces in scope:
  `ext/PhyloNetworksExt.jl`, `src/Accessors.jl`, `src/Layers.jl`,
  `src/LineageAxis.jl`, `test/test_PhyloNetworksExt.jl`,
  `test/test_Integration.jl`, `README.md`, `docs/src/index.md`,
  `examples/src/phylonetworks_view_modes_ex1.jl`, and the tranche-5 workflow
  docs named here
- Exact files or surfaces out of scope:
  `src/Topology.jl`, generic geometry redesign, generic DAG plotting APIs, new
  dependency policy, arbitrary displayed-tree enumeration, unrelated docs
  cleanup
- Required upstream primary sources:
  the `PhyloNetworks.jl` and Makie files named above
- Green-state gates:
  direct projected-tree identity regressions, `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, and
  `julia --project=test examples/src/phylonetworks_view_modes_ex1.jl`
- Stop conditions:
  Task 1 concludes that honest support requires changing the ratified major-tree
  helper route, expanding the public API, or reopening a core owner outside the
  authorization boundary

## Required revalidation before implementation

- Re-read the tranche-5 tasking and tranche-5 ratification in full.
- Re-read `src/Accessors.jl`, `src/Layers.jl`, `src/LineageAxis.jl`,
  `ext/PhyloNetworksExt.jl`, `test/test_PhyloNetworksExt.jl`,
  `test/test_Integration.jl`, `README.md`, `docs/src/index.md`, and
  `examples/src/phylonetworks_view_modes_ex1.jl` in full.
- Re-read the upstream primary sources listed above in full.
- Re-run or otherwise re-confirm the green baseline before substantial edits:
  - `julia --project=test test/runtests.jl`
  - `julia --project=docs docs/make.jl`
- Reconfirm that the exact repro command in this tasking still fails on the old
  implementation shape or otherwise still demonstrates the same owner-level
  bug.
- If current `HEAD`, the upstream sources, or the new Task 1 ratification no
  longer match this file's diagnosis, stop and rewrite the remediation tasking
  rather than blindly executing it.

## Non-negotiable execution rules

- Do not forward documented original-node or original-edge callables unchanged
  into the projected tree unless Task 1 explicitly ratifies that exact support
  contract and the implementation proves it directly.
- Do not map projected-tree nodes back to original-network nodes by `name`,
  `number`, position, or traversal order unless Task 1 explicitly ratifies the
  mapping rule and the tests prove its invariants on the routed upstream
  fixture.
- Do not change the major-tree helper route to `nofuse = true` as a hidden fix.
- Do not swallow `KeyError` or other lookup failures and convert them into
  empty labels, default coordinates, or empty annotation groups.
- Do not solve this remediation by narrowing tests, removing examples, or
  rewriting docs to hide a still-broken projected-tree callback path.
- Do not leave a supported or rejected callback family undocumented.

## Concrete anti-patterns or removal targets

- Any projected-tree path that forwards `branchingtime`, `coalescenceage`,
  `nodecoordinates`, or `nodepos` unchanged from the original network is
  forbidden unless directly proven and ratified.
- Any projected-tree path that allows `edge_color = (src, dst) -> ...` to reach
  projected edges without an explicit reviewed contract is forbidden.
- Any projected-tree path that accepts `group_nodes` or `clade_nodes` from the
  original network without an explicit reviewed mapping or rejection boundary is
  forbidden.
- Any late Makie compute-graph failure used as a stand-in for an honest
  unsupported-surface diagnostic is forbidden.
- Any docs or example text that implies "major-tree projection support" without
  naming the supported or rejected callback boundary is forbidden.

## Failure-oriented verification

- Preserve the exact `branchingtime` bug as a named regression. The old
  implementation must fail that regression.
- Add at least one second accessor-family regression on
  `networkview = :majortree`, using one of:
  `coalescenceage`, `nodecoordinates`, or `nodepos`.
- Add at least one callback-family regression on `networkview = :majortree`,
  using one of:
  `edge_color`, `leaf_label_func`, `node_label_func`, or
  `node_label_threshold`.
- Add at least one node-collection regression on `networkview = :majortree`,
  using one of:
  `group_nodes` or `clade_nodes`.
- For every surface ratified as unsupported in Task 1, add one direct
  diagnostic regression asserting the exact early error.
- For every surface ratified as supported in Task 1, add one direct regression
  proving it behaves honestly on the projected tree.
- Keep the existing full-network versus major-tree distinction regressions,
  weighted-split regressions, and unsupported `networkview` or `displaypolicy`
  regressions green.
- End the remediation with:
  - `julia --project=test test/runtests.jl`
  - `julia --project=docs docs/make.jl`
  - `julia --project=test examples/src/phylonetworks_view_modes_ex1.jl`

## Tasks

1. **Title**: Ratify the projected-tree identity contract for documented callback, accessor, and node-collection surfaces
   **Type**: `REVIEW`
   **Output**: a ratified review artifact exists at
   `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04c_tranche-5--projected-tree-identity-ratification.md`
   and settles the exact support or rejection boundary for every documented
   projected-tree identity-sensitive surface before code work proceeds.
   **Depends on**: `none`
   **Positive contract**:
   the review artifact must settle all of the following explicitly:
   - whether the ratified `majortree(...; unroot = false)` route stays unchanged
     for this remediation
   - for each accessor family named in this tasking, whether it is supported on
     `networkview = :majortree` or rejected
   - for each callback and node or edge collection family named in this
     tasking, whether it is supported on `networkview = :majortree` or rejected
   - for each supported family, the exact mapping or ownership rule
   - for each rejected family, the exact early diagnostic
   - whether any docs-described surface must be narrowed temporarily
   **Negative contract**:
   do not let the implementing agent decide support versus rejection family by
   family during coding; do not silently amend the major-tree helper route; do
   not hide any remaining judgment call inside a WRITE or TEST task.
   **Files**:
   `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04c_tranche-5--projected-tree-identity-ratification.md`
   **Out of scope**:
   source files, tests, docs, README, examples, and roadmap
   **Verification**:
   the review artifact must restate active authorities, parent documents, the
   exact family-by-family support table, any approved mapping rules, any exact
   rejection diagnostics, the exact stop conditions, and the exact doc-truth
   boundary. If any affected family remains implicit, stop and rewrite the
   remediation tasking rather than continuing.

2. **Title**: Repair the projected-tree identity owner and add the direct red-state regression
   **Type**: `WRITE`
   **Output**: the direct `HybridNetwork` projected-tree path either adapts the
   Task 1 supported families honestly or rejects the Task 1 unsupported
   families early, and the direct `branchingtime` repro is converted into an
   automated regression.
   **Depends on**: `1`
   **Positive contract**:
   - supported families reach the projected tree through one honest owner path
   - rejected families fail before reactive geometry or rendering work begins
   - the direct `branchingtime` repro no longer fails late with `KeyError`
   - the rooted full-network default and the existing full-network contract stay
     green
   **Negative contract**:
   do not patch over the bug by changing the helper route to `nofuse = true`,
   by swallowing lookup failures, or by relying on unratified node-name or
   node-number heuristics.
   **Files**:
   `ext/PhyloNetworksExt.jl`, `src/Accessors.jl`, `src/Layers.jl`,
   `src/LineageAxis.jl`, `test/test_PhyloNetworksExt.jl`
   **Out of scope**:
   README, docs site, examples, roadmap, and broad suite hardening beyond the
   minimum direct regression needed to keep this task green
   **Verification**:
   add the direct regression corresponding to the confirmed `branchingtime`
   repro and run `julia --project=test test/runtests.jl`.

3. **Title**: Harden the projected-tree proof surface across accessor, callback, and node-collection families
   **Type**: `TEST`
   **Output**: strong proof exists that the projected-tree contract behaves
   honestly across every family ratified in Task 1.
   **Depends on**: `2`
   **Positive contract**:
   - at least one supported or rejected accessor-family regression exists
   - at least one supported or rejected callback-family regression exists
   - at least one supported or rejected node-collection regression exists
   - all three direct `HybridNetwork` entry surfaces stay aligned on the same
     contract
   - the old late-crash bug shape is no longer able to hide behind a green
     suite
   **Negative contract**:
   no test may accept a fake fix that preserves simple geometry distinction
   while leaving callback or accessor families in an implicit or accidentally
   broken state.
   **Files**:
   `test/test_PhyloNetworksExt.jl`, `test/test_Integration.jl`,
   `test/runtests.jl`
   **Out of scope**:
   public docs, examples, roadmap, and workflow docs
   **Verification**:
   run `julia --project=test test/runtests.jl`; include at least one direct
   regression per family class named in the failure-oriented verification
   section, and ensure every unsupported family fails with the exact reviewed
   diagnostic.

4. **Title**: Narrow or expand docs and example truth to the ratified projected-tree identity contract
   **Type**: `MIGRATE`
   **Output**: docs, example, and workflow truth describe exactly the
   projected-tree callback and accessor contract that the code and tests now
   prove.
   **Depends on**: `1, 3`
   **Positive contract**:
   README, docs, examples, and workflow truth either document the supported
   projected-tree families or document the exact rejection boundary with exact
   user-facing diagnostics; no surface overclaims support.
   **Negative contract**:
   do not leave broad "major-tree projection support" language in place if the
   ratified contract is narrower; do not remove the example entirely just to
   avoid documenting the real boundary.
   **Files**:
   `README.md`, `docs/src/index.md`,
   `examples/src/phylonetworks_view_modes_ex1.jl`,
   `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-04c_tranche-5--projected-tree-identity-ratification.md`
   **Out of scope**:
   unrelated docs cleanup, new dependency policy, and broader roadmap changes
   **Verification**:
   run `julia --project=docs docs/make.jl`; run
   `julia --project=test examples/src/phylonetworks_view_modes_ex1.jl`; run
   `julia --project=test test/runtests.jl`; inspect the touched docs and
   example output for exact contract alignment with Task 1.
