module Geometry

# edge_shapes representation research:
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
- `edge_shapes::Vector{Point2f}`: all edge right-angle polylines concatenated
  into a single vector with `Point2f(NaN, NaN)` separators between shapes.
  Suitable for a single `lines!` call.
- `leaf_order::Vector{V}`: leaves in the order they appear along the transverse
  axis (preorder depth-first traversal order).
- `boundingbox::Rect2f`: smallest axis-aligned rectangle enclosing all entries
  in `vertex_positions`.
"""
struct LineageGraphGeometry{V}
    vertex_positions::Dict{V,Point2f}
    edge_shapes::Vector{Point2f}
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
                       lineageunits::Union{Nothing,Symbol}=nothing,
                       nonultrametric::Symbol=:error) -> LineageGraphGeometry

Compute a rectangular (right-angle) layout for a rooted lineage graph.

Process coordinates (first `Point2f` component) are determined by `lineageunits`:

- `:edgelengths` — cumulative `edgelength(fromvertex, tovertex)` from
  `rootvertex`; requires `edgelength` accessor; `rootvertex` = 0, increases
  toward leaves. Missing edge lengths emit `@warn` and fall back to 1.0;
  negative edge lengths raise `ArgumentError`.
- `:branchingtime` — per-vertex branching time read directly from
  `branchingtime(vertex)`; requires `branchingtime` accessor; `rootvertex` = 0.
- `:coalescenceage` — per-vertex coalescence age read from
  `coalescenceage(vertex)`; requires `coalescenceage` accessor; leaves = 0,
  increases toward root. Non-ultrametric inputs are controlled by `nonultrametric`.
- `:vertexdepths` — integer edge count from `rootvertex`; `rootvertex` = 0,
  increases by 1 per edge. No accessor required.
- `:vertexheights` — per-vertex height: edge count to the farthest descendant
  leaf. Leaves = 0, root = maximum. No accessor required.
- `:vertexlevels` — edge count from `rootvertex`: root = 0, leaves = maximum.
  Equal inter-level spacing. No accessor required.
- `:vertexcoords` — user-supplied `Point2f` data coordinates read from
  `vertexcoords(vertex)`; requires `vertexcoords` accessor. Bypasses layout
  computation entirely; both process and transverse coordinates come from the
  accessor.
- `:vertexpos` — user-supplied `Point2f` pixel coordinates read from
  `vertexpos(vertex)`; requires `vertexpos` accessor. Same geometry-layer
  behaviour as `:vertexcoords`; the semantic distinction (data vs pixel space)
  is documented here but not enforced at the geometry layer.

**Default detection:** if `lineageunits` is not supplied (or `nothing`), the
default is `:edgelengths` when an `edgelength` accessor is present; otherwise
`:vertexheights`.

Transverse coordinates (second `Point2f` component) place leaves at equal
intervals by default (`leaf_spacing = :equal`). The `leaf_order` field records
the leaf sequence.

Each edge `fromvertex → tovertex` contributes a right-angle polyline:
  `(x_from, y_from) → (x_from, y_to) → (x_to, y_to)`
followed by a `Point2f(NaN, NaN)` separator.

# Arguments
- `rootvertex`: root of the lineage graph; first positional argument.
- `accessor::LineageGraphAccessor`: supplies the `children` callable and
  optional accessor fields.
- `leaf_spacing`: `:equal` (default) for unit inter-leaf spacing, or a
  positive real number for an explicit inter-leaf distance in layout units.
- `lineageunits::Union{Nothing,Symbol}`: selects how process coordinates are
  computed. `nothing` triggers default detection (see above).
- `nonultrametric::Symbol`: policy for non-ultrametric inputs when
  `lineageunits = :coalescenceage`. `:error` (default) raises `ArgumentError`;
  `:minimum` uses the minimum of the children's coalescenceage values;
  `:maximum` uses the maximum.

# Returns
A `LineageGraphGeometry` with fully populated fields.

# Throws
- `ArgumentError` if the lineage graph has zero leaves.
- `ArgumentError` if `leaf_spacing` is a non-positive real number.
- `ArgumentError` if a required accessor is `nothing` for the chosen `lineageunits`.
- `ArgumentError` if `lineageunits` is not a supported value.
- `ArgumentError` if `lineageunits = :edgelengths` and any edge length is negative.
- `ArgumentError` if `lineageunits = :coalescenceage`, the tree is non-ultrametric,
  and `nonultrametric = :error`.
"""
function rectangular_layout(
    rootvertex,
    accessor::LineageGraphAccessor;
    leaf_spacing = :equal,
    lineageunits::Union{Nothing,Symbol} = nothing,
    nonultrametric::Symbol = :error,
)::LineageGraphGeometry
    lineageunits = _resolve_lineageunits(lineageunits, accessor)
    step = _validate_leaf_spacing(leaf_spacing)

    leaf_list = leaves(accessor, rootvertex)
    isempty(leaf_list) && throw(
        ArgumentError(
            "lineage graph rooted at $(repr(rootvertex)) has zero leaves; " *
            "a layout requires at least one leaf",
        ),
    )

    all_vertices = preorder(accessor, rootvertex)

    # Bypass modes: both process and transverse coordinates come from the accessor.
    if lineageunits === :vertexcoords || lineageunits === :vertexpos
        accessor_fn = lineageunits === :vertexcoords ? accessor.vertexcoords : accessor.vertexpos
        accessor_fn === nothing && throw(
            ArgumentError(
                "lineageunits = $(repr(lineageunits)) requires a $(lineageunits) accessor " *
                "but none was supplied",
            ),
        )
        vertex_positions = Dict{Any,Point2f}(v => Point2f(accessor_fn(v)) for v in all_vertices)
        pc = Dict{Any,Float64}(v => Float64(vertex_positions[v][1]) for v in all_vertices)
        tc = Dict{Any,Float64}(v => Float64(vertex_positions[v][2]) for v in all_vertices)
        edge_shapes = _build_edge_shapes(all_vertices, accessor, pc, tc)
        bb = _compute_boundingbox(vertex_positions)
        return LineageGraphGeometry(vertex_positions, edge_shapes, leaf_list, bb)
    end

    process_coords = _process_coords(rootvertex, accessor, lineageunits, all_vertices, nonultrametric)
    transverse_coords = _assign_transverse(leaf_list, accessor, all_vertices, step)

    vertex_positions = _build_vertex_positions(all_vertices, process_coords, transverse_coords)
    edge_shapes = _build_edge_shapes(all_vertices, accessor, process_coords, transverse_coords)
    bb = _compute_boundingbox(vertex_positions)

    return LineageGraphGeometry(vertex_positions, edge_shapes, leaf_list, bb)
