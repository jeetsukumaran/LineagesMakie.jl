# Tranche 4 tasking: scale-bar architecture

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
- `examples/lineageplot_ex2.jl`
- `test/test_Layers.jl`
- `test/test_Integration.jl`

The local upstream Makie codebases are primary sources. For this tranche, read
the specific upstream files in:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/CairoMakie`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/GraphMakie.jl`

At minimum, read the upstream files needed to verify decoration ownership,
non-data-space annotations, and any plot/layout behavior that informs a
Makie-consistent scale-bar solution.

This tranche must preserve the approved plotting contract from tranche 1 and the
measured shared annotation layout from tranches 2 and 3. It is not complete
until all of the following pass:

- `julia --project=test test/runtests.jl`
- `julia --project=docs docs/make.jl`

Because this tranche changes visuals, it must also rerun the affected example
scripts and verify the rendered output against the issue log.

## Tasks

### 10. Move scale-bar placement into the panel-owned decoration system

**Type**: WRITE
**Output**: The scale bar uses the shared panel-owned decoration layout rather
than the current ad hoc data-space placement path.
**Depends on**: tranche 3 complete

Rework scale-bar placement so it uses the same panel-owned layout model as the
other external decorations, instead of living just outside the data bounding box
and relying on incidental padding. This task must make panel 1's requested
scale bar visible by design rather than by extra data-limit padding hacks.

### 11. Normalize scale-bar visibility semantics and defaults

**Type**: WRITE
**Output**: Scale-bar visibility behavior is intentional and documented for
rectangular and radial layouts, including the approved default behavior for
unlabeled bars.
**Depends on**: 10

Tighten the user-visible scale-bar contract so default visibility and labeling
behavior match the design intent rather than incidental current behavior. Update
the scale-bar layer and any forwarding logic needed in the composite recipe so
rectangular panels behave intentionally and accidental unlabeled radial bars do
not appear unless the approved contract calls for them.

### 12. Add scale-bar regressions and verify tranche 4

**Type**: TEST
**Output**: Tests cover rectangular visibility, radial behavior, and the chosen
default-visibility policy, and the full test suite plus docs build pass at the
end of the tranche.
**Depends on**: 11

Add tests that specifically protect the panel 1 failure mode, the radial default
behavior, and the scale-bar contract encoded in tranche 4. Use the examples as
acceptance fixtures where appropriate, then run the full test suite and the full
Documenter build.
