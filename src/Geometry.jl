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
    LineageGraphGeometry{NodeT}

Immutable struct holding the computed 2D layout of a lineage graph.

`NodeT` is the node identity type. In generic use `NodeT` is `Any`; callers that
work with a uniform node type may instantiate a more specific `NodeT` for
better type-inference downstream.

Coordinate convention: the first component of each `Point2f` is the process
coordinate (primary lineage axis); the second is the transverse coordinate
(leaf-spacing axis). In a left-to-right rectangular layout the process
coordinate is on the x-axis and the transverse coordinate is on the y-axis.

Fields:
- `node_positions::Dict{NodeT,Point2f}`: maps each node to its `Point2f` position.
- `edge_shapes::Vector{Point2f}`: all edge polylines concatenated into a single
  vector with `Point2f(NaN, NaN)` separators between shapes. Each edge occupies
  exactly 4 entries (3 geometry points + 1 NaN separator). Suitable for a single
  `lines!` call.
- `edges::Vector{Tuple{NodeT,NodeT}}`: `(src, dst)` pairs in the same
  traversal order as `edge_shapes`. `edges[i]` corresponds to the i-th
  NaN-terminated group of 4 points in `edge_shapes`. Used by rendering layers
  to expand per-edge attribute functions without re-traversing the source tree.
- `leaf_order::Vector{NodeT}`: leaves in the order they appear along the transverse
  axis (preorder depth-first traversal order).
- `boundingbox::Rect2f`: smallest axis-aligned rectangle enclosing all entries
  in `node_positions`.
"""
struct LineageGraphGeometry{NodeT}
    node_positions::Dict{NodeT, Point2f}
    edge_shapes::Vector{Point2f}
    edges::Vector{Tuple{NodeT, NodeT}}
    leaf_order::Vector{NodeT}
    boundingbox::Rect2f
end

# ── boundingbox ────────────────────────────────────────────────────────────────

"""
    boundingbox(geom::LineageGraphGeometry) -> Rect2f

Return the smallest axis-aligned rectangle enclosing all `node_positions`
in `geom`. The value is computed at layout time and returned directly.
"""
function boundingbox(geom::LineageGraphGeometry)::Rect2f
    return geom.boundingbox
end

# ── rectangular_layout ─────────────────────────────────────────────────────────

"""
    rectangular_layout(basenode, accessor::LineageGraphAccessor;
                       leaf_spacing=:equal,
                       lineageunits::Union{Nothing,Symbol}=nothing,
                       nonultrametric::Symbol=:error) -> LineageGraphGeometry

Compute a rectangular (right-angle) layout for a rooted lineage graph.

Process coordinates (first `Point2f` component) are determined by `lineageunits`:

- `:edgeweights` — cumulative `edgeweight(src, dst)` from
  `basenode`; requires `edgeweight` accessor; `basenode` = 0, increases
  toward leaves. Missing edge weights emit `@warn` and fall back to 1.0;
  negative edge weights raise `ArgumentError`.
- `:branchingtime` — per-node branching time read directly from
  `branchingtime(node)`; requires `branchingtime` accessor; `basenode` = 0.
- `:coalescenceage` — per-node coalescence age read from
  `coalescenceage(node)`; requires `coalescenceage` accessor; leaves = 0,
  increases toward the basenode. Non-ultrametric inputs are controlled by `nonultrametric`.
- `:nodedepths` — integer edge count from `basenode`; `basenode` = 0,
  increases by 1 per edge. No accessor required.
- `:nodeheights` — per-node height: edge count to the farthest descendant
  leaf. Leaves = 0, basenode = maximum. No accessor required.
- `:nodelevels` — edge count from `basenode`: basenode = 0, leaves = maximum.
  Equal inter-level spacing. No accessor required.
- `:nodecoordinates` — user-supplied `Point2f` data coordinates read from
  `nodecoordinates(node)`; requires `nodecoordinates` accessor. Bypasses layout
  computation entirely; both process and transverse coordinates come from the
  accessor.
