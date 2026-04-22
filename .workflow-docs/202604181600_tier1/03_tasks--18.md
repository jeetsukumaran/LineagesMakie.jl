# Tasks for Issue 18: Clade highlight rects must remain clade-local after real viewport resolution

Parent issue: Issue 18 (visual correctness; supplements Tier 1 and follows Issues 15–17)
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `STYLE-vocabulary.md`.
Read-only git and shell commands may be used freely.
Mutating git operations (commit, merge, push, branch) are the human project
owner's responsibility.

These are targeted fixes for the remaining clade-highlight visual correctness
bug visible in `examples/lineageplot_ex2.png`.
The current test suite passes, but it does **not** correctly specify the
intended geometry for non-root clade highlights.
No architectural rewrite is required.
The work is confined to the current highlight-rectangle computation path and
its tests.

---

## Reading mandate

**Before touching any code**, read every file listed below — **completely,
line by line, no skipping**.
This issue is not a generic “scene mismatch” hypothesis.
The current implementation already contains a concrete highlight computation,
a concrete fallback path, and concrete tests.
The fix must be derived from those exact details.

### Primary files (read in full before any edit)

| File | Why it is critical |
|------|-------------------|
| `examples/lineageplot_ex2.jl` | This is the top-level call path that reproduces the bug. Read all four panels and note exactly which clades are highlighted (`CLADE_A`, `CLADE_B`) and which orientations are involved. |
| `src/Layers.jl` | Contains `LineagePlot`, `CladeHighlightLayer`, and the exact `map!` dependency chain that computes `:highlight_rects`. Read the full file, not just the highlight section, so you understand how sub-layers are constructed and where `parent_scene(p)` comes from. |
| `src/CoordTransform.jl` | Contains `pixel_offset_to_data_delta` and its **degenerate viewport fallback**, which is directly implicated in the current bug. |
| `src/LineageAxis.jl` | Read `initialize_block!`, `_wire_x_axis!`, `reset_limits!`, and `lineageplot!(::LineageAxis, ...)` so you understand when scene viewports become valid and how example panels are built. |
| `test/test_Layers.jl` | Contains the existing `CladeHighlightLayer` tests, including the current “clamped to bounding box” test that is too weak and can pass even when the visible output is wrong. |
| `test/test_LineageAxis.jl` | Read the existing integration tests so the new tests match current fixture naming and style. |

### Secondary files (read the sections indicated)

| File | Sections to read |
|------|------------------|
| `.workflow-docs/202604181600_tier1/03_tasks--15.md` | Read in full for the expected task-file structure and level of specificity. |
| `src/Layers.jl` | `LeafLabelLayer` and `CladeLabelLayer` — contrast cases for viewport-reactive geometry. Read them fully, but do **not** assume the same rendering target is correct for highlights. |
| `.workflow-docs/202604181600_tier1/01_prd.md` | Read once for Tier-1 scope and terminology. |

### Design / style documents (read once for governance)

| File | Purpose |
|------|---------|
| `STYLE-julia.md` | Julia coding standards |
| `STYLE-docs.md` | Task/document formatting constraints |
| `STYLE-vocabulary.md` | Canonical project vocabulary |
| `CONTRIBUTING.md` | Repository workflow constraints |

---

## Background: identified bug from the current implementation

### Bug A — `CladeHighlightLayer` converts degenerate-viewport fallback into full-span rectangles

The current implementation in `src/Layers.jl` computes each clade highlight as:

1. subtree leaf positions + MRCA position,
2. raw clade min/max bounds in data space,
3. padding conversion via `pixel_offset_to_data_delta(sc, centre, ...)`,
4. `abs(dx)` / `abs(dy)` symmetric expansion,
5. clamp to `geom.boundingbox`,
6. render via `poly!(p, p[:highlight_rects])`.

That logic is sound **only when the scene viewport is already non-degenerate**.

However, `pixel_offset_to_data_delta` in `src/CoordTransform.jl` explicitly
returns the raw `pixel_offset` unchanged when the viewport width or height is
zero:

```julia
return pixel_offset
```

In `CladeHighlightLayer`, that fallback is then interpreted as a **data-space**
padding amount.
For the current example, this produces the wrong geometry immediately:

- `CLADE_A` has raw x-span approximately `4 → 10`
- fallback `padding = Vec2f(4, 4)` becomes `adx = 4`, `ady = 4`
- the code clamps `xmin - 4` to the bounding-box left edge and `xmax + 4` to
  the bounding-box right edge
