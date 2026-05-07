# Tranches for DAG-first-class lineage graphs and `PhyloNetworks.jl` extension

Parent PRD:
`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`

## Governance confirmation

- Bundled development-policies references reviewed for this tranche design:
  `STYLE-agent-handoffs.md`, `STYLE-architecture.md`, `STYLE-docs.md`,
  `STYLE-git.md`, `STYLE-julia.md`, `STYLE-makie.md`,
  `STYLE-upstream-contracts.md`, `STYLE-verification.md`,
  `STYLE-vocabulary.md`, `STYLE-workflow-docs.md`, and
  `STYLE-writing.md`.
- Expected bundled file not found in the development-policies depot:
  `CONTRIBUTING.md`. Repo-local `CONTRIBUTING.md` is present and is in force.
- Repo-local authorities used for this tranche design:
  `AGENTS.md`, `CONTRIBUTING.md`, `STYLE-agent-handoffs.md`,
  `STYLE-architecture.md`, `STYLE-docs.md`, `STYLE-git.md`,
  `STYLE-julia.md`, `STYLE-makie.md`, `STYLE-upstream-contracts.md`,
  `STYLE-verification.md`, `STYLE-vocabulary.md`,
  `STYLE-workflow-docs.md`, and `STYLE-writing.md`.
- Project design authorities used for this tranche design:
  `design/design.md`, `design/target-reference-capacities.md`,
  `design/requirements-landscape-gap.md`, and `design/api-landscape.md`.
- Active authorities for this run:
  the bundled development-policies baseline listed above, the repo-local
  governance stack, the four design documents listed above, the parent PRD,
  and this tranche file once written.