- `:nodepos` — user-supplied `Point2f` pixel coordinates read from
  `nodepos(node)`; requires `nodepos` accessor. Same geometry-layer
  behaviour as `:nodecoordinates`; the semantic distinction (data vs pixel space)
  is documented here but not enforced at the geometry layer.

**Default detection:** if `lineageunits` is not supplied (or `nothing`), the
default is `:edgeweights` when an `edgeweight` accessor is present; otherwise
`:nodeheights`.

Transverse coordinates (second `Point2f` component) place leaves at equal
intervals by default (`leaf_spacing = :equal`). The `leaf_order` field records
the leaf sequence.

Each edge `src → dst` contributes a right-angle polyline:
  `(x_src, y_src) → (x_src, y_dst) → (x_dst, y_dst)`
followed by a `Point2f(NaN, NaN)` separator.

# Arguments
- `basenode`: basenode of the lineage graph; first positional argument.
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
- `ArgumentError` if `lineageunits = :edgeweights` and any edge weight is negative.
- `ArgumentError` if `lineageunits = :coalescenceage`, the tree is non-ultrametric,
  and `nonultrametric = :error`.
"""
function rectangular_layout(
        basenode,
        accessor::LineageGraphAccessor;
        leaf_spacing = :equal,
        lineageunits::Union{Nothing, Symbol} = nothing,
        nonultrametric::Symbol = :error,
    )::LineageGraphGeometry
    lineageunits = _resolve_lineageunits(lineageunits, accessor)
    step = _validate_leaf_spacing(leaf_spacing)

    leaf_list = leaves(accessor, basenode)
    isempty(leaf_list) && throw(
        ArgumentError(
            "lineage graph with basenode $(repr(basenode)) has zero leaves; " *
                "a layout requires at least one leaf",
        ),
    )

    all_nodes = preorder(accessor, basenode)

    # Bypass modes: both process and transverse coordinates come from the accessor.
    if lineageunits === :nodecoordinates || lineageunits === :nodepos
        accessor_fn = lineageunits === :nodecoordinates ? accessor.nodecoordinates : accessor.nodepos
        accessor_fn === nothing && throw(
            ArgumentError(
                "lineageunits = $(repr(lineageunits)) requires a $(lineageunits) accessor " *
                    "but none was supplied",
            ),
        )
        node_positions = Dict{Any, Point2f}(node => Point2f(accessor_fn(node)) for node in all_nodes)
        pc = Dict{Any, Float64}(node => Float64(node_positions[node][1]) for node in all_nodes)
        tc = Dict{Any, Float64}(node => Float64(node_positions[node][2]) for node in all_nodes)
        edge_shapes = _build_edge_shapes(all_nodes, accessor, pc, tc)
        edges = _build_edge_list(all_nodes, accessor)
        bb = _compute_boundingbox(node_positions)
        return LineageGraphGeometry(node_positions, edge_shapes, edges, leaf_list, bb)
    end

    process_coordinates = _process_coordinates(basenode, accessor, lineageunits, all_nodes, nonultrametric)
    transverse_coordinates = _assign_transverse(leaf_list, accessor, all_nodes, step)

    node_positions = _build_node_positions(all_nodes, process_coordinates, transverse_coordinates)
    edge_shapes = _build_edge_shapes(all_nodes, accessor, process_coordinates, transverse_coordinates)
    edges = _build_edge_list(all_nodes, accessor)
    bb = _compute_boundingbox(node_positions)

    return LineageGraphGeometry(node_positions, edge_shapes, edges, leaf_list, bb)
end

# ── Internal: default lineageunits detection ───────────────────────────────────

"""
    _resolve_lineageunits(lineageunits, accessor) -> Symbol

Resolve the `lineageunits` sentinel `nothing` to the appropriate default.

