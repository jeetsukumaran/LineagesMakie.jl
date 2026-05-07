---
date-created: 2026-05-06T18:25:47
scope: architecture
---

# PRD: DAG-first-class lineage graphs and `PhyloNetworks.jl` extension for LineagesMakie.jl

## User statement

LineagesMakie.jl should treat DAG lineage graphs as a first-class core model,
with rooted trees preserved as the single-parent special case. This work must
define the architecture and tranche boundary for:

- a DAG-capable core redesign of traversal, geometry, annotation, and optional
  integration scaffolding
- full, correct `PhyloNetworks.jl` visualization support as an optional package
  extension rather than a hard dependency or source-specific shadow owner

This is architecture work for an early-stage package, not a thin feature add.

## Active authorities

- `AGENTS.md`
- `CONTRIBUTING.md`
- `STYLE-architecture.md`
- `STYLE-agent-handoffs.md`
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
- this PRD

Scope is limited to this repository plus the local upstream checkouts in
`codebases-and-documentation`, especially `PhyloNetworks.jl` and Makie-family
sources. `LineagesIO.jl` must not influence this design. `Lineages.jl` and
`LineageGraphs.jl` are relics and out of scope.

## Problem statement

LineagesMakie.jl already has a strong Makie-native composition surface:
`LineageGraphAccessor`, `Geometry`, `Layers`, `CoordinateTransform`, and
`LineageAxis` are real owners, and the package should not be framed as
throwaway work. But the current implementation is still fundamentally tree
native.

Today, valid shared ancestry is treated as traversal failure, layout ownership
assumes single-parent subtree semantics, several annotation layers depend on
MRCA-subtree logic, and the package has no optional extension scaffolding for
`PhyloNetworks.jl`. The design analysis documents have already moved Tier 2 and
Tier 3 toward a DAG-first direction, but the running code, public docs, roadmap
language, examples, and verification surface still describe or prove a tree-only
system.

If downstream agents preserve tree-only invariants and attempt to "add a
PhyloNetworks adapter" on top, the package will drift into a split architecture:
the core will remain tree-native while the source-specific integration silently
owns real DAG and network semantics. That outcome is explicitly forbidden.

## Target outcome

When this work is complete, the package will truthfully support the following
architecture claims:

- DAG lineage graphs are first-class in the core owner model.
- Valid shared ancestry is accepted, while actual directed cycles are rejected
  with direct diagnostics.
- Geometry ownership no longer assumes that every node has exactly one parent or
  exactly one subtree.
- Annotation ownership separates tree-only MRCA/subtree semantics from
  network-capable group and projection semantics.
- Rooted tree behavior remains available as the special-case path inside the
  broader owner model.
- `PhyloNetworks.jl` support ships as an optional package extension layered on
  top of the core owners.
- Tier 2 ends with a genuinely DAG-capable foundation.
- Tier 3 adds network-specific rendering, view modes, and `PhyloNetworks.jl`
  integration without reopening Tier 2 owner decisions.
- README, docs, roadmap, examples, docstrings, workflow docs, and controlled
  vocabulary describe the same target architecture instead of mixed tree-only
  and DAG-first language.

## Current-state diagnosis

### Existing strengths to preserve

- `LineageAxis.jl` is already a meaningful Makie `Block` owner for screen
  embedding, decoration layout, and annotation-side policy.
- `CoordinateTransform.jl` already owns reactive data-to-pixel and pixel-to-data
  conversion and should remain reusable.
- The current `Accessors` / `Geometry` / `Layers` split is the right general
  direction even though the internals are still tree-native.
- The recipe-based Makie composition surface is worth keeping and extending.

### Tree-native traversal owner

`src/Accessors.jl:171-230` uses a global `visited::Set` for both `leaves` and
`preorder`. `_check_cycle!` explicitly states that shared ancestry is not yet
supported and throws as soon as a node is encountered more than once. In
practice, any valid DAG with a shared descendant is currently treated as a
"cycle."

Direct red-state repro shape:

- a basenode whose two children both point to the same downstream node triggers
  `ArgumentError` during traversal even when the graph is acyclic

