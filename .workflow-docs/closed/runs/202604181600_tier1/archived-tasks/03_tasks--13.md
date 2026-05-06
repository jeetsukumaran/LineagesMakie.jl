# Tasks for Issue 13: Full integration test suite

Parent issue: Issue 13
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `STYLE-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

These tests are integration-only: they verify the full end-to-end pipeline, not
module internals. Module-level unit tests live in their respective
`test_<Module>.jl` files. All integration tests use `CairoMakie`.

---

## Tasks

### 1. Smoke tests: all `lineageunits` × rectangular layout × `Axis` and `LineageAxis`

**Type**: TEST
**Output**: `test/test_Integration.jl` passes a smoke test for every
`lineageunits` value on both a plain `Axis` and a `LineageAxis`; all render to
a non-empty figure without error.
**Depends on**: none

Replace the existing smoke-test stub in `test/test_Integration.jl` with a
systematic set. For each of the eight `lineageunits` values (`:edgelengths`,
`:branchingtime`, `:coalescenceage`, `:vertexdepths`, `:vertexheights`,
`:vertexlevels`, `:vertexcoords`, `:vertexpos`), define a matching tree accessor
with the required accessor functions (e.g., `edgelength` for `:edgelengths`,
`branchingtime` for `:branchingtime`, etc.) and call `lineageplot!` on both
a `CairoMakie` `Axis` and a `CairoMakie` `LineageAxis`. For each call, render
to an in-memory buffer or temp file and assert the output is non-empty (file
size > 0). Use `try/finally` to clean up temp files.

Organize as `@testset "smoke/rectangular/$lineageunits/$axis_type"` using
interpolated names so failures are easy to identify. Use the 4-leaf balanced
fixture for all tests. Each test must be independent (create a fresh `Figure`
per test).

---

### 2. Polarity matrix and `lineage_orientation` tests

**Type**: TEST
**Output**: All four `axis_polarity × display_polarity` combinations on
`LineageAxis` render without error; all three `lineage_orientation` values
render without error.
**Depends on**: Task 1

Add `@testset "polarity_matrix"` to `test/test_Integration.jl`. For each of the
four combinations of `axis_polarity` ∈ `{:forward, :backward}` × `display_polarity`
∈ `{:standard, :reversed}`, create a `CairoMakie` `Figure`, add a `LineageAxis`
with those attributes, call `lineageplot!` with a compatible `lineageunits` value
(use `:edgelengths` for `:forward`, `:coalescenceage` for `:backward`), render,
and assert non-empty output.

Add `@testset "lineage_orientation"` testing all three orientation values:
`:left_to_right`, `:right_to_left`, and `:radial`. For `:radial`, use
`circular_layout` via `lineage_orientation = :radial` on the `LineageAxis`.
Verify render is non-empty and no error is raised for each.

---

### 3. Resize stability and Observable reactivity tests

**Type**: TEST
**Output**: Marker pixel sizes are stable after a simulated viewport resize;
updating the `rootvertex` Observable produces updated `vertex_positions` in the
rendered scene.
**Depends on**: Task 2

Add `@testset "resize_stability"` to `test/test_Integration.jl`. Create a
`CairoMakie` `Figure` with a `LineageAxis`, call `lineageplot!` with
`VertexLayer` and `LeafLayer` active. Record the `markersize` attribute from the
`VertexLayer` plot object before and after triggering the scene viewport
Observable (simulate resize by updating `scene.viewport` with a different
`Rect2i` value). Assert `markersize` is unchanged (markers are in pixel space
and must not scale).

Add `@testset "observable_reactivity"` to `test/test_Integration.jl`. Wrap the
4-leaf balanced tree root in `Observable(root4)`. Call `lineageplot!`. Verify
the `VertexLayer` scatter has 3 positions (internal vertices). Update the
Observable to a different tree (e.g., a 6-leaf unbalanced fixture). Assert that
the `VertexLayer` scatter positions have updated to reflect the new tree's
internal vertex count. This test directly verifies the ComputeGraph wiring from
Issue 12 Task 2.

---

### 4. Aqua and JET clean-pass verification

**Type**: TEST
**Output**: `Aqua.test_all(LineagesMakie)` passes without violations; `JET.test_package(LineagesMakie; target_defined_modules = true)` passes without dispatch errors; CI passes on Julia 1.10, 1.12, and pre.
**Depends on**: Task 3

Add `@testset "Aqua" begin Aqua.test_all(LineagesMakie) end` and
`@testset "JET" begin JET.test_package(LineagesMakie; target_defined_modules = true) end`
at the top of `test/runtests.jl` if not already present (they should be from
Issue 1 Task 4 — verify they are still there and have not been accidentally
removed or commented out).

Run the full test suite locally using `julia --project=test test/runtests.jl`
and confirm all tests pass. If Aqua detects ambiguities, piracy, or unbound type
parameters, fix them before marking this task complete. If JET detects dispatch
errors in any of the five modules, fix them. Do not suppress JET warnings with
`@test_broken` or similar unless explicitly approved by the project owner.

Verify that `.github/workflows/CI.yml` runs the test suite against Julia 1.10,
1.12, and pre, and that the Runic formatting check from Issue 1 Task 5 is still
present. This task is complete only when the full local test suite passes clean,
not just when the integration tests pass.