If `lineageunits` is not `nothing`, it is returned unchanged. Otherwise:
- `:edgeweights` if `accessor.edgeweight` is not `nothing`.
- `:nodeheights` otherwise.
"""
function _resolve_lineageunits(
        lineageunits::Union{Nothing, Symbol},
        accessor::LineageGraphAccessor,
    )::Symbol
    lineageunits !== nothing && return lineageunits
    return accessor.edgeweight !== nothing ? :edgeweights : :nodeheights
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

function _process_coordinates(
        basenode,
        accessor::LineageGraphAccessor,
        lineageunits::Symbol,
        all_nodes::Vector,
        nonultrametric::Symbol,
    )::Dict{Any, Float64}
    if lineageunits === :nodeheights
        return _nodeheights(all_nodes, accessor)
    elseif lineageunits === :nodelevels
        return _nodelevels(basenode, all_nodes, accessor)
    elseif lineageunits === :edgeweights
        accessor.edgeweight === nothing && throw(
            ArgumentError(
                "lineageunits = :edgeweights requires an edgeweight accessor " *
                    "but none was supplied",
            ),
        )
        return _cumulative_preorder(
            basenode,
            all_nodes,
            accessor,
            (src, dst) -> _safe_edgeweight(accessor, src, dst),
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
            basenode,
            all_nodes,
            accessor,
            (src, dst) -> bt(dst) - bt(src),
        )
    elseif lineageunits === :nodedepths
        return _node_depths(basenode, all_nodes, accessor)
    elseif lineageunits === :coalescenceage
        accessor.coalescenceage === nothing && throw(
            ArgumentError(
                "lineageunits = :coalescenceage requires a coalescenceage accessor " *
                    "but none was supplied",
            ),
        )
        return _validate_ultrametric(accessor, all_nodes, nonultrametric)
    else
        throw(
            ArgumentError(
                "unsupported lineageunits value: $(repr(lineageunits)); " *
                    "rectangular_layout supports :nodeheights, :nodelevels, " *
                    ":edgeweights, :branchingtime, :nodedepths, :coalescenceage, " *
                    ":nodecoordinates, :nodepos",
            ),
        )
    end
end

# ── Internal: safe edge-length extraction ─────────────────────────────────────

"""
    _safe_edgeweight(accessor, src, dst) -> Float64

Extract a non-negative `Float64` edge weight from `accessor.edgeweight`.

Handles all documented return forms of the `edgeweight` accessor:

1. `NamedTuple` with a `:value` field — extracts `raw.value`; ignores other
   fields (e.g. `:units`). Unit conversion is not performed at the geometry layer.
2. `nothing` or `missing` — emits `@warn` identifying the edge and returns the
   fallback value `1.0`.
3. Negative `Float64` — raises `ArgumentError` identifying the edge and value.
4. Normal non-negative numeric — converts to `Float64` and returns.

# Throws
- `ArgumentError` if the resolved value is negative.
"""
function _safe_edgeweight(
        accessor::LineageGraphAccessor,
        src,
        dst,
    )::Float64
    raw = accessor.edgeweight(src, dst)
    val = (raw isa NamedTuple && haskey(raw, :value)) ? raw.value : raw
    if val === nothing || ismissing(val)
        @warn "edgeweight returned $(repr(val)) for edge $(repr(src)) → " *
            "$(repr(dst)); using fallback of 1.0"
        return 1.0
    end
    fval = Float64(val)
    fval < 0.0 && throw(
        ArgumentError(
            "edgeweight returned negative value $(fval) for edge " *
                "$(repr(src)) → $(repr(dst)); edge weights must be non-negative",
        ),
    )
    return fval
end

# ── Internal: shared preorder cumulative-sum traversal ────────────────────────

"""
    _cumulative_preorder(basenode, all_nodes, accessor, edge_increment) -> Dict{Any,Float64}

Preorder cumulative-sum traversal used by both `:edgeweights` and `:branchingtime`.

Seeds `basenode` at 0.0. For each node in preorder order, sets each child's
coordinate to:

    coordinates[child] = coordinates[node] + edge_increment(node, child)

`edge_increment` is a callable `(src, dst) -> Float64` that returns
the additive increment for each directed edge:
- For `:edgeweights`: the edge weight via `_safe_edgeweight`.
- For `:branchingtime`: `branchingtime(dst) - branchingtime(src)`, which yields
  `coordinates[dst] = branchingtime(dst)` — i.e., the accessor value is used directly.

