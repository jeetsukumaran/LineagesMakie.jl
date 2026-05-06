# Tasks for Issue 14: Orientation-aware label and annotation placement

Parent issue: Issue 14 (visual correctness; supplements Tier 1 — see
`.workflow-docs/202604181600_tier1/01_prd.md`)
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `STYLE-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

These are targeted fixes for visual correctness bugs found in
`examples/lineageplot_ex1.png` and `examples/lineageplot_ex2.png` after
completing the 13 main Tier 1 issues. No architectural changes are required;
all modifications are additions or replacements within existing functions.

---

## Background: identified bugs

**Bug 1 — Leaf labels point into the tree** (`lineageplot_ex1.png` and
`lineageplot_ex2.png` panels 1–3)

`LeafLabelLayer` defaults to `offset = Vec2f(4, 0)` (rightward) and
`align = (:left, :center)`. Correct when leaves are on the right (`:edgelengths`
+ standard polarity), wrong when leaves are on the left (`:vertexheights` +
standard polarity, or `:right_to_left` orientation). Fix: compute orientation-aware
defaults in `lineageplot!(ax::LineageAxis, ...)`.

**Bug 2 — Clade highlight rects extend beyond axis bounds**
(`lineageplot_ex2.png` top panels)

`CladeHighlightLayer` computes padding via `pixel_offset_to_data_delta`. When
`lax.scene` has a zero-size viewport at construction time (layout not yet resolved),
`CoordTransform.pixel_offset_to_data_delta` returns `pixel_offset` as a data-space
value (fallback path, `src/CoordTransform.jl:139`). With `padding = Vec2f(4, 4)`,
this produces `dx = 4.0` data units instead of ~0.01, creating rects that span the
full data range. Fix: clamp rects to `geom.boundingbox` so the output is bounded
regardless of the ComputeGraph recomputation timing.

**Bug 3 — Clade bracket always placed to the right of leaves**
(`lineageplot_ex2.png` panels 1–3)

`CladeLabelLayer` hardcodes `x_bar = x_right + dx`. When leaves are on the left,
the bracket appears inside the tree. Fix: `side` attribute + orientation-aware dispatch.

**Bug 4 — Internal node labels stack at clade roots**
(`lineageplot_ex2.png` panels 1–2)

`LineagePlot` defaults `vertex_label_threshold = (v -> true)` with
`vertex_label_func = (v -> "")`. Invisible empty-string text objects are created at
every vertex; clade roots are also labeled by `CladeLabelLayer`, producing overlapping
render objects. Fix: change default to `vertex_label_threshold = (v -> false)` so the
vertex label layer renders nothing until the user explicitly opts in.

**Bug 5 — X-axis ticks not visible despite `show_x_axis = true`**
(`lineageplot_ex2.png` panels 1–3)

`_wire_x_axis!` renders tick marks and labels in `lax.scene` at data-space
`y = ymin - offset`. The scene's orthographic projection clips to the data bounding
box, so `y < ymin` is outside the visible area. Fix: render ticks in `blockscene`
(the decoration layer, which is not clipped) using pixel-space positions from
`data_to_pixel`.

**Bug 6 — Radial leaf labels point inward (Tier 2 — deferred)**

`LeafLabelLayer` has no concept of angular outward direction. Deferred to Tier 2;
requires an `angular_offset` attribute and per-leaf angle computation in `LeafLabelLayer`.

---

## Orientation convention (Tasks 1, 3, and 6)

A leaf renders on the **left** side of the screen when:
- `lineageunits` is backward (`:vertexheights`, `:coalescenceage`) AND
  `display_polarity = :standard`, OR
- `lineageunits` is forward AND (`display_polarity = :reversed` OR
  `lineage_orientation = :right_to_left`).

In code, after resolving defaults:

```julia
backward           = resolved_lu in (:vertexheights, :coalescenceage)
effective_reversed = (dp === :reversed) || (lo === :right_to_left)
leaves_on_left     = xor(backward, effective_reversed)
```

`lineage_orientation = :radial` is excluded; radial placement is Tier 2.

---

## Tasks

### 1. Orientation-aware leaf label defaults in `lineageplot!(ax::LineageAxis, ...)`

**Type**: WRITE
**Output**: `lineageplot!(ax::LineageAxis, ...)` passes orientation-correct
`leaf_label_offset` and `leaf_label_align` defaults when the caller has not
supplied them; leaf labels appear beyond the leaf tips for all rectangular
orientation combinations.
**Depends on**: none

Before modifying any code, read in full:

- `src/LineageAxis.jl` — the `lineageplot!(ax::LineageAxis, ...)` method.
- `src/Layers.jl` — `LeafLabelLayer` attribute block and `LineagePlot` attribute
  block for `leaf_label_offset` and `leaf_label_align`.

Modify `lineageplot!(ax::LineageAxis, ...)` in `src/LineageAxis.jl`:

1. After `resolved_lu = _resolve_lineageunits_stub(lineageunits, accessor)`,
   compute `leaves_on_left`:

   ```julia
   lo                 = ax.lineage_orientation[]
   dp                 = ax.display_polarity[]
   backward           = resolved_lu in (:vertexheights, :coalescenceage)
   effective_reversed = (dp === :reversed) || (lo === :right_to_left)
   leaves_on_left     = xor(backward, effective_reversed)
   ```

2. Build `orientation_defaults` (only when `lo !== :radial`):

   ```julia
   orientation_defaults = if lo !== :radial && leaves_on_left
       (leaf_label_offset = Makie.Vec2f(-4, 0),
        leaf_label_align  = (:right, :center))
   else
       NamedTuple()
   end
   merged_kwargs = merge(orientation_defaults, kwargs)
   ```

3. Replace `kwargs...` in the `lineageplot!(ax.scene, ...)` call with
   `merged_kwargs...`.

4. Update the docstring.

---

### 2. Clamp clade highlight rects to the layout bounding box

**Type**: WRITE
**Output**: Every `Rect2f` in `CladeHighlightLayer`'s `highlight_rects` derived
attribute is bounded by `geom.boundingbox` plus one padding unit; no rect extends
beyond the axis data extent.
**Depends on**: none

Before modifying, read `src/Layers.jl` — the `CladeHighlightLayer.plot!`
`_highlight_rects` `map!` closure.

In the `_highlight_rects` `map!` closure, after computing `dx` and `dy` (from
`pixel_offset_to_data_delta`), add a clamping step:

```julia
bb         = geom.boundingbox
bb_x0      = Float32(Makie.minimum(bb)[1])
bb_x1      = Float32(Makie.maximum(bb)[1])
bb_y0      = Float32(Makie.minimum(bb)[2])
bb_y1      = Float32(Makie.maximum(bb)[2])
padded_xmin = max(xmin - dx, bb_x0 - dx)
padded_xmax = min(xmax + dx, bb_x1 + dx)
padded_ymin = max(ymin - dy, bb_y0 - dy)
padded_ymax = min(ymax + dy, bb_y1 + dy)
```

Replace `push!(rects, Rect2f(xmin - dx, ymin - dy, ...))` with:

```julia
push!(
    rects,
    Rect2f(
        padded_xmin, padded_ymin,
        padded_xmax - padded_xmin,
        padded_ymax - padded_ymin,
    ),
)
```

Update the docstring.

---

### 3. Orientation-aware clade bracket direction

**Type**: WRITE
**Output**: `CladeLabelLayer` exposes a `side` attribute (`:right` | `:left`);
`LineagePlot` exposes `clade_label_side`; `lineageplot!(ax::LineageAxis, ...)`
passes the correct side; bracket geometry and label alignment flip for left-side.
**Depends on**: Task 1 (shares `leaves_on_left`)

Before modifying, read in full:

- `src/Layers.jl` — `CladeLabelLayer` `@recipe` block, `_bracket_shapes` map!,
  `_bracket_label_data` map!, and the `lines!` + `text!` calls.
- `LineagePlot` `@recipe` block and its `cladelabellayer!` call.
- `src/LineageAxis.jl` as modified by Task 1.

**Step A — `side` attribute on `CladeLabelLayer`:**

```julia
"Bracket side relative to leaf tips: :right (leaves at right) or :left (leaves at left)."
side = :right
```

**Step B — `_bracket_shapes` map!: side-dispatched geometry:**

Add `:side` to the input key list. Replace the bracket-geometry block with:

```julia
nan = Point2f(NaN, NaN)
if side === :right
    x_anchor = maximum(q[1] for q in leaf_pts)
    anchor   = Point2f(x_anchor, mid_y)
    dx_off   = pixel_offset_to_data_delta(sc, anchor, Vec2f(offset[1], 0))[1]
    dx_tick  = pixel_offset_to_data_delta(sc, anchor, Vec2f(3.0f0, 0))[1]
    x_bar    = x_anchor + dx_off
    push!(pts, Point2f(x_bar - dx_tick, y_min), Point2f(x_bar, y_min), nan)
    push!(pts, Point2f(x_bar, y_min),            Point2f(x_bar, y_max), nan)
    push!(pts, Point2f(x_bar, y_max),            Point2f(x_bar - dx_tick, y_max), nan)
