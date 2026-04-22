# LineageAxis.jl — included directly into LineagesMakie (no submodule wrapper).
#
# Makie.@Block generates esc(q), so all identifiers in the expansion resolve in
# the including module's scope (LineagesMakie). We therefore import everything
# the macro's generated code references without qualification — both exported
# names and the unexported make_block_docstring. GeoMakie.jl uses the same
# pattern (bare `using Makie` at top level; @Block defined in geoaxis.jl which
# is a plain include, not a submodule).
#
# @Block API:
#   Macro: Makie/src/makielayout/blocks.jl:10 — creates a mutable struct with
#     three base fields (parent, layoutobservables, blockscene) plus declared
#     fields and attribute Observables. Non-attribute fields must be assigned via
#     setfield! in initialize_block!.
#   AbstractAxis: Makie/src/types.jl:3 — abstract type AbstractAxis <: Block end.
#   External pattern: GeoMakie.jl/src/geoaxis.jl:7
#     `Makie.@Block GeoAxis <: Makie.AbstractAxis begin ... end`
#   Scene setup: LScene pattern from Makie/src/makielayout/blocks/scene.jl:12 —
#     Scene(blockscene, lift(round_to_IRect2D, blockscene, lax.layoutobservables.computedbbox))
#   Axis reversal: Makie/src/makielayout/blocks/axis.jl:64-87 (update_axis_camera)
#     — swap leftright tuple; use set_proj_view! directly. Do NOT pass reversed
#     limits to cam2d! — update_cam! calls positive_widths which negates reversal.
#   plot!(ax::AbstractAxis, plot): Makie/src/figureplotting.jl:436 — auto-routes
#     to plot!(ax.scene, plot) and calls reset_limits!(ax) after each plot!.
#   get_scene: Makie/src/makielayout/helpers.jl:471 — Makie.get_scene(ax::Axis) = ax.scene.

import Makie
using Makie:
    AbstractPlot,
    Attributes,
    Figure,
    GridLayout,
    Observable,
    Observables,
    Point2f,
    Rect2f,
    Scene,
    lift,
    lines!,
    notify,
    on,
    onany,
    scatter!,
    text!,
    theme
# make_block_docstring is unexported but referenced by the esc(q) expansion of
# @Block (Makie/src/makielayout/blocks.jl:117). Import it explicitly.
using Makie: make_block_docstring

# _resolve_lineageunits_stub is private (unexported) but needed by lineageplot!.
# LineagePlot is the return type of the updated lineageplot! method.
using .Layers: _resolve_lineageunits_stub, LineagePlot
# import (not using) to extend lineageplot! with a LineageAxis-specific method.
import .Layers: lineageplot!
# data_to_pixel is needed by _wire_x_axis! to convert tick x values to blockscene
# pixel coordinates.
using .CoordTransform: data_to_pixel

# ── Block type ─────────────────────────────────────────────────────────────────

const _LineageAxisDecorationLayout = NamedTuple{
    (:plot_rect, :title_band_rect, :xaxis_band_rect, :xlabel_band_rect, :left_gutter_px, :right_gutter_px),
    Tuple{Rect2f, Rect2f, Rect2f, Rect2f, Float32, Float32},
}

