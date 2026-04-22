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

# ── Block initialization ───────────────────────────────────────────────────────

function Makie.initialize_block!(lax::LineageAxis)
    blockscene = lax.blockscene

    # Create the plotting scene. Viewport is tied to the layout bounding box and
    # rounded to integer pixels (LScene pattern: Makie/src/makielayout/blocks/scene.jl:12).
    scenearea = lift(Makie.round_to_IRect2D, blockscene, lax.layoutobservables.computedbbox)
    lax.scene = Scene(blockscene, scenearea; clear = false, visible = false)

    # Initialize non-attribute Observable fields.
    setfield!(lax, :last_geom, Makie.Observable{Any}(nothing))
    setfield!(lax, :_polarity_locked, Makie.Observable{Bool}(false))

    # Lock axis_polarity when the user explicitly changes it. This observer is
    # connected AFTER attribute initialization so the @Block default assignment
    # (:forward) does not trigger the lock.
    on(blockscene, lax.axis_polarity) do _
        lax._polarity_locked[] = true
    end

    _wire_x_axis!(lax, blockscene)

    return nothing
end

# ── x-axis wiring (Tier-1 minimal) ────────────────────────────────────────────

function _wire_x_axis!(lax::LineageAxis, blockscene::Scene)
    # Render 5 evenly-spaced tick marks and labels in blockscene (the decoration
    # layer, which is not subject to lax.scene's data viewport clip). Tick x
    # positions are converted from data space to lax.scene pixel space via
    # data_to_pixel, then translated to blockscene pixel space using the scene
    # viewport origin. Tick y is placed 10 px below the bottom edge of lax.scene.
    # Full LineAxis integration is deferred to Tier 2.
    tick_positions = Makie.Observable(Point2f[])
    tick_labels    = Makie.Observable(String[])
    tick_visible   = Makie.Observable(false)

    scatter!(
        blockscene,
        tick_positions;
        markersize   = 0,
        visible      = tick_visible,
        inspectable  = false,
    )
    text!(
        blockscene,
        tick_labels;
        position    = tick_positions,
        align       = (:center, :top),
        fontsize    = 10,
        visible     = tick_visible,
        inspectable = false,
    )

    function _update_ticks()
        geom = lax.last_geom[]
        show = lax.show_x_axis[]
        if !show || geom === nothing
            tick_visible[]   = false
            tick_positions[] = Point2f[]
            tick_labels[]    = String[]
            return
        end
        sc_vp = Makie.viewport(lax.scene)[]
        bb    = (geom::LineageGraphGeometry).boundingbox
        xmin  = Float32(Makie.minimum(bb)[1])
        xmax  = Float32(Makie.maximum(bb)[1])
        n     = 5
        xs    = range(xmin, xmax; length = n)

        positions = Point2f[]
        for x_val in xs
            px      = data_to_pixel(lax.scene, Point2f(Float32(x_val), 0.0f0))
            block_x = Float32(sc_vp.origin[1]) + px[1]
            block_y = Float32(sc_vp.origin[2]) - 10.0f0
            push!(positions, Point2f(block_x, block_y))
        end
        tick_positions[] = positions
        tick_labels[]    = [string(round(x; digits = 2)) for x in xs]
        tick_visible[]   = true
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
