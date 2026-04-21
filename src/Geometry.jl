module Geometry

# edge_paths representation research:
# Makie's lines! accepts a single Vector{Point2f} with Point2f(NaN, NaN)
# separators between disconnected polylines. This is used throughout Makie:
#   - Makie/src/stats/dendrogram.jl:80: push!(ret_points, Point2d(NaN))
#   - GraphMakie.jl/src/recipes.jl:728: push!(points, PT(NaN))
# One lines! call draws all edges; NaN breaks the connected path between them.
# Confirmed from Makie/src/conversions.jl:207: push!(points, PT(NaN)) for Rect3.

using Makie: Point2f, Rect2f

using ..Accessors: LineageGraphAccessor, is_leaf, leaves, preorder

# ── LineageGraphGeometry ────────────────────────────────────────────────────────

"""
    LineageGraphGeometry{V}

Immutable struct holding the computed 2D layout of a lineage graph.

`V` is the vertex identity type. In generic use `V` is `Any`; callers that
work with a uniform vertex type may instantiate a more specific `V` for
better type-inference downstream.

Coordinate convention: the first component of each `Point2f` is the process
coordinate (primary lineage axis); the second is the transverse coordinate
(leaf-spacing axis). In a left-to-right rectangular layout the process
coordinate is on the x-axis and the transverse coordinate is on the y-axis.

Fields:
- `vertex_positions::Dict{V,Point2f}`: maps each vertex to its `Point2f` position.
- `edge_paths::Vector{Point2f}`: all edge right-angle polylines concatenated
  into a single vector with `Point2f(NaN, NaN)` separators between paths.
  Suitable for a single `lines!` call.
- `leaf_order::Vector{V}`: leaves in the order they appear along the transverse
  axis (preorder depth-first traversal order).
- `boundingbox::Rect2f`: smallest axis-aligned rectangle enclosing all entries
  in `vertex_positions`.
"""
struct LineageGraphGeometry{V}
    vertex_positions::Dict{V,Point2f}
    edge_paths::Vector{Point2f}
    leaf_order::Vector{V}
    boundingbox::Rect2f
end

# ── boundingbox ────────────────────────────────────────────────────────────────

"""
    boundingbox(geom::LineageGraphGeometry) -> Rect2f

Return the smallest axis-aligned rectangle enclosing all `vertex_positions`
in `geom`. The value is computed at layout time and returned directly.
"""
function boundingbox(geom::LineageGraphGeometry)::Rect2f
    return geom.boundingbox
end

# ── rectangular_layout ─────────────────────────────────────────────────────────

"""
    rectangular_layout(rootvertex, accessor::LineageGraphAccessor;
                       leaf_spacing=:equal,
                       lineageunits::Symbol=:vertexheights) -> LineageGraphGeometry

Compute a rectangular (right-angle) layout for a rooted lineage graph.

Process coordinates (first `Point2f` component) are determined by
`lineageunits`:
- `:vertexheights` — per-vertex height: edge count to the farthest descendant
  leaf. Leaves = 0, root = maximum. Backward axis polarity.
- `:vertexlevels` — edge count from rootvertex: root = 0, leaves = maximum.
  Forward axis polarity.

Transverse coordinates (second `Point2f` component) place leaves at equal
intervals by default. The `leaf_order` field records the leaf sequence.

Each edge `fromvertex → tovertex` contributes a right-angle polyline:
  `(x_from, y_from) → (x_from, y_to) → (x_to, y_to)`
followed by a `Point2f(NaN, NaN)` separator.

# Arguments
- `rootvertex`: root of the lineage graph; first positional argument.
- `accessor::LineageGraphAccessor`: supplies the `children` callable and optional
  accessor fields. Only `children` is required for this function.
- `leaf_spacing`: `:equal` (default) for unit inter-leaf spacing, or a
  positive real number for an explicit inter-leaf distance in layout units.
- `lineageunits::Symbol`: selects how process coordinates are computed.
  Supported values: `:vertexheights`, `:vertexlevels`.

# Returns
A `LineageGraphGeometry` with fully populated fields.

# Throws
- `ArgumentError` if the lineage graph has zero leaves.
- `ArgumentError` if `leaf_spacing` is a non-positive real number.
- `ArgumentError` if `lineageunits` is not a supported value for this function.
"""
function rectangular_layout(
    rootvertex,
    accessor::LineageGraphAccessor;
    leaf_spacing = :equal,
    lineageunits::Symbol = :vertexheights,
)::LineageGraphGeometry
    step = _validate_leaf_spacing(leaf_spacing)

    leaf_list = leaves(accessor, rootvertex)
    isempty(leaf_list) && throw(
        ArgumentError(
            "lineage graph rooted at $(repr(rootvertex)) has zero leaves; " *
            "a layout requires at least one leaf",
        ),
    )

    all_vertices = preorder(accessor, rootvertex)

    process_coords = _process_coords(rootvertex, accessor, lineageunits, all_vertices)
    transverse_coords = _assign_transverse(leaf_list, accessor, all_vertices, step)

    vertex_positions = _build_vertex_positions(all_vertices, process_coords, transverse_coords)
    edge_paths = _build_edge_paths(all_vertices, accessor, process_coords, transverse_coords)
    bb = _compute_boundingbox(vertex_positions)

    return LineageGraphGeometry(vertex_positions, edge_paths, leaf_list, bb)
end

