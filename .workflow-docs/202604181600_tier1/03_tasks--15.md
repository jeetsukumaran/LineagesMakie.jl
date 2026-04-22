# Tasks for Issue 15: Clade bracket rendering in blockscene

Parent issue: Issue 15 (visual correctness; supplements Tier 1 — see
`.workflow-docs/202604181600_tier1/01_prd.md`)
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `STYLE-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

These are targeted fixes for visual correctness bugs remaining after Issue 14.
The 501/501 test suite passes at the start of this issue.
No architectural changes are required; all modifications are additions or
replacements within existing functions.

---

## Reading mandate

**Before touching any code**, read every file listed below — **completely,
line by line, no skipping**. The implementation depends on exact function
signatures, attribute names, map! dependency chains, and scene-hierarchy
details that cannot be inferred without reading. The files are short enough
to read in full; partial reading will produce incorrect implementations.

### Primary files (read in full before any edit)

| File | Why it is critical |
|------|-------------------|
| `src/Layers.jl` | Contains `CladeLabelLayer` — the recipe being changed. Read the full `@recipe`, `Makie.plot!`, all `map!` closures, `lines!`, and `text!` calls. Know the exact attribute names and their computation chain. |
| `src/LineageAxis.jl` | Contains `_wire_x_axis!` — the **reference implementation** for the blockscene pattern this issue mirrors. Also read `initialize_block!` to understand `lax.scene` and `blockscene` construction. |
| `src/CoordTransform.jl` | Contains `data_to_pixel`, `pixel_offset_to_data_delta`, and `register_pixel_projection!`. Understand the pixel-space convention (origin at scene bottom-left, y up) and the fallback behaviour on degenerate viewports. |
| `test/test_Layers.jl` | Contains all existing `CladeLabelLayer` tests. Know exactly what is tested so you do not break any existing assertion. |
| `test/test_LineageAxis.jl` | Contains all existing `LineageAxis` tests including the clade-bracket-side tests added in Issue 14. |

### Secondary files (read the sections indicated)

| File | Sections to read |
|------|-----------------|
| `src/Layers.jl` | `CladeHighlightLayer` — observe how `register_pixel_projection!` + `map!` + `pixel_offset_to_data_delta` + `abs(dx)` are combined after the Issue 14 fix. The bracket fix follows an analogous reactive pattern. |
| `examples/lineageplot_ex2.jl` | Read in full so you understand the four panels being verified. |

### Design documents (read once for governance)

| File | Purpose |
|------|---------|
| `.workflow-docs/202604181600_tier1/01_prd.md` | PRD, controlled vocabulary cross-reference |
| `STYLE-julia.md` | Julia coding standards (docstrings, no magic numbers, guard clauses, etc.) |
| `STYLE-vocabulary.md` | Canonical identifier spellings — do not introduce synonyms |

---

## Background: identified bugs

### Bug A — Clade brackets clipped by the data-viewport

`CladeLabelLayer.plot!` renders its `lines!` and `text!` calls into `p` (the
recipe plot), which puts them in `ax.scene` — the data-clipped plotting scene.
The bracket is intentionally placed **outside** the data range: at
`x_bar = x_anchor + dx_off` (for `:right`, where `dx_off ≈ 6–10 pixels` in
data units), or `x_bar = x_anchor - dx_off` (for `:left`). Because `x_bar` is
outside `[bb_x0, bb_x1]`, the axis scene's orthographic camera clips the lines
and they are invisible or only barely visible as edge artifacts.

This is structurally identical to the x-axis-tick bug fixed in Issue 14 Task 5.
The resolution is the same: move the rendering target from `ax.scene` to the
**decoration scene** (`blockscene` / `Makie.parent(sc)`), which is not subject
to data-viewport clipping.

### Bug B — Label text shares the same wrong rendering target

The `text!` call for bracket labels has the same problem. Labels appear at
data-space positions outside the axis limits and are clipped along with the
bracket lines.

---

## Architecture note: `ax.scene` vs `blockscene`

`LineageAxis.initialize_block!` creates:

```julia
scenearea = lift(round_to_IRect2D, blockscene, lax.layoutobservables.computedbbox)
lax.scene = Scene(blockscene, scenearea; clear = false, visible = false)
```

`lax.scene` is a **child scene** of `blockscene`. Its parent is `blockscene`.
For a plain `Axis`, the same relationship holds: the axis plot scene is a child
of the axis's `blockscene`. Therefore, inside any recipe:

```julia
sc              = parent_scene(p)        # ax.scene — data-clipped
decoration_sc   = Makie.parent(sc)       # blockscene — pixel space, no data clip
```

Positions in `decoration_sc` are in **blockscene pixel coordinates**: origin at
the block bottom-left, x right, y up. To convert a data-space point to
blockscene pixel coordinates:

```julia
sc_vp   = Makie.viewport(sc)[]                     # sc's pixel rect within blockscene
px      = data_to_pixel(sc, data_pt)               # pixel within sc (origin at sc bottom-left)
block_pt = Point2f(sc_vp.origin[1] + px[1],        # translate to blockscene origin
                   sc_vp.origin[2] + px[2])
