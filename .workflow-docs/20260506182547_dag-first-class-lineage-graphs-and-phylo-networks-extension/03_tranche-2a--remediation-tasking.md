---
date-created: 2026-05-07T15:57:26-07:00
date-revised: 2026-05-07T15:57:26-07:00
status: approved
---

# Tasks for Tranche 2 Remediation: explicit-coordinate leaf-order compatibility and full-geometry plot-envelope ownership

Tasking identifier: `20260507T155726--tranche-2a-remediation-tasking`

This file supplements and partially supersedes
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2--tasking.md`
for the remaining tranche-2 work after review of commit `e1b5208`.

If this file is executed honestly, no further tranche-2 remediation tasking
should be required. A fresh implementation agent should use this file,
together with the parent PRD, tranche file, tranche-1 tasking, tranche-1
remediation tasking, and the original tranche-2 tasking, as the
authoritative handoff for the remaining tranche-2 repair.

Parent tranche: Tranche 2
Parent PRD: `01_prd.md`
Prerequisite tranche tasking: `03_tranche-1--tasking.md`
Prerequisite remediation tasking: `03_tranche-1a--remediation-tasking.md`
Parent tranche tasking under repair: `03_tranche-2--tasking.md`
Current implementation under repair: commit `e1b5208`

## Settled user decisions and environment baseline

- DAG lineage graphs remain first-class in the core owner model. Rooted trees
  remain the single-parent special case inside that same owner path.
- `src/Geometry.jl` remains the settled geometry owner file for this tranche
  family. Do not reopen the tranche-2 geometry-owner decision by splitting the
  fix across several new core files unless an explicit `REVIEW` gate becomes
  necessary.
- `src/Topology.jl` remains settled. Do not reopen the tranche-1 topology
  owner work except for a strictly required minimal consistency touch.
- `LineageGraphGeometry` remains the existing public geometry carrier. No
  field removal, field rename, exported API removal, signature break, or
  hidden public contract break is authorized here.
- New ratified decision: `leaf_order` is not an internal convenience. It is a
  public compatibility surface consumed by leaf-label and clade-annotation
  owners, and by `LineageAxis`. Any layout path that supports those public
  surfaces must derive `leaf_order` from rendered geometry order, not from a
  stale topology sink order.
- New ratified decision: this remediation does not authorize silently
  redefining `boundingbox`. `STYLE-vocabulary.md` already fixes it as the
  smallest axis-aligned rectangle enclosing all `node_positions` in a layout.
  Any owner that needs the full rendered extent must use an explicit
  full-geometry plot-envelope owner instead of changing the meaning of
  `boundingbox`.
- New ratified decision: render-no-error is not sufficient proof for either
  surviving bug. Verification must prove public contract alignment directly.
- The tranche file's `lineageunits` decisions remain authoritative:
  `:nodelevels`, `:nodedepths`, `:nodeheights`, `:nodecoordinates`, and
  `:nodepos` remain tranche-2 DAG-safe units. `:edgeweights`,
  `:branchingtime`, and `:coalescenceage` remain explicit full-network units.
  Do not reopen the weighted honesty policy in this remediation.
- `PhyloNetworks.jl` remains an optional package extension. Do not add it to
  `[deps]`, do not move geometry ownership into `ext/`, and do not introduce
  a hidden projected-tree owner as a workaround.
- No repo-owned public projection-selection API is authorized here. If honest
  remediation requires a new public view-mode or projection keyword, stop for
  explicit review instead of improvising one.
- No Tier 3 work is authorized here. Do not implement hybrid markers, gamma
  labels, network-specific rendering primitives, or network view modes in this
  remediation.
- README, roadmap, and docs-site cleanup remain out of scope except for
  minimal touched-surface honesty in code comments, docstrings, or scoped
  examples directly affected by the repair.
- Use the repository root project as the owning environment for core code.
- Use `test/Project.toml` and `docs/Project.toml` as the canonical test and
  docs environments.
- Do not rely on network access or registry downloads. Use the approved local
  upstream checkout root
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/`.
- No explicit `REVIEW` task is required at the current diagnosis. Stop for
  review only if honest remediation requires redefining `boundingbox`, adding
  a new public `LineageGraphGeometry` field, adding a public
  projection-selection API, or otherwise reopening a public contract.

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
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1a--remediation-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2--tasking.md`
- this remediation file
- `design/design.md`
- `design/target-reference-capacities.md`
- `design/requirements-landscape-gap.md`
- `design/api-landscape.md`

The bundled style baseline under
`/home/jeetsukumaran/site/service/env/start/workhost/resources/packages/shared/workhost-resources/configure/coding-agent-skills/development-policies/references/`
was also read during this remediation rewrite and remains aligned with the
repo-local `STYLE*.md` stack above. Bundled `CONTRIBUTING.md` was not present
there, so repo-local `CONTRIBUTING.md` remains authoritative for contribution
guidance.

Workflow authorities used to produce this remediation were
`development-policies`, `devflow-architecture-03--tranche-to-tasks`, and the
tranche-2 review findings generated against commit `e1b5208`. Downstream
implementation must preserve their pass-forward mandates, especially
active-authority restatement, exact upstream-source naming, exact
authorization boundaries, controlled vocabulary, primary-goal lock items,
direct red-state repros, and failure-oriented verification.

Upstream primary sources that must be read line by line for this remediation
are:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/types.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/auxiliary.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/recursion_routines.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/compareNetworks.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/generic/space.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/makielayout/types.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/makielayout/blocks/axis.jl`