- result: a rectangle spanning essentially the **full panel width**

This exactly matches the visible blue-frame failure in the example image.

### Bug B — the current clamping logic masks the fallback failure instead of preventing it

The current code comment says clamping prevents highlight rects from spanning
the full data range when the viewport is zero-size at construction time.
In practice, the opposite happens for non-root clades in `lineageplot_ex2.jl`:

- fallback padding is huge in data units relative to the clade span,
- clamping snaps the rectangle to the layout bounding box edges,
- the rectangle becomes bounded but **not clade-local**.

So the current clamping behavior turns an invalid padding conversion into a
plausible-looking but incorrect full-span rectangle.

### Bug C — the existing tests do not encode the intended behavior

The current tests in `test/test_Layers.jl` verify only:

- render without error,
- empty inputs produce empty rects,
- one clade produces one rect,
- root-clade leaf positions are enclosed,
- rects are clamped to the bounding box.

Those tests can all pass while the visible example is still wrong.

In particular, the current test:

```julia
@testset "CladeHighlightLayer rects clamped to bounding box"
```

asserts only that rects stay within `geom.boundingbox`.
A full-width rectangle for `CLADE_A` or `CLADE_B` still passes that test.

The missing requirement is:

- for a **non-root** clade, the highlight rect must remain **local to that clade**
  and must not expand to the full tree width except when the clade itself spans
  the full tree width.

---

## Architecture note: what the fix must preserve

This is **not** the Issue 15 bracket problem.

- Clade brackets are intentionally rendered beyond the data extent and therefore
  belong in the decoration scene.
- Clade highlights are data-local envelopes around subtree geometry and should
  remain panel-local data-space shapes.

So the expected render model here is still:

- compute the highlight rectangle in **data coordinates**,
- render it in the owning plot scene,
- use viewport-reactive conversion **only** for the padding magnitude,
- and never let a degenerate-viewport fallback become final geometry.

Do **not** move `CladeHighlightLayer` rendering to `blockscene` as part of this
issue unless a separate, code-grounded reason is discovered.
That is not the bug currently present in the source.

---

## Concrete diagnosis to verify before any edit

Before changing code, explicitly trace and confirm the following in the current
source:

1. `examples/lineageplot_ex2.jl` passes `clade_vertices = [CLADE_A, CLADE_B]`
   in Panels 1–3, not the root.
2. `LineagePlot.plot!` forwards `clade_highlight_padding` to
   `cladehighlightlayer!`.
3. `CladeHighlightLayer.plot!` computes `centre`, then calls
   `pixel_offset_to_data_delta(sc, centre, ...)`.
4. `pixel_offset_to_data_delta` returns raw `pixel_offset` unchanged on
   degenerate viewport.
5. `CladeHighlightLayer.plot!` applies `abs(dx)` / `abs(dy)` and then clamps to
   `geom.boundingbox`.
6. A non-root clade in the example therefore becomes full-width under the
   degenerate fallback, even though the code still satisfies the current tests.

Do not proceed until you have traced all six points in the actual code.

---

## Tasks

### 1. Repair `CladeHighlightLayer` so degenerate viewport fallback cannot become rendered geometry

**Type**: WRITE
**Output**: `CladeHighlightLayer` computes clade-local rectangles even when the
first evaluation occurs before viewport resolution.
Degenerate-viewport fallback must never produce full-bounding-box rectangles for
non-root clades.
**Depends on**: none

Before modifying, read `examples/lineageplot_ex2.jl`, `src/Layers.jl`,
`src/CoordTransform.jl`, and `src/LineageAxis.jl` in full.

#### Step A — preserve the current high-level computation path

Do **not** rewrite the layer into a different architectural pattern.
Keep the existing structure:

- subtree leaf positions + MRCA,
- raw data-space min/max,
- pixel-to-data padding conversion,
- symmetric expansion,
- final `Rect2f` construction,
- render in the owning plot scene.

This issue is about correcting the degenerate-viewport case, not replacing the
layer design.

#### Step B — stop treating degenerate fallback as a real data-space padding value

The current bug exists because `pixel_offset_to_data_delta` returns raw pixel
offsets when the viewport is degenerate, and `CladeHighlightLayer` currently
treats those values as true data-space deltas.