```

`_wire_x_axis!` in `src/LineageAxis.jl` implements this conversion verbatim —
**read that function before writing any conversion code here**.

---

## Coordinate sign note: signed `dx_off` for reversed axes

`pixel_offset_to_data_delta` returns a **signed** delta. On a reversed axis
(`:right_to_left` or `display_polarity = :reversed`), moving `+N` pixels
rightward corresponds to **negative** data displacement. Therefore:

- `:right` bracket: `x_bar = x_anchor + dx_off` — negative `dx_off` moves the
  bracket to the **data-left**, which is **screen-right** on a reversed axis. ✓
- `:left` bracket: `x_bar = x_anchor - dx_off` — negative `dx_off` becomes
  `x_anchor + |dx_off|`, moving the bracket to the **data-right**, which is
  **screen-left** on a reversed axis. ✓

**Do NOT apply `abs()` to `dx_off` or `dx_tick` in `CladeLabelLayer`**. The
signed value is correct and necessary. (`abs` was applied in `CladeHighlightLayer`
for symmetric padding expansion — a different use case. The bracket has a fixed
direction, not symmetric expansion.)

---

## Tasks

### 1. Move `CladeLabelLayer` rendering to the decoration scene

**Type**: WRITE
**Output**: Bracket `lines!` and label `text!` are rendered in
`Makie.parent(sc)` (blockscene / decoration layer), not in `p`. Brackets are
visible beyond the axis data boundary without being clipped.
**Depends on**: none

Before modifying, read `src/Layers.jl` `CladeLabelLayer` in its entirety.
Read `_wire_x_axis!` in `src/LineageAxis.jl` as the reference pattern.
Read `src/CoordTransform.jl` for `data_to_pixel`.

**Step A — add `data_to_pixel` to the `CoordTransform` import in `Layers.jl`:**

At the top of `src/Layers.jl`, the current import is:

```julia
using LineagesMakie.CoordTransform: register_pixel_projection!, pixel_offset_to_data_delta
```

Add `data_to_pixel`:

```julia
using LineagesMakie.CoordTransform: register_pixel_projection!, pixel_offset_to_data_delta, data_to_pixel
```

**Step B — add pixel-space derived attributes in `Makie.plot!(p::CladeLabelLayer)`:**

After the existing `map!` closures for `:bracket_shapes` and `:bracket_label_data`
(and the downstream `:bracket_label_positions`, `:bracket_label_strings`,
`:bracket_label_haligns`, `:bracket_label_aligns`), insert two new `map!`
closures that convert data-space positions to blockscene pixel coordinates.

The first converts NaN-separated bracket line points:

```julia
map!(
    p.attributes,
    [:bracket_shapes, :pixel_projection],
    :bracket_pixel_shapes,
) do shapes, _
    sc_vp = Makie.viewport(sc)[]
    result = Point2f[]
    for pt in shapes
        if isnan(pt[1]) || isnan(pt[2])
            push!(result, Point2f(NaN, NaN))
        else
            px = data_to_pixel(sc, pt)
            push!(result, Point2f(
                Float32(sc_vp.origin[1]) + px[1],
                Float32(sc_vp.origin[2]) + px[2],
            ))
        end
    end
    return result
