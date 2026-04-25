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
using .Layers: _resolve_lineageunits_stub, CladeLabelLayer, LeafLabelLayer, LineagePlot, ScaleBarLayer
# import (not using) to extend lineageplot! with a LineageAxis-specific method.
import .Layers: lineageplot!
# data_to_pixel is needed by _wire_x_axis! to convert tick x values to blockscene
# pixel coordinates.
using .CoordinateTransform: data_to_pixel

# ── Block type ─────────────────────────────────────────────────────────────────

struct _LineageAxisAnnotationMeasurements
    active_side::Symbol
    leaf_label_visible::Bool
    leaf_label_align::Tuple{Symbol, Symbol}
    leaf_label_gap_px::Float32
    leaf_label_toward_plot_px::Float32
    leaf_label_away_from_plot_px::Float32
    leaf_label_max_width_px::Float32
    leaf_label_max_height_px::Float32
    clade_annotation_visible::Bool
    clade_bracket_min_gap_px::Float32
    clade_tick_length_px::Float32
    clade_label_gap_px::Float32
    clade_label_max_width_px::Float32
    clade_label_max_height_px::Float32
    radial_leaf_gap_px::Float32
    radial_leaf_max_width_px::Float32
    radial_leaf_max_height_px::Float32
    scalebar_visible::Bool
    scalebar_position::Tuple{Symbol, Symbol}
    scalebar_label_max_width_px::Float32
    scalebar_label_max_height_px::Float32
    scalebar_label_gap_px::Float32
    scalebar_band_padding_px::Float32
end

struct _LineageAxisScreenAxisMeasurements
    yaxis_band_width_px::Float32
    ylabel_band_width_px::Float32
end

struct _LineageAxisDecorationLayout
    plot_rect::Rect2f
    title_band_rect::Rect2f
    scalebar_band_rect::Rect2f
    xaxis_band_rect::Rect2f
    xlabel_band_rect::Rect2f
    yaxis_band_rect::Rect2f
    ylabel_band_rect::Rect2f
    left_gutter_px::Float32
    right_gutter_px::Float32
    top_gutter_px::Float32
    bottom_gutter_px::Float32
    active_annotation_side::Symbol
    leaf_label_anchor_x::Float32
    leaf_label_anchor_y::Float32
    leaf_label_align::Tuple{Symbol, Symbol}
    leaf_label_outer_edge_x::Float32
    leaf_label_outer_edge_y::Float32
    clade_bracket_x::Float32
    clade_bracket_y::Float32
    clade_tick_length_px::Float32
    clade_label_anchor_x::Float32
    clade_label_anchor_y::Float32
    clade_label_align::Tuple{Symbol, Symbol}
    clade_annotation_outer_edge_x::Float32
    clade_annotation_outer_edge_y::Float32
    radial_outer_pad_px::Float32
    radial_leaf_gap_px::Float32
    scalebar_visible::Bool
    scalebar_halign::Symbol
    scalebar_valign::Symbol
    scalebar_line_y::Float32
    scalebar_label_y::Float32
end

"""
    LineageAxis

A custom Makie `Block` for lineage graph visualization that separates the three
independently variable concerns of any lineage graph plot:

- **Lineage graph-centric view** — what scalar positions each node along the
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
marks, no grid lines, no axis spines. Optional quantitative screen-axis
decorations are activated by `show_x_axis = true` and `show_y_axis = true`,
and `show_grid = true` draws grid lines aligned with whichever screen axes are
visible.

# Attributes

- `axis_polarity::Symbol` — `:forward` or `:backward`. Inferred from the active
  `lineageunits` value when `lineageplot!` is called; overridable by the user.
  Once set explicitly by the user (including before calling `lineageplot!`),
  inference will not overwrite it.
- `display_polarity::Symbol` — `:standard` (default) or `:reversed`. Controls
  whether increasing process coordinates map to increasing screen position.
- `lineage_orientation::Symbol` — `:left_to_right` (default), `:right_to_left`,
  `:bottom_to_top`, `:top_to_bottom`, or `:radial`. Controls which screen axis
  carries the process coordinate. `:right_to_left` and `:top_to_bottom`
  delegate internally to the corresponding standard-orientation path with the
  process direction reversed.
- `show_x_axis::Bool` — default `false`. When `true`, a quantitative screen
  x-axis is shown using evenly spaced ticks derived from the rendered geometry.
- `show_y_axis::Bool` — default `false`. When `true`, a quantitative screen
  y-axis is shown using evenly spaced ticks derived from the rendered geometry.
- `show_grid::Bool` — default `false`. When `true`, grid lines are shown for
  whichever screen axes are visible.
- `title`, `xlabel`, `ylabel` — standard text attributes. `xlabel` labels the
  screen x-axis and `ylabel` labels the screen y-axis.

# Usage

```julia
using CairoMakie, LineagesMakie

fig = Figure()
ax  = LineageAxis(fig[1, 1])
lineageplot!(ax, rootnode, accessor)
display(fig)
```

See `lineageplot!` for accepted keyword arguments.
"""
Makie.@Block LineageAxis <: Makie.AbstractAxis begin
    scene::Scene
    # NodeT in LineageGraphGeometry{NodeT} is determined at call time and may
    # differ across calls; Observable{Any} avoids an unnecessary type restriction.
    # Justified exception to STYLE-julia.md §1.12: existential parametricity.
    last_geom::Makie.Observable{Any}
    _polarity_locked::Makie.Observable{Bool}
    _annotation_measurements::Makie.Observable{_LineageAxisAnnotationMeasurements}
    # Decoration layout and derived tick geometry are stored on Observables so
    # tests and downstream wiring can inspect the current panel-owned bands.
    _decoration_layout::Makie.Observable{_LineageAxisDecorationLayout}
    _xaxis_tick_positions::Makie.Observable{Vector{Point2f}}
    _xaxis_tick_segments::Makie.Observable{Vector{Point2f}}
    _xaxis_tick_labels::Makie.Observable{Vector{String}}
    _yaxis_tick_positions::Makie.Observable{Vector{Point2f}}
    _yaxis_tick_segments::Makie.Observable{Vector{Point2f}}
    _yaxis_tick_labels::Makie.Observable{Vector{String}}
    _grid_segments::Makie.Observable{Vector{Point2f}}

    @attributes begin
        "Semantic direction of increasing process coordinates."
        axis_polarity::Symbol = :forward
        "Whether increasing process coordinates map to increasing screen position."
        display_polarity::Symbol = :standard
        "Which screen axis carries the lineage process coordinate."
        lineage_orientation::Symbol = :left_to_right
        "Whether to display a quantitative x-axis."
        show_x_axis::Bool = false
        "Whether to display a quantitative y-axis."
        show_y_axis::Bool = false
        "Whether to display grid lines for visible screen axes."
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

function _layout_kwargs_namedtuple(raw_kwargs, keyword_name::AbstractString)::NamedTuple
    raw_kwargs isa NamedTuple && return raw_kwargs
    raw_kwargs isa Attributes && return (; pairs(raw_kwargs)...)
    raw_kwargs isa AbstractDict{Symbol} && return (; pairs(raw_kwargs)...)
    throw(
        ArgumentError(
            "the $(keyword_name) keyword expects a NamedTuple, Attributes, or " *
            "AbstractDict{Symbol}; got $(repr(raw_kwargs)) ($(typeof(raw_kwargs)))",
        ),
    )
end

# ── Decoration layout helpers ────────────────────────────────────────────────

