module Geometry

# edge_shapes representation research:
# Makie's lines! accepts a single Vector{Point2f} with Point2f(NaN, NaN)
# separators between disconnected polylines. This is used throughout Makie:
#   - Makie/src/stats/dendrogram.jl:80: push!(ret_points, Point2d(NaN))
#   - GraphMakie.jl/src/recipes.jl:728: push!(points, PT(NaN))
# One lines! call draws all edges; NaN breaks the connected path between them.
# Confirmed from Makie/src/conversions.jl:207: push!(points, PT(NaN)) for Rect3.

using Makie: Point2f, Rect2f

using ..Accessors: LineageGraphAccessor
using ..Topology:
    NormalizedNode,
    NormalizedTopology,
    child_incidence,
    normalize_topology,
    parent_incidence,
    source_nodes

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
  normalized-topology edge order as `edge_shapes`. `edges[i]` corresponds to
  the i-th NaN-terminated group of 4 points in `edge_shapes`. Used by
  rendering layers to expand per-edge attribute functions without re-traversing
  the source tree.
- `leaf_order::Vector{NodeT}`: leaves in the order they appear along the
  rendered leaf axis. Topology-backed layouts derive this from owner-computed
  layout coordinates; explicit-coordinate layouts derive it from the supplied
  coordinates while preserving normalized-topology sink order as a tie-break.
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

The geometry owner normalizes the lineage graph once and then consumes the
normalized topology as its authority for node order, sink order, parent
incidence, child incidence, and edge order.

Process coordinates (first `Point2f` component) are determined by `lineageunits`:

- `:edgeweights` — cumulative `edgeweight(src, dst)` from
  `basenode`; requires `edgeweight` accessor; `basenode` = 0, increases
  toward leaves. Missing edge weights emit `@warn` and fall back to 1.0;
  negative edge weights raise `ArgumentError`.
- `:branchingtime` — per-node branching time read directly from
  `branchingtime(node)`; requires `branchingtime` accessor. Every normalized
  edge must remain forward-monotone (`branchingtime(dst) ≥ branchingtime(src)`).
- `:coalescenceage` — per-node coalescence age read from
  `coalescenceage(node)`; requires `coalescenceage` accessor; leaves = 0,
  increases toward the basenode. On shared-parent lineage graphs, every
  normalized edge must remain backward-monotone
  (`coalescenceage(src) ≥ coalescenceage(dst)`). Tree-only non-ultrametric
  inputs are controlled by `nonultrametric`.
- `:nodedepths` — shortest directed path length (edge count) from `basenode`;
  `basenode` = 0, increases by 1 per edge. No accessor required.
- `:nodeheights` — longest directed path length (edge count) to any descendant
  sink. Sinks = 0, basenode = maximum. No accessor required.
- `:nodelevels` — longest directed path length (edge count) from `basenode`:
  `basenode` = 0, leaves or sinks = maximum. Equal inter-level spacing. No
  accessor required.
- `:nodecoordinates` — user-supplied `Point2f` data coordinates read from
  `nodecoordinates(node)`; requires `nodecoordinates` accessor. Bypasses
  layout computation entirely; both process and transverse coordinates come
  from the accessor.
- `:nodepos` — user-supplied `Point2f` pixel coordinates read from
  `nodepos(node)`; requires `nodepos` accessor. Same geometry-layer behaviour
  as `:nodecoordinates`; the semantic distinction (data vs pixel space) is
  documented here but not enforced at the geometry layer.

**Default detection:** if `lineageunits` is not supplied (or `nothing`), the
default is `:edgeweights` when an `edgeweight` accessor is present; otherwise
`:nodeheights`.

Transverse coordinates (second `Point2f` component) place leaves at equal
intervals by default (`leaf_spacing = :equal`). The `leaf_order` field records
the rendered leaf sequence. For explicit-coordinate units, `leaf_order` is
derived from the supplied transverse coordinates rather than from topology
sink order.

For units that synthesize rectangular coordinates, each edge `src → dst`
contributes a right-angle polyline:
  `(x_src, y_src) → (x_src, y_dst) → (x_dst, y_dst)`
