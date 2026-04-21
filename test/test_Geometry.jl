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
        @test geom.edge_shapes === ep
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

    # ── :edgelengths ────────────────────────────────────────────────────────────

    @testset "rectangular_layout :edgelengths — cumulative sums" begin
        # GEO_BALANCED: root → ab (1.0), root → cd (1.0)
        #               ab → a (2.0),  ab → b (2.0)
        #               cd → c (3.0),  cd → d (3.0)
        # Expected branchingtime: root=0, ab=1, cd=1, a=3, b=3, c=4, d=4
        el = Dict(
            ("root", "ab") => 1.0,
            ("root", "cd") => 1.0,
            ("ab", "a") => 2.0,
            ("ab", "b") => 2.0,
            ("cd", "c") => 3.0,
            ("cd", "d") => 3.0,
        )
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = n -> n.children,
            edgelength = (u, v) -> el[(u.name, v.name)],
        )
        geom = rectangular_layout(GEO_BALANCED, acc; lineageunits = :edgelengths)
        vp = geom.vertex_positions

        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]

        @test vp[root][1] ≈ 0.0
        @test vp[ab][1]   ≈ 1.0
        @test vp[cd][1]   ≈ 1.0
        @test vp[a][1]    ≈ 3.0
        @test vp[b][1]    ≈ 3.0
        @test vp[c][1]    ≈ 4.0
        @test vp[d][1]    ≈ 4.0
    end

    @testset "rectangular_layout :edgelengths — named-tuple (;value,units) return form" begin
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = n -> n.children,
            edgelength = (u, v) -> (; value = 2.0, units = :ma),
        )
        geom = rectangular_layout(GEO_BALANCED, acc; lineageunits = :edgelengths)
        vp = geom.vertex_positions

        root = GEO_BALANCED
        ab   = root.children[1]
        a    = ab.children[1]

        @test vp[root][1] ≈ 0.0
        @test vp[ab][1]   ≈ 2.0
        @test vp[a][1]    ≈ 4.0
    end

    @testset "rectangular_layout :edgelengths — missing edge length warns and falls back to 1.0" begin
        # Only the ab→a edge returns nothing; all others return 1.0.
        root = GEO_BALANCED
        ab   = root.children[1]
        a    = ab.children[1]
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = n -> n.children,
            edgelength = (u, v) -> (u === ab && v === a) ? nothing : 1.0,
        )
        geom = @test_warn r"fallback" rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :edgelengths,
        )
        # ab→a fell back to 1.0, so a's process coord = ab's (1.0) + fallback (1.0) = 2.0
        @test geom.vertex_positions[a][1] ≈ 2.0
    end

    @testset "rectangular_layout :edgelengths — negative edge length raises ArgumentError" begin
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = n -> n.children,
            edgelength = (u, v) -> -1.0,
        )
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :edgelengths,
        )
    end

    @testset "rectangular_layout :edgelengths — missing accessor raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :edgelengths,
        )
    end

    # ── :branchingtime ──────────────────────────────────────────────────────────

    @testset "rectangular_layout :branchingtime — process coords match accessor" begin
        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        bt = Dict(root => 0.0, ab => 5.0, cd => 5.0, a => 10.0, b => 10.0, c => 12.0, d => 12.0)
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = n -> n.children,
            branchingtime = v -> bt[v],
        )
        geom = rectangular_layout(GEO_BALANCED, acc; lineageunits = :branchingtime)
        vp = geom.vertex_positions

        for (v, expected) in bt
            @test vp[v][1] ≈ expected
        end
    end

    @testset "rectangular_layout :branchingtime — missing accessor raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :branchingtime,
        )
    end

    # ── :vertexdepths ───────────────────────────────────────────────────────────

    @testset "rectangular_layout :vertexdepths — root at 0, integer depths" begin
        acc  = _acc(GEO_BALANCED)
        geom = rectangular_layout(GEO_BALANCED, acc; lineageunits = :vertexdepths)
        vp   = geom.vertex_positions

        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]

        @test vp[root][1] ≈ 0.0
        @test vp[ab][1]   ≈ 1.0
        @test vp[cd][1]   ≈ 1.0
        @test vp[a][1]    ≈ 2.0
        @test vp[b][1]    ≈ 2.0
        @test vp[c][1]    ≈ 2.0
        @test vp[d][1]    ≈ 2.0
    end

    @testset "rectangular_layout :vertexdepths — unbalanced tree, deepest leaf at max depth" begin
        acc  = _acc(GEO_UNBALANCED)
        geom = rectangular_layout(GEO_UNBALANCED, acc; lineageunits = :vertexdepths)
        vp   = geom.vertex_positions

        root = GEO_UNBALANCED
        a    = root.children[1]   # depth 1
        ef   = root.children[3].children[2]  # depth 3
        e    = ef.children[1]    # depth 3

        @test vp[root][1] ≈ 0.0
        @test vp[a][1]    ≈ 1.0
        @test vp[e][1]    ≈ 3.0
    end

    # ── :coalescenceage ─────────────────────────────────────────────────────────

    @testset "rectangular_layout :coalescenceage — ultrametric, leaves at 0" begin
        # GEO_BALANCED: all leaves have coalescenceage 0.
        # Ultrametric: all children of each internal vertex share the same age.
        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        ca = Dict(root => 3.0, ab => 2.0, cd => 2.0, a => 0.0, b => 0.0, c => 0.0, d => 0.0)
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = n -> n.children,
            coalescenceage = v -> ca[v],
        )
        geom = rectangular_layout(GEO_BALANCED, acc; lineageunits = :coalescenceage)
        vp = geom.vertex_positions

        for leaf in (a, b, c, d)
            @test vp[leaf][1] ≈ 0.0
        end
        @test vp[root][1] ≈ 3.0
    end

    @testset "rectangular_layout :coalescenceage — non-ultrametric, :error raises ArgumentError" begin
        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        # ab has children with ages 0.0 and 1.0 → non-ultrametric
        ca = Dict(root => 3.0, ab => 2.0, cd => 2.0, a => 0.0, b => 1.0, c => 0.0, d => 0.0)
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = n -> n.children,
            coalescenceage = v -> ca[v],
        )
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc;
            lineageunits = :coalescenceage,
            nonultrametric = :error,
        )
    end

    @testset "rectangular_layout :coalescenceage — non-ultrametric, :minimum does not raise" begin
        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        ca = Dict(root => 3.0, ab => 2.0, cd => 2.0, a => 0.0, b => 1.0, c => 0.0, d => 0.0)
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = n -> n.children,
            coalescenceage = v -> ca[v],
        )
        @test rectangular_layout(
            GEO_BALANCED, acc;
            lineageunits = :coalescenceage,
            nonultrametric = :minimum,
        ) isa LineageGraphGeometry
    end

    @testset "rectangular_layout :coalescenceage — non-ultrametric, :maximum does not raise" begin
        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        ca = Dict(root => 3.0, ab => 2.0, cd => 2.0, a => 0.0, b => 1.0, c => 0.0, d => 0.0)
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = n -> n.children,
            coalescenceage = v -> ca[v],
        )
        @test rectangular_layout(
            GEO_BALANCED, acc;
            lineageunits = :coalescenceage,
            nonultrametric = :maximum,
        ) isa LineageGraphGeometry
    end

    @testset "rectangular_layout :coalescenceage — missing accessor raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :coalescenceage,
        )
    end

    # ── :vertexcoords ───────────────────────────────────────────────────────────

    @testset "rectangular_layout :vertexcoords — vertex_positions match accessor" begin
        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        vc = Dict(
            root => Point2f(0, 2.5),
            ab => Point2f(1, 1.5),
            cd => Point2f(1, 3.5),
            a => Point2f(2, 1.0),
            b => Point2f(2, 2.0),
            c => Point2f(2, 3.0),
            d => Point2f(2, 4.0),
        )
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = n -> n.children,
            vertexcoords = v -> vc[v],
        )
        geom = rectangular_layout(GEO_BALANCED, acc; lineageunits = :vertexcoords)
        vp = geom.vertex_positions

        for (v, expected) in vc
            @test vp[v] ≈ expected
        end
    end

    @testset "rectangular_layout :vertexcoords — missing accessor raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :vertexcoords,
        )
    end

    # ── :vertexpos ──────────────────────────────────────────────────────────────

    @testset "rectangular_layout :vertexpos — vertex_positions match accessor" begin
        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        vp_src = Dict(
            root => Point2f(0, 2.5),
            ab => Point2f(10, 15),
            cd => Point2f(10, 35),
            a => Point2f(20, 10),
            b => Point2f(20, 20),
            c => Point2f(20, 30),
            d => Point2f(20, 40),
        )
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = n -> n.children,
            vertexpos = v -> vp_src[v],
        )
        geom = rectangular_layout(GEO_BALANCED, acc; lineageunits = :vertexpos)
        vp = geom.vertex_positions

        for (v, expected) in vp_src
            @test vp[v] ≈ expected
        end
    end

    @testset "rectangular_layout :vertexpos — missing accessor raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :vertexpos,
        )
    end

    # ── Default lineageunits detection ──────────────────────────────────────────

    @testset "default lineageunits — edgelength present → :edgelengths (root at 0)" begin
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = n -> n.children,
            edgelength = (u, v) -> 1.0,
        )
        geom = rectangular_layout(GEO_BALANCED, acc)  # no lineageunits kwarg
        vp = geom.vertex_positions
        @test vp[GEO_BALANCED][1] ≈ 0.0
        ls = leaves(acc, GEO_BALANCED)
        for leaf in ls
            @test vp[leaf][1] > 0.0  # leaves at max, not 0
        end
    end

    @testset "default lineageunits — no edgelength → :vertexheights (leaves at 0)" begin
        acc  = _acc(GEO_BALANCED)
        geom = rectangular_layout(GEO_BALANCED, acc)  # no lineageunits kwarg
        vp   = geom.vertex_positions
        ls   = leaves(acc, GEO_BALANCED)
        for leaf in ls
            @test vp[leaf][1] ≈ 0.0
        end
        @test vp[GEO_BALANCED][1] > 0.0
    end

end # @testset "Geometry"
