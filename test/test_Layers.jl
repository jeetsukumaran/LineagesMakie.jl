# Tests for Layers
#
# All tests use real CairoMakie scenes. CairoMakie re-exports all Makie types.

import CairoMakie
const Makie = CairoMakie.Makie
using CairoMakie: Figure, Axis
using CairoMakie: colorbuffer
using CairoMakie: Rect2i, Vec2f

# ── Fixtures ──────────────────────────────────────────────────────────────────

struct LayersTestNode
    name::String
    children::Vector{LayersTestNode}
end

#   root
#   ├── ab
#   │   ├── a
#   │   └── b
#   └── cd
#       ├── c
#       └── d
const _LT_BALANCED_ROOT = LayersTestNode("root", [
    LayersTestNode("ab", [
        LayersTestNode("a", LayersTestNode[]),
        LayersTestNode("b", LayersTestNode[]),
    ]),
    LayersTestNode("cd", [
        LayersTestNode("c", LayersTestNode[]),
        LayersTestNode("d", LayersTestNode[]),
    ]),
])

# ── Shared fixture: rendered axis ─────────────────────────────────────────────

_LT_FIG = Figure(; size = (800, 600))
_LT_AX = Axis(_LT_FIG[1, 1])
colorbuffer(_LT_FIG)

_LT_ACC = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
_LT_ACC_UNIT = lineagegraph_accessor(
    _LT_BALANCED_ROOT;
    children = n -> n.children,
    edgelength = (u, v) -> 1.0,
)
_LT_GEOM = rectangular_layout(_LT_BALANCED_ROOT, _LT_ACC)
_LT_NONROOT_CLADE = _LT_BALANCED_ROOT.children[1]

function _lt_clade_points(geom::LineageGraphGeometry, acc, mrca)
    pts = [geom.vertex_positions[v] for v in leaves(acc, mrca)]
    push!(pts, geom.vertex_positions[mrca])
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

# ── Tests ─────────────────────────────────────────────────────────────────────