followed by a `Point2f(NaN, NaN)` separator. Explicit-coordinate units preserve
the supplied node positions and connect them with direct segments while keeping
the same 4-point-per-edge storage contract.

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
- `ArgumentError` if a weighted full-network unit encounters inconsistent
  multi-parent coordinates and therefore requires an explicit projected-tree or
  other named resolution contract.
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
    topology = _normalized_geometry_inputs(basenode, accessor)

    # Bypass modes: both process and transverse coordinates come from the accessor.
    if lineageunits === :nodecoordinates || lineageunits === :nodepos
        accessor_fn = lineageunits === :nodecoordinates ? accessor.nodecoordinates : accessor.nodepos
        accessor_fn === nothing && throw(
            ArgumentError(
                "lineageunits = $(repr(lineageunits)) requires a $(lineageunits) accessor " *
                    "but none was supplied",
            ),
        )
        node_positions = _explicit_node_positions(topology, accessor_fn)
        edge_shapes = _build_direct_edge_shapes(topology, node_positions)
        edges = _build_edge_list(topology)
        bb = _compute_boundingbox(node_positions)
        leaf_list = _explicit_rectangular_leaf_order(topology, node_positions)
        return LineageGraphGeometry(node_positions, edge_shapes, edges, leaf_list, bb)
    end

    process_coordinates = _process_coordinates(topology, accessor, lineageunits, nonultrametric)
    transverse_coordinates = _transverse_coordinates(topology, step)

    node_positions = _build_node_positions(topology.node_order, process_coordinates, transverse_coordinates)
    edge_shapes = _build_edge_shapes(topology, process_coordinates, transverse_coordinates)
    edges = _build_edge_list(topology)
    leaf_list = _ordered_sinks(topology, transverse_coordinates)
    bb = _compute_boundingbox(node_positions)

    return LineageGraphGeometry(node_positions, edge_shapes, edges, leaf_list, bb)
end

function _normalized_geometry_inputs(
        basenode,
        accessor::LineageGraphAccessor,
    )::NormalizedTopology{Any}
    topology = normalize_topology(accessor, basenode)
    isempty(topology.sink_order) && throw(
        ArgumentError(
            "lineage graph with basenode $(repr(basenode)) has zero leaves; " *
                "a layout requires at least one leaf",
        ),
    )
    return topology
end

function _is_tree_topology(topology::NormalizedTopology{Any})::Bool
    for node in topology.node_order
        length(parent_incidence(topology, node)) <= 1 || return false
    end
    return true
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
        topology::NormalizedTopology{Any},
        accessor::LineageGraphAccessor,
        lineageunits::Symbol,
        nonultrametric::Symbol,
    )::Dict{Any, Float64}
    if lineageunits === :nodeheights
        return _nodeheights(topology)
    elseif lineageunits === :nodelevels
        return _nodelevels(topology)
    elseif lineageunits === :edgeweights
        accessor.edgeweight === nothing && throw(
            ArgumentError(
                "lineageunits = :edgeweights requires an edgeweight accessor " *
                    "but none was supplied",
            ),
        )
        return _edgeweight_coordinates(topology, accessor)
    elseif lineageunits === :branchingtime
        accessor.branchingtime === nothing && throw(
            ArgumentError(
                "lineageunits = :branchingtime requires a branchingtime accessor " *
                    "but none was supplied",
            ),
        )
        return _branchingtime_coordinates(topology, accessor)
    elseif lineageunits === :nodedepths
        return _node_depths(topology)
    elseif lineageunits === :coalescenceage
        accessor.coalescenceage === nothing && throw(
            ArgumentError(
                "lineageunits = :coalescenceage requires a coalescenceage accessor " *
                    "but none was supplied",
            ),
        )
        return _coalescenceage_coordinates(topology, accessor, nonultrametric)
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

# ── Internal: topology-backed process coordinates ─────────────────────────────

function _edgeweight_coordinates(
        topology::NormalizedTopology{Any},
        accessor::LineageGraphAccessor,
    )::Dict{Any, Float64}
    coordinates = Dict{Any, Float64}(topology.basenode.source_node => 0.0)
    for node in topology.node_order
        src = node.source_node
        src_coordinate = coordinates[src]
        for edge in child_incidence(topology, node)
            dst = edge.dst.source_node
            candidate = src_coordinate + _safe_edgeweight(accessor, src, dst)
            if haskey(coordinates, dst)
                isapprox(coordinates[dst], candidate; atol = 1.0e-9, rtol = 1.0e-9) || throw(
                    ArgumentError(
                        "lineageunits = :edgeweights requires additive full-network consistency; " *
                            "node $(repr(dst)) reaches conflicting cumulative coordinates " *
                            "$(coordinates[dst]) and $(candidate)) from different parent paths. " *
                            "Select an explicit projected-tree or other named resolution contract instead.",
                    ),
                )
            else
                coordinates[dst] = candidate
            end
        end
    end
    return coordinates
