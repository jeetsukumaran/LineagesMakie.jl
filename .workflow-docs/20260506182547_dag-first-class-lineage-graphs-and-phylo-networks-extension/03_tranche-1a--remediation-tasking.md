---
date-created: 2026-05-07T01:50:06-07:00
date-revised: 2026-05-07T01:50:06-07:00
status: approved
---

# Tasks for Tranche 1 Remediation: honest geometry boundary and extension-proof hardening

Tasking identifier: `20260507T015006--tranche-1-remediation-tasking`

This file supplements and partially supersedes
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1--tasking.md`
for the remaining tranche-1 work after review of commit `9815b12`.

If this file is executed honestly, no further tranche-1 remediation tasking
should be required. A fresh implementation agent should use this file,
together with the parent PRD, tranche file, and the original tranche-1 tasking
file, as the authoritative handoff for the remaining tranche-1 repair.

Parent tranche: Tranche 1
Parent PRD: `01_prd.md`
Parent tranche tasking under repair: `03_tranche-1--tasking.md`
Current implementation under repair: commit `9815b12`

## Settled user decisions and environment baseline

- DAG lineage graphs remain first-class in the core topology owner model.
  Rooted trees remain the single-parent special case inside that same owner
  path.
- `src/Topology.jl` remains the settled internal owner file for tranche-1
  topology normalization. Do not back this out or split normalization
  ownership into a second core implementation.
- `LineagesMakie.leaves` and `LineagesMakie.preorder` remain exported
  compatibility wrappers and must continue to accept valid shared-descendant
  DAGs.
- New ratified decision: Tranche 1 does not authorize end-to-end DAG geometry
  or plotting. Until Tranche 2 lands, any geometry or plotting surface that
  still depends on tree-only invariants must reject shared-parent DAG input
  directly and honestly.
- New ratified decision: successful `normalize_topology`, `leaves`, or
  `preorder` calls are not themselves proof that `rectangular_layout`,
  `circular_layout`, `lineageplot!`, or `lineageplot` support DAG geometry in
  tranche 1.
- New ratified decision: the optional `PhyloNetworks.jl` boundary is not
  proven by "extension not yet loaded" inside an environment that already
  depends on `PhyloNetworks`. The absence case must be proven in an isolated
  Julia subprocess or temporary project that does not declare `PhyloNetworks`
  as a dependency.
- `PhyloNetworks.jl` must remain an optional package extension. Do not add it
  to `[deps]` and do not move topology or geometry ownership into `ext/`.
- No repo-owned public API removal, rename, export change, or signature break
  is authorized in this remediation.
- No Tier 2 geometry implementation, Tier 3 network rendering work, hybrid
  markers, major or minor reticulation styling, gamma labels, or network view
  modes are authorized here. This remediation is an honesty and proof repair,
  not a tranche expansion.
- Use the repository root project as the owning environment for core code.
- Use `test/Project.toml` and `docs/Project.toml` as the canonical test and
  docs environments.
- Do not rely on network access or registry downloads. Use the approved local
  upstream checkout root
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/`.
- No explicit `REVIEW` task is required at the current diagnosis. Stop for
  review only if the implementation agent discovers that the honest geometry
  boundary cannot be restored without reopening public API policy or Tranche 2
  geometry design.

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
- this remediation file
- `design/design.md`
- `design/target-reference-capacities.md`
- `design/requirements-landscape-gap.md`
- `design/api-landscape.md`

The bundled style baseline under
`/home/jeetsukumaran/site/service/env/start/workhost/resources/packages/shared/workhost-resources/configure/coding-agent-skills/development-policies/references/`
was also read during this remediation rewrite and remains aligned with the
repo-local governance stack above. Bundled `CONTRIBUTING.md` was not present
there, so repo-local `CONTRIBUTING.md` remains authoritative for contribution
guidance.

Workflow authorities used to produce this remediation were
`development-policies`, `devflow-architecture-03--tranche-to-tasks`, and the
review findings generated against commit `9815b12`. Downstream implementation
must preserve their pass-forward mandates, especially active-authority
restatement, exact upstream-source naming, exact authorization boundaries,
controlled vocabulary, primary-goal lock items, direct red-state repros, and
failure-oriented verification.

