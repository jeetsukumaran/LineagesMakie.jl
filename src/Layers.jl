module Layers

# ComputeGraph (map!) pattern from:
#   Makie/src/compute-plots.jl:544 — positional arg names mapped as ComputeGraph keys
#   GraphMakie.jl/src/recipes.jl:226–234 — register_pixel_projection! idiom

import Makie
using Makie: @recipe, parent_scene, Axis, lines!, scatter!, text!, poly!, Point2f, Vec2f, Rect2f
using LineagesMakie.CoordTransform: register_pixel_projection!, pixel_offset_to_data_delta
using ..Accessors: LineageGraphAccessor, is_leaf, leaves
using ..Geometry: LineageGraphGeometry, rectangular_layout, circular_layout

# ── EdgeLayer ─────────────────────────────────────────────────────────────────

"""
    edgelayer!(ax, geom::LineageGraphGeometry; kwargs...) -> EdgeLayer

Render the edges of a lineage graph as polyline segments on axis `ax`.

For rectangular layouts each edge is a right-angle segment
`(x_parent, y_parent) → (x_parent, y_child) → (x_child, y_child)`. For
circular layouts with `circular_edge_style = :chord` (Tier 1 default) the
path is a chord connector at the parent's radial distance followed by a radial
segment to the child.

# Arguments
- `geom::LineageGraphGeometry`: pre-computed layout geometry from
  `rectangular_layout` or `circular_layout`.

# Keyword attributes
- `color`: uniform Makie color, or a `(fromvertex, tovertex) -> color` function
  for per-edge colors. Default `:black`.
- `linewidth`: line width in pixels. Default `1.0`.
- `linestyle`: Makie line style (`:solid`, `:dash`, `:dot`, etc.). Default `:solid`.
- `alpha`: transparency multiplier in `[0, 1]`. Default `1.0`.
- `edge_style`: edge rendering style; only `:right_angle` is supported in
  Tier 1 (`:chord` is wired in Issue 12). Default `:right_angle`.
- `visible`: whether the layer is rendered. Default `true`.
"""
@recipe EdgeLayer (geom,) begin
    color = :black
    linewidth = 1.0
    linestyle = :solid
    alpha = 1.0
    "Edge rendering style; only `:right_angle` is supported in Tier 1."
    edge_style = :right_angle
    visible = true
end

function Makie.plot!(p::EdgeLayer)
    sc = parent_scene(p)
    register_pixel_projection!(p.attributes, sc)

    map!(p.attributes, [:geom], :edge_shapes_data) do geom
        return geom.edge_shapes
    end

    # Expand a per-edge color function to a per-point color array.
    # Each edge occupies 4 entries in edge_shapes (3 geometry points + 1 NaN
    # separator), so the result has 4 * length(geom.edges) elements.
    map!(p.attributes, [:color, :geom], :resolved_color) do color, geom
        color isa Function || return color
        n = length(geom.edges)
        result = Vector{Any}(undef, 4 * n)
        for (i, (u, v)) in enumerate(geom.edges)
            c = color(u, v)
            base = (i - 1) * 4
            result[base + 1] = c
            result[base + 2] = c
            result[base + 3] = c
            result[base + 4] = c
        end
        return result
    end

    lines!(
        p,
        p[:edge_shapes_data];
        color = p[:resolved_color],
        linewidth = p[:linewidth],
        linestyle = p[:linestyle],
        alpha = p[:alpha],
    )
    return p
end

# ── VertexLayer ───────────────────────────────────────────────────────────────

"""
    vertexlayer!(ax, geom::LineageGraphGeometry, accessor::LineageGraphAccessor; kwargs...) -> VertexLayer

Render markers at internal (non-leaf) vertex positions on axis `ax`.

Markers are drawn in pixel space (`markerspace = :pixel`) so they remain
fixed-size regardless of axis scale or figure resize. The
`CoordTransform.register_pixel_projection!` call ensures the data↔pixel
mapping is reactive to viewport changes.

Internal vertices are those for which `Accessors.is_leaf(accessor, vertex)`
returns `false`. The derived attribute `:vertex_pos_data` holds the filtered
`Vector{Point2f}` and is accessible as `plot_obj[:vertex_pos_data][]`.

# Arguments
- `geom::LineageGraphGeometry`: pre-computed layout geometry from
  `rectangular_layout` or `circular_layout`.
- `accessor::LineageGraphAccessor`: used to identify leaf versus internal
  vertices via `Accessors.is_leaf`.

# Keyword attributes
- `marker`: Makie marker symbol. Default `:circle`.
- `color`: marker fill color. Default `:black`.
- `markersize`: marker diameter in pixels. Default `8`.
- `strokecolor`: marker stroke color. Default `:black`.
- `alpha`: transparency multiplier in `[0, 1]`. Default `1.0`.
- `visible`: whether the layer is rendered. Default `true`.
"""
@recipe VertexLayer (geom, accessor) begin
    marker = :circle
    color = :black
    markersize = 8
    strokecolor = :black
    alpha = 1.0
    visible = true
end

function Makie.plot!(p::VertexLayer)
    sc = parent_scene(p)
    register_pixel_projection!(p.attributes, sc)

    map!(p.attributes, [:geom, :accessor], :vertex_pos_data) do geom, accessor
        return [pos for (v, pos) in geom.vertex_positions if !is_leaf(accessor, v)]
    end

    scatter!(
        p,
        p[:vertex_pos_data];
        marker = p[:marker],
        color = p[:color],
        markersize = p[:markersize],
        strokecolor = p[:strokecolor],
        alpha = p[:alpha],
        markerspace = :pixel,
    )
    return p
end

# ── LeafLayer ─────────────────────────────────────────────────────────────────