end

# ── Internal: default lineageunits detection ───────────────────────────────────

"""
    _resolve_lineageunits(lineageunits, accessor) -> Symbol

Resolve the `lineageunits` sentinel `nothing` to the appropriate default.

If `lineageunits` is not `nothing`, it is returned unchanged. Otherwise:
- `:edgelengths` if `accessor.edgelength` is not `nothing`.
- `:vertexheights` otherwise.
"""
function _resolve_lineageunits(
    lineageunits::Union{Nothing,Symbol},
    accessor::LineageGraphAccessor,
)::Symbol
    lineageunits !== nothing && return lineageunits
    return accessor.edgelength !== nothing ? :edgelengths : :vertexheights
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
    nonultrametric::Symbol,
)::Dict{Any,Float64}
    if lineageunits === :vertexheights
        return _vertexheights(all_vertices, accessor)
    elseif lineageunits === :vertexlevels
        return _vertexlevels(rootvertex, all_vertices, accessor)
    elseif lineageunits === :edgelengths
        accessor.edgelength === nothing && throw(
            ArgumentError(
                "lineageunits = :edgelengths requires an edgelength accessor " *
                "but none was supplied",
            ),
        )
        return _cumulative_preorder(
            rootvertex,
            all_vertices,
            accessor,
            (u, v) -> _safe_edgelength(accessor, u, v),
        )
    elseif lineageunits === :branchingtime
        accessor.branchingtime === nothing && throw(
            ArgumentError(
                "lineageunits = :branchingtime requires a branchingtime accessor " *
                "but none was supplied",
            ),
        )
        bt = accessor.branchingtime
        return _cumulative_preorder(
            rootvertex,
            all_vertices,
            accessor,
            (u, v) -> bt(v) - bt(u),
        )
    elseif lineageunits === :vertexdepths
        return _vertex_depths(rootvertex, all_vertices, accessor)
    elseif lineageunits === :coalescenceage
        accessor.coalescenceage === nothing && throw(
            ArgumentError(
                "lineageunits = :coalescenceage requires a coalescenceage accessor " *
                "but none was supplied",
            ),
        )
        return _validate_ultrametric(accessor, all_vertices, nonultrametric)
    else
        throw(
            ArgumentError(
                "unsupported lineageunits value: $(repr(lineageunits)); " *
                "rectangular_layout supports :vertexheights, :vertexlevels, " *
                ":edgelengths, :branchingtime, :vertexdepths, :coalescenceage, " *
                ":vertexcoords, :vertexpos",
            ),
        )
    end