- Upstream source location revalidation:
  the parent PRD correctly requires local Makie-family and `PhyloNetworks.jl`
  primary sources, but the actual checkout location in this environment is
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation`
  rather than a `codebases-and-documentation` directory under this repository.
  Downstream tasking must use that real path unless the workspace is
  reorganized.

## Standing constraints

- Every tranche begins from a green, policy-compliant state.
- Every tranche ends in a green, policy-compliant state.
- DAG lineage graphs are first-class in the core owner model.
- Rooted trees remain the single-parent special case within the same owner
  path.
- No tranche may preserve tree-only core owners and paper over the gap with a
  `PhyloNetworks.jl`-specific shadow implementation.
- No tranche may describe Tier 3 as a thin adapter project.
- Any externally visible breaking change requires explicit user approval and a
  migration note in the same tranche.
- Every tranche must pass forward governance, vocabulary, upstream-reading,
  authorization-boundary, and verification obligations.
- The parent PRD defines numbered lock items rather than numbered user stories.
  This tranche file therefore maps tranche coverage to PRD lock items and notes
  that fact explicitly in each tranche.

## Tranche summary

1. `Topology owner and optional extension boundary`
   Type: `AFK`
   Blocked by: `None`
   PRD lock coverage: `1`, `3`, `4`, `6`
2. `DAG-safe geometry and coordinate policy`
   Type: `AFK`
   Blocked by: `Tranche 1`
   PRD lock coverage: `1`, `2`, `4`, `6`
3. `Annotation owner split and contract cleanup`
   Type: `AFK`
   Blocked by: `Tranche 1`, `Tranche 2`
   PRD lock coverage: `2`, `5`, `6`
4. `PhyloNetworks.jl` extension and network rendering primitives
   Type: `AFK`
   Blocked by: `Tranche 1`, `Tranche 2`, `Tranche 3`
   PRD lock coverage: `2`, `3`, `6`
5. `Network view modes, display policy completion, and extension hardening`
   Type: `HITL`
   Blocked by: `Tranche 4`
   PRD lock coverage: `2`, `4`, `5`, `6`

## Tranche 1: topology owner and optional extension boundary

**Type**: AFK
**Blocked by**: None — can start immediately

### Parent PRD

`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`

### Governance and required reading

- Mandated line-by-line reading of `AGENTS.md`, `CONTRIBUTING.md`,
  `STYLE-agent-handoffs.md`, `STYLE-architecture.md`, `STYLE-docs.md`,
  `STYLE-git.md`, `STYLE-julia.md`, `STYLE-makie.md`,
  `STYLE-upstream-contracts.md`, `STYLE-verification.md`,
  `STYLE-vocabulary.md`, `STYLE-workflow-docs.md`, and
  `STYLE-writing.md`.
- Mandated line-by-line reading of the parent PRD and this tranche file once
  it exists.
- Mandated line-by-line reading of `design/design.md`,
  `design/target-reference-capacities.md`,
  `design/requirements-landscape-gap.md`, and `design/api-landscape.md`.
- Mandated line-by-line reading of the current owner surfaces
  `src/Accessors.jl`, `src/LineagesMakie.jl`, `Project.toml`,
  `test/test_Accessors.jl`, `test/test_Integration.jl`, `README.md`,
  `ROADMAP.md`, and `docs/src/index.md`.
- Mandated reading of upstream primary sources required by this tranche:
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/types.jl`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/auxiliary.jl`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/recursion_routines.jl`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`.

### Primary-goal lock

- Owns lock item 1 at the topology-owner level.
- Owns the Tier 2 portion of lock item 3 by establishing the optional package
  extension boundary before source-specific integration exists.
- Owns the tranche-ordering proof for lock item 4 by making Tier 2 start with
  foundational owner repair rather than a feature patch.
- Preserves lock item 6 by keeping rooted-tree traversal on the same owner path
  as DAG traversal.
- Tranche-specific non-completion condition:
  the work is not complete if raw recursive child walking remains the real
  owner of node identity, edge identity, cycle diagnostics, or extension
  activation boundaries.

### What to build

Build the foundational owner repair for lineage-graph normalization and the
optional package-extension boundary.

This tranche is foundational. It establishes an explicit internal topology
owner, preferably a new `Topology.jl` module, that normalizes the reachable
lineage graph from `basenode` into a package-owned DAG model with stable node
identity, stable edge identity, parent and child incidence, cycle detection,
topological order, and projection metadata.

It also formalizes the optional extension boundary in `Project.toml` and
`ext/` so that later `PhyloNetworks.jl` support plugs into the core instead of
becoming the core.

When this tranche is complete, repeated node encounter must be interpreted as
either valid shared ancestry or an actual directed cycle based on the topology
owner's state, not based on a global visited-set shortcut. Rooted-tree callers
must still use the same public access pattern where possible, but their
compatibility path may be reduced to a thin wrapper over the normalized owner.

### Legacy artifacts to retire or demote

- Retire `Accessors.leaves` and `Accessors.preorder` as owner-level traversal
  authorities; they may survive only as topology-backed wrappers or
  compatibility helpers.
- Retire `_check_cycle!` in `src/Accessors.jl` as the owner of graph validity.
- Retire the notion that a second node encounter is itself a cycle.
- Demote direct recursive child walking on raw source objects to an input-side
  normalization concern rather than a geometry or layer concern.
- Retire the absence of `[weakdeps]`, `[extensions]`, and `ext/` as an implicit
  packaging policy.

### Forbidden regressions

- Accepting DAGs merely by skipping repeated nodes while still losing one or
  more parent incidences.
- Leaving stable edge identity implicit as `(parent, child)` pairs reconstructed
  ad hoc from raw source traversal.
- Implementing topology normalization only inside `ext/PhyloNetworksExt.jl`.
- Creating separate tree-only and DAG-only core owners that can drift apart.
- Introducing a hard dependency on `PhyloNetworks.jl`.

### Environment and dependency baseline

- Use the repository root project as the owning environment for core code.
- Preserve `PhyloNetworks.jl` as an optional dependency via `[weakdeps]` and
  `[extensions]`; do not convert it into `[deps]`.
- Treat `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation`
  as the authoritative local upstream checkout root in this environment.
- Do not rely on network access, registry downloads, or undocumented
  dependency-resolution shortcuts to satisfy this tranche.
- Canonical green gates for this tranche are
  `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl`.

### Handoff packet

- **Active authorities**:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the bundled
  development-policies baseline, `design/design.md`,
  `design/target-reference-capacities.md`,
  `design/requirements-landscape-gap.md`, `design/api-landscape.md`, the parent
  PRD, and this tranche file.
- **Parent documents**:
  `.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`.
- **Settled decisions and non-negotiables**:
  DAG is first-class in the core, rooted trees are the single-parent special
  case, the extension boundary is optional, and no source-specific shadow owner
  is allowed.
- **Authorization boundary**:
  deep internal redesign is authorized in `src/`, `test/`, docs, examples, and
  `Project.toml`; public breaks require explicit user approval and migration
  notes.
- **Current-state diagnosis**:
  `src/Accessors.jl` treats repeated node encounter as a cycle, no explicit
  topology owner exists, and no optional extension scaffolding exists.
- **Primary-goal lock**:
  lock items 1, 3, 4, and 6 from the parent PRD.
- **Direct red-state repros**:
  a shared-descendant DAG throws `ArgumentError` during traversal; the package
  has no `ext/` or weak-dependency boundary.
- **Owner and invariant under repair**:
  topology ownership and package-extension ownership; invariant that DAG support
  lives in the core and that extension code only adapts upstream objects into
  that core.
- **Exact files or surfaces in scope**:
  `src/Accessors.jl`, new topology-owner files such as `src/Topology.jl`,
  `src/LineagesMakie.jl`, `Project.toml`, `ext/`, relevant tests, and any
  directly affected docs or examples needed to keep the contract honest.
- **Exact files or surfaces out of scope**:
  Tier 3 network view modes, network-specific edge styling, gamma label
  presentation, and unrelated ecosystem packages.
- **Required upstream primary sources**:
  the `PhyloNetworks.jl` and Makie files named above for this tranche.
- **Green-state gates**:
  `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, and DAG-versus-cycle regression tests.
- **Stop conditions**:
  any required public break, any discovered upstream contract conflict about the
  optional extension boundary, or any attempt to put normalization ownership
  into the extension instead of the core.

### How to verify

- **Manual**:
  build a small shared-descendant DAG fixture and confirm normalization accepts
  it while a true directed cycle still fails directly;
  inspect the normalized topology record and confirm it exposes stable node and
  edge identity without requiring later modules to reconstruct either;
  inspect `Project.toml` and `ext/` and confirm the package still loads without
  `PhyloNetworks.jl`.
- **Automated**:
  add topology-owner tests proving shared-ancestry acceptance and true-cycle
  rejection;
  add package-loading and extension-boundary tests that fail if
  `PhyloNetworks.jl` becomes a hard dependency;
  run `julia --project=test test/runtests.jl`;
  run `julia --project=docs docs/make.jl`.

Include at least one negative regression that fails the old visited-set design
and at least one negative regression that fails a fake fix which merely skips
the second encounter instead of recording the second parent incidence.

### Acceptance criteria

