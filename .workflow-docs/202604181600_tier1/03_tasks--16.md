# Tasks for Issue 16: LineageAxis decoration layout and annotation placement

Parent issue: Issue 16 (visual correctness; follows Issue 15 and addresses the
remaining defects visible in `examples/lineageplot_ex2.png`)
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `STYLE-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

These are targeted fixes for the remaining Tier 1 visual defects after Issue 15.
No architectural rewrite is required, but the current `LineageAxis` decoration
layout is incomplete and must be regularized. The intended outcome is that each
panel owns its own title band, plot area, x-axis band, xlabel band, and outer
annotation gutter, so that labels/brackets/ticks do not collide with adjacent
panels or the figure edge.

---

## Reading mandate

**Before touching any code**, read every file listed below — **completely,
line by line, no skipping**. The remaining bugs are not isolated to a single
recipe. They arise from the interaction between `examples/lineageplot_ex2.jl`,
`lineageplot!(::LineageAxis, ...)`, `LineageAxis.initialize_block!`,
`LineageAxis._wire_x_axis!`, `reset_limits!`, and the label recipes in
`src/Layers.jl`.

### Primary files (read in full before any edit)

| File | Why it is critical |
|------|-------------------|
| `examples/lineageplot_ex2.jl` | This is the failing integration example. Read all four panels and all arguments passed to `LineageAxis` and `lineageplot!`. |
| `src/LineageAxis.jl` | Contains `LineageAxis` block initialization, scene allocation, `_wire_x_axis!`, `reset_limits!`, and the `lineageplot!(::LineageAxis, ...)` wrapper that injects orientation defaults. This is the core of the remaining layout problem. |
| `src/Layers.jl` | Contains `LeafLabelLayer`, `CladeLabelLayer`, `ScaleBarLayer`, and the `LineagePlot` composite recipe. Read all `map!` chains and every `text!` / `lines!` call. |
| `src/CoordTransform.jl` | Contains `data_to_pixel`, `pixel_to_data`, `pixel_offset_to_data_delta`, and `register_pixel_projection!`. You must understand exactly which coordinate space each layer uses. |
| `test/test_LineageAxis.jl` | Contains the existing `LineageAxis` tests, including the orientation-default tests and the x-axis tick blockscene tests. |
| `test/test_Layers.jl` | Contains the existing label-layer and clade-label tests. |

### Secondary files (read in full)

| File | Why to read it |
|------|----------------|
| `src/Geometry.jl` | Confirms what `geom.boundingbox`, `geom.vertex_positions`, and `geom.leaf_order` mean in rectangular vs radial layouts. |
| `test/test_Integration.jl` | Shows the current integration coverage and where the example-level regressions are still untested. |
| `STYLE-julia.md` | Required for helper design, guard clauses, naming, and docstring updates. |
| `STYLE-vocabulary.md` | Do not invent new synonyms for existing concepts such as polarity, orientation, blockscene, or bounding box. |

---

## Observed defects in the latest `lineageplot_ex2.png`

The latest render still shows the following visual defects:

### Defect A — panel titles are missing

All four panels were constructed with `title = ...` in `examples/lineageplot_ex2.jl`,
but no title text is rendered anywhere in the figure.

### Defect B — x-axis labels are missing

The top-left and top-right panels were constructed with `xlabel = ...`, but no
xlabel text is rendered.

### Defect C — x-axis tick labels are not placed in a stable dedicated axis band

The bottom-left panel has `show_x_axis = true`, but its tick labels appear on
the row divider above the panel rather than in a dedicated x-axis band below the
plot area. More generally, `_wire_x_axis!` currently draws ticks directly into
`blockscene` without any reserved band for them.

### Defect D — leaf labels are clipped at the plot boundary / figure boundary

Rectangular leaf labels are still rendered into the data-clipped plot scene via
`LeafLabelLayer.text!(p, ...)`. A fixed-pixel offset is converted to data units,
but the text glyphs themselves extend beyond the data viewport. In the example,
leaf labels at outer panel edges are truncated or pressed against the panel seam.

### Defect E — external annotations collide with neighboring panels because no gutter is reserved

`CladeLabelLayer` now correctly renders bracket lines and labels in the
`blockscene`, but `LineageAxis` still allocates the entire grid cell to the
inner plotting scene and reserves no external left/right gutter for annotations.
As a result, clade labels and leaf labels compete for the same inter-panel seam.

### Defect F — radial leaf-label placement is still rectangular-only

In the radial panel, `LeafLabelLayer` still uses the rectangular default logic:
a constant `Vec2f(4, 0)` offset and a fixed alignment. That is wrong for radial
layouts. Labels on the left half of the circle should move outward to the left,
labels on the right half should move outward to the right, and labels near the
top/bottom should be offset along their outward radial direction rather than by
a global +x shift.

---

## Core diagnosis

There are three core problems.

### Core problem 1 — `LineageAxis` has no decoration layout model

`LineageAxis.initialize_block!` currently sets

```julia
scenearea = lift(round_to_IRect2D, blockscene, lax.layoutobservables.computedbbox)
lax.scene = Scene(blockscene, scenearea; clear = false, visible = false)
```

That makes the inner plotting scene consume the full block bounding box.
There is no reserved top band for a title, no reserved bottom band for x-axis
and xlabel text, and no reserved side gutters for external annotations.
Any decoration rendered outside the data scene must therefore either overlap the
neighboring panel or be clipped by the figure edge.

### Core problem 2 — the codebase mixes data-scene and decoration-scene annotations without a unified placement contract

Current placement is inconsistent:

- `LeafLabelLayer` renders text into the data scene (`p`).
- `CladeLabelLayer` renders into the decoration scene (`Makie.parent(sc)`).
- `_wire_x_axis!` renders tick labels directly into `blockscene`.
- `title` and `xlabel` attributes exist on `LineageAxis` but are never rendered.

This is why some annotations clip against the data viewport while others escape
it and overlap neighboring panels.

### Core problem 3 — radial label logic is not implemented

The orientation-aware defaults in `lineageplot!(::LineageAxis, ...)` only solve
rectangular left-vs-right placement. They do not solve radial outward placement.
`LeafLabelLayer` has no branch for `lineage_orientation = :radial`, so the
radial panel uses a rectangular offset model and produces incorrect label
placement.

---

## Design requirements for the fix

The Issue 16 fix must satisfy all of the following:

1. Every `LineageAxis` must reserve its own decoration space inside the grid
   cell: title band, plot area, x-axis band, xlabel band, and left/right outer
   annotation gutters.
2. Titles, x-axis tick labels, and xlabels must render in those reserved bands,
   not by ad hoc placement against the raw scene viewport.
3. Rectangular leaf labels must no longer be clipped by the data viewport.
4. Clade brackets and clade labels must remain outside the data extent but
   inside the owning panel's reserved gutter.
5. Radial leaf labels must be placed outward from the circular layout.
6. The fix must preserve the correct orientation-aware semantics already added
   in Issue 14 and the clade-bracket blockscene rendering added in Issue 15.

---

## Tasks

### 1. Add a decoration-band layout model to `LineageAxis`

**Type**: WRITE
**Output**: `LineageAxis` uses an inset inner plotting scene, with reserved
bands/gutters inside the block bounding box.
**Depends on**: none

Before modifying, read `LineageAxis.initialize_block!`, `_wire_x_axis!`,
`reset_limits!`, and the current title/xlabel attribute declarations.

#### Required design

Introduce a private helper in `src/LineageAxis.jl` that derives a set of panel
rectangles from `lax.layoutobservables.computedbbox`, for example:

- `plot_rect`
- `title_band_rect`
- `xaxis_band_rect`
- `xlabel_band_rect`
- `left_gutter_px`
- `right_gutter_px`

Do **not** leave the scene area equal to the full computed bbox anymore.
`lax.scene` must instead be allocated from the inset `plot_rect`.

#### Minimum required behavior

Use fixed Tier 1 constants unless a file you read already defines a canonical
constant location. The exact numbers may be tuned during implementation, but the
bands must be distinct and stable. The implementation must reserve at least:

- top space when `title != ""`
- bottom space when `show_x_axis = true`
- additional bottom space when `xlabel != ""`
- left/right gutter space for external annotations in non-radial panels

The reserved gutter must be large enough that the clade bracket labels and leaf
labels in `lineageplot_ex2.jl` do not collide across the center seam.

#### Constraints

- Do not change `reset_limits!` data padding logic for this task.
- Do not change `Geometry.rectangular_layout` or `Geometry.circular_layout`.
- This task is about block layout, not layout geometry.

---

### 2. Render title, x-axis ticks, and xlabel from `LineageAxis` using the reserved bands

**Type**: WRITE
**Output**: `title`, x-axis tick labels, and `xlabel` render in the correct
panel-owned bands.
**Depends on**: Task 1

#### Step A — title and xlabel rendering

`LineageAxis` already stores `title` and `xlabel` attributes, but nothing draws
them. Add dedicated `text!` calls in `blockscene` for:

- title centered in `title_band_rect`
- xlabel centered in `xlabel_band_rect`

These text elements must be reactive on:

- `lax.title`
- `lax.xlabel`
- layout / computed bbox changes

#### Step B — rewrite `_wire_x_axis!` to use the x-axis band

Do not place ticks by "10 px below the raw scene viewport" anymore.
Instead:

- compute tick x positions from data coordinates exactly as now via `data_to_pixel`
- place their y coordinate in the center or lower portion of `xaxis_band_rect`
- ensure the tick-label text is owned by the current panel, not by the inter-row seam

The x-axis wiring must remain decoration-scene based (`blockscene`), because it
must not be clipped by the data viewport.

#### Step C — visibility rules

- `title = ""` should hide the title text
- `xlabel = ""` should hide the xlabel text
- `show_x_axis = false` should hide the x-axis tick labels

Do not introduce new public attributes unless they are truly required.

---

### 3. Move rectangular leaf-label rendering to the decoration scene and keep it inside the panel gutter

**Type**: WRITE
**Output**: rectangular leaf labels render in blockscene pixel coordinates and
no longer clip against the data viewport.
**Depends on**: Tasks 1 and 2

Before modifying, read `LeafLabelLayer.plot!` in full and compare its current
strategy with the updated `CladeLabelLayer`.

#### Required design

For non-radial layouts:

1. Keep the existing string-resolution logic.
2. Convert leaf anchor positions from data coordinates to blockscene pixel
   coordinates using `data_to_pixel(sc, ...)` plus the `viewport(sc)` origin,
   following the same pattern used by `CladeLabelLayer`.
3. Render the labels into `Makie.parent(sc)` instead of `p`.

This task must **not** push labels farther out by changing data limits. The fix
must be a rendering-target and coordinate-space correction, not a geometry hack.

#### Alignment behavior

Preserve the current left/right alignment semantics already established by
`lineageplot!(::LineageAxis, ...)` for rectangular panels:

- leaves on right → left-aligned labels with outward offset
- leaves on left → right-aligned labels with outward offset

#### Important note

After this change, rectangular leaf labels and clade bracket labels will both be
external annotations in the same owning panel gutter. Verify that the reserved
left/right gutter from Task 1 is large enough for both.

---

### 4. Add radial-specific leaf-label placement

**Type**: WRITE
**Output**: radial leaf labels are offset outward from the circle, not by a
fixed global +x shift.
**Depends on**: Task 3

Before modifying, read `Geometry.circular_layout` so you understand how radial
vertex positions are constructed.

#### Required design

In `LeafLabelLayer.plot!`, add a radial branch that activates when
`geom.boundingbox` / caller context indicates a circular layout. Do not infer
this from ad hoc coordinate heuristics if the relevant orientation value can be
threaded explicitly; if you need the orientation, add it as a proper attribute
from `LineagePlot` down to `LeafLabelLayer`.

For each radial leaf label:

1. Compute the outward direction from the layout center to the leaf position.
2. Normalize it.
3. Apply the label offset in **pixel space** along that outward direction.
4. Choose horizontal alignment so labels on the left half of the circle align
   rightward and labels on the right half align leftward.
5. Keep labels horizontal in Tier 1 unless the codebase already has an approved
   rotated-text pattern. This issue is about outward placement, not text rotation.

#### Constraints

- Do not change the radial geometry itself.
- Do not change edge shapes or vertex positions.
- This task is about label placement only.

---

### 5. Add regression tests for panel-owned decoration layout and radial label placement

**Type**: TEST
**Output**: new tests fail on the current code and pass after the Issue 16 fix.
**Depends on**: Tasks 1–4

Before writing tests, read `test/test_LineageAxis.jl`, `test/test_Layers.jl`,
and `test/test_Integration.jl` in full.

#### Additions to `test/test_LineageAxis.jl`

Add new testsets covering at least:

1. **Title text exists when `title != ""`**
   - Construct a `LineageAxis` with a non-empty title.
   - Force layout with `colorbuffer(fig)`.
   - Assert that a visible `Makie.Text` plot in `lax.blockscene.plots` contains
     the title string.

2. **Xlabel text exists when `xlabel != ""`**
   - Same pattern as title.

3. **Inner plotting viewport is inset from the full block bbox**
   - After layout resolution, assert that `viewport(lax.scene)[]` is strictly
     smaller than `lax.layoutobservables.computedbbox[]` in at least the
directions where title/x-axis/xlabel/gutters are active.

4. **X-axis ticks live in the panel-owned x-axis band**
   - Construct a lower-row panel figure analogous to `lineageplot_ex2.jl`.
   - Assert that the tick-label positions belong to the same blockscene as the
     owning panel and lie outside the plot viewport but inside the panel bbox.

#### Additions to `test/test_Layers.jl`

Add new testsets covering at least:

1. **Rectangular leaf labels have blockscene pixel positions after layout**
   - Force layout with `colorbuffer(fig)`.
   - Assert that the derived pixel-position vector is non-empty and finite.

2. **Radial leaf labels use mixed left/right alignments**
   - Build a radial layout with leaves on both halves of the circle.
   - Assert that the resolved alignments are not all identical and reflect
     outward placement.

3. **Clade labels and leaf labels coexist without empty geometry**
   - Use `clade_vertices` plus `leaf_label_func` in one panel.
   - Assert both annotation layers produce non-empty derived pixel positions.

#### Additions to `test/test_Integration.jl`

Add one integration-level regression test that constructs a 2×2 figure similar
to `examples/lineageplot_ex2.jl`, renders it, and asserts that:

- save succeeds
- the relevant decoration plots exist in each `LineageAxis.blockscene`
- no layer throws during render

The test does not need OCR or image comparison. This issue is about structural
rendering invariants, not pixel-diff snapshots.

---

### 6. Regenerate examples and verify visually

**Type**: VERIFY
**Output**: regenerated `lineageplot_ex2.png` with corrected panel-owned
annotations and no remaining Tier 1 clipping/overlap defects described above.
**Depends on**: Tasks 1–5

Run the full test suite first:

```bash
julia --project=test test/runtests.jl
```

Then regenerate the examples:

```bash
julia --project=examples examples/lineageplot_ex1.jl
julia --project=examples examples/lineageplot_ex2.jl
```

#### Expected visual outcomes in `lineageplot_ex2.png`

| Panel | Expected |
|-------|----------|
| Panel 1 (forward, `:edgelengths`) | Title visible. X-axis tick labels below the plot in its own x-axis band. Xlabel visible. Leaf labels on the right remain fully readable. Clade brackets/labels occupy the panel's right gutter and do not collide with panel 2. |
| Panel 2 (backward, `:vertexheights`) | Title visible. X-axis tick labels below the plot in its own x-axis band. Xlabel visible. Leaf labels and clade brackets/labels occupy the panel's left gutter and do not collide with panel 1. |
| Panel 3 (`:right_to_left`, forward) | Title visible. X-axis tick labels below the plot, not on the row divider. Leaf labels and clade brackets/labels occupy the left gutter and remain fully readable. |
| Panel 4 (radial) | Title visible. Radial leaf labels are offset outward from the circle; left-half labels do not use the same +x shift as right-half labels. No clade brackets are shown. |

`lineageplot_ex1.png` should remain visually unchanged except for any newly
implemented title/xlabel/x-axis decoration behavior that is already implied by
its example code.

---

## Verification checklist

```text
[ ] Read examples/lineageplot_ex2.jl in full before editing
[ ] Read src/LineageAxis.jl in full before editing
[ ] Read src/Layers.jl in full before editing
[ ] Read src/CoordTransform.jl in full before editing
[ ] Read test/test_LineageAxis.jl in full before editing
[ ] Read test/test_Layers.jl in full before editing
[ ] Added a private decoration-band / gutter helper in src/LineageAxis.jl
[ ] lax.scene now uses an inset plot rect, not the full block bbox
[ ] Title text renders from LineageAxis when title != ""
[ ] Xlabel text renders from LineageAxis when xlabel != ""
[ ] _wire_x_axis! now places ticks in a dedicated x-axis band
[ ] Rectangular leaf labels render in blockscene pixel coordinates
[ ] Rectangular leaf labels no longer depend on the data-clipped text! target
[ ] Radial leaf labels use outward placement logic
[ ] New testsets added to test/test_LineageAxis.jl
[ ] New testsets added to test/test_Layers.jl
[ ] New integration regression test added to test/test_Integration.jl
[ ] julia --project=test test/runtests.jl passes
[ ] examples/lineageplot_ex2.jl regenerated successfully
[ ] Titles, xlabels, leaf labels, and clade labels are readable and panel-owned
[ ] No visual overlap remains across the top-panel center seam
[ ] Bottom-left x-axis tick labels render below the panel, not on the row divider
```

---

## What NOT to change

- `Geometry.rectangular_layout` and `Geometry.circular_layout`
- edge-shape generation
- `CladeHighlightLayer` geometry or padding logic
- `reset_limits!` data padding unless a specific failing test proves it is part
  of the issue
- accessor semantics in `Accessors.jl`
- public vocabulary already established in `STYLE-vocabulary.md`

Scope discipline applies. If you discover a separate bug outside the files above,
report it explicitly rather than folding it silently into Issue 16.