### Tree-native geometry owner

`src/Geometry.jl:157-183` builds layout from `preorder(accessor, basenode)`,
which already excludes valid repeated-node DAGs. Even beyond traversal,
`src/Geometry.jl:353-520` uses preorder and reverse-preorder assumptions that are
only valid for trees:

- `_cumulative_preorder` overwrites child coordinates as though each node has a
  single parent
- `_nodeheights` assumes reverse preorder is a valid postorder because parents
  precede descendants exactly once
- `_nodelevels` and `_node_depths` propagate one parent path
- `_assign_transverse` places an internal node at the mean of its children,
  assuming one descendant subtree per node

The current geometry owner therefore cannot honestly claim DAG support even if
traversal were relaxed.

### Tree-native annotation owner

`src/Layers.jl:412-430` derives `parent_of = Dict(dst => src for (src, dst) in
geom.edges)` for node labels with `position = :toward_parent`, which silently
assumes a unique parent.

`src/Layers.jl:584-657` drives clade highlights and clade labels by subtree
leaf collection under one MRCA node via `_subtree_leaf_positions(accessor, mrca,
node_positions)`, which delegates back to `leaves(accessor, mrca)`. This is a
tree-only contract. It is useful and should survive for tree projections, but it
cannot remain the only annotation owner model.

### No extension scaffolding

- `Project.toml:1-13` has no `[weakdeps]` or `[extensions]` sections
- there is no `ext/` directory in the repository

So the package currently has no formal optional-integration boundary for
`PhyloNetworks.jl`.

### Documentation and workflow drift

Some local design docs are already aligned with the intended architecture:

- `design/design.md:86-99` already states that rooted trees are the special case
  of a broader lineage-graph model and that `PhyloNetworks.jl` belongs above the
  owner boundary as an optional extension
- `design/target-reference-capacities.md:56-74` already defines Tier 2 as the
  DAG-capable owner foundation and Tier 3 as the network-specific completion
- `design/requirements-landscape-gap.md:122-131` already rejects the "just add
  an adapter" framing

But major public and workflow-facing drift remains:

- `README.md:8-21` still frames the package around rooted branching structures
- `docs/src/index.md:23-27` still describes vertical support in terms of "tree
  geometry"
- `ROADMAP.md:44-46` still says `PhyloNetworks.jl adapter`
- examples, tests, and source docstrings are overwhelmingly tree-only and would
  mislead a downstream agent into preserving tree invariants in the core

### Verification drift

The test suite and examples were reviewed, but their proof surface is still
tree-native: there are no substantive DAG, reticulation, hybrid-edge, or
`PhyloNetworks.jl` extension regressions. Also, `Pkg.test()` currently reports a
project-metadata mismatch in this checkout despite `Project.toml` containing a
name and UUID, so downstream verification should treat
`julia --project=test test/runtests.jl` as the canonical green gate until that
invocation drift is resolved.

## Upstream reading obligations

Downstream tranche and implementation agents must read the following primary
sources line by line before substantial work in their tranche:

- `PhyloNetworks.jl/src/types.jl`
  - `EdgeT`, `Node`, and `HybridNetwork` data model; hybrid edges carry `gamma`,
    `ismajor`, and direction via `ischild1`
- `PhyloNetworks.jl/src/auxiliary.jl`
  - `getroot`, `getchild`, `getchildren`, `getparent`, `getparents`,
    `getparentminor`, `getparentedgeminor`
- `PhyloNetworks.jl/src/recursion_routines.jl`
  - preorder and postorder traversal contracts distinguishing tree nodes from
    hybrid nodes by parent-count semantics
- `PhyloNetworks.jl/src/interop.jl`
  - exported major-edge, minor-reticulation, length, and gamma helper shape
- `PhyloNetworks.jl/src/compareNetworks.jl`
  - `majortree` and displayed-tree expectations
- `PhyloNetworks.jl/docs/src/man/netmanipulation.md`
  - upstream public semantics for parent/child access, hybrid nodes, and major
    tree utilities