- [ ] Given a valid DAG with shared ancestry, when the topology owner
      normalizes it, then normalization succeeds and records stable node and
      edge identities without inventing a source-specific path.
- [ ] Given an actual directed cycle, when normalization is attempted, then the
      owner raises a direct cycle diagnostic rather than silently truncating or
      looping.
- [ ] Given the old traversal helpers, when this tranche is complete, then they
      are removed, reduced to thin wrappers, or otherwise prevented from
      surviving as a second topology implementation.
- [ ] Given a fake fix that merely suppresses repeated-node errors or moves
      normalization into the extension, when verification is run, then the
      tranche fails rather than reporting a fake green.

### User stories addressed

- Parent PRD note: there is no numbered user-story section.
- This tranche addresses lock item 1: DAG is first-class in the core.
- This tranche addresses lock item 3: `PhyloNetworks.jl` support is an optional
  package extension.
- This tranche addresses lock item 4: Tier 2 and Tier 3 boundaries are correct.
- This tranche preserves lock item 6: tree behavior survives as the special-case
  path.

## Tranche 2: DAG-safe geometry and coordinate policy

**Type**: AFK
**Blocked by**: Tranche 1

### Parent PRD

`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`

### Governance and required reading

- Mandated line-by-line reading of `AGENTS.md`, `CONTRIBUTING.md`,
  `STYLE-agent-handoffs.md`, `STYLE-architecture.md`, `STYLE-docs.md`,
  `STYLE-git.md`, `STYLE-julia.md`, `STYLE-makie.md`,
  `STYLE-upstream-contracts.md`, `STYLE-verification.md`,
  `STYLE-vocabulary.md`, `STYLE-workflow-docs.md`, and
  `STYLE-writing.md`.
- Mandated line-by-line reading of the parent PRD and this tranche file.
- Mandated line-by-line reading of `design/design.md`,
  `design/target-reference-capacities.md`,
  `design/requirements-landscape-gap.md`, and `design/api-landscape.md`.
- Mandated line-by-line reading of `src/Geometry.jl`, `src/Accessors.jl`,
  new topology-owner files, `src/LineageAxis.jl`, `src/CoordinateTransform.jl`,
  `test/test_Geometry.jl`, `test/test_Integration.jl`,
  `test/test_LineageAxis.jl`, and relevant example files.
- Mandated reading of upstream primary sources required by this tranche:
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/recursion_routines.jl`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/auxiliary.jl`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/compareNetworks.jl`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/generic/space.md`.

### Primary-goal lock

- Owns the geometry and coordinate-policy portion of lock item 1.
- Owns the Tier 2 geometry precondition for lock item 2.
- Preserves lock item 4 by ensuring Tier 2 closes foundational geometry repair
  before the source-specific extension work begins.
- Preserves lock item 6 by keeping rooted-tree layout behavior green through the
  same owner path.
- Tranche-specific non-completion condition:
  the work is not complete if geometry still consumes raw preorder traversal,
  silently overwrites one parent path with another, or leaves multi-parent
  coordinate semantics unspecified.

### What to build

Build the DAG-safe geometry owner on top of the normalized topology owner.

This tranche is foundational. Its purpose is to make `Geometry.jl` consume the
normalized topology and explicit view or projection metadata rather than raw
recursive source traversal. Rectangular and radial core modes must both use the
new owner model.

This tranche must define explicit semantics for topological coordinate modes
such as `:nodedepths`, `:nodelevels`, and `:nodeheights` on either the full
DAG-capable topology or an explicitly named tree projection. Weighted or
age-based coordinate modes must either consume source values that already
resolve ambiguity or require an explicit resolution policy.

When this tranche is complete, geometry must produce stable per-edge geometry
for the normalized edge set, not just a parent-before-child tree stroke list.

### Legacy artifacts to retire or demote

- Retire `all_nodes = preorder(accessor, basenode)` as the geometry owner's
  source of truth.
- Retire `_cumulative_preorder` as the implicit owner of process coordinates
  for multi-parent graphs.
- Retire `_nodeheights`'s reverse-preorder-as-postorder assumption as a generic
  lineage-graph rule.
- Retire `_nodelevels` and `_node_depths` as single-parent propagation owners.
- Demote `_assign_transverse`'s subtree-mean rule to an explicit tree-only or
  projection-specific policy if it survives.

### Forbidden regressions

- Choosing the first or last seen parent path silently for a DAG-capable mode.
- Reconstructing tree-only orderings from the raw accessor after the topology
  owner already exists.
- Treating a projected-tree helper as the generic geometry owner for full
  lineage graphs.
- Emitting node positions without stable edge geometry for the full normalized
  edge set.
- Claiming DAG support while still requiring every node to own one subtree.

### Environment and dependency baseline

- Tranche 1 must already have established the topology owner and optional
  extension boundary.
- Geometry changes must preserve tree-only public calls where the PRD still
  expects them to remain stable.
