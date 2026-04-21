module Accessors

using AbstractTrees: children as abstracttrees_children

# ── TreeAccessor ───────────────────────────────────────────────────────────────

"""
    TreeAccessor{C, E, V, B, CA, VC, VP}

The fundamental accessor protocol for LineagesMakie. Holds seven callable fields
that together describe how to navigate and query a tree-structured value. All
downstream modules (Geometry, Layers, LineageAxis) accept a `TreeAccessor` and
never depend on the source tree type.

Fields:
- `children::C`                        — required; callable `vertex -> iterable-of-children`.
- `edgelength::Union{Nothing, E}`      — optional; `(fromvertex, tovertex) -> Float64`
  or `(fromvertex, tovertex) -> (; value::Float64, units::Symbol)`.
- `vertexvalue::Union{Nothing, V}`     — optional; `vertex -> Any`; per-vertex data
  for labels and color mapping.
- `branchingtime::Union{Nothing, B}`   — optional; `vertex -> Float64`; pre-computed
  cumulative edge-length sum from the rootvertex.
- `coalescenceage::Union{Nothing, CA}` — optional; `vertex -> Float64`; pre-computed
  coalescence age (leaf = 0, increases toward root).
- `vertexcoords::Union{Nothing, VC}`   — optional; `vertex -> Point2f`; user-supplied
  data coordinates.
- `vertexpos::Union{Nothing, VP}`      — optional; `vertex -> Point2f`; user-supplied
  pixel coordinates.

Every field is concretely typed at instantiation via type parameters. When an
optional field is omitted, its type parameter resolves to `Nothing` and the
field is typed `Nothing`. When a callable is supplied, the parameter resolves to
that callable's concrete singleton type. This ensures full compiler
specialisation with no dynamic dispatch on accessor calls.
"""
struct TreeAccessor{C, E, V, B, CA, VC, VP}
    children::C
    edgelength::E
    vertexvalue::V
    branchingtime::B
    coalescenceage::CA
    vertexcoords::VC
    vertexpos::VP
end

"""
    tree_accessor(rootvertex; children, edgelength=nothing, vertexvalue=nothing,
                  branchingtime=nothing, coalescenceage=nothing,
                  vertexcoords=nothing, vertexpos=nothing) -> TreeAccessor

Construct a `TreeAccessor` from explicit keyword callables.

The `rootvertex` argument is accepted for dispatch and type-inference purposes
but is not stored. All accessor keyword arguments are stored as fields.

# Arguments
- `_` (rootvertex): the root of the tree; not stored; accepted only for API
  symmetry with `abstracttrees_accessor`.
- `children`: required callable `vertex -> iterable`; the only mandatory field.
- `edgelength`: optional callable `(fromvertex, tovertex) -> value`.
- `vertexvalue`: optional callable `vertex -> Any`.
- `branchingtime`: optional callable `vertex -> Float64`.
- `coalescenceage`: optional callable `vertex -> Float64`.
- `vertexcoords`: optional callable `vertex -> Point2f`.
- `vertexpos`: optional callable `vertex -> Point2f`.

# Returns
A fully parameterised `TreeAccessor{C, E, V, B, CA, VC, VP}` whose type
parameters are the concrete types of each supplied callable (or `Nothing` for
omitted optionals).

# Throws
- `ArgumentError` if `children` is not callable.
"""
function tree_accessor(
    rootvertex;
    children,
    edgelength     = nothing,
    vertexvalue    = nothing,
    branchingtime  = nothing,
    coalescenceage = nothing,
    vertexcoords   = nothing,
    vertexpos      = nothing,
)::TreeAccessor
    isa(children, Base.Callable) || throw(
        ArgumentError(
            "children must be callable for a tree rooted at $(typeof(rootvertex)); " *
            "got $(typeof(children)): $(repr(children))",
        ),
    )
    return TreeAccessor(
        children,
        edgelength,
        vertexvalue,
        branchingtime,
        coalescenceage,
        vertexcoords,
        vertexpos,
    )
end

# ── AbstractTrees adapter ──────────────────────────────────────────────────────