- `PhyloNetworks.jl/docs/src/man/net_plot.md`
  - upstream visualization expectations for gamma display, major/minor edge
    treatment, and style distinctions
- `Makie/docs/src/explanations/recipes.md`
  - recipe ownership, `convert_arguments`, `plot!`, compute-graph behavior, and
    Makie package extension pattern
- `Makie/docs/src/reference/generic/space.md`
  - block/scene projection ownership and plot-space rules
- `Makie/docs/src/reference/plots/text.md`
  - text placement, pixel/data marker space, offsets, and bounding-box limits
- `Makie/Makie/src/makielayout/types.jl`
  - `@Block Axis` ownership shape and axis text attributes

Agents must also re-read affected local code, tests, README, docs, examples,
design docs, and roadmap before freezing tranche decisions.

## Authorized disruption boundary

- internal redesign allowed:
  - deep redesign is authorized within `Accessors`, geometry ownership, layer
    ownership, tests, docs, examples, and package-extension scaffolding if that
    is what it takes to repair the real owners and invariants
- internal redesign forbidden:
  - do not preserve tree-only invariants in the core merely because the current
    tests are green
  - do not solve this with a source-specific shadow owner
  - do not frame the solution as a thin `PhyloNetworks.jl` adapter
  - do not let `Graphs.jl` become a competing architecture track unless it fits
    the same DAG-capable owner model after the core redesign
- external breaking changes:
  - preserve current tree-facing behavior where possible
  - if a downstream tranche concludes that a public break is necessary, that
    tranche must stop for explicit approval and provide a concrete migration
    plan before implementation
- non-negotiable protections:
  - every tranche begins and ends green
  - tree behavior remains supported as the special-case path inside the broader
    owner model
  - the package extension boundary remains optional and Makie-native

## Target architecture

### Core design direction

The package should be re-architected as a normalized lineage-graph pipeline:

1. Input adapters normalize external objects into a package-owned internal
   lineage-graph topology model.
2. The topology owner proves acyclicity, stable node and edge identity,
   parent/child incidence, and topological order, while allowing shared ancestry.
3. Geometry consumes the normalized topology plus an explicit view or projection
   contract instead of traversing raw source objects ad hoc.
4. Annotation and rendering layers consume geometry and shared projection/group
   contracts instead of inferring subtree semantics directly from source
   traversal.
5. Optional extensions adapt source-specific data models into the normalized
   core; they do not own traversal, geometry, or annotation semantics.

Rooted trees remain the simplest instance of this pipeline: one parent per
non-root node, one displayed full-network view, and tree-only MRCA/subtree
annotation paths available by default.

### Owner model

- `Accessors.jl`
  - remains the generic input boundary for tree-friendly callers
  - continues to support the current child-based access pattern for tree users
  - may grow optional richer normalization inputs, but existing tree ergonomics
    should remain stable if possible
- topology owner
  - should become an explicit internal owner, preferably extracted into a
    dedicated module such as `Topology.jl`
  - owns stable node identity, stable edge identity, root policy, parent/child
    incidence, cycle detection, topological order, and projection bookkeeping
  - must distinguish valid repeated node encounters from actual directed cycles
- `Geometry.jl`
  - must consume normalized topology and an explicit projection or view contract
  - must stop assuming single-parent or unique-subtree ownership
  - must produce per-edge geometry, not just parent-before-child tree strokes
- annotation and layer owner
  - keeps tree-only MRCA/subtree layers where honest
  - adds network-capable group/projection annotation contracts for sets, paths,
    and projected views that are not one subtree
- `LineageAxis.jl` and `CoordinateTransform.jl`
  - remain the Makie-native owners of block layout, scene/projection policy, and
    pixel/data conversion
  - should be extended only where the new graph/view contracts require it
- package extension owner
  - lives under `ext/`
  - adapts `PhyloNetworks.HybridNetwork` node, edge, major/minor, root, and
    gamma semantics into the normalized core contracts

### Shared contracts and invariants

- a second encounter of a node is not a cycle by itself
- actual directed cycles are invalid and must fail directly
- every rendered edge has a stable edge identity in the core model
- tree-only subtree semantics are allowed only on views that are actually trees
- network-capable annotation must be expressible without pretending a group is
  one MRCA subtree
