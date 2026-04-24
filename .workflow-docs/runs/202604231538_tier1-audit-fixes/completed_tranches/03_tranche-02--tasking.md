# Tasks for Tranche 2: screen-axis API completion and contract synchronization

Parent tranche: Tranche 2
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
- Confirm that Tranche 1 has completed and that its owner-level rectangular
  orientation policy is the current baseline.
- Read the relevant code, tests, docs, and examples in full:
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
- Read the cited upstream primary sources in full where they constrain the work:
  - `Makie/src/makielayout/blocks.jl`
  - `Makie/src/makielayout/blocks/axis.jl`
  - `Makie/src/figureplotting.jl`
- Re-check the user-authorized disruption boundary before making deep changes.
- Revalidate the diagnosis against current reality before editing:
  - `show_y_axis`, `show_grid`, and `ylabel` are still declared publicly on
    `LineageAxis`
  - current `LineageAxis` wiring still only renders title, `xlabel`, and the
    x-axis
  - public docs, design notes, vocabulary, examples, and source docstrings
    still contain claims that must be synchronized with the live API
- If the tranche diagnosis no longer matches reality, stop and raise that
  before changing code.

## Tranche execution rule

This tranche may redesign `LineageAxis` internals where needed to make the
screen-axis API real, but it must build on the owner established in Tranche 1
rather than reintroducing duplicated orientation logic. Public contract
synchronization is mandatory in this tranche: if behavior changes, the relevant
docs, examples, vocabulary, and source docstrings must change in the same
tranche. External breaking changes still require explicit user approval before
implementation proceeds.

Checkpoint policy:

- Tasks 1-3 must leave the repository buildable and in a targeted green state
  for the files they touch.
- Task 4 is the tranche-closing gate and must finish with the tranche's full
  required green state, including `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, and the affected example runs.

## Tasks

### 1. Implement `show_y_axis` and `ylabel` as live `LineageAxis` behavior

**Type**: WRITE
**Output**: `LineageAxis` renders a real y-axis and `ylabel` on supported
screen embeddings instead of exposing them as placeholder-only attributes.
**Depends on**: none

Update [src/LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/LineageAxis.jl) so `show_y_axis` and `ylabel` participate in the block-owned decoration model as actual rendered behavior. Build on the orientation owner established in Tranche 1 rather than inventing a separate vertical-only code path. Use Makie axis/block conventions from `Makie/src/makielayout/blocks/axis.jl` as the reference for axis ownership and placement behavior, while preserving the package’s intentionally simplified custom-block design. End the task by verifying the changed code path with targeted tests or a minimal focused render and keeping the repo in an acceptable checkpoint state.

### 2. Implement `show_grid` as real screen-axis grid behavior

**Type**: WRITE
**Output**: `show_grid` becomes a live, orientation-aware public API whose grid
aligns with the active screen axes on supported embeddings.
**Depends on**: 1

Extend [src/LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/LineageAxis.jl), and any tightly related helper code it needs, so `show_grid` is no longer a reserved placeholder. Keep grid ownership in `LineageAxis`; do not scatter grid semantics into sibling layers. Follow the owner-level orientation model already established, and ensure the grid behavior is consistent with whichever screen axis carries the process coordinate. End the task by checking targeted rendering or tests that prove the grid is truly visible and aligned, without waiting for the broader docs migration step.

### 3. Synchronize source docstrings, docs, vocabulary, design notes, and examples with the live contract

**Type**: MIGRATE
**Output**: the user-facing contract is coherent across code, docs, design
notes, examples, and controlled vocabulary for the scoped API surface.
**Depends on**: 1, 2

Update the repository’s public contract surfaces so they describe only the now-live, supported behavior in this tranche’s scope. Touch [src/LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/LineageAxis.jl), [src/Layers.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/Layers.jl) where relevant, [STYLE-vocabulary.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/STYLE-vocabulary.md), [design/design.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/design/design.md), [design/target-reference-capacities.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/design/target-reference-capacities.md), [docs/src/index.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/docs/src/index.md), [README.md](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/README.md) if needed, and the relevant examples. Preserve sentence case and other doc-style rules from `STYLE-docs.md`. Make the docs honestly reflect the implemented surface; do not silently retain stale placeholder wording.

### 4. Add public API regressions and close the tranche with full verification

**Type**: TEST
**Output**: tests and example verification protect the live y-axis/grid API and
the synchronized contract, and the tranche ends fully green.
**Depends on**: 1, 2, 3

Strengthen [test/test_LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_LineageAxis.jl) and [test/test_Integration.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_Integration.jl) so the public screen-axis API is directly protected: visible y-axis rendering, `ylabel`, `show_grid`, and documented usage paths should all be encoded in regression tests rather than left to manual inspection alone. End the tranche by running `julia --project=test test/runtests.jl`, `julia --project=docs docs/make.jl`, `julia --project=examples examples/lineageplot_ex1.jl`, and `julia --project=examples examples/lineageplot_ex2.jl`. If the final check shows lingering contract drift between docs and code, correct it before treating the tranche as complete.

---