"""
    abstracttrees_accessor(rootvertex; edgelength=nothing, vertexvalue=nothing,
                           branchingtime=nothing, coalescenceage=nothing) -> TreeAccessor

Construct a `TreeAccessor` by wrapping `AbstractTrees.children` as the
`children` callable. This is a thin adapter shim: `TreeAccessor` itself has no
dependency on AbstractTrees; the AbstractTrees dependency is confined to this
function.

The `rootvertex` argument is not stored. `AbstractTrees.children` has a
universal fallback that returns `()` for any type, so no interface check is
performed: any value is accepted and types with no explicit `children` method
will produce a single-leaf tree.

# Arguments
- `rootvertex`: not stored; accepted for API symmetry with `tree_accessor`.
- `edgelength`, `vertexvalue`, `branchingtime`, `coalescenceage`: same
  semantics as in `tree_accessor`.

# Returns
A `TreeAccessor` whose `children` field is `AbstractTrees.children`.
"""
function abstracttrees_accessor(
    rootvertex;
    edgelength     = nothing,
    vertexvalue    = nothing,
    branchingtime  = nothing,
    coalescenceage = nothing,
)::TreeAccessor
    return TreeAccessor(
        abstracttrees_children,
        edgelength,
        vertexvalue,
        branchingtime,
        coalescenceage,
        nothing,
        nothing,
    )
end

# ── Predicates ─────────────────────────────────────────────────────────────────

"""
    is_leaf(accessor::TreeAccessor, vertex) -> Bool

Return `true` when `accessor.children(vertex)` yields an empty iterable, i.e.,
the vertex has no children and is therefore a leaf.
"""
function is_leaf(accessor::TreeAccessor, vertex)::Bool
    return isempty(accessor.children(vertex))
end

# ── Traversals ─────────────────────────────────────────────────────────────────

"""
    leaves(accessor::TreeAccessor, rootvertex) -> Vector{Any}

Return all leaf vertices reachable from `rootvertex` in a deterministic
depth-first order.

Cycle detection is performed at every step. If any vertex is encountered more
than once, `ArgumentError` is raised immediately before any partial result is
returned.

# Throws
- `ArgumentError` if a cycle is detected in the tree.
"""
function leaves(accessor::TreeAccessor, rootvertex)::Vector{Any}
    result  = Vector{Any}()
    visited = Set{Any}()
    _collect_leaves!(result, visited, accessor, rootvertex)
    return result
end

"""
    preorder(accessor::TreeAccessor, rootvertex) -> Vector{Any}

Return all vertices reachable from `rootvertex` in preorder (parent before
children), depth-first, deterministic.

Cycle detection is performed at every step. If any vertex is encountered more
than once, `ArgumentError` is raised immediately before any partial result is
returned.

# Throws
- `ArgumentError` if a cycle is detected in the tree.
"""
function preorder(accessor::TreeAccessor, rootvertex)::Vector{Any}
    result  = Vector{Any}()
    visited = Set{Any}()
    _collect_preorder!(result, visited, accessor, rootvertex)
    return result
end

# ── Internal traversal helpers ─────────────────────────────────────────────────

function _check_cycle!(visited::Set, vertex)::Nothing
    vertex ∈ visited && throw(
        ArgumentError(
            "cycle detected in tree: vertex $(repr(vertex)) was encountered " *
            "more than once during traversal; the input must be a tree (acyclic)",
        ),
    )
    push!(visited, vertex)
    return nothing
end

function _collect_leaves!(result, visited, accessor, vertex)::Nothing
    _check_cycle!(visited, vertex)
    ch = accessor.children(vertex)
    if isempty(ch)
        push!(result, vertex)
    else
        for c in ch
            _collect_leaves!(result, visited, accessor, c)
        end
    end
    return nothing
end

function _collect_preorder!(result, visited, accessor, vertex)::Nothing
    _check_cycle!(visited, vertex)
    push!(result, vertex)
    for c in accessor.children(vertex)
        _collect_preorder!(result, visited, accessor, c)
    end
    return nothing
end

# ── Exports ────────────────────────────────────────────────────────────────────

export TreeAccessor, tree_accessor, abstracttrees_accessor, is_leaf, leaves, preorder

end # module Accessors
