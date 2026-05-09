---
date-created: 2026-05-08T20:05:00-07:00
status: approved
---

# Completion tasks for tranche 4: finalize rooted full-network `PhyloNetworks` support

Parent tranche: Tranche 4  
Parent PRD:
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`  
Superseded for the remaining tranche-4 work:

- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-03_tranche-4--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-03a_tranche-4--remediation-tasking.md`

Tasking identifier:
`20260508T200500--tranche-4-completion-weighted-duplicate-endpoint-contract`

This file replaces the earlier tranche-4 taskings for the remaining work at
current `HEAD` commit `cba166c`.

Revalidation on 2026-05-08 shows that tranche 4 is largely landed already:

- optional `PhyloNetworks.jl` extension activation is live
- rooted full-network `HybridNetwork` plotting is live
- duplicate-endpoint overlay identity is now repaired for reticulation styling
  and gamma labels
- docs, README, roadmap, vocabulary, and example migration are already landed

The remaining work is no longer "implement tranche 4". The remaining work is
to correct the final weighted duplicate-endpoint contract so that tranche 4
matches the parent PRD and tranche semantics rather than the narrower rule
frozen into the prior remediation tasking.

## Why this file exists

The first tranche-4 tasking failed because it was incomplete about duplicate
edge identity and did not require a 2-cycle proof.

The second remediation tasking fixed overlay identity, but it encoded the wrong
weighted-network decision. It treated "duplicate endpoint pair exists" as
equivalent to "the current `edgeweight(src, dst)` accessor contract cannot
represent this request honestly", and it instructed the implementer to reject
all duplicate-endpoint `:edgeweights` requests directly.

That is not the settled parent contract.

The parent PRD and tranche resolve weighted full-network semantics as follows:

- weighted or age-based coordinates on a network may proceed when the supplied
  values are honest for the current public contract
- `:edgeweights` must hard error only when additive full-network consistency
  cannot be proven, or when the current public boundary cannot represent the
  requested weights honestly
- no owner may silently choose one parent path over another

This file resolves the remaining derivable decision explicitly:

- duplicate-endpoint rooted `:edgeweights` requests are not banned categorically
- they remain supported whenever every upstream edge in a duplicate endpoint
  group carries the same exact `length` value, because the current public
  node-pair accessor can represent that group honestly
- they must fail directly only when one duplicate endpoint group carries
  conflicting `length` values, because the current public
  `edgeweight(src, dst)` boundary cannot encode two different values for the
  same `(src, dst)` pair without an out-of-scope API redesign
- after that local representability check passes, the settled core
  full-network consistency owner in `src/Geometry.jl` still decides whether the
  whole network is additive-consistent

No `REVIEW` task is needed. The correct rule is derivable from the parent PRD,
the tranche, the current core owner behavior, and the live repros below.

## Settled decisions and environment baseline

- Current `HEAD` is commit `cba166c`.
- `src/Topology.jl` remains the owner of stable normalized edge identity.
  Do not redesign it.
- `src/Geometry.jl` remains the owner of weighted full-network additive
  consistency. The extension must not reimplement or narrow that owner.
- `src/Layers.jl` already owns the repaired geometry-order duplicate-edge
  selection helpers. Do not reopen that overlay fix except for directly
  required non-regression coverage.
- `PhyloNetworks.jl` remains an optional extension only. Do not add it to root
  `[deps]`, `docs/Project.toml`, or `examples/Project.toml`.
- Rooted full-network view remains the only tranche-4 `HybridNetwork` display
  contract. Major-tree projection, projected-tree view, semidirected display,
  and unrooted display remain deferred.
- Rooted default plotting remains `lineageunits = :nodelevels`.
- Direct `HybridNetwork` `:edgeweights` requests are settled to the refined
  rule above:
  - allow them when each duplicate-endpoint group has one exact shared
    `edge.length` value
  - reject them only when at least one duplicate-endpoint group has conflicting
    `edge.length` values under the current public `edgeweight(src, dst)`
    contract
  - after that, leave whole-network additive consistency to the core geometry
    owner unchanged
