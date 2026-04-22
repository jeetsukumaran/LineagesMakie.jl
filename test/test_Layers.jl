# Tests for Layers
#
# All tests use real CairoMakie scenes. CairoMakie re-exports all Makie types.

import CairoMakie
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
_LT_GEOM = rectangular_layout(_LT_BALANCED_ROOT, _LT_ACC)

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

end