- extension packages may add source-specific normalization and styling, but the
  core package owns graph semantics and layout semantics
- full-network views and projected-tree views are separate contracts
- rooted trees remain supported through the same core owner path, not a forked
  legacy implementation

### Coordinate and projection policy

Tier 2 must define explicit multi-path coordinate policy rather than silently
reusing tree formulas:

- topological units such as depth, level, and height must have DAG-safe
  semantics on the normalized topology or on an explicit tree projection
- weighted or age-based coordinates on a network must either rely on
  time-consistent source values or require an explicit resolution policy or
  projection mode
- no owner may silently overwrite one parent path with another

Tier 3 must then expose the network-specific view modes that sit on top of this
contract:

- full-network view
- major-tree projection or equivalent displayed-tree projection
- rooted, semi-directed, and unrooted display policies where applicable

## Module design

- **Name**: `Accessors.jl`
  **Responsibility**: public generic input normalization for ordinary Julia
  objects and `AbstractTrees`-style data.
  **Interface**: `LineageGraphAccessor`, accessor constructors, and any
  user-facing migration layer needed to preserve tree ergonomics.
  **Tested**: yes. Must keep current tree paths green and add DAG-safe input
  normalization coverage.

- **Name**: topology owner (`Topology.jl` preferred if extracted)
  **Responsibility**: normalize reachable nodes and edges into a package-owned
  DAG model with explicit incidence, edge identity, topological order, cycle
  diagnostics, and view/projection metadata.
  **Interface**: internal normalized lineage-graph record used by geometry,
  layers, and extensions.
  **Tested**: yes. Must prove shared-ancestry acceptance, true-cycle rejection,
  and stable identity under tree and DAG fixtures.

- **Name**: `Geometry.jl`
  **Responsibility**: compute rectangular, radial, and later network-specific
  embeddings from normalized topology and active view contracts.
  **Interface**: geometry records with node positions, per-edge shapes, leaf or
  sink order, bounding boxes, and any view metadata needed by layers.
  **Tested**: yes. Must prove DAG-safe layout and preserved tree behavior.

- **Name**: `Layers.jl`
  **Responsibility**: render edges, nodes, labels, highlights, and future
  network-specific layers against geometry and shared annotation contracts.
  **Interface**: `lineageplot`, `lineageplot!`, layer recipes, and
  annotation/group APIs.
  **Tested**: yes. Must prove correct behavior for tree-only annotations,
  network-capable group annotations, and source-agnostic rendering behavior.

- **Name**: `LineageAxis.jl`
  **Responsibility**: own Makie block behavior, screen embedding, decoration
  bands, and panel-owned annotation layout.
  **Interface**: `LineageAxis`, axis attributes, and shared decoration-layout
  observables.
  **Tested**: yes. Should remain green while accommodating the new graph/view
  contracts.

- **Name**: `CoordinateTransform.jl`
  **Responsibility**: own reactive projection utilities and pixel/data
  conversions.
  **Interface**: projection-registration and conversion helpers.
  **Tested**: yes. Must remain correct for new annotation and network label
  placements.

- **Name**: `ext/PhyloNetworksExt.jl`
  **Responsibility**: optional upstream integration for `HybridNetwork` with
  correct mapping of hybrid nodes, major/minor edges, gamma annotations, and
  rooted or semidirected policies into the core contracts.
  **Interface**: package extension methods plus any extension-local tests,
  examples, and docs wiring.
  **Tested**: yes. Must prove full-network and projected-tree rendering on real
  `PhyloNetworks.jl` fixtures.

- **Name**: docs, roadmap, examples, vocabulary, and workflow docs
  **Responsibility**: describe only the supported public contract and the
  accepted architecture.
  **Interface**: `README.md`, `ROADMAP.md`, `docs/src/index.md`, design docs,
  source docstrings, examples, tests, and `STYLE-vocabulary.md`.
  **Tested**: yes. Contract alignment and example execution are part of the
  proof surface.

## Governance and controlled vocabulary