end

# ── Internal: safe edge-length extraction ─────────────────────────────────────

"""
    _safe_edgelength(accessor, fromvertex, tovertex) -> Float64

Extract a non-negative `Float64` edge length from `accessor.edgelength`.

Handles all documented return forms of the `edgelength` accessor:

1. `NamedTuple` with a `:value` field — extracts `raw.value`; ignores other
   fields (e.g. `:units`). Unit conversion is not performed at the geometry layer.
2. `nothing` or `missing` — emits `@warn` identifying the edge and returns the
   fallback value `1.0`.
3. Negative `Float64` — raises `ArgumentError` identifying the edge and value.
4. Normal non-negative numeric — converts to `Float64` and returns.

# Throws
- `ArgumentError` if the resolved value is negative.
"""
function _safe_edgelength(
    accessor::LineageGraphAccessor,
    fromvertex,
    tovertex,
)::Float64
    raw = accessor.edgelength(fromvertex, tovertex)
    val = (raw isa NamedTuple && haskey(raw, :value)) ? raw.value : raw
    if val === nothing || ismissing(val)
        @warn "edgelength returned $(repr(val)) for edge $(repr(fromvertex)) → " *
              "$(repr(tovertex)); using fallback of 1.0"
        return 1.0
    end
    fval = Float64(val)
    fval < 0.0 && throw(
        ArgumentError(
            "edgelength returned negative value $(fval) for edge " *
            "$(repr(fromvertex)) → $(repr(tovertex)); edge lengths must be non-negative",
        ),
    )
    return fval
end

# ── Internal: shared preorder cumulative-sum traversal ────────────────────────

"""
    _cumulative_preorder(rootvertex, all_vertices, accessor, edge_increment) -> Dict{Any,Float64}

Preorder cumulative-sum traversal used by both `:edgelengths` and `:branchingtime`.

Seeds `rootvertex` at 0.0. For each vertex `v` in preorder order, sets each child
`c`'s coordinate to:

    coords[c] = coords[v] + edge_increment(v, c)

`edge_increment` is a callable `(fromvertex, tovertex) -> Float64` that returns
the additive increment for each directed edge:
- For `:edgelengths`: the edge length via `_safe_edgelength`.
- For `:branchingtime`: `branchingtime(c) - branchingtime(v)`, which yields
  `coords[c] = branchingtime(c)` — i.e., the accessor value is used directly.

The caller is responsible for ensuring that `edge_increment` returns non-negative
values where required.
"""
function _cumulative_preorder(
    rootvertex,
    all_vertices::Vector,
    accessor::LineageGraphAccessor,
    edge_increment,
)::Dict{Any,Float64}
    coords = Dict{Any,Float64}()
    coords[rootvertex] = 0.0
    for v in all_vertices
        cv = coords[v]
        for c in accessor.children(v)
            coords[c] = cv + edge_increment(v, c)
        end
    end
    return coords