Replace that behavior in the highlight layer with one of the following
**code-grounded** fixes:

- detect a degenerate viewport before converting padding and use **zero padding**
  for that evaluation, or
- detect that `pixel_offset_to_data_delta` is returning fallback semantics and
  suppress padding for that evaluation, or
- guard the entire `:highlight_rects` computation so that padding is applied
  only when the viewport is non-degenerate.

The key requirement is:

> When the viewport is degenerate, the layer may produce an unpadded local clade
> rectangle or temporarily no rectangle, but it must **not** produce a
> full-width or full-height rectangle caused by interpreting raw pixel offsets
> as data units.

Do **not** leave the current fallback-to-full-bbox path in place.

#### Step C — recompute from raw clade bounds after viewport resolution

The reactive dependency on `:pixel_projection` must remain.
When the viewport becomes valid, the rectangle must recompute from the original
raw clade bounds and acquire the correct small pixel-derived padding.

Do **not** cache or accumulate padding across evaluations.
Each recomputation must start from the raw clade min/max bounds derived from the
current subtree positions.

#### Step D — keep symmetric expansion semantics

The current use of `abs(dx)` / `abs(dy)` is correct **for highlights** because
padding is symmetric around the clade envelope.
Retain this semantic unless a direct reading of the current code proves a more
localized correction is needed.

Do **not** import the signed-offset rule from `CladeLabelLayer`.
That rule is specific to brackets, not rectangles.

#### Step E — narrow or remove the misleading clamping rationale

The current code comment claims the bounding-box clamp prevents full-span rects
under zero-viewport fallback.
That claim is false for the current example.

Update the implementation and comments so that:

- clamping is treated only as a final geometric safety bound, not as the
  mechanism that “fixes” degenerate viewport fallback, and
- the real prevention mechanism is the corrected degenerate-viewport handling
  from Steps B–C.

If, after the fix, clamping is no longer needed for correct behavior, you may
remove it **only if** you can justify that change from the actual geometry path
and corresponding tests.
Do not remove it casually.

#### Step F — update the docstring for `CladeHighlightLayer`

Revise the docstring so it describes the actual intended semantics:

- rectangle built from subtree bounds in data space,
- padding derived from pixel offsets only when the plot scene viewport is valid,
- degenerate viewport evaluations do not produce fallback-expanded geometry,
- render remains panel-local in the owning plot scene.

---

### 2. Replace the current weak tests with geometry tests that encode clade-locality

**Type**: TEST
**Output**: Tests fail if a non-root clade highlight expands to the full tree
bounding box merely because the first evaluation occurred before viewport
resolution.
**Depends on**: Task 1

Before writing tests, read all existing `CladeHighlightLayer` tests in
`test/test_Layers.jl` and the current `LineageAxis` integration tests in
`test/test_LineageAxis.jl`.

#### Step A — keep the existing smoke tests

Do not delete the simple smoke tests that check:

- render without error,
- empty clade list → empty rects,
- one clade → one rect,
- visible flag accepted.

Those still provide useful basic coverage.

#### Step B — add a non-root clade locality test in `test/test_Layers.jl`

Add a new test using a **non-root** clade from the existing balanced-tree
fixture.
Do **not** use the root clade for this test.

The test must:

1. build the geometry,
2. choose an internal non-root clade vertex,
3. call `cladehighlightlayer!` for that clade,
4. force layout resolution with `colorbuffer(fig)`,
5. extract the rendered `Rect2f`,
6. compare its width against:
   - the selected clade's raw subtree x-span, and
   - the full geometry bounding-box x-span.

Required assertions:

- the highlight rect width is **greater than or equal to** the raw clade span,
- the highlight rect width is **strictly less than** the full tree width for a
  non-root clade,
- all descendant leaves of the selected clade and the MRCA point are enclosed,
- at least one leaf outside the clade is **not** enclosed horizontally by the
  rect when the tree structure permits that distinction.

This is the test the current code is missing.

#### Step C — replace the current “clamped to bounding box” test with a stronger version

The existing test that only checks bounding-box containment is too weak.
Replace it or extend it so it also asserts **localness**.

For non-root clades, “within bounding box” is necessary but not sufficient.
The test must fail if the rect spans the full bounding-box width without the
clade itself doing so.

#### Step D — add a viewport-reactivity test

Add a test that verifies the highlight geometry changes correctly when the
viewport changes from degenerate or small to a resolved size.

