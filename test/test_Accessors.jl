# Tests for Accessors

using AbstractTrees

# ── Lineage graph fixtures ─────────────────────────────────────────────────────

struct TestNode
    name::String
    children::Vector{TestNode}
end

AbstractTrees.children(n::TestNode) = n.children

#   root
#   ├── ab
#   │   ├── a
#   │   └── b
#   └── cd
#       ├── c
#       └── d
const BALANCED_ROOT = TestNode("root", [
    TestNode("ab", [TestNode("a", TestNode[]), TestNode("b", TestNode[])]),
    TestNode("cd", [TestNode("c", TestNode[]), TestNode("d", TestNode[])]),
])

#   root
#   ├── a
#   ├── bc
#   │   ├── b
#   │   └── c
#   └── def
#       ├── d
#       └── ef
#           ├── e
#           └── f
const UNBALANCED_ROOT = TestNode("root", [
    TestNode("a", TestNode[]),
    TestNode("bc", [TestNode("b", TestNode[]), TestNode("c", TestNode[])]),
    TestNode("def", [
        TestNode("d", TestNode[]),
        TestNode("ef", [TestNode("e", TestNode[]), TestNode("f", TestNode[])]),
    ]),
])

# root with 4 direct leaf children (polytomy)
const POLYTOMY_ROOT = TestNode("root", [
    TestNode("a", TestNode[]),
    TestNode("b", TestNode[]),
    TestNode("c", TestNode[]),
    TestNode("d", TestNode[]),
])

# single node; it is both rootnode and the only leaf
const SINGLE_ROOT = TestNode("root", TestNode[])

# mutable struct for constructing cycles
mutable struct CyclicNode
    name::String
    ch::Vector{CyclicNode}
end

# ── Tests ──────────────────────────────────────────────────────────────────────

