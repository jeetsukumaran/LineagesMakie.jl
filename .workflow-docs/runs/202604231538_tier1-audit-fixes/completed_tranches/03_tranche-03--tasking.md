# Tasks for Tranche 3: rendered readability hardening and release-state verification

Parent tranche: Tranche 3
Parent PRD: `.workflow-docs/202604231538_tier1-audit-fixes/01_prd.md`

This tranche remains pending after completed Tranches 1 and 2 and the
completed immediate-action tranche `IA20260423-01`.

It is not an ownership-repair tranche. Its job is to add direct proof at the
rendered contract boundary on top of the now-completed owner-normalized,
multi-surface-verified baseline.

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
- `.workflow-docs/202604231538_tier1-audit-fixes/completed_tranches/03_tranche-01--tasking.md`
- `.workflow-docs/202604231538_tier1-audit-fixes/completed_tranches/03_tranche-02--tasking.md`
- `.workflow-docs/202604231538_tier1-audit-fixes/completed_tranches/03_tranche-IA20260423-01--tasking.md`
- `.workflow-docs/202604231538_tier1-audit-fixes/log.20260423T2220--layer-ownership-issues.md`

Read-only git and shell commands may be used freely. Mutating git operations
such as commit, merge, push, branch, rebase, and tag remain the human project
owner's responsibility unless the user explicitly instructs otherwise.

## Required revalidation before implementation

- Read the tranche, parent PRD, archived Tranche 1 and Tranche 2 tasking
  files, and the completed immediate-action tasking file in full.
- Confirm that completed Tranches 1 and 2 plus `IA20260423-01` are the current
  behavioral baseline.
- Read the relevant code, tests, docs, and examples in full:
  - `src/LineageAxis.jl`
  - `src/Layers.jl`
  - `src/CoordTransform.jl`
  - `examples/lineageplot_ex2.jl`
  - `test/test_LineageAxis.jl`
  - `test/test_Layers.jl`
  - `test/test_Integration.jl`
  - `docs/src/index.md`
- Read the cited upstream primary sources in full where they constrain the
  work:
  - `Makie/src/layouting/text_boundingbox.jl`
  - `Makie/src/basic_recipes/text.jl`
  - `Makie/src/makielayout/blocks/axis.jl`
  - `GraphMakie.jl/src/recipes.jl`
- Re-check the user-authorized disruption boundary before making deep changes.
- Revalidate the diagnosis against current reality before editing:
  - `LineageAxis` now owns canonical owner-normalization for overlapping public
    semantics, and multi-surface verification already covers constructor-owned
    `LineageAxis`, `lineageplot!(lax, ...; kwargs...)`, the non-mutating
    `lineageplot(...; axis = (...))` wrapper, and the plain `Axis` path where
    plot ownership is still intentional.
  - the current remaining gap is proof-surface strength, not ownership repair:
    tests still primarily prove lane geometry, anchor placement, orientation
    routing, and decoration visibility rather than direct rendered text
    overlap, clipping, or unreadability
  - `examples/lineageplot_ex2.jl` remains the strongest in-tree public artifact
    for this tranche because its top-to-bottom panel exercises the historical
    vertical regression and includes both leaf labels and clade labels
  - the existing example-style integration coverage is now aligned with that
    public artifact and should be extended, not replaced with a different shape
  - no reusable helper yet proves pairwise non-overlap or unclipped placement
    for actual rendered Makie `Text` plots on the current baseline
  - Makie still exposes `text_bb`, `boundingbox(plot::Text, ...)`, and
    `full_boundingbox(plot::Text, ...)` as the primary-source measurement path;
    if that path turns out to be too weak or too awkward for the real failure
    mode, document why and move to a stronger image-level proof instead
- If the diagnosis no longer matches reality, stop and raise that before
  changing code.

## Tranche execution rule

This tranche is verification-first. It may introduce tightly scoped test-side
helpers and only the minimum product-side instrumentation genuinely required to
observe the rendered contract boundary.

This tranche must build on, not duplicate or reopen, the completed
owner-normalization and multi-surface contract work from Tranches 1, 2, and
`IA20260423-01` unless revalidation proves that baseline is still wrong.

The final proof surface must fail for the actual historical defect class:
overlapping, clipped, or unreadable leaf labels and clade labels in the
example-derived vertical case. A geometry-only or anchor-only check is still a
weak proxy and remains insufficient as the closing proof.