end

# ── Internal: :vertexheights — postorder, leaf = 0, internal = max(children) + 1

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

# ── Internal: :vertexlevels — preorder, root = 0, each child = parent + 1

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

# ── Internal: :vertexdepths — preorder, root = 0, each child = parent + 1 ─────

"""
    _vertex_depths(rootvertex, all_vertices, accessor) -> Dict{Any,Float64}

Compute per-vertex integer edge-count depths from `rootvertex` in a preorder pass.

`rootvertex` is assigned depth 0. Each child's depth is its parent's depth plus 1.
The result is always integer-valued (stored as `Float64`).

This is distinct from `_vertexlevels` (which assigns equal inter-level spacing for
display) in that `_vertex_depths` records the raw edge count along the path from
`rootvertex` with no further transformation.
"""
function _vertex_depths(
    rootvertex,
    all_vertices::Vector,
    accessor::LineageGraphAccessor,
)::Dict{Any,Float64}
    depths = Dict{Any,Float64}()
    depths[rootvertex] = 0.0
    for v in all_vertices
        dv = depths[v]
        for c in accessor.children(v)
            depths[c] = dv + 1.0
        end
    end
    return depths
end

# ── Internal: :coalescenceage — validation and postorder resolution ────────────

"""
    _validate_ultrametric(accessor, all_vertices, nonultrametric) -> Dict{Any,Float64}

Validate the ultrametricity of accessor-supplied `coalescenceage` values and
return a `Dict` mapping each vertex to its process coordinate.

In a postorder traversal, for each internal vertex `v`, collects the
`coalescenceage` values of all its children from `accessor.coalescenceage`. For a
strictly ultrametric tree, all children of any given internal vertex share the
same coalescence age (since the implied edge lengths sum to the same total
distance from any child path to a leaf). If any two children of `v` disagree
beyond a floating-point tolerance of `1e-9`, the `nonultrametric` policy is
applied:

- `:error` (default) — raises `ArgumentError` naming the vertex and the
  conflicting minimum and maximum child values.
- `:minimum` — suppresses the error and accepts the inconsistency.
- `:maximum` — suppresses the error and accepts the inconsistency.

All vertex coordinates in the returned dict are `accessor.coalescenceage(v)` as
supplied. The `:minimum` and `:maximum` policies do not modify the accessor-supplied
values; they only suppress the error, allowing the caller to accept a
non-ultrametric set of coordinates.

# Throws
- `ArgumentError` if `nonultrametric = :error` and any internal vertex has
  children with inconsistent coalescenceage values.
"""
function _validate_ultrametric(
    accessor::LineageGraphAccessor,
    all_vertices::Vector,
    nonultrametric::Symbol,
)::Dict{Any,Float64}
    coords = Dict{Any,Float64}()
    for v in Iterators.reverse(all_vertices)  # postorder: children before parents
        coords[v] = accessor.coalescenceage(v)
        ch = accessor.children(v)
        isempty(ch) && continue
        child_ages = [accessor.coalescenceage(c) for c in ch]
        mn = minimum(child_ages)
        mx = maximum(child_ages)
        if mx - mn > 1e-9
            if nonultrametric === :error
                throw(
                    ArgumentError(
                        "non-ultrametric lineage graph: children of vertex $(repr(v)) " *
                        "have inconsistent coalescenceage values " *
                        "(min=$(mn), max=$(mx)); pass nonultrametric = :minimum or " *
                        ":maximum to rectangular_layout to resolve",
                    ),
                )
            end
            # :minimum or :maximum: inconsistency silently accepted.
        end
    end
    return coords
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

