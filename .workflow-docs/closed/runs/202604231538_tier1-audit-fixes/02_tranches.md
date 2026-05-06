# Tranches for LineagesMakie.jl tier 1 audit fixes

Parent PRD:
`.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`

This tranche file refines, and does not replace, the baseline Tier 1 workflow
document set rooted at `.workflow-docs/202604181600_tier1/01_prd.md`.

All tranches in this file inherit the following standing constraints:

- Every tranche must begin from a green state.
- Every tranche must end in a green, policy-compliant state.
- No tranche may silently narrow the public contract to avoid implementing the
  approved target state.
- `Geometry.jl` remains process/transverse oriented unless a later
  user-approved change explicitly broadens scope.
- Any tranche that discovers a necessary external breaking change must stop and
  obtain explicit user approval before implementation continues.
- Every tranche must preserve the ratified controlled vocabulary in
  `STYLE-vocabulary.md`.
- Every tranche must pass forward all governance, upstream-reading, and
  verification obligations into downstream tasking.

## Tranche 1: rectangular orientation ownership repair

**Type**: AFK
**Blocked by**: None — can start immediately

### Parent PRD

`.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`

### Governance and required reading

- Mandated line-by-line reading of:
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
- Mandated line-by-line reading of:
  - `.workflow-docs/202604181600_tier1/01_prd.md`
  - `.workflow-docs/202604181600_tier1/logs/log.20260423T0202--codex-audit-pre-tier-2.md`
  - `.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`
- Mandated line-by-line reading of implementation files:
  - `src/LineageAxis.jl`
  - `src/Layers.jl`
  - `src/CoordTransform.jl`
  - `src/Geometry.jl`
  - `test/test_LineageAxis.jl`
  - `test/test_Integration.jl`
- Mandated reading of design and contract files:
  - `design/design.md`
  - `design/target-reference-capacities.md`
- Mandated reading of upstream primary sources named in the PRD and required by
  this tranche:
  - `Makie/src/makielayout/blocks.jl`
  - `Makie/src/makielayout/blocks/axis.jl`
  - `Makie/src/figureplotting.jl`
  - `GraphMakie.jl/src/recipes.jl`

### What to build

Build the foundational owner repair for rectangular screen embedding.

This tranche is foundational. Its purpose is to make `LineageAxis` the honest
owner of all supported rectangular `lineage_orientation` behavior, including
`:left_to_right`, `:right_to_left`, `:top_to_bottom`, and `:bottom_to_top`.

This tranche must repair the owner, not patch symptom sites. The key outcome is
that screen embedding, camera reversal, axis-direction mapping, and
annotation-side mirroring are centralized in `LineageAxis` or in a closely
related helper owned by that layer, while `Geometry.jl` remains responsible for
process/transverse layout rather than screen-axis interpretation.

The tranche must leave the repo in a state where vertical orientations are
implemented end to end for rectangular layouts, or fail fast if an unsupported
combination truly remains out of scope. It must not rely on the previous
horizontal-only fallback path.

### How to verify

- **Manual**:
  - Run a vertical dendrogram example with `lineage_orientation = :top_to_bottom`
    and confirm the rootvertex appears above the leaves.
  - Run the mirrored vertical orientation with
    `lineage_orientation = :bottom_to_top` and confirm the direction is
    inverted without breaking `axis_polarity` / `display_polarity`
    independence.
  - Inspect the affected camera and annotation behavior in representative
    left-to-right, right-to-left, top-to-bottom, and bottom-to-top plots.
- **Automated**:
  - Add or update tests in `test/test_LineageAxis.jl` and
    `test/test_Integration.jl` for the full rectangular orientation matrix.
  - Run `julia --project=test test/runtests.jl`.
  - Run `julia --project=docs docs/make.jl`.

### Acceptance criteria

- [ ] Given a rectangular lineage graph, when `lineage_orientation` is set to
      `:top_to_bottom` or `:bottom_to_top`, then `LineageAxis` renders the
      correct vertical screen embedding instead of falling through a
      horizontal-only path.
