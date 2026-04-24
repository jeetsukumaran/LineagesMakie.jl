# Tranche 1 tasking: plotting and display contract

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
- `src/LineagesMakie.jl`
- `src/Layers.jl`
- `src/LineageAxis.jl`
- `examples/lineageplot_ex1.jl`
- `examples/lineageplot_ex2.jl`
- `docs/src/index.md`
- `test/test_Integration.jl`

The local upstream Makie codebases are primary sources. For this tranche, read
the specific upstream files in:

- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/CairoMakie`
- `/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/GraphMakie.jl`

At minimum, read the Makie files that define `FigureAxisPlot`, figure plotting,
axis creation, `Axis` and block initialization, and any display-related figure
helpers needed to match Makie's public contract. Use GraphMakie as a reference
for recipe composition patterns where relevant.

The approved public contract for this tranche is:

- `lineageplot(rootvertex, accessor; kwargs...)` is the non-mutating public
  entrypoint. It must create the plotting context it needs and return a
  figure-like Makie object suitable for immediate REPL and VS Code display.
  Prefer a `FigureAxisPlot` whose axis is `LineageAxis`.
- `lineageplot!(ax, rootvertex, accessor; kwargs...) -> LineagePlot` remains the
  mutating form for existing `Axis` and `LineageAxis` targets.
- Immediate-display examples should use `lineageplot(...)`. Composed figures and
  multi-panel layouts should continue to use `lineageplot!`.

This tranche is not complete until all of the following pass:

- `julia --project=test test/runtests.jl`
- `julia --project=docs docs/make.jl`

## Tasks

### 1. Implement the approved public `lineageplot` contract

**Type**: WRITE
**Output**: A public non-mutating `lineageplot(rootvertex, accessor; kwargs...)`
entrypoint exists, follows Makie's non-bang semantics, and preserves
`lineageplot!(ax, ...) -> LineagePlot` for mutating use on existing axes.
**Depends on**: none

Implement the non-bang public path so it creates the plotting context it needs,
prefers `LineageAxis` as the owning axis, and returns a figure-like Makie object
that displays immediately in REPL and VS Code. Preserve the current bang
semantics on existing `Axis` and `LineageAxis` targets, and do not weaken the
current `LineagePlot` return contract for the mutating method.

### 2. Update user-facing usage paths for the plotting contract

**Type**: WRITE
**Output**: The examples, docstrings, and top-level public documentation use the
approved non-bang and bang forms consistently.
**Depends on**: 1

Update the example scripts and user-facing text so immediate-display workflows
use `lineageplot(...)`, while composed figures and multi-panel layouts continue
to use `lineageplot!`. Touch only the relevant examples and public-facing docs
needed to make the contract understandable now. Follow existing Makie phrasing
patterns where possible and keep the docs consistent with the actual return
types and display behavior.

### 3. Add plotting/display regressions and verify tranche 1

**Type**: TEST
**Output**: Integration tests cover the approved `lineageplot` /
`lineageplot!` return and display behavior, and the full test suite plus docs
build pass at the end of the tranche.
**Depends on**: 2

Extend the integration tests so they encode the approved public contract:
non-bang returns a figure-like object suitable for immediate display, bang on
existing axes returns `LineagePlot`, and the example-style usage paths behave as
documented. Use Makie's own return-value conventions as the reference model, and
end by running the full test suite and the full Documenter build.
