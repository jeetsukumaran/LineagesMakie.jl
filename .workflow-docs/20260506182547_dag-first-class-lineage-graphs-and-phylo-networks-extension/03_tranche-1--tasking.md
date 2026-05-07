---
date-created: 2026-05-06T21:16:53-07:00
date-revised: 2026-05-06T21:16:53-07:00
status: approved
---

# Tasks for Tranche 1: topology owner and optional extension boundary

Tasking identifier: `20260506T211653--tranche-1-topology-tasking`

Parent tranche: Tranche 1
Parent PRD: `01_prd.md`

## Settled user decisions and environment baseline

- DAG lineage graphs are first-class in the core owner model. Rooted trees
  remain the single-parent special case inside that same owner path.
- `src/Topology.jl` is the settled internal owner file for Tranche 1. Do not
  split topology ownership across several new core files in this tranche.
- `LineagesMakie.leaves` and `LineagesMakie.preorder` remain exported
  compatibility wrappers unless explicit user approval or a named `REVIEW`
  gate reopens that public contract.
- `PhyloNetworks.jl` must remain an optional package extension. Do not add it
  to `[deps]` or make it the real owner of DAG semantics.
- No repo-owned public API removal, rename, export change, or signature break
  is authorized in this tranche.
- No Tier 3 work is authorized in this tranche. Do not implement hybrid
  markers, major or minor reticulation styling, gamma labels, or network view
  modes here.
- README, roadmap, docs-site, and public example repositioning belong to the
  later documentation and contract-cleanup tranche unless a minimal local touch
  is strictly required to keep the repository green or to avoid an outright
  false statement in a touched docstring.
- Use the repository root project as the owning environment for core code.
- Use `test/Project.toml` and `docs/Project.toml` as the canonical test and
  docs environments.