These sources constrain the remediation as follows:

- `PhyloNetworks.jl` still confirms that nodes and edges are first-class
  upstream entities, that hybrid nodes may own several parent edges, and that
  multi-parent incidence must remain explicit rather than collapsing to a
  hidden single-parent path.
- `PhyloNetworks.jl` comparison and major-tree utilities still demonstrate
  that projected tree views are explicit upstream operations. This remediation
  may not smuggle an equivalent projection into leaf-order or weighted layout
  logic as an unstated fallback.
- Makie `axis.jl` shows that `update_axis_camera` feeds explicit left/right and
  bottom/top limits directly into `orthographicprojection`. Local inference:
  when the rendered geometry extends beyond the node envelope, the owner that
  sets plot limits must be given the real rendered envelope rather than hoping
  downstream scene machinery will infer it.
- Makie `space.md` and recipe guidance reinforce a second local inference: when
  explicit coordinates are supplied, downstream public label and annotation
  owners must remain aligned with the actual rendered coordinates rather than
  a stale topology order.

Controlled vocabulary from `STYLE-vocabulary.md` is mandatory. Use
`lineage graph`, `basenode`, `node`, `edge`, `topology owner`, `geometry
owner`, `compatibility surface`, `ownership boundary`, `package extension`,
`lock item`, `red-state repro`, `verification artifact`, `normalized
topology`, `boundingbox`, `leaf_order`, and `full-network view`
consistently. Do not describe a hidden tree projection, stale topology order,
or broadened node envelope as if it were successful DAG support.

Read-only git and shell commands may be used freely. Mutating git operations
such as commit, merge, push, rebase, reset, and branch creation remain the
human project owner's responsibility unless the user explicitly instructs
otherwise.

## Revalidated current state

- `src/Topology.jl` now normalizes shared-descendant DAGs and preserves stable
  node order, parent incidence, child incidence, and edge order.
- `src/Geometry.jl` now owns tranche-2 DAG-safe geometry and weighted
  full-network consistency checks. The old tree-only guard is gone.
- `test/test_Geometry.jl`, `test/test_Integration.jl`,
  `test/test_LineageAxis.jl`, and
  `examples/src/shared_descendant_dag_ex1.jl` now prove substantial tranche-2
  behavior and weighted honesty.
- The surviving red state is not a topology failure and not the tranche-1
  last-parent overwrite. The surviving red state is two public
  geometry-carrier compatibility leaks inside the new tranche-2 owner path.
- Current red state 1: explicit-coordinate bypasses in `rectangular_layout`
  and `circular_layout` still set `leaf_list = source_nodes(topology.sink_order)`.
  Direct repro on commit `e1b5208`: a four-leaf rooted tree with explicit leaf
  y positions `a=40`, `b=10`, `c=30`, and `d=20` returns
  `geom.leaf_order == ["a", "b", "c", "d"]` even though sorting those same
  leaves by rendered y coordinate yields `b, d, c, a`. This means the layout
  can render leaves in one order while public label and annotation surfaces
  consume them in another.
