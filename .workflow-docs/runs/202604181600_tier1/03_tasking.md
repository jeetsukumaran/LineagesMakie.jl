# Tasking index for review-log issue bundle

Parent issue: `.workflow-docs/202604181600_tier1/logs/log.20260422T1908--codex-review-report.md`
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

This file is the tranche index for the post-Tier-1 plotting and visual
corrections bundle. The tasking has been split into separate tranche files so an
agent can execute one focused tranche at a time without exhausting context.

All tranche files inherit the same approved issue scope:

- `lineageplot(rootvertex, accessor; kwargs...)` is the non-mutating public
  entrypoint and must follow Makie's non-bang semantics.
- `lineageplot!(ax, rootvertex, accessor; kwargs...) -> LineagePlot` remains the
  mutating form for existing `Axis` and `LineageAxis` targets.
- Every tranche must end with `julia --project=test test/runtests.jl` passing
  and `julia --project=docs docs/make.jl` passing.
- Any tranche that changes visuals must rerun the affected examples and verify
  the rendered output against the issue log.

## Tranche files

### Tranche 1

File:
`.workflow-docs/202604181600_tier1/03_tranche-01--plotting-and-display-contract.md`

Focus:
- public `lineageplot` / `lineageplot!` contract
- Makie-consistent return values
- REPL and VS Code display behavior
- example and docs usage for the plotting contract

### Tranche 2

File:
`.workflow-docs/202604181600_tier1/03_tranche-02--shared-annotation-layout-infrastructure.md`

Focus:
- measured `LineageAxis` decoration layout
- semantic annotation lanes and anchors
- panel-owned side-annotation reservation

### Tranche 3

File:
`.workflow-docs/202604181600_tier1/03_tranche-03--leaf-and-clade-label-migration.md`

Focus:
- rectangular and radial leaf-label migration
- clade bracket and clade label migration
- non-overlap and seam-safety regressions

### Tranche 4

File:
`.workflow-docs/202604181600_tier1/03_tranche-04--scale-bar-architecture.md`

Focus:
- panel-owned scale-bar placement
- scale-bar visibility semantics
- scale-bar regression coverage

### Tranche 5

File:
`.workflow-docs/202604181600_tier1/03_tranche-05--junction-rendering-and-final-polish.md`

Focus:
- explicit edge/junction/marker rendering contract
- junction continuity regressions
- final docs refresh and end-to-end acceptance