- The local upstream checkout root remains
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation`.
- Canonical green gates remain `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl`; affected examples should also remain
  runnable if they are part of the proof surface.

### Handoff packet

- **Active authorities**:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the bundled
  development-policies baseline, the four design documents, the parent PRD,
  this tranche file, and the completed output of Tranche 1.
- **Parent documents**:
  the parent PRD and the completed Tranche 1 handoff.
- **Settled decisions and non-negotiables**:
  geometry consumes normalized topology, rooted trees remain the single-parent
  special case, and no owner may silently overwrite one parent path with
  another.
- **Authorization boundary**:
  deep internal redesign is authorized in `src/Geometry.jl`, related topology
  files, tests, and examples; public breaks require review and migration notes.
- **Current-state diagnosis**:
  process and transverse coordinates are currently computed from tree-native
  preorder assumptions and unique-subtree logic.
- **Primary-goal lock**:
  lock items 1, 2, 4, and 6 from the parent PRD.
- **Direct red-state repros**:
  `_cumulative_preorder` overwrites child coordinates by parent walk order;
  `_nodeheights` assumes reverse preorder is valid postorder; transverse
  placement assumes one subtree per internal node.
- **Owner and invariant under repair**:
  geometry ownership; invariant that layout semantics come from the normalized
  lineage graph and explicit view contracts rather than raw source traversal.
- **Exact files or surfaces in scope**:
  `src/Geometry.jl`, new topology-owner files, relevant geometry-facing parts
  of `src/LineageAxis.jl` and `src/CoordinateTransform.jl`, related tests, and
  example files that prove the geometry contracts.
- **Exact files or surfaces out of scope**:
  source-specific `PhyloNetworks.jl` normalization, network-specific rendering
  styles, and public extension controls that belong to Tier 3.
- **Required upstream primary sources**:
  the `PhyloNetworks.jl` and Makie files named above for this tranche.
- **Green-state gates**:
  `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, DAG geometry regressions, and rooted-tree
  non-regression coverage.
- **Stop conditions**:
  any discovered need for a public break, any unresolved ambiguity in
  multi-parent coordinate semantics that cannot be derived honestly from the
  active sources, or any attempt to hide unresolved ambiguity inside a silent
  default.

### How to verify

- **Manual**:
  render at least one shared-ancestry DAG in rectangular and radial core modes
  and confirm all normalized edges are present;
  inspect at least one tree fixture and confirm the resulting rooted-tree layout
  matches the preserved special-case behavior;
  inspect any projection-specific mode and confirm the projection is explicit in
  code and docs rather than silently inferred.
- **Automated**:
  add geometry tests for shared-ancestry DAG process coordinates, transverse
  behavior, stable edge geometry, and true-cycle rejection;
  add rooted-tree non-regression tests for existing rectangular and radial
  layouts;
  run `julia --project=test test/runtests.jl`;
  run `julia --project=docs docs/make.jl`.

Include at least one negative regression that fails a fake fix which arbitrarily
chooses one parent path or silently projects the DAG to a tree without an
explicit contract.

### Acceptance criteria

- [ ] Given a normalized DAG with shared ancestry, when rectangular or radial
      geometry is computed, then the resulting geometry preserves the full edge
      set with stable identities.
- [ ] Given a coordinate mode whose semantics are ambiguous on a multi-parent
      graph, when the user has not supplied the required resolution or
      projection contract, then the owner fails directly or requires an
      explicit mode rather than silently inventing one.
- [ ] Given the old preorder-based helpers named above, when this tranche is
      complete, then they are removed, demoted, or otherwise prevented from
      surviving as the real geometry implementation for DAG-capable lineage
      graphs.
- [ ] Given a fake fix that still depends on one-parent or one-subtree
      assumptions, when verification is run, then the tranche fails rather than
      reporting a fake green.

### User stories addressed

- Parent PRD note: there is no numbered user-story section.
- This tranche addresses lock item 1: DAG is first-class in the core.
- This tranche addresses the geometry precondition of lock item 2:
  reticulation and hybridization are rendered correctly.
- This tranche preserves lock item 4: Tier 2 and Tier 3 boundaries are correct.
- This tranche preserves lock item 6: tree behavior survives as the special-case
  path.

## Tranche 3: annotation owner split and contract cleanup

**Type**: AFK
**Blocked by**: Tranche 1, Tranche 2

### Parent PRD

`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`

### Governance and required reading

- Mandated line-by-line reading of `AGENTS.md`, `CONTRIBUTING.md`,
  `STYLE-agent-handoffs.md`, `STYLE-architecture.md`, `STYLE-docs.md`,
  `STYLE-git.md`, `STYLE-julia.md`, `STYLE-makie.md`,
  `STYLE-upstream-contracts.md`, `STYLE-verification.md`,
  `STYLE-vocabulary.md`, `STYLE-workflow-docs.md`, and
  `STYLE-writing.md`.
- Mandated line-by-line reading of the parent PRD and this tranche file.
- Mandated line-by-line reading of `design/design.md`,
  `design/target-reference-capacities.md`,
  `design/requirements-landscape-gap.md`, and `design/api-landscape.md`.
- Mandated line-by-line reading of `src/Layers.jl`, `src/LineageAxis.jl`,
  `src/CoordinateTransform.jl`, `README.md`, `ROADMAP.md`,
  `docs/src/index.md`, relevant source docstrings and examples,
  `test/test_Layers.jl`, `test/test_Integration.jl`, and
  `test/test_LineageAxis.jl`.