- Do not average, round, tolerance-merge, or arbitrarily choose between
  conflicting duplicate-endpoint edge lengths. If the values differ, the
  request is ambiguous under the current public API and must fail directly.
- Existing docs, README, roadmap, vocabulary, and example surfaces stay in
  scope only for verification. No further public wording changes are authorized
  unless code truth cannot satisfy the already-landed tranche-4 docs.
- No public accessor redesign is authorized here. In particular, do not add a
  third `edge` argument or any other public edge-identity extension to
  `edgeweight`.

## Governance

Explicit line-by-line reading remains mandatory before implementation.
Downstream implementation must read and conform to:

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
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03-03a_tranche-4--remediation-tasking.md`
- this completion tasking file

The bundled governance baseline under
`development-policies/references/` was rechecked during this tasking run and
remains aligned with the repo-local governance stack above. Bundled
`CONTRIBUTING.md` was not present there, so repo-local `CONTRIBUTING.md`
remains authoritative for contribution guidance.

Workflow authorities used for this file were `development-policies` and
`devflow-architecture-03--tranche-to-tasks`. Downstream implementation must
pass forward their mandates explicitly.

## Controlled vocabulary

- Keep the landed tranche-4 vocabulary in `STYLE-vocabulary.md`, including
  `hybrid node`, `reticulation edge`, `major edge`, `minor edge`,
  `gamma label`, `major-tree projection`, `tree view`, and
  `full-network view`.
- Use `2-cycle` exactly as upstream defines it: two parallel hybrid edges from
  the same parent node to the same hybrid child node.
- Use `duplicate-endpoint group` for the local weighted-accessor concern that
  two or more distinct normalized edges share the same `(src, dst)` pair.
- Use `additive full-network consistency` for the settled core weighted-owner
  rule. Do not rename it as "duplicate-edge validation" or "2-cycle policy".
- Do not describe equal-length duplicate-endpoint weighted support as a
  projection mode. It is still the rooted full-network contract.

## Upstream primary sources and required local sources

Read these upstream sources line by line before implementation:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/types.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/auxiliary.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/readwrite.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/net_plot.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`

Read these local owner and proof files line by line before implementation:

- `src/Accessors.jl`
- `src/Topology.jl`
- `src/Geometry.jl`
- `src/Layers.jl`
- `ext/PhyloNetworksExt.jl`
- `test/test_PhyloNetworksExt.jl`
- `test/test_Integration.jl`
- `test/test_ExtensionBoundary.jl`

These sources constrain the remaining tranche-4 work as follows:

- `src/Geometry.jl` already proves the core weighted contract:
  `:edgeweights` is allowed when additive full-network consistency can be
  proven; otherwise it errors directly.
- `src/Accessors.jl` confirms that the current public `edgeweight` contract is
  `edgeweight(src, dst)`, not an edge-object or edge-index API.
- `PhyloNetworks.jl/src/auxiliary.jl` defines rooted 2-cycles as two parallel
  hybrid edges from the same parent to the same child.
- `PhyloNetworks.jl/src/readwrite.jl` and `getchildren(node)` semantics confirm
  that duplicate child entries can be legitimate when two upstream edges share
  the same child.
- The direct `HybridNetwork` convenience path must not be narrower than the
  generic core path when the current public accessor boundary can already
  represent the request honestly.

## Revalidated current state and direct red-state repros

Current `HEAD` already repaired overlay identity, but one weighted contract bug
survives.

### Repro A: the core owner can represent an equal-length rooted 2-cycle honestly

Using the minimal rooted 2-cycle fixture:

`((t1:1)#H22:1::0.8,#H22:1::0.2);`

the generic core plotting surface succeeds under `:edgeweights` when given a
truthful node-pair accessor:

