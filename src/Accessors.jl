module Accessors

using AbstractTrees: children as abstracttrees_children

# ── LineageGraphAccessor ────────────────────────────────────────────────────────

"""
    LineageGraphAccessor{C, E, NodeT, B, CA, NC, NP}

The fundamental accessor protocol for LineagesMakie. Holds seven callable fields
that together describe how to navigate and query a lineage graph. All
downstream modules (Geometry, Layers, LineageAxis) accept a
`LineageGraphAccessor` and never depend on the source type.

Fields:
- `children::C`                        — required; callable `node -> iterable-of-children`.
- `edgelength::Union{Nothing, E}`      — optional; `(src, dst) -> Float64`
  or `(src, dst) -> (; value::Float64, units::Symbol)`.
- `nodevalue::Union{Nothing, NodeT}`   — optional; `node -> Any`; per-node data
  for labels and color mapping.
- `branchingtime::Union{Nothing, B}`   — optional; `node -> Float64`; pre-computed
  cumulative edge-length sum from the rootnode.
- `coalescenceage::Union{Nothing, CA}` — optional; `node -> Float64`; pre-computed
  coalescence age (leaf = 0, increases toward root).
- `nodecoordinates::Union{Nothing, NC}`     — optional; `node -> Point2f`; user-supplied
  data coordinates.
- `nodepos::Union{Nothing, NP}`        — optional; `node -> Point2f`; user-supplied
  pixel coordinates.

Every field is concretely typed at instantiation via type parameters. When an
optional field is omitted, its type parameter resolves to `Nothing` and the
field is typed `Nothing`. When a callable is supplied, the parameter resolves to
that callable's concrete singleton type. This ensures full compiler
specialisation with no dynamic dispatch on accessor calls.
"""
struct LineageGraphAccessor{C, E, NodeT, B, CA, NC, NP}
    children::C
    edgelength::E
    nodevalue::NodeT
    branchingtime::B
    coalescenceage::CA
    nodecoordinates::NC
    nodepos::NP
end

"""
    lineagegraph_accessor(rootnode; children, edgelength=nothing, nodevalue=nothing,
                          branchingtime=nothing, coalescenceage=nothing,
                          nodecoordinates=nothing, nodepos=nothing) -> LineageGraphAccessor

Construct a `LineageGraphAccessor` from explicit keyword callables.

The `rootnode` argument is accepted for dispatch and type-inference purposes
but is not stored. All accessor keyword arguments are stored as fields.

# Arguments
- `_` (rootnode): the root of the lineage graph; not stored; accepted only for
  API symmetry with `abstracttrees_accessor`.
- `children`: required callable `node -> iterable`; the only mandatory field.
- `edgelength`: optional callable `(src, dst) -> value`.
- `nodevalue`: optional callable `node -> Any`.
- `branchingtime`: optional callable `node -> Float64`.
- `coalescenceage`: optional callable `node -> Float64`.
- `nodecoordinates`: optional callable `node -> Point2f`.
- `nodepos`: optional callable `node -> Point2f`.

# Returns
A fully parameterised `LineageGraphAccessor{C, E, NodeT, B, CA, NC, NP}` whose type
parameters are the concrete types of each supplied callable (or `Nothing` for
omitted optionals).

# Throws
- `ArgumentError` if `children` is not callable.
"""
function lineagegraph_accessor(
        rootnode;
        children,
        edgelength = nothing,
        nodevalue = nothing,
        branchingtime = nothing,
        coalescenceage = nothing,
        nodecoordinates = nothing,
        nodepos = nothing,
    )::LineageGraphAccessor
    isa(children, Base.Callable) || throw(
        ArgumentError(
            "children must be callable for a lineage graph rooted at $(typeof(rootnode)); " *
                "got $(typeof(children)): $(repr(children))",
        ),
    )
    return LineageGraphAccessor(
        children,
        edgelength,
        nodevalue,
        branchingtime,
        coalescenceage,
        nodecoordinates,
        nodepos,
    )
end

# ── AbstractTrees adapter ──────────────────────────────────────────────────────

