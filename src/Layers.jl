module Layers

# ComputeGraph (map!) pattern from:
#   Makie/src/compute-plots.jl:544 — positional arg names mapped as ComputeGraph keys
#   GraphMakie.jl/src/recipes.jl:226–234 — register_pixel_projection! idiom

import Makie
using Makie: @recipe, parent_scene, Axis, lines!, scatter!, text!, poly!, Point2f, Vec2f, Rect2f
using LineagesMakie.CoordTransform: register_pixel_projection!, pixel_offset_to_data_delta, data_to_pixel
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
- `render_fill`: whether the marker fill is rendered. Default `true`.
- `render_stroke`: whether the marker stroke is rendered. Default `true`.
- `alpha`: transparency multiplier in `[0, 1]`. Default `1.0`.
- `visible`: whether the layer is rendered. Default `true`.
"""
@recipe VertexLayer (geom, accessor) begin
    marker = :circle
    color = :black
    markersize = 8
    strokecolor = :black
    alpha = 1.0
    render_fill = true
    render_stroke = true
    visible = true
end

function Makie.plot!(p::VertexLayer)
    sc = parent_scene(p)
    register_pixel_projection!(p.attributes, sc)

    map!(p.attributes, [:geom, :accessor], :vertex_pos_data) do geom, accessor
        return [pos for (v, pos) in geom.vertex_positions if !is_leaf(accessor, v)]
    end

    map!(p.attributes, [:color, :render_fill], :resolved_fill_color) do color, render_fill
        return render_fill ? color : Makie.RGBAf(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    end

    map!(p.attributes, [:strokecolor, :render_stroke], :resolved_strokecolor) do strokecolor, render_stroke
        return render_stroke ? strokecolor : Makie.RGBAf(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    end

    scatter!(
        p,
        p[:vertex_pos_data];
        marker = p[:marker],
        color = p[:resolved_fill_color],
        markersize = p[:markersize],
        strokecolor = p[:resolved_strokecolor],
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

Leaf labels are rendered in `Makie.parent(parent_scene(p))` (the blockscene /
decoration layer) so they can sit beyond the data viewport without being
clipped. Their derived positions in `:leaf_label_positions` are therefore
blockscene pixel coordinates, not data coordinates.

For rectangular layouts, `offset` is applied directly in blockscene pixel
coordinates after converting each leaf anchor with `data_to_pixel`.

For radial layouts (`lineage_orientation = :radial`), the first component of
`offset` is applied along the outward radial direction and the second component
is applied along the local tangent. This preserves the existing `Vec2f(4, 0)`
default while changing its meaning from "4 px in global +x" to "4 px outward".
Setting `italic = true` renders labels in italic style.

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
  `Vec2f(4, 0)`. In rectangular layouts this is a direct blockscene pixel
  offset; in radial layouts it is interpreted in the local `(outward, tangent)`
  basis. The offset remains stable on resize.
- `italic`: when `true`, renders labels in italic style. Default `false`.
- `align`: Makie text alignment tuple. Default `(:left, :center)`.
- `lineage_orientation`: `:left_to_right` (default), `:right_to_left`,
  `:bottom_to_top`, `:top_to_bottom`, or `:radial`. Determines whether radial
  outward placement logic is used.
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
    lineage_orientation = :left_to_right
    # Internal LineageAxis-owned layout contract. Standalone layer use leaves
    # this as nothing and falls back to the local offset path.
    annotation_layout = nothing
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

    # Compute blockscene pixel positions and per-label alignments. Depends on
    # :pixel_projection so this map! reruns on viewport change.
    map!(
        p.attributes,
        [:geom, :offset, :align, :lineage_orientation, :annotation_layout, :pixel_projection],
        :leaf_label_data,
    ) do geom, offset, align, lineage_orientation, annotation_layout, _
        return _leaf_label_data(sc, geom, offset, align, lineage_orientation, annotation_layout)
    end

    map!(p.attributes, [:leaf_label_data], :leaf_label_positions) do entries
        return Point2f[pos for (pos, _) in entries]
    end

    map!(p.attributes, [:leaf_label_data], :leaf_label_aligns) do entries
        return Tuple{Symbol, Symbol}[entry_align for (_, entry_align) in entries]
    end

    # Keep one invisible child in the data-scene recipe so Makie's plot-tree
    # traversal still sees a child plot rooted under p.
    lines!(p, Point2f[]; visible = false)

    text!(
        Makie.parent(sc),
        p[:leaf_label_positions];
        text = p[:leaf_label_strings],
        font = p[:resolved_font],
        fontsize = p[:fontsize],
        color = p[:color],
        align = p[:leaf_label_aligns],
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
  Default: `v -> false` (show no vertices; opt-in).
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
    "Predicate `vertex -> Bool`; only vertices returning true are labelled. Default: none (opt-in)."
    threshold = (v -> false)
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

function _to_blockscene_pixel(sc, data_pt::Point2f)::Point2f
    sc_vp = Makie.viewport(sc)[]
    px = data_to_pixel(sc, data_pt)
    return Point2f(
        Float32(sc_vp.origin[1]) + px[1],
        Float32(sc_vp.origin[2]) + px[2],
    )
end

function _geom_center(bb::Rect2f)::Point2f
    return Point2f(
        bb.origin[1] + bb.widths[1] / 2,
        bb.origin[2] + bb.widths[2] / 2,
    )
end

function _normalized_or_default(vec::Vec2f, default::Vec2f)::Vec2f
    norm_sq = vec[1]^2 + vec[2]^2
    norm_sq > 0.0f0 || return default
    inv_norm = inv(sqrt(norm_sq))
    return Vec2f(vec[1] * inv_norm, vec[2] * inv_norm)
end

function _parent_lineage_orientation_policy(lineage_orientation::Symbol)
    return getfield(parentmodule(@__MODULE__), :_lineage_orientation_policy)(lineage_orientation)
end

function _parent_orient_rectangular_geometry(
        geom::LineageGraphGeometry,
        lineage_orientation::Symbol,
        owner_handles_direction::Bool,
    )::LineageGraphGeometry
    return getfield(parentmodule(@__MODULE__), :_orient_rectangular_geometry)(
        geom,
        lineage_orientation,
        owner_handles_direction,
    )
end

function _leaf_label_data(
        sc,
        geom::LineageGraphGeometry,
        offset::Vec2f,
        align::Tuple,
        lineage_orientation::Symbol,
        annotation_layout,
    )::Vector{Tuple{Point2f, Tuple{Symbol, Symbol}}}
    entries = Tuple{Point2f, Tuple{Symbol, Symbol}}[]

    if annotation_layout !== nothing && lineage_orientation !== :radial
        side = annotation_layout.active_annotation_side
        if side in (:left, :right)
            shared_align = annotation_layout.leaf_label_align
            anchor_x = annotation_layout.leaf_label_anchor_x
            for v in geom.leaf_order
                anchor = geom.vertex_positions[v]
                block_anchor = _to_blockscene_pixel(sc, anchor)
                push!(entries, (Point2f(anchor_x, block_anchor[2]), shared_align))
            end
            return entries
        elseif side in (:top, :bottom)
            shared_align = annotation_layout.leaf_label_align
            anchor_y = annotation_layout.leaf_label_anchor_y
            for v in geom.leaf_order
                anchor = geom.vertex_positions[v]
                block_anchor = _to_blockscene_pixel(sc, anchor)
                push!(entries, (Point2f(block_anchor[1], anchor_y), shared_align))
            end
            return entries
        end
    end

    if lineage_orientation === :radial
        center = _geom_center(geom.boundingbox)
        outward_gap_px = if annotation_layout !== nothing && annotation_layout.active_annotation_side === :radial
            annotation_layout.radial_leaf_gap_px
        else
            offset[1]
        end
        for v in geom.leaf_order
            anchor = geom.vertex_positions[v]
            outward = _normalized_or_default(
                Vec2f(anchor[1] - center[1], anchor[2] - center[2]),
                Vec2f(1, 0),
            )
            tangent = Vec2f(-outward[2], outward[1])
            block_anchor = _to_blockscene_pixel(sc, anchor)
            pixel_delta = outward * outward_gap_px + tangent * offset[2]
            halign = outward[1] < 0.0f0 ? :right : :left
            push!(entries, (block_anchor + Point2f(pixel_delta), (halign, :center)))
        end
        return entries
    end

    resolved_align = (align[1], align[2])
    for v in geom.leaf_order
        anchor = geom.vertex_positions[v]
        block_anchor = _to_blockscene_pixel(sc, anchor)
        push!(entries, (block_anchor + Point2f(offset), resolved_align))
    end
    return entries
end

function _shared_clade_annotation_active(annotation_layout)::Bool
    annotation_layout === nothing && return false
    return annotation_layout.active_annotation_side in (:left, :right, :top, :bottom)
end

function _shared_bracket_pixel_shapes(
        sc,
        geom::LineageGraphGeometry,
        accessor::LineageGraphAccessor,
        clade_vertices,
        annotation_layout,
    )::Vector{Point2f}
    !_shared_clade_annotation_active(annotation_layout) && return Point2f[]

    side = annotation_layout.active_annotation_side
    tick_length_px = annotation_layout.clade_tick_length_px
    pts = Point2f[]
    nan = Point2f(NaN, NaN)

    for mrca in clade_vertices
        leaf_pts = _subtree_leaf_positions(accessor, mrca, geom.vertex_positions)
        isempty(leaf_pts) && continue
        leaf_px = Point2f[_to_blockscene_pixel(sc, pt) for pt in leaf_pts]
        xs = [q[1] for q in leaf_px]
        ys = [q[2] for q in leaf_px]
        x_min = minimum(xs)
        x_max = maximum(xs)
        y_min = minimum(ys)
        y_max = maximum(ys)

        if side === :right
            x_bar = annotation_layout.clade_bracket_x
            push!(pts, Point2f(x_bar - tick_length_px, y_min), Point2f(x_bar, y_min), nan)
            push!(pts, Point2f(x_bar, y_min), Point2f(x_bar, y_max), nan)
            push!(pts, Point2f(x_bar, y_max), Point2f(x_bar - tick_length_px, y_max), nan)
        elseif side === :left
            x_bar = annotation_layout.clade_bracket_x
            push!(pts, Point2f(x_bar + tick_length_px, y_min), Point2f(x_bar, y_min), nan)
            push!(pts, Point2f(x_bar, y_min), Point2f(x_bar, y_max), nan)
            push!(pts, Point2f(x_bar, y_max), Point2f(x_bar + tick_length_px, y_max), nan)
        elseif side === :top
            y_bar = annotation_layout.clade_bracket_y
            push!(pts, Point2f(x_min, y_bar - tick_length_px), Point2f(x_min, y_bar), nan)
            push!(pts, Point2f(x_min, y_bar), Point2f(x_max, y_bar), nan)
            push!(pts, Point2f(x_max, y_bar), Point2f(x_max, y_bar - tick_length_px), nan)
        else
            y_bar = annotation_layout.clade_bracket_y
            push!(pts, Point2f(x_min, y_bar + tick_length_px), Point2f(x_min, y_bar), nan)
            push!(pts, Point2f(x_min, y_bar), Point2f(x_max, y_bar), nan)
            push!(pts, Point2f(x_max, y_bar), Point2f(x_max, y_bar + tick_length_px), nan)
        end
    end
    return pts
end

function _shared_bracket_label_pixel_positions(
        sc,
        geom::LineageGraphGeometry,
        accessor::LineageGraphAccessor,
        clade_vertices,
        annotation_layout,
    )::Vector{Point2f}
    !_shared_clade_annotation_active(annotation_layout) && return Point2f[]

    positions = Point2f[]
    for mrca in clade_vertices
        leaf_pts = _subtree_leaf_positions(accessor, mrca, geom.vertex_positions)
        isempty(leaf_pts) && continue
        leaf_px = Point2f[_to_blockscene_pixel(sc, pt) for pt in leaf_pts]
        xs = [q[1] for q in leaf_px]
        ys = [q[2] for q in leaf_px]
        if annotation_layout.active_annotation_side in (:left, :right)
            x_label = annotation_layout.clade_label_anchor_x
            push!(positions, Point2f(x_label, (minimum(ys) + maximum(ys)) / 2))
        else
            y_label = annotation_layout.clade_label_anchor_y
            push!(positions, Point2f((minimum(xs) + maximum(xs)) / 2, y_label))
        end
    end
    return positions
end

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

The two-argument overload additionally requires a non-empty label, which is the
default user-facing auto-visibility contract for `ScaleBarLayer`.
"""
function _scalebar_visible(lineageunits::Symbol)::Bool
    return lineageunits in (:edgelengths, :branchingtime, :coalescenceage)