"""
    leaflayer!(ax, geom::LineageGraphGeometry, accessor::LineageGraphAccessor; kwargs...) -> LeafLayer

Render markers at leaf vertex positions on axis `ax`.

Markers are drawn in pixel space (`markerspace = :pixel`) so they remain
fixed-size regardless of axis scale or figure resize. The
`CoordTransform.register_pixel_projection!` call ensures the data↔pixel
mapping is reactive to viewport changes.

Leaf vertices are those for which `Accessors.is_leaf(accessor, vertex)`
returns `true`. The derived attribute `:leaf_pos_data` holds the filtered
`Vector{Point2f}` and is accessible as `plot_obj[:leaf_pos_data][]`.

This layer is independently composable from `VertexLayer`: setting
`visible = false` on one does not affect the other.

# Arguments
- `geom::LineageGraphGeometry`: pre-computed layout geometry from
  `rectangular_layout` or `circular_layout`.
- `accessor::LineageGraphAccessor`: used to identify leaf versus internal
  vertices via `Accessors.is_leaf`.

# Keyword attributes
- `marker`: Makie marker symbol. Default `:circle`.
- `color`: marker fill color. Default `:black`.
- `markersize`: marker diameter in pixels. Default `8`.
- `strokecolor`: marker stroke color. Default `:black`.
- `alpha`: transparency multiplier in `[0, 1]`. Default `1.0`.
- `visible`: whether the layer is rendered. Default `true`.
"""
@recipe LeafLayer (geom, accessor) begin
    marker = :circle
    color = :black
    markersize = 8
    strokecolor = :black
    alpha = 1.0
    visible = true
end

function Makie.plot!(p::LeafLayer)
    sc = parent_scene(p)
    register_pixel_projection!(p.attributes, sc)

    map!(p.attributes, [:geom, :accessor], :leaf_pos_data) do geom, accessor
        return [pos for (v, pos) in geom.vertex_positions if is_leaf(accessor, v)]
    end

    scatter!(
        p,
        p[:leaf_pos_data];
        marker = p[:marker],
        color = p[:color],
        markersize = p[:markersize],
        strokecolor = p[:strokecolor],
        alpha = p[:alpha],
        markerspace = :pixel,
    )
    return p
end

# ── LeafLabelLayer ────────────────────────────────────────────────────────────

"""
    leaflabellayer!(ax, geom::LineageGraphGeometry, accessor::LineageGraphAccessor; kwargs...) -> LeafLabelLayer

Render text labels at leaf vertex positions on axis `ax`.

Label positions are computed by adding `offset` (in pixel space) to each leaf's
data-space position. The offset is converted to data-space units via
`CoordTransform.pixel_offset_to_data_delta`, so labels remain correctly placed
after figure resize. Setting `italic = true` renders labels in italic style.

Leaves are iterated in `geom.leaf_order` (transverse-axis order), which
guarantees that label strings and positions share the same index mapping.

# Arguments
- `geom::LineageGraphGeometry`: pre-computed layout geometry from
  `rectangular_layout` or `circular_layout`.
- `accessor::LineageGraphAccessor`: used to resolve the default `text_func`
  when `accessor.vertexvalue` is present.

# Keyword attributes
- `text_func`: a callable `vertex -> String` for label text. When `nothing`
  (default), uses `string(accessor.vertexvalue(v))` if `accessor.vertexvalue`
  is present, otherwise `string(v)`.
- `font`: Makie font. Default `:regular`. Overridden by `italic = true`.
- `fontsize`: label font size in points. Default `12`.
- `color`: label color. Default `:black`.
- `offset`: pixel-space offset from the leaf position as `Vec2f`. Default
  `Vec2f(4, 0)` (4 px rightward). Converted to data-space units reactively so
  the offset remains stable on resize.
- `italic`: when `true`, renders labels in italic style. Default `false`.
- `align`: Makie text alignment tuple. Default `(:left, :center)`.
- `visible`: whether the layer is rendered. Default `true`.
"""
@recipe LeafLabelLayer (geom, accessor) begin
    "Callable `vertex -> String` for label text; `nothing` → vertexvalue or string(v)."
    text_func = nothing
    font = :regular
    fontsize = 12
    color = :black
    "Pixel-space offset from the leaf position. Default: 4 px rightward."
    offset = Makie.Vec2f(4, 0)
    "Apply italic style to labels."
    italic = false
    align = (:left, :center)
    visible = true
end

function Makie.plot!(p::LeafLabelLayer)::LeafLabelLayer
    sc = parent_scene(p)
    register_pixel_projection!(p.attributes, sc)

    # Resolve font: italic overrides the font attribute.
    map!(p.attributes, [:italic, :font], :resolved_font) do italic, font
        return italic ? :italic : font
    end

    # Compute label strings in leaf_order for stable index correspondence.
    map!(p.attributes, [:geom, :accessor, :text_func], :leaf_label_strings) do geom, accessor, text_func
        resolved_tf = if text_func === nothing
            if accessor.vertexvalue !== nothing
                v -> string(accessor.vertexvalue(v))
            else
                v -> string(v)
            end
        else
            text_func
        end
        return String[resolved_tf(v) for v in geom.leaf_order]
    end

    # Compute label positions (leaf pos + pixel-space offset converted to data).
    # Depends on :pixel_projection so this map! reruns on viewport change.
    map!(
        p.attributes,
        [:geom, :offset, :pixel_projection],
        :leaf_label_positions,
    ) do geom, offset, _
        return Point2f[
            geom.vertex_positions[v] +
            Point2f(pixel_offset_to_data_delta(sc, geom.vertex_positions[v], offset))
            for v in geom.leaf_order
        ]
    end

    text!(
        p,
        p[:leaf_label_positions];
        text = p[:leaf_label_strings],
        font = p[:resolved_font],
        fontsize = p[:fontsize],
        color = p[:color],
        align = p[:align],
        visible = p[:visible],
    )
    return p
end

# ── VertexLabelLayer ──────────────────────────────────────────────────────────

