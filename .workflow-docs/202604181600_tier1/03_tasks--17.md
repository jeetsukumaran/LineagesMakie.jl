# Tasks for Issue 17: Clade highlight frame rendering and panel-local bounds

Parent issue: Issue 17 (visual correctness; supplements Tier 1 and follows Issue 15/16)
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `STYLE-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

These are targeted fixes for the remaining clade-highlight visual correctness
bugs.
The full test suite must pass at the start of this issue.
No architectural rewrite is required.
Changes should remain tightly scoped to highlight-frame computation,
render-target correctness, and tests.

---

## Reading mandate

**Before touching any code**, read every file listed below — **completely,
line by line, no skipping**.
The defect is a coordinate-system and scene-dependency bug.
The implementation depends on exact function signatures, attribute names,
reactive `map!` chains, viewport/projection dependencies, and scene hierarchy.
Partial reading will produce incorrect fixes.

### Primary files (read in full before any edit)

| File | Why it is critical |
|------|-------------------|
| `src/Layers.jl` | Contains `CladeHighlightLayer`, including the current rectangle computation, render target, and reactive attribute chain. Read the full `@recipe`, all `map!` closures, and the final `poly!`/`band`/shape calls used to draw highlight rectangles. |
| `src/CoordTransform.jl` | Contains `register_pixel_projection!`, `pixel_offset_to_data_delta`, and `data_to_pixel`. Read the full file and verify the exact pixel-space convention and fallback behavior. |
| `src/LineageAxis.jl` | Read `initialize_block!` and `_wire_x_axis!` to understand scene hierarchy, viewport ownership, and the reference pattern for blockscene-aware rendering. |
| `test/test_Layers.jl` | Contains all existing `CladeHighlightLayer` and related layer tests. Read in full so you do not duplicate or contradict existing coverage. |
| `examples/lineageplot_ex2.jl` | Read in full. This is the failing visual example being repaired. |

### Secondary files (read the sections indicated)

| File | Sections to read |
|------|------------------|
| `src/Layers.jl` | `CladeLabelLayer` — now uses blockscene-aware pixel conversion. Read the full implementation as a contrast case, but do **not** cargo-cult its scene target without verifying the highlight requirements. |
| `test/test_LineageAxis.jl` | Read the `LineageAxis` testsets that validate layout-sensitive plotting behavior. |
| `examples/lineageplot_ex1.jl` | Read in full so you can verify that the fix does not regress the simple example. |

### Design documents (read once for governance)

| File | Purpose |
|------|---------|
| `.workflow-docs/202604181600_tier1/01_prd.md` | PRD and controlled vocabulary cross-reference |
| `STYLE-julia.md` | Julia coding standards |
| `STYLE-vocabulary.md` | Canonical identifier spellings |
| `STYLE-docs.md` | Task and documentation formatting constraints |

---

## Background: identified bug

### Bug A — Clade highlight frames are computed with the wrong coordinate coupling

In the current render, the blue clade highlight frames are dramatically larger
than the intended clade spans and spill outside their owning panels.
This is not a minor styling problem.
It is a geometric correctness bug.

The failure pattern shows that the rectangle geometry is being built from a
mismatched combination of:

- clade bounds in data coordinates, and
- padding or expansion values derived from pixel-space quantities using the
  wrong scene, wrong viewport, stale projection state, or wrong application
  rule.

The result is viewport-scale or panel-scale expansion instead of a small local
highlight around the selected clade.

### Bug B — Highlight rectangles are not guaranteed to remain panel-local

Even when the clade span itself is correct, the final rectangle is not being
validated against the owning plot scene's local data extent.
As a result, rectangles can cross gutters, bleed into neighboring panels, or
occupy most of the subplot width.

### Bug C — Existing tests are too weak to prove visual correctness

A non-empty rectangle or a finite polygon is not enough.
The correct behavior requires the frame to remain close to the selected clade,
within panel-local bounds, under all example orientations used by
`lineageplot_ex2.jl`.

---

## Architecture note: expected highlight semantics

A clade highlight frame is a **data-local envelope** around the selected clade.

Its semantics are:

- determine the clade's data-space span,
- expand that span by a small visual padding equivalent to a fixed pixel offset,
- construct the rectangle in the owning plot scene's data coordinates,
- and render it so it remains visually local to the clade and confined to the
  owning panel.

This is **not** the same as the clade bracket fix from Issue 15.

For brackets, the desired final geometry intentionally lives in the decoration
scene outside the data viewport.
For highlight frames, the desired final geometry is still panel-local and should
track the clade's data-space extent.
Do **not** move highlight-frame rendering into a global decoration scene unless
you can prove that the resulting geometry remains panel-local and correctly
clipped to the owning panel.
The default expectation is that `CladeHighlightLayer` remains a panel-local
plot-scene primitive, with only its padding computation depending on the correct
plot-scene pixel projection.

---

## Diagnostic requirements before any edit

Before changing code, explicitly inspect and write down for yourself:

1. Which scene is passed into `register_pixel_projection!` for
   `CladeHighlightLayer`.
2. Which scene is passed into `pixel_offset_to_data_delta`.
3. Whether horizontal and vertical padding are each derived from the owning plot
   scene viewport.
4. Whether padding deltas are applied once or compounded across already-expanded
   bounds.
5. Whether the reactive chain recomputes after layout resolution
   (`colorbuffer(fig)` / non-zero viewport).
6. Whether reversed axes or alternate orientations change the sign convention in
   a way that should or should not use `abs`.
7. Whether the final rectangle is built directly from clade min/max bounds or
   from a transformed intermediate object whose extent is already in pixel
   coordinates.

Do not skip this audit.

---

## Tasks

### 1. Audit and repair `CladeHighlightLayer` rectangle construction

**Type**: WRITE
**Output**: `CladeHighlightLayer` computes panel-local highlight rectangles with
small, pixel-accurate padding around the selected clade, and no frame expands to
viewport scale or panel scale.
**Depends on**: none

Before modifying, read `src/Layers.jl` `CladeHighlightLayer` in its entirety.
Read `src/CoordTransform.jl` in full.
Read `CladeLabelLayer` only as a contrast case.

#### Step A — trace the existing reactive chain

Identify all of the attributes involved in highlight geometry, including:

- clade selection inputs,
- clade-span bounds,
- padding inputs,
- pixel-projection registration,
- data-delta conversion,
- final rectangle coordinates,
- and final rendering call.

Document for yourself the exact attribute names and dependency order.
The fix must preserve the existing recipe structure unless a specific closure
must be replaced.

#### Step B — ensure pixel-to-data padding uses the owning plot scene

The highlight padding must be computed from the **owning plot scene** of the
highlight layer, not from `blockscene`, not from a sibling scene, and not from a
stale viewport.

If the current code passes the wrong scene into `register_pixel_projection!` or
`pixel_offset_to_data_delta`, replace it with the correct plot scene.
The closure computing the padded bounds must depend on `:pixel_projection`
so it recomputes after layout resolution and viewport changes.

#### Step C — compute padding from the base clade bounds only once

If the current implementation expands already-expanded bounds, compounds
horizontal and vertical deltas incorrectly, or reuses transformed extents,
replace it with a direct construction:

- start from the raw clade min/max data bounds,
- compute one horizontal and one vertical padding delta from fixed pixel
  offsets,
- apply those deltas once,
- build the rectangle from those final padded min/max values.

Do **not** scale padding by clade width, panel width, or viewport width.
Do **not** mix blockscene pixel coordinates into the final rectangle points.

#### Step D — use absolute magnitudes where symmetric expansion is intended

A highlight frame is a symmetric expansion around the clade span.
If `pixel_offset_to_data_delta` returns signed deltas whose sign varies with
orientation, convert those deltas to magnitudes before applying symmetric
min/max expansion.

Concretely:
- left expansion should use `abs(dx_pad)`
- right expansion should use `abs(dx_pad)`
- bottom/top expansion should use `abs(dy_pad)` if vertical padding is used

This is the opposite of the Issue 15 bracket rule.
For a symmetric rectangle envelope, signed direction is not semantically
meaningful; magnitude is.

#### Step E — keep rendering panel-local

Unless the audit proves otherwise, continue rendering the highlight rectangle in
the owning plot scene so the frame remains panel-local and cannot float across
the global figure due to decoration-scene placement.

If the current render target is already the owning plot scene, retain it.
If it is not, move it back to the owning plot scene.

#### Step F — update docstring / inline comments

Update the `CladeHighlightLayer` docstring or the relevant inline comments to
state clearly:

- the frame geometry is computed in data space,
- padding is derived from plot-scene pixel projection,
- symmetric expansion uses padding magnitudes,
- and the frame is expected to remain panel-local.

---

### 2. Add targeted tests for highlight-frame geometry

**Type**: TEST
**Output**: New tests prove that highlight frames are panel-local, finite, and
close to the selected clade span rather than viewport-scale.
**Depends on**: Task 1

Before writing tests, read `test/test_Layers.jl` and `test/test_LineageAxis.jl`
in full.
Reuse existing fixtures and helper names where possible.

#### Additions to `test/test_Layers.jl`

Inside the `CladeHighlightLayer` test area, add tests of the following form:

##### Test A — padded highlight rectangle remains finite after layout

Construct a small figure and plot with one known clade highlight.
Force layout resolution with `colorbuffer(fig)`.
Extract the `CladeHighlightLayer`.
Assert:

- rectangle geometry is non-empty,
- all rectangle coordinates are finite,
- no coordinate is `NaN`.

##### Test B — highlight width is bounded relative to clade span

For a known selected clade with known x-span in data units:

- compute the raw clade span from the underlying plotted tree data,
- extract the rendered highlight rectangle's x-min/x-max in data coordinates,
- assert that the rendered width is greater than the raw span,
- but only by a small tolerance attributable to the configured pixel padding.

This test must fail if the rectangle expands to most of the panel width.

##### Test C — highlight bounds remain inside the owning axis limits up to small padding

After layout resolution, compare the rendered rectangle bounds against the
owning plot scene's axis/data limits.
Allow only the small expected local padding.
Assert that the rectangle does not span the full axis width unless the clade
itself actually does.

#### Additions to `test/test_LineageAxis.jl`

Add a `LineageAxis` integration test that recreates one of the problematic
rectangular panels from `lineageplot_ex2.jl` with clade highlights enabled.

After `colorbuffer(fig)`:

- extract the `CladeHighlightLayer`,
- verify that the highlight rectangle is finite,
- verify that its width is substantially smaller than the full panel data width
  for the selected non-root clade,
- and verify that the rectangle remains local to the intended clade.

These tests must validate geometry, not just presence.

---

### 3. Regenerate examples and visually verify

**Type**: VERIFY
**Output**: Example PNGs regenerated and visually checked; blue highlight frames
are local, correctly padded, and confined to their owning panels.
**Depends on**: Tasks 1 and 2

Run the full test suite first:

```bash
julia --project=test test/runtests.jl
```

All tests must pass.
If an existing test fails, investigate the real cause before proceeding.

Then regenerate the examples:

```bash
julia --project=examples examples/lineageplot_ex1.jl
julia --project=examples examples/lineageplot_ex2.jl
```

#### Expected visual outcomes in `lineageplot_ex2.png`

| Panel | Expected |
|------|----------|
| Panel 1 | Each blue highlight frame tightly surrounds its selected clade, with only small visual padding. No frame spans the full panel width unless the selected clade truly does. |
| Panel 2 | Same as Panel 1, respecting that panel's orientation. Frames remain local to their clades and do not bleed into the center gutter. |
| Panel 3 | Same as Panel 1, with correct local width under right-to-left orientation. |
| Panel 4 | Unchanged unless that panel explicitly uses clade highlights. |

#### Additional regression expectations

- No blue frame crosses subplot gutters.
- No blue frame appears viewport-scaled.
- `lineageplot_ex1.png` is unchanged except for any intentional highlight fix if
  that example includes highlights.
- No regression to the clade-bracket fix from Issue 15.

---

## Verification checklist

```text
[ ] Read src/Layers.jl in full before editing
[ ] Read src/CoordTransform.jl in full
[ ] Read src/LineageAxis.jl in full
[ ] Read test/test_Layers.jl in full before editing
[ ] Read test/test_LineageAxis.jl in full before editing
[ ] Audited the full CladeHighlightLayer reactive chain
[ ] Verified the owning plot scene used for pixel-projection registration
[ ] Verified the owning plot scene used for pixel_offset_to_data_delta
[ ] Replaced any compounded or viewport-scaled padding logic
[ ] Symmetric rectangle expansion now uses padding magnitudes via abs(...)
[ ] Highlight rendering remains panel-local
[ ] CladeHighlightLayer docstring/comments updated
[ ] New geometry tests added to test/test_Layers.jl
[ ] New integration test added to test/test_LineageAxis.jl
[ ] julia --project=test test/runtests.jl passes
[ ] examples/lineageplot_ex2.jl regenerated and visually verified
[ ] Blue frames are panel-local and correctly padded
[ ] examples/lineageplot_ex1.jl unchanged unless intentionally affected
[ ] No files outside the scoped layer/tests/example-verification path modified
```

---

## What NOT to change

- `CladeLabelLayer` — fixed separately for the bracket/label clipping issue.
- `_wire_x_axis!` in `LineageAxis.jl` — reference implementation only.
- Title/xlabel layout logic from Issue 16 — out of scope here.
- Radial leaf-label placement — out of scope here.
- Any example semantics unrelated to clade highlight rectangles.

Scope discipline applies: if you notice another visual or architectural problem
outside `CladeHighlightLayer` while working this issue, report it in your final
response — do not fix it silently.
