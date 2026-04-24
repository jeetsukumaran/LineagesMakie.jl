# Tasks for Immediate Action Tranche IA20260423-01: canonical owner-normalization hardening

Parent tranche: Immediate Action IA20260423-01
Parent PRD: `.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`

This tranche is an additive follow-up on top of completed Tranches 1 and 2.
It is triggered by the ownership-risk analysis recorded in:

- `.workflow-docs/202604231538_tier1-audit-fixes/log.20260423T2220--layer-ownership-issues.md`

It does not replace or silently rewrite Tranche 3. Tranche 3 remains the
pending render-level readability and proof-surface tranche.

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
- `.workflow-docs/202604231538_tier1-audit-fixes/03_tranche-03--tasking.md`
- `.workflow-docs/202604231538_tier1-audit-fixes/log.20260423T2220--layer-ownership-issues.md`

Read-only git and shell commands may be used freely. Mutating git operations
such as commit, merge, push, branch, rebase, and tag remain the human project
owner's responsibility unless the user explicitly instructs otherwise.

## Required revalidation before implementation

- Read the parent PRD, the archived Tranche 1 and Tranche 2 tasking files, and
  the pending Tranche 3 tasking file in full.
- Confirm that completed Tranches 1 and 2 are the current behavioral baseline.
- Read the relevant code, tests, docs, and examples in full:
  - `src/LineageAxis.jl`
  - `src/Layers.jl`
  - `examples/lineageplot_ex2.jl`
  - `test/test_LineageAxis.jl`
  - `test/test_Integration.jl`
  - `docs/src/index.md`
  - `design/design.md`
- Read the cited upstream primary sources in full where they constrain the work:
  - `Makie/src/makielayout/blocks.jl`
  - `Makie/src/makielayout/blocks/axis.jl`
  - `Makie/src/figureplotting.jl`
  - `GraphMakie.jl/src/recipes.jl`
- Re-check the user-authorized disruption boundary before making deep changes.
- Revalidate the diagnosis against current reality before editing:
  - some public semantics still enter through more than one supported surface,
    especially where `LineageAxis` attributes and `LineagePlot` recipe
    attributes overlap
  - `lineageplot!(::LineageAxis, ...)` still open-codes owner-to-plot
    reconciliation instead of routing it through a single named normalization
    helper
  - the recent regression fix proves the current owner model is much better,
    but also proves the adapter seam is still a real maintenance risk
  - the non-mutating `lineageplot(...; axis = (...))` path and the mutating
    `lineageplot!(lax, ...)` path must continue to agree on owner-resolved
    semantics
- If the diagnosis no longer matches reality, stop and raise that before
  changing code.

## Tranche execution rule

This tranche is a hardening tranche. It may refactor `LineageAxis` internals
and their immediate tests where needed, but it must not invent a speculative
3D or N-dimensional abstraction. Keep the new abstraction explicitly 2D and
`LineageAxis`-local unless revalidation proves a broader owner already exists
today.

The goal is to make owner-normalized public semantics harder to misroute in the
future by introducing one explicit normalization point and proving it across
all supported entry surfaces. This tranche must not be used to claim that
render-level readability proof is complete; Tranche 3 remains separately
required.

Checkpoint policy:

- Tasks 1-3 must leave the repository buildable and in a targeted green state
  for the files they touch.
- Task 4 is the tranche-closing gate and must finish with the tranche's full
  required green state, including `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`, and
  `julia --project=examples examples/lineageplot_ex2.jl`.

## Tasks

### 1. Extract a canonical `LineageAxis` owner-normalization helper

**Type**: WRITE
**Output**: `LineageAxis` has one explicit helper or tightly scoped local
contract object that resolves owner-normalized semantics before calling the
inner `LineagePlot`.
**Depends on**: none

Refactor [src/LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/LineageAxis.jl) so the owner-to-plot handoff is no longer open-coded inside `lineageplot!(::LineageAxis, ...)`. Introduce one named normalization point that resolves precedence, owner-forwarded semantics, and derived defaults for the inner plot call. Build on the existing `_lineage_orientation_policy` and related owner helpers rather than inventing a second policy layer. Keep the abstraction local to the current 2D `LineageAxis` problem; do not generalize it for hypothetical 3D work. End the task with targeted verification of the touched code path.

### 2. Route all supported `LineageAxis` entry surfaces through the canonical owner handoff

**Type**: WRITE
**Output**: the mutating `LineageAxis` path and the non-mutating `lineageplot(...; axis = (...))` path share one owner-normalized contract and no longer depend on duplicated reconciliation logic.
**Depends on**: 1

Update [src/LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/LineageAxis.jl), and [src/Layers.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/src/Layers.jl) only if the recipe-facing contract truly needs tightening, so every supported `LineageAxis` entry surface uses the same owner-normalized semantics. Remove any remaining duplicated merge logic for the same semantic inside `LineageAxis`. Preserve support for plain `Axis` plotting where it is intentionally plot-owned rather than axis-owned. End the task by rerunning the touched targeted tests and keeping the repository in an acceptable checkpoint state.

### 3. Add multi-surface regressions aligned with the real public artifacts

**Type**: TEST
**Output**: regression coverage directly protects every supported entry surface
for owner-normalized semantics, including the real top-to-bottom example shape.
**Depends on**: 1, 2

Strengthen [test/test_LineageAxis.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_LineageAxis.jl) and [test/test_Integration.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/test/test_Integration.jl) so the same owner-normalized semantic is verified through each supported surface that accepts it. At minimum, cover the `LineageAxis` constructor surface, `lineageplot!(lax, ...; kwargs...)`, the non-mutating `lineageplot(...; axis = (...))` wrapper, and the plain `Axis` path where the semantic remains supported there. Keep [examples/lineageplot_ex2.jl](/home/jeetsukumaran/site/storage/local/computing/research/20260418_LineagesMakie.jl/LineagesMakie.jl/examples/lineageplot_ex2.jl) aligned as the public reference artifact for the top-to-bottom panel rather than letting the integration smoke drift to a different shape. End the task by running the tranche-relevant targeted tests and example check.

### 4. Close the tranche with full verification and follow-up impact review

**Type**: REVIEW
**Output**: the immediate-action tranche ends fully green, and there is an
explicit review of whether pending Tranche 3 needs only revalidation later or a
real rewrite.
**Depends on**: 1, 2, 3

Review the completed hardening against the parent PRD, the archived Tranche 1 and Tranche 2 tasking, the pending Tranche 3 tasking, and the ownership-risk log. Confirm that the new abstraction is a real owner-normalization improvement rather than a cosmetic wrapper, that the public entry surfaces now agree on the resolved semantics they support, and that the tranche did not smuggle in speculative 3D architecture. Then run the tranche-closing gates: `julia --project=test test/runtests.jl`, `julia --project=docs docs/make.jl`, and `julia --project=examples examples/lineageplot_ex2.jl`. Finish by stating explicitly whether Tranche 3 merely needs later revalidation against the new baseline or whether its current tasking has become materially stale and must be rewritten before execution.

---
