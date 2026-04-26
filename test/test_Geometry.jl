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

# Single node: rootnode is also the only leaf
const GEO_SINGLE = TestNode("root", TestNode[])

# Helper: build a LineageGraphAccessor with only children
function _acc(rootnode)
    return lineagegraph_accessor(rootnode; children = node -> node.children)
end

# ── Tests ──────────────────────────────────────────────────────────────────────

@testset "Geometry" begin

    @testset "LineageGraphGeometry — struct fields and immutability" begin
        node_pos = Dict{Any,Point2f}(GEO_SINGLE => Point2f(0, 1))
        ep       = Point2f[]
        lo       = Any[GEO_SINGLE]
        bb       = Rect2f(0, 0, 0, 0)
        geom     = LineageGraphGeometry(node_pos, ep, Tuple{Any,Any}[], lo, bb)
        @test geom isa LineageGraphGeometry
        @test geom.node_positions === node_pos
        @test geom.edge_shapes === ep
        @test geom.leaf_order === lo
        @test geom.boundingbox === bb
        @test !ismutable(geom)
    end

    @testset "boundingbox — delegates to stored field" begin
        node_pos = Dict{Any,Point2f}(GEO_SINGLE => Point2f(0, 1))
        bb       = Rect2f(0, 0, 5, 3)
        geom     = LineageGraphGeometry(node_pos, Point2f[], Tuple{Any,Any}[], Any[GEO_SINGLE], bb)
        @test boundingbox(geom) === bb
    end

    # ── :nodeheights ────────────────────────────────────────────────────────────

    @testset "rectangular_layout :nodeheights — balanced (4 leaves)" begin
        acc      = _acc(GEO_BALANCED)
        geom     = rectangular_layout(GEO_BALANCED, acc; lineageunits = :nodeheights)
        node_pos = geom.node_positions

        @test length(node_pos) == 7

        ls = leaves(acc, GEO_BALANCED)
        @test length(ls) == 4
        for leaf in ls
            @test node_pos[leaf][1] ≈ 0.0
        end

        root_proc = node_pos[GEO_BALANCED][1]
        @test root_proc == maximum(node_pos[node][1] for node in keys(node_pos))
        @test root_proc > 0.0
    end

    @testset "rectangular_layout :nodeheights — unbalanced (6 leaves)" begin
        acc      = _acc(GEO_UNBALANCED)
        geom     = rectangular_layout(GEO_UNBALANCED, acc; lineageunits = :nodeheights)
        node_pos = geom.node_positions

        ls = leaves(acc, GEO_UNBALANCED)
        @test length(ls) == 6
        for leaf in ls
            @test node_pos[leaf][1] ≈ 0.0
        end
        @test node_pos[GEO_UNBALANCED][1] > 0.0
    end

    @testset "rectangular_layout :nodeheights — polytomy (4 leaves)" begin
        acc      = _acc(GEO_POLYTOMY)
        geom     = rectangular_layout(GEO_POLYTOMY, acc; lineageunits = :nodeheights)
        node_pos = geom.node_positions

        ls = leaves(acc, GEO_POLYTOMY)
        @test length(ls) == 4
        for leaf in ls
            @test node_pos[leaf][1] ≈ 0.0
        end
        @test node_pos[GEO_POLYTOMY][1] ≈ 1.0
    end

    @testset "rectangular_layout :nodeheights — single leaf" begin
        acc      = _acc(GEO_SINGLE)
        geom     = rectangular_layout(GEO_SINGLE, acc; lineageunits = :nodeheights)
        node_pos = geom.node_positions

        @test length(node_pos) == 1
        @test node_pos[GEO_SINGLE][1] ≈ 0.0
    end

    # ── :nodelevels ─────────────────────────────────────────────────────────────

    @testset "rectangular_layout :nodelevels — balanced (4 leaves)" begin
        acc      = _acc(GEO_BALANCED)
        geom     = rectangular_layout(GEO_BALANCED, acc; lineageunits = :nodelevels)
        node_pos = geom.node_positions

        @test length(node_pos) == 7
        @test node_pos[GEO_BALANCED][1] ≈ 0.0

        ls        = leaves(acc, GEO_BALANCED)
        max_level = maximum(node_pos[node][1] for node in keys(node_pos))
        for leaf in ls
            @test node_pos[leaf][1] ≈ max_level
        end
        @test max_level > 0.0
    end

    @testset "rectangular_layout :nodelevels — unbalanced (6 leaves)" begin
        acc      = _acc(GEO_UNBALANCED)
        geom     = rectangular_layout(GEO_UNBALANCED, acc; lineageunits = :nodelevels)
        node_pos = geom.node_positions

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

        @test node_pos[root][1] ≈ 0.0
        @test node_pos[a][1]   ≈ 1.0
        @test node_pos[bc][1]  ≈ 1.0
        @test node_pos[b][1]   ≈ 2.0
        @test node_pos[c][1]   ≈ 2.0
        @test node_pos[def][1] ≈ 1.0
        @test node_pos[d][1]   ≈ 2.0
        @test node_pos[ef][1]  ≈ 2.0
        @test node_pos[e][1]   ≈ 3.0
        @test node_pos[f][1]   ≈ 3.0
    end

    @testset "rectangular_layout :nodelevels — polytomy" begin
        acc      = _acc(GEO_POLYTOMY)
        geom     = rectangular_layout(GEO_POLYTOMY, acc; lineageunits = :nodelevels)
        node_pos = geom.node_positions

        @test node_pos[GEO_POLYTOMY][1] ≈ 0.0
        ls = leaves(acc, GEO_POLYTOMY)
        for leaf in ls
            @test node_pos[leaf][1] ≈ 1.0
        end
    end

    @testset "rectangular_layout :nodelevels — single leaf" begin
        acc      = _acc(GEO_SINGLE)
        geom     = rectangular_layout(GEO_SINGLE, acc; lineageunits = :nodelevels)
        node_pos = geom.node_positions

        @test length(node_pos) == 1
        @test node_pos[GEO_SINGLE][1] ≈ 0.0
    end

    # ── Equal-spacing invariant ─────────────────────────────────────────────────

    @testset "leaf_spacing :equal — balanced, adjacent gaps all 1.0" begin
        acc      = _acc(GEO_BALANCED)
        geom     = rectangular_layout(GEO_BALANCED, acc)
        leaf_ys  = sort([geom.node_positions[node][2] for node in geom.leaf_order])
        @test all(diff(leaf_ys) .≈ 1.0)
    end

    @testset "leaf_spacing :equal — unbalanced, adjacent gaps all 1.0" begin
        acc      = _acc(GEO_UNBALANCED)
        geom     = rectangular_layout(GEO_UNBALANCED, acc)
        leaf_ys  = sort([geom.node_positions[node][2] for node in geom.leaf_order])
        @test all(diff(leaf_ys) .≈ 1.0)
    end

    @testset "leaf_spacing :equal — polytomy, adjacent gaps all 1.0" begin
        acc      = _acc(GEO_POLYTOMY)
        geom     = rectangular_layout(GEO_POLYTOMY, acc)
        leaf_ys  = sort([geom.node_positions[node][2] for node in geom.leaf_order])
        @test all(diff(leaf_ys) .≈ 1.0)
    end

    # ── Real leaf_spacing ───────────────────────────────────────────────────────

    @testset "leaf_spacing Float64 2.5 — adjacent gaps all 2.5" begin
        acc      = _acc(GEO_BALANCED)
        geom     = rectangular_layout(GEO_BALANCED, acc; leaf_spacing = 2.5)
        leaf_ys  = sort([geom.node_positions[node][2] for node in geom.leaf_order])
        @test all(diff(leaf_ys) .≈ 2.5)
    end

    @testset "leaf_spacing Int — accepted and converted to Float64" begin
        acc      = _acc(GEO_BALANCED)
        geom     = rectangular_layout(GEO_BALANCED, acc; leaf_spacing = 3)
        leaf_ys  = sort([geom.node_positions[node][2] for node in geom.leaf_order])
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

    @testset "boundingbox contains all node_positions — balanced :nodeheights" begin
        acc  = _acc(GEO_BALANCED)
        geom = rectangular_layout(GEO_BALANCED, acc)
        bb   = geom.boundingbox
        for (_, p) in geom.node_positions
            @test bb.origin[1] <= p[1] <= bb.origin[1] + bb.widths[1]
            @test bb.origin[2] <= p[2] <= bb.origin[2] + bb.widths[2]
        end
    end

    @testset "boundingbox contains all node_positions — unbalanced :nodelevels" begin
        acc  = _acc(GEO_UNBALANCED)
        geom = rectangular_layout(GEO_UNBALANCED, acc; lineageunits = :nodelevels)
        bb   = geom.boundingbox
        for (_, p) in geom.node_positions
            @test bb.origin[1] <= p[1] <= bb.origin[1] + bb.widths[1]
            @test bb.origin[2] <= p[2] <= bb.origin[2] + bb.widths[2]
        end
    end

    @testset "boundingbox contains all node_positions — polytomy" begin
        acc  = _acc(GEO_POLYTOMY)
        geom = rectangular_layout(GEO_POLYTOMY, acc)
        bb   = geom.boundingbox
        for (_, p) in geom.node_positions
            @test bb.origin[1] <= p[1] <= bb.origin[1] + bb.widths[1]
            @test bb.origin[2] <= p[2] <= bb.origin[2] + bb.widths[2]
        end
    end

    # ── Zero-leaf guard and unsupported lineageunits ────────────────────────────
    #
    # The zero-leaf ArgumentError guard in rectangular_layout is defensive: any
    # acyclic tree traversed by leaves() yields at least one leaf (a node whose
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

    # ── :edgeweights ────────────────────────────────────────────────────────────

    @testset "rectangular_layout :edgeweights — cumulative sums" begin
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
            children = node -> node.children,
            edgeweight = (src, dst) -> el[(src.name, dst.name)],
        )
        geom     = rectangular_layout(GEO_BALANCED, acc; lineageunits = :edgeweights)
        node_pos = geom.node_positions

        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]

        @test node_pos[root][1] ≈ 0.0
        @test node_pos[ab][1]   ≈ 1.0
        @test node_pos[cd][1]   ≈ 1.0
        @test node_pos[a][1]    ≈ 3.0
        @test node_pos[b][1]    ≈ 3.0
        @test node_pos[c][1]    ≈ 4.0
        @test node_pos[d][1]    ≈ 4.0
    end

    @testset "rectangular_layout :edgeweights — named-tuple (;value,units) return form" begin
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = node -> node.children,
            edgeweight = (src, dst) -> (; value = 2.0, units = :ma),
        )
        geom     = rectangular_layout(GEO_BALANCED, acc; lineageunits = :edgeweights)
        node_pos = geom.node_positions

        root = GEO_BALANCED
        ab   = root.children[1]
        a    = ab.children[1]

        @test node_pos[root][1] ≈ 0.0
        @test node_pos[ab][1]   ≈ 2.0
        @test node_pos[a][1]    ≈ 4.0
    end

    @testset "rectangular_layout :edgeweights — missing edge weight warns and falls back to 1.0" begin
        # Only the ab→a edge returns nothing; all others return 1.0.
        root = GEO_BALANCED
        ab   = root.children[1]
        a    = ab.children[1]
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = node -> node.children,
            edgeweight = (src, dst) -> (src === ab && dst === a) ? nothing : 1.0,
        )
        geom = @test_warn r"fallback" rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :edgeweights,
        )
        # ab→a fell back to 1.0, so a's process coordinate = ab's (1.0) + fallback (1.0) = 2.0
        @test geom.node_positions[a][1] ≈ 2.0
    end

    @testset "rectangular_layout :edgeweights — negative edge weight raises ArgumentError" begin
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = node -> node.children,
            edgeweight = (src, dst) -> -1.0,
        )
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :edgeweights,
        )
    end

    @testset "rectangular_layout :edgeweights — missing accessor raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :edgeweights,
        )
    end

    # ── :branchingtime ──────────────────────────────────────────────────────────

    @testset "rectangular_layout :branchingtime — process coordinates match accessor" begin
        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        bt = Dict(root => 0.0, ab => 5.0, cd => 5.0, a => 10.0, b => 10.0, c => 12.0, d => 12.0)
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = node -> node.children,
            branchingtime = node -> bt[node],
        )
        geom     = rectangular_layout(GEO_BALANCED, acc; lineageunits = :branchingtime)
        node_pos = geom.node_positions

        for (node, expected) in bt
            @test node_pos[node][1] ≈ expected
        end
    end

    @testset "rectangular_layout :branchingtime — missing accessor raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :branchingtime,
        )
    end

    # ── :nodedepths ─────────────────────────────────────────────────────────────

    @testset "rectangular_layout :nodedepths — root at 0, integer depths" begin
        acc      = _acc(GEO_BALANCED)
        geom     = rectangular_layout(GEO_BALANCED, acc; lineageunits = :nodedepths)
        node_pos = geom.node_positions

        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]

        @test node_pos[root][1] ≈ 0.0
        @test node_pos[ab][1]   ≈ 1.0
        @test node_pos[cd][1]   ≈ 1.0
        @test node_pos[a][1]    ≈ 2.0
        @test node_pos[b][1]    ≈ 2.0
        @test node_pos[c][1]    ≈ 2.0
        @test node_pos[d][1]    ≈ 2.0
    end

    @testset "rectangular_layout :nodedepths — unbalanced tree, deepest leaf at max depth" begin
        acc      = _acc(GEO_UNBALANCED)
        geom     = rectangular_layout(GEO_UNBALANCED, acc; lineageunits = :nodedepths)
        node_pos = geom.node_positions

        root = GEO_UNBALANCED
        a    = root.children[1]   # depth 1
        ef   = root.children[3].children[2]  # depth 3
        e    = ef.children[1]    # depth 3

        @test node_pos[root][1] ≈ 0.0
        @test node_pos[a][1]    ≈ 1.0
        @test node_pos[e][1]    ≈ 3.0
    end

    # ── :coalescenceage ─────────────────────────────────────────────────────────

    @testset "rectangular_layout :coalescenceage — ultrametric, leaves at 0" begin
        # GEO_BALANCED: all leaves have coalescenceage 0.
        # Ultrametric: all children of each internal node share the same age.
        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        ca = Dict(root => 3.0, ab => 2.0, cd => 2.0, a => 0.0, b => 0.0, c => 0.0, d => 0.0)
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = node -> node.children,
            coalescenceage = node -> ca[node],
        )
        geom     = rectangular_layout(GEO_BALANCED, acc; lineageunits = :coalescenceage)
        node_pos = geom.node_positions

        for leaf in (a, b, c, d)
            @test node_pos[leaf][1] ≈ 0.0
        end
        @test node_pos[root][1] ≈ 3.0
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
            children = node -> node.children,
            coalescenceage = node -> ca[node],
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
            children = node -> node.children,
            coalescenceage = node -> ca[node],
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
            children = node -> node.children,
            coalescenceage = node -> ca[node],
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

    # ── :nodecoordinates ─────────────────────────────────────────────────────────────

    @testset "rectangular_layout :nodecoordinates — node_positions match accessor" begin
        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        node_coordinates = Dict(
            root => Point2f(0, 2.5),
            ab => Point2f(1, 1.5),
            cd => Point2f(1, 3.5),
            a => Point2f(2, 1.0),
            b => Point2f(2, 2.0),
            c => Point2f(2, 3.0),
            d => Point2f(2, 4.0),
        )
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = node -> node.children,
            nodecoordinates = node -> node_coordinates[node],
        )
        geom     = rectangular_layout(GEO_BALANCED, acc; lineageunits = :nodecoordinates)
        node_pos = geom.node_positions

        for (node, expected) in node_coordinates
            @test node_pos[node] ≈ expected
        end
    end

    @testset "rectangular_layout :nodecoordinates — missing accessor raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :nodecoordinates,
        )
    end

    # ── :nodepos ────────────────────────────────────────────────────────────────

    @testset "rectangular_layout :nodepos — node_positions match accessor" begin
        root = GEO_BALANCED
        ab   = root.children[1]
        cd   = root.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        node_pos_src = Dict(
            root => Point2f(0, 2.5),
            ab => Point2f(10, 15),
            cd => Point2f(10, 35),
            a => Point2f(20, 10),
            b => Point2f(20, 20),
            c => Point2f(20, 30),
            d => Point2f(20, 40),
        )
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = node -> node.children,
            nodepos = node -> node_pos_src[node],
        )
        geom     = rectangular_layout(GEO_BALANCED, acc; lineageunits = :nodepos)
        node_pos = geom.node_positions

        for (node, expected) in node_pos_src
            @test node_pos[node] ≈ expected
        end
    end

    @testset "rectangular_layout :nodepos — missing accessor raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :nodepos,
        )
    end

    # ── Default lineageunits detection ──────────────────────────────────────────

    @testset "default lineageunits — edgeweight present → :edgeweights (root at 0)" begin
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = node -> node.children,
            edgeweight = (src, dst) -> 1.0,
        )
        geom     = rectangular_layout(GEO_BALANCED, acc)  # no lineageunits kwarg
        node_pos = geom.node_positions
        @test node_pos[GEO_BALANCED][1] ≈ 0.0
        ls = leaves(acc, GEO_BALANCED)
        for leaf in ls
            @test node_pos[leaf][1] > 0.0  # leaves at max, not 0
        end
    end

    @testset "default lineageunits — no edgeweight → :nodeheights (leaves at 0)" begin
        acc      = _acc(GEO_BALANCED)
        geom     = rectangular_layout(GEO_BALANCED, acc)  # no lineageunits kwarg
        node_pos = geom.node_positions
        ls       = leaves(acc, GEO_BALANCED)
        for leaf in ls
            @test node_pos[leaf][1] ≈ 0.0
        end
        @test node_pos[GEO_BALANCED][1] > 0.0
    end

    # ── circular_layout ─────────────────────────────────────────────────────────

    @testset "circular_layout" begin

        @testset "equal angular spacing — 4-leaf balanced, gaps of π/2" begin
            acc  = _acc(GEO_BALANCED)
            geom = circular_layout(GEO_BALANCED, acc; lineageunits = :nodelevels)
            ls   = leaves(acc, GEO_BALANCED)
            @test length(ls) == 4
            # Recover angles via atan(y, x); leaves at radius 2 (levels: root=0, ab/cd=1, leaves=2)
            angles = sort([atan(geom.node_positions[node][2], geom.node_positions[node][1]) for node in ls])
            gaps = diff(angles)
            @test all(g -> isapprox(g, π / 2; atol = 1e-6), gaps)
        end

        @testset ":nodeheights — leaves at radial distance 0.0" begin
            acc  = _acc(GEO_BALANCED)
            geom = circular_layout(GEO_BALANCED, acc; lineageunits = :nodeheights)
            ls   = leaves(acc, GEO_BALANCED)
            for leaf in ls
                p = geom.node_positions[leaf]
                @test hypot(p[1], p[2]) ≈ 0.0 atol = 1e-8
            end
        end

        @testset ":nodelevels — rootnode at radial distance 0.0" begin
            acc  = _acc(GEO_BALANCED)
            geom = circular_layout(GEO_BALANCED, acc; lineageunits = :nodelevels)
            p    = geom.node_positions[GEO_BALANCED]
            @test hypot(p[1], p[2]) ≈ 0.0 atol = 1e-8
        end

        @testset "boundingbox encloses all node_positions — balanced :nodelevels" begin
            acc  = _acc(GEO_BALANCED)
            geom = circular_layout(GEO_BALANCED, acc; lineageunits = :nodelevels)
            bb   = geom.boundingbox
            # Use a small tolerance because circular node positions involve
            # trigonometric values (e.g. cos(π/2) ≈ 6e-17 in Float32) that can
            # fall just outside the Float32-precision bounding box.
            atol = 1.0f-6
            for (_, p) in geom.node_positions
                @test bb.origin[1] - atol <= p[1] <= bb.origin[1] + bb.widths[1] + atol
                @test bb.origin[2] - atol <= p[2] <= bb.origin[2] + bb.widths[2] + atol
            end
        end

        @testset "boundingbox encloses all node_positions — unbalanced :nodeheights" begin
            acc  = _acc(GEO_UNBALANCED)
            geom = circular_layout(GEO_UNBALANCED, acc; lineageunits = :nodeheights)
            bb   = geom.boundingbox
            atol = 1.0f-6
            for (_, p) in geom.node_positions
                @test bb.origin[1] - atol <= p[1] <= bb.origin[1] + bb.widths[1] + atol
                @test bb.origin[2] - atol <= p[2] <= bb.origin[2] + bb.widths[2] + atol
            end
        end

        @testset "chord edge shapes — all segment endpoints are finite Point2f" begin
            acc  = _acc(GEO_BALANCED)
            geom = circular_layout(GEO_BALANCED, acc; lineageunits = :nodelevels,
                circular_edge_style = :chord)
            finite_pts = filter(p -> !isnan(p[1]) && !isnan(p[2]), geom.edge_shapes)
            @test !isempty(finite_pts)
            @test all(p -> isfinite(p[1]) && isfinite(p[2]), finite_pts)
        end

        @testset "single-leaf does not raise (boundary: 1 >= 1 leaf)" begin
            acc = _acc(GEO_SINGLE)
            @test circular_layout(GEO_SINGLE, acc) isa LineageGraphGeometry
        end

        @testset "polytomy (4 direct leaves) — root at radius 0 for :nodelevels" begin
            acc  = _acc(GEO_POLYTOMY)
            geom = circular_layout(GEO_POLYTOMY, acc; lineageunits = :nodelevels)
            p    = geom.node_positions[GEO_POLYTOMY]
            @test hypot(p[1], p[2]) ≈ 0.0 atol = 1e-8
            ls = leaves(acc, GEO_POLYTOMY)
            @test length(ls) == 4
        end

        @testset "unsupported circular_edge_style raises ArgumentError" begin
            acc = _acc(GEO_BALANCED)
            @test_throws ArgumentError circular_layout(
                GEO_BALANCED, acc; circular_edge_style = :arc,
            )
        end

        @testset "non-regression: rectangular_layout :nodeheights still correct" begin
            acc  = _acc(GEO_BALANCED)
            geom = rectangular_layout(GEO_BALANCED, acc; lineageunits = :nodeheights)
            ls   = leaves(acc, GEO_BALANCED)
            for leaf in ls
                @test geom.node_positions[leaf][1] ≈ 0.0
            end
            @test geom.node_positions[GEO_BALANCED][1] > 0.0
        end

    end # @testset "circular_layout"

end # @testset "Geometry"
