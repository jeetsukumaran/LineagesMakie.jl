module Layers

# ComputeGraph (map!) pattern from:
#   Makie/src/compute-plots.jl:544 — positional arg names mapped as ComputeGraph keys
#   GraphMakie.jl/src/recipes.jl:226–234 — register_pixel_projection! idiom

import Makie
using Makie: @recipe, parent_scene, Axis, lines!, scatter!
using LineagesMakie.CoordTransform: register_pixel_projection!
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
    return leaflayer!(ax, geom, accessor; kwargs...)
end

export lineageplot!, EdgeLayer, edgelayer!, VertexLayer, vertexlayer!, LeafLayer, leaflayer!

end # module Layers