- [ ] Given supported rectangular orientations, when annotation-bearing layers
      are rendered, then side or edge reservation mirrors consistently with the
      chosen screen embedding.
- [ ] Given the repaired owner, when horizontal and radial tests are rerun,
      then previously working behavior remains green.
- [ ] Given an actually unsupported combination, then the code fails fast and
      explicitly rather than silently producing plausible but wrong output.

### User stories addressed

- User story 1: public `lineage_orientation` values must work
- User story 2: implement `:top_to_bottom`
- User story 3: implement `:bottom_to_top`
- User story 4: preserve polarity independence
- User story 8: preserve horizontal axis behavior
- User story 9: mirror decoration ownership across embeddings
- User story 12: fail fast outside supported scope
- User story 16: repair the owning layer

## Tranche 2: screen-axis API completion and contract synchronization

**Type**: AFK
**Blocked by**: Tranche 1

### Parent PRD

`.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`

### Governance and required reading

- Mandated line-by-line reading of:
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
- Mandated line-by-line reading of:
  - `.workflow-docs/202604181600_tier1/01_prd.md`
  - `.workflow-docs/202604181600_tier1/logs/log.20260423T0202--codex-audit-pre-tier-2.md`
  - `.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`
  - `.workflow-docs/202604231538_tier1-audit-fixes/02_tranches.md`
- Mandated line-by-line reading of implementation and docs files:
  - `src/LineageAxis.jl`
  - `src/Layers.jl`
  - `docs/src/index.md`
  - `README.md`
  - `design/design.md`
  - `design/target-reference-capacities.md`
  - `STYLE-vocabulary.md`
  - `examples/lineageplot_ex1.jl`
  - `examples/lineageplot_ex2.jl`
  - `test/test_LineageAxis.jl`
  - `test/test_Integration.jl`
- Mandated reading of upstream primary sources named in the PRD and required by
  this tranche:
  - `Makie/src/makielayout/blocks.jl`
  - `Makie/src/makielayout/blocks/axis.jl`
  - `Makie/src/figureplotting.jl`

### What to build

Build the user-facing completion of the public screen-axis contract.

This tranche is user-facing and migration-oriented within the repository. It
must finish the public `LineageAxis` API promised by the docs by implementing
`show_y_axis`, `ylabel`, and `show_grid` as real behavior rather than reserved
placeholders.

It must also synchronize every public contract surface with the implemented
state: source docstrings, `STYLE-vocabulary.md`, design docs, README content if
affected, docs pages, and examples. After this tranche, a user reading the
public documentation should see only supported behavior, and every documented
attribute mentioned in the scoped area should be demonstrably live.

This tranche relies on the repaired ownership model from Tranche 1. It must not
recreate local orientation logic inside examples or docs to paper over code
gaps.

### How to verify

- **Manual**:
  - Render at least one vertical plot with `show_y_axis = true` and a non-empty
    `ylabel`, and confirm the y-axis and label are visibly present.
  - Render at least one plot with `show_grid = true` and confirm grid lines are
    visibly aligned with the active screen axes.
  - Inspect the updated docs/examples to confirm they describe only supported
    orientation and axis behavior.
- **Automated**:
  - Add or update API-level tests in `test/test_LineageAxis.jl` and
    `test/test_Integration.jl` for `show_y_axis`, `ylabel`, and `show_grid`.
  - Run `julia --project=test test/runtests.jl`.
  - Run `julia --project=docs docs/make.jl`.
  - Run `julia --project=examples examples/lineageplot_ex1.jl`.
  - Run `julia --project=examples examples/lineageplot_ex2.jl`.

### Acceptance criteria

- [ ] Given `show_y_axis = true` on a supported plot, when the figure is
      rendered, then a real y-axis appears and `ylabel` is displayed when
      provided.
- [ ] Given `show_grid = true`, when the figure is rendered, then the grid is
      visible and aligned with the active screen axes.