- Mandated reading of upstream primary sources required by this tranche:
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/generic/space.md`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/plots/text.md`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/net_plot.md`.

### Primary-goal lock

- Owns the Tier 2 annotation-owner portion of lock item 2.
- Owns lock item 5 for documentation, vocabulary, and workflow drift repair in
  the scoped surfaces.
- Preserves lock item 6 by keeping rooted-tree annotation behavior as an honest
  special-case path.
- Tranche-specific non-completion condition:
  the work is not complete if generic annotation owners still assume a unique
  parent or one MRCA subtree, or if public docs still frame the package as
  tree-only or as a thin adapter host.

### What to build

Build the annotation-owner split between tree-only subtree semantics and
network-capable group or projection semantics, and clean up the public contract
surfaces to match that split.

This tranche is both foundational and migration-oriented within the repository.
It must preserve honest tree-only clade layers where subtree semantics are real
while adding shared contracts for graph-capable group annotation, projected
views, and other non-subtree annotation cases needed by DAG-capable lineage
graphs.

It must also update README, docs, roadmap, examples, source docstrings, and
workflow-facing language in the scoped surfaces so downstream agents are no
longer told that the package is tree-only or that `PhyloNetworks.jl` support is
just an adapter.

### Legacy artifacts to retire or demote

- Retire the universal `parent_of = Dict(dst => src ...)` assumption for
  generic node-label placement.
- Demote `_subtree_leaf_positions` to an explicitly tree-only or
  tree-projection helper if it survives.
- Retire the assumption that `clade_nodes`-style MRCA annotation is the only
  annotation owner model.
- Retire tree-only and adapter framing in `README.md`, `ROADMAP.md`,
  `docs/src/index.md`, examples, workflow notes, and affected docstrings.

### Forbidden regressions

- Keeping tree-only annotation semantics but merely renaming them as graph
  semantics in docs.
- Auto-projecting every DAG or network to one tree for annotation without
  exposing that projection contract.
- Shipping docs-only cleanup without the owner split that makes the docs true.
- Leaving new DAG or network terms out of `STYLE-vocabulary.md` once they
  become real project terms.
- Letting clade-oriented helpers remain the hidden owner of generic group
  annotations.

### Environment and dependency baseline

- Tranches 1 and 2 must already have established normalized topology and
  geometry ownership.
- Rooted-tree public behavior may remain stable where honest, but tree-only
  semantics must be named as such.
- The local upstream checkout root remains
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation`.
- Canonical green gates remain `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl`; affected examples must be updated and
  rerun in the same tranche as the contract change.

### Handoff packet

- **Active authorities**:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the bundled
  development-policies baseline, the four design documents, the parent PRD,
  this tranche file, and the completed outputs of Tranches 1 and 2.
- **Parent documents**:
  the parent PRD and the completed Tranche 1 and Tranche 2 handoffs.
- **Settled decisions and non-negotiables**:
  tree-only MRCA or subtree semantics may survive only where they are honest;
  graph-capable annotations must not pretend every group is one subtree; public
  docs must match the real architecture.
- **Authorization boundary**:
  deep redesign is authorized in layer internals, docs, examples, and
  vocabulary surfaces; public breaks require explicit approval and migration
  notes.
- **Current-state diagnosis**:
  node labels assume one parent, clade layers assume one subtree, and public
  docs still drift toward tree-only or adapter language.
- **Primary-goal lock**:
  lock items 2, 5, and 6 from the parent PRD.
- **Direct red-state repros**:
  `position = :toward_parent` derives one parent from `geom.edges`; clade
  highlights and clade labels delegate to subtree leaf collection; README,
  roadmap, and docs still use tree-only or adapter framing.
- **Owner and invariant under repair**:
  annotation and contract ownership; invariant that tree-only semantics are
  explicitly bounded and graph-capable annotations do not depend on fake
  subtree assumptions.
- **Exact files or surfaces in scope**:
  `src/Layers.jl`, `src/LineageAxis.jl`, `src/CoordinateTransform.jl`,
  `README.md`, `ROADMAP.md`, `docs/src/index.md`, source docstrings, examples,
  workflow docs in scope, vocabulary entries, and related tests.
- **Exact files or surfaces out of scope**:
  `PhyloNetworks.jl` extension normalization, network view-mode controls, and
  network-specific rendering primitives beyond the contracts needed to keep Tier
  2 honest.
- **Required upstream primary sources**:
  the Makie and `PhyloNetworks.jl` files named above for this tranche.
