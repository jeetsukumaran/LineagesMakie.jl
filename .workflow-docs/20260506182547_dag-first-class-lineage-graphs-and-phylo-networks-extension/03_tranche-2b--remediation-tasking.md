---
date-created: 2026-05-07T18:07:49-07:00
date-revised: 2026-05-07T18:07:49-07:00
status: approved
---

# Tasks for Tranche 2B Remediation: unify `LineageAxis` quantitative-axis extent ownership with the rendered plot envelope

Tasking identifier: `20260507T180749--tranche-2b-remediation-tasking`

This file supplements and partially supersedes
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2a--remediation-tasking.md`
for the remaining tranche-2 work after review of commit `52ee7d8`.

If this file is executed honestly, and its required revalidation step does not
reveal new drift, no further tranche-2 remediation tasking should be required
before tranche 2 can be considered fully delivered.

Parent tranche: Tranche 2  
Parent PRD: `01_prd.md`  
Prerequisite tranche tasking: `03_tranche-1--tasking.md`  
Prerequisite remediation tasking: `03_tranche-1a--remediation-tasking.md`  
Parent tranche tasking under repair: `03_tranche-2--tasking.md`  
Prior remediation under repair: `03_tranche-2a--remediation-tasking.md`  
Current implementation under repair: commit `52ee7d8`

## Settled user decisions and environment baseline

- DAG lineage graphs remain first-class in the core owner model. Rooted trees
  remain the single-parent special case inside that same owner path.
- `src/Geometry.jl` remains the settled geometry owner for tranche 2. This
  remediation does not reopen topology ownership, weighted full-network
  honesty, or explicit-coordinate `leaf_order`.
- `src/LineageAxis.jl` is the owner under repair here. The surviving drift is
  inside its quantitative-axis and grid surfaces, not in the topology owner
  and not in the core geometry owner.
- `LineageGraphGeometry.boundingbox` remains the node envelope exactly as
  ratified in `STYLE-vocabulary.md`. This remediation does not authorize
  widening, renaming, or reinterpreting it.
- `Geometry._plot_envelope(geom)` already exists as the internal full-geometry
  extent owner. This remediation must use and preserve that owner rather than
  inventing a competing extent source.
- `reset_limits!` and scale-bar placement/sizing already migrated to the plot
  envelope. They are not the bug anymore. The remaining bug is that sibling
  `LineageAxis` quantitative-axis surfaces still consume `geom.boundingbox`.
- Supported public surfaces affected by the shared "displayed extent" semantic
  are now settled explicitly:
  - already on the correct owner and must remain there:
    `LineageAxis.reset_limits!`, radial scale-bar sizing, radial scale-bar
    placement, and any other `ScaleBarLayer` full-extent defaults already using
    `Geometry._plot_envelope`
  - still on the stale owner and must migrate in this remediation:
    x-axis tick values/labels/segments, y-axis tick values/labels/segments,
    y-axis band measurement, and grid generation in `LineageAxis`
  - intentionally preserved on the node envelope:
    `boundingbox(::LineageGraphGeometry)`, node-envelope geometry tests, and
    node-bounded consumers whose contract is not the full rendered extent
- No public `LineageGraphGeometry` field change, no public projection API, no
  new `LineageAxis` keyword, and no Tier 3 rendering work are authorized here.
- README, roadmap, docs-site cleanup, and broad example churn remain out of
  scope except for minimal touched-surface honesty in comments or docstrings.
- Use the repository root project as the owning environment for code changes.
- Use `test/Project.toml` and `docs/Project.toml` as the canonical test and
  docs environments.
- Do not rely on network access or registry downloads.
- No `REVIEW` task is required at the current diagnosis. Stop for review only
  if honest repair appears to require a public contract split where the camera
  and visible quantitative axes intentionally describe different extents.

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
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2a--remediation-tasking.md`
- this remediation file
- `design/design.md`
- `design/target-reference-capacities.md`
- `design/requirements-landscape-gap.md`
- `design/api-landscape.md`

The bundled style baseline under
`/home/jeetsukumaran/site/service/env/start/workhost/resources/packages/shared/workhost-resources/configure/coding-agent-skills/development-policies/references/`
was also read during this remediation rewrite and remains aligned with the
repo-local `STYLE*.md` stack above. The expected bundled `CONTRIBUTING.md` was
still absent there, so repo-local `CONTRIBUTING.md` remains authoritative for
contribution guidance.