end

function _branchingtime_coordinates(
        topology::NormalizedTopology{Any},
        accessor::LineageGraphAccessor,
    )::Dict{Any, Float64}
    coordinates = Dict{Any, Float64}()
    for node in topology.node_order
        coordinates[node.source_node] = Float64(accessor.branchingtime(node.source_node))
    end
    for edge in topology.edges
        src = edge.src.source_node
        dst = edge.dst.source_node
        coordinates[dst] + 1.0e-9 >= coordinates[src] || throw(
            ArgumentError(
                "lineageunits = :branchingtime requires forward full-network-consistent node values; " *
                    "edge $(repr(src)) -> $(repr(dst)) decreases from $(coordinates[src]) to " *
                    "$(coordinates[dst]). Select an explicit projected-tree or other named resolution " *
                    "contract instead.",
            ),
        )
    end
    return coordinates
end

function _coalescenceage_coordinates(
        topology::NormalizedTopology{Any},
        accessor::LineageGraphAccessor,
        nonultrametric::Symbol,
    )::Dict{Any, Float64}
    coordinates = Dict{Any, Float64}()
    for node in topology.node_order
        coordinates[node.source_node] = Float64(accessor.coalescenceage(node.source_node))
    end
    _is_tree_topology(topology) && _validate_tree_coalescence(topology, coordinates, nonultrametric)
    for edge in topology.edges
        src = edge.src.source_node
        dst = edge.dst.source_node
        coordinates[src] + 1.0e-9 >= coordinates[dst] || throw(
            ArgumentError(
                "lineageunits = :coalescenceage requires backward full-network-consistent node values; " *
                    "edge $(repr(src)) -> $(repr(dst)) increases from $(coordinates[src]) to " *
                    "$(coordinates[dst]). Select an explicit projected-tree or other named resolution " *
                    "contract instead.",
            ),
        )
    end
    return coordinates
end

function _nodeheights(topology::NormalizedTopology{Any})::Dict{Any, Float64}
    heights = Dict{Any, Float64}()
    for node in Iterators.reverse(topology.node_order)
        child_edges = child_incidence(topology, node)
        if isempty(child_edges)
            heights[node.source_node] = 0.0
        else
            heights[node.source_node] = maximum(
                heights[edge.dst.source_node] for edge in child_edges
            ) + 1.0
        end
    end
    return heights
end

function _nodelevels(topology::NormalizedTopology{Any})::Dict{Any, Float64}
    levels = Dict{Any, Float64}(topology.basenode.source_node => 0.0)
    for node in topology.node_order
        level = levels[node.source_node]
        for edge in child_incidence(topology, node)
            dst = edge.dst.source_node
            candidate = level + 1.0
            levels[dst] = haskey(levels, dst) ? max(levels[dst], candidate) : candidate
        end
    end
    return levels
end

function _node_depths(topology::NormalizedTopology{Any})::Dict{Any, Float64}
    depths = Dict{Any, Float64}(topology.basenode.source_node => 0.0)
    for node in topology.node_order
        depth = depths[node.source_node]
        for edge in child_incidence(topology, node)
            dst = edge.dst.source_node
            candidate = depth + 1.0
            depths[dst] = haskey(depths, dst) ? min(depths[dst], candidate) : candidate
        end
    end
    return depths
end

function _validate_tree_coalescence(
        topology::NormalizedTopology{Any},
        coordinates::Dict{Any, Float64},
        nonultrametric::Symbol,
    )::Nothing
    for node in Iterators.reverse(topology.node_order)
        child_edges = child_incidence(topology, node)
        isempty(child_edges) && continue
        child_ages = [coordinates[edge.dst.source_node] for edge in child_edges]
        mn = minimum(child_ages)
        mx = maximum(child_ages)
        if mx - mn > 1.0e-9 && nonultrametric === :error
            throw(
                ArgumentError(
                    "non-ultrametric lineage graph: children of node $(repr(node.source_node)) " *
                        "have inconsistent coalescenceage values (min=$(mn), max=$(mx)); " *
                        "pass nonultrametric = :minimum or :maximum to rectangular_layout to resolve",
                ),
            )
        end
    end
    return nothing