const _LINEAGEAXIS_TITLE_BAND_PX = 28.0f0
const _LINEAGEAXIS_XAXIS_BAND_PX = 26.0f0
const _LINEAGEAXIS_XLABEL_BAND_PX = 24.0f0
const _LINEAGEAXIS_SIDE_GUTTER_PX = 84.0f0
const _LINEAGEAXIS_RADIAL_OUTER_PAD_PX = 24.0f0
const _LINEAGEAXIS_PLOT_GAP_PX = 8.0f0
const _LINEAGEAXIS_SIDE_OUTER_MARGIN_PX = 8.0f0
const _LINEAGEAXIS_TITLE_FONTSIZE = 16
const _LINEAGEAXIS_LABEL_FONTSIZE = 12
const _LINEAGEAXIS_TICK_FONTSIZE = 10
const _LINEAGEAXIS_TICK_LENGTH_PX = 6.0f0
const _LINEAGEAXIS_YAXIS_MIN_BAND_PX = 30.0f0
const _LINEAGEAXIS_YAXIS_LABEL_GAP_PX = 4.0f0
const _LINEAGEAXIS_YLABEL_PAD_PX = 6.0f0
const _LINEAGEAXIS_CLADE_LABEL_OFFSET_PX = 28.0f0
const _LINEAGEAXIS_CLADE_LANE_GAP_PX = 8.0f0
const _LINEAGEAXIS_CLADE_TICK_LENGTH_PX = 3.0f0
const _LINEAGEAXIS_CLADE_TEXT_GAP_PX = 6.0f0
const _LINEAGEAXIS_SCALEBAR_FONTSIZE = 10
const _LINEAGEAXIS_SCALEBAR_LABEL_GAP_PX = 3.0f0
const _LINEAGEAXIS_SCALEBAR_BAND_PADDING_PX = 6.0f0
const _LINEAGEAXIS_GRID_COLOR = (:black, 0.12)

struct _LineageOrientationPolicy
    rectangular::Bool
    process_axis::Symbol
    orientation_reversed::Bool
    negative_annotation_side::Symbol
    positive_annotation_side::Symbol
end

struct _LineageAxisPlotContract{NT<:NamedTuple}
    lineage_orientation::Symbol
    policy::_LineageOrientationPolicy
    effective_process_reversed::Bool
    annotation_side::Symbol
    plot_kwargs::NT
end

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

function _default_annotation_measurements()::_LineageAxisAnnotationMeasurements
    return _LineageAxisAnnotationMeasurements(
        :none,
        false,
        (:left, :center),
        0.0f0,
        0.0f0,
        0.0f0,
        0.0f0,
        0.0f0,
        false,
        _LINEAGEAXIS_CLADE_LABEL_OFFSET_PX,
        _LINEAGEAXIS_CLADE_TICK_LENGTH_PX,
        _LINEAGEAXIS_CLADE_TEXT_GAP_PX,
        0.0f0,
        0.0f0,
        4.0f0,
        0.0f0,
        0.0f0,
        false,
        (:left, :bottom),
        0.0f0,
        0.0f0,
        _LINEAGEAXIS_SCALEBAR_LABEL_GAP_PX,
        _LINEAGEAXIS_SCALEBAR_BAND_PADDING_PX,
    )
end

function _default_screen_axis_measurements()::_LineageAxisScreenAxisMeasurements
    return _LineageAxisScreenAxisMeasurements(0.0f0, 0.0f0)
end

function _lineage_orientation_policy(lineage_orientation::Symbol)::_LineageOrientationPolicy
    if lineage_orientation === :left_to_right
        return _LineageOrientationPolicy(true, :x, false, :left, :right)
    elseif lineage_orientation === :right_to_left
        return _LineageOrientationPolicy(true, :x, true, :left, :right)
    elseif lineage_orientation === :bottom_to_top
        return _LineageOrientationPolicy(true, :y, false, :bottom, :top)
    elseif lineage_orientation === :top_to_bottom
        return _LineageOrientationPolicy(true, :y, true, :bottom, :top)
    elseif lineage_orientation === :radial
        return _LineageOrientationPolicy(false, :x, false, :radial, :radial)
    end
    throw(
        ArgumentError(
            "unsupported lineage_orientation $(repr(lineage_orientation)); " *
            "supported values are :left_to_right, :right_to_left, " *
            ":bottom_to_top, :top_to_bottom, and :radial",
        ),
    )
end

function _clean_tick_value(value::Float32)::Float32
    abs(value) < 5.0f-4 && return 0.0f0
    return value
end

function _axis_tick_values(lower::Float32, upper::Float32; n::Int = 5)::Vector{Float32}
    if !isfinite(lower) || !isfinite(upper)
        return Float32[]
    elseif isapprox(lower, upper; atol = 1.0f-6, rtol = 1.0f-6)
        return Float32[_clean_tick_value(lower)]
    end
    return Float32[_clean_tick_value(value) for value in range(lower, upper; length = n)]
end

function _axis_tick_labels(values::Vector{Float32})::Vector{String}
    return [string(round(value; digits = 2)) for value in values]
end

function _boundingbox_tick_values(
        geom::LineageGraphGeometry,
        axis::Symbol,
    )::Vector{Float32}
    bb = geom.boundingbox
    lower = axis === :x ? Float32(Makie.minimum(bb)[1]) : Float32(Makie.minimum(bb)[2])
    upper = axis === :x ? Float32(Makie.maximum(bb)[1]) : Float32(Makie.maximum(bb)[2])
    return _axis_tick_values(lower, upper)
end

function _screen_axis_measurements(
        geom,
        show_y_axis::Bool,
        ylabel::String,
    )::_LineageAxisScreenAxisMeasurements
    (!show_y_axis || geom === nothing) && return _default_screen_axis_measurements()

    ylabels = _axis_tick_labels(_boundingbox_tick_values(geom::LineageGraphGeometry, :y))
    tick_width_px, _ = _max_text_size_px(ylabels, Makie.defaultfont(), _LINEAGEAXIS_TICK_FONTSIZE)
    yaxis_band_width_px = max(
        _LINEAGEAXIS_YAXIS_MIN_BAND_PX,
        tick_width_px + _LINEAGEAXIS_TICK_LENGTH_PX + _LINEAGEAXIS_YAXIS_LABEL_GAP_PX + 6.0f0,
    )

    ylabel_band_width_px = if isempty(strip(ylabel))
        0.0f0
    else
        bb = Makie.text_bb(ylabel, Makie.defaultfont(), _LINEAGEAXIS_LABEL_FONTSIZE)
        Float32(bb.widths[2]) + _LINEAGEAXIS_YLABEL_PAD_PX
    end

    return _LineageAxisScreenAxisMeasurements(yaxis_band_width_px, ylabel_band_width_px)
end

function _blockscene_x_for_data(lax::LineageAxis, data_x::Float32, data_y::Float32)::Float32
    px = data_to_pixel(lax.scene, Point2f(data_x, data_y))
    sc_vp = Makie.viewport(lax.scene)[]
    return Float32(sc_vp.origin[1]) + px[1]
end

function _blockscene_y_for_data(lax::LineageAxis, data_x::Float32, data_y::Float32)::Float32
    px = data_to_pixel(lax.scene, Point2f(data_x, data_y))
    sc_vp = Makie.viewport(lax.scene)[]
    return Float32(sc_vp.origin[2]) + px[2]
end