- build `root = PhyloNetworks.getroot(net)`
- build `accessor = lineagegraph_accessor(root; children = PhyloNetworks.getchildren, edgeweight = (src, dst) -> 1.0)`
- call `lineageplot!(ax, root, accessor; lineageunits = :edgeweights, leaf_label_visible = false)`

This succeeds today and produces valid geometry. Therefore, equal-length
duplicate-endpoint groups are representable under the current public accessor
boundary.

### Repro B: the direct extension path incorrectly rejects that same honest case

On the same fixture, current direct plotting:

- `lineageplot!(ax, net; lineageunits = :edgeweights, leaf_label_visible = false)`

fails today from `ext/PhyloNetworksExt.jl` with the blanket
duplicate-endpoint diagnostic, before the core additive-consistency owner runs.

### Repro C: the surviving bug is caused by blanket pre-rejection, not by the core owner

Current `ext/PhyloNetworksExt.jl` still contains:

- `_require_unambiguous_edgeweights(...)` that rejects any duplicate-endpoint
  group before checking whether all partner lengths are equal
- `edgeweight(src, dst)` logic that rejects any endpoint group of multiplicity
  greater than 1, even when all partner `edge.length` values are the same

This is the remaining owner-level mismatch.

### Repro D: negative ambiguity still remains a real failure mode

If one partner edge in that same minimal rooted 2-cycle is mutated to a
different `length`, the current public `edgeweight(src, dst)` contract cannot
represent both values honestly. That request must still fail directly.

## Ownership and invariant framing

The owner under repair is the extension-local weighted duplicate-endpoint
resolution boundary in `ext/PhyloNetworksExt.jl`.

The invariant being repaired is:

- the direct `HybridNetwork` convenience path must permit every rooted
  full-network `:edgeweights` request that the current public
  `edgeweight(src, dst)` contract can already represent honestly
- the extension must reject only genuinely ambiguous duplicate-endpoint groups
  under that public contract
- the core geometry owner must remain the sole authority for global additive
  full-network consistency after local representability is established

Supported public surfaces affected by this work are:

- generic core weighted plotting:
  `lineageplot!(ax, basenode, accessor; lineageunits = :edgeweights, ...)`
- direct extension weighted plotting:
  `lineageplot(net::PhyloNetworks.HybridNetwork; lineageunits = :edgeweights, ...)`
- `lineageplot!(::Axis, ::PhyloNetworks.HybridNetwork; lineageunits = :edgeweights, ...)`
- `lineageplot!(::LineageAxis, ::PhyloNetworks.HybridNetwork; lineageunits = :edgeweights, ...)`

The direct extension surfaces must not be stricter than the generic core
surface for equal-length duplicate-endpoint groups.

## Authorization boundary

Authorized for the remaining tranche-4 work:

- `ext/PhyloNetworksExt.jl`
- targeted weighted-contract tests in `test/test_PhyloNetworksExt.jl`
- any directly required integration or extension-boundary tests in
  `test/test_Integration.jl` and `test/test_ExtensionBoundary.jl`
- touched source docstrings if needed to keep the weighted contract honest

Not authorized:

- redesigning `src/Topology.jl`
- redesigning the public `LineageGraphAccessor` callable shapes
- reopening the overlay identity repair in `src/Layers.jl` beyond necessary
  non-regression coverage
- adding public view-mode, projection, or styling controls
- reopening docs, README, roadmap, vocabulary, or example content except for
  verification or if a truth-boundary failure forces escalation
- widening support to major-tree projection, semidirected display, or
  unrooted display

## Primary-goal lock

### Lock 1: optional extension and rooted-scope honesty remain intact

- The work is not complete if the final tranche-4 fix regresses the optional
  extension boundary, weakens the extension-absence proof, or widens support
  beyond rooted full-network `HybridNetwork` plotting.
- Direct red-state repro:
  current `HEAD` already has optional activation and rooted-scope rejection;
  the completion fix must not disturb them.
