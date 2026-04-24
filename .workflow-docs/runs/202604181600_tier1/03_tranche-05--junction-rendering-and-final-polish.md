# Tranche 5 tasking: junction rendering and final polish

Parent issue: `.workflow-docs/202604181600_tier1/logs/log.20260422T1908--codex-review-report.md`
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`
Tranche index: `.workflow-docs/202604181600_tier1/03_tasking.md`

## Governance

This tranche treats `.workflow-docs/202604181600_tier1/logs/log.20260422T1908--codex-review-report.md`
as the authoritative issue source. Do not modify the parent issue log or the
parent PRD.

All tasks must comply with:

- `STYLE-julia.md`
- `STYLE-git.md`
- `STYLE-docs.md`
- `STYLE-vocabulary.md`
- `CONTRIBUTING.md`

Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch, rebase, tag) are the human project owner's
responsibility.

Before starting this tranche, read completely, line by line:

- `.workflow-docs/202604181600_tier1/logs/log.20260422T1908--codex-review-report.md`
- `.workflow-docs/202604181600_tier1/01_prd.md`
- `.workflow-docs/202604181600_tier1/03_tasking.md`
- `STYLE-julia.md`
- `STYLE-git.md`
- `STYLE-docs.md`
- `STYLE-vocabulary.md`
- `CONTRIBUTING.md`
- `src/Geometry.jl`
- `src/Layers.jl`
- `src/LineageAxis.jl`
- `examples/lineageplot_ex1.jl`
- `examples/lineageplot_ex2.jl`
- `docs/src/index.md`
- `test/test_Layers.jl`
- `test/test_Integration.jl`

The local upstream Makie codebases are primary sources. For this tranche, read
the specific upstream files in:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/CairoMakie`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/GraphMakie.jl`

At minimum, read the upstream files needed to verify recipe draw-order,
compositing expectations, marker rendering, and any figure or docs behavior
needed for final public-facing polish.

This tranche must preserve the approved plotting contract from tranche 1 and the
finished visual architecture from tranches 2 through 4. It is not complete until
all of the following pass:

- `julia --project=test test/runtests.jl`
- `julia --project=docs docs/make.jl`

Because this tranche changes visuals, it must also rerun the affected example
scripts and verify the rendered output against the issue log.

## Tasks

### 13. Define the explicit junction rendering contract

**Type**: WRITE
**Output**: Edge rendering and internal vertex-marker rendering follow an
explicit contract that preserves visible junction continuity under default
styling.
**Depends on**: tranche 4 complete

Implement an intentional edge/junction/marker rendering contract so default
internal markers no longer visually punch holes in continuous branch
intersections. The fix must coordinate edge geometry, marker fill, marker
stroke, size, and draw order, not simply retune one default in isolation.

### 14. Add junction-continuity regressions under example styling

**Type**: TEST
**Output**: Tests catch the example-style visual hole at internal junctions, and
the full test suite plus docs build pass at the end of the tranche.
**Depends on**: 13

Add targeted regressions that use example-like styling, not only abstract
geometry, so the current compositing defect cannot silently return. Verify the
result against the examples, then run the full test suite and the full docs
build.

### 15. Refresh docs and run final end-to-end acceptance

**Type**: WRITE
**Output**: Public docs, examples, and docstrings match the final plotting and
rendering contract, and end-to-end acceptance closes the issue-log defects.
**Depends on**: 14

Perform the final public-facing cleanup: refresh examples, docstrings, and docs
text so they describe the finished plotting API, annotation behavior, scale-bar
behavior, and junction rendering contract. Then rerun the full acceptance path:
the affected examples, `julia --project=test test/runtests.jl`, and
`julia --project=docs docs/make.jl`. Use the issue log as the final checklist,
not only the test suite.
