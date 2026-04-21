module Layers

# ComputeGraph (map!) pattern from:
#   Makie/src/compute-plots.jl:544 — positional arg names mapped as ComputeGraph keys
#   GraphMakie.jl/src/recipes.jl:226–234 — register_pixel_projection! idiom

import Makie
using Makie: @recipe, parent_scene, Axis, lines!, scatter!, text!, Point2f, Vec2f
using LineagesMakie.CoordTransform: register_pixel_projection!, pixel_offset_to_data_delta
using ..Accessors: LineageGraphAccessor, is_leaf
using ..Geometry: LineageGraphGeometry, rectangular_layout

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

# ── lineageplot! stub ─────────────────────────────────────────────────────────

"""
    lineageplot!(ax::Axis, rootvertex, accessor::LineageGraphAccessor; kwargs...) -> LeafLayer

Tier-1 composite entry point (stub). Computes a rectangular layout from
`rootvertex` and `accessor` and renders `EdgeLayer`, `VertexLayer`, and
`LeafLayer`.

The full composite recipe assembling all visual layers (`LeafLabelLayer`,
`VertexLabelLayer`, `CladeHighlightLayer`, etc.) is Issue 12.

# Arguments
- `ax::Axis`: the Makie axis to render into.
- `rootvertex`: the root vertex of the lineage graph.
- `accessor::LineageGraphAccessor`: accessor callables supplying `children`
  and optional `edgelength`, `vertexvalue`, etc.

# Returns
The `LeafLayer` plot object.
"""
function lineageplot!(
        ax::Axis,
        rootvertex,
        accessor::LineageGraphAccessor;
        kwargs...,
    )::LeafLayer
    geom = rectangular_layout(rootvertex, accessor)
    edgelayer!(ax, geom; kwargs...)
    vertexlayer!(ax, geom, accessor; kwargs...)
    leaflabellayer!(ax, geom, accessor)
    vertexlabellayer!(ax, geom, accessor)
    return leaflayer!(ax, geom, accessor; kwargs...)
end

export lineageplot!,
    EdgeLayer,
    edgelayer!,
    VertexLayer,
    vertexlayer!,
    LeafLayer,
    leaflayer!,
    LeafLabelLayer,
    leaflabellayer!,
    VertexLabelLayer,
    vertexlabellayer!

end # module Layers