"""
    vertexlabellayer!(ax, geom::LineageGraphGeometry, accessor::LineageGraphAccessor; kwargs...) -> VertexLabelLayer

Render data-driven text labels at vertex positions on axis `ax`, with a
threshold predicate to control which vertices are labelled.

At plot time (when `vertexlabellayer!` is called), every vertex that passes
`threshold` is checked: if `value_func` returns a value that is not an
`AbstractString`, `Number`, or `Symbol`, an `ArgumentError` is raised
immediately, identifying the vertex and the returned type.

Position mode `:toward_parent` shifts the label slightly toward the parent
vertex along the transverse axis, separating the label from the vertex marker.

# Arguments
- `geom::LineageGraphGeometry`: pre-computed layout geometry.
- `accessor::LineageGraphAccessor`: used for future extension; not used
  directly in this layer's core logic.

# Keyword attributes
- `value_func`: a callable `vertex -> Any` supplying the label value. Must
  return `AbstractString`, `Number`, or `Symbol` for every vertex that passes
  `threshold`; otherwise `ArgumentError` is raised at plot time. Default:
  `v -> ""` (empty string — labels exist but render invisibly at zero width).
- `threshold`: a predicate `vertex -> Bool` selecting which vertices to label.
  Default: `v -> true` (show all vertices).
- `position`: `:vertex` places the label at the vertex data position;
  `:toward_parent` shifts the label slightly (3 px) toward the parent vertex
  along the transverse axis. Default `:vertex`.
- `font`: Makie font. Default `:regular`.
- `fontsize`: label font size in points. Default `10`.
- `color`: label color. Default `:gray50`.
- `visible`: whether the layer is rendered. Default `true`.
"""
@recipe VertexLabelLayer (geom, accessor) begin
    "Callable `vertex -> Any` supplying label values; must return AbstractString, Number, or Symbol."
    value_func = (v -> "")
    "Predicate `vertex -> Bool`; only vertices returning true are labelled."
    threshold = (v -> true)
    "Label position: `:vertex` or `:toward_parent`."
    position = :vertex
    font = :regular
    fontsize = 10
    color = :gray50
    visible = true
end

function Makie.plot!(p::VertexLabelLayer)::VertexLabelLayer
    sc = parent_scene(p)
    register_pixel_projection!(p.attributes, sc)

    # Build (position, string) pairs for every vertex passing the threshold.
    # The type check is performed here: since Makie 0.24's ComputeGraph runs
    # map! closures immediately during plot!, an ArgumentError raised here
    # propagates directly from vertexlabellayer!, satisfying the "at plot time"
    # requirement without accessing positional args via p.geom[] (which has an
    # opaque type in the ComputeGraph and confuses JET's type inference).
    # Depends on :pixel_projection so this reruns on viewport change (needed
    # for the :toward_parent pixel-offset conversion).
    map!(
        p.attributes,
        [:geom, :value_func, :threshold, :position, :pixel_projection],
        :vertex_label_raw,
    ) do geom, value_func, threshold, position, _
        parent_of = Dict{Any, Any}(tovertex => fromvertex for (fromvertex, tovertex) in geom.edges)
        entries = Tuple{Point2f, String}[]
        for (v, pos) in geom.vertex_positions
            threshold(v) || continue
            val = value_func(v)
            if !isa(val, Union{AbstractString, Number, Symbol})
                throw(
                    ArgumentError(
                        "value_func returned a value of type $(typeof(val)) for vertex $(v), " *
                        "which cannot be rendered as text; " *
                        "expected AbstractString, Number, or Symbol",
                    ),
                )
            end
            label_pos = if position === :toward_parent && haskey(parent_of, v)
                parent_pos = geom.vertex_positions[parent_of[v]]
                dy = parent_pos[2] - pos[2]
                delta = pixel_offset_to_data_delta(sc, pos, Vec2f(0, 3 * sign(dy)))
                pos + Point2f(delta)
            else
                pos
            end
            push!(entries, (label_pos, string(val)))
        end
        return entries
    end

    map!(p.attributes, [:vertex_label_raw], :vertex_label_positions) do entries
        return Point2f[pos for (pos, _) in entries]
    end

    map!(p.attributes, [:vertex_label_raw], :vertex_label_strings) do entries
        return String[str for (_, str) in entries]
    end

    text!(
        p,
        p[:vertex_label_positions];
        text = p[:vertex_label_strings],
        font = p[:font],
        fontsize = p[:fontsize],
        color = p[:color],
        visible = p[:visible],
    )
    return p
end

# ── Private helpers ───────────────────────────────────────────────────────────

"""
Return `Point2f` positions of all leaves in the subtree rooted at `mrca`.
Uses `Accessors.leaves` so cycle detection is inherited automatically.
"""
function _subtree_leaf_positions(
        accessor::LineageGraphAccessor,
        mrca,
        vertex_positions::Dict,
    )::Vector{Point2f}
    subtree_leaves = leaves(accessor, mrca)
    return Point2f[vertex_positions[v] for v in subtree_leaves if haskey(vertex_positions, v)]
end

"""
Return `true` iff `lineageunits` encodes physical process-coordinate units for
which a scale bar is meaningful (`:edgelengths`, `:branchingtime`,
`:coalescenceage`). Returns `false` for all topological modes.
"""
function _scalebar_visible(lineageunits::Symbol)::Bool
    return lineageunits in (:edgelengths, :branchingtime, :coalescenceage)
end

"""
Compute the bottom-left origin of a scale bar in data space given `position`
(halign × valign tuple), the layout bounding box `bb`, and the bar length.
"""
function _scalebar_origin(
        position::Tuple{Symbol, Symbol},
        bb::Rect2f,
        bar_length::Float64,
    )::Point2f
    halign, valign = position
    x = if halign === :left
        bb.origin[1]
    elseif halign === :right
        bb.origin[1] + bb.widths[1] - bar_length
    else  # :center
        bb.origin[1] + (bb.widths[1] - bar_length) / 2
    end
    y = if valign === :bottom
        bb.origin[2] - 0.5f0
    elseif valign === :top
        bb.origin[2] + bb.widths[2] + 0.5f0
    else  # :center
        bb.origin[2] + bb.widths[2] / 2
    end
    return Point2f(x, y)