Workflow authorities used to produce this remediation were
`development-policies` and `devflow-architecture-03--tranche-to-tasks`,
informed by the surviving tranche-2 remediation review finding against current
`HEAD` `52ee7d8`.

Upstream primary sources that must be read line by line for this remediation
are:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/generic/space.md`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/makielayout/types.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/makielayout/blocks/axis.jl`

These sources constrain the remediation as follows:

- Makie `axis.jl` confirms that the effective visible range comes from the
  explicit limits fed into the camera projection. Local inference: once
  `LineageAxis.reset_limits!` migrates from the node envelope to the full
  rendered plot envelope, visible quantitative-axis surfaces that claim to
  describe the displayed range must use the same owner unless an explicit and
  documented divergence is approved.
- Makie layout and space documentation reinforce that panel-owned quantitative
  axes and grid lines are decoration-layer behaviors tied to the displayed plot
  extent, not ad hoc node-extent conveniences.
- No `PhyloNetworks.jl` contract is being reopened here. The broader tranche-2
  DAG and weighted honesty obligations remain parent constraints, but the
  contract-sensitive upstream owner for this follow-on remediation is Makie.

Controlled vocabulary from `STYLE-vocabulary.md` is mandatory. Use
`lineage graph`, `node envelope`, `boundingbox`, `plot envelope`, `displayed
extent`, `geometry owner`, `LineageAxis`, `lock item`, `red-state repro`,
`verification artifact`, and `supported public surface` consistently.

Read-only git and shell commands may be used freely. Mutating git operations
such as commit, merge, push, rebase, reset, and branch creation remain the
human project owner's responsibility unless the user explicitly instructs
otherwise.

## Revalidated current state

- `src/Geometry.jl` now repairs the two earlier tranche-2 remediation findings:
  explicit-coordinate `leaf_order` is derived from rendered order, and
  `_plot_envelope(geom)` contains the full finite rendered geometry while
  `geom.boundingbox` remains the node envelope.
- `src/Layers.jl` scale-bar sizing and placement now consume
  `Geometry._plot_envelope(geom)` where their contract is the full rendered
  extent.
- `src/LineageAxis.jl:reset_limits!` now consumes `Geometry._plot_envelope`
  and correctly widens the camera for backward-time radial geometry.
- The remaining red state is a split owner inside `LineageAxis` itself:
  `reset_limits!` and scale-bar consumers use the plot envelope, while
  `_boundingbox_tick_values`, `_screen_axis_measurements`, `_wire_x_axis!`,
  `_wire_y_axis!`, and `_wire_grid!` still derive visible quantitative-axis
  behavior from `geom.boundingbox`.
- Direct current repro on commit `52ee7d8`:
  a balanced four-leaf rooted tree rendered through
  `LineageAxis(...; lineage_orientation = :radial, show_x_axis = true,
  show_y_axis = true, show_grid = true)` with
  `lineageplot!(...; lineageunits = :nodeheights)` produces:
  - `geom.boundingbox = Rect2f(origin = [-1.4142135, -0.70710677], widths = [2.1213202, 2.1213202])`
  - `_plot_envelope(geom) = Rect2f(origin = [-1.4142135, -1.4142135], widths = [2.828427, 2.828427])`
  - visible x-axis tick labels `["-1.41", "-0.88", "-0.35", "0.18", "0.71"]`
  - visible y-axis tick labels `["-0.71", "-0.18", "0.35", "0.88", "1.41"]`
- That means the camera shows a square full-envelope radial view while the
  quantitative axes still describe the narrower node envelope. Because grid
  generation consumes the same stale tick owner, grid lines drift with it.
- Current tests already prove the earlier fixes and radial full-envelope limit
  containment, but they still allow this split-owner state to survive because
  they do not directly assert that visible quantitative-axis ticks and grid
  span the same displayed extent that `reset_limits!` shows.

## Drift diagnosis

### Why the previous remediation was still incomplete

- The prior remediation packet correctly hardened `leaf_order` and plot
  envelope ownership, and it explicitly moved `reset_limits!` and scale-bar
  consumers to the full-geometry owner.
- But it still framed the remaining extent migration as "move the consumers
  whose real contract is the full rendered extent" without enumerating every
  `LineageAxis` quantitative-axis sibling surface separately.
- That left a derivable but nontrivial sibling sweep to the implementing agent.
  The agent repaired the camera and scale bar, but not the quantitative-axis
  and grid surfaces that still described the old owner.