"""
    LineageAxis

A custom Makie `Block` for lineage graph visualization that separates the three
independently variable concerns of any lineage graph plot:

- **Lineage graph-centric view** — what scalar positions each vertex along the
  primary dimension. Captured by `lineageunits` and accessor callables passed to
  `lineageplot!`; `axis_polarity` records the resulting direction.
- **User-centric view** — what the researcher means by those scalars. Recorded by
  `axis_polarity` (`:forward` for root-relative values, `:backward` for
  leaf-relative values) but not further interpreted.
- **Plotting-centric view** — how the lineage graph appears on screen. Governed by
  `display_polarity` and `lineage_orientation`.

These three views are independent. A coalescent lineage graph (`axis_polarity =
:backward`) can be displayed with the root at the left by setting
`display_polarity = :reversed`. A forward-time lineage graph can be embedded
radially by setting `lineage_orientation = :radial`.

`LineageAxis` provides a naked lineage graph appearance by default: no tick
marks, no grid lines, no axis spines. An optional quantitative x-axis is
activated by `show_x_axis = true`.

# Attributes

- `axis_polarity::Symbol` — `:forward` or `:backward`. Inferred from the active
  `lineageunits` value when `lineageplot!` is called; overridable by the user.
  Once set explicitly by the user (including before calling `lineageplot!`),
  inference will not overwrite it.
- `display_polarity::Symbol` — `:standard` (default) or `:reversed`. Controls
  whether increasing process coordinates map to increasing screen position.
- `lineage_orientation::Symbol` — `:left_to_right` (default), `:right_to_left`,
  or `:radial`. Controls which screen axis carries the process coordinate.
  `:right_to_left` delegates internally to the `:left_to_right` path with
  `display_polarity = :reversed` (DRY).
- `show_x_axis::Bool` — default `false`. When `true`, a quantitative x-axis is
  shown (Tier-1 implementation: evenly-spaced tick marks from bounding box).
- `show_y_axis::Bool` — default `false`. Reserved; not rendered in Tier 1.
- `show_grid::Bool` — default `false`. Reserved; not rendered in Tier 1.
- `title`, `xlabel`, `ylabel` — standard text attributes.

# Usage

```julia
using CairoMakie, LineagesMakie

fig = Figure()
ax  = LineageAxis(fig[1, 1])
lineageplot!(ax, rootvertex, accessor)
display(fig)
```

See `lineageplot!` for accepted keyword arguments.
"""
Makie.@Block LineageAxis <: Makie.AbstractAxis begin
    scene::Scene
    # V in LineageGraphGeometry{V} is determined at call time and may differ
    # across calls; Observable{Any} avoids an unnecessary type restriction.
    # Justified exception to STYLE-julia.md §1.12: existential parametricity.
    last_geom::Makie.Observable{Any}
    _polarity_locked::Makie.Observable{Bool}
    # Decoration layout and derived tick geometry are stored on Observables so
    # tests and downstream wiring can inspect the current panel-owned bands.
    _decoration_layout::Makie.Observable{_LineageAxisDecorationLayout}
    _xaxis_tick_positions::Makie.Observable{Vector{Point2f}}
    _xaxis_tick_segments::Makie.Observable{Vector{Point2f}}
    _xaxis_tick_labels::Makie.Observable{Vector{String}}

    @attributes begin
        "Semantic direction of increasing process coordinates."
        axis_polarity::Symbol = :forward
        "Whether increasing process coordinates map to increasing screen position."
        display_polarity::Symbol = :standard
        "Which screen axis carries the lineage process coordinate."
        lineage_orientation::Symbol = :left_to_right
        "Whether to display a quantitative x-axis."
        show_x_axis::Bool = false
        "Whether to display a quantitative y-axis (reserved; not rendered in Tier 1)."
        show_y_axis::Bool = false
        "Whether to display grid lines (reserved; not rendered in Tier 1)."
        show_grid::Bool = false
        "Axis title."
        title::String = ""
        "X-axis label."
        xlabel::String = ""
        "Y-axis label."
        ylabel::String = ""
        "Height setting of the block."
        height = nothing
        "Width setting of the block."
        width = nothing
        "Controls if the parent layout can adjust to this element's width."
        tellwidth::Bool = true
        "Controls if the parent layout can adjust to this element's height."
        tellheight::Bool = true
        "Horizontal alignment of the scene in its suggested bounding box."
        halign = :center
        "Vertical alignment of the scene in its suggested bounding box."
        valign = :center
        "Alignment mode."
        alignmode = Makie.Inside()
    end
end

# ── Decoration layout helpers ────────────────────────────────────────────────

const _LINEAGEAXIS_TITLE_BAND_PX = 28.0f0
const _LINEAGEAXIS_XAXIS_BAND_PX = 26.0f0
const _LINEAGEAXIS_XLABEL_BAND_PX = 24.0f0
const _LINEAGEAXIS_SIDE_GUTTER_PX = 84.0f0
const _LINEAGEAXIS_RADIAL_OUTER_PAD_PX = 24.0f0
const _LINEAGEAXIS_PLOT_GAP_PX = 8.0f0
const _LINEAGEAXIS_TITLE_FONTSIZE = 16
const _LINEAGEAXIS_LABEL_FONTSIZE = 12
const _LINEAGEAXIS_TICK_FONTSIZE = 10
const _LINEAGEAXIS_TICK_LENGTH_PX = 6.0f0
const _LINEAGEAXIS_CLADE_LABEL_OFFSET_PX = 28.0f0

function _rectf(
        x::Float32,
        y::Float32,
        w::Float32,
        h::Float32;
        clamp_minimum::Bool = false,
    )::Rect2f
    width  = clamp_minimum ? max(w, 1.0f0) : max(w, 0.0f0)
    height = clamp_minimum ? max(h, 1.0f0) : max(h, 0.0f0)
    return Rect2f(x, y, width, height)
