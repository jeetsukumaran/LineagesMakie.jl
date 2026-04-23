# Tasks for Issue 6: `CoordTransform` module

Parent issue: Issue 6
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `STYLE-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

This module has no knowledge of tree structure or process coordinates. It
operates purely on geometric values. Per the PRD three-view model: no module
may cross layer boundaries.

---

## Tasks

### 1. Coordinate conversion functions

**Type**: WRITE
**Output**: `src/CoordTransform.jl` defines and exports `data_to_pixel`,
`pixel_to_data`, and `pixel_offset_to_data_delta`; the module loads cleanly with
no Makie dependency errors.
**Depends on**: none

Before writing any code, read the following in the local Makie source at
`/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/`:
`src/camera/camera.jl` or wherever the `projectionview` matrix and `viewport`
observable are defined; look for how `Scene` or `Axis` exposes the current
camera projection for converting between data coordinates and pixel coordinates.
Also read `GraphMakie.jl/src/recipes.jl` (at
`/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/GraphMakie.jl/src/recipes.jl`)
for how it handles pixel-projection in a recipe context. Document the approach
chosen in a comment citing the source file and line.

Implement `data_to_pixel(scene, point::Point2f) -> Point2f`: converts a data-
space point to pixel (screen) coordinates using the scene's current camera
matrices. Implement `pixel_to_data(scene, point::Point2f) -> Point2f`: the
inverse. Implement `pixel_offset_to_data_delta(scene, data_point::Point2f,
pixel_offset::Vec2f) -> Vec2f`: given a point in data space and an offset in
pixel space, returns the equivalent offset in data space at that point (this is
not a global conversion — it depends on the local Jacobian of the projection).

All three functions must handle non-isotropic axes correctly (x and y scales may
differ by any factor). Do not assume isotropy anywhere. Add explicit return type
annotations. Write triple-quoted docstrings on all three. Export all three from
`src/CoordTransform.jl`. Confirm with `julia --project -e 'using LineagesMakie'`.

---

### 2. `register_pixel_projection!` and degenerate viewport handling

**Type**: WRITE
**Output**: `register_pixel_projection!` registers viewport and projectionview
Observables in a ComputeGraph so pixel↔data mappings update reactively on
resize; degenerate (zero-size) viewport emits `@warn` and returns identity.
**Depends on**: Task 1

Before writing any code, read `src/compute-plots.jl` in the local Makie source
to understand how `map!` and `register_computation!` work in the ComputeGraph
pattern. Confirm the correct API for registering reactive inputs on a plot's
attribute dict. Document the chosen pattern in a comment with source citation.

Implement `register_pixel_projection!(plot_attrs, scene)`: this function
registers `scene.viewport` and `scene.camera.projectionview` (or their
equivalents — confirm from the Makie source) as reactive inputs on `plot_attrs`
via the ComputeGraph API. The effect is that any downstream computation using
pixel↔data mappings will recompute when the viewport changes (e.g., on window
resize). The function should not return a value (return type `-> Nothing`).

Add degenerate viewport detection: in `data_to_pixel` and `pixel_to_data`, check
whether the viewport has zero width or height (using the current scene
dimensions). If so, emit `@warn` identifying which dimension is zero and return
an identity-mapped point rather than attempting a projection that would produce
`Inf` or `NaN`. Write a docstring on `register_pixel_projection!`. Export it.

---

### 3. Write `test/test_CoordTransform.jl`

**Type**: TEST
**Output**: All `test_CoordTransform` assertions green; round-trip holds for
non-isotropic scenes; degenerate viewport emits warning and returns identity.
**Depends on**: Task 2

Write `test/test_CoordTransform.jl`. Tests must use a real `CairoMakie` scene
(not a mock) to exercise actual coordinate transform paths.

Cover:
- Round-trip: create a `CairoMakie` `Figure` with an `Axis` having explicitly
  non-isotropic limits (e.g., x in `[0, 100]`, y in `[0, 1]`). Assert that
  `data_to_pixel(scene, pixel_to_data(scene, p)) ≈ p` for several points `p`,
  using `atol = 1e-3` or better.
- Non-isotropic: verify that the pixel coordinates of `(0.0, 0.0)` and
  `(1.0, 0.0)` differ from those of `(0.0, 0.0)` and `(0.0, 1.0)` by different
  amounts (confirming scale is not isotropic).
- `pixel_offset_to_data_delta`: for a known non-isotropic scene, apply a 10px
  horizontal offset and verify the data-space delta is consistent with the x
  scale.
- Degenerate viewport: construct a zero-size scene (or simulate by passing a
  zero-height viewport) and use `@test_warn` to confirm a warning is emitted;
  verify the returned point equals the input.
- `register_pixel_projection!`: call the function on a plot attribute dict and
  verify that triggering the `scene.viewport` Observable causes the registered
  computation to be marked for recomputation.

Use `@testset` blocks. All tests deterministic.
