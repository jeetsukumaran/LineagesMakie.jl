---
date-created: 2026-04-22T19:11:10
date-updated: 2026-04-22T19:11:10
---

# Salvaged session analysis — Tier 1 visual correctness issues

Source: JSONL session `e7159d37-a1f6-455e-b76a-e3c350c1cd97`, lines 387 and 395.
Recovered after context compaction interrupted the session before the task file could be written.

---

## Current state (post-Issue-11)

401/401 tests pass.

**`LineageAxis` is fully implemented (Issue 11 complete).** It delivers `display_polarity`,
`lineage_orientation`, `reset_limits!`, `axis_polarity` inference, and the
`lineageplot!(ax::LineageAxis, ...)` dispatch. The orientation flip is now available — using
`LineageAxis` instead of a plain `Axis` and setting `display_polarity = :reversed` (or
`lineage_orientation = :right_to_left`) correctly places the root at the left.

**The leaf label overlap is not resolved yet, in either path.** `lineageplot!(ax::LineageAxis,
...)` ([src/LineageAxis.jl:402](src/LineageAxis.jl#L402)) calls `leaflabellayer!(ax, geom,
accessor)` with no offset argument, so it inherits the default `Vec2f(4, 0)` (rightward)
regardless of orientation. The `LineageAxis` has the information needed to compute the correct
offset (from `lineage_orientation` and `display_polarity`), but that wiring isn't done.

**What's left in Tier 1:** Issue 12 (full composite recipe, Observable reactivity,
orientation-aware label placement) and Issue 13 (full integration test suite). The plain-`Axis`
stub and the `LineageAxis` stub both have correct structure — Issue 12 replaces both stubs with
the real composite recipe.

---

## Visual bug inventory

From image analysis of `lineageplot_ex1.png` and `lineageplot_ex2.png` after Issue 11
implementation.

### `lineageplot_ex1.png` — 4-leaf tree on `LineageAxis`

The tree renders structurally correct (right-angle edges, 3 internal vertex markers, 4 leaf
markers). One clear problem:

1. **Leaf labels overlap the branch lines.** The labels `b2`, `b1`, `a2`, `a1` are placed
   immediately to the right of the leaf dot, which is also where the horizontal branch segment
   starts. The text sits on top of the branch. Root cause: `LeafLabelLayer` default
   `offset = Vec2f(4, 0)` and `align = (:left, :center)` — 4 px rightward — points INTO the tree
   because leaves sit at x=0 (leftmost) in `:vertexheights` geometry. The correct default for
   this orientation would be `Vec2f(-4, 0)` / `align = (:right, :center)`.

### `lineageplot_ex2.png` — 4-panel figure on `LineageAxis`

2. **Clade highlight rectangles bleed massively across panel boundaries.** The blue
   `CladeHighlightLayer` rectangles span nearly the full figure width, cutting across all four
   panels. The clade bounding boxes are being computed in a coordinate space that is not scoped to
   each panel's scene. This suggests the highlight geometry is either using the wrong scene
   reference for coordinate conversion or the padding/bounding-box computation is scaling
   incorrectly.

3. **Internal node labels stack on top of each other.** In panels 1 and 2, labels appear printed
   twice or more at the same screen position. `lineageplot!` calls `vertexlabellayer!` with
   `threshold = v -> true` unconditionally, then also calls `cladelabellayer!`. Clade roots get
   labelled by both layers at the same position.

4. **Leaf labels in left-orientation panels (panels 2, 3) still point into the tree** — same
   cause as ex1.

5. **Radial panel (bottom-right):** The chord-based radial layout renders structurally but leaf
   labels extend in a fixed direction (rightward) regardless of which direction is "outward" from
   each leaf tip. Labels at the bottom or left of the circle point into the tree rather than away
   from it.

6. **No visible x-axis ticks** in the three panels that declare `show_x_axis = true`. The tick
   labels may be rendering outside the scene viewport (below the bottom of the clipped area) due
   to how `_wire_x_axis!` places them at `ymin - offset` in data space.

### Priority table

| # | Problem | Location |
|---|---|---|
| 1 | Clade highlight boxes span full figure, cross panel boundaries | ex2, all panels |
| 2 | Leaf labels overlap branch lines (wrong offset direction) | ex1, ex2 panels 2+3 |
| 3 | Internal node labels stack / collide | ex2 panels 1+2 |
| 4 | Radial leaf labels point inward regardless of angular position | ex2 panel 4 |
| 5 | X-axis ticks not visible despite `show_x_axis = true` | ex2 panels 1+2+3 |

---

## (1) Nature of each issue

| Problem | Character |
|---|---|
| Clade highlight bleeding across panels | **Structural bug** — the `rect!` call in `CladeHighlightLayer` is almost certainly targeting the wrong scene (a parent or figure-level scene instead of `lax.scene`), so Makie's viewport clipping never applies. Locatable and small. |
| Leaf label direction (labels into tree) | **Design coordination gap** — `LeafLabelLayer` has the right mechanism (offset/align attributes) but `lineageplot!(ax::LineageAxis, ...)` never computes and passes orientation-aware defaults. The fix exists, it just hasn't been wired. |
| Label stacking at internal nodes | **Logic issue** — `lineageplot!` calls `vertexlabellayer!` with default `threshold = v -> true` unconditionally, then also calls `cladelabellayer!`. In ex2 the clade roots get labelled by both layers at the same position. Fixable by tuning the default threshold or call order. |
| Radial leaf labels pointing inward | **Design limitation** — `LeafLabelLayer` has no concept of angular outward direction. The `Vec2f(4, 0)` offset is meaningless for polar geometry. Needs an angular-offset mode added to `LeafLabelLayer`. More substantive than the others but still contained. |
| X-axis ticks not visible | **Architecture mismatch** — `_wire_x_axis!` places tick marks in `lax.scene` at `y < ymin`, which gets clipped by the scene viewport. Ticks need to live in `blockscene` (outside the data clip area), the way Makie's own `Axis` separates the plot scene from the decoration scene. |

None of these is a fundamental design flaw. The three-layer model (geometry → layers → axis) is
sound. The issues are all in the wiring layer.

---

## (2) Scope of fix

No refactoring, no rearchitecture. All five are targeted edits:

- **Clade highlight**: 1–3 lines — find the scene reference passed to `rect!` and correct it to
  `get_scene(ax)`.
- **Leaf label direction**: ~5 lines in `lineageplot!(ax::LineageAxis, ...)` — compute
  `effective_reversed` from `lineage_orientation` and `display_polarity` already available on
  `ax`, then pass `offset` and `align` to `leaflabellayer!`.
- **Label stacking**: Change the default `lineageplot!` call to
  `vertexlabellayer!(ax, geom, accessor; threshold = v -> false)` (labels off by default, user
  opts in).
- **Radial labels**: Add an `angular_offset` attribute and a branch in `LeafLabelLayer.plot!`
  that computes outward direction from the leaf's position relative to the origin.
- **X-axis ticks**: Move `text!` and `scatter!` from `lax.scene` to `blockscene` in
  `_wire_x_axis!`, mapping data-space x to pixel-space coordinates for the decoration layer.

---

## (3) Can these be tested?

Pixel-level visual regression (reference image comparison) is possible but brittle — most Julia
packages avoid it. However, the geometric properties that produce these visual bugs ARE testable:

- **Clade highlight scene scope**: assert that the `rect!` geometry returned by
  `CladeHighlightLayer` has all corners within `geom.boundingbox` — out-of-bounds coordinates
  diagnose the wrong-scene bug without rendering.
- **Leaf label direction**: after `colorbuffer`, assert that all `leaf_label_positions[]` have
  x ≤ minimum leaf x (for leaves-on-left) or x ≥ maximum leaf x (for leaves-on-right).
- **Label stacking**: assert that all `vertex_label_positions[]` are pairwise distinct (within
  floating-point tolerance).
- **Radial labels**: assert that the distance of each `leaf_label_positions[]` from the origin is
  strictly greater than the corresponding `leaf_pos_data[]` distance — labels are always outward
  of the leaf.
- **X-axis ticks**: after `colorbuffer`, assert that `tick_positions[]` lie within the scene's
  `viewport[]` rectangle.

So yes — each visual bug maps to a geometric invariant that can be stated as a `@test` without
pixel comparison.