- Closing tasks: 1, 2, and 3.
- Verification artifact:
  the existing extension-absence probe remains green, non-rooted direct
  rejection remains green, and `PhyloNetworks.jl` stays out of root `[deps]`.

### Lock 2: equal-length duplicate-endpoint weighted requests remain supported

- The work is not complete if a rooted duplicate-endpoint group with one exact
  shared `edge.length` value still fails early in the direct extension path.
- Direct red-state repro:
  the minimal rooted 2-cycle `((t1:1)#H22:1::0.8,#H22:1::0.2);` succeeds on the
  generic core weighted surface but currently fails on the direct
  `HybridNetwork` convenience surface.
- Closing tasks: 1 and 2.
- Verification artifact:
  direct weighted plotting on that equal-length minimal rooted 2-cycle must
  succeed on `Axis`, `LineageAxis`, and the non-mutating `lineageplot` surface,
  and its computed geometry must match the generic core accessor path.

### Lock 3: ambiguous duplicate-endpoint weighted requests still fail directly

- The work is not complete if the fix restores equal-length support by
  choosing, averaging, tolerance-merging, or otherwise hiding conflicting
  duplicate-endpoint weights.
- Direct red-state repro:
  a duplicate-endpoint group with conflicting partner `edge.length` values is
  genuinely unrepresentable under the current `edgeweight(src, dst)` API.
- Closing tasks: 1 and 2.
- Verification artifact:
  a direct weighted regression that mutates one partner edge length in the
  minimal rooted 2-cycle must fail with a duplicate-endpoint ambiguity
  diagnostic that names the node-pair contract boundary.

### Lock 4: the core geometry owner remains the sole authority for global additive consistency

- The work is not complete if the extension now precomputes or substitutes its
  own whole-network weighted consistency rule instead of letting
  `src/Geometry.jl` decide that contract.
- Direct red-state repro:
  the previous blanket duplicate-endpoint pre-rejection prevented some valid
  requests from ever reaching the core owner.
- Closing tasks: 1 and 2.
- Verification artifact:
  the existing unique-endpoint inconsistent weighted `net1.out` regression must
  still fail with the core `full-network consistency` diagnostic after the
  extension-local fix lands.

### Lock 5: direct extension and generic core weighted surfaces stay aligned

- The work is not complete if equal-length duplicate-endpoint weighted plots
  succeed only on the generic core path while the direct `HybridNetwork`
  convenience path remains narrower.
- Direct red-state repro:
  the current minimal rooted 2-cycle already demonstrates generic-core success
  but direct-extension failure.
- Closing tasks: 1 and 2.
- Verification artifact:
  compare `computed_geom` from the direct extension path against
  `computed_geom` from the generic core accessor path on the same equal-length
  minimal rooted 2-cycle.

### Lock 6: overlay identity and rooted full-network rendering remain green

- The work is not complete if the weighted fix accidentally regresses the
  already-landed per-edge overlay repair, rooted 2-cycle reticulation styling,
  or gamma-label separation.
- Direct red-state repro:
  current overlay identity is green at `HEAD`, but the remaining work touches
  the same extension file and could regress it.
- Closing tasks: 2 and 3.
- Verification artifact:
  the existing rooted 2-cycle render regressions for separate major/minor edge
  styling and gamma labels remain green.

### Lock 7: tranche-4 docs truth, example truth, and tree or tranche-3 behavior remain green

- The work is not complete if the final weighted fix forces public docs truth
  changes, breaks the tranche-4 example, or regresses tree or tranche-3
  behavior.
- Direct red-state repro:
  current docs and example surfaces are already landed and must stay honest.