# ── Internal: leaf spacing validation ─────────────────────────────────────────

function _validate_leaf_spacing(leaf_spacing)::Float64
    if leaf_spacing === :equal
        return 1.0
    elseif leaf_spacing isa Real
        leaf_spacing > 0 || throw(
            ArgumentError(
                "leaf_spacing must be a positive real number; got $(leaf_spacing)",
            ),
        )
        return Float64(leaf_spacing)
    else
        throw(
            ArgumentError(
                "leaf_spacing must be :equal or a positive real number; " *
                "got $(repr(leaf_spacing)) ($(typeof(leaf_spacing)))",
            ),
        )
    end
end

# ── Internal: process coordinate computation ───────────────────────────────────

function _process_coords(
    rootvertex,
    accessor::LineageGraphAccessor,
    lineageunits::Symbol,
    all_vertices::Vector,
)::Dict{Any,Float64}
    if lineageunits === :vertexheights
        return _vertexheights(all_vertices, accessor)
    elseif lineageunits === :vertexlevels
        return _vertexlevels(rootvertex, all_vertices, accessor)
    else
        throw(
            ArgumentError(
                "unsupported lineageunits value: $(repr(lineageunits)); " *
                "rectangular_layout currently supports " *
                ":vertexheights and :vertexlevels",
            ),
        )
    end
end

# :vertexheights — postorder: leaf = 0, internal = max(children) + 1
function _vertexheights(all_vertices::Vector, accessor::LineageGraphAccessor)::Dict{Any,Float64}
    heights = Dict{Any,Float64}()
    # Reversing a preorder traversal yields a valid postorder (children before
    # parents), because in preorder every parent precedes all its descendants.
    for v in Iterators.reverse(all_vertices)
        ch = accessor.children(v)
        if isempty(ch)
            heights[v] = 0.0
        else
            heights[v] = maximum(heights[c] for c in ch) + 1.0
        end
    end
    return heights
end

# :vertexlevels — preorder: root = 0, each child = parent + 1
function _vertexlevels(
    rootvertex,
    all_vertices::Vector,
    accessor::LineageGraphAccessor,
)::Dict{Any,Float64}
    levels = Dict{Any,Float64}()
    levels[rootvertex] = 0.0
    for v in all_vertices
        lv = levels[v]
        for c in accessor.children(v)
            levels[c] = lv + 1.0
        end
    end
    return levels
end

# ── Internal: transverse coordinate assignment ─────────────────────────────────

# Leaves get equally spaced transverse positions (1*step, 2*step, …).
# Internal vertices are placed at the mean of their children's transverse
# positions. Reverse preorder (≈ postorder) ensures children are assigned
# before their parents.
function _assign_transverse(
    leaf_list::Vector,
    accessor::LineageGraphAccessor,
    all_vertices::Vector,
    step::Float64,
)::Dict{Any,Float64}
    transverse = Dict{Any,Float64}()
    for (i, leaf) in enumerate(leaf_list)
        transverse[leaf] = i * step
    end
    for v in Iterators.reverse(all_vertices)
        haskey(transverse, v) && continue
        n = 0
        s = 0.0
        for c in accessor.children(v)
            n += 1
            s += transverse[c]
        end
        transverse[v] = s / n
    end
    return transverse
end

# ── Internal: geometry assembly ────────────────────────────────────────────────

function _build_vertex_positions(
    all_vertices::Vector,
    process_coords::Dict{Any,Float64},
    transverse_coords::Dict{Any,Float64},
)::Dict{Any,Point2f}
    pos = Dict{Any,Point2f}()
    for v in all_vertices
        pos[v] = Point2f(process_coords[v], transverse_coords[v])
    end
    return pos
end

# Each edge produces three points forming a right-angle path, plus a NaN
# separator. For an edge fromvertex → tovertex with coordinates (xp, yp)
# and (xc, yc):
#   (xp, yp) → (xp, yc) → (xc, yc) → (NaN, NaN)
# The first segment is parallel to the transverse axis (changes y at fixed x).
# The second segment is parallel to the lineage axis (changes x at fixed y).
function _build_edge_paths(
    all_vertices::Vector,
    accessor::LineageGraphAccessor,
    process_coords::Dict{Any,Float64},
    transverse_coords::Dict{Any,Float64},
)::Vector{Point2f}
    paths = Point2f[]
    for v in all_vertices
        xp = process_coords[v]
        yp = transverse_coords[v]
        for c in accessor.children(v)
            xc = process_coords[c]
            yc = transverse_coords[c]
            push!(paths,
                Point2f(xp, yp),
                Point2f(xp, yc),
                Point2f(xc, yc),
                Point2f(NaN, NaN),
            )
        end
    end
    return paths
end

function _compute_boundingbox(vertex_positions::Dict{Any,Point2f})::Rect2f
    isempty(vertex_positions) && return Rect2f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    first_p = first(values(vertex_positions))
    xmin = xmax = first_p[1]
    ymin = ymax = first_p[2]
    for p in values(vertex_positions)
        x, y = p[1], p[2]
        x < xmin && (xmin = x)
        x > xmax && (xmax = x)
        y < ymin && (ymin = y)
        y > ymax && (ymax = y)
    end
    return Rect2f(xmin, ymin, xmax - xmin, ymax - ymin)
end

# ── Exports ────────────────────────────────────────────────────────────────────

export LineageGraphGeometry, boundingbox, rectangular_layout

end # module Geometry