end

# Mirrors Geometry._resolve_lineageunits without importing that private function.
function _resolve_lineageunits_stub(
        lineageunits::Union{Nothing, Symbol},
        accessor::LineageGraphAccessor,
    )::Symbol
    lineageunits === nothing || return lineageunits
    return accessor.edgelength !== nothing ? :edgelengths : :vertexheights
end

# ── CladeHighlightLayer ───────────────────────────────────────────────────────

"""
    cladehighlightlayer!(ax, geom::LineageGraphGeometry,
                         accessor::LineageGraphAccessor; kwargs...) -> CladeHighlightLayer

Render filled rectangular highlight regions behind subtrees on axis `ax`.

For each MRCA vertex in `clade_vertices`, the layer collects the positions of
all descendant leaves (via `Accessors.leaves`) plus the MRCA vertex itself,
computes the axis-aligned bounding box of those positions, expands the box by
`padding` (pixel space, converted to data units via
`CoordTransform.pixel_offset_to_data_delta`), and renders the result as a
filled rectangle using `poly!`. The padding conversion is viewport-reactive:
it reruns whenever the scene is resized.

# Arguments
- `geom::LineageGraphGeometry`: pre-computed layout geometry.
- `accessor::LineageGraphAccessor`: supplies the `children` callable used to
  traverse each subtree via `Accessors.leaves`.

# Keyword attributes
- `clade_vertices`: `Vector` of MRCA vertices whose subtrees should be
  highlighted. Default `Any[]` (no highlights).
- `color`: fill color, including alpha channel. Default
  `Makie.RGBAf(0.2, 0.6, 1.0, 0.15)`.
- `alpha`: opacity in `[0, 1]`; replaces the alpha of `color` in the rendered
  output. Default `0.15`.
- `padding`: pixel-space expansion of the bounding box on each side, as
  `Vec2f(dx_px, dy_px)`. Default `Vec2f(4, 4)`.
- `visible`: whether the layer is rendered. Default `true`.
"""
@recipe CladeHighlightLayer (geom, accessor) begin
    clade_vertices = Any[]
    color = Makie.RGBAf(0.2f0, 0.6f0, 1.0f0, 0.15f0)
    alpha = 0.15
    "Pixel-space expansion of the clade bounding box. Default: 4 px on each side."
    padding = Makie.Vec2f(4, 4)
    visible = true
end

function Makie.plot!(p::CladeHighlightLayer)::CladeHighlightLayer
    sc = parent_scene(p)
    register_pixel_projection!(p.attributes, sc)

    # Merge color + alpha: alpha overrides the alpha component of color.
    map!(p.attributes, [:color, :alpha], :resolved_highlight_color) do color, alpha
        c = Makie.to_color(color)
        return Makie.RGBAf(c.r, c.g, c.b, Float32(alpha))
    end

    # Compute one Rect2f per MRCA, expanded by pixel-space padding.
    # Depends on :pixel_projection so padding recomputes on viewport change.
    map!(
        p.attributes,
        [:geom, :accessor, :clade_vertices, :padding, :pixel_projection],
        :highlight_rects,
    ) do geom, accessor, clade_vertices, padding, _
        rects = Rect2f[]
        for mrca in clade_vertices
            leaf_pts = _subtree_leaf_positions(accessor, mrca, geom.vertex_positions)
            mrca_pt = get(geom.vertex_positions, mrca, nothing)
            mrca_pt === nothing && continue
            all_pts = push!(copy(leaf_pts), mrca_pt)
            isempty(all_pts) && continue

            xmin = minimum(q[1] for q in all_pts)
            xmax = maximum(q[1] for q in all_pts)
            ymin = minimum(q[2] for q in all_pts)
            ymax = maximum(q[2] for q in all_pts)

            centre = Point2f((xmin + xmax) / 2, (ymin + ymax) / 2)
            dx = pixel_offset_to_data_delta(sc, centre, Vec2f(padding[1], 0))[1]
            dy = pixel_offset_to_data_delta(sc, centre, Vec2f(0, padding[2]))[2]

            push!(
                rects,
                Rect2f(xmin - dx, ymin - dy, (xmax - xmin) + 2dx, (ymax - ymin) + 2dy),
            )
        end
        return rects
    end

    poly!(
        p,
        p[:highlight_rects];
        color = p[:resolved_highlight_color],
        visible = p[:visible],
    )
    return p
end

# ── CladeLabelLayer ───────────────────────────────────────────────────────────

"""
    cladelabellayer!(ax, geom::LineageGraphGeometry,
                     accessor::LineageGraphAccessor; kwargs...) -> CladeLabelLayer

Render bracket annotations with text labels for named clades on axis `ax`.

For each MRCA vertex in `clade_vertices`, the layer draws a vertical bracket at
the right extent of the clade's leaf span (plus `offset` in pixel space), with
two small horizontal tick marks at the top and bottom ends, and a text label at
the bracket midpoint. This is the standard phylogenetic clade-bracket annotation.

Bracket geometry is computed as a NaN-separated `Vector{Point2f}` rendered with
a single `lines!` call. Label positions are kept in a companion derived
attribute `bracket_label_data` from which positions and strings are split.

# Arguments
- `geom::LineageGraphGeometry`: pre-computed layout geometry.
- `accessor::LineageGraphAccessor`: supplies the `children` callable used to
  traverse each subtree via `Accessors.leaves`.

# Keyword attributes
- `clade_vertices`: `Vector` of MRCA vertices to annotate. Default `Any[]`.
- `label_func`: callable `mrca -> String` producing the bracket label.
  Default `v -> ""` (invisible empty labels).
- `color`: line and text color. Default `:black`.
- `fontsize`: label font size in points. Default `11`.
- `offset`: pixel-space offset from the maximum leaf x-position to the bracket
  vertical bar, as `Vec2f(dx_px, 0)`. Default `Vec2f(6, 0)`.
- `visible`: whether the layer is rendered. Default `true`.
"""
@recipe CladeLabelLayer (geom, accessor) begin
    clade_vertices = Any[]
    "Callable `mrca -> String` producing the bracket label."
    label_func = (v -> "")
    color = :black
    fontsize = 11
    "Pixel-space offset from the rightmost leaf position to the bracket bar."
    offset = Makie.Vec2f(6, 0)
    visible = true
