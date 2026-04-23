# Tasks for Tranche 3: rendered readability hardening and release-state verification

Parent tranche: Tranche 3
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
- Confirm that Tranches 1 and 2 have completed and that their repaired owner
  model plus synchronized public contract are the current baseline.
- Read the relevant code, tests, docs, and examples in full:
  - `src/LineageAxis.jl`
  - `src/Layers.jl`
  - `src/CoordTransform.jl`
  - `examples/lineageplot_ex2.jl`
  - `test/test_LineageAxis.jl`
  - `test/test_Layers.jl`
  - `test/test_Integration.jl`
- Read the cited upstream primary sources in full where they constrain the work:
  - `Makie/src/layouting/text_boundingbox.jl`
  - `Makie/src/basic_recipes/text.jl`
  - `Makie/src/makielayout/blocks/axis.jl`
  - `GraphMakie.jl/src/recipes.jl`
- Re-check the user-authorized disruption boundary before making deep changes.
- Revalidate the diagnosis against current reality before editing:
  - current tests still primarily protect lane geometry, anchor positions, and
    blockscene placement rather than render-level readability
  - `examples/lineageplot_ex2.jl` is still the best in-tree public artifact for
    a non-overlap regression unless a stronger example now exists after
    Tranche 2
  - Makie still exposes `text_bb`, `boundingbox(plot::Text, ...)`, and
    `full_boundingbox(plot::Text, ...)` as the primary-source measurement path
- If the tranche diagnosis no longer matches reality, stop and raise that
  before changing code.

## Tranche execution rule

This tranche is verification-first. It may introduce helper code or test-side
infrastructure where needed, but the goal is to strengthen proof at the real
contract boundary, not to add yet another indirect proxy. The final regression
must fail for unreadable or overlapping rendered text, or for a precisely
documented equivalent render-level failure mode. If the chosen mechanism turns
out to be too weak, stop and choose a stronger one before closing the tranche.

Checkpoint policy:

- Tasks 1-2 must leave the repository buildable and in a targeted green state
  for the files they touch.
- Task 3 is the tranche-closing gate and must finish with the tranche's full
  required green state, including `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, and the affected example runs.

## Tasks

### 1. Build a reusable render-level readability verification path

**Type**: WRITE
**Output**: the test suite has a clear, reusable mechanism for measuring or
comparing rendered text readability at the actual visual contract boundary.
**Depends on**: none

Add the minimum helper infrastructure needed for direct render-level readability checks, using the strongest suitable primary-source-backed mechanism available from Makie. This may live in existing test files or in tightly scoped test-side helpers, but it should be reusable enough that future regressions in this class can use it without re-inventing the measurement path. Use `Makie/src/layouting/text_boundingbox.jl` and `Makie/src/basic_recipes/text.jl` as the primary sources for how text bounding boxes are defined and measured, and avoid inventing an unverified local notion of text extent. End the task by demonstrating that the helper works on a focused example and leaves the repo in a targeted green state.

### 2. Encode example-derived non-overlap regressions

**Type**: TEST
**Output**: at least one regression derived from `examples/lineageplot_ex2.jl`
fails on unreadable or overlapping text instead of passing on lane geometry
alone.
**Depends on**: 1

Strengthen [test/test_LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_LineageAxis.jl), [test/test_Layers.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_Layers.jl), and/or [test/test_Integration.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_Integration.jl) with a regression that uses [examples/lineageplot_ex2.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/examples/lineageplot_ex2.jl) or a directly derived equivalent as its public reference artifact. Keep the test aimed at the real failure mode: label overlap, clipping, or unreadability in the rendered result. The regression should not be satisfiable by correct lane geometry alone. End the task by running the tranche-relevant tests and confirming the new regression would have failed on the historical weak-proxy state.

### 3. Close the tranche with full verification and proof-surface review

**Type**: REVIEW
**Output**: Tranche 3 ends in a fully green, policy-compliant state, with an
explicit review that the new verification really protects the intended
historical bug class.
**Depends on**: 1, 2

Review the completed tranche against the parent PRD and tranche document. Confirm that the chosen measurement or image-level path truly verifies the rendered contract boundary, that it is not just another geometry proxy in disguise, and that it would have caught the class of defect called out in the audit log. Then run the tranche-closing gates: `julia --project=test test/runtests.jl`, `julia --project=docs docs/make.jl`, `julia --project=examples examples/lineageplot_ex1.jl`, and `julia --project=examples examples/lineageplot_ex2.jl`. If the final review shows the proof surface is still too weak, strengthen it before treating the tranche as complete.

---