- This file closes that gap by enumerating the remaining supported public
  surfaces one by one and by requiring direct proofs for each.

### What is now baked in

- The camera extent owner and the visible quantitative-axis extent owner are
  now treated as one shared public semantic unless explicit review approves a
  divergence.
- The remaining stale surfaces are explicitly enumerated:
  x-axis ticks, y-axis ticks, y-axis band measurement, and grid generation.
- The already-correct plot-envelope consumers are also enumerated so the next
  implementing agent does not reopen them or rework unrelated layers.
- `boundingbox` preservation is still mandatory and remains a separate lock.

## Primary-goal lock

### Lock 1: visible x-axis ticks must describe the displayed radial extent

- The work is not complete if `show_x_axis = true` can still display tick
  labels or tick marks derived from the node envelope while the camera shows
  the wider plot envelope.
- Direct red-state repro: on commit `52ee7d8`, radial backward-time geometry
  with `show_x_axis = true` displays
  `["-1.41", "-0.88", "-0.35", "0.18", "0.71"]` even though the displayed
  plot-envelope x range is approximately `[-1.4142135, 1.4142135]`.
- Closing tasks: 1 and 2.
- Verification artifact: a direct `LineageAxis` regression through
  `lineageplot!` must prove that x-axis tick labels or their underlying values
  span the plot-envelope x range rather than the node-envelope x range. A fake
  fix that leaves x-axis ticks on `geom.boundingbox` while only widening the
  camera must fail.

### Lock 2: visible y-axis ticks and y-axis band measurement must describe the displayed radial extent

- The work is not complete if `show_y_axis = true` can still reserve band
  width or display tick labels from the node envelope while the camera shows
  the wider plot envelope.
- Direct red-state repro: on commit `52ee7d8`, the same radial backward-time
  layout displays y-axis tick labels
  `["-0.71", "-0.18", "0.35", "0.88", "1.41"]` even though the displayed
  plot-envelope y range is approximately `[-1.4142135, 1.4142135]`.
- Closing tasks: 1 and 2.
- Verification artifact: direct tests must prove that y-axis tick values and
  the measurement path that reserves y-axis band width both consume the
  plot-envelope owner. A fake fix that updates only visible labels while
  leaving `_screen_axis_measurements` on `geom.boundingbox` must fail.

### Lock 3: grid generation must share the same extent owner as the visible quantitative axes and camera

- The work is not complete if `show_grid = true` can still draw grid lines at
  node-envelope positions after the camera and visible axes have moved to the
  plot envelope.
- Direct red-state repro: on commit `52ee7d8`, `_wire_grid!` still consumes
  `_boundingbox_tick_values`, so the grid is mechanically tied to the stale
  node-envelope owner even when the camera is not.
- Closing tasks: 1 and 2.
- Verification artifact: a direct `LineageAxis` regression with
  `show_x_axis = true`, `show_y_axis = true`, and `show_grid = true` must
  prove that grid lines are generated from the same plot-envelope tick values
  used by the visible axes. A fake fix that updates the visible labels only
  while leaving grid generation stale must fail.

### Lock 4: `boundingbox` must remain the node envelope and node-envelope consumers must not be migrated indiscriminately

- The work is not complete if remediation widens `geom.boundingbox`, redefines
  `boundingbox(::LineageGraphGeometry)`, or applies a blanket replacement of
  every `geom.boundingbox` consumer regardless of contract.
- Direct red-state equivalent: the current bug tempts a quick fix by replacing
  every node-envelope read with plot-envelope reads, but the controlled
  vocabulary and existing geometry tests still require `boundingbox` to remain
  the node envelope.
- Closing tasks: 1 and 2.
- Verification artifact: existing geometry proofs that
  `_plot_envelope(geom)` can exceed `geom.boundingbox` must remain intact, and
  the new `LineageAxis` regressions must pass without broadening
  `geom.boundingbox`. A fake fix that simply widens `boundingbox` must fail.

### Lock 5: earlier tranche-2 and tranche-2a repairs must remain green

- The work is not complete if this remediation regresses DAG-safe geometry,
  weighted full-network honesty, rooted-tree plotting behavior, explicit
  `leaf_order`, stable edge ordering, or the already-fixed full-envelope
  camera and scale-bar behavior.
- Direct red-state equivalent: this remediation touches the same owner family
  that tranche 2 and tranche 2a already repaired, so a narrow `LineageAxis`
  fix can still silently regress those guarantees.