- [ ] Given the updated implementation, when docs, design notes, examples, and
      source docstrings are reviewed, then they describe one coherent public
      contract with no stale placeholder claims.
- [ ] Given a user-approved public surface, when the tranche ends, then no
      supported attribute in this scope remains a no-op placeholder.

### User stories addressed

- User story 5: implement `show_y_axis`
- User story 6: implement `ylabel`
- User story 7: implement `show_grid`
- User story 8: preserve horizontal axis behavior
- User story 9: preserve coordinated decoration behavior
- User story 11: synchronize docs and public contract
- User story 14: preserve green tranche boundaries

## Tranche 3: rendered readability hardening and release-state verification

**Type**: AFK
**Blocked by**: Tranche 1, Tranche 2

### Parent PRD

`.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`

### Governance and required reading

- Mandated line-by-line reading of:
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
- Mandated line-by-line reading of:
  - `.workflow-docs/202604181600_tier1/01_prd.md`
  - `.workflow-docs/202604181600_tier1/logs/log.20260423T0202--codex-audit-pre-tier-2.md`
  - `.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`
  - `.workflow-docs/202604231538_tier1-audit-fixes/02_tranches.md`
- Mandated line-by-line reading of verification-sensitive files:
  - `examples/lineageplot_ex2.jl`
  - `test/test_LineageAxis.jl`
  - `test/test_Layers.jl`
  - `test/test_Integration.jl`
  - `src/LineageAxis.jl`
  - `src/Layers.jl`
  - `src/CoordTransform.jl`
- Mandated reading of upstream primary sources named in the PRD and required by
  this tranche:
  - `Makie/src/layouting/text_boundingbox.jl`
  - `Makie/src/basic_recipes/text.jl`
  - `Makie/src/makielayout/blocks/axis.jl`
  - `GraphMakie.jl/src/recipes.jl`

### What to build

Build the stabilization and verification hardening layer for the repaired
contract.

This tranche is stabilization-focused. Its purpose is to strengthen proof at
the real contract boundary by adding direct render-level readability checks,
preferably measured text-bounding-box or image-level non-overlap regressions,
instead of relying only on lane geometry and anchor-position proxies.

This tranche must encode the historical bug class in a way that fails for the
old behavior and passes for the repaired behavior. It should use
`examples/lineageplot_ex2.jl` as the reference artifact unless a stronger or
more direct public example becomes available during implementation.

It also closes the bundle by rerunning the required verification gates so the
repository ends in a release-ready green state for this scope.

### How to verify

- **Manual**:
  - Render the example-derived verification figure and inspect that leaf labels,
    clade labels, and other relevant text remain readable and non-overlapping in
    the supported orientations covered by the bundle.
  - Inspect the chosen regression mechanism and confirm it would have failed for
    the historical weak-proxy state.
- **Automated**:
  - Add direct render-level regression coverage to `test/test_LineageAxis.jl`,
    `test/test_Layers.jl`, and/or `test/test_Integration.jl`.
  - Run `julia --project=test test/runtests.jl`.
  - Run `julia --project=docs docs/make.jl`.
  - Run `julia --project=examples examples/lineageplot_ex1.jl`.
  - Run `julia --project=examples examples/lineageplot_ex2.jl`.

### Acceptance criteria

- [ ] Given the example-derived regression case, when text placement would
      overlap or become unreadable, then the new test fails directly rather than
      passing on lane geometry alone.
- [ ] Given the repaired implementation, when render-level verification is run,
      then label readability remains acceptable across the supported scoped
      cases.
- [ ] Given the full bundle, when the tranche ends, then tests, docs, and
      affected examples all pass from a clean green checkpoint.
- [ ] Given future refactors in this area, then the repository retains a direct
      proof surface against this regression class.

### User stories addressed

- User story 10: add direct readability regressions
- User story 11: preserve public contract coherence
- User story 14: finish in a green verified state