# Each edge produces three points forming a right-angle shape, plus a NaN
# separator. For an edge fromvertex → tovertex with coordinates (xp, yp)
# and (xc, yc):
#   (xp, yp) → (xp, yc) → (xc, yc) → (NaN, NaN)
# The first segment is parallel to the transverse axis (changes y at fixed x).
# The second segment is parallel to the lineage axis (changes x at fixed y).
function _build_edge_shapes(
    all_vertices::Vector,
    accessor::LineageGraphAccessor,
    process_coords::Dict{Any,Float64},
    transverse_coords::Dict{Any,Float64},
)::Vector{Point2f}
    shapes = Point2f[]
    for v in all_vertices
        xp = process_coords[v]
        yp = transverse_coords[v]
        for c in accessor.children(v)
            xc = process_coords[c]
            yc = transverse_coords[c]
            push!(shapes,
                Point2f(xp, yp),
                Point2f(xp, yc),
                Point2f(xc, yc),
                Point2f(NaN, NaN),
            )
        end
    end
    return shapes
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

# ── circular_layout ────────────────────────────────────────────────────────────

"""
    circular_layout(rootvertex, accessor::LineageGraphAccessor;
                    leaf_spacing=:equal,
                    lineageunits::Union{Nothing,Symbol}=nothing,
                    nonultrametric::Symbol=:error,
                    circular_edge_style::Symbol=:chord,
                    min_leaf_angle::Union{Nothing,Float64}=nothing) -> LineageGraphGeometry

Compute a circular (radial) layout for a rooted lineage graph.

Process coordinates (radial distances from the origin) are determined by `lineageunits`
using the same rules as `rectangular_layout`. Leaves are placed at equal angular
spacing by default; internal vertices are placed at the mean angle of their children.

**Angular leaf placement:** with `leaf_spacing = :equal` the angular step is
`2π / n_leaves`. A positive `Float64` `leaf_spacing` sets an explicit angular step
in radians. The `min_leaf_angle` keyword sets a lower bound on the step: if the
computed step is smaller, a warning is emitted and `min_leaf_angle` is used instead,
causing the layout to span less than a full circle. The default (`nothing`) applies
no floor.

**Edge style:** only `:chord` is implemented for Tier 1. For each edge the path is a
chord segment at the parent's radial distance spanning the child's angular position,
followed by a radial segment from that connector point to the child's position. The
`:arc` style (Tier 2) is not implemented.

**Bypass modes:** `lineageunits = :vertexcoords` and `:vertexpos` use the accessor
coordinates directly, bypassing angular computation (same as `rectangular_layout`).

# Arguments
- `rootvertex`: root of the lineage graph.
- `accessor::LineageGraphAccessor`: supplies the `children` callable and optional
  accessor fields.
- `leaf_spacing`: `:equal` (default) or a positive `Float64` angular step in radians.
- `lineageunits::Union{Nothing,Symbol}`: see `rectangular_layout` for all values.
- `nonultrametric::Symbol`: policy for non-ultrametric inputs; see `rectangular_layout`.
- `circular_edge_style::Symbol`: `:chord` (default, Tier 1 only).
- `min_leaf_angle::Union{Nothing,Float64}`: minimum angular step; `nothing` means no
  floor. Documented decision (PRD Open Q3): the default is `nothing` (no forced floor)
  so that small trees use exactly equal spacing; users with very large trees may supply
  a floor such as `2π/360` (one degree) to prevent illegibly dense layouts.

# Returns
A `LineageGraphGeometry` with `vertex_positions` storing Cartesian `(x, y)` from
polar coordinates, `edge_shapes` using the chord representation, `leaf_order` in
preorder traversal order, and `boundingbox` enclosing all vertex positions.

# Throws
- `ArgumentError` if the lineage graph has zero leaves.
- `ArgumentError` if `leaf_spacing` is a non-positive real number.
- `ArgumentError` if a required accessor is `nothing` for the chosen `lineageunits`.
- `ArgumentError` if `lineageunits` is not a supported value.
- `ArgumentError` if `circular_edge_style` is not `:chord`.
- `ArgumentError` if `lineageunits = :edgelengths` and any edge length is negative.
- `ArgumentError` if `lineageunits = :coalescenceage`, the tree is non-ultrametric,
  and `nonultrametric = :error`.
"""
function circular_layout(
    rootvertex,
    accessor::LineageGraphAccessor;
    leaf_spacing = :equal,
    lineageunits::Union{Nothing,Symbol} = nothing,
    nonultrametric::Symbol = :error,
    circular_edge_style::Symbol = :chord,
    min_leaf_angle::Union{Nothing,Float64} = nothing,
)::LineageGraphGeometry
    circular_edge_style === :chord || throw(
        ArgumentError(
            "unsupported circular_edge_style: $(repr(circular_edge_style)); " *
            "circular_layout supports :chord (Tier 1); :arc is Tier 2 and not yet implemented",
        ),
    )

    lineageunits = _resolve_lineageunits(lineageunits, accessor)

    leaf_list = leaves(accessor, rootvertex)
    isempty(leaf_list) && throw(
        ArgumentError(
            "lineage graph rooted at $(repr(rootvertex)) has zero leaves; " *
            "a layout requires at least one leaf",
        ),
    )

    all_vertices = preorder(accessor, rootvertex)

    # Bypass modes: both coordinates come from the accessor; no angular computation.
    if lineageunits === :vertexcoords || lineageunits === :vertexpos
        accessor_fn = lineageunits === :vertexcoords ? accessor.vertexcoords : accessor.vertexpos
        accessor_fn === nothing && throw(
            ArgumentError(
                "lineageunits = $(repr(lineageunits)) requires a $(lineageunits) accessor " *
                "but none was supplied",
            ),
        )
        vertex_positions = Dict{Any,Point2f}(v => Point2f(accessor_fn(v)) for v in all_vertices)
        pc = Dict{Any,Float64}(v => Float64(vertex_positions[v][1]) for v in all_vertices)
        tc = Dict{Any,Float64}(v => Float64(vertex_positions[v][2]) for v in all_vertices)
        edge_shapes = _build_edge_shapes(all_vertices, accessor, pc, tc)
        bb = _compute_boundingbox(vertex_positions)
        return LineageGraphGeometry(vertex_positions, edge_shapes, leaf_list, bb)
    end

    process_coords = _process_coords(rootvertex, accessor, lineageunits, all_vertices, nonultrametric)

    θ_step = _angular_leaf_step(leaf_spacing, length(leaf_list), min_leaf_angle)
    angles = _angular_positions(leaf_list, all_vertices, accessor, θ_step)

    vertex_positions = Dict{Any,Point2f}()
    for v in all_vertices
        r = process_coords[v]
        θ = angles[v]
        vertex_positions[v] = Point2f(r * cos(θ), r * sin(θ))
    end

    edge_shapes = _build_circular_edge_shapes(all_vertices, accessor, process_coords, angles)
    bb = _compute_boundingbox(vertex_positions)

    return LineageGraphGeometry(vertex_positions, edge_shapes, leaf_list, bb)