else  # :left
    x_anchor = minimum(q[1] for q in leaf_pts)
    anchor   = Point2f(x_anchor, mid_y)
    dx_off   = pixel_offset_to_data_delta(sc, anchor, Vec2f(offset[1], 0))[1]
    dx_tick  = pixel_offset_to_data_delta(sc, anchor, Vec2f(3.0f0, 0))[1]
    x_bar    = x_anchor - dx_off
    push!(pts, Point2f(x_bar + dx_tick, y_min), Point2f(x_bar, y_min), nan)
    push!(pts, Point2f(x_bar, y_min),            Point2f(x_bar, y_max), nan)
    push!(pts, Point2f(x_bar, y_max),            Point2f(x_bar + dx_tick, y_max), nan)
end
```

Remove the standalone `nan = Point2f(NaN, NaN)` that precedes the outer loop
(it is now inside the `side`-dispatched block).

**Step C — `_bracket_label_data` map!: correct position and alignment:**

Add `:side` to the input key list. Change the tuple element type to
`Tuple{Point2f, String, Symbol}` (third element = horizontal alignment):

```julia
if side === :right
    x_anchor = maximum(q[1] for q in leaf_pts)
    anchor   = Point2f(x_anchor, mid_y)
    dx_off   = pixel_offset_to_data_delta(sc, anchor, Vec2f(offset[1], 0))[1]
    x_bar    = x_anchor + dx_off
    push!(entries, (Point2f(x_bar, mid_y), string(label_func(mrca)), :left))
