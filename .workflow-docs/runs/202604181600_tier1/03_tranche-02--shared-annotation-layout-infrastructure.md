# Tranche 2 tasking: shared annotation layout infrastructure

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

The local upstream Makie codebases are primary sources. For this tranche, read
the specific upstream files in:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/CairoMakie`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/GraphMakie.jl`

At minimum, read the Makie line-axis layout and text bounding-box files that
govern measured label reservation, plus any upstream block layout files needed
to preserve Makie-compatible block scene ownership. Use GraphMakie recipe code
as a reference where it clarifies shared sublayer layout contracts.

This tranche must preserve the approved plotting contract from tranche 1 and is
not complete until all of the following pass:

- `julia --project=test test/runtests.jl`
- `julia --project=docs docs/make.jl`

## Tasks

### 4. Replace fixed side gutters with a measured decoration layout

**Type**: WRITE
**Output**: `LineageAxis` owns a measured decoration layout rather than only
fixed gutter constants, while preserving the existing panel-band architecture.
**Depends on**: tranche 1 complete

Rework the `LineageAxis` decoration layout so side reservation is derived from
actual annotation requirements rather than a single hard-coded seam width.
Preserve the panel-owned title/x-axis/xlabel model, but make the side
decoration layout measured and explicit enough to support later leaf-label,
clade-label, and scale-bar migration without more ad hoc offsets.

### 5. Introduce semantic annotation lanes and shared placement anchors

**Type**: WRITE
**Output**: `LineageAxis` exposes a shared semantic layout contract for outer
annotations, including distinct lanes or anchors for leaf labels, clade
brackets, clade labels, and future scale-bar placement.
**Depends on**: 4

Build the shared annotation-placement model that downstream layers will consume.
The important outcome is that side annotations no longer invent their own local
pixel offsets independently. Define the lane ownership and anchor semantics in
`LineageAxis` or a closely related helper, and wire it so later tasks can query
this layout instead of recomputing uncoordinated geometry inside sublayers.

### 6. Add layout-lane regressions and verify tranche 2

**Type**: TEST
**Output**: Tests protect the measured layout contract, mirrored orientation
behavior, and panel-owned decoration placement, and the full test suite plus
docs build pass at the end of the tranche.
**Depends on**: 5

Strengthen the `LineageAxis` and integration tests so they assert the existence
and stability of the new measured decoration contract. Protect against fallback
to the old single-gutter behavior, broken left/right mirroring, and loss of
panel ownership. End this task by running the full test suite and the full
Documenter build.