end

function _rect_center(rect::Rect2f)::Point2f
    return Point2f(
        rect.origin[1] + rect.widths[1] / 2,
        rect.origin[2] + rect.widths[2] / 2,
    )
end

function _decoration_layout(
        bbox,
        title::String,
        xlabel::String,
        show_x_axis::Bool,
        lineage_orientation::Symbol,
    )
    x0 = Float32(bbox.origin[1])
    y0 = Float32(bbox.origin[2])
    w  = Float32(bbox.widths[1])
    h  = Float32(bbox.widths[2])

    has_title  = !isempty(strip(title))
    has_xlabel = !isempty(strip(xlabel))
    is_radial  = lineage_orientation === :radial

    title_band_h  = has_title ? _LINEAGEAXIS_TITLE_BAND_PX : 0.0f0
    xaxis_band_h  = show_x_axis ? _LINEAGEAXIS_XAXIS_BAND_PX : 0.0f0
    xlabel_band_h = has_xlabel ? _LINEAGEAXIS_XLABEL_BAND_PX : 0.0f0
    side_gutter   = is_radial ? _LINEAGEAXIS_RADIAL_OUTER_PAD_PX : _LINEAGEAXIS_SIDE_GUTTER_PX
    vertical_pad  = is_radial ? _LINEAGEAXIS_RADIAL_OUTER_PAD_PX : _LINEAGEAXIS_PLOT_GAP_PX

    plot_x0 = x0 + side_gutter
    plot_y0 = y0 + xlabel_band_h + xaxis_band_h + vertical_pad
    plot_w  = w - 2.0f0 * side_gutter
    plot_h  = h - title_band_h - xlabel_band_h - xaxis_band_h - 2.0f0 * vertical_pad
    plot_rect = _rectf(plot_x0, plot_y0, plot_w, plot_h; clamp_minimum = true)

    plot_top = plot_rect.origin[2] + plot_rect.widths[2]
    title_band_rect = _rectf(
        plot_rect.origin[1],
        plot_top + vertical_pad,
        plot_rect.widths[1],
        title_band_h,
    )
    xaxis_band_rect = _rectf(
        plot_rect.origin[1],
        y0 + xlabel_band_h,
        plot_rect.widths[1],
        xaxis_band_h,
    )
    xlabel_band_rect = _rectf(
        plot_rect.origin[1],
        y0,
        plot_rect.widths[1],
        xlabel_band_h,
    )

    return (
        plot_rect = plot_rect,
        title_band_rect = title_band_rect,
        xaxis_band_rect = xaxis_band_rect,
        xlabel_band_rect = xlabel_band_rect,
        left_gutter_px = side_gutter,
        right_gutter_px = side_gutter,
    )
end

# ── Block initialization ───────────────────────────────────────────────────────

function Makie.initialize_block!(lax::LineageAxis)
    blockscene = lax.blockscene

    layout_obs = lift(
        blockscene,
        lax.layoutobservables.computedbbox,
        lax.title,
        lax.xlabel,
        lax.show_x_axis,
        lax.lineage_orientation,
    ) do bbox, title, xlabel, show_x_axis, lineage_orientation
        _decoration_layout(bbox, title, xlabel, show_x_axis, lineage_orientation)
    end

    # Create the plotting scene inside the reserved plot rect rather than using
    # the full block bounding box.
    scenearea = lift(blockscene, layout_obs) do layout
        Makie.round_to_IRect2D(layout.plot_rect)
    end
    lax.scene = Scene(blockscene, scenearea; clear = false, visible = false)

    # Initialize non-attribute Observable fields.
    setfield!(lax, :last_geom, Makie.Observable{Any}(nothing))
    setfield!(lax, :_polarity_locked, Makie.Observable{Bool}(false))
    setfield!(lax, :_decoration_layout, layout_obs)
    setfield!(lax, :_xaxis_tick_positions, Makie.Observable(Point2f[]))
    setfield!(lax, :_xaxis_tick_segments, Makie.Observable(Point2f[]))
    setfield!(lax, :_xaxis_tick_labels, Makie.Observable(String[]))

    # Lock axis_polarity when the user explicitly changes it. This observer is
    # connected AFTER attribute initialization so the @Block default assignment
    # (:forward) does not trigger the lock.
    on(blockscene, lax.axis_polarity) do _
        lax._polarity_locked[] = true
    end

    _wire_panel_text!(lax, blockscene, layout_obs)
    _wire_x_axis!(lax, blockscene, layout_obs)

    return nothing
