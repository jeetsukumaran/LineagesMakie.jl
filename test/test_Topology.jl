# Tests for Topology

const _Topology = LineagesMakie.Topology

mutable struct DagNode
    name::String
    children::Vector{DagNode}
end

function _dag_accessor(basenode)
    return lineagegraph_accessor(basenode; children = node -> node.children)
end

@testset "Topology" begin

    @testset "normalize_topology accepts shared-descendant DAGs" begin
        shared = DagNode("shared", DagNode[])
        left = DagNode("left", DagNode[shared])
        right = DagNode("right", DagNode[shared])
        basenode = DagNode("root", DagNode[left, right])

        topology = _Topology.normalize_topology(_dag_accessor(basenode), basenode)
        shared_node = _Topology.normalized_node(topology, shared)

        @test length(topology.nodes) == 4
        @test length(topology.edges) == 4
        @test [node.source_node.name for node in topology.node_order] == ["root", "left", "right", "shared"]
        @test [node.source_node.name for node in topology.sink_order] == ["shared"]
        @test [edge.src.source_node.name for edge in _Topology.parent_incidence(topology, shared_node)] == ["left", "right"]
        @test [edge.index for edge in _Topology.parent_incidence(topology, shared_node)] == [2, 4]
        @test [edge.dst.source_node.name for edge in _Topology.child_incidence(topology, topology.basenode)] == ["left", "right"]
    end

    @testset "normalize_topology rejects true directed cycles directly" begin
        a = DagNode("a", DagNode[])
        b = DagNode("b", DagNode[])
        c = DagNode("c", DagNode[])
        a.children = DagNode[b]
        b.children = DagNode[c]
        c.children = DagNode[a]

        error = try
            _Topology.normalize_topology(_dag_accessor(a), a)
            nothing
        catch caught_error
            caught_error
        end

        @test error isa ArgumentError
        @test occursin("directed cycle", sprint(showerror, error))
    end

end