Use the same style as the existing reactive tests in the suite:

- construct the figure,
- instantiate the plot,
- force a render/layout pass,
- optionally mutate the scene viewport,
- verify that `:highlight_rects` remains finite and local afterward.

The goal is to ensure the layer recomputes from raw clade bounds rather than
freezing fallback-expanded geometry.

#### Step E — add a `LineageAxis` integration test mirroring the example path

In `test/test_LineageAxis.jl`, add an integration test that uses
`lineageplot!(lax, ..., clade_vertices = [nonroot_clade])` on `LineageAxis`
and then checks that the resulting `CladeHighlightLayer` rectangle for that
clade remains **strictly narrower** than the full geometry width after
`colorbuffer(fig)`.

This test must follow the actual example call path more closely than the
current layer-only tests.

---

### 3. Regenerate examples and verify against the specific failure mode

**Type**: VERIFY
**Output**: `examples/lineageplot_ex2.jl` regenerated and visually checked;
blue highlight frames are local to `CLADE_A` and `CLADE_B`, not full-span panel
boxes.
**Depends on**: Tasks 1 and 2

Run the full test suite first:

```bash
julia --project=test test/runtests.jl
```

All tests must pass.
Do not weaken tests to preserve the current behavior.

Then regenerate the examples:

```bash
julia --project=examples examples/lineageplot_ex1.jl
julia --project=examples examples/lineageplot_ex2.jl
```

#### Expected visual outcomes in `lineageplot_ex2.png`

| Panel | Expected |
|-------|----------|
| Panel 1 | The blue highlight around `CLADE_A` encloses only the left subtree rooted at `clade_A`; the blue highlight around `CLADE_B` encloses only the right subtree rooted at `clade_B`. Neither frame spans the full panel width. |
| Panel 2 | Same clade-local behavior under backward-time layout. Rectangles remain local to their clades and do not collapse into full-width boxes. |
| Panel 3 | Same clade-local behavior under `:right_to_left` orientation. Symmetric padding still works, but the rectangles remain subtree-local. |
| Panel 4 | No clade highlights unless explicitly requested by the example. |

#### Additional regression expectations

- The MRCA point for each highlighted clade remains inside its rectangle.
- All descendant leaves of each highlighted clade remain inside its rectangle.
- Leaves from the sibling clade are not swept into the rectangle merely because
  of fallback-expanded padding.
- The Issue 15 bracket fix remains intact.
- No new clipping or scene-target regressions are introduced.

---

## Verification checklist

```text
[ ] Read examples/lineageplot_ex2.jl in full before editing
[ ] Read src/Layers.jl in full before editing
[ ] Read src/CoordTransform.jl in full
[ ] Read src/LineageAxis.jl in full
[ ] Read test/test_Layers.jl in full before editing
[ ] Read test/test_LineageAxis.jl in full before editing
[ ] Traced the exact current fallback path from pixel_offset_to_data_delta to full-span highlight rects
[ ] Preserved the existing CladeHighlightLayer data-space rectangle architecture
[ ] Degenerate viewport fallback no longer becomes rendered full-span geometry
[ ] :highlight_rects still recomputes reactively from raw clade bounds after viewport resolution
[ ] Symmetric highlight expansion still uses magnitude semantics
[ ] Misleading clamp comment removed or corrected
[ ] CladeHighlightLayer docstring updated
[ ] New non-root clade locality test added to test/test_Layers.jl
[ ] Weak bounding-box-only test replaced or strengthened
[ ] Viewport-reactivity test added for highlight geometry
[ ] New LineageAxis integration test added
[ ] julia --project=test test/runtests.jl passes
[ ] examples/lineageplot_ex2.jl regenerated and visually verified
[ ] Blue highlight frames are subtree-local in Panels 1–3
[ ] examples/lineageplot_ex1.jl unchanged unless intentionally affected
[ ] No unrelated files modified
```

---

## What NOT to change

- `CladeLabelLayer` — separate issue; already handled in Issue 15.
- `_wire_x_axis!` in `LineageAxis.jl` — not the source of the blue-frame bug.
- Title/xlabel layout logic — separate issue.
- Radial leaf-label placement — separate issue.
- Any scene-target changes that are not directly justified by the current
  `CladeHighlightLayer` source path.

Scope discipline applies: if you find another visual bug while fixing this one,
report it in the implementation response — do not silently fold it into this
issue.