The caller is responsible for ensuring that `edge_increment` returns non-negative
values where required.
"""
function _cumulative_preorder(
        basenode,
        all_nodes::Vector,
        accessor::LineageGraphAccessor,
        edge_increment,
    )::Dict{Any, Float64}
    coordinates = Dict{Any, Float64}()
    coordinates[basenode] = 0.0
    for node in all_nodes
        coordinate = coordinates[node]
        for child in accessor.children(node)
            coordinates[child] = coordinate + edge_increment(node, child)
        end
    end
    return coordinates
end

# ── Internal: :nodeheights — postorder, leaf = 0, internal = max(children) + 1

function _nodeheights(all_nodes::Vector, accessor::LineageGraphAccessor)::Dict{Any, Float64}
    heights = Dict{Any, Float64}()
    # Reversing a preorder traversal yields a valid postorder (children before
    # parents), because in preorder every parent precedes all its descendants.
    for node in Iterators.reverse(all_nodes)
        child_collection = accessor.children(node)
        if isempty(child_collection)
            heights[node] = 0.0
        else
            heights[node] = maximum(heights[child] for child in child_collection) + 1.0
        end
    end
    return heights
end

# ── Internal: :nodelevels — preorder, basenode = 0, each child = parent + 1

function _nodelevels(
        basenode,
        all_nodes::Vector,
        accessor::LineageGraphAccessor,
    )::Dict{Any, Float64}
    levels = Dict{Any, Float64}()
    levels[basenode] = 0.0
    for node in all_nodes
        level = levels[node]
        for child in accessor.children(node)
            levels[child] = level + 1.0
        end
    end
    return levels
end

# ── Internal: :nodedepths — preorder, basenode = 0, each child = parent + 1 ───────

"""
    _node_depths(basenode, all_nodes, accessor) -> Dict{Any,Float64}

Compute per-node integer edge-count depths from `basenode` in a preorder pass.

`basenode` is assigned depth 0. Each child's depth is its parent's depth plus 1.
The result is always integer-valued (stored as `Float64`).

This is distinct from `_nodelevels` (which assigns equal inter-level spacing for
display) in that `_node_depths` records the raw edge count along the path from
`basenode` with no further transformation.
"""
function _node_depths(
        basenode,
        all_nodes::Vector,
        accessor::LineageGraphAccessor,
    )::Dict{Any, Float64}
    depths = Dict{Any, Float64}()
    depths[basenode] = 0.0
    for node in all_nodes
        depth = depths[node]
        for child in accessor.children(node)
            depths[child] = depth + 1.0
        end
    end
    return depths
end

# ── Internal: :coalescenceage — validation and postorder resolution ────────────

"""
    _validate_ultrametric(accessor, all_nodes, nonultrametric) -> Dict{Any,Float64}

Validate the ultrametricity of accessor-supplied `coalescenceage` values and
return a `Dict` mapping each node to its process coordinate.

In a postorder traversal, for each internal node, collects the
`coalescenceage` values of all its children from `accessor.coalescenceage`. For a
strictly ultrametric tree, all children of any given internal node share the
same coalescence age (since the implied edge weights sum to the same total
distance from any child path to a leaf). If any two children disagree
beyond a floating-point tolerance of `1e-9`, the `nonultrametric` policy is
applied:

- `:error` (default) — raises `ArgumentError` naming the node and the
  conflicting minimum and maximum child values.
- `:minimum` — suppresses the error and accepts the inconsistency.
- `:maximum` — suppresses the error and accepts the inconsistency.

All node coordinates in the returned dict are `accessor.coalescenceage(node)` as
supplied. The `:minimum` and `:maximum` policies do not modify the accessor-supplied
values; they only suppress the error, allowing the caller to accept a
non-ultrametric set of coordinates.

# Throws
- `ArgumentError` if `nonultrametric = :error` and any internal node has
  children with inconsistent coalescenceage values.