end

# ── Internal: angular leaf step computation ────────────────────────────────────

"""
    _angular_leaf_step(leaf_spacing, n_leaves, min_leaf_angle) -> Float64

Compute the angular spacing in radians between adjacent leaves for a circular layout.

For `leaf_spacing = :equal` the step is `2π / n_leaves` (a single leaf gets `2π`).
For a positive `Float64` `leaf_spacing` the value is used directly as the angular step.
When `min_leaf_angle` is not `nothing` and the computed step is smaller, a warning is
emitted and `min_leaf_angle` is used, causing the layout to span less than a full circle.
"""
function _angular_leaf_step(
    leaf_spacing,
    n_leaves::Int,
    min_leaf_angle::Union{Nothing,Float64},
)::Float64
    θ_step = if leaf_spacing === :equal
        n_leaves > 1 ? 2π / n_leaves : 2π
    elseif leaf_spacing isa Real
        leaf_spacing > 0 || throw(
            ArgumentError(
                "leaf_spacing must be a positive real number; got $(leaf_spacing)",
            ),
        )
        Float64(leaf_spacing)
    else
        throw(
            ArgumentError(
                "leaf_spacing must be :equal or a positive real number; " *
                "got $(repr(leaf_spacing)) ($(typeof(leaf_spacing)))",
            ),
        )
    end
    if min_leaf_angle !== nothing && θ_step < min_leaf_angle
        @warn "computed angular leaf spacing $(θ_step) rad is smaller than " *
              "min_leaf_angle=$(min_leaf_angle) rad; using min_leaf_angle instead — " *
              "the layout will span less than a full circle"
        θ_step = min_leaf_angle
    end
    return θ_step
