---
date-created: 2026-04-23T15:38:19
parent-prd: .workflow-docs/202604181600_tier1/01_prd.md
scope: refinement
---

# PRD: LineagesMakie.jl tier 1 audit fixes

## User statement

> Focus this PRD on items 1-3 in
> `.workflow-docs/202604181600_tier1/logs/log.20260423T0202--codex-audit-pre-tier-2.md`.
> The public `lineage_orientation` contract is inconsistent: the docs and
> vocabulary still describe `:top_to_bottom` and `:bottom_to_top`, while the
> implementation only supports `:left_to_right`, `:right_to_left`, and
> `:radial`. `show_y_axis`, `show_grid`, and `ylabel` are exposed publicly even
> though Tier 1 does not implement them. The annotation-layout work is better,
> but the tests still mostly prove lane geometry rather than rendered
> readability. Determine the effort based on those findings. All redesign is
> allowed with user consent if good design demands it. APIs, docs, and examples
> can change with user permission, but verification gates and non-regressions
> must be respected. External breaking changes are allowed. We are done with the
> original `01_prd`; this is a refinement and fix layer on top of that document.
> The target is full implementation of the documented target-state
> functionality. Save this work under `tier1-audit-fixes`.

## Problem statement

`LineagesMakie.jl` currently has contract drift between its public design
documents, its controlled vocabulary, its source-level docstrings, and its
actual `LineageAxis` implementation. A user who reads the public docs can
reasonably expect vertical dendrogram orientations, a live y-axis, grid
support, and y-axis labeling, but the running code does not yet provide that
end-to-end behavior. This creates a user-facing risk of silent wrong behavior
and a maintainer-facing risk of shipping a public contract that is broader than
the verified implementation.

The deeper architectural problem is ownership drift. `Geometry` correctly models
process and transverse coordinates without screen assumptions, and recent
`LineageAxis` work improved panel-owned annotation reservation, but the screen
embedding contract is still only partially owned. Horizontal and radial cases
are implemented; vertical orientations and full screen-axis decoration policy
are not. Verification has improved at the layout-lane level, but it still does
not directly prove rendered readability or non-overlap for the public examples.

## Target outcome

When this work is complete, the documented Tier 1 target state for audit items
1-3 will be true in code, tests, docs, and examples.

- `lineage_orientation` will have one coherent public contract across
  `STYLE-vocabulary.md`, design docs, source docstrings, examples, and tests.
- `:top_to_bottom` and `:bottom_to_top` will be implemented end to end for
  rectangular layouts, including camera limits, annotation-side mirroring,
  axis-label placement, and public examples.
- `show_y_axis`, `show_grid`, and `ylabel` will be real implemented public API
  on `LineageAxis`, not reserved placeholders.
- `LineageAxis` will own screen-axis decoration policy for all supported
  rectangular orientations rather than leaving parts of that policy implicit or
  horizontal-only.
- Verification will include at least one direct render-level proof of label
  readability or non-overlap, not only lane-geometry proxies.
- The existing horizontal and radial behaviors that already work will remain
  green unless an explicit user-approved breaking change is required.

## User stories

1. As a researcher, if the public docs mention a `lineage_orientation` value, I
   want it to work in the implementation so that documentation does not promise
   nonexistent behavior.
2. As a researcher, I want `lineage_orientation = :top_to_bottom` to render a
   vertical dendrogram correctly so that the rootvertex appears above the
   leaves.
3. As a researcher, I want `lineage_orientation = :bottom_to_top` to render the
   mirrored vertical orientation correctly so that the lineage axis can increase
   upward.
4. As a researcher, I want vertical orientation to preserve the existing
   independence of `axis_polarity` and `display_polarity` so that semantic
   polarity remains separate from screen embedding.
5. As a researcher, I want `show_y_axis = true` to produce a visible,
   meaningful y-axis on vertical layouts so that the public attribute is a real
   contract rather than a no-op.
6. As a researcher, I want `ylabel` to be displayed when the y-axis is shown so
   that vertical layouts can be labeled clearly.
7. As a researcher, I want `show_grid = true` to render an actual grid aligned
   with the visible screen axes so that grid visibility is not a false public
   promise.
8. As a researcher, I want horizontal layouts to continue to support
   `show_x_axis` and `xlabel` without regression so that current working plots
   remain stable.
9. As a researcher, I want `LineageAxis` decorations to mirror correctly across
   left, right, top, and bottom screen embeddings so that leaf labels, clade
   annotations, and scale-related decorations do not depend on hard-coded
   horizontal assumptions.