Upstream primary sources that must be read line by line for this remediation
remain:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/types.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/auxiliary.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/recursion_routines.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/compareNetworks.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`

These sources constrain the remediation as follows:

- `PhyloNetworks.jl` confirms that multi-parent lineage-graph semantics belong
  in the core topology owner rather than in a source-specific extension.
- `PhyloNetworks.jl` traversal utilities distinguish shared ancestry from true
  cycles, which remains the preserved tranche-1 topology repair.
- Makie package-extension guidance confirms that extension modules are for
  optional integration wiring, not for making the core package importable only
  when the optional dependency is installed.

Controlled vocabulary from `STYLE-vocabulary.md` is mandatory. Use
`lineage graph`, `basenode`, `node`, `edge`, `compatibility wrapper`,
`topology owner`, `geometry owner`, `ownership boundary`, `package extension`,
`lock item`, `red-state repro`, and `verification artifact` consistently. Do
not describe this remediation as adding DAG geometry support. It restores an
honest boundary until the DAG-safe geometry tranche lands.

Read-only git and shell commands may be used freely. Mutating git operations
such as commit, merge, push, rebase, reset, and branch creation remain the
human project owner's responsibility unless the user explicitly instructs
otherwise.

## Revalidated current state

- `src/Topology.jl` now exists and correctly normalizes shared-descendant DAGs
  while distinguishing them from true directed cycles.
- `src/Accessors.jl` now routes `leaves` and `preorder` through the normalized
  topology owner, and those exported compatibility wrappers accept valid
  shared-descendant DAGs.
- `Project.toml` now declares `[weakdeps]` and `[extensions]`, and
  `ext/PhyloNetworksExt.jl` exists as the optional extension boundary.
- The current red state is not the old visited-set failure. The current red
  state is that `src/Geometry.jl` still consumes topology-backed traversal
  results with tree-only one-parent assumptions.
- Review-time direct repro on commit `9815b12` confirmed that a
  shared-descendant DAG with asymmetric edge weights reaches
  `rectangular_layout` and silently assigns the shared node from the later
  parent path instead of rejecting the unsupported geometry contract. In the
  reviewed repro, `shared` received process coordinate `13.0`, proving a
  last-parent overwrite rather than an honest owner-level rejection.
- `circular_layout` still uses the same tree-only process-coordinate and
  child-mean angular assumptions, so it inherits the same unsupported DAG
  geometry boundary unless guarded explicitly.
- `test/test_ExtensionBoundary.jl` proves that the extension is not yet loaded
  before `PhyloNetworks` is required and that it activates afterward, but it
  does not yet prove the stronger absence-case boundary where `LineagesMakie`
  imports cleanly in an environment that does not declare `PhyloNetworks`.
- `julia --project=test test/runtests.jl` must be rerun at remediation start
  and remediation end. The review-time invocation did not complete within the
  tool timebox, so this remediation file does not claim a fresh green baseline
  from that interrupted observation.
- `julia --project=docs docs/make.jl` remains a required remediation gate.

## Drift diagnosis

### Why the implementation drifted

- The implementation drift was not purely an implementer invention. The
  original tranche-1 tasking explicitly required DAG-safe compatibility
  wrappers while also keeping `src/Geometry.jl` and the plotting stack out of
  scope. That left one derivable boundary decision unstated: should tree-only
  geometry keep rejecting DAGs until Tranche 2, or should Tranche 1 expand into
  geometry-owner work? This remediation now resolves that decision explicitly.
- The original tranche-1 lock items correctly demanded that topology and
  wrappers accept DAGs, but they did not include a separate lock item proving
  that downstream tree-only geometry surfaces still reject unsupported DAGs
  honestly. That omission allowed a fresh implementation agent to satisfy the
  topology tasks while silently moving the failure deeper into geometry.
- The original extension-boundary lock item named the right goal, but the task
  verification did not force an isolated absence-case proof. That left room for
  a weaker "not yet loaded" test inside a project that still declared
  `PhyloNetworks`.

### What is now baked in

- Topology-owner success and geometry-owner support are explicitly separated.
- A shared-descendant DAG reaching `rectangular_layout`, `circular_layout`,
  `lineageplot!`, or `lineageplot` must fail directly and honestly until
  Tranche 2 lands.
- The known bad shape is no longer "cycle error on second encounter." It is
  "silent last-parent overwrite in a tree-only geometry owner." Verification
  must fail that exact shape.
- Optional-extension proof must now cover both absence and activation, not just
  activation.

## Primary-goal lock

### Lock 1: unsupported DAG geometry must fail honestly at the geometry owner boundary

- The work is not complete if a shared-descendant DAG can still reach
  `rectangular_layout` or `circular_layout` and be assigned coordinates by a
  one-parent overwrite path or any other tree-only fallback.
- Direct red-state repro: under commit `9815b12`, a basenode whose two
  children both point to the same descendant normalizes successfully, but
  `rectangular_layout(...; lineageunits = :edgeweights)` assigns the shared
  node from the later parent path and returns geometry instead of rejecting the
  unsupported contract.
- Closing tasks: 1 and 2.
- Verification artifact: direct geometry regressions must prove that the same
  shared-descendant DAG still succeeds through `normalize_topology`, `leaves`,
  and `preorder`, but `rectangular_layout` and `circular_layout` both raise the
  tranche-1 DAG-unsupported diagnostic before returning any geometry.

### Lock 2: public plotting surfaces must not hide the same geometry anti-fix

- The work is not complete if `lineageplot!` or `lineageplot` still accept the
  same shared-descendant DAG and merely surface the geometry anti-fix at render
  time or through silently wrong positions.
- Direct red-state repro: `Layers` and `LineageAxis` currently route through
  `rectangular_layout` or `circular_layout`, so a geometry owner that silently
  accepts unsupported DAG input also makes the public plotting surfaces
  dishonest.
- Closing tasks: 1 and 2.
- Verification artifact: integration regressions must prove that both
  mutating and non-mutating public plotting entrypoints surface the same direct
  rejection for the shared-descendant DAG while a representative rooted-tree
  plot still succeeds.

### Lock 3: the topology-owner repair must remain intact

- The work is not complete if this remediation backs out DAG-safe
  normalization, reintroduces "second encounter means cycle" in the exported
  wrappers, or turns the geometry honesty repair into a rollback of the
  topology owner.
- Direct red-state repro: the pre-remediation implementation before
  `src/Topology.jl` treated any second node encounter as a cycle.
- Closing tasks: 1 and 2.
- Verification artifact: preserved topology and accessor regressions must prove
  that shared-descendant DAG normalization, `leaves`, and `preorder` still
  succeed after the geometry guard lands.

### Lock 4: the optional extension boundary must be proven as optional, not just unloaded

- The work is not complete if `using LineagesMakie` still lacks a direct proof
  of succeeding in an environment where `PhyloNetworks` is not declared.
- Direct red-state repro: the current extension test checks only that
  `Base.get_extension(LineagesMakie, :PhyloNetworksExt) === nothing` before
  `PhyloNetworks` is required inside a test environment that already depends on
  `PhyloNetworks`.
- Closing tasks: 3.
- Verification artifact: an isolated Julia subprocess or temporary project
  test must prove that `using LineagesMakie` succeeds without `PhyloNetworks`
  present, while the existing activation path still proves that the extension
  loads once `PhyloNetworks` is made available.

### Lock 5: rooted-tree behavior must remain green while the honesty boundary is restored

- The work is not complete if the DAG guard starts rejecting rooted trees or
  regresses representative tree layout or plotting behavior.
- Direct red-state repro equivalent: the remediation touches owner boundaries
  that sit on the main tree plotting path, so an over-broad guard could break
  the currently working rooted-tree contract.
- Closing tasks: 1 and 2.
- Verification artifact: existing representative rooted-tree geometry and
  integration tests must remain green, and at least one explicit tree
  non-regression should sit alongside the new DAG rejection tests.

## Handoff packet

- Active authorities:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the four design
  documents, the parent PRD, the tranche file, the original tranche-1 tasking,
  and this remediation file.
- Parent documents:
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`,
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`,
  and
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/03_tranche-1--tasking.md`.
- Settled decisions and non-negotiables:
  core DAG ownership stays in `src/Topology.jl`; rooted trees remain the
  single-parent special case; `leaves` and `preorder` stay exported as
  compatibility wrappers; Tranche 1 now explicitly rejects unsupported DAG
  geometry at the geometry owner boundary; `PhyloNetworks.jl` stays optional;
  no Tier 2 geometry implementation or Tier 3 rendering work is allowed here.
