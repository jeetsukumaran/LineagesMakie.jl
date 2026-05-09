# Tests for Layers
#
# All tests use real CairoMakie scenes. CairoMakie re-exports all Makie types.

import CairoMakie
const Makie = CairoMakie.Makie
const _LT_GEOMETRY = LineagesMakie.Geometry
using CairoMakie: Figure, Axis
using CairoMakie: colorbuffer
using CairoMakie: Rect2f, Rect2i, Vec2f

if !isdefined(@__MODULE__, :_rt_matching_text_plots)
    include("test_render_helpers.jl")
end

# ── Fixtures ──────────────────────────────────────────────────────────────────

struct LayersTestNode
    name::String
    children::Vector{LayersTestNode}
end

struct LayersDagNode
    name::String
    children::Vector{LayersDagNode}
end

#   root
#   ├── ab
#   │   ├── a
#   │   └── b
#   └── cd
#       ├── c
#       └── d
const _LT_BALANCED_BASENODE = LayersTestNode("root", [
    LayersTestNode("ab", [
        LayersTestNode("a", LayersTestNode[]),
        LayersTestNode("b", LayersTestNode[]),
    ]),
    LayersTestNode("cd", [
        LayersTestNode("c", LayersTestNode[]),
        LayersTestNode("d", LayersTestNode[]),
    ]),
])

const _LT_SHARED_DESCENDANT_DAG = let
    shared = LayersDagNode("shared", LayersDagNode[])
    left = LayersDagNode("left", LayersDagNode[shared])
    right = LayersDagNode("right", LayersDagNode[shared])
    LayersDagNode("root", LayersDagNode[left, right])
end

# ── Shared fixture: rendered axis ─────────────────────────────────────────────

_LT_FIG = Figure(; size = (800, 600))
_LT_AX = Axis(_LT_FIG[1, 1])
colorbuffer(_LT_FIG)

_LT_ACC = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
_LT_ACC_UNIT = lineagegraph_accessor(
    _LT_BALANCED_BASENODE;
    children = node -> node.children,
    edgeweight = (src, dst) -> 1.0,
)
_LT_GEOM = rectangular_layout(_LT_BALANCED_BASENODE, _LT_ACC)
_LT_GEOM_RADIAL = circular_layout(_LT_BALANCED_BASENODE, _LT_ACC_UNIT; lineageunits = :edgeweights)
const _LT_DUPLICATE_EDGE_GEOM = LineageGraphGeometry(
    Dict{Any, Makie.Point2f}(
        :dup_parent => Makie.Point2f(0.0f0, 0.0f0),
        :dup_child => Makie.Point2f(2.0f0, 0.5f0),
        :other_parent => Makie.Point2f(0.0f0, 1.0f0),
        :other_child => Makie.Point2f(2.0f0, 1.5f0),
    ),
    Makie.Point2f[
        Makie.Point2f(0.0f0, 0.0f0),
        Makie.Point2f(1.0f0, 0.0f0),
        Makie.Point2f(2.0f0, 0.0f0),
        Makie.Point2f(NaN32, NaN32),
        Makie.Point2f(0.0f0, 0.5f0),
        Makie.Point2f(1.0f0, 0.5f0),
        Makie.Point2f(2.0f0, 0.5f0),
        Makie.Point2f(NaN32, NaN32),
        Makie.Point2f(0.0f0, 1.0f0),
        Makie.Point2f(1.0f0, 1.0f0),
        Makie.Point2f(2.0f0, 1.5f0),
        Makie.Point2f(NaN32, NaN32),
    ],
    Tuple{Any, Any}[(:dup_parent, :dup_child), (:dup_parent, :dup_child), (:other_parent, :other_child)],
    Any[],
    Rect2f(0.0f0, 0.0f0, 2.0f0, 1.5f0),
)
_LT_NONBASENODE_CLADE = _LT_BALANCED_BASENODE.children[1]

function _lt_dag_accessor()
    return lineagegraph_accessor(_LT_SHARED_DESCENDANT_DAG; children = node -> node.children)
end

function _lt_clade_points(geom::LineageGraphGeometry, acc, mrca)
    pts = [geom.node_positions[node] for node in leaves(acc, mrca)]
    push!(pts, geom.node_positions[mrca])
    return pts
end

function _lt_clade_xspan(geom::LineageGraphGeometry, acc, mrca)::Float32
    pts = _lt_clade_points(geom, acc, mrca)
    xmin = minimum(pt[1] for pt in pts)
    xmax = maximum(pt[1] for pt in pts)
    return Float32(xmax - xmin)
end

function _lt_rect_xmax(rect::Rect2f)::Float32
    return Float32(rect.origin[1] + rect.widths[1])
end

function _lt_rect_ymax(rect::Rect2f)::Float32
    return Float32(rect.origin[2] + rect.widths[2])
end

function _lt_rect_contains(rect::Rect2f, pt)::Bool
    return rect.origin[1] <= pt[1] <= _lt_rect_xmax(rect) &&
        rect.origin[2] <= pt[2] <= _lt_rect_ymax(rect)
end

function _lt_expected_edge_shape_subset(
        geom::LineageGraphGeometry,
        selected_edges,
    )::Vector{Makie.Point2f}
    used_slots = falses(length(geom.edges))
    selected_indices = Int[]
    for edge_selector in selected_edges
        if edge_selector isa Integer
            edge_index = Int(edge_selector)
            used_slots[edge_index] && error("duplicate geometry edge selector in test fixture")
            used_slots[edge_index] = true
            push!(selected_indices, edge_index)
            continue
        end

        resolved_index = nothing
        for (i, edge_key) in enumerate(geom.edges)
            used_slots[i] && continue
            edge_key == edge_selector || continue
            resolved_index = i
            break
        end
        resolved_index === nothing && error("could not resolve expected test edge selector")
        used_slots[resolved_index] = true
        push!(selected_indices, resolved_index)
    end
    sort!(selected_indices)

    shapes = Makie.Point2f[]
    for edge_index in selected_indices
        base = 4 * (edge_index - 1)
        append!(shapes, @view geom.edge_shapes[(base + 1):(base + 4)])
    end
    return shapes