- Closing tasks: 1 and 2.
- Verification artifact: the existing tranche-2 and tranche-2a tests remain in
  force and stay green alongside the new direct `LineageAxis` regressions.

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
- `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-2a--remediation-tasking.md`
- this remediation file
- `design/design.md`
- `design/target-reference-capacities.md`
- `design/requirements-landscape-gap.md`
- `design/api-landscape.md`

Settled decisions and non-negotiables:

- DAG-safe geometry and weighted honesty from tranche 2 remain landed.
- The earlier tranche-2a fixes for explicit-coordinate `leaf_order`,
  plot-envelope camera limits, and scale-bar extent ownership remain landed.
- `boundingbox` remains the node envelope.
- The shared displayed-extent semantic for `LineageAxis` must now be owned
  consistently across camera, visible quantitative axes, and grid.
- No public API break is authorized.
- No new projection-selection API is authorized.
- No Tier 3 rendering work is authorized.

Authorization boundary:

- Internal `LineageAxis` owner repair plus direct proof-surface strengthening
  is authorized.
- Public contract breaks are not authorized.
- Minimal touched-surface comment and docstring honesty is authorized.

Current-state diagnosis:

- The surviving tranche-2 drift is entirely inside `LineageAxis`.
- Camera and scale-bar surfaces use `Geometry._plot_envelope`.
- Visible x-axis ticks, visible y-axis ticks, y-axis band measurement, and grid
  generation still use `geom.boundingbox`.

Primary-goal lock:

- Lock 1 through Lock 5 above.

Direct red-state repros:

- Radial backward-time `LineageAxis` with
  `show_x_axis = true`, `show_y_axis = true`, and `show_grid = true` still
  shows node-envelope tick labels while the camera shows the wider plot
  envelope.
- `_boundingbox_tick_values`, `_screen_axis_measurements`, `_wire_x_axis!`,
  `_wire_y_axis!`, and `_wire_grid!` still reveal the stale owner directly in
  source.

Owner and invariant under repair:

- `LineageAxis` quantitative-axis extent ownership.
- Invariant: any supported public `LineageAxis` surface that claims to describe
  the displayed extent must consume the same plot-envelope owner as the camera,
  unless an explicit reviewed divergence says otherwise.

Exact scope in:

- `src/LineageAxis.jl`
- `test/test_LineageAxis.jl`
- `test/test_Integration.jl`
- `src/Layers.jl` only if touched-surface comment honesty or an existing
  shared helper truly requires a minimal change
- `src/Geometry.jl` only if a minimal helper signature or comment touch is
  strictly required, not for a new owner redesign

Exact scope out:

- `src/Topology.jl`
- `ext/`
- `Project.toml`
- `README.md`
- `ROADMAP.md`
- broad docs-site cleanup
- new public APIs
- weighted full-network policy
- Tier 3 rendering

Green-state gates:

- `julia --project=test test/runtests.jl`
- `julia --project=docs docs/make.jl`

Stop conditions:

- Honest repair appears to require the camera and visible quantitative axes to
  intentionally describe different extents.
- Honest repair appears to require widening or redefining `boundingbox`.
- Honest repair appears to require a new public API or keyword.
- Revalidation shows the live code has already moved enough that this diagnosis
  is no longer true.

## Required revalidation before edits

- Re-read `src/LineageAxis.jl`, `src/Layers.jl`, and the touched tests before
  making substantive edits.
- Re-run the direct radial backward-time repro against current `HEAD` before
  editing. Do not assume this file is current merely because the review was
  recent.
- Re-run `julia --project=test test/runtests.jl` at remediation start if there
  is no fresher trustworthy full-suite green evidence.
- Re-run `julia --project=docs docs/make.jl` at remediation start if needed to
  confirm the docs baseline.
- Stop and escalate if the live code has already moved the visible
  quantitative-axis surfaces off `geom.boundingbox`, or if a new sibling
  displayed-extent surface appears that this file does not name.

## Tranche execution rule

This remediation must begin and end green. It must repair the one remaining
shared-owner drift in `LineageAxis` by moving the supported public
quantitative-axis surfaces that describe the displayed extent onto the same
plot-envelope owner as the camera.

It must not:

- reopen weighted full-network policy
- reopen explicit-coordinate `leaf_order`
- redefine `boundingbox`
- add a public API
- broaden scope into Tier 3 rendering

## Non-negotiable execution rules

- Do not fix this by widening `geom.boundingbox`.
- Do not fix this by adding extra radial padding while leaving visible ticks on
  the stale owner.