- Current red state 2: `geom.boundingbox` is still computed from
  `node_positions` only, while circular chord edge geometry can extend beyond
  that node envelope. Direct repro on commit `e1b5208`: a balanced four-leaf
  rooted tree rendered with `circular_layout(...; lineageunits = :nodeheights)`
  has 9 finite `geom.edge_shapes` points outside `geom.boundingbox`, with the
  first escaping point at approximately `(-1.4142135, 1.4142135)`.
- `src/Layers.jl` consumes `geom.leaf_order` directly for leaf-label strings
  and label-position correspondence. `src/LineageAxis.jl` also consumes
  `geom.leaf_order` directly for label text resolution.
- `src/LineageAxis.jl:reset_limits!` and `ScaleBarLayer` still consume
  `geom.boundingbox` along public paths where the real contract may instead be
  the full rendered plot envelope. This remediation must examine each such
  consumer honestly rather than applying a blanket substitution.
- Current tests still let both bugs survive because they prove node positions,
  edge counts, representative renders, and render-no-error behavior, but they
  do not yet force public leaf-label order or radial full-geometry
  limit/decor correctness.
- `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl` must be rerun at remediation start and
  remediation end. Review-time execution did not finish within the prior
  timebox, so this remediation file does not claim a fresh green baseline from
  that interrupted run.

## Drift diagnosis

### Why the implementation drifted

- The previous implementation failure was not purely an implementer mistake.
  The original tranche-2 tasking correctly forced a DAG-safe geometry owner,
  stable edge identity, and weighted honesty, but it did not promote
  `leaf_order` to a separate lock item even though `STYLE-vocabulary.md` and
  current public plotting code already treat it as a first-class public
  geometry field.
- The original tranche-2 tasking also preserved `LineageGraphGeometry` and its
  `boundingbox` field without explicitly reconciling that preservation with
  the vocabulary contract that `boundingbox` is a node envelope while some
  public consumers actually need the full rendered plot extent. That left an
  ownership gap: the review found a real plot-envelope bug, but the tasking
  had not yet named the owner that should close it.
- The original tranche-2 verification stayed too close to helper geometry
  proxies. It proved node positions, edge presence, and successful plotting,
  but it did not require a direct proof that explicit-coordinate labels stay
  aligned with rendered leaf order or that all finite circular edge geometry
  lies inside the owner used for limits and plot-sensitive decoration.

### What is now baked in

- `leaf_order` is now a separate lock item and a named public compatibility
  surface.
- `boundingbox` now has an explicit non-redefinition rule. A fix that silently
  broadens it to full rendered extent is an anti-fix unless the implementation
  agent stops for explicit review.
- Plot-envelope ownership is now explicit. The remediation must repair the
  owner used by limit-setting and decoration consumers whose true contract is
  the full rendered extent. It must not assume that every existing
  `geom.boundingbox` consumer should change, and it must not assume that none
  should.
- Render-no-error, geometry-exists, and node-only containment checks are now
  explicitly insufficient proofs for this remediation.

## Primary-goal lock

### Lock 1: explicit-coordinate `leaf_order` must match rendered leaf order

- The work is not complete if `:nodecoordinates` or `:nodepos` can still
  render leaves in one order while returning `geom.leaf_order` in another.
- Direct red-state repro: on commit `e1b5208`, explicit leaf y positions
  `a=40`, `b=10`, `c=30`, and `d=20` render in transverse order `b, d, c, a`
  while `geom.leaf_order` remains topology ordered as `a, b, c, d`.
- Closing tasks: 1 and 3.
- Verification artifact: direct geometry tests plus public leaf-label proofs on
  `Axis` and `LineageAxis` must show that label strings, leaf positions, and
  `geom.leaf_order` all agree with rendered order. A fake fix that sorts only
  strings or only consumer-local positions must fail because the geometry
  carrier remains stale.

### Lock 2: the full-geometry plot envelope must own radial limits and other full-extent consumers

- The work is not complete if finite rendered geometry points can still lie
  outside the owner used by radial limit-setting, clipping-sensitive plot
  decisions, or any other consumer whose real contract is the full rendered
  extent.