end

# ── Title/xlabel wiring ───────────────────────────────────────────────────────

function _wire_panel_text!(lax::LineageAxis, blockscene::Scene, layout_obs)
    title_positions = lift(blockscene, layout_obs) do layout
        Point2f[_rect_center(layout.title_band_rect)]
    end
    title_strings = lift(blockscene, lax.title) do title
        String[title]
    end
    title_visible = lift(blockscene, lax.title) do title
        !isempty(strip(title))
    end

    xlabel_positions = lift(blockscene, layout_obs) do layout
        Point2f[_rect_center(layout.xlabel_band_rect)]
    end
    xlabel_strings = lift(blockscene, lax.xlabel) do xlabel
        String[xlabel]
    end
    xlabel_visible = lift(blockscene, lax.xlabel) do xlabel
        !isempty(strip(xlabel))
    end

    text!(
        blockscene,
        title_positions;
        text = title_strings,
        align = (:center, :center),
        fontsize = _LINEAGEAXIS_TITLE_FONTSIZE,
        visible = title_visible,
        inspectable = false,
    )
    text!(
        blockscene,
        xlabel_positions;
        text = xlabel_strings,
        align = (:center, :center),
        fontsize = _LINEAGEAXIS_LABEL_FONTSIZE,
        visible = xlabel_visible,
        inspectable = false,
    )

    return nothing
end

# ── x-axis wiring (Tier-1 minimal) ────────────────────────────────────────────

function _wire_x_axis!(lax::LineageAxis, blockscene::Scene, layout_obs)
    tick_visible   = Makie.Observable(false)

    lines!(
        blockscene,
        lax._xaxis_tick_segments;
        visible = tick_visible,
        inspectable = false,
    )
    text!(
        blockscene,
        lax._xaxis_tick_positions;
        text = lax._xaxis_tick_labels,
        align = (:center, :bottom),
        fontsize = _LINEAGEAXIS_TICK_FONTSIZE,
        visible = tick_visible,
        inspectable = false,
    )

    function _update_ticks()
        geom = lax.last_geom[]
        show = lax.show_x_axis[]
        if !show || geom === nothing
            tick_visible[]   = false
            lax._xaxis_tick_positions[] = Point2f[]
            lax._xaxis_tick_segments[]  = Point2f[]
            lax._xaxis_tick_labels[]    = String[]
            return
        end
        sc_vp = Makie.viewport(lax.scene)[]
        layout = lax._decoration_layout[]
        bb    = (geom::LineageGraphGeometry).boundingbox
        xmin  = Float32(Makie.minimum(bb)[1])
        xmax  = Float32(Makie.maximum(bb)[1])
        n     = 5
        xs    = range(xmin, xmax; length = n)

        positions = Point2f[]
        segments  = Point2f[]
        xaxis_band_rect = layout.xaxis_band_rect
        tick_top = xaxis_band_rect.origin[2] + xaxis_band_rect.widths[2] - 4.0f0
        tick_bottom = tick_top - _LINEAGEAXIS_TICK_LENGTH_PX
        label_y = xaxis_band_rect.origin[2] + 2.0f0
        for x_val in xs
            px      = data_to_pixel(lax.scene, Point2f(Float32(x_val), 0.0f0))
            block_x = Float32(sc_vp.origin[1]) + px[1]
            push!(positions, Point2f(block_x, label_y))
            push!(segments, Point2f(block_x, tick_bottom), Point2f(block_x, tick_top), Point2f(NaN, NaN))
        end
        lax._xaxis_tick_positions[] = positions
        lax._xaxis_tick_segments[]  = segments
        lax._xaxis_tick_labels[]    = [string(round(x; digits = 2)) for x in xs]
        tick_visible[] = !isempty(positions)
    end

    on(blockscene, lax.show_x_axis) do _
        _update_ticks()
    end
    on(blockscene, lax.last_geom) do _
        _update_ticks()
    end
    # Recompute when lax.scene's layout position changes (e.g. on figure resize).
    on(blockscene, Makie.viewport(lax.scene)) do _
        _update_ticks()
    end
    on(blockscene, layout_obs) do _
        _update_ticks()
    end

    return nothing
end

# ── Makie axis protocol ────────────────────────────────────────────────────────