- downstream documents must re-read:
  - `AGENTS.md`
  - `CONTRIBUTING.md`
  - all relevant `STYLE*.md` files listed under active authorities
  - this PRD
  - affected tranche and tasking files once created
- vocabulary decisions:
  - `lineage graph` now means a broader DAG-capable owner model with rooted
    trees as the single-parent special case
  - `tree projection`, `full-network view`, `major-tree projection`,
    `hybrid node`, `reticulation edge`, `major edge`, `minor edge`, `gamma
    label`, `group annotation`, and any new DAG-specific owner terms must be
    added to `STYLE-vocabulary.md` before implementation if not already present
  - `MRCA`, `subtree`, and `clade` remain valid terms, but only for tree views
    or explicit tree-only layers
- terms to avoid:
  - avoid describing Tier 3 as an `adapter` unless the term refers narrowly to
    one input normalization shim inside an already DAG-capable core
  - avoid implying that repeated node encounter means cycle
  - avoid calling a network projection a `tree` without naming the projection
    mode

## Tranche boundary

### Tier 2: DAG-capable foundation

Tier 2 is complete only when the package can honestly say that DAG lineage
graphs are first-class in the core architecture even before the
`PhyloNetworks.jl` extension is added.

Tier 2 must include:

- DAG-capable topology normalization and cycle detection
- DAG-capable traversal APIs and internal view/projection support
- DAG-capable geometry ownership for rectangular and radial core modes
- explicit split between tree-only annotation semantics and graph-capable
  group/projection annotation semantics
- package-extension scaffolding in `Project.toml` and `ext/`
- preserved tree behavior as a special case through the same owner path
- doc, roadmap, vocabulary, example, and docstring cleanup needed to stop
  misleading downstream agents
- foundational verification for shared ancestry, true cycles, DAG geometry, and
  tree non-regression

Tier 2 must not leave any foundational traversal, geometry, or annotation owner
repair for Tier 3.

### Tier 3: network completion and `PhyloNetworks.jl`

Tier 3 is complete only when `PhyloNetworks.jl` support is honest, correct, and
fully layered over the Tier 2 foundation.

Tier 3 must include:

- `PhyloNetworks.jl` package extension
- hybrid node markers
- major/minor reticulation edge rendering
- gamma label support
- full-network versus projected-tree or major-tree view modes
- rooted, semi-directed, and unrooted network display policies as required by
  the upstream model and public visualization contract
- any additional network-specific annotation, routing, or style policy required
  for correct `HybridNetwork` support
- docs, examples, and tests that prove the extension is optional and fully
  functional when present

Tier 3 must not become the first place where traversal, layout, annotation, or
projection semantics are truly implemented.

## Proposed tranche sequence

- Tranche 1: topology owner and extension scaffolding
  - introduce normalized lineage-graph topology ownership
  - add `ext/` and optional dependency scaffolding
  - add DAG-versus-cycle verification fixtures
- Tranche 2: geometry redesign
  - rework rectangular and radial geometry to consume normalized topology
  - preserve tree layout behavior as the special case
  - add DAG geometry proofs
- Tranche 3: annotation and contract cleanup
  - separate tree-only MRCA/subtree layers from graph-capable group/projection
    layers
  - update README, docs, roadmap, docstrings, examples, and vocabulary
  - leave Tier 2 green and non-misleading
- Tranche 4: `PhyloNetworks.jl` extension and rendering primitives
  - implement normalization from `HybridNetwork`
  - add hybrid markers, major/minor edge rendering, and gamma labels
- Tranche 5: network view modes and policy completion
  - add full-network and major-tree projections
  - add rooted, semi-directed, and unrooted display policies
  - prove correct extension behavior on real upstream fixtures

Downstream tranche files may refine this sequence, but they must preserve the
Tier 2 and Tier 3 boundary above.

## Lock items

### Lock item 1: DAG is first-class in the core

- non-completion condition:
  - any core owner still rejects shared ancestry, requires unique parentage, or
    routes DAG support through a source-specific side path
- current red-state repro:
  - `src/Accessors.jl:171-230` throws on repeated node encounter even for valid
    DAGs
