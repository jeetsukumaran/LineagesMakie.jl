module Topology

# Package-owned node record for a normalized lineage graph.
struct NormalizedNode{NodeT}
    index::Int
    source_node::NodeT
end

# Package-owned directed edge record for a normalized lineage graph.
struct NormalizedEdge{NodeT}
    index::Int
    src::NormalizedNode{NodeT}
    dst::NormalizedNode{NodeT}
end

# Normalized lineage-graph topology with stable node identity, stable edge
# identity, parent and child incidence, deterministic topological node order,
# and deterministic sink order.
struct NormalizedTopology{NodeT}
    basenode::NormalizedNode{NodeT}
    nodes::Vector{NormalizedNode{NodeT}}
    edges::Vector{NormalizedEdge{NodeT}}
    parent_edges::Vector{Vector{NormalizedEdge{NodeT}}}
    child_edges::Vector{Vector{NormalizedEdge{NodeT}}}
    node_order::Vector{NormalizedNode{NodeT}}
    sink_order::Vector{NormalizedNode{NodeT}}
    node_lookup::IdDict{Any, NormalizedNode{NodeT}}
end

function normalize_topology(accessor, basenode)::NormalizedTopology{Any}
    node_lookup = IdDict{Any, NormalizedNode{Any}}()
    nodes = NormalizedNode{Any}[]
    edges = NormalizedEdge{Any}[]
    parent_edges = Vector{Vector{NormalizedEdge{Any}}}()
    child_edges = Vector{Vector{NormalizedEdge{Any}}}()
    sink_order = NormalizedNode{Any}[]
    visit_state = IdDict{Any, UInt8}()

    basenode_record = _visit!(
        accessor,
        basenode,
        node_lookup,
        nodes,
        edges,
        parent_edges,
        child_edges,
        sink_order,
        visit_state,
    )
    node_order = _topological_order(nodes, parent_edges, child_edges)

    return NormalizedTopology(
        basenode_record,
        nodes,
        edges,
        parent_edges,
        child_edges,
        node_order,
        sink_order,
        node_lookup,
    )
end

function normalized_node(
        topology::NormalizedTopology{Any},
        source_node,
    )::NormalizedNode{Any}
    node = get(topology.node_lookup, source_node, nothing)
    node === nothing && throw(
        ArgumentError(
            "source node $(repr(source_node)) is not reachable from the normalized basenode",
        ),
    )
    return node
end

function parent_incidence(
        topology::NormalizedTopology{Any},
        node::NormalizedNode{Any},
    )::Vector{NormalizedEdge{Any}}
    return topology.parent_edges[node.index]
end

function child_incidence(
        topology::NormalizedTopology{Any},
        node::NormalizedNode{Any},
    )::Vector{NormalizedEdge{Any}}
    return topology.child_edges[node.index]
end

function source_nodes(nodes::Vector{NormalizedNode{Any}})::Vector{Any}
    return Any[node.source_node for node in nodes]
end

function _visit!(
        accessor,
        source_node,
        node_lookup::IdDict{Any, NormalizedNode{Any}},
        nodes::Vector{NormalizedNode{Any}},
        edges::Vector{NormalizedEdge{Any}},
        parent_edges::Vector{Vector{NormalizedEdge{Any}}},
        child_edges::Vector{Vector{NormalizedEdge{Any}}},
        sink_order::Vector{NormalizedNode{Any}},
        visit_state::IdDict{Any, UInt8},
    )::NormalizedNode{Any}
    state = get(visit_state, source_node, 0x00)
    state == 0x01 && throw(
        ArgumentError(
            "directed cycle detected while normalizing the lineage graph: " *
                "node $(repr(source_node)) was reached again on the active traversal path",
        ),
    )
    state == 0x02 && return node_lookup[source_node]

    normalized = _get_or_create_node!(
        source_node,
        node_lookup,
        nodes,
        parent_edges,
        child_edges,
    )
    visit_state[source_node] = 0x01

    child_collection = accessor.children(source_node)
    if isempty(child_collection)
        push!(sink_order, normalized)
    else
        for child_source_node in child_collection
            child_state = get(visit_state, child_source_node, 0x00)
            child_state == 0x01 && throw(
                ArgumentError(
                    "directed cycle detected while normalizing the lineage graph: " *
                        "edge $(repr(source_node)) -> $(repr(child_source_node)) " *
                        "re-enters the active traversal path",
                ),
            )
            child = _get_or_create_node!(
                child_source_node,
                node_lookup,
                nodes,
                parent_edges,
                child_edges,
            )
            edge = NormalizedEdge{Any}(length(edges) + 1, normalized, child)
            push!(edges, edge)
            push!(child_edges[normalized.index], edge)
            push!(parent_edges[child.index], edge)
            child_state == 0x00 && _visit!(
                accessor,
                child_source_node,
                node_lookup,
                nodes,
                edges,
                parent_edges,
                child_edges,
                sink_order,
                visit_state,
            )
        end
    end

    visit_state[source_node] = 0x02
    return normalized
end

function _get_or_create_node!(
        source_node,
        node_lookup::IdDict{Any, NormalizedNode{Any}},
        nodes::Vector{NormalizedNode{Any}},
        parent_edges::Vector{Vector{NormalizedEdge{Any}}},
        child_edges::Vector{Vector{NormalizedEdge{Any}}},
    )::NormalizedNode{Any}
    haskey(node_lookup, source_node) && return node_lookup[source_node]

    normalized = NormalizedNode{Any}(length(nodes) + 1, source_node)
    node_lookup[source_node] = normalized
    push!(nodes, normalized)
    push!(parent_edges, NormalizedEdge{Any}[])
    push!(child_edges, NormalizedEdge{Any}[])
    return normalized
end

function _topological_order(
        nodes::Vector{NormalizedNode{Any}},
        parent_edges::Vector{Vector{NormalizedEdge{Any}}},
        child_edges::Vector{Vector{NormalizedEdge{Any}}},
    )::Vector{NormalizedNode{Any}}
    indegrees = [length(parent_edges[node.index]) for node in nodes]
    available = sort(
        [node for node in nodes if indegrees[node.index] == 0];
        by = node -> node.index,
    )
    ordered = NormalizedNode{Any}[]

    while !isempty(available)
        node = popfirst!(available)
        push!(ordered, node)
        for edge in child_edges[node.index]
            child_index = edge.dst.index
            indegrees[child_index] -= 1
            if indegrees[child_index] == 0
                push!(available, edge.dst)
                sort!(available; by = available_node -> available_node.index)
            end
        end
    end

    length(ordered) == length(nodes) || error(
        "internal error: topological ordering failed after cycle checks",
    )
    return ordered
end

export NormalizedEdge
export NormalizedNode
export NormalizedTopology
export child_incidence
export normalize_topology
export normalized_node
export parent_incidence
export source_nodes

end # module Topology