"""
function _validate_ultrametric(
        accessor::LineageGraphAccessor,
        all_nodes::Vector,
        nonultrametric::Symbol,
    )::Dict{Any, Float64}
    coordinates = Dict{Any, Float64}()
    for node in Iterators.reverse(all_nodes)  # postorder: children before parents
        coordinates[node] = accessor.coalescenceage(node)
        child_collection = accessor.children(node)
        isempty(child_collection) && continue
        child_ages = [accessor.coalescenceage(child) for child in child_collection]
        mn = minimum(child_ages)
        mx = maximum(child_ages)
        if mx - mn > 1.0e-9
            if nonultrametric === :error
                throw(
                    ArgumentError(
                        "non-ultrametric lineage graph: children of node $(repr(node)) " *
                            "have inconsistent coalescenceage values " *
                            "(min=$(mn), max=$(mx)); pass nonultrametric = :minimum or " *
                            ":maximum to rectangular_layout to resolve",
                    ),
                )
            end
            # :minimum or :maximum: inconsistency silently accepted.
        end
    end
    return coordinates
end

# ── Internal: transverse coordinate assignment ─────────────────────────────────

# Leaves get equally spaced transverse positions (1*step, 2*step, …).
# Internal nodes are placed at the mean of their children's transverse
# positions. Reverse preorder (≈ postorder) ensures children are assigned
# before their parents.
function _assign_transverse(
        leaf_list::Vector,
        accessor::LineageGraphAccessor,
        all_nodes::Vector,
        step::Float64,
    )::Dict{Any, Float64}
    transverse = Dict{Any, Float64}()
    for (i, leaf) in enumerate(leaf_list)
        transverse[leaf] = i * step
    end
    for node in Iterators.reverse(all_nodes)
        haskey(transverse, node) && continue
        n_children = 0
        transverse_sum = 0.0
        for child in accessor.children(node)
            n_children += 1
            transverse_sum += transverse[child]
        end
        transverse[node] = transverse_sum / n_children
    end
    return transverse
end

# ── Internal: geometry assembly ────────────────────────────────────────────────

# Build the ordered list of (src, dst) pairs.
# Iterates all_nodes in preorder and loops over accessor.children(node) in the
# same inner order as _build_edge_shapes, so edges[i] corresponds to the i-th
# NaN-terminated group of 4 points in edge_shapes.
function _build_edge_list(
        all_nodes::Vector,
        accessor::LineageGraphAccessor,
    )::Vector{Tuple{Any, Any}}
    edges = Tuple{Any, Any}[]
    for node in all_nodes
        for child in accessor.children(node)
            push!(edges, (node, child))
        end
    end
    return edges
end

function _build_node_positions(
        all_nodes::Vector,
        process_coordinates::Dict{Any, Float64},
        transverse_coordinates::Dict{Any, Float64},
    )::Dict{Any, Point2f}
    pos = Dict{Any, Point2f}()
    for node in all_nodes
        pos[node] = Point2f(process_coordinates[node], transverse_coordinates[node])
    end
    return pos
end

# Each edge produces three points forming a right-angle shape, plus a NaN
# separator. For an edge src → dst with coordinates (xp, yp) and (xc, yc):
#   (xp, yp) → (xp, yc) → (xc, yc) → (NaN, NaN)
# The first segment is parallel to the transverse axis (changes y at fixed x).
# The second segment is parallel to the lineage axis (changes x at fixed y).
function _build_edge_shapes(
        all_nodes::Vector,
        accessor::LineageGraphAccessor,
        process_coordinates::Dict{Any, Float64},
        transverse_coordinates::Dict{Any, Float64},
    )::Vector{Point2f}
    shapes = Point2f[]
    for node in all_nodes
        xp = process_coordinates[node]
        yp = transverse_coordinates[node]
        for child in accessor.children(node)
            xc = process_coordinates[child]
            yc = transverse_coordinates[child]
            push!(
                shapes,
                Point2f(xp, yp),
                Point2f(xp, yc),
                Point2f(xc, yc),
                Point2f(NaN, NaN),
            )
        end
    end
    return shapes
end

function _compute_boundingbox(node_positions::Dict{Any, Point2f})::Rect2f
    isempty(node_positions) && return Rect2f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    first_p = first(values(node_positions))
    xmin = xmax = first_p[1]
    ymin = ymax = first_p[2]
    for p in values(node_positions)
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
    circular_layout(basenode, accessor::LineageGraphAccessor;
                    leaf_spacing=:equal,
                    lineageunits::Union{Nothing,Symbol}=nothing,
                    nonultrametric::Symbol=:error,
                    circular_edge_style::Symbol=:chord,
                    min_leaf_angle::Union{Nothing,Float64}=nothing) -> LineageGraphGeometry

Compute a circular (radial) layout for a rooted lineage graph.

Process coordinates (radial distances from the origin) are determined by `lineageunits`
using the same rules as `rectangular_layout`. Leaves are placed at equal angular
spacing by default; internal nodes are placed at the mean angle of their children.

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

**Bypass modes:** `lineageunits = :nodecoordinates` and `:nodepos` use the accessor
coordinates directly, bypassing angular computation (same as `rectangular_layout`).

# Arguments
- `basenode`: basenode of the lineage graph.
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
A `LineageGraphGeometry` with `node_positions` storing Cartesian `(x, y)` from
polar coordinates, `edge_shapes` using the chord representation, `leaf_order` in
preorder traversal order, and `boundingbox` enclosing all node positions.

# Throws
- `ArgumentError` if the lineage graph has zero leaves.
- `ArgumentError` if `leaf_spacing` is a non-positive real number.
- `ArgumentError` if a required accessor is `nothing` for the chosen `lineageunits`.
- `ArgumentError` if `lineageunits` is not a supported value.
- `ArgumentError` if `circular_edge_style` is not `:chord`.
- `ArgumentError` if `lineageunits = :edgeweights` and any edge weight is negative.
- `ArgumentError` if `lineageunits = :coalescenceage`, the tree is non-ultrametric,
  and `nonultrametric = :error`.
"""
function circular_layout(
        basenode,
        accessor::LineageGraphAccessor;
        leaf_spacing = :equal,
        lineageunits::Union{Nothing, Symbol} = nothing,
        nonultrametric::Symbol = :error,
        circular_edge_style::Symbol = :chord,
        min_leaf_angle::Union{Nothing, Float64} = nothing,
    )::LineageGraphGeometry
    circular_edge_style === :chord || throw(
        ArgumentError(
            "unsupported circular_edge_style: $(repr(circular_edge_style)); " *
                "circular_layout supports :chord (Tier 1); :arc is Tier 2 and not yet implemented",
        ),
    )

    lineageunits = _resolve_lineageunits(lineageunits, accessor)

    leaf_list = leaves(accessor, basenode)
    isempty(leaf_list) && throw(
        ArgumentError(
            "lineage graph with basenode $(repr(basenode)) has zero leaves; " *
                "a layout requires at least one leaf",
        ),
    )

    all_nodes = preorder(accessor, basenode)

    # Bypass modes: both coordinates come from the accessor; no angular computation.
    if lineageunits === :nodecoordinates || lineageunits === :nodepos
        accessor_fn = lineageunits === :nodecoordinates ? accessor.nodecoordinates : accessor.nodepos
        accessor_fn === nothing && throw(
            ArgumentError(
                "lineageunits = $(repr(lineageunits)) requires a $(lineageunits) accessor " *
                    "but none was supplied",
            ),
        )
        node_positions = Dict{Any, Point2f}(node => Point2f(accessor_fn(node)) for node in all_nodes)
        pc = Dict{Any, Float64}(node => Float64(node_positions[node][1]) for node in all_nodes)
        tc = Dict{Any, Float64}(node => Float64(node_positions[node][2]) for node in all_nodes)
        edge_shapes = _build_edge_shapes(all_nodes, accessor, pc, tc)
        edges = _build_edge_list(all_nodes, accessor)
        bb = _compute_boundingbox(node_positions)
        return LineageGraphGeometry(node_positions, edge_shapes, edges, leaf_list, bb)
    end

    process_coordinates = _process_coordinates(basenode, accessor, lineageunits, all_nodes, nonultrametric)

    θ_step = _angular_leaf_step(leaf_spacing, length(leaf_list), min_leaf_angle)
    angles = _angular_positions(leaf_list, all_nodes, accessor, θ_step)

    node_positions = Dict{Any, Point2f}()
    for node in all_nodes
        r = process_coordinates[node]
        θ = angles[node]
        node_positions[node] = Point2f(r * cos(θ), r * sin(θ))
    end

    edge_shapes = _build_circular_edge_shapes(all_nodes, accessor, process_coordinates, angles)
    edges = _build_edge_list(all_nodes, accessor)
    bb = _compute_boundingbox(node_positions)

    return LineageGraphGeometry(node_positions, edge_shapes, edges, leaf_list, bb)
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
        min_leaf_angle::Union{Nothing, Float64},
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
    _angular_positions(leaf_list, all_nodes, accessor, θ_step) -> Dict{Any,Float64}