end

function Makie.plot!(p::CladeLabelLayer)::CladeLabelLayer
    sc = parent_scene(p)
    register_pixel_projection!(p.attributes, sc)

    # NaN-separated bracket geometry: bottom tick + vertical bar + top tick per clade.
    # Depends on :pixel_projection so offset/tick conversions recompute on resize.
    map!(
        p.attributes,
        [:geom, :accessor, :clade_vertices, :offset, :pixel_projection],
        :bracket_shapes,
    ) do geom, accessor, clade_vertices, offset, _
        pts = Point2f[]
        nan = Point2f(NaN, NaN)
        for mrca in clade_vertices
            leaf_pts = _subtree_leaf_positions(accessor, mrca, geom.vertex_positions)
            isempty(leaf_pts) && continue

            ys = [q[2] for q in leaf_pts]
            y_min = minimum(ys)
            y_max = maximum(ys)
            x_right = maximum(q[1] for q in leaf_pts)
            mid_y = (y_min + y_max) / 2

            anchor = Point2f(x_right, mid_y)
            dx = pixel_offset_to_data_delta(sc, anchor, Vec2f(offset[1], 0))[1]
            dtick = pixel_offset_to_data_delta(sc, anchor, Vec2f(3.0f0, 0))[1]
            x_bar = x_right + dx

            # Bottom tick
            push!(pts, Point2f(x_bar - dtick, y_min), Point2f(x_bar, y_min), nan)
            # Vertical bar
            push!(pts, Point2f(x_bar, y_min), Point2f(x_bar, y_max), nan)
            # Top tick
            push!(pts, Point2f(x_bar, y_max), Point2f(x_bar - dtick, y_max), nan)
        end
        return pts
    end

    # Label (position, string) pairs — one per MRCA.
    # Has a separate dependency on :label_func so label text changes do not
    # force bracket geometry recomputation.
    map!(
        p.attributes,
        [:geom, :accessor, :clade_vertices, :label_func, :offset, :pixel_projection],
        :bracket_label_data,
    ) do geom, accessor, clade_vertices, label_func, offset, _
        entries = Tuple{Point2f, String}[]
        for mrca in clade_vertices
            leaf_pts = _subtree_leaf_positions(accessor, mrca, geom.vertex_positions)
            isempty(leaf_pts) && continue

            ys = [q[2] for q in leaf_pts]
            y_min = minimum(ys)
            y_max = maximum(ys)
            x_right = maximum(q[1] for q in leaf_pts)
            mid_y = (y_min + y_max) / 2

            anchor = Point2f(x_right, mid_y)
            dx = pixel_offset_to_data_delta(sc, anchor, Vec2f(offset[1], 0))[1]
            x_bar = x_right + dx

            push!(entries, (Point2f(x_bar, mid_y), string(label_func(mrca))))
        end
        return entries
    end

    map!(p.attributes, [:bracket_label_data], :bracket_label_positions) do entries
        return Point2f[pos for (pos, _) in entries]
    end

    map!(p.attributes, [:bracket_label_data], :bracket_label_strings) do entries
        return String[str for (_, str) in entries]
    end

    lines!(
        p,
        p[:bracket_shapes];
        color = p[:color],
        visible = p[:visible],
    )
    text!(
        p,
        p[:bracket_label_positions];
        text = p[:bracket_label_strings],
        fontsize = p[:fontsize],
        color = p[:color],
        align = (:left, :center),
        visible = p[:visible],
    )
    return p
end

# ── ScaleBarLayer ─────────────────────────────────────────────────────────────

"""
    scalebarlayer!(ax, geom::LineageGraphGeometry,
                   accessor::LineageGraphAccessor,
                   lineageunits_val::Symbol; kwargs...) -> ScaleBarLayer

Render a scale bar showing the magnitude of process-coordinate units on axis `ax`.

The scale bar is visible by default only when `lineageunits_val` is one of
`:edgelengths`, `:branchingtime`, or `:coalescenceage` — values that carry
physical units. For topological layouts (`:vertexheights`, `:vertexlevels`,
`:vertexdepths`, `:vertexcoords`, `:vertexpos`) the bar defaults to invisible.
This default can be overridden by passing `scalebar_auto_visible = true` or
`scalebar_auto_visible = false` explicitly.

The bar length defaults to 10% of the process-coordinate span of
`geom.boundingbox`. Pass an explicit `length` value (in data units) to override.

# Arguments
- `geom::LineageGraphGeometry`: pre-computed layout geometry; provides the
  bounding box for default bar length and position computation.
- `accessor::LineageGraphAccessor`: accepted for API symmetry with other layers;
  not used by the core logic of this layer.
- `lineageunits_val::Symbol`: the resolved `lineageunits` value; determines the
  default `visible` setting via `_scalebar_visible`.

# Keyword attributes
- `position`: placement as `(halign, valign)` where
  `halign ∈ {:left, :center, :right}` and `valign ∈ {:top, :center, :bottom}`.
  Default `(:left, :bottom)`.
- `length`: bar length in data units. `nothing` (default) → 10% of the
  process-coordinate range from `geom.boundingbox`.
- `label`: text displayed below the bar midpoint. Default `""`.
- `color`: bar and label color. Default `:black`.
- `linewidth`: bar line width in pixels. Default `1.5f0`.
- `scalebar_auto_visible`: `nothing` (default) → derived from `lineageunits_val` via
  `_scalebar_visible`; `true` or `false` overrides the derived default.
  Use the standard `visible` attribute to hide the entire plot object regardless.
"""
@recipe ScaleBarLayer (geom, accessor, lineageunits_val) begin
    position = (:left, :bottom)
    "Bar length in data units; nothing → 10% of process-coordinate span."
    length = nothing
    label = ""
    color = :black
    linewidth = 1.5f0
    "nothing → derived from lineageunits_val via _scalebar_visible; true/false overrides."
    scalebar_auto_visible = nothing