- **Green-state gates**:
  `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, updated examples, and contract-alignment
  review of the scoped docs surfaces.
- **Stop conditions**:
  any required public break, any unresolved vocabulary decision that cannot be
  derived from current authorities, or any attempt to keep generic annotation
  behavior on a hidden tree projection.

### How to verify

- **Manual**:
  render at least one rooted-tree case and confirm tree-only clade annotations
  still work where honest;
  render at least one DAG-capable group or projection case and confirm the
  annotation owner no longer relies on unique-parent or unique-subtree logic;
  inspect README, docs, roadmap, examples, and relevant docstrings and confirm
  they describe one coherent architecture.
- **Automated**:
  add or strengthen tests that fail if generic annotation code still assumes one
  parent or one subtree;
  add tests that fail if tree-only annotation surfaces are used on unsupported
  full-network views without an explicit diagnostic;
  run `julia --project=test test/runtests.jl`;
  run `julia --project=docs docs/make.jl`;
  rerun affected examples.

Include at least one negative verification that fails a fake fix which silently
projects a DAG or network to a tree for annotation, and at least one negative
verification that fails docs-only cleanup without the underlying owner repair.

### Acceptance criteria

- [ ] Given a rooted-tree view, when tree-only clade or MRCA annotation is
      used, then it still works through the repaired owner path.
- [ ] Given a graph-capable view that is not one subtree, when annotation is
      applied, then the owner uses an explicit group or projection contract or
      fails directly rather than pretending the group is one subtree.
- [ ] Given the legacy tree-only helpers and docs surfaces named above, when
      this tranche is complete, then they are removed, demoted, or explicitly
      bounded instead of surviving as the generic annotation model.
- [ ] Given a fake fix that keeps unique-parent or unique-subtree assumptions
      behind renamed APIs or updated docs, when verification is run, then the
      tranche fails rather than reporting a fake green.

### User stories addressed

- Parent PRD note: there is no numbered user-story section.
- This tranche addresses the annotation-owner portion of lock item 2:
  reticulation and hybridization are rendered correctly.
- This tranche addresses lock item 5: documentation, vocabulary, and workflow
  drift are repaired.
- This tranche preserves lock item 6: tree behavior survives as the special-case
  path.

## Tranche 4: `PhyloNetworks.jl` extension and network rendering primitives

**Type**: AFK
**Blocked by**: Tranche 1, Tranche 2, Tranche 3

### Parent PRD

`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`

### Governance and required reading

- Mandated line-by-line reading of `AGENTS.md`, `CONTRIBUTING.md`,
  `STYLE-agent-handoffs.md`, `STYLE-architecture.md`, `STYLE-docs.md`,
  `STYLE-git.md`, `STYLE-julia.md`, `STYLE-makie.md`,
  `STYLE-upstream-contracts.md`, `STYLE-verification.md`,
  `STYLE-vocabulary.md`, `STYLE-workflow-docs.md`, and
  `STYLE-writing.md`.
- Mandated line-by-line reading of the parent PRD, this tranche file, and the
  completed outputs of Tranches 1 through 3.
- Mandated line-by-line reading of `Project.toml`, `ext/PhyloNetworksExt.jl`
  once introduced, topology-owner files, `src/Geometry.jl`, `src/Layers.jl`,
  relevant tests, examples, and docs surfaces touched by the extension.
- Mandated reading of upstream primary sources required by this tranche:
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/types.jl`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/auxiliary.jl`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/interop.jl`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/netmanipulation.md`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/net_plot.md`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/explanations/recipes.md`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/plots/text.md`.

### Primary-goal lock

- Owns the Tier 3 extension and rendering-primitives portion of lock item 2.
- Owns the Tier 3 completion portion of lock item 3.
- Preserves lock item 6 by proving the optional extension leaves tree behavior
  green when the extension is absent.
- Tranche-specific non-completion condition:
  the work is not complete if the extension duplicates core traversal, layout,
  or annotation owners, or if network rendering still lacks honest hybrid-node,
  major-edge, minor-edge, and gamma-aware primitives.

### What to build

Build the optional `PhyloNetworks.jl` package extension and the first honest
network rendering primitives on top of the completed Tier 2 core.

This tranche is user-facing within Tier 3 but still owner-sensitive. It must
normalize `PhyloNetworks.HybridNetwork` objects into the core topology owner,
not around it, and it must use extension-local methods only for upstream object
adaptation and upstream-specific styling defaults.

This tranche must add the rendering primitives required for honest network
support: hybrid-node markers, major and minor reticulation edge styling, and
gamma-label plumbing. It may choose one explicit initial view contract, such as
full-network view, as the host for those primitives, but it must not smuggle
view-mode policy decisions that belong to Tranche 5 into hidden defaults.

### Legacy artifacts to retire or demote

- Retire the absence of any `PhyloNetworks.jl` extension implementation.
- Retire the idea that network support can exist without stable hybrid-node and
  reticulation-edge primitives.
- Retire any temptation to add extension-local traversal or geometry logic that
  bypasses the core owners.
- Demote any extension-local source-specific convenience code to thin adapter
  methods if it starts to grow into a second implementation.

### Forbidden regressions

- Duplicating topology, geometry, or annotation owners inside the extension.
- Treating the major tree alone as "network support" while minor reticulation
  edges disappear silently.
- Deriving hybrid semantics from label strings or plotting metadata instead of
  upstream node and edge fields.
- Making the extension mandatory for package load or for rooted-tree behavior.
- Hiding unresolved view-mode policy behind one undocumented default.

### Environment and dependency baseline

- Tranches 1 through 3 must already have landed and be green.
- `PhyloNetworks.jl` remains a weak dependency and activates via the package
  extension mechanism only when present.
- The authoritative upstream checkout root remains
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation`.
- Canonical green gates remain `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl`; extension-specific tests and examples
  must prove both extension absence and extension presence behavior.

### Handoff packet

- **Active authorities**:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the bundled
  development-policies baseline, the four design documents, the parent PRD,
  this tranche file, and the completed outputs of Tranches 1 through 3.
- **Parent documents**:
  the parent PRD and the completed Tranche 1 through Tranche 3 handoffs.
- **Settled decisions and non-negotiables**:
  the extension adapts `HybridNetwork` into the core owner model; no shadow
  owner is allowed; tree behavior must stay green when the extension is absent.
- **Authorization boundary**:
  redesign is authorized in `Project.toml`, `ext/`, tests, examples, docs, and
  directly affected layer surfaces; public breaks require explicit approval and
  migration notes.
- **Current-state diagnosis**:
  there is no extension yet, no optional integration path yet, and no network
  rendering primitives yet.
- **Primary-goal lock**:
  lock items 2, 3, and 6 from the parent PRD.
- **Direct red-state repros**:
  the repository has no `ext/` implementation, no weak-dependency activation
  behavior, and no hybrid-marker or major/minor-edge rendering path.
- **Owner and invariant under repair**:
  extension-boundary ownership and network rendering primitives; invariant that
  the extension only adapts upstream objects into core owners rather than
  becoming the real owner.
- **Exact files or surfaces in scope**:
  `Project.toml`, `ext/PhyloNetworksExt.jl`, topology-owner files, directly
  affected geometry and layer surfaces, extension-aware tests, examples, and
  docs.
- **Exact files or surfaces out of scope**:
  final view-mode and display-policy completion, new public controls that need
  review, and unrelated data-package integrations.
- **Required upstream primary sources**:
  the `PhyloNetworks.jl` and Makie files named above for this tranche.
- **Green-state gates**:
  `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, extension activation tests, rooted-tree
  non-regression tests, and rendered network-primitives artifacts.