- Direct red-state repro: on commit `e1b5208`,
  `circular_layout(...; lineageunits = :nodeheights)` produces 9 finite
  `edge_shapes` points outside `geom.boundingbox`, with the first escaping
  point at approximately `(-1.4142135, 1.4142135)`.
- Closing tasks: 2 and 3.
- Verification artifact: direct regressions must prove that the node envelope
  remains unchanged while the full-geometry plot-envelope owner contains all
  finite node and edge points used by the relevant public consumers.

### Lock 3: `boundingbox` semantics must not be silently rewritten

- The work is not complete if remediation broadens `boundingbox` or otherwise
  changes its meaning from "node envelope" to "full rendered extent" without
  explicit review.
- Direct red-state equivalent: the current bug tempts a quick fix by widening
  `geom.boundingbox`, but `STYLE-vocabulary.md` already defines that field and
  `boundingbox(::LineageGraphGeometry)` as the `node_positions` envelope.
- Closing tasks: 2 and 3.
- Verification artifact: a direct regression must prove that a radial layout
  can have full rendered geometry that extends beyond the node envelope while
  `geom.boundingbox` still equals the node-position envelope and the new plot
  envelope still contains the whole rendered geometry. This catches the
  "just widen boundingbox" anti-fix.

### Lock 4: public plotting surfaces must prove the same contracts, not just helper geometry

- The work is not complete if helper-level geometry tests pass while `Axis`,
  `LineageAxis`, leaf-label, clade-annotation, limit-setting, or scale-bar
  public behavior can still drift from the repaired owner contracts.
- Direct red-state equivalent: the current public suite renders successfully
  while both review findings survive.
- Closing tasks: 1 through 3.
- Verification artifact: public plotting tests must cover both mutating and
  non-mutating entrypoints where relevant, and must prove leaf-label order and
  full-geometry plot-envelope behavior directly rather than through
  render-no-error proxies alone.

### Lock 5: tranche-2 DAG-safe geometry, weighted honesty, rooted-tree behavior, and stable edge order must remain green

- The work is not complete if this remediation regresses DAG-safe units,
  weighted full-network honesty, rooted-tree plotting behavior, or stable edge
  identity tied to normalized topology order.
- Direct red-state equivalent: the remediation touches the same geometry and
  plotting path that tranche 2 already repaired, so a local compatibility fix
  can still regress those tranche-2 contracts.
- Closing tasks: 1 through 3.
- Verification artifact: existing tranche-2 DAG, weighted, rooted-tree, and
  edge-order proofs must remain in force and stay green.

## Handoff packet

Active authorities:

- `AGENTS.md`
- `CONTRIBUTING.md`
- all repo-local `STYLE*.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1--tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1a--remediation-tasking.md`
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2--tasking.md`
- this remediation file
- `design/design.md`
- `design/target-reference-capacities.md`
- `design/requirements-landscape-gap.md`
- `design/api-landscape.md`

Settled decisions and non-negotiables:

- DAG-safe geometry owner work from tranche 2 remains landed.
- Rooted trees remain the single-parent special case inside the same core
  owner path.
- `leaf_order` is a public compatibility surface and must reflect rendered
  order for explicit-coordinate layouts.
- `boundingbox` remains the node envelope and may not be silently redefined.
- No public `LineageGraphGeometry` break is authorized.
- No new public projection-selection API is authorized.
- No Tier 3 rendering or docs-site cleanup is authorized.

Authorization boundary:

- Internal geometry-adjacent compatibility repair is authorized.
- Public contract breaks are not authorized.
- Minimal touched-surface docstring and comment honesty is authorized where
  the owner semantics change.

Current-state diagnosis:

- The surviving tranche-2 failures are public compatibility leaks, not core
  DAG-topology failures.
- The first leak is stale explicit-coordinate `leaf_order`.
- The second leak is missing full-geometry plot-envelope ownership for the
  consumers whose contract is the full rendered extent.

Primary-goal lock:

- Lock 1 through Lock 5 above.

Direct red-state repros:

- Explicit-coordinate leaf-order repro: a four-leaf tree with leaf y values
  `a=40`, `b=10`, `c=30`, `d=20` still returns topology-order `leaf_order`
  instead of rendered-order `leaf_order`.
- Circular `:nodeheights` repro: a balanced four-leaf tree still yields 9
  finite `edge_shapes` points outside `geom.boundingbox`.

Owner and invariant under repair:

- Public leaf-order compatibility ownership for explicit-coordinate layouts.
- Full-geometry plot-envelope ownership for limit-setting and other consumers
  whose true contract is the rendered extent.
- Preservation of `boundingbox` as a node-envelope compatibility surface.

Exact scope in:

- `src/Geometry.jl`
- `src/Layers.jl`
- `src/LineageAxis.jl`
- `test/test_Geometry.jl`
- `test/test_Integration.jl`
- `test/test_LineageAxis.jl`
- `test/test_Layers.jl` only if a direct public proof belongs there
- one scoped example file only if it is genuinely needed as a proof artifact

Exact scope out:

- `src/Topology.jl` except for a strictly required minimal consistency touch
- `ext/`
- `Project.toml`
- `README.md`
- `ROADMAP.md`
- broad docs-site cleanup
- new public APIs
- Tier 3 rendering work

Green-state gates:

- `julia --project=test test/runtests.jl`
- `julia --project=docs docs/make.jl`

Stop conditions:

- Honest remediation appears to require redefining `boundingbox`.
- Honest remediation appears to require a new public `LineageGraphGeometry`
  field or another public geometry-carrier break.
- Honest remediation appears to require a new public projection-selection API.
- The live code has already moved enough that the repros or ownership
  assumptions in this file are no longer true.

## Required revalidation before edits

- Re-read `src/Geometry.jl`, `src/Layers.jl`, `src/LineageAxis.jl`, and all
  touched tests before making substantive edits.
- Re-run both direct red-state repros against the current `HEAD` before
  editing. Do not assume this remediation file is current merely because the
  review was recent.
- Re-run `julia --project=test test/runtests.jl` at remediation start if there
  is no fresher trustworthy green evidence than the interrupted review-time
  run.
- Re-run `julia --project=docs docs/make.jl` at remediation start if needed to
  confirm the docs baseline.
- Stop and escalate if the live code has already repaired either bug, or if
  `boundingbox` semantics have already changed elsewhere.

## Tranche execution rule

This remediation may redesign internal geometry-adjacent compatibility
ownership, but it must begin and end green. It must repair:

- explicit-coordinate `leaf_order`
- full-geometry plot-envelope ownership for the consumers whose contract is
  the full rendered extent

It must not:

- reopen tranche-2 weighted full-network policy
- redefine `boundingbox`
- add a public projection-selection API
- add a new public `LineageGraphGeometry` field

## Non-negotiable execution rules

- Do not fix explicit-coordinate leaf order by sorting only leaf-label strings,
  only clade labels, or only one consumer-local position array while leaving
  `geom.leaf_order` stale.
- Do not reinterpret `boundingbox` or silently widen it to absorb rendered
  edge geometry.
- Do not patch radial clipping by adding magic padding, larger fixed limits,
  or disabled clipping while leaving the owner ambiguous.
- Do not weaken or delete existing tranche-2 DAG, weighted, rooted-tree, or
  stable-edge-order proofs just to simplify remediation.
- Do not replace direct regressions with render-no-error, plot-exists, or
  helper-returned-something proxies.
- Do not apply a blanket migration of every `geom.boundingbox` consumer. Move
  only the consumers whose real contract is the full rendered extent, and
  prove each such move directly.

## Known anti-fix shapes that verification must fail

- `source_nodes(topology.sink_order)` remains the owner of explicit-coordinate
  `leaf_order`.
- `geom.boundingbox` is silently broadened and tests are updated to match the
  new meaning.
- Radial limit-setting is patched with extra padding but no explicit
  full-geometry plot-envelope owner.
- A consumer-local string reorder makes labels look right while
  `geom.leaf_order` still disagrees with rendered order.
- A fake proof checks only node containment inside `geom.boundingbox` while
  finite circular edge geometry still escapes the actual plotting envelope.

## Tasks

1. **Title**: Repair explicit-coordinate leaf-order ownership and public label compatibility  
   **Type**: `WRITE`  
   **Output**: explicit-coordinate rectangular and circular layouts derive
   `leaf_order` from actual rendered leaf positions used by public label and
   annotation surfaces, and `geom.leaf_order` is no longer stale on bypass
   paths.  
   **Depends on**: none  
   **Positive contract**: `rectangular_layout(...; lineageunits = :nodecoordinates/:nodepos)`
   sorts leaves by explicit transverse coordinate, using stable normalized-topology
   order only as a tie-break. `circular_layout(...; lineageunits = :nodecoordinates/:nodepos)`
   sorts leaves by the same around-center angular interpretation used by radial
   label placement, again with stable tie-breaks. Public label and annotation
   owners continue consuming the repaired `geom.leaf_order` rather than
   inventing their own order.  
   **Negative contract**: do not fix this by sorting only strings, only
   label-anchor positions, or only one plotting surface while leaving the
   geometry carrier stale. Do not reopen weighted semantics or stable edge
   order.  
   **Files**: `src/Geometry.jl`; `src/Layers.jl` and `src/LineageAxis.jl` only
   if shared compatibility wiring is strictly required.  
   **Out of scope**: `src/Topology.jl`, `ext/`, docs-site cleanup, new public
   API.  
   **Verification**: direct explicit-coordinate repro with y-order
   `a=40`, `b=10`, `c=30`, `d=20`; public leaf-label proofs on `Axis` and
   `LineageAxis`; a fake fix that sorts only consumer strings must fail.

2. **Title**: Establish an explicit full-geometry plot-envelope owner without redefining `boundingbox`  
   **Type**: `WRITE`  
   **Output**: an internal full-geometry plot-envelope owner derived from the
   finite rendered geometry exists and is used wherever limit-setting,
   clipping-sensitive plotting, or other full-extent consumers genuinely
   require it, while `boundingbox(geom)` remains the node envelope.  
   **Depends on**: none  
   **Positive contract**: radial and any other layouts whose rendered edge
   geometry extends beyond node extents get correct full-extent ownership for
   the consumers that need it. Touched `LineageAxis` and `Layers` docstrings
   or comments become honest about which owner governs limits, default
   placement, or default sizing when that owner changes.  
   **Negative contract**: do not silently broaden `boundingbox`; do not paper
   over the bug with extra padding, fixed oversized limits, or disabled
   clipping; do not add a new public `LineageGraphGeometry` field; do not
   assume every `geom.boundingbox` consumer must migrate.  
   **Files**: `src/Geometry.jl`, `src/LineageAxis.jl`, `src/Layers.jl`,
   `src/CoordinateTransform.jl` only if a helper truly belongs there.  
   **Out of scope**: public API changes, topology-owner redesign, broad docs
   cleanup.  
   **Verification**: direct radial `:nodeheights` and/or `:coalescenceage`
   repro that currently finds finite `edge_shapes` points outside
   `geom.boundingbox`; direct proof that `geom.boundingbox` still equals node
   extents; direct proof that the new plot envelope contains all finite
   geometry points required by the migrated consumers; fake fix that only
   broadens `boundingbox` must fail.

3. **Title**: Strengthen the proof surface for leaf-order and plot-envelope contracts while preserving tranche-2 behavior  
   **Type**: `TEST`  
   **Output**: direct and public tests fail the two known bugs, fail the
   `boundingbox`-broadening anti-fix, and keep existing tranche-2 DAG-safe,
   weighted, stable-edge-order, and rooted-tree proofs green.  
   **Depends on**: 1, 2  
   **Positive contract**: both geometry-owner and public plotting-owner proofs
   exist. At least one regression covers `Axis`. At least one regression
   covers `LineageAxis`. Existing tranche-2 proofs remain in force.  
   **Negative contract**: do not replace direct regressions with render-no-error
   proxies. Do not weaken weighted or rooted-tree tests to make the remediation
   easier. Do not erase the anti-fix coverage for broadened `boundingbox` or
   stale `geom.leaf_order`.  
   **Files**: `test/test_Geometry.jl`, `test/test_Integration.jl`,
   `test/test_LineageAxis.jl`, `test/test_Layers.jl` only if needed, and one
   optional scoped example file only if a public proof artifact is genuinely
   required.  
   **Out of scope**: README, roadmap, docs-site overhaul, Tier 3 features.  
   **Verification**: `julia --project=test test/runtests.jl`;
   `julia --project=docs docs/make.jl`; direct regressions that fail the
   current bugs and the `boundingbox` anti-fix shape.
