# Tests for Geometry
#
# CairoMakie re-exports all Makie types; import geometric types through it
# since the test environment lists CairoMakie rather than Makie directly.

using CairoMakie: Point2f, Rect2f

# ── Lineage graph fixtures ────────────────────────────────────────────────────

# TestNode is defined in test_Accessors.jl, which runtests.jl includes before
# this file. The GEO_* constants below use unique names to avoid conflicts.

#   root
#   ├── ab
#   │   ├── a
#   │   └── b
#   └── cd
#       ├── c
#       └── d
const GEO_BALANCED = TestNode("root", [
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
const GEO_UNBALANCED = TestNode("root", [
    TestNode("a", TestNode[]),
    TestNode("bc", [TestNode("b", TestNode[]), TestNode("c", TestNode[])]),
    TestNode("def", [
        TestNode("d", TestNode[]),
        TestNode("ef", [TestNode("e", TestNode[]), TestNode("f", TestNode[])]),
    ]),
])

# Root with 4 direct leaf children
const GEO_POLYTOMY = TestNode("root", [
    TestNode("a", TestNode[]),
    TestNode("b", TestNode[]),
    TestNode("c", TestNode[]),
    TestNode("d", TestNode[]),
])

# Single vertex: rootvertex is also the only leaf
const GEO_SINGLE = TestNode("root", TestNode[])

# Helper: build a LineageGraphAccessor with only children
function _acc(rootvertex)
    return lineagegraph_accessor(rootvertex; children = n -> n.children)
end

# ── Tests ──────────────────────────────────────────────────────────────────────

@testset "Geometry" begin

    @testset "LineageGraphGeometry — struct fields and immutability" begin
        vp   = Dict{Any,Point2f}(GEO_SINGLE => Point2f(0, 1))
        ep   = Point2f[]
        lo   = Any[GEO_SINGLE]
        bb   = Rect2f(0, 0, 0, 0)
        geom = LineageGraphGeometry(vp, ep, lo, bb)
        @test geom isa LineageGraphGeometry
        @test geom.vertex_positions === vp
        @test geom.edge_paths === ep
        @test geom.leaf_order === lo
        @test geom.boundingbox === bb
        @test !ismutable(geom)
    end

    @testset "boundingbox — delegates to stored field" begin
        vp   = Dict{Any,Point2f}(GEO_SINGLE => Point2f(0, 1))
        bb   = Rect2f(0, 0, 5, 3)
        geom = LineageGraphGeometry(vp, Point2f[], Any[GEO_SINGLE], bb)
        @test boundingbox(geom) === bb
    end

    # ── :vertexheights ──────────────────────────────────────────────────────────

    @testset "rectangular_layout :vertexheights — balanced (4 leaves)" begin
        acc  = _acc(GEO_BALANCED)
        geom = rectangular_layout(GEO_BALANCED, acc; lineageunits = :vertexheights)
        vp   = geom.vertex_positions

        @test length(vp) == 7

        ls = leaves(acc, GEO_BALANCED)
        @test length(ls) == 4
        for leaf in ls
            @test vp[leaf][1] ≈ 0.0
        end

        root_proc = vp[GEO_BALANCED][1]
        @test root_proc == maximum(vp[v][1] for v in keys(vp))
        @test root_proc > 0.0
    end

    @testset "rectangular_layout :vertexheights — unbalanced (6 leaves)" begin
        acc  = _acc(GEO_UNBALANCED)
        geom = rectangular_layout(GEO_UNBALANCED, acc; lineageunits = :vertexheights)
        vp   = geom.vertex_positions

        ls = leaves(acc, GEO_UNBALANCED)
        @test length(ls) == 6
        for leaf in ls
            @test vp[leaf][1] ≈ 0.0
        end
        @test vp[GEO_UNBALANCED][1] > 0.0
    end

    @testset "rectangular_layout :vertexheights — polytomy (4 leaves)" begin
        acc  = _acc(GEO_POLYTOMY)
        geom = rectangular_layout(GEO_POLYTOMY, acc; lineageunits = :vertexheights)
        vp   = geom.vertex_positions

        ls = leaves(acc, GEO_POLYTOMY)
        @test length(ls) == 4
        for leaf in ls
            @test vp[leaf][1] ≈ 0.0
        end
        @test vp[GEO_POLYTOMY][1] ≈ 1.0
    end

    @testset "rectangular_layout :vertexheights — single leaf" begin
        acc  = _acc(GEO_SINGLE)
        geom = rectangular_layout(GEO_SINGLE, acc; lineageunits = :vertexheights)
        vp   = geom.vertex_positions

        @test length(vp) == 1
        @test vp[GEO_SINGLE][1] ≈ 0.0
    end

    # ── :vertexlevels ───────────────────────────────────────────────────────────

    @testset "rectangular_layout :vertexlevels — balanced (4 leaves)" begin
        acc  = _acc(GEO_BALANCED)
        geom = rectangular_layout(GEO_BALANCED, acc; lineageunits = :vertexlevels)
        vp   = geom.vertex_positions

        @test length(vp) == 7
        @test vp[GEO_BALANCED][1] ≈ 0.0

        ls        = leaves(acc, GEO_BALANCED)
        max_level = maximum(vp[v][1] for v in keys(vp))
        for leaf in ls
            @test vp[leaf][1] ≈ max_level
        end
        @test max_level > 0.0
    end

    @testset "rectangular_layout :vertexlevels — unbalanced (6 leaves)" begin
        acc  = _acc(GEO_UNBALANCED)
        geom = rectangular_layout(GEO_UNBALANCED, acc; lineageunits = :vertexlevels)
        vp   = geom.vertex_positions

        # GEO_UNBALANCED structure (levels):
        #   root  (0) → a (1), bc (1), def (1)
        #   bc    (1) → b (2), c (2)
        #   def   (1) → d (2), ef (2)
        #   ef    (2) → e (3), f (3)
        root = GEO_UNBALANCED
        a    = root.children[1]
        bc   = root.children[2]
        b, c = bc.children[1], bc.children[2]
        def  = root.children[3]
        d    = def.children[1]
        ef   = def.children[2]
        e, f = ef.children[1], ef.children[2]

        @test vp[root][1] ≈ 0.0
        @test vp[a][1]   ≈ 1.0
        @test vp[bc][1]  ≈ 1.0
        @test vp[b][1]   ≈ 2.0
        @test vp[c][1]   ≈ 2.0
        @test vp[def][1] ≈ 1.0
        @test vp[d][1]   ≈ 2.0
        @test vp[ef][1]  ≈ 2.0
        @test vp[e][1]   ≈ 3.0
        @test vp[f][1]   ≈ 3.0
    end

    @testset "rectangular_layout :vertexlevels — polytomy" begin
        acc  = _acc(GEO_POLYTOMY)
        geom = rectangular_layout(GEO_POLYTOMY, acc; lineageunits = :vertexlevels)
        vp   = geom.vertex_positions

        @test vp[GEO_POLYTOMY][1] ≈ 0.0
        ls = leaves(acc, GEO_POLYTOMY)
        for leaf in ls
            @test vp[leaf][1] ≈ 1.0
        end
    end

    @testset "rectangular_layout :vertexlevels — single leaf" begin
        acc  = _acc(GEO_SINGLE)
        geom = rectangular_layout(GEO_SINGLE, acc; lineageunits = :vertexlevels)
        vp   = geom.vertex_positions

        @test length(vp) == 1
        @test vp[GEO_SINGLE][1] ≈ 0.0
    end

    # ── Equal-spacing invariant ─────────────────────────────────────────────────

    @testset "leaf_spacing :equal — balanced, adjacent gaps all 1.0" begin
        acc     = _acc(GEO_BALANCED)
        geom    = rectangular_layout(GEO_BALANCED, acc)
        leaf_ys = sort([geom.vertex_positions[v][2] for v in geom.leaf_order])
        @test all(diff(leaf_ys) .≈ 1.0)
    end

    @testset "leaf_spacing :equal — unbalanced, adjacent gaps all 1.0" begin
        acc     = _acc(GEO_UNBALANCED)
        geom    = rectangular_layout(GEO_UNBALANCED, acc)
        leaf_ys = sort([geom.vertex_positions[v][2] for v in geom.leaf_order])
        @test all(diff(leaf_ys) .≈ 1.0)
    end

    @testset "leaf_spacing :equal — polytomy, adjacent gaps all 1.0" begin
        acc     = _acc(GEO_POLYTOMY)
        geom    = rectangular_layout(GEO_POLYTOMY, acc)
        leaf_ys = sort([geom.vertex_positions[v][2] for v in geom.leaf_order])
        @test all(diff(leaf_ys) .≈ 1.0)
    end

    # ── Real leaf_spacing ───────────────────────────────────────────────────────

    @testset "leaf_spacing Float64 2.5 — adjacent gaps all 2.5" begin
        acc     = _acc(GEO_BALANCED)
        geom    = rectangular_layout(GEO_BALANCED, acc; leaf_spacing = 2.5)
        leaf_ys = sort([geom.vertex_positions[v][2] for v in geom.leaf_order])
        @test all(diff(leaf_ys) .≈ 2.5)
    end

    @testset "leaf_spacing Int — accepted and converted to Float64" begin
        acc     = _acc(GEO_BALANCED)
        geom    = rectangular_layout(GEO_BALANCED, acc; leaf_spacing = 3)
        leaf_ys = sort([geom.vertex_positions[v][2] for v in geom.leaf_order])
        @test all(diff(leaf_ys) .≈ 3.0)
    end

    @testset "leaf_spacing negative raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(GEO_BALANCED, acc; leaf_spacing = -1.0)
        @test_throws ArgumentError rectangular_layout(GEO_BALANCED, acc; leaf_spacing = -1)
    end

    @testset "leaf_spacing zero raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(GEO_BALANCED, acc; leaf_spacing = 0.0)
        @test_throws ArgumentError rectangular_layout(GEO_BALANCED, acc; leaf_spacing = 0)
    end

    # ── boundingbox containment ─────────────────────────────────────────────────

    @testset "boundingbox contains all vertex_positions — balanced :vertexheights" begin
        acc  = _acc(GEO_BALANCED)
        geom = rectangular_layout(GEO_BALANCED, acc)
        bb   = geom.boundingbox
        for (_, p) in geom.vertex_positions
            @test bb.origin[1] <= p[1] <= bb.origin[1] + bb.widths[1]
            @test bb.origin[2] <= p[2] <= bb.origin[2] + bb.widths[2]
        end
    end

    @testset "boundingbox contains all vertex_positions — unbalanced :vertexlevels" begin
        acc  = _acc(GEO_UNBALANCED)
        geom = rectangular_layout(GEO_UNBALANCED, acc; lineageunits = :vertexlevels)
        bb   = geom.boundingbox
        for (_, p) in geom.vertex_positions
            @test bb.origin[1] <= p[1] <= bb.origin[1] + bb.widths[1]
            @test bb.origin[2] <= p[2] <= bb.origin[2] + bb.widths[2]
        end
    end

    @testset "boundingbox contains all vertex_positions — polytomy" begin
        acc  = _acc(GEO_POLYTOMY)
        geom = rectangular_layout(GEO_POLYTOMY, acc)
        bb   = geom.boundingbox
        for (_, p) in geom.vertex_positions
            @test bb.origin[1] <= p[1] <= bb.origin[1] + bb.widths[1]
            @test bb.origin[2] <= p[2] <= bb.origin[2] + bb.widths[2]
        end
    end

    # ── Zero-leaf guard and unsupported lineageunits ────────────────────────────
    #
    # The zero-leaf ArgumentError guard in rectangular_layout is defensive: any
    # acyclic tree traversed by leaves() yields at least one leaf (a vertex whose
    # children iterable is empty is by definition a leaf). The boundary case —
    # exactly one leaf — exercises the guard correctly; it must not raise.

    @testset "single-leaf lineage graph does not raise (boundary: 1 >= 1 leaf)" begin
        acc = _acc(GEO_SINGLE)
        @test rectangular_layout(GEO_SINGLE, acc) isa LineageGraphGeometry
    end

    @testset "unsupported lineageunits raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :nonsense,
        )
    end

end # @testset "Geometry"