end
```

The second converts label anchor positions:

```julia
map!(
    p.attributes,
    [:bracket_label_positions, :pixel_projection],
    :bracket_label_pixel_positions,
) do positions, _
    sc_vp = Makie.viewport(sc)[]
    return Point2f[
        Point2f(
            Float32(sc_vp.origin[1]) + data_to_pixel(sc, pos)[1],
            Float32(sc_vp.origin[2]) + data_to_pixel(sc, pos)[2],
        )
        for pos in positions
    ]
end
```

Both map! closures depend on `:pixel_projection` (which fires whenever
`viewport(sc)` or `projectionview` changes) so they recompute correctly after
layout resolution.

**Step C — change `lines!` and `text!` to target `Makie.parent(sc)`:**

Replace the current `lines!` and `text!` calls (which use `p` as parent and
data-space attributes) with calls that target the decoration scene directly:

```julia
decoration_sc = Makie.parent(sc)

lines!(
    decoration_sc,
    p[:bracket_pixel_shapes];
    color   = p[:color],
    visible = p[:visible],
)
text!(
    decoration_sc,
    p[:bracket_label_pixel_positions];
    text     = p[:bracket_label_strings],
    fontsize = p[:fontsize],
    color    = p[:color],
    align    = p[:bracket_label_aligns],
    visible  = p[:visible],
)
```

Note: these calls target `decoration_sc` directly, NOT `p`. Their content will
NOT appear in `p.plots` — that is expected. All other sub-layer rendering
(CladeHighlightLayer, EdgeLayer, etc.) continues to use `p` as before; only
`CladeLabelLayer`'s final `lines!` and `text!` move to the decoration scene.

**Step D — update the docstring for `CladeLabelLayer` / `cladelabellayer!`:**

Add a note that bracket and label rendering target the decoration scene
(`Makie.parent(parent_scene(p))`), not the data-clipped axis scene, so that
brackets appear beyond the data extent without clipping.

---

### 2. Tests for bracket visibility

**Type**: TEST
**Output**: New `@testset` blocks verify that brackets render in blockscene
pixel coordinates after layout resolution and are not clipped by the axis data
viewport.
**Depends on**: Task 1

Before writing tests, read `test/test_Layers.jl` and `test/test_LineageAxis.jl`
in full. Use the exact fixture variable names already present.

**Additions to `test/test_Layers.jl`** inside `@testset "CladeLabelLayer"`:

```julia
@testset "bracket renders in decoration scene (not clipped)" begin
    fig = Figure(; size = (400, 300))
    ax  = Axis(fig[1, 1])
    lp  = lineageplot!(ax, _LT_BALANCED_ROOT, _LT_ACC;
                       clade_vertices = [_LT_BALANCED_ROOT],
                       clade_label_func = v -> "root")
    colorbuffer(fig)   # force layout resolution so viewport is non-zero
    cll = only(filter(p -> p isa CladeLabelLayer, lp.plots))
    # bracket_pixel_shapes must be non-empty after layout.
    @test !isempty(cll[:bracket_pixel_shapes][])
    # All non-NaN pixel positions must be finite.
    for pt in cll[:bracket_pixel_shapes][]
        isnan(pt[1]) && continue
        @test isfinite(pt[1]) && isfinite(pt[2])
    end
end

@testset "bracket label pixel positions non-empty after layout" begin
    fig = Figure(; size = (400, 300))
    ax  = Axis(fig[1, 1])
    lp  = lineageplot!(ax, _LT_BALANCED_ROOT, _LT_ACC;
                       clade_vertices = [_LT_BALANCED_ROOT],
                       clade_label_func = v -> "root")
    colorbuffer(fig)
    cll = only(filter(p -> p isa CladeLabelLayer, lp.plots))
    @test !isempty(cll[:bracket_label_pixel_positions][])