else  # :left
    x_anchor = minimum(q[1] for q in leaf_pts)
    anchor   = Point2f(x_anchor, mid_y)
    dx_off   = pixel_offset_to_data_delta(sc, anchor, Vec2f(offset[1], 0))[1]
    x_bar    = x_anchor - dx_off
    push!(entries, (Point2f(x_bar, mid_y), string(label_func(mrca)), :right))
end
```

Update the two downstream map! closures that extract positions and strings to
use `(pos, _, _)` and `(_, str, _)` destructuring. Add a third:

```julia
map!(p.attributes, [:bracket_label_data], :bracket_label_haligns) do entries
    return [halign for (_, _, halign) in entries]
end
```

Add a fourth to produce full `align` tuples:

```julia
map!(p.attributes, [:bracket_label_haligns], :bracket_label_aligns) do haligns
    return [(h, :center) for h in haligns]
end
```

In the `text!` call replace `align = (:left, :center)` with
`align = p[:bracket_label_aligns]`. If Makie 0.24 does not accept a vector of
`align` tuples, split into two `text!` calls (one per side) instead.

**Step D — `clade_label_side` in `LineagePlot`:**

Add to `@recipe LineagePlot`:

```julia
"Side on which the clade bracket is placed: :right or :left."
clade_label_side = :right
```

In `Makie.plot!(lp::LineagePlot)`, add `side = lp[:clade_label_side]` to the
`cladelabellayer!` kwargs.

**Step E — set `clade_label_side` in `lineageplot!(ax::LineageAxis, ...)`:**

Extend `orientation_defaults` from Task 1:

```julia
orientation_defaults = if lo !== :radial
    side_kw = (clade_label_side = leaves_on_left ? :left : :right,)
    if leaves_on_left
        merge(side_kw,
              (leaf_label_offset = Makie.Vec2f(-4, 0),
               leaf_label_align  = (:right, :center)))
    else
        side_kw
    end
else
    NamedTuple()