@testset "Accessors" begin

    @testset "lineagegraph_accessor — construction" begin
        acc = lineagegraph_accessor(BALANCED_ROOT; children = node -> node.children)
        @test acc isa LineageGraphAccessor
        @test acc.children isa Function
        @test acc.children(BALANCED_ROOT) == BALANCED_ROOT.children
        @test acc.edgelength    === nothing
        @test acc.nodevalue     === nothing
        @test acc.branchingtime === nothing
        @test acc.coalescenceage === nothing
        @test acc.nodecoordinates    === nothing
        @test acc.nodepos       === nothing
    end

    @testset "lineagegraph_accessor — all keyword combinations" begin
        el           = (src, dst) -> 1.0
        nodevalue_fn = node -> node.name
        bt           = node -> 0.0
        ca           = node -> 0.0
        nodecoordinates_fn = node -> (0.0, 0.0)
        nodepos_fn    = node -> (0.0, 0.0)
        acc = lineagegraph_accessor(BALANCED_ROOT;
            children       = node -> node.children,
            edgelength     = el,
            nodevalue      = nodevalue_fn,
            branchingtime  = bt,
            coalescenceage = ca,
            nodecoordinates     = nodecoordinates_fn,
            nodepos        = nodepos_fn,
        )
        @test acc isa LineageGraphAccessor
        @test acc.edgelength     === el
        @test acc.nodevalue      === nodevalue_fn
        @test acc.branchingtime  === bt
        @test acc.coalescenceage === ca
        @test acc.nodecoordinates     === nodecoordinates_fn
        @test acc.nodepos        === nodepos_fn
    end

    @testset "lineagegraph_accessor — non-callable children raises ArgumentError" begin
        @test_throws ArgumentError lineagegraph_accessor(BALANCED_ROOT; children = 42)
        @test_throws ArgumentError lineagegraph_accessor(BALANCED_ROOT; children = "notfn")
        @test_throws ArgumentError lineagegraph_accessor(BALANCED_ROOT; children = nothing)
        @test_throws ArgumentError lineagegraph_accessor(BALANCED_ROOT; children = [1, 2, 3])
    end

    @testset "abstracttrees_accessor — compliant type" begin
        acc = abstracttrees_accessor(BALANCED_ROOT)
        @test acc isa LineageGraphAccessor
        # children field must be AbstractTrees.children
        @test acc.children === AbstractTrees.children
        @test acc.edgelength    === nothing
        @test acc.nodecoordinates    === nothing
        @test acc.nodepos       === nothing
    end

    @testset "abstracttrees_accessor — universal fallback accepts any type" begin
        # AbstractTrees.children has a universal fallback returning () for any
        # type without an explicit children method, so any rootnode is accepted.
        # Such a value is treated as a single leaf.
        struct NoExplicitChildren end
        acc = abstracttrees_accessor(NoExplicitChildren())
        @test acc isa LineageGraphAccessor
        @test is_leaf(acc, NoExplicitChildren())
    end

    @testset "is_leaf" begin
        acc = lineagegraph_accessor(BALANCED_ROOT; children = node -> node.children)
        # leaves return true
        @test is_leaf(acc, TestNode("x", TestNode[]))
        @test is_leaf(acc, SINGLE_ROOT)
        # internal nodes return false
        @test !is_leaf(acc, BALANCED_ROOT)
        @test !is_leaf(acc, BALANCED_ROOT.children[1])
    end

    @testset "leaves — balanced (4 leaves)" begin
        acc = lineagegraph_accessor(BALANCED_ROOT; children = node -> node.children)
        ls  = leaves(acc, BALANCED_ROOT)
        @test length(ls) == 4
        @test all(is_leaf(acc, node) for node in ls)
        # deterministic: same call returns identical order
        @test ls == leaves(acc, BALANCED_ROOT)
    end

    @testset "leaves — unbalanced (6 leaves)" begin
        acc = lineagegraph_accessor(UNBALANCED_ROOT; children = node -> node.children)
        @test length(leaves(acc, UNBALANCED_ROOT)) == 6
    end

    @testset "leaves — polytomy (4 leaves)" begin
        acc = lineagegraph_accessor(POLYTOMY_ROOT; children = node -> node.children)
        @test length(leaves(acc, POLYTOMY_ROOT)) == 4
    end

    @testset "leaves — single node is its own leaf" begin
        acc = lineagegraph_accessor(SINGLE_ROOT; children = node -> node.children)
        ls  = leaves(acc, SINGLE_ROOT)
        @test length(ls) == 1
        @test ls[1] === SINGLE_ROOT
    end

    @testset "preorder — balanced (7 nodes, rootnode first)" begin
        acc = lineagegraph_accessor(BALANCED_ROOT; children = node -> node.children)
        po  = preorder(acc, BALANCED_ROOT)
        @test length(po) == 7
        @test po[1] === BALANCED_ROOT
        # all leaves appear somewhere in preorder
        ls = leaves(acc, BALANCED_ROOT)
        po_set = Set(po)
        @test all(node ∈ po_set for node in ls)
        # deterministic
        @test po == preorder(acc, BALANCED_ROOT)
    end

    @testset "preorder — single node" begin
        acc = lineagegraph_accessor(SINGLE_ROOT; children = node -> node.children)
        po  = preorder(acc, SINGLE_ROOT)
        @test length(po) == 1
        @test po[1] === SINGLE_ROOT
    end

    @testset "cycle detection — leaves raises ArgumentError" begin
        a = CyclicNode("a", CyclicNode[])
        b = CyclicNode("b", [a])
        push!(a.ch, b)  # a → b → a
        acc = lineagegraph_accessor(a; children = node -> node.ch)
        @test_throws ArgumentError leaves(acc, a)
    end

    @testset "cycle detection — preorder raises ArgumentError" begin
        a = CyclicNode("a", CyclicNode[])
        b = CyclicNode("b", [a])
        push!(a.ch, b)
        acc = lineagegraph_accessor(a; children = node -> node.ch)
        @test_throws ArgumentError preorder(acc, a)
    end

end