- Authorization boundary:
  deep internal redesign remains authorized only within the limited remediation
  surfaces named below. Public breaks and tranche-expansion design changes
  remain out of bounds.
- Current-state diagnosis:
  topology normalization and wrapper repair landed, but tree-only geometry now
  silently accepts unsupported DAGs, and the extension absence-case proof is
  too weak.
- Primary-goal lock:
  Locks 1 through 5 above.
- Direct red-state repros:
  shared-descendant DAG reaches `rectangular_layout` and gets a last-parent
  overwrite; extension test proves only unloaded state, not absent dependency.
- Owner and invariant under repair:
  the boundary between the topology owner and still-tree-native geometry
  owner, plus the honesty of the optional package-extension proof.
- Exact files or surfaces in scope:
  `src/Topology.jl`, `src/Geometry.jl`, `test/test_Accessors.jl`,
  `test/test_Geometry.jl`, `test/test_Integration.jl`,
  `test/test_ExtensionBoundary.jl`, and `test/runtests.jl` only if the test
  include set must change.
- Exact files or surfaces out of scope:
  `src/Layers.jl`, `src/LineageAxis.jl`, `src/CoordinateTransform.jl`,
  `README.md`, `ROADMAP.md`, `docs/src/index.md`, examples, Tier 2 geometry
  algorithms, Tier 3 network rendering surfaces, `ext/PhyloNetworksExt.jl`,
  and dependency-policy changes unless a listed verification artifact proves
  the metadata itself is wrong.