function _effective_process_reversed(
        policy::_LineageOrientationPolicy,
        display_polarity::Symbol,
    )::Bool
    user_reversed = if display_polarity === :standard
        false
    elseif display_polarity === :reversed
        true
    else
        throw(
            ArgumentError(
                "unsupported display_polarity $(repr(display_polarity)); " *
                "supported values are :standard and :reversed",
            ),
        )
    end
    return xor(policy.orientation_reversed, user_reversed)
end

function _compute_rectangular_boundingbox(node_positions::Dict)::Rect2f
    xs = Float32[pos[1] for pos in values(node_positions)]
    ys = Float32[pos[2] for pos in values(node_positions)]
    isempty(xs) && throw(ArgumentError("cannot compute a bounding box for empty node positions"))
    xmin = minimum(xs)
    xmax = maximum(xs)
    ymin = minimum(ys)
    ymax = maximum(ys)
    return Rect2f(xmin, ymin, xmax - xmin, ymax - ymin)
end

function _orient_rectangular_geometry(
        geom::LineageGraphGeometry,
        lineage_orientation::Symbol,
        owner_handles_direction::Bool = false,
    )::LineageGraphGeometry
    policy = _lineage_orientation_policy(lineage_orientation)
    !policy.rectangular && return geom

    function _transform_rectangular_point(pt::Point2f)::Point2f
        process = pt[1]
        transverse = pt[2]
        process_coordinate = if owner_handles_direction || !policy.orientation_reversed
            process
        else
            -process
        end
        if policy.process_axis === :x
            return Point2f(process_coordinate, transverse)
        end
        return Point2f(transverse, process_coordinate)
    end

    key_t = Base.keytype(typeof(geom.node_positions))
    node_positions = Dict{key_t, Point2f}()
    sizehint!(node_positions, length(geom.node_positions))
    for (node, pos) in geom.node_positions
        node_positions[node] = _transform_rectangular_point(pos)
    end
    edge_shapes = Point2f[_transform_rectangular_point(pt) for pt in geom.edge_shapes]
    boundingbox = _compute_rectangular_boundingbox(node_positions)
    return LineageGraphGeometry(
        node_positions,
        edge_shapes,
        copy(geom.edges),
        copy(geom.leaf_order),
        boundingbox,
    )
end

function _text_anchor_extents(size_px::Float32, align::Symbol)::Tuple{Float32, Float32}
    if align in (:right, :top)
        return (size_px, 0.0f0)
    elseif align === :center
        half_size = size_px / 2.0f0
        return (half_size, half_size)
    elseif align in (:left, :bottom)
        return (0.0f0, size_px)
    end
    throw(
        ArgumentError(
            "unsupported text alignment component $(repr(align)); " *
            "expected :left/:center/:right or :bottom/:center/:top",
        ),
    )
end

function _text_extents_for_side(
        size_px::Float32,
        align::Symbol,
        side::Symbol,
    )::Tuple{Float32, Float32}
    low_extent, high_extent = _text_anchor_extents(size_px, align)
    if side in (:left, :bottom)
        return (high_extent, low_extent)
    elseif side in (:right, :top)
        return (low_extent, high_extent)
    end
    throw(
        ArgumentError(
            "unsupported annotation side $(repr(side)); " *
            "expected :left, :right, :top, or :bottom",
        ),
    )
end

function _rectangular_annotation_side(side::Symbol)::Symbol
    side in (:left, :right, :top, :bottom) && return side
    throw(
        ArgumentError(
            "unsupported rectangular annotation side $(repr(side)); " *
            "supported values are :left, :right, :top, and :bottom",
        ),
    )
end

function _text_normal_alignment(
        align::Tuple{Symbol, Symbol},
        side::Symbol,
    )::Symbol
    return side in (:top, :bottom) ? align[2] : align[1]
end

function _offset_component_px(offset::Makie.Vec2f, side::Symbol)::Float32
    return abs(Float32(side in (:top, :bottom) ? offset[2] : offset[1]))
end

function _normal_text_extent_px(
        width_px::Float32,
        height_px::Float32,
        side::Symbol,
    )::Float32
    return side in (:top, :bottom) ? height_px : width_px
end

function _max_text_size_px(strings::Vector{String}, font, fontsize)::Tuple{Float32, Float32}
    resolved_font = if font isa Symbol
        raw_fonts = theme(:fonts)
        fonts = if raw_fonts isa Observable
            raw_fonts[]
        else
            raw_fonts
        end
        if fonts isa NamedTuple
            Makie.to_font(Attributes(; pairs(fonts)...), font)
        elseif fonts isa Attributes
            Makie.to_font(fonts, font)
        else
            Makie.defaultfont()
        end
    else
        Makie.to_font(font)
    end
    max_width = 0.0f0
    max_height = 0.0f0
    for label in strings
        isempty(label) && continue
        bb = Makie.text_bb(label, resolved_font, fontsize)
        width_px = Float32(bb.widths[1])
        height_px = Float32(bb.widths[2])
        isfinite(width_px) || continue
        isfinite(height_px) || continue
        max_width = max(max_width, width_px)
        max_height = max(max_height, height_px)
    end
    return (max_width, max_height)
end

function _rectangular_annotation_extent_px(
        measurements::_LineageAxisAnnotationMeasurements,
    )::Float32
    leaf_extent = if measurements.leaf_label_visible
        measurements.leaf_label_gap_px +
        measurements.leaf_label_toward_plot_px +
        measurements.leaf_label_away_from_plot_px
    else
        0.0f0
    end

    if !measurements.clade_annotation_visible
        return leaf_extent
    end

    clade_bracket_extent = max(
        measurements.clade_bracket_min_gap_px,
        leaf_extent + _LINEAGEAXIS_CLADE_LANE_GAP_PX + measurements.clade_tick_length_px,
    )
    clade_label_extent_px = _normal_text_extent_px(
        measurements.clade_label_max_width_px,
        measurements.clade_label_max_height_px,
        measurements.active_side,
    )
    clade_label_extent = clade_bracket_extent +
        measurements.clade_label_gap_px +
        clade_label_extent_px
    return max(leaf_extent, clade_label_extent)
end

function _scalebar_band_height_px(
        measurements::_LineageAxisAnnotationMeasurements,
    )::Float32
    measurements.scalebar_visible || return 0.0f0
    label_height = measurements.scalebar_label_max_height_px
    label_gap = label_height > 0.0f0 ? measurements.scalebar_label_gap_px : 0.0f0
    return 2.0f0 * measurements.scalebar_band_padding_px + label_gap + label_height
end