end

# ── Internal: angular position assignment ─────────────────────────────────────

"""
    _angular_positions(leaf_list, all_vertices, accessor, θ_step) -> Dict{Any,Float64}

Assign an angular position (radians) to every vertex.

Leaves receive evenly spaced angles starting at 0: `θ_i = (i-1) * θ_step` for the
i-th leaf in `leaf_list` (1-indexed). Internal vertices receive the mean of their
children's angles, computed in reverse-preorder so children are assigned before
their parents.
"""
function _angular_positions(
    leaf_list::Vector,
    all_vertices::Vector,
    accessor::LineageGraphAccessor,
    θ_step::Float64,
)::Dict{Any,Float64}
    angles = Dict{Any,Float64}()
    for (i, leaf) in enumerate(leaf_list)
        angles[leaf] = (i - 1) * θ_step
    end
    for v in Iterators.reverse(all_vertices)
        haskey(angles, v) && continue
        n = 0
        s = 0.0
        for c in accessor.children(v)
            n += 1
            s += angles[c]
        end
        angles[v] = s / n
    end
    return angles
end

# ── Internal: circular chord edge shape construction ──────────────────────────

"""
    _build_circular_edge_shapes(all_vertices, accessor, process_coords, angles) -> Vector{Point2f}

Build the chord-style edge shape vector for a circular layout.

For each directed edge `fromvertex → tovertex` the path consists of three Cartesian
points followed by a `Point2f(NaN, NaN)` separator (four points total per edge),
matching the convention used by `_build_edge_shapes` for rectangular layouts:

1. Parent Cartesian: `(r_from * cos(θ_from), r_from * sin(θ_from))`
2. Chord connector: `(r_from * cos(θ_to), r_from * sin(θ_to))` — at parent radius,
   child angle
3. Child Cartesian: `(r_to * cos(θ_to), r_to * sin(θ_to))`
4. `Point2f(NaN, NaN)` separator
"""
function _build_circular_edge_shapes(
    all_vertices::Vector,
    accessor::LineageGraphAccessor,
    process_coords::Dict{Any,Float64},
    angles::Dict{Any,Float64},
)::Vector{Point2f}
    shapes = Point2f[]
    for v in all_vertices
        r_v = process_coords[v]
        θ_v = angles[v]
        x_v = r_v * cos(θ_v)
        y_v = r_v * sin(θ_v)
        for c in accessor.children(v)
            r_c = process_coords[c]
            θ_c = angles[c]
            x_conn = r_v * cos(θ_c)
            y_conn = r_v * sin(θ_c)
            x_c = r_c * cos(θ_c)
            y_c = r_c * sin(θ_c)
            push!(shapes,
                Point2f(x_v, y_v),
                Point2f(x_conn, y_conn),
                Point2f(x_c, y_c),
                Point2f(NaN, NaN),
            )
        end
    end
    return shapes
end

# ── Exports ────────────────────────────────────────────────────────────────────

export LineageGraphGeometry, boundingbox, rectangular_layout, circular_layout

end # module Geometry
