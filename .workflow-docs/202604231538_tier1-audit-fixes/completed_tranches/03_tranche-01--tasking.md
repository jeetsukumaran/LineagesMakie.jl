# Tasks for Tranche 1: rectangular orientation ownership repair

Parent tranche: Tranche 1
Parent PRD: `.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`

## Governance

All tasks in this tranche must comply with the following documents, read line
by line:

- `CONTRIBUTING.md`
- `STYLE-julia.md`
- `STYLE-git.md`
- `STYLE-docs.md`
- `STYLE-vocabulary.md`
- `STYLE-architecture.md`
- `STYLE-verification.md`
- `STYLE-upstream-contracts.md`
- `STYLE-workflow-docs.md`
- `STYLE-makie.md`

All tasks must also read, line by line:

- `.workflow-docs/202604181600_tier1/01_prd.md`
- `.workflow-docs/202604181600_tier1/logs/log.20260423T0202--codex-audit-pre-tier-2.md`
- `.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`
- `.workflow-docs/202604231538_tier1-audit-fixes/02_tranches.md`

Read-only git and shell commands may be used freely. Mutating git operations
such as commit, merge, push, branch, rebase, and tag remain the human project
owner's responsibility unless the user explicitly instructs otherwise.

## Required revalidation before implementation

- Read the tranche and parent PRD in full.
- Read the relevant code, tests, docs, and examples in full:
  - `src/LineageAxis.jl`
  - `src/Layers.jl`
  - `src/CoordTransform.jl`
  - `src/Geometry.jl`
  - `test/test_LineageAxis.jl`
  - `test/test_Layers.jl`
  - `test/test_Integration.jl`
  - `design/design.md`
  - `design/target-reference-capacities.md`
  - `STYLE-vocabulary.md`
- Read the cited upstream primary sources in full where they constrain the work:
  - `Makie/src/makielayout/blocks.jl`
  - `Makie/src/makielayout/blocks/axis.jl`
  - `Makie/src/figureplotting.jl`
  - `GraphMakie.jl/src/recipes.jl`
- Re-check the user-authorized disruption boundary before making deep changes.
- Revalidate the diagnosis against current reality before editing:
  - the public docs and vocabulary still describe `:top_to_bottom` and
    `:bottom_to_top`
  - `src/LineageAxis.jl` still documents only `:left_to_right`,
    `:right_to_left`, and `:radial`
  - `reset_limits!` still treats every non-`:radial` case as horizontal
  - rectangular shared annotation layout and layer consumers still assume
    `:left` / `:right` or `:radial`, not `:top` / `:bottom`
- If the tranche diagnosis no longer matches reality, stop and raise that
  before changing code.

## Tranche execution rule

This tranche may redesign internals within `LineageAxis`, `Layers`, and closely
related helpers where needed, but it must repair the owner rather than stack
local compensations. `Geometry.jl` must remain process/transverse oriented; do
not move screen-embedding policy into the geometry core. External breaking
changes require explicit user approval before implementation proceeds.

Checkpoint policy:

- Tasks 1-3 must leave the repository buildable and in a targeted green state
  for the files they touch.
- Task 4 is the tranche-closing gate and must finish with the tranche's full
  required green state, including `julia --project=test test/runtests.jl` and
  `julia --project=docs docs/make.jl`.

## Tasks

### 1. Establish an owner-level rectangular orientation policy

**Type**: WRITE
**Output**: `LineageAxis` has a single validated orientation-policy path for
rectangular embeddings, and `reset_limits!` no longer falls back to a
horizontal-only interpretation for vertical modes.
**Depends on**: none

Introduce or extract the owner-level policy in [src/LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/LineageAxis.jl) that defines how supported rectangular `lineage_orientation` values map process and transverse coordinates onto screen x/y direction, including the interaction with `display_polarity`. Use Makie's axis-camera reversal pattern from `Makie/src/makielayout/blocks/axis.jl` as the primary source rather than inventing a local convention. Touch the public docstrings in `src/LineageAxis.jl` only as needed to keep the modified source honest, but do not attempt the broad docs/design synchronization reserved for Tranche 2. End the task by verifying that the module builds cleanly and that the touched orientation-sensitive tests are passing for the current checkpoint.

### 2. Propagate the orientation policy through decoration ownership and layer consumers

**Type**: WRITE
**Output**: shared decoration layout, orientation-aware defaults, and label or clade layer consumption all honor the repaired rectangular owner for left, right, top, and bottom embeddings.
**Depends on**: 1

Update [src/LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/LineageAxis.jl) and [src/Layers.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/Layers.jl) so the new rectangular orientation policy is consumed consistently by annotation measurement, shared decoration layout, `lineageplot!` orientation defaults, and any label or clade placement helpers that currently special-case only `:left`, `:right`, or `:radial`. Repair the owner-level layout contract rather than inserting one-off vertical offsets inside individual layers. Use the existing shared-anchor patterns and the current radial special case as references for how ownership should be centralized, while intentionally replacing the current left-right-only rectangular assumption. End the task by rerunning the touched targeted tests and confirming the repository remains in an acceptable checkpoint state.

### 3. Add direct rectangular orientation and vertical-annotation regressions

**Type**: TEST
**Output**: the test suite directly covers the full rectangular orientation matrix, rejects silent horizontal fallback for vertical modes, and proves shared annotation behavior for the new vertical embeddings.
**Depends on**: 1, 2

Strengthen [test/test_LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_LineageAxis.jl), [test/test_Layers.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_Layers.jl), and [test/test_Integration.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_Integration.jl) so the historical defect is encoded directly. Use the current left-to-right, right-to-left, and radial tests as the baseline pattern, then add vertical orientation coverage, orientation-policy assertions, and shared-annotation assertions that would fail on the old horizontal fallback path. Keep horizontal and radial regressions green while expanding the rectangular matrix. End the task by running the tranche-relevant test coverage for the changed files.

### 4. Close the tranche with full verification and diagnosis review

**Type**: REVIEW
**Output**: Tranche 1 ends in a fully green, policy-compliant state, and the implementation is reviewed against the original diagnosis to confirm the owner was repaired rather than cosmetically patched.
**Depends on**: 1, 2, 3

Review the final Tranche 1 result against the parent PRD and tranche document. Confirm that vertical orientations are actually implemented end to end for rectangular layouts, that shared decoration ownership no longer depends on a horizontal-only fallback, and that no unauthorized external contract break was introduced. Run the tranche-closing gates: `julia --project=test test/runtests.jl` and `julia --project=docs docs/make.jl`. If a simple manual vertical demo is needed to validate the screen embedding and annotation behavior, use a temporary local plot or an existing test-style figure rather than broadening scope into public example migration, which belongs to Tranche 2. If the review reveals that the tranche diagnosis was only partially repaired, stop and correct that before treating the tranche as complete.

---