function _decoration_layout(
        bbox,
        title::String,
        xlabel::String,
        ylabel::String,
        show_x_axis::Bool,
        show_y_axis::Bool,
        lineage_orientation::Symbol,
        measurements::_LineageAxisAnnotationMeasurements,
        screen_axis_measurements::_LineageAxisScreenAxisMeasurements,
    )
    policy = _lineage_orientation_policy(lineage_orientation)
    x0 = Float32(bbox.origin[1])
    y0 = Float32(bbox.origin[2])
    w  = Float32(bbox.widths[1])
    h  = Float32(bbox.widths[2])

    has_title  = !isempty(strip(title))
    has_xlabel = !isempty(strip(xlabel))
    is_radial  = !policy.rectangular
    scalebar_halign = measurements.scalebar_position[1]
    scalebar_valign = measurements.scalebar_position[2] === :top ? :top : :bottom
    scalebar_band_h = _scalebar_band_height_px(measurements)
    scalebar_top_band_h = measurements.scalebar_visible && scalebar_valign === :top ? scalebar_band_h : 0.0f0
    scalebar_bottom_band_h = measurements.scalebar_visible && scalebar_valign !== :top ? scalebar_band_h : 0.0f0

    title_band_h  = has_title ? _LINEAGEAXIS_TITLE_BAND_PX : 0.0f0
    xaxis_band_h  = show_x_axis ? _LINEAGEAXIS_XAXIS_BAND_PX : 0.0f0
    xlabel_band_h = has_xlabel ? _LINEAGEAXIS_XLABEL_BAND_PX : 0.0f0
    yaxis_band_w = show_y_axis ? screen_axis_measurements.yaxis_band_width_px : 0.0f0
    ylabel_band_w = show_y_axis && !isempty(strip(ylabel)) ?
        screen_axis_measurements.ylabel_band_width_px :
        0.0f0
    radial_outer_pad = if is_radial
        max(
            _LINEAGEAXIS_RADIAL_OUTER_PAD_PX,
            measurements.radial_leaf_gap_px +
            max(measurements.radial_leaf_max_width_px, measurements.radial_leaf_max_height_px) +
            _LINEAGEAXIS_SIDE_OUTER_MARGIN_PX,
        )
    else
        _LINEAGEAXIS_RADIAL_OUTER_PAD_PX
    end

    active_side = is_radial ? :radial : measurements.active_side
    annotation_extent_px = is_radial ? 0.0f0 : _rectangular_annotation_extent_px(measurements)
    left_gutter = if is_radial
        radial_outer_pad
    elseif active_side === :left
        _LINEAGEAXIS_SIDE_OUTER_MARGIN_PX + annotation_extent_px
    else
        _LINEAGEAXIS_SIDE_OUTER_MARGIN_PX
    end
    right_gutter = if is_radial
        radial_outer_pad
    elseif active_side === :right
        _LINEAGEAXIS_SIDE_OUTER_MARGIN_PX + annotation_extent_px
    else
        _LINEAGEAXIS_SIDE_OUTER_MARGIN_PX
    end
    top_gutter = if is_radial
        radial_outer_pad
    elseif active_side === :top
        _LINEAGEAXIS_SIDE_OUTER_MARGIN_PX + annotation_extent_px
    else
        _LINEAGEAXIS_PLOT_GAP_PX
    end
    bottom_gutter = if is_radial
        radial_outer_pad
    elseif active_side === :bottom
        _LINEAGEAXIS_SIDE_OUTER_MARGIN_PX + annotation_extent_px
    else
        _LINEAGEAXIS_PLOT_GAP_PX
    end

    plot_x0 = x0 + ylabel_band_w + yaxis_band_w + left_gutter
    plot_y0 = y0 + xlabel_band_h + xaxis_band_h + scalebar_bottom_band_h + bottom_gutter
    plot_w  = w - ylabel_band_w - yaxis_band_w - left_gutter - right_gutter
    plot_h  = h - title_band_h - xlabel_band_h - xaxis_band_h - scalebar_top_band_h -
        scalebar_bottom_band_h - top_gutter - bottom_gutter
    plot_rect = _rectf(plot_x0, plot_y0, plot_w, plot_h; clamp_minimum = true)
    plot_left = plot_rect.origin[1]
    plot_right = plot_rect.origin[1] + plot_rect.widths[1]
    plot_bottom = plot_rect.origin[2]

    plot_top = plot_rect.origin[2] + plot_rect.widths[2]
    scalebar_band_rect = if scalebar_valign === :top
        _rectf(
            plot_rect.origin[1],
            plot_top + top_gutter,
            plot_rect.widths[1],
            scalebar_top_band_h,
        )
    else
        _rectf(
            plot_rect.origin[1],
            y0 + xlabel_band_h + xaxis_band_h,
            plot_rect.widths[1],
            scalebar_bottom_band_h,
        )
    end
    title_band_rect = _rectf(
        plot_rect.origin[1],
        plot_top + top_gutter + scalebar_top_band_h,
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
    yaxis_band_rect = _rectf(
        x0 + ylabel_band_w,
        plot_rect.origin[2],
        yaxis_band_w,
        plot_rect.widths[2],
    )
    ylabel_band_rect = _rectf(
        x0,
        plot_rect.origin[2],
        ylabel_band_w,
        plot_rect.widths[2],
    )

    leaf_anchor_x = Float32(NaN)
    leaf_anchor_y = Float32(NaN)
    leaf_outer_edge_x = Float32(NaN)
    leaf_outer_edge_y = Float32(NaN)
    clade_bracket_x = Float32(NaN)
    clade_bracket_y = Float32(NaN)
    clade_label_anchor_x = Float32(NaN)
    clade_label_anchor_y = Float32(NaN)
    clade_annotation_outer_edge_x = Float32(NaN)
    clade_annotation_outer_edge_y = Float32(NaN)
    scalebar_line_y = Float32(NaN)
    scalebar_label_y = Float32(NaN)
    leaf_align = measurements.leaf_label_align
    clade_align = if active_side === :left
        (:right, :center)
    elseif active_side === :right
        (:left, :center)
    elseif active_side === :top
        (:center, :bottom)
    elseif active_side === :bottom
        (:center, :top)
    else
        (:left, :center)
    end
    clade_label_extent_px = _normal_text_extent_px(
        measurements.clade_label_max_width_px,
        measurements.clade_label_max_height_px,
        active_side,
    )

    if !is_radial && active_side === :right
        leaf_anchor_x = plot_right + measurements.leaf_label_gap_px + measurements.leaf_label_toward_plot_px
        leaf_outer_edge_x = leaf_anchor_x + measurements.leaf_label_away_from_plot_px
        clade_bracket_x = max(
            plot_right + measurements.clade_bracket_min_gap_px,
            leaf_outer_edge_x + _LINEAGEAXIS_CLADE_LANE_GAP_PX + measurements.clade_tick_length_px,
        )
        clade_label_anchor_x = clade_bracket_x + measurements.clade_label_gap_px
        clade_annotation_outer_edge_x = max(
            leaf_outer_edge_x,
            measurements.clade_annotation_visible ?
                (clade_label_anchor_x + measurements.clade_label_max_width_px) :
                leaf_outer_edge_x,
        )
    elseif !is_radial && active_side === :left
        leaf_anchor_x = plot_left - measurements.leaf_label_gap_px - measurements.leaf_label_toward_plot_px
        leaf_outer_edge_x = leaf_anchor_x - measurements.leaf_label_away_from_plot_px
        clade_bracket_x = min(
            plot_left - measurements.clade_bracket_min_gap_px,
            leaf_outer_edge_x - _LINEAGEAXIS_CLADE_LANE_GAP_PX - measurements.clade_tick_length_px,
        )
        clade_label_anchor_x = clade_bracket_x - measurements.clade_label_gap_px
        clade_annotation_outer_edge_x = min(
            leaf_outer_edge_x,
            measurements.clade_annotation_visible ?
                (clade_label_anchor_x - clade_label_extent_px) :
                leaf_outer_edge_x,
        )
    elseif !is_radial && active_side === :top
        leaf_anchor_y = plot_top + measurements.leaf_label_gap_px + measurements.leaf_label_toward_plot_px
        leaf_outer_edge_y = leaf_anchor_y + measurements.leaf_label_away_from_plot_px
        clade_bracket_y = max(
            plot_top + measurements.clade_bracket_min_gap_px,
            leaf_outer_edge_y + _LINEAGEAXIS_CLADE_LANE_GAP_PX + measurements.clade_tick_length_px,
        )
        clade_label_anchor_y = clade_bracket_y + measurements.clade_label_gap_px
        clade_annotation_outer_edge_y = max(
            leaf_outer_edge_y,
            measurements.clade_annotation_visible ?
                (clade_label_anchor_y + clade_label_extent_px) :
                leaf_outer_edge_y,
        )
    elseif !is_radial && active_side === :bottom
        leaf_anchor_y = plot_bottom - measurements.leaf_label_gap_px - measurements.leaf_label_toward_plot_px
        leaf_outer_edge_y = leaf_anchor_y - measurements.leaf_label_away_from_plot_px
        clade_bracket_y = min(
            plot_bottom - measurements.clade_bracket_min_gap_px,
            leaf_outer_edge_y - _LINEAGEAXIS_CLADE_LANE_GAP_PX - measurements.clade_tick_length_px,
        )
        clade_label_anchor_y = clade_bracket_y - measurements.clade_label_gap_px
        clade_annotation_outer_edge_y = min(
            leaf_outer_edge_y,
            measurements.clade_annotation_visible ?
                (clade_label_anchor_y - clade_label_extent_px) :
                leaf_outer_edge_y,
        )
    end

    if measurements.scalebar_visible
        band_top = scalebar_band_rect.origin[2] + scalebar_band_rect.widths[2]
        scalebar_line_y = band_top - measurements.scalebar_band_padding_px
        label_gap = measurements.scalebar_label_max_height_px > 0.0f0 ? measurements.scalebar_label_gap_px : 0.0f0
        scalebar_label_y = scalebar_line_y - label_gap
    end

    return _LineageAxisDecorationLayout(
        plot_rect,
        title_band_rect,
        scalebar_band_rect,
        xaxis_band_rect,
        xlabel_band_rect,
        yaxis_band_rect,
        ylabel_band_rect,
        left_gutter,
        right_gutter,
        top_gutter,
        bottom_gutter,
        active_side,
        leaf_anchor_x,
        leaf_anchor_y,
        leaf_align,
        leaf_outer_edge_x,
        leaf_outer_edge_y,
        clade_bracket_x,
        clade_bracket_y,
        measurements.clade_tick_length_px,
        clade_label_anchor_x,
        clade_label_anchor_y,
        clade_align,
        clade_annotation_outer_edge_x,
        clade_annotation_outer_edge_y,
        radial_outer_pad,
        measurements.radial_leaf_gap_px,
        measurements.scalebar_visible,
        scalebar_halign,
        scalebar_valign,
        scalebar_line_y,
        scalebar_label_y,
    )
end

# ── Block initialization ───────────────────────────────────────────────────────

function Makie.initialize_block!(lax::LineageAxis)
    blockscene = lax.blockscene
    annotation_measurements = Makie.Observable(_default_annotation_measurements())
    setfield!(lax, :last_geom, Makie.Observable{Any}(nothing))

    screen_axis_measurements = lift(
        blockscene,
        lax.last_geom,
        lax.show_y_axis,
        lax.ylabel,
    ) do geom, show_y_axis, ylabel
        _screen_axis_measurements(geom, show_y_axis, ylabel)
    end

    layout_obs = lift(
        blockscene,
        lax.layoutobservables.computedbbox,
        lax.title,
        lax.xlabel,
        lax.ylabel,
        lax.show_x_axis,
        lax.show_y_axis,
        lax.lineage_orientation,
        annotation_measurements,
        screen_axis_measurements,
    ) do bbox, title, xlabel, ylabel, show_x_axis, show_y_axis, lineage_orientation, measurements, axis_measurements
        _decoration_layout(
            bbox,
            title,
            xlabel,
            ylabel,
            show_x_axis,
            show_y_axis,
            lineage_orientation,
            measurements,
            axis_measurements,
        )
    end

    # Create the plotting scene inside the reserved plot rect rather than using
    # the full block bounding box.
    scenearea = lift(blockscene, layout_obs) do layout
        Makie.round_to_IRect2D(layout.plot_rect)
    end
    lax.scene = Scene(blockscene, scenearea; clear = false, visible = false)

    # Initialize non-attribute Observable fields.
    setfield!(lax, :_polarity_locked, Makie.Observable{Bool}(false))
    setfield!(lax, :_annotation_measurements, annotation_measurements)
    setfield!(lax, :_decoration_layout, layout_obs)
    setfield!(lax, :_xaxis_tick_positions, Makie.Observable(Point2f[]))
    setfield!(lax, :_xaxis_tick_segments, Makie.Observable(Point2f[]))
    setfield!(lax, :_xaxis_tick_labels, Makie.Observable(String[]))
    setfield!(lax, :_yaxis_tick_positions, Makie.Observable(Point2f[]))
    setfield!(lax, :_yaxis_tick_segments, Makie.Observable(Point2f[]))
    setfield!(lax, :_yaxis_tick_labels, Makie.Observable(String[]))
    setfield!(lax, :_grid_segments, Makie.Observable(Point2f[]))

    # Lock axis_polarity when the user explicitly changes it. This observer is
    # connected AFTER attribute initialization so the @Block default assignment
    # (:forward) does not trigger the lock.
    on(blockscene, lax.axis_polarity) do _
        lax._polarity_locked[] = true
    end

    _wire_panel_text!(lax, blockscene, layout_obs)
    _wire_x_axis!(lax, blockscene, layout_obs)
    _wire_y_axis!(lax, blockscene, layout_obs)
    _wire_grid!(lax, blockscene, layout_obs)

    return nothing
end

# ── Title/xlabel/ylabel wiring ────────────────────────────────────────────────

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
    ylabel_positions = lift(blockscene, layout_obs) do layout
        Point2f[_rect_center(layout.ylabel_band_rect)]
    end
    ylabel_strings = lift(blockscene, lax.ylabel) do ylabel
        String[ylabel]
    end
    ylabel_visible = lift(blockscene, lax.show_y_axis, lax.ylabel) do show_y_axis, ylabel
        show_y_axis && !isempty(strip(ylabel))
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
    text!(
        blockscene,
        ylabel_positions;
        text = ylabel_strings,
        align = (:center, :center),
        rotation = pi / 2,
        fontsize = _LINEAGEAXIS_LABEL_FONTSIZE,
        visible = ylabel_visible,
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
        layout = lax._decoration_layout[]
        bb = (geom::LineageGraphGeometry).boundingbox
        ymid = (Float32(Makie.minimum(bb)[2]) + Float32(Makie.maximum(bb)[2])) / 2.0f0
        xs = _boundingbox_tick_values(geom, :x)

        positions = Point2f[]
        segments = Point2f[]
        xaxis_band_rect = layout.xaxis_band_rect
        tick_top = xaxis_band_rect.origin[2] + xaxis_band_rect.widths[2] - 4.0f0
        tick_bottom = tick_top - _LINEAGEAXIS_TICK_LENGTH_PX
        label_y = xaxis_band_rect.origin[2] + 2.0f0
        plot_left = layout.plot_rect.origin[1]
        plot_right = layout.plot_rect.origin[1] + layout.plot_rect.widths[1]
        push!(segments, Point2f(plot_left, tick_top), Point2f(plot_right, tick_top), Point2f(NaN, NaN))
        for x_val in xs
            block_x = _blockscene_x_for_data(lax, x_val, ymid)
            push!(positions, Point2f(block_x, label_y))
            push!(segments, Point2f(block_x, tick_bottom), Point2f(block_x, tick_top), Point2f(NaN, NaN))
        end
        lax._xaxis_tick_positions[] = positions
        lax._xaxis_tick_segments[]  = segments
        lax._xaxis_tick_labels[]    = _axis_tick_labels(xs)
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

function _wire_y_axis!(lax::LineageAxis, blockscene::Scene, layout_obs)
    tick_visible = Makie.Observable(false)

    lines!(
        blockscene,
        lax._yaxis_tick_segments;
        visible = tick_visible,
        inspectable = false,
    )
    text!(
        blockscene,
        lax._yaxis_tick_positions;
        text = lax._yaxis_tick_labels,
        align = (:left, :center),
        fontsize = _LINEAGEAXIS_TICK_FONTSIZE,
        visible = tick_visible,
        inspectable = false,
    )

    function _update_ticks()
        geom = lax.last_geom[]
        show = lax.show_y_axis[]
        if !show || geom === nothing
            tick_visible[] = false
            lax._yaxis_tick_positions[] = Point2f[]
            lax._yaxis_tick_segments[] = Point2f[]
            lax._yaxis_tick_labels[] = String[]
            return
        end

        layout = lax._decoration_layout[]
        bb = (geom::LineageGraphGeometry).boundingbox
        xmid = (Float32(Makie.minimum(bb)[1]) + Float32(Makie.maximum(bb)[1])) / 2.0f0
        ys = _boundingbox_tick_values(geom, :y)

        yaxis_band_rect = layout.yaxis_band_rect
        axis_x = yaxis_band_rect.origin[1] + yaxis_band_rect.widths[1] - 4.0f0
        tick_left = axis_x - _LINEAGEAXIS_TICK_LENGTH_PX
        label_x = yaxis_band_rect.origin[1] + 2.0f0
        plot_bottom = layout.plot_rect.origin[2]
        plot_top = layout.plot_rect.origin[2] + layout.plot_rect.widths[2]

        positions = Point2f[]
        segments = Point2f[Point2f(axis_x, plot_bottom), Point2f(axis_x, plot_top), Point2f(NaN, NaN)]
        for y_val in ys
            block_y = _blockscene_y_for_data(lax, xmid, y_val)
            push!(positions, Point2f(label_x, block_y))
            push!(segments, Point2f(tick_left, block_y), Point2f(axis_x, block_y), Point2f(NaN, NaN))
        end
        lax._yaxis_tick_positions[] = positions
        lax._yaxis_tick_segments[] = segments
        lax._yaxis_tick_labels[] = _axis_tick_labels(ys)
        tick_visible[] = !isempty(positions)
    end

    on(blockscene, lax.show_y_axis) do _
        _update_ticks()
    end
    on(blockscene, lax.last_geom) do _
        _update_ticks()
    end
    on(blockscene, Makie.viewport(lax.scene)) do _
        _update_ticks()
    end
    on(blockscene, layout_obs) do _
        _update_ticks()
    end

    return nothing
end

function _wire_grid!(lax::LineageAxis, blockscene::Scene, layout_obs)
    grid_visible = Makie.Observable(false)
    grid_plot = lines!(
        blockscene,
        lax._grid_segments;
        color = _LINEAGEAXIS_GRID_COLOR,
        linewidth = 1.0,
        visible = grid_visible,
        inspectable = false,
    )
    Makie.translate!(grid_plot, 0, 0, -10)

    function _update_grid()
        geom = lax.last_geom[]
        show_grid = lax.show_grid[]
        if !show_grid || geom === nothing
            grid_visible[] = false
            lax._grid_segments[] = Point2f[]
            return
        end

        xvals = lax.show_x_axis[] ? _boundingbox_tick_values(geom::LineageGraphGeometry, :x) : Float32[]
        yvals = lax.show_y_axis[] ? _boundingbox_tick_values(geom::LineageGraphGeometry, :y) : Float32[]
        if isempty(xvals) && isempty(yvals)
            grid_visible[] = false
            lax._grid_segments[] = Point2f[]
            return
        end

        layout = lax._decoration_layout[]
        bb = geom.boundingbox
        xmid = (Float32(Makie.minimum(bb)[1]) + Float32(Makie.maximum(bb)[1])) / 2.0f0
        ymid = (Float32(Makie.minimum(bb)[2]) + Float32(Makie.maximum(bb)[2])) / 2.0f0
        plot_left = layout.plot_rect.origin[1]
        plot_right = layout.plot_rect.origin[1] + layout.plot_rect.widths[1]
        plot_bottom = layout.plot_rect.origin[2]
        plot_top = layout.plot_rect.origin[2] + layout.plot_rect.widths[2]

        segments = Point2f[]
        for x_val in xvals
            block_x = _blockscene_x_for_data(lax, x_val, ymid)
            push!(segments, Point2f(block_x, plot_bottom), Point2f(block_x, plot_top), Point2f(NaN, NaN))
        end
        for y_val in yvals
            block_y = _blockscene_y_for_data(lax, xmid, y_val)
            push!(segments, Point2f(plot_left, block_y), Point2f(plot_right, block_y), Point2f(NaN, NaN))
        end
        lax._grid_segments[] = segments
        grid_visible[] = !isempty(segments)
    end

    on(blockscene, lax.show_grid) do _
        _update_grid()
    end
    on(blockscene, lax.show_x_axis) do _
        _update_grid()
    end
    on(blockscene, lax.show_y_axis) do _
        _update_grid()
    end
    on(blockscene, lax.last_geom) do _
        _update_grid()
    end
    on(blockscene, Makie.viewport(lax.scene)) do _
        _update_grid()
    end
    on(blockscene, layout_obs) do _
        _update_grid()
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

Rectangular orientations support both horizontal and vertical embeddings:
`:left_to_right`, `:right_to_left`, `:bottom_to_top`, and `:top_to_bottom`.
`:right_to_left` and `:top_to_bottom` are implemented as the corresponding
standard embedding plus a reversed process direction. `:radial` sets equal x
and y extents centred on the data bounding box, producing a square viewport
suitable for circular layouts.
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

    policy = _lineage_orientation_policy(lax.lineage_orientation[])
    effective_reversed = _effective_process_reversed(policy, lax.display_polarity[])

    local leftright::Tuple{Float32, Float32}
    local bottomtop::Tuple{Float32, Float32}

    if !policy.rectangular
        cx   = (data_left + data_right) / 2f0
        cy   = (data_bottom + data_top) / 2f0
        half = max(xspan, yspan) / 2f0 + max(xpad, ypad)
        leftright = effective_reversed ? (cx + half, cx - half) : (cx - half, cx + half)
        bottomtop = (cy - half, cy + half)
    elseif policy.process_axis === :x
        leftright = effective_reversed ?
            (data_right + xpad, data_left - xpad) :
            (data_left - xpad, data_right + xpad)
        bottomtop = (data_bottom - ypad, data_top + ypad)
    else
        leftright = (data_left - xpad, data_right + xpad)
        bottomtop = effective_reversed ?
            (data_top + ypad, data_bottom - ypad) :
            (data_bottom - ypad, data_top + ypad)
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

Backward `lineageunits` values (`:coalescenceage`, `:nodeheights`) assign a
process coordinate of 0 to leaves and increasing values toward the root.
All other values are forward (root = 0, increasing toward leaves).
"""
function _infer_axis_polarity(lineageunits::Symbol)::Symbol
    lineageunits in (:coalescenceage, :nodeheights) && return :backward
    return :forward
end

function _lineageaxis_orientation_defaults(annotation_side::Symbol)::NamedTuple
    if annotation_side === :left
        return (
            leaf_label_offset = Makie.Vec2f(-4, 0),
            leaf_label_align = (:right, :center),
            clade_label_side = :left,
            clade_label_offset = Makie.Vec2f(_LINEAGEAXIS_CLADE_LABEL_OFFSET_PX, 0),
        )
    elseif annotation_side === :right
        return (
            leaf_label_offset = Makie.Vec2f(4, 0),
            leaf_label_align = (:left, :center),
            clade_label_side = :right,
            clade_label_offset = Makie.Vec2f(_LINEAGEAXIS_CLADE_LABEL_OFFSET_PX, 0),
        )
    elseif annotation_side === :top
        return (
            leaf_label_offset = Makie.Vec2f(0, 4),
            leaf_label_align = (:center, :bottom),
            clade_label_side = :top,
            clade_label_offset = Makie.Vec2f(0, _LINEAGEAXIS_CLADE_LABEL_OFFSET_PX),
        )
    elseif annotation_side === :bottom
        return (
            leaf_label_offset = Makie.Vec2f(0, -4),
            leaf_label_align = (:center, :top),
            clade_label_side = :bottom,
            clade_label_offset = Makie.Vec2f(0, _LINEAGEAXIS_CLADE_LABEL_OFFSET_PX),
        )
    end
    throw(
        ArgumentError(
            "unsupported annotation side $(repr(annotation_side)); " *
            "expected :left, :right, :top, or :bottom",
        ),
    )
end

function _resolved_lineageaxis_plot_contract!(
        ax::LineageAxis,
        resolved_lu::Symbol,
        user_kwargs::NamedTuple,
    )::_LineageAxisPlotContract
    if haskey(user_kwargs, :lineage_orientation)
        ax.lineage_orientation[] = user_kwargs.lineage_orientation
    end

    if !ax._polarity_locked[]
        ax.axis_polarity[] = _infer_axis_polarity(resolved_lu)
    end

    lo = ax.lineage_orientation[]
    policy = _lineage_orientation_policy(lo)
    backward = resolved_lu in (:nodeheights, :coalescenceage)
    effective_reversed = _effective_process_reversed(policy, ax.display_polarity[])
    leaves_on_negative_end = xor(backward, effective_reversed)
    annotation_side = leaves_on_negative_end ? policy.negative_annotation_side : policy.positive_annotation_side
    orientation_defaults = policy.rectangular ?
        _lineageaxis_orientation_defaults(annotation_side) :
        NamedTuple()
    plot_kwargs = merge(
        orientation_defaults,
        user_kwargs,
        (
            lineage_orientation = lo,
            rectangular_orientation_owner = :lineageaxis,
        ),
    )
    return _LineageAxisPlotContract(
        lo,
        policy,
        effective_reversed,
        annotation_side,
        plot_kwargs,
    )
end

function _resolved_leaf_label_font(font, italic::Bool)
    return italic ? :italic : font
end

function _resolved_leaf_label_strings(
        geom::LineageGraphGeometry,
        accessor::LineageGraphAccessor,
        text_func,
    )::Vector{String}
    resolved_tf = if text_func === nothing
        if accessor.nodevalue !== nothing
            node -> string(accessor.nodevalue(node))
        else
            node -> string(node)
        end
    else
        text_func
    end
    return String[resolved_tf(node) for node in geom.leaf_order]
end

function _resolved_clade_label_strings(clade_nodes, label_func)::Vector{String}
    return String[string(label_func(node)) for node in clade_nodes]
end

function _resolved_scalebar_label(label)::String
    return string(label)
end

function _annotation_measurements(
        geom::LineageGraphGeometry,
        accessor::LineageGraphAccessor,
        lineage_orientation::Symbol,
        leaf_label_func,
        leaf_label_font,
        leaf_label_fontsize,
        leaf_label_italic::Bool,
        leaf_label_align::Tuple,
        leaf_label_visible::Bool,
        leaf_label_offset::Makie.Vec2f,
        clade_nodes,
        clade_label_func,
        clade_label_fontsize,
        clade_label_visible::Bool,
        clade_label_offset::Makie.Vec2f,
        clade_label_side::Symbol,
        scalebar_visible::Bool,
        scalebar_position::Tuple,
        scalebar_label,
    )::_LineageAxisAnnotationMeasurements
    resolved_leaf_font = _resolved_leaf_label_font(leaf_label_font, leaf_label_italic)
    leaf_strings = _resolved_leaf_label_strings(geom, accessor, leaf_label_func)
    leaf_width_px, leaf_height_px = _max_text_size_px(leaf_strings, resolved_leaf_font, leaf_label_fontsize)

    clade_strings = _resolved_clade_label_strings(clade_nodes, clade_label_func)
    clade_width_px, clade_height_px = _max_text_size_px(clade_strings, :regular, clade_label_fontsize)
    scalebar_label_string = _resolved_scalebar_label(scalebar_label)
    scalebar_width_px, scalebar_height_px = _max_text_size_px(
        String[scalebar_label_string],
        Makie.defaultfont(),
        _LINEAGEAXIS_SCALEBAR_FONTSIZE,
    )

    if lineage_orientation === :radial
        radial_gap_px = max(abs(Float32(leaf_label_offset[1])), 4.0f0)
        return _LineageAxisAnnotationMeasurements(
            :radial,
            leaf_label_visible && !isempty(leaf_strings),
            (leaf_label_align[1], leaf_label_align[2]),
            0.0f0,
            0.0f0,
            0.0f0,
            leaf_width_px,
            leaf_height_px,
            false,
            abs(Float32(clade_label_offset[1])),
            _LINEAGEAXIS_CLADE_TICK_LENGTH_PX,
            _LINEAGEAXIS_CLADE_TEXT_GAP_PX,
            clade_width_px,
            clade_height_px,
            radial_gap_px,
            leaf_width_px,
            leaf_height_px,
            scalebar_visible,
            (scalebar_position[1], scalebar_position[2]),
            scalebar_width_px,
            scalebar_height_px,
            _LINEAGEAXIS_SCALEBAR_LABEL_GAP_PX,
            _LINEAGEAXIS_SCALEBAR_BAND_PADDING_PX,
        )
    end

    active_side = _rectangular_annotation_side(clade_label_side)
    leaf_normal_align = _text_normal_alignment(leaf_label_align, active_side)
    leaf_normal_extent_px = _normal_text_extent_px(leaf_width_px, leaf_height_px, active_side)
    toward_plot_px, away_from_plot_px = _text_extents_for_side(
        leaf_normal_extent_px,
        leaf_normal_align,
        active_side,
    )

    return _LineageAxisAnnotationMeasurements(
        active_side,
        leaf_label_visible && !isempty(leaf_strings),
        (leaf_label_align[1], leaf_label_align[2]),
        _offset_component_px(leaf_label_offset, active_side),
        toward_plot_px,
        away_from_plot_px,
        leaf_width_px,
        leaf_height_px,
        clade_label_visible && !isempty(clade_nodes),
        _offset_component_px(clade_label_offset, active_side),
        _LINEAGEAXIS_CLADE_TICK_LENGTH_PX,
        _LINEAGEAXIS_CLADE_TEXT_GAP_PX,
        clade_width_px,
        clade_height_px,
        max(_offset_component_px(leaf_label_offset, active_side), 4.0f0),
        leaf_width_px,
        leaf_height_px,
        scalebar_visible,
        (scalebar_position[1], scalebar_position[2]),
        scalebar_width_px,
        scalebar_height_px,
        _LINEAGEAXIS_SCALEBAR_LABEL_GAP_PX,
        _LINEAGEAXIS_SCALEBAR_BAND_PADDING_PX,
    )
end

function _sync_annotation_measurements!(ax::LineageAxis, lp::LineagePlot)::Nothing
    function _update_annotation_measurements()
        geom = lp[:computed_geom][]
        geom === nothing && return

        ax._annotation_measurements[] = _annotation_measurements(
            geom,
            lp[:accessor][],
            lp[:lineage_orientation][],
            lp[:leaf_label_func][],
            lp[:leaf_label_font][],
            lp[:leaf_label_fontsize][],
            lp[:leaf_label_italic][],
            lp[:leaf_label_align][],
            lp[:leaf_label_visible][],
            lp[:leaf_label_offset][],
            lp[:clade_nodes][],
            lp[:clade_label_func][],
            lp[:clade_label_fontsize][],
            lp[:clade_label_visible][],
            lp[:clade_label_offset][],
            lp[:clade_label_side][],
            lp[:resolved_scalebar_visible][],
            lp[:scalebar_position][],
            lp[:scalebar_label][],
        )
    end

    _update_annotation_measurements()

    onany(
        ax.scene,
        lp[:computed_geom],
        lp[:lineage_orientation],
        lp[:leaf_label_func],
        lp[:leaf_label_font],
        lp[:leaf_label_fontsize],
        lp[:leaf_label_italic],
        lp[:leaf_label_align],
        lp[:leaf_label_visible],
        lp[:leaf_label_offset],
        lp[:clade_nodes],
        lp[:clade_label_func],
        lp[:clade_label_fontsize],
        lp[:clade_label_visible],
        lp[:clade_label_offset],
        lp[:clade_label_side],
        lp[:resolved_scalebar_visible],
        lp[:scalebar_position],
        lp[:scalebar_label],
    ) do args...
        _update_annotation_measurements()
    end

    return nothing
end

function _wire_annotation_layout!(ax::LineageAxis, lp::LineagePlot)::Nothing
    annotation_layers = filter(p -> p isa Union{LeafLabelLayer, CladeLabelLayer, ScaleBarLayer}, lp.plots)

    function _push_annotation_layout!(layout)
        for plot in annotation_layers
            plot.annotation_layout = layout
        end
        return nothing
    end

    _push_annotation_layout!(ax._decoration_layout[])
    on(ax.scene, ax._decoration_layout) do layout
        _push_annotation_layout!(layout)
    end

    return nothing
end

# ── lineageplot! dispatch for LineageAxis ──────────────────────────────────────

"""
    lineageplot(rootnode, accessor::LineageGraphAccessor; figure = NamedTuple(),
                axis = NamedTuple(), kwargs...) -> Makie.FigureAxisPlot

Non-mutating public entry point for lineage-graph plotting.

Creates a new `Figure` and a new `LineageAxis`, calls `lineageplot!` on that
axis, and returns a Makie `FigureAxisPlot` so the result behaves like other
non-bang Makie plotting functions in the REPL and VS Code.

Use `figure = (...)` to pass keyword arguments to `Figure` and `axis = (...)`
to pass keyword arguments to `LineageAxis`.

For plotting into an existing `Axis` or `LineageAxis`, use `lineageplot!`.
"""
function lineageplot(
        rootnode,
        accessor::LineageGraphAccessor;
        figure = NamedTuple(),
        axis = NamedTuple(),
        kwargs...,
    )::Makie.FigureAxisPlot
    figure_kwargs = _layout_kwargs_namedtuple(figure, "figure")
    axis_kwargs   = _layout_kwargs_namedtuple(axis, "axis")
    fig = Figure(; figure_kwargs...)
    lax = LineageAxis(fig[1, 1]; axis_kwargs...)
    lp = lineageplot!(lax, rootnode, accessor; kwargs...)
    return Makie.FigureAxisPlot(fig, lax, lp)
end

"""
    lineageplot!(ax::LineageAxis, rootnode, accessor::LineageGraphAccessor;
                 lineageunits=nothing, kwargs...) -> LineagePlot

Render a lineage graph on `ax`.

When `ax` is a `LineageAxis`, this method additionally:
1. Infers `ax.axis_polarity` from `lineageunits` unless the user has explicitly
   set it (detected by the `_polarity_locked` flag wired in `initialize_block!`).
2. Computes orientation-aware defaults for `leaf_label_offset`, `leaf_label_align`,
   and `clade_label_side` based on `lineage_orientation` and `display_polarity`.
   Horizontal embeddings default to left/right annotation lanes; vertical
   embeddings default to top/bottom annotation lanes. Caller-supplied keyword
   arguments always override these defaults.
3. Calls `reset_limits!(ax, geom)` after the recipe sets `lp[:computed_geom]`
   so that axis limits fit the lineage graph bounding box with `display_polarity`
   and `lineage_orientation` applied.
4. Registers a reactive `on` callback so that if `rootnode` or `lineageunits`
   changes later, `reset_limits!` is reapplied automatically.

Node labels are off by default (`node_label_threshold = node -> false`); pass an
explicit `node_label_threshold` predicate to enable them.

For the non-mutating convenience form that creates a new `Figure` and
`LineageAxis`, use `lineageplot(rootnode, accessor; kwargs...)`.

All keyword arguments are forwarded to the `LineagePlot` composite recipe.
See `lineageplot!` for the full attribute list.
"""
function lineageplot!(
        ax::LineageAxis,
        rootnode,
        accessor::LineageGraphAccessor;
        lineageunits = nothing,
        kwargs...,
    )::LineagePlot
    user_kwargs = (; kwargs...)

    resolved_lu = _resolve_lineageunits_stub(lineageunits, accessor)
    contract = _resolved_lineageaxis_plot_contract!(ax, resolved_lu, user_kwargs)

    # Route to ax.scene (not ax) to avoid recursive dispatch through the
    # @recipe-generated lineageplot! which also accepts AbstractAxis.
    # plot!(ax::AbstractAxis, ...) at figureplotting.jl:436 would call
    # reset_limits!(ax) after every sub-layer plot! — wasteful and premature
    # before computed_geom is populated. Going directly to ax.scene bypasses
    # the AbstractAxis protocol; we call reset_limits! manually below.
    lp = lineageplot!(ax.scene, rootnode, accessor; lineageunits = lineageunits, contract.plot_kwargs...)

    _wire_annotation_layout!(ax, lp)
    _sync_annotation_measurements!(ax, lp)

    # Apply initial limits. lp[:computed_geom][] is already populated because
    # map! nodes run synchronously during plot! construction (Makie 0.24).
    reset_limits!(ax, lp[:computed_geom][])

    # Register reactive limit updates: whenever rootnode, accessor, or
    # lineageunits changes, computed_geom fires and we re-apply limits.
    on(ax.scene, lp[:computed_geom]) do geom
        reset_limits!(ax, geom)
    end

    return lp
end

# LineageAxis is auto-exported by the @Block macro.
# reset_limits! is exported from LineagesMakie.jl alongside other public names.