end

function _scalebar_visible(lineageunits::Symbol, label)::Bool
    return _scalebar_visible(lineageunits) && !isempty(strip(string(label)))
end

function _resolved_scalebar_length(
        geom::LineageGraphGeometry,
        len,
        lineage_orientation::Symbol,
    )::Float64
    bb = geom.boundingbox
    if len !== nothing
        return Float64(len)
    end
    policy = _parent_lineage_orientation_policy(lineage_orientation)
    process_span = (!policy.rectangular || policy.process_axis === :x) ? bb.widths[1] : bb.widths[2]
    return Float64(process_span) * 0.1
end

function _scalebar_length_px(
        sc,
        geom::LineageGraphGeometry,
        bar_length::Float64,
        lineage_orientation::Symbol,
    )::Float32
    bb = geom.boundingbox
    if lineage_orientation === :radial
        center = _geom_center(bb)
        start_pt = center
        end_pt = Point2f(center[1] + Float32(bar_length), center[2])
        px_start = data_to_pixel(sc, start_pt)
        px_end = data_to_pixel(sc, end_pt)
        return abs(Float32(px_end[1] - px_start[1]))
    else
        policy = _parent_lineage_orientation_policy(lineage_orientation)
        if policy.process_axis === :x
            y_mid = Float32(Makie.minimum(bb)[2] + Makie.maximum(bb)[2]) / 2.0f0
            start_x = Float32(Makie.minimum(bb)[1])
            start_pt = Point2f(start_x, y_mid)
            end_pt = Point2f(start_x + Float32(bar_length), y_mid)
            px_start = data_to_pixel(sc, start_pt)
            px_end = data_to_pixel(sc, end_pt)
            return abs(Float32(px_end[1] - px_start[1]))
        end
        x_mid = Float32(Makie.minimum(bb)[1] + Makie.maximum(bb)[1]) / 2.0f0
        start_y = Float32(Makie.minimum(bb)[2])
        start_pt = Point2f(x_mid, start_y)
        end_pt = Point2f(x_mid, start_y + Float32(bar_length))
        px_start = data_to_pixel(sc, start_pt)
        px_end = data_to_pixel(sc, end_pt)
        return abs(Float32(px_end[2] - px_start[2]))
    end