- Do not fix this by updating only visible tick labels while leaving
  `_screen_axis_measurements` or `_wire_grid!` stale.
- Do not fix this by updating only grid lines while leaving visible ticks or
  band measurement stale.
- Do not migrate unrelated node-envelope consumers just because they happen to
  read `geom.boundingbox`.
- Do not weaken or remove the existing tranche-2 and tranche-2a proofs.
- Do not replace direct public regressions with render-no-error or
  helper-returned-something proxies.

## Known anti-fix shapes that verification must fail

- `_boundingbox_tick_values` survives unchanged as the owner of visible
  quantitative-axis extent.
- `geom.boundingbox` is widened and the tests are updated to match the new
  meaning.
- Visible x-axis ticks are fixed but y-axis ticks or y-axis band measurement
  still use the node envelope.
- Visible ticks are fixed but grid generation still uses the node envelope.
- The camera remains correct only because of `reset_limits!`, while the visible
  axis and grid surfaces still describe a different range.

## Tasks

1. **Title**: Centralize `LineageAxis` displayed-extent ownership for quantitative axes and grid  
   **Type**: `WRITE`  
   **Output**: `LineageAxis` uses one internal plot-envelope extent owner for
   all supported public surfaces that describe the displayed quantitative range:
   x-axis ticks, y-axis ticks, y-axis band measurement, and grid generation.  
   **Depends on**: none  
   **Positive contract**: `reset_limits!`, visible x-axis ticks, visible y-axis
   ticks, y-axis band measurement, and grid generation all consume the same
   plot-envelope extent owner. The implementation makes that shared owner
   explicit in `src/LineageAxis.jl` rather than repeating stale
   `geom.boundingbox` reads in sibling helpers. `boundingbox(geom)` remains the
   node envelope, and already-correct scale-bar consumers remain on the plot
   envelope without rework.  
   **Negative contract**: do not widen `boundingbox`; do not update only one of
   x ticks, y ticks, y-axis measurement, or grid; do not migrate unrelated
   node-envelope consumers; do not reopen tranche-2 geometry or weighted policy.  
   **Files**: `src/LineageAxis.jl`; `src/Layers.jl` or `src/Geometry.jl` only if
   a minimal touched-surface helper or comment change is strictly required.  
   **Out of scope**: `src/Topology.jl`, `ext/`, `Project.toml`, public API
   changes, docs-site cleanup, Tier 3 rendering.  
   **Verification**: direct radial backward-time repro with
   `show_x_axis = true`, `show_y_axis = true`, and `show_grid = true`; direct
   proof that visible x ticks, visible y ticks, and grid all span the
   plot-envelope range; direct proof that `geom.boundingbox` remains the node
   envelope; fake fixes that widen `boundingbox` or leave any sibling surface
   stale must fail.

2. **Title**: Strengthen the direct `LineageAxis` proof surface for displayed extent without regressing tranche 2  
   **Type**: `TEST`  
   **Output**: tests fail the current split-owner bug, fail the common
   anti-fix shapes, and keep the earlier tranche-2 and tranche-2a guarantees
   green.  
   **Depends on**: 1  
   **Positive contract**: at least one public regression covers
   `lineageplot!` on `LineageAxis`, and at least one integration regression
   covers the non-mutating `lineageplot(...; axis = (...))` path or explicitly
   justifies why the mutating proof is an exact proxy. The proof surface names
   and checks x-axis ticks, y-axis ticks, y-axis band measurement, and grid
   behavior separately enough that one cannot remain stale behind a green suite.
   Existing tranche-2 DAG-safe, weighted, rooted-tree, explicit-`leaf_order`,
   stable-edge-order, and plot-envelope camera proofs remain in force.  
   **Negative contract**: do not replace direct public regressions with
   render-no-error checks; do not weaken earlier geometry or integration tests;
   do not rely on a helper-only proof when a public `LineageAxis` artifact is
   available.  
   **Files**: `test/test_LineageAxis.jl`, `test/test_Integration.jl`,
   `test/test_Geometry.jl` only if an existing anti-fix proof needs a minimal
   strengthening.  
   **Out of scope**: README, roadmap, docs-site overhaul, Tier 3 examples.  
   **Verification**: `julia --project=test test/runtests.jl`;
   `julia --project=docs docs/make.jl`; direct regressions that fail the
   current `52ee7d8` split-owner bug and the `boundingbox`-widening anti-fix.