"""
    Makie.get_scene(lax::LineageAxis) -> Scene

Return the plotting scene of `lax`. Required by Makie's `AbstractAxis` protocol
so that recipe plot calls (e.g. `edgelayer!(lax, geom)`) route to the correct
scene (Makie/src/makielayout/helpers.jl:471).
"""
Makie.get_scene(lax::LineageAxis)::Scene = lax.scene

"""
    Makie.tightlimits!(lax::LineageAxis) -> Nothing

No-op. `LineageAxis` manages limits explicitly via `reset_limits!`; automatic
tight-limit adjustment from data bounding boxes is not applicable.
"""
Makie.tightlimits!(lax::LineageAxis) = nothing

# ── Limit management ──────────────────────────────────────────────────────────

"""
    reset_limits!(lax::LineageAxis, geom::LineageGraphGeometry) -> Nothing

Set axis limits from `geom.boundingbox`, applying `display_polarity` and
`lineage_orientation`. Stores `geom` in `lax.last_geom` so `autolimits!` can
re-apply the same limits after viewport changes.

Axis reversal is implemented by swapping the `leftright` tuple in the
orthographic projection rather than passing reversed limits to any higher-level
limit function. Confirmed idiom from
`Makie/src/makielayout/blocks/axis.jl:update_axis_camera` (lines 64-87):
`leftright = xrev ? (right, left) : (left, right)` feeds directly into
`orthographicprojection` / `set_proj_view!`.

`lineage_orientation = :right_to_left` delegates to the `:left_to_right` path
with `display_polarity = :reversed` (DRY, per `02_issues.md` resolution of
PRD Open Q5).

`lineage_orientation = :radial` sets equal x and y extents centred on the data
bounding box, producing a square viewport suitable for circular layouts.
"""
function reset_limits!(lax::LineageAxis, geom::LineageGraphGeometry)::Nothing
    lax.last_geom[] = geom

    bb = geom.boundingbox
    data_left   = Float32(Makie.minimum(bb)[1])
    data_right  = Float32(Makie.maximum(bb)[1])
    data_bottom = Float32(Makie.minimum(bb)[2])
    data_top    = Float32(Makie.maximum(bb)[2])

    xspan = data_right - data_left
    yspan = data_top - data_bottom
    xpad = max(xspan * 0.05f0, 0.1f0)
    ypad = max(yspan * 0.05f0, 0.1f0)

    lo = lax.lineage_orientation[]
    dp = lax.display_polarity[]
    effective_reversed = (dp === :reversed) || (lo === :right_to_left)

    local leftright::Tuple{Float32, Float32}
    local bottomtop::Tuple{Float32, Float32}

    if lo === :radial
        cx   = (data_left + data_right) / 2f0
        cy   = (data_bottom + data_top) / 2f0
        half = max(xspan, yspan) / 2f0 + max(xpad, ypad)
        leftright = effective_reversed ? (cx + half, cx - half) : (cx - half, cx + half)
        bottomtop = (cy - half, cy + half)
    else
        leftright = effective_reversed ?
            (data_right + xpad, data_left - xpad) :
            (data_left - xpad, data_right + xpad)
        bottomtop = (data_bottom - ypad, data_top + ypad)
    end

    proj = Makie.orthographicprojection(
        Float32,
        leftright[1], leftright[2],
        bottomtop[1], bottomtop[2],
        -10_000f0,
        10_000f0,
    )
    Makie.set_proj_view!(Makie.camera(lax.scene), proj, Makie.Mat4f(Makie.I))
    return nothing
end

"""
    Makie.reset_limits!(lax::LineageAxis) -> Nothing

One-argument override required by the Makie `AbstractAxis` protocol.
`plot!(ax::AbstractAxis, plot)` calls this after every `plot!` call
(Makie/src/figureplotting.jl:446). Re-applies limits from the stored
`last_geom`, or does nothing when `last_geom` has not been set yet.
"""
function Makie.reset_limits!(lax::LineageAxis)::Nothing
    geom = lax.last_geom[]
    geom === nothing && return nothing
    reset_limits!(lax, geom::LineageGraphGeometry)
    return nothing
end

"""
    Makie.autolimits!(lax::LineageAxis) -> Nothing

Re-apply axis limits from the stored geometry. Equivalent to `reset_limits!`.
"""
function Makie.autolimits!(lax::LineageAxis)::Nothing
    return Makie.reset_limits!(lax)
end

# ── axis_polarity inference ────────────────────────────────────────────────────