Checkpoint policy:

- Tasks 1-3 must leave the repository buildable and in a targeted green state
  for the files they touch.
- Task 4 is the tranche-closing gate and must finish with the tranche's full
  required green state, including `julia --project=test test/runtests.jl`,
  `julia --project=docs docs/make.jl`,
  `julia --project=examples examples/lineageplot_ex1.jl`, and
  `julia --project=examples examples/lineageplot_ex2.jl`.

## Tasks

### 1. Establish the strongest rendered-text proof mechanism for the current baseline

**Type**: WRITE
**Output**: the test suite has a reusable, primary-source-backed mechanism for
measuring actual rendered text extents, overlap, or clipping on the current
Makie baseline.
**Depends on**: none

Add the minimum helper infrastructure needed for direct render-level
readability checks, using the strongest suitable primary-source-backed
mechanism available from Makie. Prefer a measurement path that operates on
actual rendered `Text` plots from the layer or blockscene context rather than
on synthetic strings alone. This may live in existing test files or in tightly
scoped test-side helpers, but it should be reusable enough that future
regressions in this class can use it without re-inventing the measurement path.
Use `Makie/src/layouting/text_boundingbox.jl` and `Makie/src/basic_recipes/text.jl`
as the primary sources for how text bounding boxes are defined and measured,
and avoid inventing an unverified local notion of text extent. If direct
bounding-box measurement proves insufficient for the real failure mode, record
that and switch to a stronger image-level proof rather than forcing a weak
proxy. End the task by demonstrating that the helper works on a focused case
and leaves the repo in a targeted green state.

### 2. Add direct leaf-label and clade-label readability regressions

**Type**: TEST
**Output**: direct non-overlap or unclipped-placement regressions protect the
actual rendered label layers instead of only their lane geometry.
**Depends on**: 1

Strengthen `test/test_Layers.jl` and/or `test/test_LineageAxis.jl` with direct
render-level checks for text-bearing layers on the current owner-normalized
baseline. Cover both leaf labels and clade labels, and ensure the regressions
operate on actual rendered text extents or a stronger documented equivalent.
Prefer cases that reflect the vertical top/bottom annotation lanes relevant to
the historical regression, but do not let the tests collapse back to anchor or
lane-position assertions alone. End the task by running targeted tests for the
touched files and keeping the repo in an acceptable checkpoint state.

### 3. Encode the example-derived public proof surface

**Type**: TEST
**Output**: the public top-to-bottom example path has a direct render-level
proof surface aligned with `examples/lineageplot_ex2.jl`.
**Depends on**: 1, 2

Strengthen `test/test_Integration.jl` with a regression derived from
`examples/lineageplot_ex2.jl`, using the current public example shape rather
than inventing a different demonstration case. At minimum, the proof must cover
the top-to-bottom panel and directly protect both leaf-label and clade-label
readability in that public path. The regression should fail for overlap,
clipping, or another precisely documented unreadability condition, and it must
not be satisfiable by correct orientation routing, lane geometry, or decoration
visibility alone. End the task by running the tranche-relevant targeted tests
and example check, and confirm that the chosen proof surface would not have
passed on the historical weak-proxy state.

### 4. Close the tranche with full verification and proof-surface review

**Type**: REVIEW
**Output**: Tranche 3 ends in a fully green, policy-compliant state, with an
explicit review that the new verification really protects the intended
historical bug class.
**Depends on**: 1, 2, 3

Review the completed tranche against the parent PRD, the parent tranche
document, the archived Tranche 1 and Tranche 2 tasking files, the completed
immediate-action tranche, and the ownership-risk log. Confirm that the chosen
measurement or image-level path truly verifies the rendered contract boundary,
that it is not just another geometry proxy in disguise, that it would have
caught the class of defect called out in the audit log, and that the tranche
did not reopen already-settled owner responsibilities without evidence. Then
run the tranche-closing gates: `julia --project=test test/runtests.jl`,
`julia --project=docs docs/make.jl`,
`julia --project=examples examples/lineageplot_ex1.jl`, and
`julia --project=examples examples/lineageplot_ex2.jl`. If the final review
shows the proof surface is still too weak, strengthen it before treating the
tranche as complete.

---