end

function _scalebar_origin_x(
        halign::Symbol,
        band_rect::Rect2f,
        bar_length_px::Float32,
    )::Float32
    usable_width = max(Float32(band_rect.widths[1]) - bar_length_px, 0.0f0)
    if halign === :right
        return Float32(band_rect.origin[1]) + usable_width
    elseif halign === :center
        return Float32(band_rect.origin[1]) + usable_width / 2.0f0
    end
    return Float32(band_rect.origin[1])
end

"""
Compute the bottom-left origin of a scale bar in data space given `position`
(halign × valign tuple), the layout bounding box `bb`, and the bar length.
"""
function _scalebar_origin(
        position::Tuple{Symbol, Symbol},
        bb::Rect2f,
        bar_length::Float64,
        lineage_orientation::Symbol,
    )::Point2f
    policy = _parent_lineage_orientation_policy(lineage_orientation)
    halign, valign = position
    if !policy.rectangular || policy.process_axis === :x
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
    x = if halign === :left
        bb.origin[1] - 0.5f0
    elseif halign === :right
        bb.origin[1] + bb.widths[1] + 0.5f0
    else  # :center
        bb.origin[1] + bb.widths[1] / 2
    end
    y = if valign === :bottom
        bb.origin[2]
    elseif valign === :top
        bb.origin[2] + bb.widths[2] - bar_length
    else  # :center
        bb.origin[2] + (bb.widths[2] - bar_length) / 2
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
`CoordTransform.pixel_offset_to_data_delta`) only when the owning plot scene's
viewport is valid, clamps the expanded rect to the layout bounding box as a
final geometric safety bound, and renders the result as a filled rectangle
using `poly!`. When the viewport is degenerate, the layer falls back to the raw
unpadded clade bounds for that evaluation rather than interpreting raw pixel
offsets as data-space padding. The padding conversion is viewport-reactive: it
reruns whenever the scene is resized.

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

            vp = Makie.viewport(sc)[]
            vp_w, vp_h = Makie.widths(vp)
            adx, ady = if iszero(vp_w) || iszero(vp_h)
                # A degenerate viewport means pixel_offset_to_data_delta would
                # hand raw pixel offsets back as data units. For highlights that
                # would create incorrect full-span rectangles, so use the raw
                # clade bounds with zero padding until the viewport resolves.
                (0.0f0, 0.0f0)
            else
                centre = Point2f((xmin + xmax) / 2, (ymin + ymax) / 2)
                dx = pixel_offset_to_data_delta(sc, centre, Vec2f(padding[1], 0))[1]
                dy = pixel_offset_to_data_delta(sc, centre, Vec2f(0, padding[2]))[2]
                # Use abs: on reversed axes the projection gives negative dx/dy,
                # but highlight padding always expands outward symmetrically.
                (abs(dx), abs(dy))
            end

            bb          = geom.boundingbox
            bb_x0       = Float32(Makie.minimum(bb)[1])
            bb_x1       = Float32(Makie.maximum(bb)[1])
            bb_y0       = Float32(Makie.minimum(bb)[2])
            bb_y1       = Float32(Makie.maximum(bb)[2])
            # Clamp as a final safety bound; the degenerate-viewport case is
            # handled above by suppressing padding rather than by relying on
            # clamping to repair fallback-expanded geometry.
            padded_xmin = max(xmin - adx, bb_x0)
            padded_xmax = min(xmax + adx, bb_x1)
            padded_ymin = max(ymin - ady, bb_y0)
            padded_ymax = min(ymax + ady, bb_y1)
            push!(
                rects,
                Rect2f(
                    padded_xmin, padded_ymin,
                    padded_xmax - padded_xmin,
                    padded_ymax - padded_ymin,
                ),
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

Bracket lines and labels are rendered in `Makie.parent(parent_scene(p))` (the
blockscene / decoration layer) rather than the data-clipped axis scene. This
ensures that brackets placed beyond the data extent (outside `[bb_x0, bb_x1]`)
are not clipped by the axis camera. The derived attributes
`:bracket_pixel_shapes` and `:bracket_label_pixel_positions` hold the
corresponding blockscene pixel coordinates and are updated reactively whenever
the scene viewport or camera changes.

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
- `offset`: pixel-space offset from the leaf span toward the bracket bar.
  Horizontal brackets use the x component; vertical brackets use the y
  component. Default `Vec2f(6, 0)`.
- `side`: which side of the leaf tips to place the bracket. Supported values
  are `:right` (default), `:left`, `:top`, and `:bottom`. Set automatically by
  `lineageplot!(ax::LineageAxis, ...)` based on orientation.
- `visible`: whether the layer is rendered. Default `true`.
"""
@recipe CladeLabelLayer (geom, accessor) begin
    clade_vertices = Any[]
    "Callable `mrca -> String` producing the bracket label."
    label_func = (v -> "")
    color = :black
    fontsize = 11
    "Pixel-space offset from the leaf span toward the bracket bar."
    offset = Makie.Vec2f(6, 0)
    "Bracket side relative to leaf tips: :right, :left, :top, or :bottom."
    side = :right
    annotation_layout = nothing
    visible = true
end

function Makie.plot!(p::CladeLabelLayer)::CladeLabelLayer
    sc = parent_scene(p)
    register_pixel_projection!(p.attributes, sc)

    # NaN-separated bracket geometry in data space. Horizontal sides produce
    # the classic vertical phylogenetic bracket; top/bottom sides produce the
    # transposed horizontal version for vertical embeddings.
    map!(
        p.attributes,
        [:geom, :accessor, :clade_vertices, :offset, :pixel_projection, :side],
        :bracket_shapes,
    ) do geom, accessor, clade_vertices, offset, _, side
        pts = Point2f[]
        for mrca in clade_vertices
            leaf_pts = _subtree_leaf_positions(accessor, mrca, geom.vertex_positions)
            isempty(leaf_pts) && continue

            xs    = [q[1] for q in leaf_pts]
            ys    = [q[2] for q in leaf_pts]
            x_min = minimum(xs)
            x_max = maximum(xs)
            y_min = minimum(ys)
            y_max = maximum(ys)
            mid_x = (x_min + x_max) / 2
            mid_y = (y_min + y_max) / 2
            nan   = Point2f(NaN, NaN)

            if side === :right
                x_anchor = maximum(q[1] for q in leaf_pts)
                anchor   = Point2f(x_anchor, mid_y)
                dx_off   = pixel_offset_to_data_delta(sc, anchor, Vec2f(offset[1], 0))[1]
                dx_tick  = pixel_offset_to_data_delta(sc, anchor, Vec2f(3.0f0, 0))[1]
                x_bar    = x_anchor + dx_off
                push!(pts, Point2f(x_bar - dx_tick, y_min), Point2f(x_bar, y_min), nan)
                push!(pts, Point2f(x_bar, y_min),            Point2f(x_bar, y_max), nan)
                push!(pts, Point2f(x_bar, y_max),            Point2f(x_bar - dx_tick, y_max), nan)
            elseif side === :left
                x_anchor = minimum(q[1] for q in leaf_pts)
                anchor   = Point2f(x_anchor, mid_y)
                dx_off   = pixel_offset_to_data_delta(sc, anchor, Vec2f(offset[1], 0))[1]
                dx_tick  = pixel_offset_to_data_delta(sc, anchor, Vec2f(3.0f0, 0))[1]
                x_bar    = x_anchor - dx_off
                push!(pts, Point2f(x_bar + dx_tick, y_min), Point2f(x_bar, y_min), nan)
                push!(pts, Point2f(x_bar, y_min),            Point2f(x_bar, y_max), nan)
                push!(pts, Point2f(x_bar, y_max),            Point2f(x_bar + dx_tick, y_max), nan)
            elseif side === :top
                y_anchor = maximum(q[2] for q in leaf_pts)
                anchor   = Point2f(mid_x, y_anchor)
                dy_off   = pixel_offset_to_data_delta(sc, anchor, Vec2f(0, offset[2]))[2]
                dy_tick  = pixel_offset_to_data_delta(sc, anchor, Vec2f(0, 3.0f0))[2]
                y_bar    = y_anchor + dy_off
                push!(pts, Point2f(x_min, y_bar - dy_tick), Point2f(x_min, y_bar), nan)
                push!(pts, Point2f(x_min, y_bar),           Point2f(x_max, y_bar), nan)
                push!(pts, Point2f(x_max, y_bar),           Point2f(x_max, y_bar - dy_tick), nan)
            elseif side === :bottom
                y_anchor = minimum(q[2] for q in leaf_pts)
                anchor   = Point2f(mid_x, y_anchor)
                dy_off   = pixel_offset_to_data_delta(sc, anchor, Vec2f(0, offset[2]))[2]
                dy_tick  = pixel_offset_to_data_delta(sc, anchor, Vec2f(0, 3.0f0))[2]
                y_bar    = y_anchor - dy_off
                push!(pts, Point2f(x_min, y_bar + dy_tick), Point2f(x_min, y_bar), nan)
                push!(pts, Point2f(x_min, y_bar),           Point2f(x_max, y_bar), nan)
                push!(pts, Point2f(x_max, y_bar),           Point2f(x_max, y_bar + dy_tick), nan)
            else
                throw(
                    ArgumentError(
                        "unsupported clade label side $(repr(side)); " *
                        "supported values are :right, :left, :top, and :bottom",
                    ),
                )
            end
        end
        return pts
    end

    # Label (position, string, align) triples — one per MRCA.
    map!(
        p.attributes,
        [:geom, :accessor, :clade_vertices, :label_func, :offset, :pixel_projection, :side],
        :bracket_label_data,
    ) do geom, accessor, clade_vertices, label_func, offset, _, side
        entries = Tuple{Point2f, String, Tuple{Symbol, Symbol}}[]
        for mrca in clade_vertices
            leaf_pts = _subtree_leaf_positions(accessor, mrca, geom.vertex_positions)
            isempty(leaf_pts) && continue

            xs    = [q[1] for q in leaf_pts]
            ys    = [q[2] for q in leaf_pts]
            x_min = minimum(xs)
            x_max = maximum(xs)
            y_min = minimum(ys)
            y_max = maximum(ys)
            mid_x = (x_min + x_max) / 2
            mid_y = (y_min + y_max) / 2

            if side === :right
                x_anchor = maximum(q[1] for q in leaf_pts)
                anchor   = Point2f(x_anchor, mid_y)
                dx_off   = pixel_offset_to_data_delta(sc, anchor, Vec2f(offset[1], 0))[1]
                x_bar    = x_anchor + dx_off
                push!(entries, (Point2f(x_bar, mid_y), string(label_func(mrca)), (:left, :center)))
            elseif side === :left
                x_anchor = minimum(q[1] for q in leaf_pts)
                anchor   = Point2f(x_anchor, mid_y)
                dx_off   = pixel_offset_to_data_delta(sc, anchor, Vec2f(offset[1], 0))[1]
                x_bar    = x_anchor - dx_off
                push!(entries, (Point2f(x_bar, mid_y), string(label_func(mrca)), (:right, :center)))
            elseif side === :top
                y_anchor = maximum(q[2] for q in leaf_pts)
                anchor   = Point2f(mid_x, y_anchor)
                dy_off   = pixel_offset_to_data_delta(sc, anchor, Vec2f(0, offset[2]))[2]
                y_bar    = y_anchor + dy_off
                push!(entries, (Point2f(mid_x, y_bar), string(label_func(mrca)), (:center, :bottom)))
            elseif side === :bottom
                y_anchor = minimum(q[2] for q in leaf_pts)
                anchor   = Point2f(mid_x, y_anchor)
                dy_off   = pixel_offset_to_data_delta(sc, anchor, Vec2f(0, offset[2]))[2]
                y_bar    = y_anchor - dy_off
                push!(entries, (Point2f(mid_x, y_bar), string(label_func(mrca)), (:center, :top)))
            else
                throw(
                    ArgumentError(
                        "unsupported clade label side $(repr(side)); " *
                        "supported values are :right, :left, :top, and :bottom",
                    ),
                )
            end
        end
        return entries
    end

    map!(p.attributes, [:bracket_label_data], :bracket_label_positions) do entries
        return Point2f[pos for (pos, _, _) in entries]
    end

    map!(p.attributes, [:bracket_label_data], :bracket_label_strings) do entries
        return String[str for (_, str, _) in entries]
    end

    map!(p.attributes, [:bracket_label_data], :local_bracket_label_aligns) do entries
        return Tuple{Symbol, Symbol}[align for (_, _, align) in entries]
    end

    map!(p.attributes, [:local_bracket_label_aligns, :annotation_layout], :bracket_label_aligns) do aligns, annotation_layout
        if _shared_clade_annotation_active(annotation_layout)
            return Tuple{Symbol, Symbol}[annotation_layout.clade_label_align for _ in aligns]
        end
        return aligns
    end

    # Convert NaN-separated bracket line points to blockscene pixel coordinates.
    # Depends on :pixel_projection so this reruns whenever viewport or camera changes.
    map!(
        p.attributes,
        [:geom, :accessor, :clade_vertices, :bracket_shapes, :annotation_layout, :pixel_projection],
        :bracket_pixel_shapes,
    ) do geom, accessor, clade_vertices, shapes, annotation_layout, _
        if _shared_clade_annotation_active(annotation_layout)
            return _shared_bracket_pixel_shapes(sc, geom, accessor, clade_vertices, annotation_layout)
        end

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

    # Convert label anchor positions to blockscene pixel coordinates.
    # Depends on :pixel_projection so this reruns whenever viewport or camera changes.
    map!(
        p.attributes,
        [:geom, :accessor, :clade_vertices, :bracket_label_positions, :annotation_layout, :pixel_projection],
        :bracket_label_pixel_positions,
    ) do geom, accessor, clade_vertices, positions, annotation_layout, _
        if _shared_clade_annotation_active(annotation_layout)
            return _shared_bracket_label_pixel_positions(
                sc,
                geom,
                accessor,
                clade_vertices,
                annotation_layout,
            )
        end

        sc_vp = Makie.viewport(sc)[]
        return Point2f[
            Point2f(
                Float32(sc_vp.origin[1]) + data_to_pixel(sc, pos)[1],
                Float32(sc_vp.origin[2]) + data_to_pixel(sc, pos)[2],
            )
            for pos in positions
        ]
    end

    # Dummy invisible Lines child in p keeps p.plots non-empty so that Makie's
    # autolimits/boundingbox machinery can find a child plot with :clip_planes.
    # An empty vector contributes no data to autolimit computation.
    lines!(p, Point2f[]; visible = false)

    # Render into the decoration scene (blockscene = Makie.parent(sc)) so that
    # bracket geometry placed beyond the axis data extent is not clipped by the
    # ax.scene orthographic camera. These sub-plots do NOT appear in p.plots.
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
    return p
end

# ── ScaleBarLayer ─────────────────────────────────────────────────────────────

"""
    scalebarlayer!(ax, geom::LineageGraphGeometry,
                   accessor::LineageGraphAccessor,
                   lineageunits_val::Symbol; kwargs...) -> ScaleBarLayer

Render a scale bar showing the magnitude of process-coordinate units on axis `ax`.

The scale bar is visible by default only when both of the following are true:

- `lineageunits_val` is one of `:edgelengths`, `:branchingtime`, or
  `:coalescenceage` — values that carry physical units.
- `label` is non-empty after trimming whitespace.

For topological layouts (`:vertexheights`, `:vertexlevels`, `:vertexdepths`,
`:vertexcoords`, `:vertexpos`) or unlabeled bars, the scale bar defaults to
invisible. This default can be overridden by passing
`scalebar_auto_visible = true` or `scalebar_auto_visible = false` explicitly.

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
- `scalebar_auto_visible`: `nothing` (default) → derived from
  `lineageunits_val` and `label`; `true` or `false` overrides the derived
  default.
  Use the standard `visible` attribute to hide the entire plot object regardless.
"""
@recipe ScaleBarLayer (geom, accessor, lineageunits_val) begin
    position = (:left, :bottom)
    "Bar length in data units; nothing → 10% of process-coordinate span."
    length = nothing
    label = ""
    color = :black
    linewidth = 1.5f0
    lineage_orientation = :left_to_right
    annotation_layout = nothing
    "nothing → derived from lineageunits_val and label; true/false overrides."
    scalebar_auto_visible = nothing
end

function Makie.plot!(p::ScaleBarLayer)::ScaleBarLayer
    # accessor is not used in the core logic; accepted for API symmetry.
    _ = p[:accessor]
    sc = parent_scene(p)
    register_pixel_projection!(p.attributes, sc)

    # Resolve the auto-visibility sentinel reactively via map!.
    # We use a dedicated `scalebar_auto_visible` attribute rather than overriding
    # Makie's standard `visible` attribute, because Makie internals (autolimit
    # code, bounding-box queries) call `!(plot.visible[])` and would fail if
    # `visible` held `nothing`.
    # `scalebar_auto_visible = nothing` → derived from lineageunits_val and label;
    # Bool value → used directly.
    map!(p.attributes, [:lineageunits_val, :label, :scalebar_auto_visible], :resolved_visible) do lu, label, av
        return av === nothing ? _scalebar_visible(lu, label) : av::Bool
    end

    map!(
        p.attributes,
        [:geom, :position, :length, :lineage_orientation],
        :scalebar_line_pts,
    ) do geom, position, len, lineage_orientation
        bb = geom.boundingbox
        bar_length = _resolved_scalebar_length(geom, len, lineage_orientation)
        origin = _scalebar_origin(position, bb, bar_length, lineage_orientation)
        policy = _parent_lineage_orientation_policy(lineage_orientation)
        if !policy.rectangular || policy.process_axis === :x
            return Point2f[origin, Point2f(origin[1] + bar_length, origin[2])]
        end
        return Point2f[origin, Point2f(origin[1], origin[2] + bar_length)]
    end

    map!(
        p.attributes,
        [:geom, :position, :length, :lineage_orientation],
        :scalebar_label_pos_vec,
    ) do geom, position, len, lineage_orientation
        bb = geom.boundingbox
        bar_length = _resolved_scalebar_length(geom, len, lineage_orientation)
        origin = _scalebar_origin(position, bb, bar_length, lineage_orientation)
        policy = _parent_lineage_orientation_policy(lineage_orientation)
        midpoint = if !policy.rectangular || policy.process_axis === :x
            Point2f(origin[1] + bar_length / 2, origin[2])
        else
            Point2f(origin[1], origin[2] + bar_length / 2)
        end
        return Point2f[midpoint]
    end

    map!(
        p.attributes,
        [:geom, :length, :lineage_orientation, :annotation_layout, :pixel_projection],
        :scalebar_line_pixel_pts,
    ) do geom, len, lineage_orientation, annotation_layout, _
        annotation_layout === nothing && return Point2f[]
        annotation_layout.scalebar_visible || return Point2f[]

        bar_length = _resolved_scalebar_length(geom, len, lineage_orientation)
        bar_length_px = min(
            _scalebar_length_px(sc, geom, bar_length, lineage_orientation),
            Float32(annotation_layout.scalebar_band_rect.widths[1]),
        )
        x0 = _scalebar_origin_x(
            annotation_layout.scalebar_halign,
            annotation_layout.scalebar_band_rect,
            bar_length_px,
        )
        y = annotation_layout.scalebar_line_y
        return Point2f[Point2f(x0, y), Point2f(x0 + bar_length_px, y)]
    end

    map!(
        p.attributes,
        [:scalebar_line_pixel_pts, :annotation_layout],
        :scalebar_label_pixel_pos_vec,
    ) do line_pts, annotation_layout
        annotation_layout === nothing && return Point2f[]
        length(line_pts) == 2 || return Point2f[]
        return Point2f[
            Point2f(
                (line_pts[1][1] + line_pts[2][1]) / 2.0f0,
                annotation_layout.scalebar_label_y,
            ),
        ]
    end

    map!(p.attributes, [:annotation_layout], :render_in_blockscene) do annotation_layout
        return annotation_layout !== nothing
    end

    map!(p.attributes, [:position, :lineage_orientation], :resolved_data_label_align) do position, lineage_orientation
        policy = _parent_lineage_orientation_policy(lineage_orientation)
        if !policy.rectangular || policy.process_axis === :x
            return (:center, :top)
        elseif position[1] === :right
            return (:right, :center)
        else
            return (:left, :center)
        end
    end

    map!(p.attributes, [:resolved_visible, :render_in_blockscene], :resolved_data_visible) do visible, in_blockscene
        return visible && !in_blockscene
    end

    map!(p.attributes, [:resolved_visible, :render_in_blockscene], :resolved_blockscene_visible) do visible, in_blockscene
        return visible && in_blockscene
    end

    lines!(p, Point2f[]; visible = false)
    decoration_sc = Makie.parent(sc)

    lines!(
        p,
        p[:scalebar_line_pts];
        color = p[:color],
        linewidth = p[:linewidth],
        visible = p[:resolved_data_visible],
    )
    text!(
        p,
        p[:scalebar_label_pos_vec];
        text = p[:label],
        color = p[:color],
        align = p[:resolved_data_label_align],
        fontsize = 10,
        visible = p[:resolved_data_visible],
    )
    lines!(
        decoration_sc,
        p[:scalebar_line_pixel_pts];
        color = p[:color],
        linewidth = p[:linewidth],
        visible = p[:resolved_blockscene_visible],
    )
    text!(
        decoration_sc,
        p[:scalebar_label_pixel_pos_vec];
        text = p[:label],
        color = p[:color],
        align = (:center, :top),
        fontsize = 10,
        visible = p[:resolved_blockscene_visible],
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
values use `Geometry.rectangular_layout`, followed by owner-level rectangular
embedding repair for vertical orientations.

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
- `lineage_orientation`: `:left_to_right` (default), `:right_to_left`,
  `:bottom_to_top`, `:top_to_bottom`, or `:radial`. `:radial` triggers
  `circular_layout`.
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
  `clade_label_offset`, `clade_label_side`, `clade_label_visible`: forwarded to
  `CladeLabelLayer`. `clade_label_side` is set automatically by
  `lineageplot!(ax::LineageAxis, ...)` based on orientation.
- `scalebar_position`, `scalebar_length`, `scalebar_label`, `scalebar_color`,
  `scalebar_linewidth`, `scalebar_auto_visible`: forwarded to `ScaleBarLayer`.

# Returns
The `LineagePlot` plot object. Sub-layer recipes are accessible as children via
`lp.plots` (e.g. `filter(p -> p isa EdgeLayer, lp.plots)`).

For the non-mutating convenience entry point that creates a `Figure` and
`LineageAxis` automatically, use `LineagesMakie.lineageplot`.

# Derived ComputeGraph attributes
- `lp[:computed_geom][]` — current `LineageGraphGeometry`.
- `lp[:resolved_lineageunits][]` — resolved `lineageunits` `Symbol`.
"""
@recipe LineagePlot (rootvertex, accessor) begin
    "How the lineage axis is embedded in the 2D scene: :left_to_right, :right_to_left, :bottom_to_top, :top_to_bottom, or :radial."
    lineage_orientation = :left_to_right
    "Selects how process coordinates are computed. nothing triggers auto-detection."
    lineageunits = nothing
    # Internal ownership split: LineageAxis keeps rectangular direction reversal
    # in its camera policy, while standalone plots bake it into geometry.
    rectangular_orientation_owner = :plot

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
    "Predicate vertex -> Bool; only vertices returning true are labelled. Default: none (opt-in)."
    vertex_label_threshold = (v -> false)
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
    "Pixel-space offset from the leaf span toward the bracket bar."
    clade_label_offset = Makie.Vec2f(6, 0)
    "Side on which the clade bracket is placed: :right, :left, :top, or :bottom."
    clade_label_side = :right
    clade_label_visible = true

    # ── ScaleBarLayer ─────────────────────────────────────────────────────────
    scalebar_position = (:left, :bottom)
    "Bar length in data units; nothing → 10% of process-coordinate span."
    scalebar_length = nothing
    scalebar_label = ""
    scalebar_color = :black
    scalebar_linewidth = 1.5f0
    "nothing → derived from lineageunits and label; Bool overrides auto-visibility."
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
        [:rootvertex, :accessor, :resolved_lineageunits, :lineage_orientation, :rectangular_orientation_owner],
        :computed_geom,
    ) do rv, acc, lu, lo, orientation_owner
        resolved_acc = acc::LineageGraphAccessor
        return if lo === :radial
            circular_layout(rv, resolved_acc; lineageunits = lu)
        else
            base_geom = rectangular_layout(rv, resolved_acc; lineageunits = lu)
            owner_handles_direction = if orientation_owner === :lineageaxis
                true
            elseif orientation_owner === :plot
                false
            else
                throw(
                    ArgumentError(
                        "unsupported rectangular_orientation_owner $(repr(orientation_owner)); " *
                        "expected :plot or :lineageaxis",
                    ),
                )
            end
            _parent_orient_rectangular_geometry(base_geom, lo, owner_handles_direction)
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
        [:resolved_lineageunits, :scalebar_label, :scalebar_auto_visible],
        :resolved_scalebar_visible,
    ) do lu, label, av
        return av === nothing ? _scalebar_visible(lu, label) : av::Bool
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

    # Internal vertex markers are rendered in two passes so the marker fill can
    # sit under the branches while the outline remains visible on top. This
    # preserves junction continuity without discarding marker styling.
    vertexlayer!(
        lp, lp[:computed_geom], lp[:accessor];
        marker = lp[:vertex_marker],
        color = lp[:vertex_color],
        markersize = lp[:vertex_markersize],
        strokecolor = lp[:vertex_strokecolor],
        alpha = lp[:vertex_alpha],
        render_fill = true,
        render_stroke = false,
        visible = lp[:vertex_visible],
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
        render_fill = false,
        render_stroke = true,
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
        lineage_orientation = lp[:lineage_orientation],
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
        side = lp[:clade_label_side],
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
        lineage_orientation = lp[:lineage_orientation],
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