- **Stop conditions**:
  any requirement to put traversal or geometry ownership into the extension,
  any requirement for a public break, or any unresolved upstream contract
  mismatch around hybrid-edge direction, `gamma`, or `ismajor`.

### How to verify

- **Manual**:
  load the package without `PhyloNetworks.jl` and confirm rooted-tree plotting
  still works;
  load with `PhyloNetworks.jl` present and render at least one real
  `HybridNetwork` fixture;
  visually confirm hybrid markers, major and minor edge distinction, and gamma
  labels or gamma-ready annotation positions on the scoped view contract.
- **Automated**:
  add extension activation tests that fail if the package hard-depends on
  `PhyloNetworks.jl`;
  add extension integration tests using real upstream fixtures for hybrid nodes,
  major edges, minor edges, and gamma values;
  run `julia --project=test test/runtests.jl`;
  run `julia --project=docs docs/make.jl`;
  rerun affected examples.

Include at least one negative verification that fails if minor reticulation
edges disappear from the supposed full-network rendering, and at least one
negative verification that fails if the extension duplicates core traversal or
layout logic.

### Acceptance criteria

- [ ] Given `PhyloNetworks.jl` is absent, when the package is loaded and rooted
      tree features are exercised, then the package stays usable without the
      extension.
- [ ] Given a real `PhyloNetworks.HybridNetwork`, when the extension is active,
      then the core owners receive stable topology and rendering data for hybrid
      nodes, major edges, minor edges, and gamma-aware annotations.
- [ ] Given the legacy absence of extension scaffolding and network primitives,
      when this tranche is complete, then those gaps are closed without leaving
      a source-specific shadow implementation behind.
- [ ] Given a fake fix that loads `PhyloNetworks.jl` as a hard dependency or
      reimplements traversal or geometry inside the extension, when verification
      is run, then the tranche fails rather than reporting a fake green.

### User stories addressed

- Parent PRD note: there is no numbered user-story section.
- This tranche addresses the Tier 3 rendering-primitives portion of lock item
  2: reticulation and hybridization are rendered correctly.
- This tranche addresses lock item 3: `PhyloNetworks.jl` support is an optional
  package extension.
- This tranche preserves lock item 6: tree behavior survives as the special-case
  path.

## Tranche 5: network view modes, display policy completion, and extension hardening

**Type**: HITL
**Blocked by**: Tranche 4

### Parent PRD

`.workflow-docs/20260506182547_dag-first-class-lineage-graphs-and-phylo-networks-extension/01_prd.md`

### Governance and required reading

- Mandated line-by-line reading of `AGENTS.md`, `CONTRIBUTING.md`,
  `STYLE-agent-handoffs.md`, `STYLE-architecture.md`, `STYLE-docs.md`,
  `STYLE-git.md`, `STYLE-julia.md`, `STYLE-makie.md`,
  `STYLE-upstream-contracts.md`, `STYLE-verification.md`,
  `STYLE-vocabulary.md`, `STYLE-workflow-docs.md`, and
  `STYLE-writing.md`.
- Mandated line-by-line reading of the parent PRD, this tranche file, and the
  completed outputs of Tranches 1 through 4.
- Mandated line-by-line reading of extension files, affected topology, geometry,
  and layer files, docs and examples for network behavior, and all relevant
  tests added by earlier tranches.
- Mandated reading of upstream primary sources required by this tranche:
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/compareNetworks.jl`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/src/auxiliary.jl`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/netmanipulation.md`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl/docs/src/man/net_plot.md`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/generic/space.md`,
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/docs/src/reference/plots/text.md`.

### Primary-goal lock

- Owns the remaining view-mode and display-policy portion of lock item 2.
- Closes lock item 4 at Tier 3 completion time by proving the source-specific
  tranche builds only on already-completed foundational owners.
- Closes the remaining Tier 3-facing part of lock item 5 in docs, examples, and
  workflow surfaces touched by final network support.
- Preserves lock item 6 by keeping rooted-tree and tree-projection behavior
  green beside the new network views.
- Tranche-specific non-completion condition:
  the work is not complete if full-network view, major-tree or projected-tree
  view, and rooted or semidirected display policies remain ambiguous, hidden,
  or silently chosen by undocumented defaults.

### What to build

Build the final network view modes, display policies, and hardening layer for
the `PhyloNetworks.jl` extension.

This tranche is HITL because the parent PRD contains explicit review gates for
public controls that may be needed for semidirected or unrooted display policy.
If those controls are derivable from active authorities, implementation may
proceed AFK within the tranche. If they are not derivable, the tranche must
stop for review rather than freezing a guessed public contract into code.

This tranche must add the explicit view-mode policy surface above the completed
extension foundation:
full-network view, major-tree projection or another explicitly named
projected-tree view, and rooted, semidirected, or unrooted display policies as
required by the verified upstream model. It must also harden docs, examples,
fixtures, and verification so the final Tier 3 contract is honest and
reproducible.