end
```

---

### 4. Change default `vertex_label_threshold` to `v -> false`

**Type**: WRITE
**Output**: `LineagePlot` renders no vertex labels by default; users must supply
an explicit `vertex_label_threshold` predicate to opt in. Visual artifacts from
empty-string text objects at every vertex are eliminated.
**Depends on**: none

Before modifying, read `src/Layers.jl` — the `@recipe LineagePlot` attribute
block, specifically the `vertex_label_threshold` and `vertex_label_func` lines.

In `src/Layers.jl`, in the `@recipe LineagePlot (rootvertex, accessor) begin
... end` block, change:

```julia
vertex_label_threshold = (v -> true)
```

to:

```julia
"Predicate vertex -> Bool; only vertices returning true are labelled. Default: none (opt-in)."
vertex_label_threshold = (v -> false)
```

No other changes are needed. Update the docstring for `lineageplot!` to note
that vertex labels are off by default.

---

### 5. Fix x-axis tick rendering in `_wire_x_axis!`

**Type**: WRITE
**Output**: When `show_x_axis = true`, tick marks and labels appear below the
lineage graph data area and are not clipped by the scene viewport.
**Depends on**: none

Before modifying, read in full:

- `src/LineageAxis.jl` — `_wire_x_axis!` (the full function including
  `_update_ticks` and the two `on` callbacks) and `initialize_block!`.
- `src/CoordTransform.jl` — `data_to_pixel` (the exact pixel-space convention:
  origin at scene viewport bottom-left, y increasing upward).

The problem: ticks are placed in `lax.scene` at `y = ymin - offset_data`, which
the scene's orthographic projection clips. The fix: render in `blockscene`
(decoration layer, no data clip) using pixel coordinates.

Replace `_wire_x_axis!(lax::LineageAxis, blockscene::Scene)` with the following
implementation. Read the existing function first; the structure is the same but
the rendering target and coordinate computation change.

The new approach:

1. **Keep `scatter!` and `text!` calls in `blockscene`** (not `lax.scene`), so
   they are not subject to the data-viewport clip.

2. **Compute tick positions in blockscene pixel space** inside `_update_ticks()`:
   - `lax.scene`'s viewport (`sc_vp = viewport(lax.scene)[]`) gives the scene's
     position and size within `blockscene` in pixel coordinates.
   - For each x tick value, convert from data space to `lax.scene` pixel space:
     `px = CoordTransform.data_to_pixel(lax.scene, Point2f(x_val, 0.0f0))`
   - Convert to `blockscene` pixel space:
     `block_x = Float32(sc_vp.origin[1]) + px[1]`
     `block_y = Float32(sc_vp.origin[2]) - 10.0f0`  # 10px below scene bottom
   - Tick position in `blockscene`: `Point2f(block_x, block_y)`

3. **`blockscene` uses pixel coordinates** (origin at block bottom-left, y
   increasing upward). The `scatter!` and `text!` calls in `blockscene` receive
   positions in these pixel coordinates. No `markerspace = :pixel` needed since
   `blockscene` is already in pixel space.

4. **Reactivity**: the `on(lax.last_geom)` and `on(lax.show_x_axis)` callbacks
   already exist; add a third `on(blockscene, viewport(lax.scene))` so that
   ticks recompute if the scene's layout position changes.

The `scatter!` call (zero-size marker for positioning) and `text!` call remain
structured as before, but with positions supplied as `Point2f` in `blockscene`
pixel coordinates and with `space = :pixel` if needed (check whether
`blockscene` already interprets positions as pixels — in Makie, a scene's local
coordinates are pixel coordinates when the scene has no camera override, which
`blockscene` does not).

Update the docstring for `_wire_x_axis!`.

Do not change `initialize_block!`. Do not move any other rendering out of
`lax.scene`.

---

### 6. Tests for all visual correctness fixes

**Type**: TEST
**Output**: `@testset` blocks in `test/test_LineageAxis.jl` and
`test/test_Layers.jl` verify all five fixes; the full test suite passes.
**Depends on**: Tasks 1, 2, 3, 4, 5

Before writing tests, read `test/test_LineageAxis.jl` and `test/test_Layers.jl`
in full. Use the exact fixture variable names already present in those files.

**Additions to `test/test_LineageAxis.jl`:**

```julia
@testset "lineageplot! orientation-aware leaf label defaults" begin
    # Backward (vertexheights) + standard → leaves left → labels go left.
    fig = Figure()
    lax = LineageAxis(fig[1, 1])
    lp  = lineageplot!(lax, root4, acc_no_el; leaf_label_func = v -> string(v))
    ll  = only(filter(p -> p isa LeafLabelLayer, lp.plots))
    @test ll[:offset][] == Makie.Vec2f(-4, 0)
    @test ll[:align][]  == (:right, :center)

    # Forward (edgelengths) + standard → leaves right → recipe defaults.
    fig2 = Figure()
    lax2 = LineageAxis(fig2[1, 1])
    lp2  = lineageplot!(lax2, root4, acc_el; leaf_label_func = v -> string(v))
    ll2  = only(filter(p -> p isa LeafLabelLayer, lp2.plots))
    @test ll2[:offset][] == Makie.Vec2f(4, 0)
    @test ll2[:align][]  == (:left, :center)

    # right_to_left + backward → double reversal → leaves right.
    fig3 = Figure()
    lax3 = LineageAxis(fig3[1, 1]; lineage_orientation = :right_to_left)
    lp3  = lineageplot!(lax3, root4, acc_no_el; leaf_label_func = v -> string(v))
    ll3  = only(filter(p -> p isa LeafLabelLayer, lp3.plots))
    @test ll3[:offset][] == Makie.Vec2f(4, 0)
    @test ll3[:align][]  == (:left, :center)