10. As a researcher, I want rendered label readability to be protected by a
    direct regression so that future refactors cannot reintroduce overlap while
    still satisfying geometric proxy tests.
11. As a maintainer, I want the source docstrings, vocabulary file, design
    notes, docs site, and examples to describe the same supported public
    surface so that review and user support are simpler.
12. As a maintainer, I want unsupported behavior outside this PRD's scope to
    fail fast and clearly rather than silently falling through a horizontal code
    path.
13. As a maintainer, I want the current Tier 1 PRD to remain the base document
    while this refinement document adds the missing repair layer so that earlier
    accepted work is not erased.
14. As a maintainer, I want downstream tranches to begin from a green state and
    end with tests, docs, and affected example renders passing so that
    architectural repair does not leave the repo in an indeterminate state.
15. As a maintainer, if an external breaking change is genuinely needed, I want
    explicit user approval plus a migration story so that internal cleanup does
    not silently become external contract breakage.
16. As a reviewer, I want the owning layer for orientation, axis decoration,
    and annotation reservation to be obvious so that future fixes repair the
    owner instead of adding local compensations.

## Authorized disruption boundary

- internal redesign allowed: Deep redesign is authorized within
  `LineageAxis`, `Layers`, `CoordTransform`, tests, examples, docs, design
  notes, workflow docs, and controlled vocabulary where needed to make audit
  items 1-3 correct by design rather than by local patching.
- internal redesign forbidden: Do not solve the contract drift with anti-fixes,
  placeholder public API, doc-only narrowing, or local horizontal special cases
  that leave ownership unclear. Do not expand this effort into an unrelated
  `Lineages.jl` redesign.
- external breaking changes allowed: Yes, but only with explicit user approval
  for the specific breaking change.
- required migration or compatibility obligations: Any user-approved external
  break must update docs, examples, design notes, and workflow documents in the
  same tranche; the tranche must also state whether compatibility shims or
  deprecations are being provided, and if not, it must include explicit
  migration notes for users.
- non-negotiable protections: Every tranche must begin and end in a green
  state, preserve approved behavior outside the scoped change, and satisfy the
  required test, docs, example, and visual verification gates.

## Current-state architecture

- existing owners:
  - `Accessors.jl` owns input normalization behind `LineageGraphAccessor`.
  - `Geometry.jl` owns process-coordinate and transverse-coordinate layout
    generation and stays mostly screen-orientation-agnostic.
  - `CoordTransform.jl` owns viewport-reactive data-to-pixel and pixel-to-data
    conversion.
  - `Layers.jl` owns plot-layer composition and routes `:radial` separately,
    but rectangular orientation handling still assumes a horizontal embedding in
    several places.
  - `LineageAxis.jl` owns the custom Makie block, camera setup, polarity
    inference, title/x-axis/xlabel bands, and the current shared side-annotation
    layout.
- existing failure modes:
  - The public contract advertises vertical orientations that are not
    implemented end to end.
  - `show_y_axis`, `show_grid`, and `ylabel` are public attributes but not yet
    wired into the rendered block.
  - Current tests prove lane geometry and anchor ownership more directly than
    they prove final rendered readability.
- existing coupling, duplication, or design debt:
  - Orientation semantics are duplicated across `STYLE-vocabulary.md`,
    `design/design.md`, `design/target-reference-capacities.md`, source
    docstrings, and tests.
  - `LineageAxis` is the natural owner of screen embedding, but it currently
    owns only a horizontal/radial subset of that policy.
  - Verification still relies too much on weak proxies for visual correctness.

## Target architecture

- major modules and responsibilities:
  - `Geometry.jl` continues to emit process/transverse layout geometry without
    embedding screen orientation into the layout core.
  - `LineageAxis.jl` becomes the explicit owner of all rectangular screen
    embeddings, including x/y camera reversal, screen-axis decoration placement,
    grid policy, tick placement, and annotation-side mirroring.
  - `Layers.jl` consumes the normalized `LineageAxis` orientation and
    decoration contract instead of re-deriving side and anchor policy locally.
  - `CoordTransform.jl` remains the owner of viewport-reactive pixel/data
    conversion and stays reusable across all orientations.
  - Test helpers become an explicit verification layer for render-level
    readability, using measured text bounding boxes, image-level comparison, or
    both.
- ownership boundaries:
  - `Geometry` owns lineage-graph geometry.
  - `LineageAxis` owns screen embedding and panel-owned decorations.
  - Individual layers own only their local rendering once the shared layout
    contract is supplied.
  - Tests own proof of public behavior and rendered readability.