### Legacy artifacts to retire or demote

- Retire any hidden default that silently drops minor edges or silently projects
  a network to one displayed tree.
- Retire any remaining roadmap, docs, or workflow language that still frames
  Tier 3 as an adapter rather than a completed extension architecture.
- Demote any temporary internal projection flags to explicit public or
  extension-internal contracts with named semantics.

### Forbidden regressions

- Claiming full-network support while still showing only the major tree.
- Adding semidirected or unrooted controls without an explicit review checkpoint
  if those controls are not derivable from the active sources.
- Letting extension-local view code bypass the core topology and geometry
  contracts.
- Leaving docs or examples ambiguous about whether a render shows the full
  network or a projected-tree view.
- Regressing rooted-tree or rooted-tree-projection behavior while adding network
  modes.

### Environment and dependency baseline

- Tranches 1 through 4 must already be complete and green.
- The extension remains optional; rooted-tree behavior must remain green without
  `PhyloNetworks.jl`.
- The authoritative upstream checkout root remains
  `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation`.
- Canonical green gates remain `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl`; network examples and rendered artifacts
  are also mandatory for tranche completion.

### Handoff packet

- **Active authorities**:
  `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the bundled
  development-policies baseline, the four design documents, the parent PRD,
  this tranche file, and the completed outputs of Tranches 1 through 4.
- **Parent documents**:
  the parent PRD and the completed Tranche 1 through Tranche 4 handoffs.
- **Settled decisions and non-negotiables**:
  Tier 2 foundational owners are already closed; Tier 3 may not reopen them;
  view modes must be explicit; public-control questions that are not derivable
  must stop for review.
- **Authorization boundary**:
  extension, rendering, docs, examples, and verification work is authorized;
  any required public break or non-derivable new public control requires review
  before implementation continues.
- **Current-state diagnosis**:
  after Tranche 4, network primitives exist but the final view-mode and
  display-policy contract is not yet complete.
- **Primary-goal lock**:
  lock items 2, 4, 5, and 6 from the parent PRD.
- **Direct red-state repros**:
  current documentation and roadmap still permit an adapter reading;
  absent or hidden network projection policy would still let full-network and
  projected-tree behavior drift.
- **Owner and invariant under repair**:
  network view-mode and display-policy ownership; invariant that Tier 3 builds
  on completed core owners and that each rendered network mode is named
  honestly.
- **Exact files or surfaces in scope**:
  extension files, affected geometry and layer surfaces, network examples,
  docs, README, roadmap, workflow docs in scope, and all network-facing tests.
- **Exact files or surfaces out of scope**:
  unrelated new data-package integrations, unrelated layout families, and
  post-Tier-3 aspirational features.
- **Required upstream primary sources**:
  the `PhyloNetworks.jl` and Makie files named above for this tranche.
- **Green-state gates**:
  `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, rendered full-network and projected-tree
  artifacts, rooted-tree non-regression tests, and extension integration tests.
- **Stop conditions**:
  any non-derivable public control, any required public break, or any attempt
  to move foundational owner repair back into Tier 3.

### How to verify

- **Manual**:
  render the same real `PhyloNetworks.HybridNetwork` fixture in at least one
  full-network view and one explicitly named projected-tree view;
  inspect the outputs and confirm which edges, hybrid markers, and gamma labels
  are present in each mode;
  inspect rooted, semidirected, and unrooted policy behavior for the scoped
  upstream-supported cases;
  review the final docs, examples, roadmap, and workflow surfaces for contract
  alignment.
- **Automated**:
  add integration tests that distinguish full-network and projected-tree output
  behavior;
  add tests that cross-check projected-tree behavior against upstream helpers
  such as `displayedtrees` or major-tree utilities where applicable;
  add tests that fail if minor edges disappear in full-network mode or if a
  projected-tree mode is not explicitly named;
  run `julia --project=test test/runtests.jl`;
  run `julia --project=docs docs/make.jl`;
  rerun affected examples and any extension-specific demonstrations.

Include at least one negative verification that fails if full-network mode
silently degenerates into the major tree, and at least one negative verification
that fails if a projected-tree mode is exposed without explicit naming and
documentation.

### Acceptance criteria

- [ ] Given a real `HybridNetwork` fixture, when the user selects full-network
      view, then major and minor reticulation edges, hybrid markers, and scoped
      gamma annotations appear according to the verified contract.
- [ ] Given the same fixture, when the user selects an explicitly named
      projected-tree or major-tree view, then the render matches that named
      projection rather than an undocumented fallback.
- [ ] Given the legacy hidden or ambiguous policy surfaces named above, when
      this tranche is complete, then they are removed, demoted, or otherwise
      prevented from surviving as silent defaults.
- [ ] Given a fake fix that silently chooses one projection or introduces new
      public controls without the required review gate, when verification is
      run, then the tranche fails rather than reporting a fake green.

### User stories addressed

- Parent PRD note: there is no numbered user-story section.
- This tranche closes the remaining view-mode and display-policy portion of lock
  item 2: reticulation and hybridization are rendered correctly.
- This tranche closes lock item 4: Tier 2 and Tier 3 boundaries are correct.
- This tranche closes the remaining Tier 3-facing part of lock item 5:
  documentation, vocabulary, and workflow drift are repaired.
- This tranche preserves lock item 6: tree behavior survives as the special-case
  path.