- Closing tasks: 2 and 3.
- Verification artifact:
  `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, and
  `julia --project=test examples/src/phylonetworks_full_network_ex1.jl`
  all remain green at tranche completion.

## Handoff packet

- Active authorities:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the bundled
  development-policies baseline, the four design documents, the parent PRD,
  the tranche file, the earlier tranche-4 taskings, and this completion file
- Parent documents:
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
  and
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- Settled decisions and non-negotiables:
  rooted full-network only; optional extension only; no public accessor
  redesign; equal-length duplicate-endpoint weighted groups must be supported;
  conflicting duplicate-endpoint weighted groups must fail directly; global
  additive consistency remains owned by `src/Geometry.jl`
- Authorization boundary:
  `ext/PhyloNetworksExt.jl`, targeted tests, touched source docstrings only
- Current-state diagnosis:
  overlay identity is fixed, but the direct weighted extension path still
  blanket-rejects duplicate-endpoint networks that the generic core path can
  already represent honestly
- Primary-goal lock:
  lock items 1 through 7 above
- Direct red-state repros:
  minimal equal-length rooted 2-cycle succeeds on the generic core weighted
  surface but fails on the direct extension weighted surface
- Owner and invariant under repair:
  extension-local duplicate-endpoint weighted representability boundary
- Exact files or surfaces in scope:
  `ext/PhyloNetworksExt.jl`, `test/test_PhyloNetworksExt.jl`,
  `test/test_Integration.jl`, `test/test_ExtensionBoundary.jl`,
  and touched source docstrings if necessary
- Exact files or surfaces out of scope:
  `src/Topology.jl`, public accessor API redesign, public docs rewrites,
  projection-policy work, styling-control work, and unrelated integrations
- Required upstream primary sources:
  the `PhyloNetworks.jl` and Makie files named above
- Green-state gates:
  equal-length duplicate-endpoint weighted positive regressions,
  differing-length duplicate-endpoint weighted negative regressions,
  existing rooted 2-cycle overlay regressions,
  extension-absence proof,
  `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, and
  `julia --project=test examples/src/phylonetworks_full_network_ex1.jl`
- Stop conditions:
  any claimed need to redesign the public `edgeweight` API,
  any claimed need to reopen docs truth rather than fix code,
  any attempt to average or choose among conflicting duplicate-endpoint
  weights, or any attempt to reopen tranche-5 policy work

## Required revalidation before implementation

- Re-read the parent PRD, tranche file, and all tranche-4 tasking files in
  full.
- Re-read the local owner files and tests listed above in full.
- Re-read the upstream primary sources listed above in full.
- Reconfirm that the current public `edgeweight` contract remains
  `edgeweight(src, dst)`.
- Reconfirm that the minimal rooted 2-cycle
  `((t1:1)#H22:1::0.8,#H22:1::0.2);` still parses, is rooted, and contains one
  duplicate-endpoint group of multiplicity 2.
- Reconfirm before edits that:
  - the generic core weighted plotting surface succeeds on that equal-length
    minimal rooted 2-cycle
  - the direct extension weighted plotting surface still fails on that same
    fixture
  - the failure comes from the extension blanket duplicate-endpoint check, not
    from the core additive-consistency owner
- Reconfirm that the current rooted 2-cycle overlay render regressions are
  still present and still represent the separate-edge styling contract.
- Re-run the required baseline verification before substantial edits:
  - `julia --project=test test/runtests.jl`
- If current `HEAD` no longer matches this diagnosis, stop and rewrite the
  tasking instead of executing it blindly.

## Tranche execution rule

This completion pass must begin from the already-landed tranche-4 code and end
with the direct `HybridNetwork` weighted contract aligned to the parent PRD and
tranche semantics.

When tranche 4 is finally complete:

- direct rooted full-network weighted plotting succeeds whenever the current
  public node-pair accessor can represent every duplicate-endpoint group
  honestly and the core additive full-network consistency owner accepts the
  network
- direct rooted full-network weighted plotting fails directly only for genuine
  duplicate-endpoint ambiguity or for the settled core full-network
  consistency reasons
- overlay identity and rooted full-network rendering remain green
- docs, example, tree behavior, and tranche-3 behavior remain green

## Non-negotiable execution rules