end

function Makie.plot!(p::ScaleBarLayer)::ScaleBarLayer
    # accessor is not used in the core logic; accepted for API symmetry.
    _ = p[:accessor]

    # NOTE: register_pixel_projection! is intentionally omitted here.
    # The scale bar lives entirely in data space (geom.boundingbox); no
    # pixel-space offset conversion is needed.

    # Resolve the auto-visibility sentinel reactively via map!.
    # We use a dedicated `scalebar_auto_visible` attribute rather than overriding
    # Makie's standard `visible` attribute, because Makie internals (autolimit
    # code, bounding-box queries) call `!(plot.visible[])` and would fail if
    # `visible` held `nothing`.
    # `scalebar_auto_visible = nothing` → derived from lineageunits_val;
    # Bool value → used directly.
    map!(p.attributes, [:lineageunits_val, :scalebar_auto_visible], :resolved_visible) do lu, av
        return av === nothing ? _scalebar_visible(lu) : av::Bool
    end

    map!(p.attributes, [:geom, :position, :length], :scalebar_line_pts) do geom, position, len
        bb = geom.boundingbox
        bar_length = len === nothing ? Float64(bb.widths[1]) * 0.1 : Float64(len)
        origin = _scalebar_origin(position, bb, bar_length)
        return Point2f[origin, Point2f(origin[1] + bar_length, origin[2])]
    end

    map!(p.attributes, [:geom, :position, :length], :scalebar_label_pos_vec) do geom, position, len
        bb = geom.boundingbox
        bar_length = len === nothing ? Float64(bb.widths[1]) * 0.1 : Float64(len)
        origin = _scalebar_origin(position, bb, bar_length)
        midpoint = Point2f(origin[1] + bar_length / 2, origin[2])
        return Point2f[midpoint]
    end

    lines!(
        p,
        p[:scalebar_line_pts];
        color = p[:color],
        linewidth = p[:linewidth],
        visible = p[:resolved_visible],
    )
    text!(
        p,
        p[:scalebar_label_pos_vec];
        text = p[:label],
        color = p[:color],
        align = (:center, :top),
        visible = p[:resolved_visible],
    )
    return p
end

# ── LineagePlot composite recipe ──────────────────────────────────────────────

