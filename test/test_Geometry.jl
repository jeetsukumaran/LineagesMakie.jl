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

# Single node: basenode is also the only leaf
const GEO_SINGLE = TestNode("root", TestNode[])

# Helper: build a LineageGraphAccessor with only children
function _acc(basenode)
    return lineagegraph_accessor(basenode; children = node -> node.children)
end

const _GEO_GEOMETRY = LineagesMakie.Geometry
const _GEO_TOPOLOGY = LineagesMakie.Topology
const _GEO_SHARED_DESCENDANT_CONSISTENT_EDGEWEIGHTS = Dict(
    ("root", "left") => 1.0,
    ("root", "right") => 1.0,
    ("left", "shared") => 2.0,
    ("right", "shared") => 2.0,
)
const _GEO_SHARED_DESCENDANT_INCONSISTENT_EDGEWEIGHTS = Dict(
    ("root", "left") => 1.0,
    ("root", "right") => 10.0,
    ("left", "shared") => 2.0,
    ("right", "shared") => 3.0,
)
const _GEO_SHARED_DESCENDANT_CONSISTENT_BRANCHINGTIMES = Dict(
    "root" => 0.0,
    "left" => 1.0,
    "right" => 1.0,
    "shared" => 3.0,
)
const _GEO_SHARED_DESCENDANT_INCONSISTENT_BRANCHINGTIMES = Dict(
    "root" => 0.0,
    "left" => 1.0,
    "right" => 10.0,
    "shared" => 3.0,
)
const _GEO_SHARED_DESCENDANT_CONSISTENT_COALESCENCEAGES = Dict(
    "root" => 3.0,
    "left" => 1.0,
    "right" => 1.0,
    "shared" => 0.0,
)
const _GEO_SHARED_DESCENDANT_INCONSISTENT_COALESCENCEAGES = Dict(
    "root" => 5.0,
    "left" => 3.0,
    "right" => 4.0,
    "shared" => 4.5,
)
const _GEO_SHARED_DESCENDANT_NODECOORDINATES = Dict(
    "root" => Point2f(0, 1),
    "left" => Point2f(1, 2),
    "right" => Point2f(1, 4),
    "shared" => Point2f(2, 3),
)
const _GEO_SHARED_DESCENDANT_NODEPOS = Dict(
    "root" => Point2f(10, 10),
    "left" => Point2f(20, 20),
    "right" => Point2f(20, 40),
    "shared" => Point2f(30, 30),
)

function _dag_nodes()
    root = SHARED_DESCENDANT_DAG
    left = root.children[1]
    right = root.children[2]
    shared = left.children[1]
    return (; root, left, right, shared)
end

function _dag_acc(;
        edgeweights = nothing,
        branchingtimes = nothing,
        coalescenceages = nothing,
        nodecoordinates = nothing,
        nodepos = nothing,
    )
    return lineagegraph_accessor(
        SHARED_DESCENDANT_DAG;
        children = node -> node.children,
        edgeweight = edgeweights === nothing ? nothing :
            (src, dst) -> edgeweights[(src.name, dst.name)],
        branchingtime = branchingtimes === nothing ? nothing :
            node -> branchingtimes[node.name],
        coalescenceage = coalescenceages === nothing ? nothing :
            node -> coalescenceages[node.name],
        nodecoordinates = nodecoordinates === nothing ? nothing :
            node -> nodecoordinates[node.name],
        nodepos = nodepos === nothing ? nothing :
            node -> nodepos[node.name],
    )
end

function _expected_dag_edges(acc)
    topology = _GEO_TOPOLOGY.normalize_topology(acc, SHARED_DESCENDANT_DAG)
    return Tuple{Any, Any}[
        (edge.src.source_node, edge.dst.source_node) for edge in topology.edges
    ]
end

function _assert_edge_contract(geom, expected_edges)
    @test geom.edges == expected_edges
    @test length(geom.edge_shapes) == 4 * length(expected_edges)
    @test count(p -> isnan(p[1]) && isnan(p[2]), geom.edge_shapes) == length(expected_edges)
end

function _assert_direct_edge_shapes(geom)
    for (i, (src, dst)) in enumerate(geom.edges)
        quartet = geom.edge_shapes[(4 * (i - 1) + 1):(4 * i)]
        @test quartet[1] ≈ geom.node_positions[src]
        @test quartet[3] ≈ geom.node_positions[dst]
        @test isnan(quartet[4][1]) && isnan(quartet[4][2])
    end
end