@testset "Layers" begin

    @testset "EdgeLayer" begin

        @testset "renders without error" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = edgelayer!(ax, geom)
            @test plot_obj isa EdgeLayer
        end

        @testset "visible = false" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = edgelayer!(ax, geom; visible = false)
            @test plot_obj.visible[] == false
        end

        @testset "per-edge color function" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = edgelayer!(ax, geom; color = (u, v) -> :red)
            colorbuffer(fig)
            @test plot_obj[:resolved_color][] isa AbstractVector
        end

        @testset "linewidth and alpha accepted" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            @test_nowarn edgelayer!(ax, geom; linewidth = 2.0, alpha = 0.5)
        end

    end

    @testset "VertexLayer" begin

        @testset "renders without error" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = vertexlayer!(ax, geom, acc)
            @test plot_obj isa VertexLayer
        end

        @testset "exactly 3 internal vertices" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = vertexlayer!(ax, geom, acc)
            colorbuffer(fig)
            # 4-leaf balanced binary tree has root + 2 internal nodes = 3 internal vertices
            @test length(plot_obj[:vertex_pos_data][]) == 3
        end

        @testset "pixel-size stability after viewport change" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = vertexlayer!(ax, geom, acc; markersize = 12)
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
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = leaflayer!(ax, geom, acc)
            @test plot_obj isa LeafLayer
        end

        @testset "exactly 4 leaf positions" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = leaflayer!(ax, geom, acc)
            colorbuffer(fig)
            @test length(plot_obj[:leaf_pos_data][]) == 4
        end

        @testset "independence: visible = false on LeafLayer does not affect VertexLayer" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            vl = vertexlayer!(ax, geom, acc)
            ll = leaflayer!(ax, geom, acc)
            ll.visible[] = false
            @test vl.visible[] == true
        end

    end

    @testset "LeafLabelLayer" begin

        @testset "renders without error" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = leaflabellayer!(ax, geom, acc; text_func = v -> "label")
            @test plot_obj isa LeafLabelLayer
        end

        @testset "label positions: 4 entries for 4-leaf tree" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = leaflabellayer!(ax, geom, acc; text_func = v -> "x")
            colorbuffer(fig)
            @test length(plot_obj[:leaf_label_positions][]) == 4
        end

        @testset "italic = true encodes italic font in resolved_font" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = leaflabellayer!(ax, geom, acc; italic = true)
            @test plot_obj[:resolved_font][] == :italic
        end

        @testset "visible = false" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = leaflabellayer!(ax, geom, acc; visible = false)
            @test plot_obj.visible[] == false
        end

        @testset "pixel offset: positions update reactively after viewport change" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
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
            plot_obj = leaflabellayer!(ax, _LT_GEOM, _LT_ACC; text_func = v -> string(v.name))
            colorbuffer(fig)
            positions = plot_obj[:leaf_label_positions][]
            @test !isempty(positions)
            @test all(pt -> isfinite(pt[1]) && isfinite(pt[2]), positions)
        end

        @testset "radial leaf labels use blockscene pixel positions and mixed left/right alignments" begin
            fig = Figure(; size = (500, 500))
            ax = Axis(fig[1, 1])
            geom = circular_layout(_LT_BALANCED_ROOT, _LT_ACC_UNIT; lineageunits = :edgelengths)
            plot_obj = leaflabellayer!(
                ax,
                geom,
                _LT_ACC_UNIT;
                text_func = v -> string(v.name),
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
                _LT_BALANCED_ROOT,
                _LT_ACC;
                leaf_label_func = v -> string(v.name),
                clade_vertices = [_LT_BALANCED_ROOT],
                clade_label_func = v -> "root",
            )
            colorbuffer(fig)
            ll = only(filter(p -> p isa LeafLabelLayer, lp.plots))
            cll = only(filter(p -> p isa CladeLabelLayer, lp.plots))
            @test !isempty(ll[:leaf_label_positions][])
            @test !isempty(cll[:bracket_label_pixel_positions][])
        end

        @testset "LineageAxis leaf and clade labels consume shared lane anchors" begin
            fig = Figure(; size = (500, 350))
            lax = LineageAxis(fig[1, 1])
            lp = lineageplot!(
                lax,
                _LT_BALANCED_ROOT,
                _LT_ACC_UNIT;
                lineageunits = :edgelengths,
                leaf_label_func = v -> "species_" * string(v.name),
                clade_vertices = [_LT_NONROOT_CLADE],
                clade_label_func = v -> "clade_" * string(v.name),
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
                _LT_BALANCED_ROOT,
                _LT_ACC_UNIT;
                lineageunits = :edgelengths,
                leaf_label_func = v -> "species_" * string(v.name),
                clade_vertices = [_LT_NONROOT_CLADE],
                clade_label_func = v -> "clade_" * string(v.name),
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

    end

    @testset "VertexLabelLayer" begin

        @testset "renders without error" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = vertexlabellayer!(ax, geom, acc)
            @test plot_obj isa VertexLabelLayer
        end

        @testset "threshold = v -> false: zero labels" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = vertexlabellayer!(ax, geom, acc; threshold = v -> false)
            colorbuffer(fig)
            @test length(plot_obj[:vertex_label_strings][]) == 0
        end

        @testset "threshold = v -> true: all 7 vertices labelled" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            # 4-leaf balanced tree has 3 internal + 4 leaf = 7 vertices total.
            plot_obj = vertexlabellayer!(
                ax,
                geom,
                acc;
                value_func = v -> "x",
                threshold = v -> true,
            )
            colorbuffer(fig)
            @test length(plot_obj[:vertex_label_strings][]) == 7
        end

        @testset "value_func returning non-renderable type raises error at plot time" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            # Makie's ComputeGraph wraps map! errors in ResolveException, so we
            # match by message content. The cause is an ArgumentError naming
            # the vertex and the non-renderable type.
            @test_throws r"cannot be rendered as text" vertexlabellayer!(
                ax,
                geom,
                acc;
                value_func = v -> Dict(),
                threshold  = v -> true,
            )
        end

        @testset "visible = false" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = vertexlabellayer!(ax, geom, acc; visible = false)
            @test plot_obj.visible[] == false
        end

    end

    @testset "CladeHighlightLayer" begin

        @testset "renders without error" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = cladehighlightlayer!(ax, geom, acc; clade_vertices = [_LT_BALANCED_ROOT])
            @test plot_obj isa CladeHighlightLayer
        end

        @testset "empty clade_vertices produces empty highlight_rects" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = cladehighlightlayer!(ax, geom, acc; clade_vertices = [])
            colorbuffer(fig)
            @test isempty(plot_obj[:highlight_rects][])
        end

        @testset "one MRCA produces exactly one highlight rect" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = cladehighlightlayer!(ax, geom, acc; clade_vertices = [_LT_BALANCED_ROOT])
            colorbuffer(fig)
            @test length(plot_obj[:highlight_rects][]) == 1
        end

        @testset "highlight rect encloses all leaf positions for root clade" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = cladehighlightlayer!(ax, geom, acc; clade_vertices = [_LT_BALANCED_ROOT])
            colorbuffer(fig)
            rect = plot_obj[:highlight_rects][][1]
            for v in geom.leaf_order
                pos = geom.vertex_positions[v]
                @test pos[1] >= rect.origin[1]
                @test pos[1] <= rect.origin[1] + rect.widths[1]
                @test pos[2] >= rect.origin[2]
                @test pos[2] <= rect.origin[2] + rect.widths[2]
            end
        end

        @testset "visible = false accepted" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = cladehighlightlayer!(ax, geom, acc; visible = false)
            @test plot_obj.visible[] == false
        end

        @testset "non-root clade highlight remains local after layout" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(
                _LT_BALANCED_ROOT;
                children = n -> n.children,
                edgelength = (u, v) -> 1.0,
            )
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc; lineageunits = :edgelengths)
            plot_obj = cladehighlightlayer!(ax, geom, acc; clade_vertices = [_LT_NONROOT_CLADE])
            colorbuffer(fig)

            rect = only(plot_obj[:highlight_rects][])
            raw_span = _lt_clade_xspan(geom, acc, _LT_NONROOT_CLADE)
            full_span = Float32(geom.boundingbox.widths[1])

            @test rect.widths[1] >= raw_span
            @test rect.widths[1] < full_span

            for pt in _lt_clade_points(geom, acc, _LT_NONROOT_CLADE)
                @test _lt_rect_contains(rect, pt)
            end

            outside_leaves = [
                geom.vertex_positions[v] for v in geom.leaf_order
                if !(v in collect(leaves(acc, _LT_NONROOT_CLADE)))
            ]
            @test any(pt -> !_lt_rect_contains(rect, pt), outside_leaves)
        end

        @testset "highlight geometry remains local across initial viewport resolution" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(
                _LT_BALANCED_ROOT;
                children = n -> n.children,
                edgelength = (u, v) -> 1.0,
            )
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc; lineageunits = :edgelengths)
            plot_obj = cladehighlightlayer!(ax, geom, acc; clade_vertices = [_LT_NONROOT_CLADE])
            raw_span = _lt_clade_xspan(geom, acc, _LT_NONROOT_CLADE)
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

    @testset "CladeLabelLayer" begin

        @testset "renders without error" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = cladelabellayer!(
                ax,
                geom,
                acc;
                clade_vertices = [_LT_BALANCED_ROOT],
                label_func = v -> "Clade A",
            )
            @test plot_obj isa CladeLabelLayer
        end

        @testset "label_func text content appears in bracket_label_strings" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = cladelabellayer!(
                ax,
                geom,
                acc;
                clade_vertices = [_LT_BALANCED_ROOT],
                label_func = v -> "Clade A",
            )
            colorbuffer(fig)
            strings = plot_obj[:bracket_label_strings][]
            @test any(s -> occursin("Clade A", s), strings)
        end

        @testset "empty clade_vertices produces no bracket shapes" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = cladelabellayer!(ax, geom, acc; clade_vertices = [])
            colorbuffer(fig)
            @test isempty(plot_obj[:bracket_shapes][])
        end

        @testset "visible = false accepted" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = cladelabellayer!(ax, geom, acc; visible = false)
            @test plot_obj.visible[] == false
        end

        @testset "bracket renders in decoration scene (not clipped)" begin
            fig = Figure(; size = (400, 300))
            ax  = Axis(fig[1, 1])
            lp  = lineageplot!(ax, _LT_BALANCED_ROOT, _LT_ACC;
                               clade_vertices = [_LT_BALANCED_ROOT],
                               clade_label_func = v -> "root")
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
            lp  = lineageplot!(ax, _LT_BALANCED_ROOT, _LT_ACC;
                               clade_vertices = [_LT_BALANCED_ROOT],
                               clade_label_func = v -> "root")
            colorbuffer(fig)
            cll = only(filter(p -> p isa CladeLabelLayer, lp.plots))
            @test !isempty(cll[:bracket_label_pixel_positions][])
        end

    end

    @testset "ScaleBarLayer" begin

        @testset "visible defaults to false for :vertexheights" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = scalebarlayer!(ax, geom, acc, :vertexheights)
            @test plot_obj[:resolved_visible][] == false
        end

        @testset "visible defaults to true for :edgelengths" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = scalebarlayer!(ax, geom, acc, :edgelengths)
            @test plot_obj[:resolved_visible][] == true
        end

        @testset "explicit visible = true overrides :vertexheights default" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = scalebarlayer!(ax, geom, acc, :vertexheights; scalebar_auto_visible = true)
            @test plot_obj[:resolved_visible][] == true
        end

        @testset "scalebar_line_pts has exactly two endpoints when rendered" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            plot_obj = scalebarlayer!(ax, geom, acc, :edgelengths)
            colorbuffer(fig)
            @test length(plot_obj[:scalebar_line_pts][]) == 2
        end

        @testset "visible defaults to true for :branchingtime and :coalescenceage" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            geom = rectangular_layout(_LT_BALANCED_ROOT, acc)
            p1 = scalebarlayer!(ax, geom, acc, :branchingtime)
            p2 = scalebarlayer!(ax, geom, acc, :coalescenceage)
            @test p1[:resolved_visible][] == true
            @test p2[:resolved_visible][] == true
        end

    end

    # ── LineagePlot composite recipe ──────────────────────────────────────────

    @testset "LineagePlot" begin

        @testset "returns LineagePlot on plain Axis" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            lp = lineageplot!(ax, _LT_BALANCED_ROOT, acc)
            @test lp isa LineagePlot
        end

        @testset "computed_geom is a LineageGraphGeometry after construction" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            lp = lineageplot!(ax, _LT_BALANCED_ROOT, acc)
            @test lp[:computed_geom][] isa LineageGraphGeometry
        end

        @testset "computed_geom has correct leaf count" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            lp = lineageplot!(ax, _LT_BALANCED_ROOT, acc)
            @test length(lp[:computed_geom][].leaf_order) == 4
        end

        @testset "renders without error and produces non-empty colorbuffer" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            @test_nowarn begin
                lineageplot!(ax, _LT_BALANCED_ROOT, acc)
                colorbuffer(fig)
            end
        end

        @testset "lineageunits = :vertexlevels accepted" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            @test_nowarn lineageplot!(ax, _LT_BALANCED_ROOT, acc; lineageunits = :vertexlevels)
        end

        @testset "resolved_lineageunits is :vertexheights for children-only accessor" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            lp = lineageplot!(ax, _LT_BALANCED_ROOT, acc)
            @test lp[:resolved_lineageunits][] === :vertexheights
        end

        @testset "lineage_orientation = :radial triggers circular_layout" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            lp = lineageplot!(ax, _LT_BALANCED_ROOT, acc; lineage_orientation = :radial)
            colorbuffer(fig)
            geom = lp[:computed_geom][]
            # All 4 leaves are at equal radius in a circular layout.
            leaf_radii = [
                sqrt(geom.vertex_positions[v][1]^2 + geom.vertex_positions[v][2]^2)
                for v in geom.leaf_order
            ]
            @test all(r -> isapprox(r, leaf_radii[1]; atol = 1.0f-3), leaf_radii)
        end

        @testset "edge_color kwarg forwarded to EdgeLayer child" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            lp = lineageplot!(ax, _LT_BALANCED_ROOT, acc; edge_color = :red)
            edge_children = filter(p -> p isa EdgeLayer, lp.plots)
            @test !isempty(edge_children)
            @test edge_children[1][:color][] === :red
        end

        @testset "edge_visible = false forwarded to EdgeLayer child" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            lp = lineageplot!(ax, _LT_BALANCED_ROOT, acc; edge_visible = false)
            edge_children = filter(p -> p isa EdgeLayer, lp.plots)
            @test !isempty(edge_children)
            @test edge_children[1][:visible][] == false
        end

        @testset "leaf_label_func kwarg forwarded to LeafLabelLayer child" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            custom_tf = v -> "TEST"
            lp = lineageplot!(ax, _LT_BALANCED_ROOT, acc; leaf_label_func = custom_tf)
            colorbuffer(fig)
            label_children = filter(p -> p isa LeafLabelLayer, lp.plots)
            @test !isempty(label_children)
            @test all(s -> s == "TEST", label_children[1][:leaf_label_strings][])
        end

        @testset "clade_vertices shared by CladeHighlightLayer and CladeLabelLayer" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            lp = lineageplot!(ax, _LT_BALANCED_ROOT, acc; clade_vertices = [_LT_BALANCED_ROOT])
            colorbuffer(fig)
            hl_children = filter(p -> p isa CladeHighlightLayer, lp.plots)
            cl_children = filter(p -> p isa CladeLabelLayer, lp.plots)
            @test !isempty(hl_children)
            @test !isempty(cl_children)
            # Both sub-layers received the single MRCA vertex.
            @test length(hl_children[1][:highlight_rects][]) == 1
        end

        @testset "scalebar_auto_visible = true overrides default for :vertexheights" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            lp = lineageplot!(
                ax, _LT_BALANCED_ROOT, acc;
                lineageunits = :vertexheights, scalebar_auto_visible = true,
            )
            scalebar_children = filter(p -> p isa ScaleBarLayer, lp.plots)
            @test !isempty(scalebar_children)
            @test scalebar_children[1][:resolved_visible][] == true
        end

        @testset "scalebar is auto-hidden for :vertexheights by default" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            lp = lineageplot!(ax, _LT_BALANCED_ROOT, acc; lineageunits = :vertexheights)
            scalebar_children = filter(p -> p isa ScaleBarLayer, lp.plots)
            @test !isempty(scalebar_children)
            @test scalebar_children[1][:resolved_visible][] == false
        end

        @testset "computed_geom updates reactively when lineageunits attribute changes" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            lp = lineageplot!(ax, _LT_BALANCED_ROOT, acc; lineageunits = :vertexheights)
            geom_before = lp[:computed_geom][]
            lp.lineageunits = :vertexlevels
            geom_after = lp[:computed_geom][]
            # Both are valid geometries; bounding boxes differ because
            # :vertexheights and :vertexlevels assign different x coordinates.
            @test geom_before !== geom_after
            @test geom_after isa LineageGraphGeometry
        end

        @testset "edge_color updates reactively when attribute Observable changes" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            color_obs = CairoMakie.Makie.Observable(:blue)
            lp = lineageplot!(ax, _LT_BALANCED_ROOT, acc; edge_color = color_obs)
            edge_children = filter(p -> p isa EdgeLayer, lp.plots)
            @test !isempty(edge_children)
            @test edge_children[1][:color][] === :blue
            color_obs[] = :red
            @test edge_children[1][:color][] === :red
        end

        @testset "lift on edge_color attribute tracks source Observable" begin
            fig = Figure(; size = (400, 300))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
            c = CairoMakie.Makie.Observable(:black)
            lp = lineageplot!(ax, _LT_BALANCED_ROOT, acc;
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
        acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
        lp  = lineageplot!(ax, _LT_BALANCED_ROOT, acc;
                           clade_vertices = [_LT_NONROOT_CLADE])
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
        raw_span = _lt_clade_xspan(geom, acc, _LT_NONROOT_CLADE)
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

    @testset "vertex_label_threshold defaults to v -> false" begin
        fig = Figure(; size = (400, 300))
        ax  = Axis(fig[1, 1])
        acc = lineagegraph_accessor(_LT_BALANCED_ROOT; children = n -> n.children)
        lp  = lineageplot!(ax, _LT_BALANCED_ROOT, acc)
        vll = only(filter(p -> p isa VertexLabelLayer, lp.plots))
        # With threshold = v -> false, no vertex passes → zero label positions.
        @test isempty(vll[:vertex_label_positions][])
    end

end