"""
    lineageplot!(ax, rootvertex, accessor::LineageGraphAccessor; kwargs...) -> LineagePlot

Composite entry point. Computes a rectangular or circular layout from
`rootvertex` and `accessor` and renders all visual layers: `EdgeLayer`,
`VertexLayer`, `LeafLayer`, `LeafLabelLayer`, `VertexLabelLayer`,
`CladeHighlightLayer`, `CladeLabelLayer`, and `ScaleBarLayer`.

`lineageunits` selects how process coordinates are computed (see
`Geometry.rectangular_layout` for all values). `nothing` (default) detects
the appropriate value automatically: `:edgelengths` when an `edgelength`
accessor is present, `:vertexheights` otherwise.

`lineage_orientation = :radial` selects `Geometry.circular_layout`; all other
values use `Geometry.rectangular_layout`.

All layer attributes are exposed as namespaced keyword arguments (e.g.,
`edge_color`, `leaf_label_func`, `vertex_label_threshold`). All are Observable-
native: updating `lp.edge_color = :red` changes the rendered edge color without
re-calling `lineageplot!`. The `rootvertex` argument may be a plain value or an
`Observable`; Makie wraps plain values in Observables automatically.

# Arguments
- `ax`: any Makie axis or scene.
- `rootvertex`: the root vertex of the lineage graph.
- `accessor::LineageGraphAccessor`: accessor callables supplying `children`
  and optional `edgelength`, `vertexvalue`, etc.

# Keyword attributes
- `lineageunits`: `nothing` or a `Symbol`; see `Geometry.rectangular_layout`.
- `lineage_orientation`: `:left_to_right` (default), `:right_to_left`, or
  `:radial`. `:radial` triggers `circular_layout`.
- `edge_color`, `edge_linewidth`, `edge_linestyle`, `edge_alpha`,
  `edge_visible`: forwarded to `EdgeLayer`.
- `vertex_marker`, `vertex_color`, `vertex_markersize`, `vertex_strokecolor`,
  `vertex_alpha`, `vertex_visible`: forwarded to `VertexLayer`.
- `leaf_marker`, `leaf_color`, `leaf_markersize`, `leaf_strokecolor`,
  `leaf_alpha`, `leaf_visible`: forwarded to `LeafLayer`.
- `leaf_label_func`, `leaf_label_font`, `leaf_label_fontsize`,
  `leaf_label_color`, `leaf_label_offset`, `leaf_label_italic`,
  `leaf_label_align`, `leaf_label_visible`: forwarded to `LeafLabelLayer`.
- `vertex_label_func`, `vertex_label_threshold`, `vertex_label_position`,
  `vertex_label_font`, `vertex_label_fontsize`, `vertex_label_color`,
  `vertex_label_visible`: forwarded to `VertexLabelLayer`.
- `clade_vertices`: vector of MRCA vertices shared by `CladeHighlightLayer`
  and `CladeLabelLayer`. Default `Any[]`.
- `clade_highlight_color`, `clade_highlight_alpha`, `clade_highlight_padding`,
  `clade_highlight_visible`: forwarded to `CladeHighlightLayer`.
- `clade_label_func`, `clade_label_color`, `clade_label_fontsize`,
  `clade_label_offset`, `clade_label_visible`: forwarded to `CladeLabelLayer`.
- `scalebar_position`, `scalebar_length`, `scalebar_label`, `scalebar_color`,
  `scalebar_linewidth`, `scalebar_auto_visible`: forwarded to `ScaleBarLayer`.

# Returns
The `LineagePlot` plot object. Sub-layer recipes are accessible as children via
`lp.plots` (e.g. `filter(p -> p isa EdgeLayer, lp.plots)`).

# Derived ComputeGraph attributes
- `lp[:computed_geom][]` — current `LineageGraphGeometry`.
- `lp[:resolved_lineageunits][]` — resolved `lineageunits` `Symbol`.
"""
@recipe LineagePlot (rootvertex, accessor) begin
    "How the lineage axis is embedded in the 2D scene: :left_to_right, :right_to_left, or :radial."
    lineage_orientation = :left_to_right
    "Selects how process coordinates are computed. nothing triggers auto-detection."
    lineageunits = nothing

    # ── EdgeLayer ─────────────────────────────────────────────────────────────
    "Edge color; uniform Makie color or (fromvertex, tovertex) -> color function."
    edge_color = :black
    edge_linewidth = 1.0
    edge_linestyle = :solid
    edge_alpha = 1.0
    edge_visible = true

    # ── VertexLayer ───────────────────────────────────────────────────────────
    vertex_marker = :circle
    vertex_color = :black
    vertex_markersize = 8
    vertex_strokecolor = :black
    vertex_alpha = 1.0
    vertex_visible = true

    # ── LeafLayer ─────────────────────────────────────────────────────────────
    leaf_marker = :circle
    leaf_color = :black
    leaf_markersize = 8
    leaf_strokecolor = :black
    leaf_alpha = 1.0
    leaf_visible = true

    # ── LeafLabelLayer ────────────────────────────────────────────────────────
    "Callable vertex -> String for leaf labels; nothing uses vertexvalue or string(v)."
    leaf_label_func = nothing
    leaf_label_font = :regular
    leaf_label_fontsize = 12
    leaf_label_color = :black
    "Pixel-space offset from leaf position. Default: 4 px rightward."
    leaf_label_offset = Makie.Vec2f(4, 0)
    leaf_label_italic = false
    leaf_label_align = (:left, :center)
    leaf_label_visible = true

    # ── VertexLabelLayer ──────────────────────────────────────────────────────
    "Callable vertex -> Any supplying vertex label values."
    vertex_label_func = (v -> "")
    "Predicate vertex -> Bool; only vertices returning true are labelled."
    vertex_label_threshold = (v -> true)
    "Label position: :vertex or :toward_parent."
    vertex_label_position = :vertex
    vertex_label_font = :regular
    vertex_label_fontsize = 10
    vertex_label_color = :gray50
    vertex_label_visible = true

    # ── CladeHighlightLayer (shares clade_vertices with CladeLabelLayer) ──────
    "Vector of MRCA vertices whose subtrees are highlighted and labelled."
    clade_vertices = Any[]
    clade_highlight_color = Makie.RGBAf(0.2f0, 0.6f0, 1.0f0, 0.15f0)
    clade_highlight_alpha = 0.15
    "Pixel-space expansion of clade bounding box on each side."
    clade_highlight_padding = Makie.Vec2f(4, 4)
    clade_highlight_visible = true

    # ── CladeLabelLayer ───────────────────────────────────────────────────────
    "Callable mrca -> String producing the bracket label."
    clade_label_func = (v -> "")
    clade_label_color = :black
    clade_label_fontsize = 11
    "Pixel-space offset from the rightmost leaf position to the bracket bar."
    clade_label_offset = Makie.Vec2f(6, 0)
    clade_label_visible = true

    # ── ScaleBarLayer ─────────────────────────────────────────────────────────
    scalebar_position = (:left, :bottom)
    "Bar length in data units; nothing → 10% of process-coordinate span."
    scalebar_length = nothing
    scalebar_label = ""
    scalebar_color = :black
    scalebar_linewidth = 1.5f0
    "nothing → derived from lineageunits; Bool overrides auto-visibility."
    scalebar_auto_visible = nothing
end