- owning tranche or owner:
  - Tier 2, topology owner plus geometry owner
- verification artifact:
  - DAG fixtures with shared descendants and no directed cycle must normalize and
    render without error; directed-cycle fixtures must still fail directly

### Lock item 2: reticulation and hybridization are rendered correctly

- non-completion condition:
  - the package can ingest a network but still lacks correct edge identity,
    hybrid markers, major/minor path distinction, or honest annotation semantics
- current red-state repro:
  - geometry and layers derive tree-only parent/subtree logic from `geom.edges`
    and `leaves(accessor, mrca)`
- owning tranche or owner:
  - Tier 2 geometry and annotation split, then Tier 3 network rendering layers
- verification artifact:
  - rendered regression artifacts for shared ancestry, hybrid nodes, major/minor
    reticulation edges, and gamma labels on real network fixtures

### Lock item 3: `PhyloNetworks.jl` support is an optional package extension

- non-completion condition:
  - `PhyloNetworks.jl` becomes a hard dependency, or its extension becomes the
    real owner of traversal, layout, annotation, or projection semantics
- current red-state repro:
  - there is no `ext/` scaffolding and no optional dependency boundary today
- owning tranche or owner:
  - Tier 2 extension scaffolding, then Tier 3 `PhyloNetworks` extension
- verification artifact:
  - package loads and tree features stay green without `PhyloNetworks.jl`; the
    extension activates and renders correctly when `PhyloNetworks.jl` is present

### Lock item 4: Tier 2 and Tier 3 boundaries are correct

- non-completion condition:
  - any foundational DAG owner repair is deferred to the `PhyloNetworks.jl`
    tranche, or Tier 2 ends while the core is still tree-native
- current red-state repro:
  - current docs and roadmap still permit an "adapter on top of tree core"
    reading
- owning tranche or owner:
  - this PRD, then the tranche file derived from it
- verification artifact:
  - tranche documents show Tier 2 closing all foundational owners before Tier 3
    starts source-specific network completion

### Lock item 5: documentation, vocabulary, and workflow drift are repaired

- non-completion condition:
  - README, docs, roadmap, design notes, workflow docs, examples, or docstrings
    still tell downstream agents that the package is tree-only or that
    `PhyloNetworks.jl` is just an adapter
- current red-state repro:
  - `README.md:8-21`, `docs/src/index.md:23-27`, and `ROADMAP.md:44-46` still
    encode tree-only or adapter framing
- owning tranche or owner:
  - Tier 2 doc and contract cleanup tranche
- verification artifact:
  - contract-alignment review plus updated docs/examples committed in the same
    tranche as the owner changes

### Lock item 6: tree behavior survives as the special-case path

- non-completion condition:
  - DAG redesign regresses current tree layouts, annotations, or `LineageAxis`
    behavior without an approved break
- current red-state repro:
  - no DAG support exists yet, so downstream could over-correct by rebuilding
    around network-only assumptions
- owning tranche or owner:
  - every Tier 2 and Tier 3 tranche
- verification artifact:
  - current tree tests, docs, and examples remain green alongside new DAG and
    network coverage

## Tranche gates

- required green checks at tranche start and end:
  - `julia --project=test test/runtests.jl`
  - `julia --project=docs docs/make.jl`
- required example and docs proofs:
  - rerun affected existing examples
  - add DAG and `PhyloNetworks.jl` examples as the relevant tranche lands
  - update README, docs site, roadmap, design notes, and source docstrings in
    the same tranche as the contract change
- required visual proofs:
  - rendered artifacts for at least one shared-ancestry DAG
  - rendered artifacts for at least one `PhyloNetworks.HybridNetwork` in full
    network view and one projected-tree view
  - render-level proof of hybrid marker, major/minor edge styling, and gamma
    label placement
- migration and compatibility obligations:
  - any externally visible break requires explicit approval and a migration note
    in the same tranche

## Testing and verification decisions

- what must stay green throughout:
  - existing tree-oriented unit and integration tests, unless an explicit
    approved change updates them
  - docs build
  - current Makie block ownership and coordinate-transform correctness
