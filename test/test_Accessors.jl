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

# single vertex; it is both rootvertex and the only leaf
const SINGLE_ROOT = TestNode("root", TestNode[])

# mutable struct for constructing cycles
mutable struct CyclicNode
    name::String
    ch::Vector{CyclicNode}
end

# ── Tests ──────────────────────────────────────────────────────────────────────

@testset "Accessors" begin

    @testset "lineagegraph_accessor — construction" begin
        acc = lineagegraph_accessor(BALANCED_ROOT; children = n -> n.children)
        @test acc isa LineageGraphAccessor
        @test acc.children isa Function
        @test acc.children(BALANCED_ROOT) == BALANCED_ROOT.children
        @test acc.edgelength    === nothing
        @test acc.vertexvalue   === nothing
        @test acc.branchingtime === nothing
        @test acc.coalescenceage === nothing
        @test acc.vertexcoords  === nothing
        @test acc.vertexpos     === nothing
    end

    @testset "lineagegraph_accessor — all keyword combinations" begin
        el  = (u, v) -> 1.0
        vv  = n -> n.name
        bt  = n -> 0.0
        ca  = n -> 0.0
        vc  = n -> (0.0, 0.0)
        vp  = n -> (0.0, 0.0)
        acc = lineagegraph_accessor(BALANCED_ROOT;
            children       = n -> n.children,
            edgelength     = el,
            vertexvalue    = vv,
            branchingtime  = bt,
            coalescenceage = ca,
            vertexcoords   = vc,
            vertexpos      = vp,
        )
        @test acc isa LineageGraphAccessor
        @test acc.edgelength     === el
        @test acc.vertexvalue    === vv
        @test acc.branchingtime  === bt
        @test acc.coalescenceage === ca
        @test acc.vertexcoords   === vc
        @test acc.vertexpos      === vp
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
        @test acc.vertexcoords  === nothing
        @test acc.vertexpos     === nothing
    end

    @testset "abstracttrees_accessor — universal fallback accepts any type" begin
        # AbstractTrees.children has a universal fallback returning () for any
        # type without an explicit children method, so any rootvertex is accepted.
        # Such a value is treated as a single leaf.
        struct NoExplicitChildren end
        acc = abstracttrees_accessor(NoExplicitChildren())
        @test acc isa LineageGraphAccessor
        @test is_leaf(acc, NoExplicitChildren())
    end

    @testset "is_leaf" begin
        acc = lineagegraph_accessor(BALANCED_ROOT; children = n -> n.children)
        # leaves return true
        @test is_leaf(acc, TestNode("x", TestNode[]))
        @test is_leaf(acc, SINGLE_ROOT)
        # internal vertices return false
        @test !is_leaf(acc, BALANCED_ROOT)
        @test !is_leaf(acc, BALANCED_ROOT.children[1])
    end

    @testset "leaves — balanced (4 leaves)" begin
        acc = lineagegraph_accessor(BALANCED_ROOT; children = n -> n.children)
        ls  = leaves(acc, BALANCED_ROOT)
        @test length(ls) == 4
        @test all(is_leaf(acc, v) for v in ls)
        # deterministic: same call returns identical order
        @test ls == leaves(acc, BALANCED_ROOT)
    end

    @testset "leaves — unbalanced (6 leaves)" begin
        acc = lineagegraph_accessor(UNBALANCED_ROOT; children = n -> n.children)
        @test length(leaves(acc, UNBALANCED_ROOT)) == 6
    end

    @testset "leaves — polytomy (4 leaves)" begin
        acc = lineagegraph_accessor(POLYTOMY_ROOT; children = n -> n.children)
        @test length(leaves(acc, POLYTOMY_ROOT)) == 4
    end

    @testset "leaves — single vertex is its own leaf" begin
        acc = lineagegraph_accessor(SINGLE_ROOT; children = n -> n.children)
        ls  = leaves(acc, SINGLE_ROOT)
        @test length(ls) == 1
        @test ls[1] === SINGLE_ROOT
    end

    @testset "preorder — balanced (7 vertices, rootvertex first)" begin
        acc = lineagegraph_accessor(BALANCED_ROOT; children = n -> n.children)
        po  = preorder(acc, BALANCED_ROOT)
        @test length(po) == 7
        @test po[1] === BALANCED_ROOT
        # all leaves appear somewhere in preorder
        ls = leaves(acc, BALANCED_ROOT)
        po_set = Set(po)
        @test all(v ∈ po_set for v in ls)
        # deterministic
        @test po == preorder(acc, BALANCED_ROOT)
    end

    @testset "preorder — single vertex" begin
        acc = lineagegraph_accessor(SINGLE_ROOT; children = n -> n.children)
        po  = preorder(acc, SINGLE_ROOT)
        @test length(po) == 1
        @test po[1] === SINGLE_ROOT
    end

    @testset "cycle detection — leaves raises ArgumentError" begin
        a = CyclicNode("a", CyclicNode[])
        b = CyclicNode("b", [a])
        push!(a.ch, b)  # a → b → a
        acc = lineagegraph_accessor(a; children = n -> n.ch)
        @test_throws ArgumentError leaves(acc, a)
    end

    @testset "cycle detection — preorder raises ArgumentError" begin
        a = CyclicNode("a", CyclicNode[])
        b = CyclicNode("b", [a])
        push!(a.ch, b)
        acc = lineagegraph_accessor(a; children = n -> n.ch)
        @test_throws ArgumentError preorder(acc, a)
    end

end
