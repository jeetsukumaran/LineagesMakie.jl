# Tasks for Issue 1: Project scaffolding and dependency setup

Parent issue: Issue 1
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `.workflow-docs/00-design/controlled-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

---

## Tasks

### 1. Add Makie and AbstractTrees to main `Project.toml`

**Type**: CONFIG
**Output**: `Project.toml` lists `Makie` (compat `"0.24"`) and `AbstractTrees`
in `[deps]` and `[compat]`; `Manifest.toml` is resolved.
**Depends on**: none

Start a Julia REPL with `julia --project` from the package root. Use `Pkg.add`
to add `Makie` and `AbstractTrees`. Then open `Project.toml` and confirm that
`[compat]` entries are present for both packages, with `Makie` constrained to
`"0.24"` (meaning ≥ 0.24). Do not edit `Project.toml` by hand. Verify with
`julia --project -e 'using Makie, AbstractTrees'` that both load without error.

---

### 2. Add `CairoMakie` to the test environment

**Type**: CONFIG
**Output**: `test/Project.toml` lists `CairoMakie`; `test/Manifest.toml` is
resolved.
**Depends on**: none

Start a Julia REPL with `julia --project=test` from the package root. Use
`Pkg.add("CairoMakie")` to add it to the test environment. Confirm the entry
appears in `test/Project.toml` under `[deps]`. Verify with
`julia --project=test -e 'using CairoMakie'` that it loads without error.

---

### 3. Create module stub files and wire into `LineagesMakie.jl`

**Type**: WRITE
**Output**: Five files `src/Accessors.jl`, `src/Geometry.jl`,
`src/CoordTransform.jl`, `src/Layers.jl`, `src/LineageAxis.jl` exist, each
declaring an empty module. `src/LineagesMakie.jl` includes all five.
**Depends on**: Task 1

Create each of the five stub files. Each file must follow the `using
Package: name` import style (no bare `using Package`) per `STYLE-julia.md`
§1.16.6 — at this stage there are no imports, just the `module`/`end` wrapper.
Each stub declares its module with the exact name matching the filename
(e.g., `module Accessors ... end`). Update `src/LineagesMakie.jl` to replace
the placeholder comment with five `include(...)` calls in dependency order:
`Accessors`, `Geometry`, `CoordTransform`, `Layers`, `LineageAxis`. Do not add
any exports yet. Verify with `julia --project -e 'using LineagesMakie'` that
the package loads cleanly.

---

### 4. Create test stub files and wire into `runtests.jl`

**Type**: TEST
**Output**: Seven stub test files exist under `test/`; `test/runtests.jl`
includes them after the Aqua and JET checks; `julia --project=test
test/runtests.jl` completes with 0 failures.
**Depends on**: Tasks 2, 3

Create `test/test_Accessors.jl`, `test/test_Geometry.jl`,
`test/test_CoordTransform.jl`, `test/test_Layers.jl`,
`test/test_LineageAxis.jl`, and `test/test_Integration.jl`. Each file should
contain exactly one empty `@testset` block whose name matches the module, e.g.
`@testset "Accessors" begin end`. Update `test/runtests.jl` to add `include`
calls for all six files inside the top-level `@testset` block, placed after the
existing Aqua and JET checks so quality gates always run first. Run
`julia --project=test test/runtests.jl` and confirm all tests pass trivially.

---