- Do not add `PhyloNetworks.jl` to root `[deps]`, `docs/Project.toml`, or
  `examples/Project.toml`.
- Do not redesign `src/Topology.jl`.
- Do not redesign the public `LineageGraphAccessor.edgeweight` callable shape.
- Do not keep the blanket duplicate-endpoint `:edgeweights` ban from
  `03-03a_tranche-4--remediation-tasking.md`; that narrower rule is
  superseded by this file.
- Do not choose the first partner edge, average partner edges, or merge them by
  tolerance when duplicate-endpoint lengths disagree.
- Do not add projection, view-mode, or styling controls.
- Do not move additive full-network consistency logic into the extension.
- Do not reopen docs truth or tranche-5 policy work to justify a code-side
  shortcut.

## Concrete anti-patterns or removal targets

- The current blanket `_require_unambiguous_edgeweights(...)` behavior must be
  removed or narrowed so equal-length duplicate-endpoint groups no longer fail.
- Any `edgeweight(src, dst)` implementation that throws solely because the
  endpoint-group multiplicity exceeds 1 is forbidden.
- Any fix that restores success by choosing one conflicting partner length is
  forbidden.
- Any fix that leaves the direct extension weighted path narrower than the
  generic core weighted path on equal-length duplicate-endpoint groups is
  forbidden.
- Any proof surface that checks only the negative ambiguity case and omits the
  equal-length positive case is forbidden.

## Failure-oriented verification

- Keep the extension-absence proof green.
- Keep the rooted-scope rejection green.
- Keep the existing unique-endpoint `net1.out` weighted-consistency rejection
  green so the core owner remains authoritative.
- Keep the existing rooted 2-cycle overlay render proof green.
- Add a minimal equal-length rooted 2-cycle fixture:
  `((t1:1)#H22:1::0.8,#H22:1::0.2);`
- Add a direct positive regression proving that:
  - the generic core weighted path succeeds on that fixture
  - the direct extension weighted path succeeds on that fixture
  - `computed_geom` from the direct extension path matches `computed_geom`
    from the generic core path on that fixture
- Add a direct negative regression that mutates exactly one partner edge length
  in that same minimal rooted 2-cycle and proves that the direct extension
  weighted path fails with a duplicate-endpoint ambiguity diagnostic.
- Keep or strengthen the existing multi-surface proof obligations:
  - at least one `Axis` regression
  - at least one `LineageAxis` regression
  - at least one non-mutating `lineageplot` regression
- End the completion pass with:
  - `julia --project=test test/runtests.jl`
  - `julia --project=docs docs/make.jl`
  - `julia --project=test examples/src/phylonetworks_full_network_ex1.jl`

## Tasks

1. **Title**: Narrow the extension-local duplicate-endpoint weighted rejection to genuine ambiguity only
   **Type**: `WRITE`
   **Output**: `ext/PhyloNetworksExt.jl` treats duplicate-endpoint groups as
   weighted-ambiguous only when their partner `edge.length` values conflict;
   equal-length duplicate-endpoint groups flow through the direct weighted
   `HybridNetwork` path and then into the settled core additive-consistency
   owner unchanged.
   **Depends on**: `none`
   **Positive contract**:
   the direct `HybridNetwork` weighted path becomes exactly as permissive as
   the current public `edgeweight(src, dst)` contract allows; equal-length
   duplicate groups are accepted; conflicting groups fail directly; the core
   geometry owner still decides whole-network additive consistency.
   **Negative contract**:
   do not keep the blanket multiplicity-based rejection; do not choose or
   average conflicting partner lengths; do not redesign the public accessor API;
   do not move full-network consistency logic into `ext/`.
   **Files**:
   `ext/PhyloNetworksExt.jl`, touched source docstrings if strictly required
   **Out of scope**:
   `src/Topology.jl`, public API redesign, docs rewrites, examples rewrites,
   and tranche-5 policy work
   **Verification**:
   add or update focused regressions showing that the equal-length minimal
   rooted 2-cycle reaches the weighted plot path successfully while a mutated
   differing-length version fails directly; run `julia --project=test test/runtests.jl`.