- shared contracts and invariants:
  - A public `lineage_orientation` value is not considered supported unless the
    code, docs, examples, and tests all agree on it.
  - Public axis attributes must either be fully implemented or absent from the
    supported public surface.
  - Annotation placement must be derived from shared owner-level layout data,
    not recomputed independently by sibling layers.
  - Visual correctness for label readability must be verified at the rendered
    contract boundary.
- target deep modules and simplified interfaces:
  - A centralized orientation/decoration policy inside `LineageAxis`, or in a
    helper extracted from it, should translate `lineage_orientation` and
    `display_polarity` into camera, axis-owner, and annotation-owner decisions.
  - A reusable render-verification helper should provide a single place to
    measure or compare label extents for readability regressions.

## Implementation decisions

- This PRD refines `.workflow-docs/202604181600_tier1/01_prd.md`; it does not
  replace that document.
- This effort is scoped to `LineagesMakie.jl`. Open `Lineages.jl` editor tabs do
  not enlarge the approved architecture scope.
- Vertical orientations are required target-state functionality. They must be
  implemented, not scrubbed from the public contract.
- `Geometry.jl` should remain process/transverse oriented. Screen-axis embedding
  belongs in `LineageAxis`, not in the geometry core.
- `show_x_axis` and `xlabel` are screen x-axis controls. `show_y_axis` and
  `ylabel` are screen y-axis controls. The documentation must explicitly say
  which screen axis carries the lineage process coordinate for each
  `lineage_orientation`.
- `show_grid` must render actual grid behavior for the visible screen axes. It
  must not remain a reserved placeholder.
- Verification for this effort must include at least one direct rendered
  readability regression derived from `examples/lineageplot_ex2.jl`.
- If a tranche proposes an external break, that tranche must stop for user
  approval before implementation proceeds.

## Module design

- **Name**: `LineageAxis.jl`
  **Responsibility**: Own Makie block construction, rectangular and radial
  screen embedding, axis and grid rendering, panel-owned decoration layout, and
  polarity inference.
  **Interface**: `LineageAxis`, `reset_limits!`, orientation attributes, axis
  visibility attributes, label attributes, and shared decoration layout
  observables consumed by layers.
  **Tested**: Yes. Requires unit, integration, orientation-matrix, and
  render-level readability regressions.

- **Name**: `Layers.jl`
  **Responsibility**: Compose edges, markers, labels, highlights, and scale-bar
  rendering against precomputed geometry and `LineageAxis` layout contracts.
  **Interface**: `lineageplot`, `lineageplot!`, and layer constructors such as
  `leaflabellayer!` and `cladelabellayer!`.
  **Tested**: Yes. Must prove that layers consume shared anchors consistently in
  horizontal, vertical, and radial configurations.

- **Name**: `Geometry.jl`
  **Responsibility**: Compute lineage graph geometry in process/transverse
  coordinates for rectangular and circular layouts.
  **Interface**: `LineageGraphGeometry`, `rectangular_layout`,
  `circular_layout`, `boundingbox`.
  **Tested**: Yes. Existing geometry behavior should remain stable unless a
  user-approved change is explicitly required.

- **Name**: `CoordTransform.jl`
  **Responsibility**: Provide reactive pixel/data conversion used by annotation
  placement and render-level measurement.
  **Interface**: `data_to_pixel`, `pixel_to_data`,
  `pixel_offset_to_data_delta`, `register_pixel_projection!`.
  **Tested**: Yes. Must remain correct for non-isotropic axes and all supported
  orientations.

- **Name**: Docs, design notes, and vocabulary
  **Responsibility**: Describe only the supported public contract and preserve
  canonical terminology.
  **Interface**: `README.md`, `docs/src/index.md`, `design/design.md`,
  `design/target-reference-capacities.md`, `STYLE-vocabulary.md`, and relevant
  source docstrings.
  **Tested**: Yes. Verified by docs build, example execution, and contract
  alignment review.

- **Name**: Visual verification harness
  **Responsibility**: Prove rendered readability and non-overlap at the public
  contract boundary.
  **Interface**: Test helpers and regression artifacts built around
  `examples/lineageplot_ex2.jl` and affected integration tests.
  **Tested**: Yes. Its job is to strengthen the repo's proof surface for this
  class of regressions.

## Governance and controlled vocabulary

- list all governance documents that must be read line by line downstream:
  - `CONTRIBUTING.md`
  - `STYLE-julia.md`
  - `STYLE-docs.md`
  - `STYLE-git.md`
  - `STYLE-vocabulary.md`
  - `STYLE-architecture.md`
  - `STYLE-verification.md`
  - `STYLE-upstream-contracts.md`
  - `STYLE-workflow-docs.md`
  - `STYLE-makie.md`