- Do not rely on network access or registry downloads. Use the approved local
  upstream checkout root
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/`.
- No `REVIEW` task is required at the current diagnosis. Stop for review only
  if a public break becomes necessary, if the weak-dependency boundary cannot
  be implemented honestly, or if the implementing agent concludes that a
  derivable design decision in this file is no longer compatible with the live
  codebase.

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
- `design/design.md`
- `design/target-reference-capacities.md`
- `design/requirements-landscape-gap.md`
- `design/api-landscape.md`

The bundled style baseline under
`/home/jeetsukumaran/site/service/env/start/workhost/resources/packages/shared/workhost-resources/configure/coding-agent-skills/development-policies/references/`
was also read during this tasking run and is byte-identical to the repo-local
`STYLE*.md` files above. Bundled `CONTRIBUTING.md` was not present there, so
repo-local `CONTRIBUTING.md` remains authoritative for contribution guidance.

Workflow authorities used to produce this tasking were `development-policies`
and `devflow-architecture-03--tranche-to-tasks`. Downstream implementation
must preserve their pass-forward mandates, especially active-authority
restatement, exact upstream-source naming, exact authorization boundaries,
controlled vocabulary, primary-goal lock items, direct red-state repros, and
failure-oriented verification.

Upstream primary sources that must be read line by line for this tranche are:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/types.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/auxiliary.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/recursion_routines.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/compareNetworks.jl`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`

These sources constrain the tranche as follows:

- `PhyloNetworks.jl` confirms that node identity and edge identity are
  first-class upstream concepts, that hybrid nodes may have multiple parent
  edges, and that major and minor parent semantics belong above a DAG-capable
  core rather than inside a tree-only traversal owner.
- `PhyloNetworks.jl` traversal utilities distinguish root, tree-node, and
  hybrid-node update paths using topological node order and parent vectors,
  which reinforces the tranche requirement that a second node encounter is not
  itself a cycle.
- Makie package-extension guidance confirms that extension modules add methods
  and package-integration glue; they do not justify moving core traversal or
  normalization semantics into the extension.

Controlled vocabulary from `STYLE-vocabulary.md` is mandatory. Use
`lineage graph`, `basenode`, `node`, `edge`, `leaf`, `compatibility wrapper`,
`ownership boundary`, `package extension`, `lock item`, `red-state repro`,
`verification artifact`, and `foundational tranche` consistently. Do not
describe `PhyloNetworks.jl` work as an `adapter` except when referring narrowly
to a source-side shim layered over an already-correct core.

Read-only git and shell commands may be used freely. Mutating git operations
such as commit, merge, push, rebase, reset, and branch creation remain the
human project owner's responsibility unless the user explicitly instructs
otherwise.

## Revalidated current state

- `src/Accessors.jl` still owns traversal through `leaves`, `preorder`, and
  `_check_cycle!`, and it still treats any second node encounter as a cycle.
- No `src/Topology.jl` file exists yet.
- `Project.toml` has no `[weakdeps]` or `[extensions]` sections, and no `ext/`
  directory exists.
- `README.md`, `ROADMAP.md`, and `docs/src/index.md` still contain public
  drift, but that documentation repair remains out of scope for this tranche
  except for minimal touched-surface honesty.
- `julia --project=docs docs/make.jl` was revalidated green during this tasking
  run, with the existing `Documenter` warnings about `index.md` size and
  deployment auto-detection.
- `julia --project=test test/runtests.jl` must be rerun at tranche start and
  tranche end. The planning-time invocation did not emit a final completion
  signal within the tool timebox, so this tasking file does not claim a fresh
  start-state test proof on the basis of that interrupted observation.

## Primary-goal lock

### Lock 1: DAG topology is first-class in the core

- The work is not complete if a valid shared-descendant DAG still fails during
  normalization or if one of the parent incidences is silently dropped.
- Direct red-state repro: under the current `visited::Set` traversal owner, a
  basenode whose two children both point to the same descendant throws as if it
  were cyclic.
- Closing tasks: 1 and 2.
- Verification artifact: direct topology-owner tests must prove that a
  shared-descendant DAG normalizes successfully, produces one normalized node
  for the shared descendant, and retains both inbound edges. A fake fix that
  merely suppresses the second encounter must fail this proof because it loses
  one parent incidence or one edge identity.

### Lock 2: true directed cycles still fail directly

- The work is not complete if shared ancestry and actual directed cycles remain
  conflated or if a true directed cycle is silently truncated.
- Direct red-state repro: the current traversal cannot distinguish
  shared ancestry from a true cycle because both are implemented as “node seen
  twice.”
- Closing tasks: 1 and 2.
- Verification artifact: topology-owner tests must prove that a true directed
  cycle fails directly with a cycle diagnostic while the shared-descendant DAG
  above succeeds. A fake fix that simply skips repeated encounters must fail
  because the cycle case would no longer diagnose the invalid graph honestly.

### Lock 3: exported traversal helpers survive only as compatibility wrappers

- The work is not complete if `LineagesMakie.leaves` or `LineagesMakie.preorder`
  remain the real topology owner, disappear without approval, or fork into a
  second tree-only implementation.
- Direct red-state repro: today the exported helpers are also the owner-level
  traversal and validity logic.
- Closing tasks: 2.
- Verification artifact: wrapper-level tests must prove that tree fixtures keep
  their current deterministic behavior while shared-descendant DAG fixtures now
  pass through topology-backed wrappers. A fake fix that reintroduces a second
  topology implementation behind the wrappers must fail because the wrapper and
  direct topology outputs would drift.

### Lock 4: the `PhyloNetworks.jl` boundary is optional and extension-owned

- The work is not complete if `PhyloNetworks.jl` becomes a hard dependency or
  if the extension starts owning DAG normalization semantics.
- Direct red-state repro: today there is no weak dependency, no extension
  boundary, and no `ext/` module at all.
- Closing tasks: 3.
- Verification artifact: configuration and test coverage must prove that
  `import LineagesMakie` succeeds before `PhyloNetworks` is loaded, that
  `Base.get_extension(LineagesMakie, :PhyloNetworksExt)` stays `nothing` until
  `PhyloNetworks` is imported, and that the extension then activates. A fake
  fix that adds `PhyloNetworks` to `[deps]` or places normalization ownership
  in `ext/` must fail this proof.

### Lock 5: Tier 2 and Tier 3 boundaries remain correct

- The work is not complete if Tranche 1 starts implementing hybrid rendering,
  view modes, gamma labels, or other Tier 3 network presentation features, or
  if any foundational DAG owner repair is deferred into the extension.
- Direct red-state repro: the package currently has no DAG-capable core owner
  and no extension boundary, so an implementer could still drift into “just add
  an adapter” work unless the tranche stays explicit.
- Closing tasks: 1 and 3.
- Verification artifact: the changed files must show the topology owner in
  `src/Topology.jl`, compatibility wrappers in `src/Accessors.jl`, and only
  weak-dependency wiring in `Project.toml` and `ext/PhyloNetworksExt.jl`. No
  Tier 3 rendering or projection controls may appear in this tranche’s changed
  surfaces.

## Handoff packet

- Active authorities:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the four design
  documents, the parent PRD, the tranche file, and this tasking file.
- Parent documents:
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`
  and
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/02_tranches.md`.
- Settled decisions and non-negotiables:
  core DAG ownership lives in `src/Topology.jl`; rooted trees remain the
  special case; `leaves` and `preorder` stay exported as compatibility wrappers
  unless explicitly reopened; `PhyloNetworks.jl` stays optional; no Tier 3
  rendering work is allowed here; no `REVIEW` task is currently required.
- Authorization boundary:
  deep internal redesign is authorized in `src/`, `test/`, and root or test
  package metadata. Public breaks require explicit approval and migration notes.
- Current-state diagnosis:
  traversal and cycle detection are still tree-native, no topology owner file
  exists, and no weak-dependency extension boundary exists.
- Primary-goal lock:
  Locks 1 through 5 above.
- Direct red-state repros:
  shared-descendant DAG throws as cycle; exported traversal helpers are still
  owner-level; package metadata has no extension boundary.
- Owner and invariant under repair:
  topology ownership and package-extension ownership; invariant that DAG support
  lives in the core and that the extension only adapts upstream objects into
  that core.
- Exact files or surfaces in scope:
  `src/Topology.jl`, `src/Accessors.jl`, `src/LineagesMakie.jl`, `Project.toml`,
  `Manifest.toml` if package resolution updates it, `ext/PhyloNetworksExt.jl`,
  `test/Project.toml`, `test/Manifest.toml` if package resolution updates it,
  `test/test_Topology.jl`, `test/test_Accessors.jl`, `test/test_ExtensionBoundary.jl`,
  and `test/runtests.jl`.
- Exact files or surfaces out of scope:
  `src/Geometry.jl`, `src/Layers.jl`, `src/LineageAxis.jl`,
  `src/CoordinateTransform.jl`, `README.md`, `ROADMAP.md`, `docs/src/index.md`,
  examples, and all Tier 3 network rendering surfaces unless a minimal touched
  docstring change is required to keep the repository green and honest.
- Required upstream primary sources:
  the `PhyloNetworks.jl` and Makie files listed in the governance section.
- Green-state gates:
  `julia --project=test test/runtests.jl` and `julia --project=docs docs/make.jl`.
- Stop conditions:
  any required public break; any attempt to remove or stop exporting `leaves`
  or `preorder`; any attempt to move normalization ownership into
  `ext/PhyloNetworksExt.jl`; any attempt to start Tier 3 rendering work; any
  material conflict between this tasking file and the live codebase.

## Required revalidation before implementation

- Read the parent PRD, the tranche file, and this tasking file in full.
- Read `src/Accessors.jl`, `src/LineagesMakie.jl`, `Project.toml`,
  `test/test_Accessors.jl`, `test/test_Integration.jl`, `README.md`,
  `ROADMAP.md`, and `docs/src/index.md` in full.
- Re-read the `PhyloNetworks.jl` and Makie upstream primary sources named in
  the governance section before changing core topology or extension-boundary
  code.
- Re-run `julia --project=test test/runtests.jl` at tranche start. If the live
  baseline is not green, stop and raise that before changing code.
- Re-run `julia --project=docs docs/make.jl` at tranche start if any docs
  baseline question arises.
- Re-check the user-authorized disruption boundary before making deep changes.
- If any public break seems necessary, stop for explicit review instead of
  proceeding.

## Tranche execution rule

This tranche may redesign, replace, or deeply refactor internal topology and
extension-boundary ownership where needed, but it must begin and end in a
green, policy-compliant state. It must establish one internal topology owner,
route the exported traversal helpers through that owner as compatibility
wrappers, and create the optional package-extension boundary without moving DAG
semantics into the extension.

When Tranche 1 is complete:

- `src/Accessors.jl` no longer owns graph validity or cycle detection
- one normalized topology record exists in `src/Topology.jl`
- a second node encounter is treated as shared ancestry or a true cycle based
  on topology-owner state rather than a global visited-set shortcut
- `LineagesMakie.leaves` and `LineagesMakie.preorder` survive only as
  topology-backed public compatibility wrappers
- `Project.toml` and `ext/PhyloNetworksExt.jl` define an honest optional
  extension boundary

This tranche does not authorize geometry redesign, annotation-owner split,
public docs repositioning, or any network-specific rendering feature.

## Non-negotiable execution rules

- Do not move the real topology owner into `src/Accessors.jl`, `ext/`, or any
  future `PhyloNetworks`-specific helper.
- Do not keep `_check_cycle!` or an equivalent “seen twice means cycle” helper
  as the core validity owner.
- Do not solve DAG support by skipping repeated nodes while silently losing a
  parent incidence or edge identity.
- Do not create separate tree-only and DAG-only core topology implementations.
- Do not remove, rename, or stop exporting `LineagesMakie.leaves` or
  `LineagesMakie.preorder`.
- Do not add `PhyloNetworks` to `[deps]`.
- Do not let the extension own traversal, normalization, or cycle diagnostics.
- Do not implement hybrid markers, major or minor reticulation styling, gamma
  labels, or network view modes.
- Do not rewrite README, roadmap, docs-site pages, or examples as if the later
  documentation tranche had already landed.
- Do not weaken rooted-tree behavior merely to make new DAG tests pass.

## Concrete anti-patterns or removal targets

- `_check_cycle!` in `src/Accessors.jl` as the owner of graph validity
- the notion that a second node encounter is itself a directed cycle
- direct recursive child-walking as the owner of stable node identity or edge
  identity
- any surviving owner path that reconstructs parent incidence from repeated raw
  traversal instead of from normalized topology
- any surviving owner path in which `leaves` or `preorder` define graph
  validity rather than consume already-normalized topology
- the absence of `[weakdeps]`, `[extensions]`, and `ext/` as an implicit
  packaging policy
- any new code that places Tier 2 normalization inside `ext/PhyloNetworksExt.jl`

## Failure-oriented verification

- Add a direct topology-owner regression for a shared-descendant DAG fixture
  that would fail under the old visited-set design.
- Add a direct topology-owner regression for a true directed cycle fixture that
  would fail under a fake fix that merely suppresses repeated-node errors.
- Add at least one negative topology proof that fails a fake fix which skips
  the second encounter instead of retaining the second parent incidence. This
  proof must assert retained parent count or retained edge count on the shared
  descendant.
- Add wrapper-level tests proving `LineagesMakie.leaves` and
  `LineagesMakie.preorder` are now topology-backed compatibility wrappers and
  that rooted-tree order remains deterministic.
- Add extension-boundary tests proving that `LineagesMakie` imports before
  `PhyloNetworks` is loaded, that the extension is inactive before
  `PhyloNetworks` import, and that it activates after import.
- Use config or metadata assertions only as supplementary proof. They do not
  replace behavior-level DAG and extension-boundary tests.
- Run `julia --project=test test/runtests.jl`.
- Run `julia --project=docs docs/make.jl`.

## Tasks

### 1. Create the internal topology owner

**Type**: WRITE
**Output**: A non-exported topology owner in `src/Topology.jl` normalizes
`basenode + children` input into a package-owned `NormalizedTopology` record
with stable node identity, stable edge identity, parent and child incidence,
deterministic topological node order, deterministic sink order, and direct
cycle diagnostics.
**Depends on**: none
**Positive contract**: Valid shared-descendant DAGs normalize successfully and
retain all parent incidences. Rooted-tree inputs normalize through the same
owner path. The new owner becomes the single source of truth for graph
validity.
**Negative contract**: No Geometry or Layers redesign is allowed here. No
topology ownership may be implemented in `ext/`. The old “second encounter
means cycle” rule must not survive inside the new owner under another helper
name.
**Files**: `src/Topology.jl`, `src/LineagesMakie.jl`, `test/test_Topology.jl`,
`test/runtests.jl`
**Out of scope**: `src/Accessors.jl`, `Project.toml`, `ext/`, `README.md`,
`ROADMAP.md`, `docs/src/index.md`, all Tier 3 rendering surfaces
**Verification**: Add one shared-descendant DAG fixture and one true directed
cycle fixture to `test/test_Topology.jl`. Assert that the DAG normalizes once
per reachable node, retains both inbound parent incidences on the shared
descendant, and exposes deterministic topological and sink orders. Assert that
the true cycle raises a direct cycle diagnostic. Run
`julia --project=test test/runtests.jl` and `julia --project=docs docs/make.jl`.

Introduce a new non-exported `Topology` submodule in `src/Topology.jl` and
include it from `src/LineagesMakie.jl` without exporting it. Settle the
internal owner interface as `Topology.normalize_topology(accessor, basenode)`,
returning a package-owned `NormalizedTopology` record. The record must hold one
normalized node for each reachable source node value, one normalized edge for
each directed parent or child relationship discovered during traversal, parent
and child incidence for every normalized node, one deterministic topological
node order, one deterministic sink order, and enough stored state to diagnose a
true directed cycle directly. This task is complete only when the topology
owner exists, direct topology tests are green, and no other core file still
needs to invent graph validity independently.

### 2. Route exported traversal helpers through normalized topology

**Type**: WRITE
**Output**: `LineagesMakie.leaves` becomes a thin wrapper over normalized sink
order and `LineagesMakie.preorder` becomes a thin wrapper over normalized
topological order, while preserving current rooted-tree behavior on existing
fixtures.
**Depends on**: 1
**Positive contract**: The wrappers stay exported, accept valid DAGs, preserve
deterministic rooted-tree behavior, and stop owning graph validity or cycle
diagnostics.
**Negative contract**: Do not remove `leaves` or `preorder`. Do not keep
`_check_cycle!` or a second hidden topology implementation in `src/Accessors.jl`.
Do not pull `src/Geometry.jl` into this tranche.
**Files**: `src/Accessors.jl`, `test/test_Accessors.jl`
**Out of scope**: `src/Geometry.jl`, `Project.toml`, `ext/`, `README.md`,
`ROADMAP.md`, `docs/src/index.md`, `test/test_Integration.jl`
**Verification**: Add wrapper-level DAG regressions proving that
`leaves(accessor, basenode)` returns each normalized sink once and that
`preorder(accessor, basenode)` returns each reachable node once in the
topology-owner order. Preserve existing rooted-tree order expectations. Run
`julia --project=test test/runtests.jl` and `julia --project=docs docs/make.jl`.

Refactor `src/Accessors.jl` so `leaves` and `preorder` call
`Topology.normalize_topology(accessor, basenode)` and return the corresponding
normalized sink or node order projected back through the normalized node record.
Delete `_check_cycle!` and the direct recursive ownership of graph validity.
Keep `lineagegraph_accessor`, `abstracttrees_accessor`, and `is_leaf` intact
except for any minimal docstring touch needed to keep touched comments honest.
This task is complete only when the exported traversal helpers are visibly thin
compatibility wrappers and no second topology owner survives in `src/Accessors.jl`.

### 3. Wire the optional `PhyloNetworks.jl` extension boundary

**Type**: CONFIG
**Output**: The root project declares `PhyloNetworks` as a weak dependency,
declares `PhyloNetworksExt` in `[extensions]`, ships `ext/PhyloNetworksExt.jl`,
and the test project proves extension activation from the approved local
`PhyloNetworks.jl` checkout without turning `PhyloNetworks.jl` into a hard
dependency.
**Depends on**: 1, 2
**Positive contract**: `import LineagesMakie` succeeds before `PhyloNetworks`
is loaded. `Base.get_extension(LineagesMakie, :PhyloNetworksExt)` is `nothing`
before `PhyloNetworks` import and non-`nothing` after it. The extension owns
only activation wiring and future source-adaptation hooks, not DAG semantics.
**Negative contract**: Do not add `PhyloNetworks` to `[deps]`. Do not
implement network rendering, network view modes, or source-specific topology
ownership in `ext/PhyloNetworksExt.jl`. Do not require network access or
registry resolution shortcuts.
**Files**: `Project.toml`, `Manifest.toml` if package resolution updates it,
`ext/PhyloNetworksExt.jl`, `test/Project.toml`, `test/Manifest.toml` if
package resolution updates it, `test/test_ExtensionBoundary.jl`,
`test/runtests.jl`
**Out of scope**: `src/Geometry.jl`, `src/Layers.jl`, public network examples,
`README.md`, `ROADMAP.md`, `docs/src/index.md`, and docs-site repositioning
**Verification**: Add an extension-boundary test that imports `LineagesMakie`,
asserts `Base.get_extension(LineagesMakie, :PhyloNetworksExt) === nothing`,
then imports `PhyloNetworks` from the local upstream checkout and asserts that
the extension activates. Add a supplementary metadata assertion that root
`Project.toml` keeps `PhyloNetworks` out of `[deps]` and in the weak-extension
boundary instead. Run `julia --project=test test/runtests.jl` and
`julia --project=docs docs/make.jl`.

Update root `Project.toml` to declare the weak dependency and extension mapping.
Create `ext/PhyloNetworksExt.jl` as the sole extension module and keep it
minimal: import `LineagesMakie`, import `PhyloNetworks`, and define only the
non-exported activation scaffolding that later tranches will build on. Add
`PhyloNetworks` to the test environment using the approved local upstream
checkout, not via network resolution. This task is complete only when the weak
boundary is honest, the extension activates under test, and no DAG semantics
have been moved into the extension.