"""
    _infer_axis_polarity(lineageunits::Symbol) -> Symbol

Return the `axis_polarity` that corresponds to `lineageunits`.

Backward `lineageunits` values (`:coalescenceage`, `:vertexheights`) assign a
process coordinate of 0 to leaves and increasing values toward the root.
All other values are forward (root = 0, increasing toward leaves).
"""
function _infer_axis_polarity(lineageunits::Symbol)::Symbol
    lineageunits in (:coalescenceage, :vertexheights) && return :backward
    return :forward
end

# ── lineageplot! dispatch for LineageAxis ──────────────────────────────────────

"""
    lineageplot!(ax::LineageAxis, rootvertex, accessor::LineageGraphAccessor;
                 lineageunits=nothing, kwargs...) -> LineagePlot

Render a lineage graph on `ax`.

When `ax` is a `LineageAxis`, this method additionally:
1. Infers `ax.axis_polarity` from `lineageunits` unless the user has explicitly
   set it (detected by the `_polarity_locked` flag wired in `initialize_block!`).
2. Computes orientation-aware defaults for `leaf_label_offset`, `leaf_label_align`,
   and `clade_label_side` based on `lineage_orientation` and `display_polarity`.
   When leaves fall on the left side of the screen, leaf labels are offset leftward
   (`Vec2f(-4, 0)`, right-aligned) and the clade bracket is placed on the left.
   Caller-supplied keyword arguments always override these defaults.
3. Calls `reset_limits!(ax, geom)` after the recipe sets `lp[:computed_geom]`
   so that axis limits fit the lineage graph bounding box with `display_polarity`
   and `lineage_orientation` applied.
4. Registers a reactive `on` callback so that if `rootvertex` or `lineageunits`
   changes later, `reset_limits!` is reapplied automatically.

Vertex labels are off by default (`vertex_label_threshold = v -> false`); pass an
explicit `vertex_label_threshold` predicate to enable them.

All keyword arguments are forwarded to the `LineagePlot` composite recipe.
See `lineageplot!` for the full attribute list.
"""
function lineageplot!(
        ax::LineageAxis,
        rootvertex,
        accessor::LineageGraphAccessor;
        lineageunits = nothing,
        kwargs...,
    )::LineagePlot
    resolved_lu = _resolve_lineageunits_stub(lineageunits, accessor)

    if !ax._polarity_locked[]
        ax.axis_polarity[] = _infer_axis_polarity(resolved_lu)
    end

    # Compute orientation-aware defaults for leaf labels and clade bracket side.
    # leaves_on_left is true when the layout places leaf tips on the left screen edge.
    lo                 = ax.lineage_orientation[]
    dp                 = ax.display_polarity[]
    backward           = resolved_lu in (:vertexheights, :coalescenceage)
    effective_reversed = (dp === :reversed) || (lo === :right_to_left)
    leaves_on_left     = xor(backward, effective_reversed)

    orientation_defaults = if lo !== :radial
        side_kw = (
            clade_label_side = leaves_on_left ? :left : :right,
            clade_label_offset = Makie.Vec2f(_LINEAGEAXIS_CLADE_LABEL_OFFSET_PX, 0),
        )
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
    # Caller-supplied kwargs take precedence over orientation defaults.
    merged_kwargs = merge(orientation_defaults, kwargs)

    # Route to ax.scene (not ax) to avoid recursive dispatch through the
    # @recipe-generated lineageplot! which also accepts AbstractAxis.
    # plot!(ax::AbstractAxis, ...) at figureplotting.jl:436 would call
    # reset_limits!(ax) after every sub-layer plot! — wasteful and premature
    # before computed_geom is populated. Going directly to ax.scene bypasses
    # the AbstractAxis protocol; we call reset_limits! manually below.
    lp = lineageplot!(ax.scene, rootvertex, accessor; lineageunits = lineageunits, merged_kwargs...)

    # Apply initial limits. lp[:computed_geom][] is already populated because
    # map! nodes run synchronously during plot! construction (Makie 0.24).
    reset_limits!(ax, lp[:computed_geom][])

    # Register reactive limit updates: whenever rootvertex, accessor, or
    # lineageunits changes, computed_geom fires and we re-apply limits.
    on(ax.scene, lp[:computed_geom]) do geom
        reset_limits!(ax, geom)
    end

    return lp
end

# LineageAxis is auto-exported by the @Block macro.
# reset_limits! is exported from LineagesMakie.jl alongside other public names.