Assign an angular position (radians) to every node.

Leaves receive evenly spaced angles starting at 0: `θ_i = (i-1) * θ_step` for the
i-th leaf in `leaf_list` (1-indexed). Internal nodes receive the mean of their
children's angles, computed in reverse-preorder so children are assigned before
their parents.
"""
function _angular_positions(
        leaf_list::Vector,
        all_nodes::Vector,
        accessor::LineageGraphAccessor,
        θ_step::Float64,
    )::Dict{Any, Float64}
    angles = Dict{Any, Float64}()
    for (i, leaf) in enumerate(leaf_list)
        angles[leaf] = (i - 1) * θ_step
    end
    for node in Iterators.reverse(all_nodes)
        haskey(angles, node) && continue
        n_children = 0
        angle_sum = 0.0
        for child in accessor.children(node)
            n_children += 1
            angle_sum += angles[child]
        end
        angles[node] = angle_sum / n_children
    end
    return angles
end

# ── Internal: circular chord edge shape construction ──────────────────────────

"""
    _build_circular_edge_shapes(all_nodes, accessor, process_coordinates, angles) -> Vector{Point2f}

Build the chord-style edge shape vector for a circular layout.

For each directed edge `src → dst` the path consists of three Cartesian
points followed by a `Point2f(NaN, NaN)` separator (four points total per edge),
matching the convention used by `_build_edge_shapes` for rectangular layouts:

1. Parent Cartesian: `(r_parent * cos(θ_parent), r_parent * sin(θ_parent))`
2. Chord connector: `(r_parent * cos(θ_child), r_parent * sin(θ_child))` — at
   parent radius, child angle
3. Child Cartesian: `(r_child * cos(θ_child), r_child * sin(θ_child))`
4. `Point2f(NaN, NaN)` separator
"""
function _build_circular_edge_shapes(
        all_nodes::Vector,
        accessor::LineageGraphAccessor,
        process_coordinates::Dict{Any, Float64},
        angles::Dict{Any, Float64},
    )::Vector{Point2f}
    shapes = Point2f[]
    for node in all_nodes
        r_parent = process_coordinates[node]
        θ_parent = angles[node]
        x_parent = r_parent * cos(θ_parent)
        y_parent = r_parent * sin(θ_parent)
        for child in accessor.children(node)
            r_child = process_coordinates[child]
            θ_child = angles[child]
            x_conn = r_parent * cos(θ_child)
            y_conn = r_parent * sin(θ_child)
            x_child = r_child * cos(θ_child)
            y_child = r_child * sin(θ_child)
            push!(
                shapes,
                Point2f(x_parent, y_parent),
                Point2f(x_conn, y_conn),
                Point2f(x_child, y_child),
                Point2f(NaN, NaN),
            )
        end
    end
    return shapes
end

# ── Exports ────────────────────────────────────────────────────────────────────

export LineageGraphGeometry, boundingbox, rectangular_layout, circular_layout

end # module Geometry