end

function _lt_expected_edge_anchor(points)::Makie.Point2f
    start_pt, mid_pt, end_pt = points
    seg1 = hypot(mid_pt[1] - start_pt[1], mid_pt[2] - start_pt[2])
    seg2 = hypot(end_pt[1] - mid_pt[1], end_pt[2] - mid_pt[2])
    total = seg1 + seg2
    total > 0.0f0 || return mid_pt

    half_length = total / 2.0f0
    if half_length <= seg1 && seg1 > 0.0f0
        t = half_length / seg1
        return Makie.Point2f(
            start_pt[1] + (mid_pt[1] - start_pt[1]) * t,
            start_pt[2] + (mid_pt[2] - start_pt[2]) * t,
        )
    end

    t = seg2 > 0.0f0 ? (half_length - seg1) / seg2 : 0.0f0
    return Makie.Point2f(
        mid_pt[1] + (end_pt[1] - mid_pt[1]) * t,
        mid_pt[2] + (end_pt[2] - mid_pt[2]) * t,
    )
end

# ── Tests ─────────────────────────────────────────────────────────────────────

@testset "Layers" begin

    @testset "EdgeLayer" begin

        @testset "renders without error" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = edgelayer!(ax, geom)
            @test plot_obj isa EdgeLayer
        end

        @testset "visible = false" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = edgelayer!(ax, geom; visible = false)
            @test plot_obj.visible[] == false
        end

        @testset "per-edge color function" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = edgelayer!(ax, geom; color = (src, dst) -> :red)
            colorbuffer(fig)
            @test plot_obj[:resolved_color][] isa AbstractVector
        end

        @testset "linewidth and alpha accepted" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            @test_nowarn edgelayer!(ax, geom; linewidth = 2.0, alpha = 0.5)
        end

        @testset "edge subset helper preserves geometry-owned edge order on rectangular layouts" begin
            selected_edges = Set((_LT_GEOM.edges[4], _LT_GEOM.edges[1]))
            expected_shapes = _lt_expected_edge_shape_subset(_LT_GEOM, selected_edges)
            actual_shapes = LineagesMakie.Layers._edge_shape_subset(_LT_GEOM, selected_edges)

            @test isequal(actual_shapes, expected_shapes)
            @test isequal(actual_shapes[1:4], _LT_GEOM.edge_shapes[1:4])
            @test isequal(actual_shapes[5:8], _LT_GEOM.edge_shapes[13:16])
        end

        @testset "edge label anchor helper follows selected rectangular edge shapes" begin
            selected_edges = (_LT_GEOM.edges[2], _LT_GEOM.edges[5])
            actual_anchors = LineagesMakie.Layers._edge_label_anchor_positions(_LT_GEOM, selected_edges)
            expected_anchors = [
                _lt_expected_edge_anchor(_LT_GEOM.edge_shapes[(4 * (i - 1) + 1):(4 * (i - 1) + 3)])
                for i in (2, 5)
            ]

            @test actual_anchors == expected_anchors
            @test length(actual_anchors) == 2
        end

        @testset "edge subset and anchor helpers stay geometry-owned on radial layouts" begin
            selected_edges = (_LT_GEOM_RADIAL.edges[2], _LT_GEOM_RADIAL.edges[6])
            expected_shapes = _lt_expected_edge_shape_subset(_LT_GEOM_RADIAL, selected_edges)
            actual_shapes = LineagesMakie.Layers._edge_shape_subset(_LT_GEOM_RADIAL, selected_edges)
            actual_anchors = LineagesMakie.Layers._edge_label_anchor_positions(_LT_GEOM_RADIAL, selected_edges)
            expected_anchors = [
                _lt_expected_edge_anchor(_LT_GEOM_RADIAL.edge_shapes[(4 * (i - 1) + 1):(4 * (i - 1) + 3)])
                for i in (2, 6)
            ]

            @test isequal(actual_shapes, expected_shapes)
            @test actual_anchors == expected_anchors
            @test all(pt -> isfinite(pt[1]) && isfinite(pt[2]), actual_anchors)
        end

        @testset "edge helpers keep duplicate endpoint pairs distinct in geometry order" begin
            selected_edges = (_LT_DUPLICATE_EDGE_GEOM.edges[1], _LT_DUPLICATE_EDGE_GEOM.edges[2])
            expected_shapes = _lt_expected_edge_shape_subset(_LT_DUPLICATE_EDGE_GEOM, selected_edges)
            actual_shapes = LineagesMakie.Layers._edge_shape_subset(_LT_DUPLICATE_EDGE_GEOM, selected_edges)
            actual_anchors = LineagesMakie.Layers._edge_label_anchor_positions(_LT_DUPLICATE_EDGE_GEOM, (2, 1))
            expected_anchors = [
                _lt_expected_edge_anchor(_LT_DUPLICATE_EDGE_GEOM.edge_shapes[1:3]),
                _lt_expected_edge_anchor(_LT_DUPLICATE_EDGE_GEOM.edge_shapes[5:7]),
            ]

            @test isequal(actual_shapes, expected_shapes)
            @test isequal(actual_shapes[1:4], _LT_DUPLICATE_EDGE_GEOM.edge_shapes[1:4])
            @test isequal(actual_shapes[5:8], _LT_DUPLICATE_EDGE_GEOM.edge_shapes[5:8])
            @test actual_anchors == expected_anchors
        end

    end

    @testset "NodeLayer" begin

        @testset "renders without error" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = nodelayer!(ax, geom, acc)
            @test plot_obj isa NodeLayer
        end

        @testset "exactly 3 internal nodes" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = nodelayer!(ax, geom, acc)
            colorbuffer(fig)
            # 4-leaf balanced binary tree has 1 basenode + 2 internal nodes = 3 non-leaf nodes
            @test length(plot_obj[:node_pos_data][]) == 3
        end

        @testset "pixel-size stability after viewport change" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = nodelayer!(ax, geom, acc; markersize = 12)
            colorbuffer(fig)
            initial_size = plot_obj.markersize[]
            ax.scene.viewport[] = Rect2i(0, 0, 1200, 900)
            @test plot_obj.markersize[] == initial_size
        end

    end

    @testset "LeafLayer" begin

        @testset "renders without error" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = leaflayer!(ax, geom, acc)
            @test plot_obj isa LeafLayer
        end

        @testset "exactly 4 leaf positions" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = leaflayer!(ax, geom, acc)
            colorbuffer(fig)
            @test length(plot_obj[:leaf_pos_data][]) == 4
        end

        @testset "independence: visible = false on LeafLayer does not affect NodeLayer" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            nl = nodelayer!(ax, geom, acc)
            ll = leaflayer!(ax, geom, acc)
            ll.visible[] = false
            @test nl.visible[] == true
        end

    end

    @testset "LeafLabelLayer" begin

        @testset "renders without error" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = leaflabellayer!(ax, geom, acc; text_func = node -> "label")
            @test plot_obj isa LeafLabelLayer
        end

        @testset "label positions: 4 entries for 4-leaf tree" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = leaflabellayer!(ax, geom, acc; text_func = node -> "x")
            colorbuffer(fig)
            @test length(plot_obj[:leaf_label_positions][]) == 4
        end

        @testset "italic = true encodes italic font in resolved_font" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = leaflabellayer!(ax, geom, acc; italic = true)
            @test plot_obj[:resolved_font][] == :italic
        end

        @testset "visible = false" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = leaflabellayer!(ax, geom, acc; visible = false)
            @test plot_obj.visible[] == false
        end

        @testset "pixel offset: positions update reactively after viewport change" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = leaflabellayer!(ax, geom, acc; offset = Vec2f(10, 0))
            colorbuffer(fig)
            ax.scene.viewport[] = Rect2i(0, 0, 1200, 900)
            positions_after = plot_obj[:leaf_label_positions][]
            # Positions Observable must still hold exactly 4 entries after resize.
            @test length(positions_after) == 4
        end

        @testset "rectangular leaf labels have blockscene pixel positions after layout" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            plot_obj = leaflabellayer!(ax, _LT_GEOM, _LT_ACC; text_func = node -> string(node.name))
            colorbuffer(fig)
            positions = plot_obj[:leaf_label_positions][]
            @test !isempty(positions)
            @test all(pt -> isfinite(pt[1]) && isfinite(pt[2]), positions)
        end

        @testset "radial leaf labels use blockscene pixel positions and mixed left/right alignments" begin
            fig = Figure(; size = (500, 500))
            ax = Axis(fig[1, 1])
            geom = circular_layout(_LT_BALANCED_BASENODE, _LT_ACC_UNIT; lineageunits = :edgeweights)
            plot_obj = leaflabellayer!(
                ax,
                geom,
                _LT_ACC_UNIT;
                text_func = node -> string(node.name),
                lineage_orientation = :radial,
            )
            colorbuffer(fig)
            positions = plot_obj[:leaf_label_positions][]
            aligns = plot_obj[:leaf_label_aligns][]
            @test !isempty(positions)
            @test all(pt -> isfinite(pt[1]) && isfinite(pt[2]), positions)
            @test any(a -> a[1] === :left, aligns)
            @test any(a -> a[1] === :right, aligns)
        end

        @testset "clade labels and leaf labels coexist without empty geometry" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            lp = lineageplot!(
                ax,
                _LT_BALANCED_BASENODE,
                _LT_ACC;
                leaf_label_func = node -> string(node.name),
                clade_nodes = [_LT_BALANCED_BASENODE],
                clade_label_func = node -> "basenode",
            )
            colorbuffer(fig)
            ll = only(filter(p -> p isa LeafLabelLayer, lp.plots))
            cll = only(filter(p -> p isa CladeLabelLayer, lp.plots))
            @test !isempty(ll[:leaf_label_positions][])
            @test !isempty(cll[:bracket_label_pixel_positions][])
        end

        @testset "standalone LineagePlot honors reversed rectangular embeddings in geometry" begin
            fig = Figure(; size = (500, 350))
            ax = Axis(fig[1, 1])
            lp = lineageplot!(
                ax,
                _LT_BALANCED_BASENODE,
                _LT_ACC_UNIT;
                lineageunits = :edgeweights,
                lineage_orientation = :top_to_bottom,
            )
            colorbuffer(fig)

            geom = lp[:computed_geom][]
            root_pos = geom.node_positions[_LT_BALANCED_BASENODE]
            leaf_pos = geom.node_positions[_LT_BALANCED_BASENODE.children[1].children[1]]
            @test root_pos[2] > leaf_pos[2]

            fig2 = Figure(; size = (500, 350))
            ax2 = Axis(fig2[1, 1])
            lp2 = lineageplot!(
                ax2,
                _LT_BALANCED_BASENODE,
                _LT_ACC_UNIT;
                lineageunits = :edgeweights,
                lineage_orientation = :right_to_left,
            )
            colorbuffer(fig2)

            geom2 = lp2[:computed_geom][]
            root_pos2 = geom2.node_positions[_LT_BALANCED_BASENODE]
            leaf_pos2 = geom2.node_positions[_LT_BALANCED_BASENODE.children[1].children[1]]
            @test root_pos2[1] > leaf_pos2[1]
        end

        @testset "LineageAxis leaf and clade labels consume shared lane anchors" begin
            fig = Figure(; size = (500, 350))
            lax = LineageAxis(fig[1, 1])
            lp = lineageplot!(
                lax,
                _LT_BALANCED_BASENODE,
                _LT_ACC_UNIT;
                lineageunits = :edgeweights,
                leaf_label_func = node -> "species_" * string(node.name),
                clade_nodes = [_LT_NONBASENODE_CLADE],
                clade_label_func = node -> "clade_" * string(node.name),
            )
            colorbuffer(fig)

            layout = lax._decoration_layout[]
            ll = only(filter(p -> p isa LeafLabelLayer, lp.plots))
            cll = only(filter(p -> p isa CladeLabelLayer, lp.plots))

            @test all(
                pos -> isapprox(pos[1], layout.leaf_label_anchor_x; atol = 1.0f-3),
                ll[:leaf_label_positions][],
            )

            bracket_xs = unique(Float32[pt[1] for pt in cll[:bracket_pixel_shapes][] if isfinite(pt[1])])
            @test any(x -> isapprox(x, layout.clade_bracket_x; atol = 1.0f-3), bracket_xs)
            @test all(
                pos -> isapprox(pos[1], layout.clade_label_anchor_x; atol = 1.0f-3),
                cll[:bracket_label_pixel_positions][],
            )
        end

        @testset "LineageAxis shared lanes mirror on the left side" begin
            fig = Figure(; size = (500, 350))
            lax = LineageAxis(fig[1, 1]; lineage_orientation = :right_to_left)
            lp = lineageplot!(
                lax,
                _LT_BALANCED_BASENODE,
                _LT_ACC_UNIT;
                lineageunits = :edgeweights,
                leaf_label_func = node -> "species_" * string(node.name),
                clade_nodes = [_LT_NONBASENODE_CLADE],
                clade_label_func = node -> "clade_" * string(node.name),
            )
            colorbuffer(fig)

            layout = lax._decoration_layout[]
            ll = only(filter(p -> p isa LeafLabelLayer, lp.plots))
            cll = only(filter(p -> p isa CladeLabelLayer, lp.plots))

            @test all(
                pos -> isapprox(pos[1], layout.leaf_label_anchor_x; atol = 1.0f-3),
                ll[:leaf_label_positions][],
            )
            @test all(
                pos -> isapprox(pos[1], layout.clade_label_anchor_x; atol = 1.0f-3),
                cll[:bracket_label_pixel_positions][],
            )
            @test layout.clade_label_anchor_x < layout.clade_bracket_x < layout.leaf_label_anchor_x
        end

        @testset "LineageAxis shared lanes transpose to the top side" begin
            fig = Figure(; size = (500, 350))
            lax = LineageAxis(fig[1, 1]; lineage_orientation = :bottom_to_top)
            lp = lineageplot!(
                lax,
                _LT_BALANCED_BASENODE,
                _LT_ACC_UNIT;
                lineageunits = :edgeweights,
                leaf_label_func = node -> "species_" * string(node.name),
                clade_nodes = [_LT_NONBASENODE_CLADE],
                clade_label_func = node -> "clade_" * string(node.name),
            )
            colorbuffer(fig)

            layout = lax._decoration_layout[]
            ll = only(filter(p -> p isa LeafLabelLayer, lp.plots))
            cll = only(filter(p -> p isa CladeLabelLayer, lp.plots))

            @test all(
                pos -> isapprox(pos[2], layout.leaf_label_anchor_y; atol = 1.0f-3),
                ll[:leaf_label_positions][],
            )

            bracket_ys = unique(Float32[pt[2] for pt in cll[:bracket_pixel_shapes][] if isfinite(pt[2])])
            @test any(y -> isapprox(y, layout.clade_bracket_y; atol = 1.0f-3), bracket_ys)
            @test all(
                pos -> isapprox(pos[2], layout.clade_label_anchor_y; atol = 1.0f-3),
                cll[:bracket_label_pixel_positions][],
            )
            @test layout.leaf_label_anchor_y < layout.clade_bracket_y < layout.clade_label_anchor_y
        end

        @testset "LineageAxis shared lanes transpose to the bottom side" begin
            fig = Figure(; size = (500, 350))
            lax = LineageAxis(fig[1, 1]; lineage_orientation = :top_to_bottom)
            lp = lineageplot!(
                lax,
                _LT_BALANCED_BASENODE,
                _LT_ACC_UNIT;
                lineageunits = :edgeweights,
                leaf_label_func = node -> "species_" * string(node.name),
                clade_nodes = [_LT_NONBASENODE_CLADE],
                clade_label_func = node -> "clade_" * string(node.name),
            )
            colorbuffer(fig)

            layout = lax._decoration_layout[]
            ll = only(filter(p -> p isa LeafLabelLayer, lp.plots))
            cll = only(filter(p -> p isa CladeLabelLayer, lp.plots))

            @test all(
                pos -> isapprox(pos[2], layout.leaf_label_anchor_y; atol = 1.0f-3),
                ll[:leaf_label_positions][],
            )

            bracket_ys = unique(Float32[pt[2] for pt in cll[:bracket_pixel_shapes][] if isfinite(pt[2])])
            @test any(y -> isapprox(y, layout.clade_bracket_y; atol = 1.0f-3), bracket_ys)
            @test all(
                pos -> isapprox(pos[2], layout.clade_label_anchor_y; atol = 1.0f-3),
                cll[:bracket_label_pixel_positions][],
            )
            @test layout.leaf_label_anchor_y > layout.clade_bracket_y > layout.clade_label_anchor_y
        end

        @testset "top-to-bottom rendered label bboxes stay non-overlapping and visible" begin
            fig = Figure(; size = (700, 500))
            lax = LineageAxis(fig[1, 1]; lineage_orientation = :top_to_bottom)
            lp = lineageplot!(
                lax,
                _LT_BALANCED_BASENODE,
                _LT_ACC_UNIT;
                lineageunits = :edgeweights,
                leaf_label_func = node -> "species_" * string(node.name),
                clade_nodes = [_LT_BALANCED_BASENODE.children[1], _LT_BALANCED_BASENODE.children[2]],
                clade_label_func = node -> "clade_" * string(node.name),
            )
            colorbuffer(fig)

            ll = only(filter(p -> p isa LeafLabelLayer, lp.plots))
            cll = only(filter(p -> p isa CladeLabelLayer, lp.plots))

            leaf_text_plot = _rt_only_text_plot(lax.blockscene, ll[:leaf_label_strings][])
            clade_text_plot = _rt_only_text_plot(lax.blockscene, cll[:bracket_label_strings][])

            leaf_rects = _rt_string_bbox_ranges(leaf_text_plot)
            clade_rects = _rt_string_bbox_ranges(clade_text_plot)

            @test length(leaf_rects) == length(ll[:leaf_label_strings][])
            @test length(clade_rects) == length(cll[:bracket_label_strings][])
            @test _rt_rects_all_nonoverlapping(leaf_rects)
            @test _rt_rects_all_nonoverlapping(clade_rects)
            @test _rt_rects_collections_disjoint(leaf_rects, clade_rects)
            @test _rt_rects_within_viewport(leaf_rects, lax.blockscene)
            @test _rt_rects_within_viewport(clade_rects, lax.blockscene)
        end

    end

    @testset "NodeLabelLayer" begin

        @testset "renders without error" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = nodelabellayer!(ax, geom, acc)
            @test plot_obj isa NodeLabelLayer
        end

        @testset "threshold = node -> false: zero labels" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = nodelabellayer!(ax, geom, acc; threshold = node -> false)
            colorbuffer(fig)
            @test length(plot_obj[:node_label_strings][]) == 0
        end

        @testset "threshold = node -> true: all 7 nodes labelled" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            # 4-leaf balanced tree has 3 internal + 4 leaf = 7 nodes total.
            plot_obj = nodelabellayer!(
                ax,
                geom,
                acc;
                value_func = node -> "x",
                threshold = node -> true,
            )
            colorbuffer(fig)
            @test length(plot_obj[:node_label_strings][]) == 7
        end

        @testset "value_func returning non-renderable type raises error at plot time" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            # Makie's ComputeGraph wraps map! errors in ResolveException, so we
            # match by message content. The cause is an ArgumentError naming
            # the node and the non-renderable type.
            @test_throws r"cannot be rendered as text" nodelabellayer!(
                ax,
                geom,
                acc;
                value_func = node -> Dict(),
                threshold  = node -> true,
            )
        end

        @testset "visible = false" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = nodelabellayer!(ax, geom, acc; visible = false)
            @test plot_obj.visible[] == false
        end

        @testset ":toward_parent rejects shared-parent DAG displays" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = _lt_dag_accessor()
            geom = rectangular_layout(_LT_SHARED_DESCENDANT_DAG, acc)
            @test_throws r"NodeLabelLayer\(position = :toward_parent\).*rooted-tree or explicit tree-view.*shared-parent lineage graphs" nodelabellayer!(
                ax,
                geom,
                acc;
                value_func = node -> node.name,
                threshold = node -> true,
                position = :toward_parent,
            )
        end

        @testset ":toward_parent remains green on rooted trees" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = nodelabellayer!(
                ax,
                geom,
                acc;
                value_func = node -> node.name,
                threshold = node -> node === _LT_NONBASENODE_CLADE,
                position = :toward_parent,
            )
            colorbuffer(fig)
            @test length(plot_obj[:node_label_positions][]) == 1
            @test only(plot_obj[:node_label_positions][]) != geom.node_positions[_LT_NONBASENODE_CLADE]
        end

    end

    @testset "CladeHighlightLayer" begin

        @testset "renders without error" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = cladehighlightlayer!(ax, geom, acc; clade_nodes = [_LT_BALANCED_BASENODE])
            @test plot_obj isa CladeHighlightLayer
        end

        @testset "empty clade_nodes produces empty highlight_rects" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = cladehighlightlayer!(ax, geom, acc; clade_nodes = [])
            colorbuffer(fig)
            @test isempty(plot_obj[:highlight_rects][])
        end

        @testset "one MRCA produces exactly one highlight rect" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = cladehighlightlayer!(ax, geom, acc; clade_nodes = [_LT_BALANCED_BASENODE])
            colorbuffer(fig)
            @test length(plot_obj[:highlight_rects][]) == 1
        end

        @testset "highlight rect encloses all leaf positions for the basenode clade" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = cladehighlightlayer!(ax, geom, acc; clade_nodes = [_LT_BALANCED_BASENODE])
            colorbuffer(fig)
            rect = plot_obj[:highlight_rects][][1]
            for node in geom.leaf_order
                pos = geom.node_positions[node]
                @test pos[1] >= rect.origin[1]
                @test pos[1] <= rect.origin[1] + rect.widths[1]
                @test pos[2] >= rect.origin[2]
                @test pos[2] <= rect.origin[2] + rect.widths[2]
            end
        end

        @testset "visible = false accepted" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = cladehighlightlayer!(ax, geom, acc; visible = false)
            @test plot_obj.visible[] == false
        end

        @testset "clade_nodes reject shared-parent DAG displays" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = _lt_dag_accessor()
            geom = rectangular_layout(_LT_SHARED_DESCENDANT_DAG, acc)
            @test_throws r"CladeHighlightLayer\(clade_nodes = \.\.\.\).*rooted-tree or explicit tree-view.*shared-parent lineage graphs" cladehighlightlayer!(
                ax,
                geom,
                acc;
                clade_nodes = [_LT_SHARED_DESCENDANT_DAG],
            )
        end

        @testset "non-basenode-clade highlight remains local after layout" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(
                _LT_BALANCED_BASENODE;
                children = node -> node.children,
                edgeweight = (src, dst) -> 1.0,
            )
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc; lineageunits = :edgeweights)
            plot_obj = cladehighlightlayer!(ax, geom, acc; clade_nodes = [_LT_NONBASENODE_CLADE])
            colorbuffer(fig)

            rect = only(plot_obj[:highlight_rects][])
            raw_span = _lt_clade_xspan(geom, acc, _LT_NONBASENODE_CLADE)
            full_span = Float32(geom.boundingbox.widths[1])

            @test rect.widths[1] >= raw_span
            @test rect.widths[1] < full_span

            for pt in _lt_clade_points(geom, acc, _LT_NONBASENODE_CLADE)
                @test _lt_rect_contains(rect, pt)
            end

            outside_leaves = [
                geom.node_positions[node] for node in geom.leaf_order
                if !(node in collect(leaves(acc, _LT_NONBASENODE_CLADE)))
            ]
            @test any(pt -> !_lt_rect_contains(rect, pt), outside_leaves)
        end

        @testset "highlight geometry remains local across initial viewport resolution" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(
                _LT_BALANCED_BASENODE;
                children = node -> node.children,
                edgeweight = (src, dst) -> 1.0,
            )
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc; lineageunits = :edgeweights)
            plot_obj = cladehighlightlayer!(ax, geom, acc; clade_nodes = [_LT_NONBASENODE_CLADE])
            raw_span = _lt_clade_xspan(geom, acc, _LT_NONBASENODE_CLADE)
            full_span = Float32(geom.boundingbox.widths[1])
            initial_viewport = ax.scene.viewport[]
            initial_degenerate = any(iszero, Makie.widths(initial_viewport))
            rect_initial = only(plot_obj[:highlight_rects][])
            initial_width = Float32(rect_initial.widths[1])
            @test initial_width >= raw_span
            @test initial_width < full_span

            colorbuffer(fig)
            rect_resolved = only(plot_obj[:highlight_rects][])
            resolved_width = Float32(rect_resolved.widths[1])
            @test resolved_width >= raw_span
            @test resolved_width < full_span
            if initial_degenerate
                @test resolved_width != initial_width
            end
        end

    end

    @testset "NodeGroupHighlightLayer" begin

        @testset "renders without error on shared-parent DAG displays" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = _lt_dag_accessor()
            geom = rectangular_layout(_LT_SHARED_DESCENDANT_DAG, acc)
            plot_obj = nodegrouphighlightlayer!(
                ax,
                geom,
                acc;
                group_nodes = _LT_SHARED_DESCENDANT_DAG.children,
            )
            @test plot_obj isa NodeGroupHighlightLayer
        end

        @testset "exact group highlight stays local rather than expanding to the full DAG" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = _lt_dag_accessor()
            geom = rectangular_layout(_LT_SHARED_DESCENDANT_DAG, acc)
            plot_obj = nodegrouphighlightlayer!(
                ax,
                geom,
                acc;
                group_nodes = _LT_SHARED_DESCENDANT_DAG.children,
            )
            colorbuffer(fig)

            rect = only(plot_obj[:highlight_rects][])
            full_span = Float32(geom.boundingbox.widths[1])

            @test rect.widths[1] < full_span
            for node in _LT_SHARED_DESCENDANT_DAG.children
                @test _lt_rect_contains(rect, geom.node_positions[node])
            end
            @test !_lt_rect_contains(rect, geom.node_positions[_LT_SHARED_DESCENDANT_DAG])
            @test !_lt_rect_contains(rect, geom.node_positions[_LT_SHARED_DESCENDANT_DAG.children[1].children[1]])
        end

    end

    @testset "NodeGroupLabelLayer" begin

        @testset "renders without error on shared-parent DAG displays" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = _lt_dag_accessor()
            geom = rectangular_layout(_LT_SHARED_DESCENDANT_DAG, acc)
            plot_obj = nodegrouplabellayer!(
                ax,
                geom,
                acc;
                group_nodes = _LT_SHARED_DESCENDANT_DAG.children,
                label_func = nodes -> join(String[node.name for node in nodes], " + "),
            )
            @test plot_obj isa NodeGroupLabelLayer
        end

        @testset "label_func receives the explicit node group" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = _lt_dag_accessor()
            geom = rectangular_layout(_LT_SHARED_DESCENDANT_DAG, acc)
            plot_obj = nodegrouplabellayer!(
                ax,
                geom,
                acc;
                group_nodes = _LT_SHARED_DESCENDANT_DAG.children,
                label_func = nodes -> join(String[node.name for node in nodes], " + "),
            )
            colorbuffer(fig)

            @test plot_obj[:bracket_label_strings][] == ["left + right"]
            @test length(plot_obj[:bracket_label_positions][]) == 1
            @test only(plot_obj[:bracket_label_positions][])[1] >
                maximum(geom.node_positions[node][1] for node in _LT_SHARED_DESCENDANT_DAG.children)
        end

        @testset "empty resolved labels suppress bracket rendering" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = _lt_dag_accessor()
            geom = rectangular_layout(_LT_SHARED_DESCENDANT_DAG, acc)
            plot_obj = nodegrouplabellayer!(
                ax,
                geom,
                acc;
                group_nodes = _LT_SHARED_DESCENDANT_DAG.children,
                label_func = nodes -> "",
            )
            colorbuffer(fig)

            @test isempty(plot_obj[:bracket_shapes][])
            @test isempty(plot_obj[:bracket_pixel_shapes][])
            @test isempty(plot_obj[:bracket_label_positions][])
            @test isempty(plot_obj[:bracket_label_pixel_positions][])
            @test plot_obj[:bracket_label_strings][] == String[]
        end

    end

    @testset "CladeLabelLayer" begin

        @testset "renders without error" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = cladelabellayer!(
                ax,
                geom,
                acc;
                clade_nodes = [_LT_BALANCED_BASENODE],
                label_func = node -> "Clade A",
            )
            @test plot_obj isa CladeLabelLayer
        end

        @testset "label_func text content appears in bracket_label_strings" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = cladelabellayer!(
                ax,
                geom,
                acc;
                clade_nodes = [_LT_BALANCED_BASENODE],
                label_func = node -> "Clade A",
            )
            colorbuffer(fig)
            strings = plot_obj[:bracket_label_strings][]
            @test any(s -> occursin("Clade A", s), strings)
        end

        @testset "empty clade_nodes produces no bracket shapes" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = cladelabellayer!(ax, geom, acc; clade_nodes = [])
            colorbuffer(fig)
            @test isempty(plot_obj[:bracket_shapes][])
        end

        @testset "visible = false accepted" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = cladelabellayer!(ax, geom, acc; visible = false)
            @test plot_obj.visible[] == false
        end

        @testset "clade_nodes reject shared-parent DAG displays" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = _lt_dag_accessor()
            geom = rectangular_layout(_LT_SHARED_DESCENDANT_DAG, acc)
            @test_throws r"CladeLabelLayer\(clade_nodes = \.\.\.\).*rooted-tree or explicit tree-view.*shared-parent lineage graphs" cladelabellayer!(
                ax,
                geom,
                acc;
                clade_nodes = [_LT_SHARED_DESCENDANT_DAG],
                label_func = node -> node.name,
            )
        end

        @testset "bracket renders in decoration scene (not clipped)" begin
            fig = Figure(; size = (400, 300))
            ax  = Axis(fig[1, 1])
            lp  = lineageplot!(ax, _LT_BALANCED_BASENODE, _LT_ACC;
                               clade_nodes = [_LT_BALANCED_BASENODE],
                               clade_label_func = node -> "basenode")
            colorbuffer(fig)   # force layout resolution so viewport is non-zero
            cll = only(filter(p -> p isa CladeLabelLayer, lp.plots))
            # bracket_pixel_shapes must be non-empty after layout.
            @test !isempty(cll[:bracket_pixel_shapes][])
            # All non-NaN pixel positions must be finite.
            for pt in cll[:bracket_pixel_shapes][]
                isnan(pt[1]) && continue
                @test isfinite(pt[1]) && isfinite(pt[2])
            end
        end

        @testset "bracket label pixel positions non-empty after layout" begin
            fig = Figure(; size = (400, 300))
            ax  = Axis(fig[1, 1])
            lp  = lineageplot!(ax, _LT_BALANCED_BASENODE, _LT_ACC;
                               clade_nodes = [_LT_BALANCED_BASENODE],
                               clade_label_func = node -> "basenode")
            colorbuffer(fig)
            cll = only(filter(p -> p isa CladeLabelLayer, lp.plots))
            @test !isempty(cll[:bracket_label_pixel_positions][])
        end

    end

    @testset "ScaleBarLayer" begin

        @testset "visible defaults to false for :nodeheights" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = scalebarlayer!(ax, geom, acc, :nodeheights)
            @test plot_obj[:resolved_visible][] == false
        end

        @testset "visible defaults to false for :edgeweights when label is empty" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = scalebarlayer!(ax, geom, acc, :edgeweights)
            @test plot_obj[:resolved_visible][] == false
        end

        @testset "visible defaults to true for :edgeweights when label is present" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = scalebarlayer!(ax, geom, acc, :edgeweights; label = "1 unit")
            @test plot_obj[:resolved_visible][] == true
        end

        @testset "explicit visible = true overrides :nodeheights default" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = scalebarlayer!(ax, geom, acc, :nodeheights; scalebar_auto_visible = true)
            @test plot_obj[:resolved_visible][] == true
        end

        @testset "scalebar_line_pts has exactly two endpoints when rendered" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            plot_obj = scalebarlayer!(ax, geom, acc, :edgeweights; label = "1 unit")
            colorbuffer(fig)
            @test length(plot_obj[:scalebar_line_pts][]) == 2
        end

        @testset "visible defaults to true for :branchingtime and :coalescenceage when labelled" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            geom = rectangular_layout(_LT_BALANCED_BASENODE, acc)
            p1 = scalebarlayer!(ax, geom, acc, :branchingtime; label = "1 unit")
            p2 = scalebarlayer!(ax, geom, acc, :coalescenceage; label = "1 unit")
            @test p1[:resolved_visible][] == true
            @test p2[:resolved_visible][] == true
        end

        @testset "radial defaults derive from the full plot envelope" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            geom = circular_layout(_LT_BALANCED_BASENODE, _LT_ACC; lineageunits = :nodeheights)
            plot_obj = scalebarlayer!(
                ax,
                geom,
                _LT_ACC,
                :nodeheights;
                lineage_orientation = :radial,
                scalebar_auto_visible = true,
                label = "1 unit",
            )
            colorbuffer(fig)

            plot_bb = _LT_GEOMETRY._plot_envelope(geom)
            node_bb = geom.boundingbox
            line_pts = plot_obj[:scalebar_line_pts][]
            expected_length = Float32(plot_bb.widths[1]) * 0.1f0
            node_length = Float32(node_bb.widths[1]) * 0.1f0

            @test plot_obj[:resolved_visible][] == true
            @test length(line_pts) == 2
            @test plot_bb.widths[1] > node_bb.widths[1] ||
                plot_bb.widths[2] > node_bb.widths[2]
            @test !isapprox(expected_length, node_length; atol = 1.0f-4)
            @test line_pts[1][1] ≈ plot_bb.origin[1] atol = 1.0f-4
            @test line_pts[1][2] ≈ plot_bb.origin[2] - 0.5f0 atol = 1.0f-4
            @test line_pts[2][1] ≈ plot_bb.origin[1] + expected_length atol = 1.0f-4
            @test line_pts[2][2] ≈ plot_bb.origin[2] - 0.5f0 atol = 1.0f-4
        end

    end

    # ── LineagePlot composite recipe ──────────────────────────────────────────

    @testset "LineagePlot" begin

        @testset "returns LineagePlot on plain Axis" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc)
            @test lp isa LineagePlot
        end

        @testset "computed_geom is a LineageGraphGeometry after construction" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc)
            @test lp[:computed_geom][] isa LineageGraphGeometry
        end

        @testset "computed_geom has correct leaf count" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc)
            @test length(lp[:computed_geom][].leaf_order) == 4
        end

        @testset "renders without error and produces non-empty colorbuffer" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            @test_nowarn begin
                lineageplot!(ax, _LT_BALANCED_BASENODE, acc)
                colorbuffer(fig)
            end
        end

        @testset "lineageunits = :nodelevels accepted" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            @test_nowarn lineageplot!(ax, _LT_BALANCED_BASENODE, acc; lineageunits = :nodelevels)
        end

        @testset "resolved_lineageunits is :nodeheights for children-only accessor" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc)
            @test lp[:resolved_lineageunits][] === :nodeheights
        end

        @testset "lineage_orientation = :radial triggers circular_layout" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc; lineage_orientation = :radial)
            colorbuffer(fig)
            geom = lp[:computed_geom][]
            # All 4 leaves are at equal radius in a circular layout.
            leaf_radii = [
                sqrt(geom.node_positions[node][1]^2 + geom.node_positions[node][2]^2)
                for node in geom.leaf_order
            ]
            @test all(r -> isapprox(r, leaf_radii[1]; atol = 1.0f-3), leaf_radii)
        end

        @testset "edge_color kwarg forwarded to EdgeLayer child" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc; edge_color = :red)
            edge_children = filter(p -> p isa EdgeLayer, lp.plots)
            @test !isempty(edge_children)
            @test edge_children[1][:color][] === :red
        end

        @testset "edge_visible = false forwarded to EdgeLayer child" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc; edge_visible = false)
            edge_children = filter(p -> p isa EdgeLayer, lp.plots)
            @test !isempty(edge_children)
            @test edge_children[1][:visible][] == false
        end

        @testset "leaf_label_func kwarg forwarded to LeafLabelLayer child" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            custom_tf = node -> "TEST"
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc; leaf_label_func = custom_tf)
            colorbuffer(fig)
            label_children = filter(p -> p isa LeafLabelLayer, lp.plots)
            @test !isempty(label_children)
            @test all(s -> s == "TEST", label_children[1][:leaf_label_strings][])
        end

        @testset "clade_nodes shared by CladeHighlightLayer and CladeLabelLayer" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc; clade_nodes = [_LT_BALANCED_BASENODE])
            colorbuffer(fig)
            hl_children = filter(p -> p isa CladeHighlightLayer, lp.plots)
            cl_children = filter(p -> p isa CladeLabelLayer, lp.plots)
            @test !isempty(hl_children)
            @test !isempty(cl_children)
            # Both sub-layers received the single MRCA node.
            @test length(hl_children[1][:highlight_rects][]) == 1
        end

        @testset "scalebar_auto_visible = true overrides default for :nodeheights" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            lp = lineageplot!(
                ax, _LT_BALANCED_BASENODE, acc;
                lineageunits = :nodeheights, scalebar_auto_visible = true,
            )
            scalebar_children = filter(p -> p isa ScaleBarLayer, lp.plots)
            @test !isempty(scalebar_children)
            @test scalebar_children[1][:resolved_visible][] == true
        end

        @testset "scalebar is auto-hidden for :nodeheights by default" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc; lineageunits = :nodeheights)
            scalebar_children = filter(p -> p isa ScaleBarLayer, lp.plots)
            @test !isempty(scalebar_children)
            @test scalebar_children[1][:resolved_visible][] == false
        end

        @testset "scalebar is auto-hidden for :edgeweights when label is empty" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(
                _LT_BALANCED_BASENODE;
                children = node -> node.children,
                edgeweight = (src, dst) -> 1.0,
            )
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc; lineageunits = :edgeweights)
            scalebar_children = filter(p -> p isa ScaleBarLayer, lp.plots)
            @test !isempty(scalebar_children)
            @test scalebar_children[1][:resolved_visible][] == false
        end

        @testset "scalebar is auto-visible for :edgeweights when label is present" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(
                _LT_BALANCED_BASENODE;
                children = node -> node.children,
                edgeweight = (src, dst) -> 1.0,
            )
            lp = lineageplot!(
                ax,
                _LT_BALANCED_BASENODE,
                acc;
                lineageunits = :edgeweights,
                scalebar_label = "1 unit",
            )
            scalebar_children = filter(p -> p isa ScaleBarLayer, lp.plots)
            @test !isempty(scalebar_children)
            @test scalebar_children[1][:resolved_visible][] == true
        end

        @testset "computed_geom updates reactively when lineageunits attribute changes" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc; lineageunits = :nodeheights)
            geom_before = lp[:computed_geom][]
            lp.lineageunits = :nodelevels
            geom_after = lp[:computed_geom][]
            # Both are valid geometries; bounding boxes differ because
            # :nodeheights and :nodelevels assign different x coordinates.
            @test geom_before !== geom_after
            @test geom_after isa LineageGraphGeometry
        end

        @testset "edge_color updates reactively when attribute Observable changes" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            color_obs = CairoMakie.Makie.Observable(:blue)
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc; edge_color = color_obs)
            edge_children = filter(p -> p isa EdgeLayer, lp.plots)
            @test !isempty(edge_children)
            @test edge_children[1][:color][] === :blue
            color_obs[] = :red
            @test edge_children[1][:color][] === :red
        end

        @testset "lift on edge_color attribute tracks source Observable" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
            c = CairoMakie.Makie.Observable(:black)
            lp = lineageplot!(ax, _LT_BALANCED_BASENODE, acc;
                edge_color = CairoMakie.Makie.lift(x -> x, c))
            edge_children = filter(p -> p isa EdgeLayer, lp.plots)
            @test !isempty(edge_children)
            @test edge_children[1][:color][] === :black
            c[] = :green
            @test edge_children[1][:color][] === :green
        end

    end

    @testset "CladeHighlightLayer rects stay within the bounding box and remain clade-local" begin
        fig = Figure(; size = (400, 300))
        ax  = Axis(fig[1, 1])
        acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
        lp  = lineageplot!(ax, _LT_BALANCED_BASENODE, acc;
                           clade_nodes = [_LT_NONBASENODE_CLADE])
        colorbuffer(fig)
        chl = only(filter(p -> p isa CladeHighlightLayer, lp.plots))
        geom = lp[:computed_geom][]
        bb  = geom.boundingbox
        # Use Rect2f field access: origin is the bottom-left, widths is the extent.
        bb_x0 = Float32(bb.origin[1])
        bb_y0 = Float32(bb.origin[2])
        bb_x1 = Float32(bb.origin[1] + bb.widths[1])
        bb_y1 = Float32(bb.origin[2] + bb.widths[2])
        full_span = Float32(bb.widths[1])
        raw_span = _lt_clade_xspan(geom, acc, _LT_NONBASENODE_CLADE)
        # Strict clamping: rects must not extend beyond the bounding box.
        for r in chl[:highlight_rects][]
            @test r.origin[1] >= bb_x0
            @test r.origin[1] + r.widths[1] <= bb_x1
            @test r.origin[2] >= bb_y0
            @test r.origin[2] + r.widths[2] <= bb_y1
            @test r.widths[1] >= raw_span
            @test r.widths[1] < full_span
        end
    end

    @testset "node_label_threshold defaults to node -> false" begin
        fig = Figure(; size = (400, 300))
        ax  = Axis(fig[1, 1])
        acc = lineagegraph_accessor(_LT_BALANCED_BASENODE; children = node -> node.children)
        lp  = lineageplot!(ax, _LT_BALANCED_BASENODE, acc)
        nll = only(filter(p -> p isa NodeLabelLayer, lp.plots))
        # With threshold = node -> false, no node passes → zero label positions.
        @test isempty(nll[:node_label_positions][])
    end

end