function _captured_error(f)
    try
        f()
        return nothing
    catch err
        return err
    end
end

function _geo_rect_contains(rect::Rect2f, pt; atol::Float32 = 1.0f-6)::Bool
    return rect.origin[1] - atol <= pt[1] <= rect.origin[1] + rect.widths[1] + atol &&
        rect.origin[2] - atol <= pt[2] <= rect.origin[2] + rect.widths[2] + atol
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
        basenode = GEO_UNBALANCED
        a    = basenode.children[1]
        bc   = basenode.children[2]
        b, c = bc.children[1], bc.children[2]
        def  = basenode.children[3]
        d    = def.children[1]
        ef   = def.children[2]
        e, f = ef.children[1], ef.children[2]

        @test node_pos[basenode][1] ≈ 0.0
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

        basenode = GEO_BALANCED
        ab   = basenode.children[1]
        cd   = basenode.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]

        @test node_pos[basenode][1] ≈ 0.0
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

        basenode = GEO_BALANCED
        ab   = basenode.children[1]
        a    = ab.children[1]

        @test node_pos[basenode][1] ≈ 0.0
        @test node_pos[ab][1]   ≈ 2.0
        @test node_pos[a][1]    ≈ 4.0
    end

    @testset "rectangular_layout :edgeweights — missing edge weight warns and falls back to 1.0" begin
        # Only the ab→a edge returns nothing; all others return 1.0.
        basenode = GEO_BALANCED
        ab   = basenode.children[1]
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

    @testset "shared-descendant DAG — DAG-safe rectangular units preserve normalized edges" begin
        nodes = _dag_nodes()
        acc = _dag_acc(
            nodecoordinates = _GEO_SHARED_DESCENDANT_NODECOORDINATES,
            nodepos = _GEO_SHARED_DESCENDANT_NODEPOS,
        )
        topology = _GEO_TOPOLOGY.normalize_topology(acc, SHARED_DESCENDANT_DAG)
        shared_node = _GEO_TOPOLOGY.normalized_node(topology, nodes.shared)
        expected_edges = _expected_dag_edges(acc)

        @test length(_GEO_TOPOLOGY.parent_incidence(topology, shared_node)) == 2
        @test [node.name for node in leaves(acc, SHARED_DESCENDANT_DAG)] == ["shared"]
        @test [node.name for node in preorder(acc, SHARED_DESCENDANT_DAG)] ==
            ["root", "left", "right", "shared"]
        @test expected_edges == Tuple{Any, Any}[
            (nodes.root, nodes.left),
            (nodes.left, nodes.shared),
            (nodes.root, nodes.right),
            (nodes.right, nodes.shared),
        ]

        geom_levels = rectangular_layout(
            SHARED_DESCENDANT_DAG,
            acc;
            lineageunits = :nodelevels,
        )
        _assert_edge_contract(geom_levels, expected_edges)
        @test length(geom_levels.node_positions) == length(topology.node_order)
        @test geom_levels.node_positions[nodes.root][1] ≈ 0.0
        @test geom_levels.node_positions[nodes.left][1] ≈ 1.0
        @test geom_levels.node_positions[nodes.right][1] ≈ 1.0
        @test geom_levels.node_positions[nodes.shared][1] ≈ 2.0
        @test geom_levels.leaf_order == Any[nodes.shared]

        geom_depths = rectangular_layout(
            SHARED_DESCENDANT_DAG,
            acc;
            lineageunits = :nodedepths,
        )
        _assert_edge_contract(geom_depths, expected_edges)
        @test geom_depths.node_positions[nodes.root][1] ≈ 0.0
        @test geom_depths.node_positions[nodes.left][1] ≈ 1.0
        @test geom_depths.node_positions[nodes.right][1] ≈ 1.0
        @test geom_depths.node_positions[nodes.shared][1] ≈ 2.0

        geom_heights = rectangular_layout(
            SHARED_DESCENDANT_DAG,
            acc;
            lineageunits = :nodeheights,
        )
        _assert_edge_contract(geom_heights, expected_edges)
        @test geom_heights.node_positions[nodes.root][1] ≈ 2.0
        @test geom_heights.node_positions[nodes.left][1] ≈ 1.0
        @test geom_heights.node_positions[nodes.right][1] ≈ 1.0
        @test geom_heights.node_positions[nodes.shared][1] ≈ 0.0
    end

    @testset "shared-descendant DAG — explicit-coordinate units preserve supplied positions" begin
        nodes = _dag_nodes()
        acc = _dag_acc(
            nodecoordinates = _GEO_SHARED_DESCENDANT_NODECOORDINATES,
            nodepos = _GEO_SHARED_DESCENDANT_NODEPOS,
        )
        expected_edges = _expected_dag_edges(acc)

        for (layout, lineageunits, expected_positions) in (
                (rectangular_layout, :nodecoordinates, _GEO_SHARED_DESCENDANT_NODECOORDINATES),
                (rectangular_layout, :nodepos, _GEO_SHARED_DESCENDANT_NODEPOS),
                (circular_layout, :nodecoordinates, _GEO_SHARED_DESCENDANT_NODECOORDINATES),
                (circular_layout, :nodepos, _GEO_SHARED_DESCENDANT_NODEPOS),
            )
            geom = layout(
                SHARED_DESCENDANT_DAG,
                acc;
                lineageunits = lineageunits,
            )
            _assert_edge_contract(geom, expected_edges)
            _assert_direct_edge_shapes(geom)
            @test geom.node_positions[nodes.root] ≈ expected_positions["root"]
            @test geom.node_positions[nodes.left] ≈ expected_positions["left"]
            @test geom.node_positions[nodes.right] ≈ expected_positions["right"]
            @test geom.node_positions[nodes.shared] ≈ expected_positions["shared"]
        end
    end

    @testset "shared-descendant DAG — weighted full-network units are explicit and honest" begin
        nodes = _dag_nodes()
        consistent_acc = _dag_acc(
            edgeweights = _GEO_SHARED_DESCENDANT_CONSISTENT_EDGEWEIGHTS,
            branchingtimes = _GEO_SHARED_DESCENDANT_CONSISTENT_BRANCHINGTIMES,
            coalescenceages = _GEO_SHARED_DESCENDANT_CONSISTENT_COALESCENCEAGES,
        )
        expected_edges = _expected_dag_edges(consistent_acc)

        geom_edgeweights = rectangular_layout(
            SHARED_DESCENDANT_DAG,
            consistent_acc;
            lineageunits = :edgeweights,
        )
        _assert_edge_contract(geom_edgeweights, expected_edges)
        @test geom_edgeweights.node_positions[nodes.root][1] ≈ 0.0
        @test geom_edgeweights.node_positions[nodes.left][1] ≈ 1.0
        @test geom_edgeweights.node_positions[nodes.right][1] ≈ 1.0
        @test geom_edgeweights.node_positions[nodes.shared][1] ≈ 3.0

        geom_branchingtime = rectangular_layout(
            SHARED_DESCENDANT_DAG,
            consistent_acc;
            lineageunits = :branchingtime,
        )
        _assert_edge_contract(geom_branchingtime, expected_edges)
        @test geom_branchingtime.node_positions[nodes.root][1] ≈ 0.0
        @test geom_branchingtime.node_positions[nodes.left][1] ≈ 1.0
        @test geom_branchingtime.node_positions[nodes.right][1] ≈ 1.0
        @test geom_branchingtime.node_positions[nodes.shared][1] ≈ 3.0

        geom_coalescenceage = rectangular_layout(
            SHARED_DESCENDANT_DAG,
            consistent_acc;
            lineageunits = :coalescenceage,
        )
        _assert_edge_contract(geom_coalescenceage, expected_edges)
        @test geom_coalescenceage.node_positions[nodes.root][1] ≈ 3.0
        @test geom_coalescenceage.node_positions[nodes.left][1] ≈ 1.0
        @test geom_coalescenceage.node_positions[nodes.right][1] ≈ 1.0
        @test geom_coalescenceage.node_positions[nodes.shared][1] ≈ 0.0

        geom_radial = circular_layout(
            SHARED_DESCENDANT_DAG,
            consistent_acc;
            lineageunits = :edgeweights,
        )
        _assert_edge_contract(geom_radial, expected_edges)
        @test hypot(geom_radial.node_positions[nodes.root]...) ≈ 0.0 atol = 1e-8
        @test hypot(geom_radial.node_positions[nodes.left]...) ≈ 1.0 atol = 1e-6
        @test hypot(geom_radial.node_positions[nodes.right]...) ≈ 1.0 atol = 1e-6
        @test hypot(geom_radial.node_positions[nodes.shared]...) ≈ 3.0 atol = 1e-6

        inconsistent_acc = _dag_acc(
            edgeweights = _GEO_SHARED_DESCENDANT_INCONSISTENT_EDGEWEIGHTS,
            branchingtimes = _GEO_SHARED_DESCENDANT_INCONSISTENT_BRANCHINGTIMES,
            coalescenceages = _GEO_SHARED_DESCENDANT_INCONSISTENT_COALESCENCEAGES,
        )

        edgeweight_err = _captured_error(() -> rectangular_layout(
            SHARED_DESCENDANT_DAG,
            inconsistent_acc;
            lineageunits = :edgeweights,
        ))
        @test edgeweight_err isa ArgumentError
        @test occursin("additive full-network consistency", sprint(showerror, edgeweight_err))
        @test occursin("projected-tree", sprint(showerror, edgeweight_err))

        branchingtime_err = _captured_error(() -> rectangular_layout(
            SHARED_DESCENDANT_DAG,
            inconsistent_acc;
            lineageunits = :branchingtime,
        ))
        @test branchingtime_err isa ArgumentError
        @test occursin("forward full-network-consistent", sprint(showerror, branchingtime_err))
        @test occursin("projected-tree", sprint(showerror, branchingtime_err))

        coalescenceage_err = _captured_error(() -> rectangular_layout(
            SHARED_DESCENDANT_DAG,
            inconsistent_acc;
            lineageunits = :coalescenceage,
        ))
        @test coalescenceage_err isa ArgumentError
        @test occursin("backward full-network-consistent", sprint(showerror, coalescenceage_err))
        @test occursin("projected-tree", sprint(showerror, coalescenceage_err))
    end

    @testset "topology-backed DAG geometry preserves rooted-tree behavior" begin
        acc = lineagegraph_accessor(
            GEO_BALANCED;
            children = node -> node.children,
            edgeweight = (src, dst) -> 1.0,
        )
        @test rectangular_layout(GEO_BALANCED, acc; lineageunits = :edgeweights) isa
            LineageGraphGeometry
        @test circular_layout(GEO_BALANCED, acc; lineageunits = :edgeweights) isa
            LineageGraphGeometry
    end

    # ── :branchingtime ──────────────────────────────────────────────────────────

    @testset "rectangular_layout :branchingtime — process coordinates match accessor" begin
        basenode = GEO_BALANCED
        ab   = basenode.children[1]
        cd   = basenode.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        bt = Dict(basenode =>0.0, ab => 5.0, cd => 5.0, a => 10.0, b => 10.0, c => 12.0, d => 12.0)
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

    @testset "rectangular_layout :nodedepths — basenode at 0, integer depths" begin
        acc      = _acc(GEO_BALANCED)
        geom     = rectangular_layout(GEO_BALANCED, acc; lineageunits = :nodedepths)
        node_pos = geom.node_positions

        basenode = GEO_BALANCED
        ab   = basenode.children[1]
        cd   = basenode.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]

        @test node_pos[basenode][1] ≈ 0.0
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

        basenode = GEO_UNBALANCED
        a    = basenode.children[1]   # depth 1
        ef   = basenode.children[3].children[2]  # depth 3
        e    = ef.children[1]    # depth 3

        @test node_pos[basenode][1] ≈ 0.0
        @test node_pos[a][1]    ≈ 1.0
        @test node_pos[e][1]    ≈ 3.0
    end

    # ── :coalescenceage ─────────────────────────────────────────────────────────

    @testset "rectangular_layout :coalescenceage — ultrametric, leaves at 0" begin
        # GEO_BALANCED: all leaves have coalescenceage 0.
        # Ultrametric: all children of each internal node share the same age.
        basenode = GEO_BALANCED
        ab   = basenode.children[1]
        cd   = basenode.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        ca = Dict(basenode =>3.0, ab => 2.0, cd => 2.0, a => 0.0, b => 0.0, c => 0.0, d => 0.0)
        acc = lineagegraph_accessor(GEO_BALANCED;
            children = node -> node.children,
            coalescenceage = node -> ca[node],
        )
        geom     = rectangular_layout(GEO_BALANCED, acc; lineageunits = :coalescenceage)
        node_pos = geom.node_positions

        for leaf in (a, b, c, d)
            @test node_pos[leaf][1] ≈ 0.0
        end
        @test node_pos[basenode][1] ≈ 3.0
    end

    @testset "rectangular_layout :coalescenceage — non-ultrametric, :error raises ArgumentError" begin
        basenode = GEO_BALANCED
        ab   = basenode.children[1]
        cd   = basenode.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        # ab has children with ages 0.0 and 1.0 → non-ultrametric
        ca = Dict(basenode =>3.0, ab => 2.0, cd => 2.0, a => 0.0, b => 1.0, c => 0.0, d => 0.0)
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
        basenode = GEO_BALANCED
        ab   = basenode.children[1]
        cd   = basenode.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        ca = Dict(basenode =>3.0, ab => 2.0, cd => 2.0, a => 0.0, b => 1.0, c => 0.0, d => 0.0)
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
        basenode = GEO_BALANCED
        ab   = basenode.children[1]
        cd   = basenode.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        ca = Dict(basenode =>3.0, ab => 2.0, cd => 2.0, a => 0.0, b => 1.0, c => 0.0, d => 0.0)
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
        basenode = GEO_BALANCED
        ab   = basenode.children[1]
        cd   = basenode.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        node_coordinates = Dict(
            basenode => Point2f(0, 2.5),
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

    @testset "rectangular_layout :nodecoordinates — leaf_order follows explicit transverse coordinates" begin
        basenode = GEO_BALANCED
        ab = basenode.children[1]
        cd = basenode.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        node_coordinates = Dict(
            basenode => Point2f(0, 25),
            ab => Point2f(1, 15),
            cd => Point2f(1, 35),
            a => Point2f(2, 40),
            b => Point2f(2, 10),
            c => Point2f(2, 30),
            d => Point2f(2, 20),
        )
        acc = lineagegraph_accessor(
            GEO_BALANCED;
            children = node -> node.children,
            nodecoordinates = node -> node_coordinates[node],
        )
        geom = rectangular_layout(GEO_BALANCED, acc; lineageunits = :nodecoordinates)
        expected = ["b", "d", "c", "a"]
        rendered = sort(
            collect(leaves(acc, GEO_BALANCED));
            by = node -> Float64(geom.node_positions[node][2]),
        )
        @test [node.name for node in geom.leaf_order] == expected
        @test [node.name for node in rendered] == expected
    end

    @testset "rectangular_layout :nodecoordinates — missing accessor raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :nodecoordinates,
        )
    end

    # ── :nodepos ────────────────────────────────────────────────────────────────

    @testset "rectangular_layout :nodepos — node_positions match accessor" begin
        basenode = GEO_BALANCED
        ab   = basenode.children[1]
        cd   = basenode.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        node_pos_src = Dict(
            basenode => Point2f(0, 2.5),
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

    @testset "rectangular_layout :nodepos — leaf_order follows explicit transverse coordinates" begin
        basenode = GEO_BALANCED
        ab = basenode.children[1]
        cd = basenode.children[2]
        a, b = ab.children[1], ab.children[2]
        c, d = cd.children[1], cd.children[2]
        node_pos_src = Dict(
            basenode => Point2f(0, 250),
            ab => Point2f(10, 150),
            cd => Point2f(10, 350),
            a => Point2f(20, 400),
            b => Point2f(20, 100),
            c => Point2f(20, 300),
            d => Point2f(20, 200),
        )
        acc = lineagegraph_accessor(
            GEO_BALANCED;
            children = node -> node.children,
            nodepos = node -> node_pos_src[node],
        )
        geom = rectangular_layout(GEO_BALANCED, acc; lineageunits = :nodepos)
        expected = ["b", "d", "c", "a"]
        rendered = sort(
            collect(leaves(acc, GEO_BALANCED));
            by = node -> Float64(geom.node_positions[node][2]),
        )
        @test [node.name for node in geom.leaf_order] == expected
        @test [node.name for node in rendered] == expected
    end

    @testset "rectangular_layout :nodepos — missing accessor raises ArgumentError" begin
        acc = _acc(GEO_BALANCED)
        @test_throws ArgumentError rectangular_layout(
            GEO_BALANCED, acc; lineageunits = :nodepos,
        )
    end

    # ── Default lineageunits detection ──────────────────────────────────────────

    @testset "default lineageunits — edgeweight present → :edgeweights (basenode at 0)" begin
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

        @testset ":nodelevels — basenode at radial distance 0.0" begin
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

        @testset "explicit-coordinate bypasses derive circular leaf_order from rendered angular order" begin
            basenode = GEO_BALANCED
            ab = basenode.children[1]
            cd = basenode.children[2]
            a, b = ab.children[1], ab.children[2]
            c, d = cd.children[1], cd.children[2]
            nodecoordinates = Dict(
                basenode => Point2f(0, 0),
                ab => Point2f(0, 0.35),
                cd => Point2f(0, -0.35),
                a => Point2f(0, 1),
                b => Point2f(0, -1),
                c => Point2f(1, 0),
                d => Point2f(-1, 0),
            )
            nodepos = Dict(
                basenode => Point2f(0, 0),
                ab => Point2f(0, 35),
                cd => Point2f(0, -35),
                a => Point2f(0, 100),
                b => Point2f(0, -100),
                c => Point2f(100, 0),
                d => Point2f(-100, 0),
            )
            expected = ["c", "a", "d", "b"]

            for (lu, accessor_kw) in [
                (:nodecoordinates, (nodecoordinates = node -> nodecoordinates[node],)),
                (:nodepos, (nodepos = node -> nodepos[node],)),
            ]
                acc = lineagegraph_accessor(
                    GEO_BALANCED;
                    children = node -> node.children,
                    accessor_kw...,
                )
                geom = circular_layout(GEO_BALANCED, acc; lineageunits = lu)
                center = Point2f(
                    geom.boundingbox.origin[1] + geom.boundingbox.widths[1] / 2,
                    geom.boundingbox.origin[2] + geom.boundingbox.widths[2] / 2,
                )
                rendered = sort(
                    collect(leaves(acc, GEO_BALANCED));
                    by = node -> begin
                        pt = geom.node_positions[node]
                        angle = atan(Float64(pt[2] - center[2]), Float64(pt[1] - center[1]))
                        angle < 0.0 && (angle += 2.0 * π)
                        angle
                    end,
                )
                @test [node.name for node in geom.leaf_order] == expected
                @test [node.name for node in rendered] == expected
            end
        end

        @testset "plot envelope contains circular nodeheights geometry without redefining boundingbox" begin
            acc = _acc(GEO_BALANCED)
            geom = circular_layout(GEO_BALANCED, acc; lineageunits = :nodeheights)
            plot_bb = _GEO_GEOMETRY._plot_envelope(geom)
            finite_edge_points = [
                pt for pt in geom.edge_shapes if isfinite(pt[1]) && isfinite(pt[2])
            ]
            @test !isempty(finite_edge_points)
            @test any(!_geo_rect_contains(geom.boundingbox, pt) for pt in finite_edge_points)
            for pt in values(geom.node_positions)
                @test _geo_rect_contains(geom.boundingbox, pt)
                @test _geo_rect_contains(plot_bb, pt)
            end
            for pt in finite_edge_points
                @test _geo_rect_contains(plot_bb, pt)
            end
            node_xs = Float32[pt[1] for pt in values(geom.node_positions)]
            node_ys = Float32[pt[2] for pt in values(geom.node_positions)]
            @test geom.boundingbox.origin[1] ≈ minimum(node_xs)
            @test geom.boundingbox.origin[2] ≈ minimum(node_ys)
            @test geom.boundingbox.widths[1] ≈ maximum(node_xs) - minimum(node_xs)
            @test geom.boundingbox.widths[2] ≈ maximum(node_ys) - minimum(node_ys)
            @test plot_bb.widths[1] > geom.boundingbox.widths[1] ||
                plot_bb.widths[2] > geom.boundingbox.widths[2]
        end

        @testset "plot envelope contains all finite circular coalescenceage geometry points" begin
            basenode = GEO_BALANCED
            ab = basenode.children[1]
            cd = basenode.children[2]
            a, b = ab.children[1], ab.children[2]
            c, d = cd.children[1], cd.children[2]
            coalescenceages = Dict(
                basenode => 2.0,
                ab => 1.0,
                cd => 1.0,
                a => 0.0,
                b => 0.0,
                c => 0.0,
                d => 0.0,
            )
            acc = lineagegraph_accessor(
                GEO_BALANCED;
                children = node -> node.children,
                coalescenceage = node -> coalescenceages[node],
            )
            geom = circular_layout(GEO_BALANCED, acc; lineageunits = :coalescenceage)
            plot_bb = _GEO_GEOMETRY._plot_envelope(geom)
            finite_points = Point2f[collect(values(geom.node_positions))...]
            append!(finite_points, [pt for pt in geom.edge_shapes if isfinite(pt[1]) && isfinite(pt[2])])
            @test !isempty(finite_points)
            @test all(pt -> _geo_rect_contains(plot_bb, pt), finite_points)
        end

        @testset "single-leaf does not raise (boundary: 1 >= 1 leaf)" begin
            acc = _acc(GEO_SINGLE)
            @test circular_layout(GEO_SINGLE, acc) isa LineageGraphGeometry
        end

        @testset "polytomy (4 direct leaves) — basenode at radius 0 for :nodelevels" begin
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