end

@testset "lineageplot! orientation-aware clade_label_side" begin
    fig = Figure()
    lax = LineageAxis(fig[1, 1])
    lp  = lineageplot!(lax, root4, acc_no_el; clade_vertices = [root4])
    @test lp[:clade_label_side][] === :left

    fig2 = Figure()
    lax2 = LineageAxis(fig2[1, 1])
    lp2  = lineageplot!(lax2, root4, acc_el; clade_vertices = [root4])
    @test lp2[:clade_label_side][] === :right
end

@testset "x-axis ticks within blockscene viewport when show_x_axis = true" begin
    fig = Figure(); lax = LineageAxis(fig[1, 1]; show_x_axis = true)
    lp  = lineageplot!(lax, root4, acc_el)
    # Trigger rendering so layout resolves.
    CairoMakie.colorbuffer(fig)
    # At minimum: assert that lax.scene's viewport has non-zero size.
    @test !iszero(Makie.widths(Makie.viewport(lax.scene)[])[1])
    # Assert tick positions are below the scene (in blockscene coords).
    # Full tick visibility is verified by running the examples.
end
```

(`acc_no_el` = accessor without `edgelength`; `acc_el` = accessor with
`edgelength = (u, v) -> 1.0`. Use the variable names from the existing fixtures.)

**Additions to `test/test_Layers.jl`:**

```julia
@testset "CladeHighlightLayer rects clamped to bounding box" begin
    fig = Figure(); ax = Axis(fig[1, 1])
    lp  = lineageplot!(ax, root4, acc_no_el; clade_vertices = [root4])
    chl = only(filter(p -> p isa CladeHighlightLayer, lp.plots))
    bb  = lp[:computed_geom][].boundingbox
    tol = 0.5f0
    for r in chl[:highlight_rects][]
        @test r.origin[1] >= Float32(Makie.minimum(bb)[1]) - tol
        @test r.origin[1] + r.widths[1] <= Float32(Makie.maximum(bb)[1]) + tol
        @test r.origin[2] >= Float32(Makie.minimum(bb)[2]) - tol
        @test r.origin[2] + r.widths[2] <= Float32(Makie.maximum(bb)[2]) + tol
    end
end

@testset "vertex_label_threshold defaults to v -> false" begin
    fig = Figure(); ax = Axis(fig[1, 1])
    lp  = lineageplot!(ax, root4, acc_no_el)
    vll = only(filter(p -> p isa VertexLabelLayer, lp.plots))
    # With threshold = v -> false, no vertex passes → zero label positions.
    @test isempty(vll[:vertex_label_positions][])
end
```

Run `julia --project=test test/runtests.jl` and confirm all tests pass.

---

## Verification

After all tasks, regenerate examples:

```
julia --project=examples examples/lineageplot_ex1.jl
julia --project=examples examples/lineageplot_ex2.jl
```

Expected:
- **ex1**: leaf labels to the LEFT of leaf dots, no branch overlap.
- **ex2**:
  - Panel 1 (`:edgelengths`, standard): labels right of leaves ✓; highlights
    within panel ✓; bracket on right ✓; x-axis ticks visible ✓.
  - Panel 2 (`:vertexheights`, standard): labels left of leaves ✓; highlights
    within panel ✓; bracket on left ✓; x-axis ticks visible ✓.
  - Panel 3 (`:right_to_left`): labels right of leaves ✓; bracket on right ✓;
    x-axis ticks visible ✓.
  - Panel 4 (`:radial`): labels unchanged (radial placement Tier 2) ✓; scale
    bar visible ✓.
  - No label stacking at internal nodes in any panel ✓.
- All tests pass: `julia --project=test test/runtests.jl`.