end

# ── Internal: transverse coordinate assignment ─────────────────────────────────

function _transverse_coordinates(
        topology::NormalizedTopology{Any},
        step::Float64,
    )::Dict{Any, Float64}
    return _is_tree_topology(topology) ?
        _tree_transverse_coordinates(topology, step) :
        _dag_transverse_coordinates(topology, step)
end

function _tree_transverse_coordinates(
        topology::NormalizedTopology{Any},
        step::Float64,
    )::Dict{Any, Float64}
    transverse = Dict{Any, Float64}()
    for (i, leaf) in enumerate(topology.sink_order)
        transverse[leaf.source_node] = i * step
    end
    for node in Iterators.reverse(topology.node_order)
        haskey(transverse, node.source_node) && continue
        child_edges = child_incidence(topology, node)
        transverse[node.source_node] = sum(
            transverse[edge.dst.source_node] for edge in child_edges
        ) / length(child_edges)
    end
    return transverse
end

function _dag_transverse_coordinates(
        topology::NormalizedTopology{Any},
        step::Float64,
    )::Dict{Any, Float64}
    transverse = Dict{Any, Float64}()
    for (i, node) in enumerate(topology.node_order)
        transverse[node.source_node] = i * step
    end
    return transverse
end

function _ordered_sinks(
        topology::NormalizedTopology{Any},
        axis_coordinates::Dict{Any, Float64},
    )::Vector{Any}
    ordered = sort(
        topology.sink_order;
        by = node -> (axis_coordinates[node.source_node], node.index),
    )
    return source_nodes(ordered)
end

function _explicit_rectangular_leaf_order(
        topology::NormalizedTopology{Any},
        node_positions::Dict{Any, Point2f},
    )::Vector{Any}
    ordered = sort(
        topology.sink_order;
        by = node -> (Float64(node_positions[node.source_node][2]), node.index),
    )
    return source_nodes(ordered)
end

function _explicit_radial_leaf_order(
        topology::NormalizedTopology{Any},
        node_positions::Dict{Any, Point2f},
        bb::Rect2f,
    )::Vector{Any}
    center = Point2f(
        bb.origin[1] + bb.widths[1] / 2,
        bb.origin[2] + bb.widths[2] / 2,
    )
    ordered = sort(
        topology.sink_order;
        by = node -> (
            _normalized_polar_angle(node_positions[node.source_node], center),
            node.index,
        ),
    )
    return source_nodes(ordered)
end

function _normalized_polar_angle(point::Point2f, center::Point2f)::Float64
    angle = atan(Float64(point[2] - center[2]), Float64(point[1] - center[1]))
    angle < 0.0 && (angle += 2.0 * π)
    return angle
end

# ── Internal: geometry assembly ────────────────────────────────────────────────

# Build the ordered list of (src, dst) pairs in normalized-topology edge order.
function _build_edge_list(
        topology::NormalizedTopology{Any},
    )::Vector{Tuple{Any, Any}}
    return Tuple{Any, Any}[
        (edge.src.source_node, edge.dst.source_node) for edge in topology.edges
    ]
end

function _explicit_node_positions(
        topology::NormalizedTopology{Any},
        accessor_fn,
    )::Dict{Any, Point2f}
    node_positions = Dict{Any, Point2f}()
    for node in topology.node_order
        node_positions[node.source_node] = Point2f(accessor_fn(node.source_node))
    end
    return node_positions
end

function _build_node_positions(
        node_order::Vector{NormalizedNode{Any}},
        process_coordinates::Dict{Any, Float64},
        transverse_coordinates::Dict{Any, Float64},
    )::Dict{Any, Point2f}
    pos = Dict{Any, Point2f}()
    for node in node_order
        pos[node.source_node] = Point2f(
            process_coordinates[node.source_node],
            transverse_coordinates[node.source_node],
        )
    end
    return pos
end