"""
    abstracttrees_accessor(rootnode; edgelength=nothing, nodevalue=nothing,
                           branchingtime=nothing, coalescenceage=nothing) -> LineageGraphAccessor

Construct a `LineageGraphAccessor` by wrapping `AbstractTrees.children` as the
`children` callable. This is a thin adapter shim: `LineageGraphAccessor` itself
has no dependency on AbstractTrees; the AbstractTrees dependency is confined to
this function.

The `rootnode` argument is not stored. `AbstractTrees.children` has a
universal fallback that returns `()` for any type, so no interface check is
performed: any value is accepted and types with no explicit `children` method
will produce a single-leaf lineage graph.

# Arguments
- `rootnode`: not stored; accepted for API symmetry with `lineagegraph_accessor`.
- `edgelength`, `nodevalue`, `branchingtime`, `coalescenceage`: same
  semantics as in `lineagegraph_accessor`.

# Returns
A `LineageGraphAccessor` whose `children` field is `AbstractTrees.children`.
"""
function abstracttrees_accessor(
        rootnode;
        edgelength = nothing,
        nodevalue = nothing,
        branchingtime = nothing,
        coalescenceage = nothing,
    )::LineageGraphAccessor
    return LineageGraphAccessor(
        abstracttrees_children,
        edgelength,
        nodevalue,
        branchingtime,
        coalescenceage,
        nothing,
        nothing,
    )
end

# ── Predicates ─────────────────────────────────────────────────────────────────

"""
    is_leaf(accessor::LineageGraphAccessor, node) -> Bool

Return `true` when `accessor.children(node)` yields an empty iterable, i.e.,
the node has no children and is therefore a leaf.
"""
function is_leaf(accessor::LineageGraphAccessor, node)::Bool
    return isempty(accessor.children(node))
end

# ── Traversals ─────────────────────────────────────────────────────────────────

"""
    leaves(accessor::LineageGraphAccessor, rootnode) -> Vector{Any}

Return all leaf nodes reachable from `rootnode` in a deterministic
depth-first order.

Cycle detection is performed at every step. If any node is encountered more
than once, `ArgumentError` is raised immediately before any partial result is
returned.

# Throws
- `ArgumentError` if a cycle is detected in the lineage graph.
"""
function leaves(accessor::LineageGraphAccessor, rootnode)::Vector{Any}
    result = Vector{Any}()
    visited = Set{Any}()
    _collect_leaves!(result, visited, accessor, rootnode)
    return result
end

"""
    preorder(accessor::LineageGraphAccessor, rootnode) -> Vector{Any}

Return all nodes reachable from `rootnode` in preorder (parent before
children), depth-first, deterministic.

Cycle detection is performed at every step. If any node is encountered more
than once, `ArgumentError` is raised immediately before any partial result is
returned.

# Throws
- `ArgumentError` if a cycle is detected in the lineage graph.
"""
function preorder(accessor::LineageGraphAccessor, rootnode)::Vector{Any}
    result = Vector{Any}()
    visited = Set{Any}()
    _collect_preorder!(result, visited, accessor, rootnode)
    return result
end

# ── Internal traversal helpers ─────────────────────────────────────────────────

function _check_cycle!(visited::Set, node)::Nothing
    # Shared ancestry (reticulation) is not yet supported; acyclicity is required.
    node ∈ visited && throw(
        ArgumentError(
            "cycle detected in lineage graph: node $(repr(node)) was encountered " *
                "more than once during traversal; the lineage graph must be acyclic",
        ),
    )
    push!(visited, node)
    return nothing
end

function _collect_leaves!(result, visited, accessor, node)::Nothing
    _check_cycle!(visited, node)
    child_collection = accessor.children(node)
    if isempty(child_collection)
        push!(result, node)
    else
        for child in child_collection
            _collect_leaves!(result, visited, accessor, child)
        end
    end
    return nothing
end

function _collect_preorder!(result, visited, accessor, node)::Nothing
    _check_cycle!(visited, node)
    push!(result, node)
    for child in accessor.children(node)
        _collect_preorder!(result, visited, accessor, child)
    end
    return nothing
end

# ── Exports ────────────────────────────────────────────────────────────────────

export LineageGraphAccessor, lineagegraph_accessor, abstracttrees_accessor, is_leaf, leaves, preorder

end # module Accessors