- what must be added:
  - topology normalization tests for shared ancestry and true cycles
  - geometry tests for DAG-safe process and transverse coordinate behavior
  - annotation tests distinguishing tree-only MRCA paths from graph-capable
    group or projection annotations
  - extension activation tests
  - `PhyloNetworks.jl` integration tests using real upstream fixtures
- what cannot count as sufficient proof by itself:
  - grep checks
  - source-level reasoning without rendered proof for label and edge-annotation
    behavior
  - a green tree-only suite after foundational DAG work

## Migration envelope

Expected stable behavior if possible:

- existing tree-facing plotting calls
- existing Makie-native composition patterns
- current `LineageAxis` embedding and decoration ownership

Potentially breaking areas if the real owner repair demands it:

- internal accessor normalization details
- public annotation APIs that currently imply subtree-only semantics
- any public naming that conflates trees with general lineage graphs

If any of those must break, the tranche must ship:

- explicit approval
- migration notes
- updated examples and docs
- compatibility shims or tests proving why no shim is provided

## Out of scope

- design influence from `LineagesIO.jl`
- using `Lineages.jl` or `LineageGraphs.jl` as architecture inputs
- a separate Graphs.jl-first architecture track
- unrelated feature work outside the DAG-core and `PhyloNetworks.jl` support
- pretending R/PhyloPlots behavior is the core owner model instead of an
  upstream reference point

## Review gates

- REVIEW if a public API break is required to preserve honest DAG semantics
- REVIEW if semidirected or unrooted `PhyloNetworks.jl` display policy needs new
  public user controls that are not derivable from existing contracts
- REVIEW if a proposed implementation tries to move foundational owner work from
  Tier 2 into the `PhyloNetworks.jl` tranche

## Further notes

The architectural direction is a foundational redesign of the real owners, not a
surface styling pass. The right reading of the current package is "promising
Makie-native early-stage system whose core owners must now be lifted from tree
native to DAG capable," not "failed tree package that should be thrown away."

The updated design docs already point in the correct direction. The practical
task of this PRD is to freeze that direction as the governing implementation
boundary, clean up the remaining public drift, and make it impossible for a
downstream agent to misread Tier 3 as a thin bolt-on adapter project.

## Handoff packet

- active authorities:
  - `AGENTS.md`, `CONTRIBUTING.md`, all repo-local `STYLE*.md`, the listed
    design docs, and this PRD
- parent documents:
  - none; this is the governing architecture PRD for this initiative
- settled decisions and non-negotiables:
  - DAG is first-class in the core
  - trees are the special case
  - no thin `PhyloNetworks` adapter framing
  - no source-specific shadow owner
  - Tier 2 closes foundational owners; Tier 3 builds on them
- authorization boundary:
  - deep internal redesign is authorized in this repo
  - public breaks require explicit approval and migration notes
- current-state diagnosis:
  - traversal, geometry, and several annotation paths are tree-native
  - no extension scaffolding exists
  - docs and roadmap still drift
- primary-goal locks:
  - lock items 1-6 above
- direct red-state repros:
  - repeated-node DAG currently throws as cycle
  - node-label parent lookup assumes one parent
  - clade layers assume one MRCA subtree
  - roadmap still says `PhyloNetworks.jl adapter`
- owner and invariant being repaired:
  - topology, geometry, annotation, and extension-boundary ownership
  - invariant: DAG support lives in the core, not in the extension
- exact scope in:
  - this repo, local `PhyloNetworks.jl`, and Makie-family upstream references
- exact scope out:
  - `LineagesIO.jl`, `Lineages.jl`, `LineageGraphs.jl`, unrelated ecosystem work
- required upstream primary sources:
  - the `PhyloNetworks.jl` and Makie files listed above
- green-state gates:
  - `julia --project=test test/runtests.jl`
  - `julia --project=docs docs/make.jl`
  - rendered DAG and network verification artifacts
- stop conditions:
  - any required public break
  - any attempt to defer foundational owner repair to Tier 3
  - any conflict between workflow docs and current code reality
