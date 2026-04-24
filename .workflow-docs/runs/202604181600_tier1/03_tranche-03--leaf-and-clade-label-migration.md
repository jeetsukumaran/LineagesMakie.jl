# Tranche 3 tasking: leaf and clade label migration

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
- `src/LineageAxis.jl`
- `src/Layers.jl`
- `src/CoordTransform.jl`
- `examples/lineageplot_ex2.jl`
- `test/test_LineageAxis.jl`
- `test/test_Layers.jl`
- `test/test_Integration.jl`
- `.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--15.md`
- `.workflow-docs/202604181600_tier1/archived-tasks/03_tasks--16.md`

The local upstream Makie codebases are primary sources. For this tranche, read
the specific upstream files in:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/CairoMakie`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/GraphMakie.jl`

At minimum, read the upstream files needed for text alignment, text measurement,
scene ownership, and recipe composition. Use them to verify that label placement
and blockscene ownership match Makie's actual conventions.

This tranche must preserve the approved plotting contract from tranche 1 and the
measured layout infrastructure from tranche 2. It is not complete until all of
the following pass:

- `julia --project=test test/runtests.jl`
- `julia --project=docs docs/make.jl`

Because this tranche changes visuals, it must also rerun the affected example
scripts and verify the rendered output against the issue log.

## Tasks

### 7. Move leaf-label placement onto the shared annotation layout

**Type**: WRITE
**Output**: Rectangular and radial leaf labels use the shared annotation layout
contract rather than independent fixed offsets.
**Depends on**: tranche 2 complete

Migrate rectangular and radial leaf-label placement so it consumes the shared
lane or anchor contract from tranche 2. Preserve the correct left/right mirrored
semantics and radial outward placement, but remove the current independent
offset logic as the source of truth.

### 8. Move clade bracket and clade label placement onto the same contract

**Type**: WRITE
**Output**: Clade brackets and clade labels are coordinated with leaf labels and
cannot compete for the same seam.
**Depends on**: 7

Migrate `CladeLabelLayer` so bracket geometry and label text use the same shared
annotation layout contract as leaf labels. The goal is not a new offset tweak;
it is to eliminate the structural possibility that leaf labels and clade labels
occupy the same narrow strip. Preserve the blockscene rendering model already in
place, but make placement fully coordinated by the panel owner.

### 9. Add readability regressions and verify tranche 3

**Type**: TEST
**Output**: Tests encode non-overlap, seam safety, mirrored orientation
correctness, and radial outward placement, and the full test suite plus docs
build pass at the end of the tranche.
**Depends on**: 8

Extend layer and integration tests beyond "geometry exists" to capture the
actual readability expectations from the issue log. The new assertions should
detect leaf/clade label crowding, center-seam collisions, broken mirrored side
selection, and regressions in radial label direction. Rerun the relevant example
scripts as part of this tranche's acceptance, then run the full test suite and
the full docs build.