- Required upstream primary sources:
  the `PhyloNetworks.jl` and Makie files listed in the governance section.
- Green-state gates:
  `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl`.
- Stop conditions:
  any required public break, any attempt to turn this into actual DAG geometry
  implementation, any attempt to move topology or geometry ownership into the
  extension, any attempt to weaken the preserved topology-owner DAG tests, or
  any material conflict between this remediation file and the live codebase.

## Required revalidation before implementation

- Re-read `src/Topology.jl`, `src/Geometry.jl`, `test/test_Accessors.jl`,
  `test/test_Geometry.jl`, `test/test_Integration.jl`, and
  `test/test_ExtensionBoundary.jl`.
- Re-run the shared-descendant DAG repro against current `HEAD` before editing.
  Confirm that topology normalization succeeds and that the current geometry
  owner still returns silently wrong layout instead of rejecting.
- Re-run `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl` at remediation start if no fresher green
  evidence exists in the working session.
- Stop and escalate if the live code already contains a partial geometry guard
  or a stronger extension-boundary proof that conflicts with this remediation
  framing.

## Tasks

1. **Title**: Reinstate an honest tree-only geometry boundary on top of the topology owner
   **Type**: `WRITE`
   **Output**: `rectangular_layout` and `circular_layout` normalize topology
   once, preserve rooted-tree success paths, and raise a direct
   DAG-unsupported `ArgumentError` for shared-parent DAG input before any
   coordinate assignment or edge-shape construction.
   **Depends on**: `none`
   **Positive contract**:
   topology normalization and the exported `leaves` / `preorder` wrappers still
   accept shared-descendant DAGs, while the geometry owner refuses to produce
   layout for any normalized topology with a node that has more than one parent
   edge.
   **Negative contract**:
   do not back out `src/Topology.jl`; do not reintroduce the old visited-set
   cycle check in `Accessors`; do not silently choose one parent path; do not
   start implementing DAG process-coordinate or transverse-coordinate policy;
   do not move the boundary into `ext/`.
   **Files**:
   `src/Topology.jl`, `src/Geometry.jl`
   **Out of scope**:
   `src/Layers.jl`, `src/LineageAxis.jl`, `src/CoordinateTransform.jl`,
   docs-site files, examples, `Project.toml`, and `ext/`
   **Verification**:
   add a direct regression fixture with `root -> left -> shared` and
   `root -> right -> shared`, using asymmetric edge weights so the old bad
   implementation would place `shared` at the later-parent coordinate;
   prove that `normalize_topology`, `leaves`, and `preorder` still succeed, but
   `rectangular_layout(...; lineageunits = :edgeweights)`,
   `rectangular_layout(...; lineageunits = :nodelevels)`, and
   `circular_layout(...; lineageunits = :edgeweights)` all throw the same
   DAG-unsupported diagnostic before returning geometry; run
   `julia --project=test test/runtests.jl`; run
   `julia --project=docs docs/make.jl`.