# Each edge produces three points forming a right-angle shape, plus a NaN
# separator. For an edge src → dst with coordinates (xp, yp) and (xc, yc):
#   (xp, yp) → (xp, yc) → (xc, yc) → (NaN, NaN)
# The first segment is parallel to the transverse axis (changes y at fixed x).
# The second segment is parallel to the lineage axis (changes x at fixed y).
function _build_edge_shapes(
        topology::NormalizedTopology{Any},
        process_coordinates::Dict{Any, Float64},
        transverse_coordinates::Dict{Any, Float64},
    )::Vector{Point2f}
    shapes = Point2f[]
    for edge in topology.edges
        src = edge.src.source_node
        dst = edge.dst.source_node
        xp = process_coordinates[src]
        yp = transverse_coordinates[src]
        xc = process_coordinates[dst]
        yc = transverse_coordinates[dst]
        push!(
            shapes,
            Point2f(xp, yp),
            Point2f(xp, yc),
            Point2f(xc, yc),
            Point2f(NaN, NaN),
        )
    end
    return shapes
end

function _build_direct_edge_shapes(
        topology::NormalizedTopology{Any},
        node_positions::Dict{Any, Point2f},
    )::Vector{Point2f}
    shapes = Point2f[]
    for edge in topology.edges
        src = node_positions[edge.src.source_node]
        dst = node_positions[edge.dst.source_node]
        midpoint = Point2f((src[1] + dst[1]) / 2, (src[2] + dst[2]) / 2)
        push!(shapes, src, midpoint, dst, Point2f(NaN, NaN))
    end
    return shapes
end

function _compute_envelope(points)::Rect2f
    found = false
    xmin = xmax = ymin = ymax = 0.0f0
    for point in points
        x = Float32(point[1])
        y = Float32(point[2])
        isfinite(x) && isfinite(y) || continue
        if !found
            xmin = xmax = x
            ymin = ymax = y
            found = true
            continue
        end
        x < xmin && (xmin = x)
        x > xmax && (xmax = x)
        y < ymin && (ymin = y)
        y > ymax && (ymax = y)
    end
    found || return Rect2f(0.0f0, 0.0f0, 0.0f0, 0.0f0)
    return Rect2f(xmin, ymin, xmax - xmin, ymax - ymin)
end

function _compute_boundingbox(node_positions::Dict{Any, Point2f})::Rect2f
    return _compute_envelope(values(node_positions))
end

function _plot_envelope(geom::LineageGraphGeometry)::Rect2f
    return _compute_envelope(Iterators.flatten((values(geom.node_positions), geom.edge_shapes)))
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

The geometry owner normalizes the lineage graph once and then consumes the
normalized topology as its authority for node order, sink order, parent
incidence, child incidence, and edge order.

Process coordinates (radial distances from the origin) are determined by `lineageunits`
using the same rules as `rectangular_layout`. Leaves are placed at equal angular
spacing by default for trees. Shared-parent lineage graphs use explicit
normalized-topology node order for angular placement so that the full network
remains visible without a hidden tree projection.

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

**Bypass modes:** `lineageunits = :nodecoordinates` and `:nodepos` use the
accessor coordinates directly, bypassing angular computation and preserving the
supplied node positions.

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
polar coordinates, `edge_shapes` using the chord representation, `leaf_order`
recording rendered leaf order, and `boundingbox` enclosing all node positions.

# Throws
- `ArgumentError` if the lineage graph has zero leaves.
- `ArgumentError` if `leaf_spacing` is a non-positive real number.
- `ArgumentError` if a required accessor is `nothing` for the chosen `lineageunits`.
- `ArgumentError` if `lineageunits` is not a supported value.
- `ArgumentError` if `circular_edge_style` is not `:chord`.
- `ArgumentError` if `lineageunits = :edgeweights` and any edge weight is negative.
- `ArgumentError` if `lineageunits = :coalescenceage`, the tree is non-ultrametric,
  and `nonultrametric = :error`.