- additional required project documents for downstream reading:
  - `.workflow-docs/202604181600_tier1/01_prd.md`
  - `.workflow-docs/202604181600_tier1/logs/log.20260423T0202--codex-audit-pre-tier-2.md`
  - `design/design.md`
  - `design/target-reference-capacities.md`
- vocabulary decisions or required updates:
  - `lineage_orientation`, `display_polarity`, `axis_polarity`,
    `process_coordinate`, `boundingbox`, and all existing ratified lineage-axis
    terms remain authoritative.
  - `:top_to_bottom` and `:bottom_to_top` remain supported canonical
    `lineage_orientation` values and must be implemented consistently if they
    remain in the vocabulary.
  - Documentation must distinguish screen-axis controls from process semantics.
- terms that must be avoided:
  - avoid unqualified `flip`, `invert`, `reverse axis`, or `vertical mode` when
    a canonical orientation or polarity term exists
  - avoid treating reserved or partial API as if it were supported behavior

## Primary upstream references

- `Makie/src/makielayout/blocks.jl`
  - constrains `Makie.@Block` field layout, attribute generation, and block
    ownership semantics for `LineageAxis`
- `Makie/src/makielayout/blocks/axis.jl`
  - constrains axis camera reversal, screen-axis protrusions, gridline
    ownership, and axis/block initialization patterns
- `Makie/src/layouting/text_boundingbox.jl`
  - constrains the public text-bounding-box helpers available for render-level
    measurement
- `Makie/src/basic_recipes/text.jl`
  - constrains `full_boundingbox(plot::Text, target_space)` and related
    full-text measurement behavior
- `Makie/src/figureplotting.jl`
  - constrains `plot!(ax::AbstractAxis, plot)` and the expectation that
    `reset_limits!` participates in axis display readiness
- `GraphMakie.jl/src/recipes.jl`
  - constrains the established reactive viewport/projection registration pattern
    for pixel-space label and angle computation

## Tranche gates

- required green checks at tranche start and end:
  - `julia --project=test test/runtests.jl`
  - `julia --project=docs docs/make.jl`
- required docs, example builds, or integration outputs:
  - rerun all affected examples
  - at minimum for this bundle, rerun `examples/lineageplot_ex1.jl` and
    `examples/lineageplot_ex2.jl`
  - update affected design docs, source docstrings, and docs site pages in the
    same tranche as the contract change
- migration and compatibility verification obligations:
  - any user-approved break must ship with updated docs and explicit migration
    notes in the same tranche
  - if compatibility shims or deprecations are promised, they must be tested
- regression expectations:
  - horizontal and radial behavior already working in Tier 1 must remain green
  - vertical orientation work must end with direct API tests and at least one
    direct render-level readability regression
  - no tranche may leave code and docs disagreeing on supported orientations or
    axis attributes

## Testing and verification decisions

- what must stay green throughout:
  - the full existing test suite
  - the full docs build
  - existing approved horizontal and radial plot behavior
- what examples or integration artifacts must be checked:
  - affected example renders, especially `examples/lineageplot_ex2.jl`
  - integration tests covering all supported rectangular orientations plus
    `:radial`
  - direct screen-axis tests for `show_x_axis`, `show_y_axis`, `xlabel`,
    `ylabel`, and `show_grid`
- what migration verification is required if breakage is allowed:
  - user approval recorded before implementation
  - docs and examples updated in the same tranche
  - explicit migration notes, with compatibility behavior tested if provided

## Out of scope

- unrelated redesign of `Lineages.jl`
- future capacities beyond this audit-fix bundle, including interval schemas,
  3D lineage embeddings, unrooted layouts, fan layouts, and other Tier 3 or
  Tier 4 work
- broad geometry-core redesign unless it is directly required by the ownership
  repair for orientations and screen-axis policy
- removing vertical orientations from the contract instead of implementing them

## Open questions

No blocking open questions remain at PRD time.

If any downstream tranche concludes that an externally visible break is truly
necessary, that tranche must stop and obtain explicit user approval together
with a concrete migration plan before implementation begins.

## Further notes

This document is a refinement layer on top of the original Tier 1 PRD and the
current pre-tier-2 audit log. Downstream tranches must preserve the mandates of
the original PRD while treating audit findings 1-3 as the motivating current
state diagnosis for this bundle.

The intended architectural direction is not merely to make the current tests
pass. It is to repair ownership so that `LineageAxis` honestly owns the full
screen-embedding contract it already claims publicly, and to leave behind a
verification surface that proves rendered readability rather than inferring it
from proxy geometry alone.