function Makie.plot!(lp::LineagePlot)::LineagePlot
    # Step 1: Resolve lineageunits Symbol reactively.
    # This derived node feeds both the layout computation and the ScaleBar
    # visibility resolution, ensuring both update when lineageunits changes.
    # _initial_lu captures the first run's value for use as ScaleBarLayer's
    # non-reactive third positional arg. Ref{Symbol} gives JET a concrete type,
    # avoiding the union-typed `lp.lineageunits[]` / `lp.accessor[]` pattern.
    _initial_lu = Ref{Symbol}(:vertexheights)
    map!(lp.attributes, [:lineageunits, :accessor], :resolved_lineageunits) do lu, acc
        sym = _resolve_lineageunits_stub(lu, acc)::Symbol
        _initial_lu[] = sym
        return sym
    end

    # Step 2: Compute the full layout geometry reactively.
    # The ComputeGraph fires this closure whenever any of the four inputs
    # changes, recomputing the geometry and notifying all downstream nodes.
    #
    # accessor is stored as Ref{Any} inside the ComputeGraph (per Makie
    # compute-plots.jl:394: `attr[sym].value = RefValue{Any}(arg)`). The
    # type assertion `acc::LineageGraphAccessor` narrows the type for dispatch.
    # This is a justified exception to STYLE-julia.md §1.12 (existential
    # parametricity): the accessor type parameters C,E,V,B,CA,VC,VP are
    # determined at call time and cannot be known at recipe definition time.
    # Same pattern as LineageAxis.last_geom::Observable{Any}.
    map!(
        lp.attributes,
        [:rootvertex, :accessor, :resolved_lineageunits, :lineage_orientation],
        :computed_geom,
    ) do rv, acc, lu, lo
        resolved_acc = acc::LineageGraphAccessor
        return if lo === :radial
            circular_layout(rv, resolved_acc; lineageunits = lu)
        else
            rectangular_layout(rv, resolved_acc; lineageunits = lu)
        end
    end

    # Step 3: Resolve ScaleBar visibility at the composite level.
    # ScaleBarLayer's third positional arg (lineageunits_val::Symbol) is used
    # inside its plot! only when scalebar_auto_visible === nothing. By resolving
    # visibility here and passing a Bool as scalebar_auto_visible, the sub-layer
    # always takes the Bool path and ignores its own lineageunits_val inference.
    # This avoids passing a ComputeGraph Computed node as a positional arg to
    # scalebarlayer! (unsupported pattern in Makie 0.24).
    map!(
        lp.attributes,
        [:resolved_lineageunits, :scalebar_auto_visible],
        :resolved_scalebar_visible,
    ) do lu, av
        return av === nothing ? _scalebar_visible(lu) : av::Bool
    end

    # Step 4: Call all 8 sub-layer recipes, passing ComputeGraph node handles
    # as positional arguments where possible.
    #
    # Reactive chain:
    #   rootvertex changes
    #     → :computed_geom recomputes
    #       → each sub-layer's map! on [:geom, ...] reruns
    #         → render updates
    #
    # Sub-layers are called on `lp` (the parent LineagePlot plot object), not
    # on the axis. This is the composite recipe pattern (see GraphMakie
    # recipes.jl:254–260): sub-plots become children of lp.plots. Calling
    # parent_scene(lp) inside each sub-layer's plot! correctly walks the plot
    # parent chain to find the containing scene.

    cladehighlightlayer!(
        lp, lp[:computed_geom], lp[:accessor];
        clade_vertices = lp[:clade_vertices],
        color = lp[:clade_highlight_color],
        alpha = lp[:clade_highlight_alpha],
        padding = lp[:clade_highlight_padding],
        visible = lp[:clade_highlight_visible],
    )

    edgelayer!(
        lp, lp[:computed_geom];
        color = lp[:edge_color],
        linewidth = lp[:edge_linewidth],
        linestyle = lp[:edge_linestyle],
        alpha = lp[:edge_alpha],
        visible = lp[:edge_visible],
    )

    vertexlayer!(
        lp, lp[:computed_geom], lp[:accessor];
        marker = lp[:vertex_marker],
        color = lp[:vertex_color],
        markersize = lp[:vertex_markersize],
        strokecolor = lp[:vertex_strokecolor],
        alpha = lp[:vertex_alpha],
        visible = lp[:vertex_visible],
    )

    leaflayer!(
        lp, lp[:computed_geom], lp[:accessor];
        marker = lp[:leaf_marker],
        color = lp[:leaf_color],
        markersize = lp[:leaf_markersize],
        strokecolor = lp[:leaf_strokecolor],
        alpha = lp[:leaf_alpha],
        visible = lp[:leaf_visible],
    )

    leaflabellayer!(
        lp, lp[:computed_geom], lp[:accessor];
        text_func = lp[:leaf_label_func],
        font = lp[:leaf_label_font],
        fontsize = lp[:leaf_label_fontsize],
        color = lp[:leaf_label_color],
        offset = lp[:leaf_label_offset],
        italic = lp[:leaf_label_italic],
        align = lp[:leaf_label_align],
        visible = lp[:leaf_label_visible],
    )

    vertexlabellayer!(
        lp, lp[:computed_geom], lp[:accessor];
        value_func = lp[:vertex_label_func],
        threshold = lp[:vertex_label_threshold],
        position = lp[:vertex_label_position],
        font = lp[:vertex_label_font],
        fontsize = lp[:vertex_label_fontsize],
        color = lp[:vertex_label_color],
        visible = lp[:vertex_label_visible],
    )

    cladelabellayer!(
        lp, lp[:computed_geom], lp[:accessor];
        clade_vertices = lp[:clade_vertices],
        label_func = lp[:clade_label_func],
        color = lp[:clade_label_color],
        fontsize = lp[:clade_label_fontsize],
        offset = lp[:clade_label_offset],
        visible = lp[:clade_label_visible],
    )

    # ScaleBarLayer takes (geom, accessor, lineageunits_val) as positional args.
    # The third arg is read at construction time (not reactive) because Makie
    # does not support passing ComputeGraph Computed nodes as positional args.
    # Visibility reactivity is preserved via :resolved_scalebar_visible (Bool)
    # passed as scalebar_auto_visible: ScaleBarLayer.plot! takes the Bool path
    # and never consults lineageunits_val for auto-visibility.
    # _initial_lu[] was set synchronously by the :resolved_lineageunits map! node
    # above (map! nodes run synchronously during plot! construction in Makie 0.24).
    scalebarlayer!(
        lp, lp[:computed_geom], lp[:accessor], _initial_lu[];
        position = lp[:scalebar_position],
        length = lp[:scalebar_length],
        label = lp[:scalebar_label],
        color = lp[:scalebar_color],
        linewidth = lp[:scalebar_linewidth],
        scalebar_auto_visible = lp[:resolved_scalebar_visible],
    )

    return lp
end

export LineagePlot,
    lineageplot!,
    EdgeLayer,
    edgelayer!,
    VertexLayer,
    vertexlayer!,
    LeafLayer,
    leaflayer!,
    LeafLabelLayer,
    leaflabellayer!,
    VertexLabelLayer,
    vertexlabellayer!,
    CladeHighlightLayer,
    cladehighlightlayer!,
    CladeLabelLayer,
    cladelabellayer!,
    ScaleBarLayer,
    scalebarlayer!

end # module Layers