- `ArgumentError` if a weighted full-network unit encounters inconsistent
  multi-parent coordinates and therefore requires an explicit projected-tree or
  other named resolution contract.
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
    topology = _normalized_geometry_inputs(basenode, accessor)

    # Bypass modes: both coordinates come from the accessor; no angular computation.
    if lineageunits === :nodecoordinates || lineageunits === :nodepos
        accessor_fn = lineageunits === :nodecoordinates ? accessor.nodecoordinates : accessor.nodepos
        accessor_fn === nothing && throw(
            ArgumentError(
                "lineageunits = $(repr(lineageunits)) requires a $(lineageunits) accessor " *
                    "but none was supplied",
            ),
        )
        node_positions = _explicit_node_positions(topology, accessor_fn)
        edge_shapes = _build_direct_edge_shapes(topology, node_positions)
        edges = _build_edge_list(topology)
        bb = _compute_boundingbox(node_positions)
        leaf_list = _explicit_radial_leaf_order(topology, node_positions, bb)
        return LineageGraphGeometry(node_positions, edge_shapes, edges, leaf_list, bb)
    end

    process_coordinates = _process_coordinates(topology, accessor, lineageunits, nonultrametric)

    θ_step = _angular_step(leaf_spacing, topology, min_leaf_angle)
    angles = _angular_positions(topology, θ_step)

    node_positions = Dict{Any, Point2f}()
    for node in topology.node_order
        r = process_coordinates[node.source_node]
        θ = angles[node.source_node]
        node_positions[node.source_node] = Point2f(r * cos(θ), r * sin(θ))
    end

    edge_shapes = _build_circular_edge_shapes(topology, process_coordinates, angles)
    edges = _build_edge_list(topology)
    leaf_list = _ordered_sinks(topology, angles)
    bb = _compute_boundingbox(node_positions)

    return LineageGraphGeometry(node_positions, edge_shapes, edges, leaf_list, bb)
end

# ── Internal: angular leaf step computation ────────────────────────────────────

"""
    _angular_step(leaf_spacing, topology, min_leaf_angle) -> Float64

Compute the angular spacing in radians for a circular layout.

For tree topologies, `leaf_spacing = :equal` uses `2π / n_sinks` (a single sink
gets `2π`). For shared-parent lineage graphs, `:equal` uses the normalized
topology's node order so that every node receives a distinct full-network
placement without a hidden tree projection. For a positive `Float64`
`leaf_spacing` the value is used directly as the angular step. When
`min_leaf_angle` is not `nothing` and the computed step is smaller, a warning
is emitted and `min_leaf_angle` is used, causing the layout to span less than a
full circle.
"""
function _angular_step(
        leaf_spacing,
        topology::NormalizedTopology{Any},
        min_leaf_angle::Union{Nothing, Float64},
    )::Float64
    n_positions = _is_tree_topology(topology) ? length(topology.sink_order) : length(topology.node_order)
    θ_step = if leaf_spacing === :equal
        n_positions > 1 ? 2π / n_positions : 2π
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
    _angular_positions(topology, θ_step) -> Dict{Any,Float64}

Assign an angular position (radians) to every node.

Tree topologies receive the classic leaf-driven placement: sinks receive evenly
spaced angles and internal nodes receive the mean of their children's angles.
Shared-parent lineage graphs receive explicit normalized-topology node-order
angles, preserving one full-network position per node without projecting the
DAG onto a tree.
"""
function _angular_positions(
        topology::NormalizedTopology{Any},
        θ_step::Float64,
    )::Dict{Any, Float64}
    return _is_tree_topology(topology) ?
        _tree_angular_positions(topology, θ_step) :
        _dag_angular_positions(topology, θ_step)
end

function _tree_angular_positions(
        topology::NormalizedTopology{Any},
        θ_step::Float64,
    )::Dict{Any, Float64}
    angles = Dict{Any, Float64}()
    for (i, leaf) in enumerate(topology.sink_order)
        angles[leaf.source_node] = (i - 1) * θ_step
    end
    for node in Iterators.reverse(topology.node_order)
        haskey(angles, node.source_node) && continue
        child_edges = child_incidence(topology, node)
        angles[node.source_node] = sum(
            angles[edge.dst.source_node] for edge in child_edges
        ) / length(child_edges)
    end
    return angles
end

function _dag_angular_positions(
        topology::NormalizedTopology{Any},
        θ_step::Float64,
    )::Dict{Any, Float64}
    angles = Dict{Any, Float64}()
    for (i, node) in enumerate(topology.node_order)
        angles[node.source_node] = (i - 1) * θ_step
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
        topology::NormalizedTopology{Any},
        process_coordinates::Dict{Any, Float64},
        angles::Dict{Any, Float64},
    )::Vector{Point2f}
    shapes = Point2f[]
    for edge in topology.edges
        src = edge.src.source_node
        dst = edge.dst.source_node
        r_parent = process_coordinates[src]
        θ_parent = angles[src]
        x_parent = r_parent * cos(θ_parent)
        y_parent = r_parent * sin(θ_parent)
        r_child = process_coordinates[dst]
        θ_child = angles[dst]
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
    return shapes
end

# ── Exports ────────────────────────────────────────────────────────────────────

export LineageGraphGeometry, boundingbox, rectangular_layout, circular_layout

end # module Geometry