end
```

**Additions to `test/test_LineageAxis.jl`** inside `@testset "LineageAxis"`:

```julia
@testset "clade bracket pixel shapes non-empty after lineageplot! on LineageAxis" begin
    fig, lax, lp = _plotted_lax(; lineageunits = :vertexheights)
    colorbuffer(fig)
    cll = only(filter(p -> p isa CladeLabelLayer, lp.plots))
    # Bracket geometry must be populated (clade_vertices defaults to [] so no shapes).
    # Re-run with an actual clade vertex to confirm pixel shapes populate.
    fig2 = Figure(; size = (400, 300))
    lax2 = LineageAxis(fig2[1, 1])
    lp2  = lineageplot!(lax2, _LA_BALANCED_ROOT, _LA_ACC;
                        clade_vertices = [_LA_BALANCED_ROOT],
                        clade_label_func = v -> "root")
    colorbuffer(fig2)
    cll2 = only(filter(p -> p isa CladeLabelLayer, lp2.plots))
    @test !isempty(cll2[:bracket_pixel_shapes][])
    for pt in cll2[:bracket_pixel_shapes][]
        isnan(pt[1]) && continue
        @test isfinite(pt[1]) && isfinite(pt[2])
    end
end
```

---

### 3. Regenerate examples and verify

**Type**: VERIFY
**Output**: Both example PNGs regenerated; visual inspection confirms clade
brackets are visible and in the correct panel-margin position.
**Depends on**: Tasks 1 and 2

Run the full test suite first:

```
julia --project=test test/runtests.jl
```

All tests must pass (currently 501; will increase by the new tests above).
If any existing test fails, investigate before proceeding — do not modify
tests to hide failures.

Then regenerate both examples:

```
julia --project=examples examples/lineageplot_ex1.jl
julia --project=examples examples/lineageplot_ex2.jl
```

**Expected visual outcomes per panel in `lineageplot_ex2.png`:**

| Panel | Expected |
|-------|----------|
| Panel 1 (forward, `:edgelengths`, standard) | Clade brackets visible in **right margin** of panel, outside the leaf positions. Bracket labels ("clade_A", "clade_B") to the right of each bracket bar. |
| Panel 2 (backward, `:vertexheights`, standard) | Clade brackets visible in **left margin** of panel. Labels to the left of each bracket bar. |
| Panel 3 (`:right_to_left`, forward) | Clade brackets visible in **left margin** (leaves on left → bracket on left). |
| Panel 4 (radial) | No clade brackets (none specified). |

All four panels should also retain the correct behavior from Issue 14:
- Leaf labels on the correct side (left for panels 2 and 3, right for panel 1)
- Highlight rects bounded within each panel's data extent
- X-axis tick labels visible below each panel (panels 1, 2, 3)
- No vertex label stacking at internal nodes

`lineageplot_ex1.png` is expected to be unchanged (it does not use
`clade_vertices`).

---

## Verification checklist

```
[ ] Read src/Layers.jl in full before editing
[ ] Read src/LineageAxis.jl in full (especially _wire_x_axis! reference impl.)
[ ] Read src/CoordTransform.jl in full
[ ] Read test/test_Layers.jl in full before editing
[ ] Read test/test_LineageAxis.jl in full before editing
[ ] data_to_pixel added to CoordTransform import in Layers.jl
[ ] :bracket_pixel_shapes map! added (NaN-safe, reactive on :pixel_projection)
[ ] :bracket_label_pixel_positions map! added (reactive on :pixel_projection)
[ ] lines! now targets Makie.parent(sc)
[ ] text! now targets Makie.parent(sc)
[ ] CladeLabelLayer docstring updated to mention decoration-scene rendering
[ ] New @testset blocks added to test_Layers.jl
[ ] New @testset block added to test_LineageAxis.jl
[ ] julia --project=test test/runtests.jl passes (all tests, no failures)
[ ] lineageplot_ex2.png regenerated; brackets visible in correct panel margins
[ ] lineageplot_ex1.png unchanged
[ ] No files outside src/Layers.jl, test/test_Layers.jl, test/test_LineageAxis.jl modified
```

---

## What NOT to change

- `CladeHighlightLayer` — correctly fixed in Issue 14; do not touch.
- `_wire_x_axis!` in `LineageAxis.jl` — already correct; read as a reference,
  do not modify.
- `lineageplot!(ax::LineageAxis, ...)` — orientation-aware defaults are already
  correct from Issue 14; do not modify.
- Any other recipe or layer not mentioned above.
- `STYLE-julia.md`, `STYLE-vocabulary.md`, `CONTRIBUTING.md`, `STYLE-docs.md`.

Scope discipline applies: if you notice a bug or suboptimal code outside the
files listed above, report it in your response — do not fix it silently.