2. **Title**: Add contract-level weighted duplicate-endpoint proofs across generic and direct public surfaces
   **Type**: `TEST`
   **Output**: the suite proves that equal-length duplicate-endpoint weighted
   requests succeed and match the generic core geometry, while conflicting
   duplicate-endpoint weighted requests fail directly and unique-endpoint global
   inconsistency still fails in the core owner.
   **Depends on**: `1`
   **Positive contract**:
   `Axis`, `LineageAxis`, and non-mutating direct `lineageplot` surfaces are
   all covered; the equal-length minimal rooted 2-cycle succeeds on both the
   direct and generic weighted paths; `computed_geom` equality proves the
   direct extension did not invent a narrower contract.
   **Negative contract**:
   do not prove only error/no-error; do not leave the equal-length positive case
   untested; do not let the suite pass if the direct extension path remains
   narrower than the generic core path.
   **Files**:
   `test/test_PhyloNetworksExt.jl`, `test/test_Integration.jl`,
   `test/test_ExtensionBoundary.jl`
   **Out of scope**:
   source owner redesign outside `ext/PhyloNetworksExt.jl`, docs rewrites,
   vocabulary rewrites, and projection-policy work
   **Verification**:
   run `julia --project=test test/runtests.jl`; include:
   - a positive equal-length minimal 2-cycle weighted regression on `Axis`
   - a positive equal-length minimal 2-cycle weighted regression on `LineageAxis`
   - a positive equal-length minimal 2-cycle non-mutating regression
   - a geometry-equality proof between generic and direct weighted paths
   - a negative differing-length ambiguity regression
   - the existing unique-endpoint `net1.out` full-network consistency failure

3. **Title**: Reconfirm rooted full-network render integrity and tranche-completion green state
   **Type**: `TEST`
   **Output**: the already-landed overlay identity repair, optional extension
   boundary, docs truth, and example truth remain green after the weighted
   contract correction, and tranche 4 can be closed honestly.
   **Depends on**: `2`
   **Positive contract**:
   rooted 2-cycle overlay render proofs still show separate major/minor edge
   styling and gamma labels; extension absence still works; docs and example
   still build and run; the repo ends the tranche in a fully green user-facing
   state.
   **Negative contract**:
   do not treat passing weighted regressions alone as tranche completion; do not
   let the weighted fix regress the already-landed overlay repair or public
   docs truth; do not accept a fake green that skips docs or example gates.
   **Files**:
   `test/test_PhyloNetworksExt.jl`, `test/test_ExtensionBoundary.jl`
   **Out of scope**:
   new docs content, new example content, new public APIs, and unrelated
   integrations
   **Verification**:
   run all of:
   - `julia --project=test test/runtests.jl`
   - `julia --project=docs docs/make.jl`
   - `julia --project=test examples/src/phylonetworks_full_network_ex1.jl`
   and confirm that the rooted 2-cycle overlay regressions, extension-absence
   proof, and direct weighted regressions are all green together.

## Fresh-agent durability check

This file is only acceptable if a fresh implementing agent can succeed without
reopening design decisions. The weighted decision is now fully resolved here:

- equal-length duplicate-endpoint weighted groups must succeed
- conflicting duplicate-endpoint weighted groups must fail directly
- global additive consistency remains owned by `src/Geometry.jl`
- the direct extension path must match the generic core path when the current
  public accessor can represent the request honestly
- no public accessor redesign is authorized in tranche 4
- overlay identity, docs truth, example truth, and optional activation are
  already landed and must remain green

If implementation discovers that the code still cannot satisfy this resolved
contract without redesigning the public accessor API, stop and rewrite the
workflow document instead of improvising inside tranche 4.

No project files are changed by this document alone. The next workflow phase is
`Tasks -> Execute`.