2. **Title**: Prove the geometry boundary across all supported public entry surfaces
   **Type**: `TEST`
   **Output**: direct tests pin the split contract: topology and wrappers
   accept shared-descendant DAGs, geometry rejects them, and both mutating and
   non-mutating public plotting entrypoints surface the same honest rejection
   while representative rooted-tree calls remain green.
   **Depends on**: `1`
   **Positive contract**:
   at least one regression exists for each of
   `rectangular_layout`, `circular_layout`, `lineageplot!`, and `lineageplot`,
   plus at least one explicit rooted-tree non-regression that still succeeds in
   the same touched files.
   **Negative contract**:
   do not rely only on helper-level topology tests; do not verify only one
   public entry surface when the same semantic is available through several;
   do not weaken the current DAG-topology tests just to make the new geometry
   rejection pass; do not add render-time image-diff work for unsupported DAG
   layouts.
   **Files**:
   `test/test_Accessors.jl`, `test/test_Geometry.jl`, `test/test_Integration.jl`
   **Out of scope**:
   `test/test_Layers.jl`, docs-site content, examples, pixel-level DAG render
   assertions, and Tier 2 geometry feature tests
   **Verification**:
   the new tests must fail on commit `9815b12`; they must prove that the known
   bad implementation can no longer return geometry or a `LineagePlot` for the
   shared-descendant DAG, while the existing rooted-tree smoke paths still
   succeed; run `julia --project=test test/runtests.jl`; run
   `julia --project=docs docs/make.jl`.

3. **Title**: Upgrade the optional-extension proof from "not loaded" to "not required"
   **Type**: `TEST`
   **Output**: `test/test_ExtensionBoundary.jl` proves both halves of the
   optional-boundary contract: `using LineagesMakie` succeeds in an isolated
   temporary environment that does not declare `PhyloNetworks`, and the
   extension still activates only after `PhyloNetworks` is made available.
   **Depends on**: `none`
   **Positive contract**:
   the absence-case proof uses an isolated Julia subprocess or temporary
   project with only path-developed `LineagesMakie`; the activation-case proof
   continues to assert weakdep metadata and extension activation once
   `PhyloNetworks` is loaded.
   **Negative contract**:
   do not treat `Base.get_extension(...) === nothing` before import as the only
   absence proof; do not add `PhyloNetworks` to `[deps]`; do not use network
   access, registry resolution, or manual environment mutation outside the test
   process.
   **Files**:
   `test/test_ExtensionBoundary.jl`
   **Out of scope**:
   `Project.toml`, `ext/PhyloNetworksExt.jl`, docs, examples, and topology or
   geometry code
   **Verification**:
   the absence-case subprocess must fail under any implementation that truly
   requires `PhyloNetworks` to import `LineagesMakie`; the activation-case must
   fail if the extension no longer loads from the local upstream path source;
   run `julia --project=test test/runtests.jl`; run
   `julia --project=docs docs/make.jl`.

## Fresh-agent durability check

- A fresh implementation agent using only the PRD, tranche file, original
  tranche-1 tasking, this remediation file, and the codebase can now recover
  the missing boundary decision without reopening it.
- The negative target is explicit: do not silently accept unsupported DAG
  geometry, do not back out topology-owner DAG support, and do not weaken the
  extension absence-case proof.
- The known anti-fix shape is explicit: the old bad implementation returned
  geometry with last-parent overwrite semantics instead of rejecting.
- The optional-dependency proof standard is explicit: isolated absence case plus
  activation case.
- No further `REVIEW` task is currently identified. The implementer should stop
  only if the live code forces a tranche-expansion decision not authorized
  here.
