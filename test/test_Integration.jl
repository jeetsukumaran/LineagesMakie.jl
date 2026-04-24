# Integration smoke tests
#
# Exercises the full public entry-point path: lineageplot! → edgelayer! → CairoMakie render.
# All tests use CairoMakie (non-interactive backend) and create fresh Figure objects per
# testset to ensure independence.

import CairoMakie
using CairoMakie: Figure, Axis, save

# ── Fixtures ──────────────────────────────────────────────────────────────────

struct IntegrationTestNode
    name::String
    children::Vector{IntegrationTestNode}
end

# 4-leaf balanced tree: root → {ab → {a, b}, cd → {c, d}}
# Internal vertices: root, ab, cd (3 total); leaves: a, b, c, d (4 total)
const _IT_ROOT = IntegrationTestNode("root", [
    IntegrationTestNode("ab", [
        IntegrationTestNode("a", IntegrationTestNode[]),
        IntegrationTestNode("b", IntegrationTestNode[]),
    ]),
    IntegrationTestNode("cd", [
        IntegrationTestNode("c", IntegrationTestNode[]),
        IntegrationTestNode("d", IntegrationTestNode[]),
    ]),
])

# 6-leaf unbalanced tree for Observable reactivity test (Task 3)
# Internal vertices: root6, ab, cdef, cd, ef (5 total); leaves: a,b,c,d,e,f (6 total)
const _IT_ROOT6 = IntegrationTestNode("root6", [
    IntegrationTestNode("ab", [
        IntegrationTestNode("a", IntegrationTestNode[]),
        IntegrationTestNode("b", IntegrationTestNode[]),
    ]),
    IntegrationTestNode("cdef", [
        IntegrationTestNode("cd", [
            IntegrationTestNode("c", IntegrationTestNode[]),
            IntegrationTestNode("d", IntegrationTestNode[]),
        ]),
        IntegrationTestNode("ef", [
            IntegrationTestNode("e", IntegrationTestNode[]),
            IntegrationTestNode("f", IntegrationTestNode[]),
        ]),
    ]),
])

# ── Accessor helper functions ──────────────────────────────────────────────────

# branchingtime: root=0.0, ab/cd=1.0, leaves=2.0
# (Consistent with edgelength=1.0 per edge on the 4-leaf balanced tree)
function _it_branchingtime(n::IntegrationTestNode)
    return n.name in ("a", "b", "c", "d") ? 2.0 : n.name in ("ab", "cd") ? 1.0 : 0.0
end

# coalescenceage: leaves=0.0, ab/cd=1.0, root=2.0
# Ultrametric (all leaf-to-root sums equal); consistent with edgelength=1.0
function _it_coalescenceage(n::IntegrationTestNode)
    return n.name in ("a", "b", "c", "d") ? 0.0 : n.name in ("ab", "cd") ? 1.0 : 2.0
end

# vertexcoords: data-space Point2f for each vertex in the 4-leaf tree
const _IT_VERTEXCOORDS = Dict{String, CairoMakie.Makie.Point2f}(
    "root" => CairoMakie.Makie.Point2f(0, 2),
    "ab" => CairoMakie.Makie.Point2f(1, 1),
    "cd" => CairoMakie.Makie.Point2f(1, 3),
    "a" => CairoMakie.Makie.Point2f(2, 0),
    "b" => CairoMakie.Makie.Point2f(2, 1),
    "c" => CairoMakie.Makie.Point2f(2, 3),
    "d" => CairoMakie.Makie.Point2f(2, 4),
)
_it_vertexcoords(n::IntegrationTestNode) = _IT_VERTEXCOORDS[n.name]

# vertexpos: pixel-space Point2f for each vertex in the 4-leaf tree
const _IT_VERTEXPOS = Dict{String, CairoMakie.Makie.Point2f}(
    "root" => CairoMakie.Makie.Point2f(100, 200),
    "ab" => CairoMakie.Makie.Point2f(200, 100),
    "cd" => CairoMakie.Makie.Point2f(200, 300),
    "a" => CairoMakie.Makie.Point2f(300, 50),
    "b" => CairoMakie.Makie.Point2f(300, 150),
    "c" => CairoMakie.Makie.Point2f(300, 250),
    "d" => CairoMakie.Makie.Point2f(300, 350),
)
_it_vertexpos(n::IntegrationTestNode) = _IT_VERTEXPOS[n.name]

function _it_visible_blockscene_strings(lax::LineageAxis)::Vector{String}
    strings = String[]
    for plot in lax.blockscene.plots
        plot isa CairoMakie.Makie.Text || continue
        plot.visible[] || continue
        payload = plot.text[]
        if payload isa AbstractVector
            append!(strings, String[string(item) for item in payload])
        else
            push!(strings, string(payload))
        end
    end
    return strings
end

function _it_sample_figure_pixel(img, scene, data_pt)
    px = data_to_pixel(scene, data_pt)
    vp = scene.viewport[]
    col = clamp(round(Int, Float32(vp.origin[1]) + px[1]), 1, size(img, 2))
    row = clamp(round(Int, size(img, 1) - (Float32(vp.origin[2]) + px[2]) + 1), 1, size(img, 1))
    return img[row, col]
end

function _it_rgb_channels(pixel)
    word = reinterpret(UInt32, [pixel])[1]
    r = Float32((word >> 16) & 0xff) / 255.0f0
    g = Float32((word >> 8) & 0xff) / 255.0f0
    b = Float32(word & 0xff) / 255.0f0
    return (r, g, b)
end

# ── Tests ─────────────────────────────────────────────────────────────────────

@testset "Integration" begin

    @testset "smoke test: lineageplot! on CairoMakie Axis" begin
        tmpfile = tempname() * ".png"
        try
            fig = Figure(; size = (800, 600))
            ax = Axis(fig[1, 1])
            acc = lineagegraph_accessor(_IT_ROOT; children = n -> n.children)
            lp = lineageplot!(ax, _IT_ROOT, acc)
            @test lp isa LineagePlot
            save(tmpfile, fig)
            @test filesize(tmpfile) > 0
        finally
            isfile(tmpfile) && rm(tmpfile)
        end
    end

    @testset "lineageplot returns FigureAxisPlot with LineageAxis" begin
        tmpfile = tempname() * ".png"
        try
            acc = lineagegraph_accessor(_IT_ROOT; children = n -> n.children)
            plot_result = lineageplot(
                _IT_ROOT,
                acc;
                figure = (; size = (700, 500)),
                axis = (; title = "Integration plot"),
                leaf_label_func = n -> n.name,
            )
            @test plot_result isa CairoMakie.Makie.FigureAxisPlot
            fig, lax, lp = plot_result
            @test fig isa Figure
            @test lax isa LineageAxis
            @test lp isa LineagePlot
            @test lax.last_geom[] !== nothing
            @test repr(MIME("text/plain"), plot_result) == "FigureAxisPlot()"
            save(tmpfile, fig)
            @test filesize(tmpfile) > 0
        finally
            isfile(tmpfile) && rm(tmpfile)
        end
    end

    @testset "lineageplot! on LineageAxis returns LineagePlot and sets last_geom" begin
        fig = Figure(; size = (800, 600))
        lax = LineageAxis(fig[1, 1])
        acc = lineagegraph_accessor(_IT_ROOT; children = n -> n.children)
        lp = lineageplot!(lax, _IT_ROOT, acc)
        @test lp isa LineagePlot
        @test lax.last_geom[] !== nothing
        @test_nowarn CairoMakie.colorbuffer(fig)
    end

    @testset "vertical screen-axis API renders through lineageplot" begin
        acc = lineagegraph_accessor(
            _IT_ROOT;
            children = n -> n.children,
            edgelength = (u, v) -> 1.0,
        )
        plot_result = lineageplot(
            _IT_ROOT,
            acc;
            lineageunits = :edgelengths,
            figure = (; size = (700, 500)),
            axis = (;
                lineage_orientation = :top_to_bottom,
                show_y_axis = true,
                show_grid = true,
                ylabel = "Lineage distance",
            ),
        )
        fig, lax, lp = plot_result
        @test lp isa LineagePlot
        @test_nowarn CairoMakie.colorbuffer(fig)
        @test !isempty(lax._yaxis_tick_segments[])
        @test !isempty(lax._grid_segments[])
        @test "Lineage distance" in _it_visible_blockscene_strings(lax)
    end

    @testset "LineageAxis camera projection is non-identity after lineageplot!" begin
        fig = Figure(; size = (800, 600))
        lax = LineageAxis(fig[1, 1])
        acc = lineagegraph_accessor(_IT_ROOT; children = n -> n.children)
        lineageplot!(lax, _IT_ROOT, acc)
        # reset_limits! was called, so projection is no longer the identity matrix.
        proj = CairoMakie.Makie.camera(lax.scene).projection[]
        @test proj != CairoMakie.Makie.Mat4f(CairoMakie.Makie.I)
    end

    @testset "LineageAxis reset_limits! reruns reactively when lineageunits changes" begin
        fig = Figure(; size = (800, 600))
        lax = LineageAxis(fig[1, 1])
        # edgelength = 2.0:
        #   :edgelengths produces x ∈ [0, 4] (cumulative edge length from root)
        #   :vertexlevels produces x ∈ [0, 2] (integer depth, ignores edge lengths)
        # These have different bounding boxes, so the orthographic projection must
        # change when lineageunits is mutated reactively.
        acc = lineagegraph_accessor(
            _IT_ROOT;
            children = n -> n.children,
            edgelength = (u, v) -> 2.0,
        )
        lp = lineageplot!(lax, _IT_ROOT, acc; lineageunits = :edgelengths)
        proj_before = CairoMakie.Makie.camera(lax.scene).projection[]
        # Mutating lineageunits → computed_geom fires → on() callback → reset_limits!.
        lp.lineageunits = :vertexlevels
        proj_after = CairoMakie.Makie.camera(lax.scene).projection[]
        # x-scale differs between [0,4]+pad and [0,2]+pad projections.
        @test proj_before != proj_after
    end

    @testset "circular layout: lineage_orientation = :radial on LineageAxis" begin
        tmpfile = tempname() * ".png"
        try
            fig = Figure(; size = (600, 600))
            lax = LineageAxis(fig[1, 1]; lineage_orientation = :radial)
            acc = lineagegraph_accessor(_IT_ROOT; children = n -> n.children)
            lp = lineageplot!(lax, _IT_ROOT, acc; lineage_orientation = :radial)
            @test lp isa LineagePlot
            save(tmpfile, fig)
            @test filesize(tmpfile) > 0
        finally
            isfile(tmpfile) && rm(tmpfile)
        end
    end

    @testset "example-style scale bar is rendered in the panel-owned band" begin
        fig = Figure(; size = (800, 600))
        lax = LineageAxis(fig[1, 1]; show_x_axis = true)
        acc = lineagegraph_accessor(
            _IT_ROOT;
            children = n -> n.children,
            edgelength = (u, v) -> 1.0,
        )
        lp = lineageplot!(
            lax,
            _IT_ROOT,
            acc;
            lineageunits = :edgelengths,
            scalebar_auto_visible = true,
            scalebar_label = "1 unit",
        )
        CairoMakie.colorbuffer(fig)

        layout = lax._decoration_layout[]
        scalebar = only(filter(p -> p isa ScaleBarLayer, lp.plots))
        @test layout.scalebar_visible
        @test length(scalebar[:scalebar_line_pixel_pts][]) == 2
        @test scalebar[:resolved_visible][] == true
    end

    @testset "radial scale bar remains auto-hidden when unlabeled" begin
        fig = Figure(; size = (600, 600))
        lax = LineageAxis(fig[1, 1]; lineage_orientation = :radial)
        acc = lineagegraph_accessor(
            _IT_ROOT;
            children = n -> n.children,
            edgelength = (u, v) -> 1.0,
        )
        lp = lineageplot!(
            lax,
            _IT_ROOT,
            acc;
            lineageunits = :edgelengths,
            lineage_orientation = :radial,
        )
        CairoMakie.colorbuffer(fig)

        layout = lax._decoration_layout[]
        scalebar = only(filter(p -> p isa ScaleBarLayer, lp.plots))
        @test !layout.scalebar_visible
        @test scalebar[:resolved_visible][] == false
    end

    @testset "internal vertex markers preserve junction continuity under example styling" begin
        fig = Figure(; size = (500, 400))
        lax = LineageAxis(fig[1, 1])
        acc = lineagegraph_accessor(
            _IT_ROOT;
            children = n -> n.children,
            edgelength = (u, v) -> 1.0,
        )
        lp = lineageplot!(
            lax,
            _IT_ROOT,
            acc;
            lineageunits = :edgelengths,
            edge_color = :slategray,
            edge_linewidth = 1.5,
            vertex_color = :white,
            vertex_strokecolor = :slategray,
            vertex_markersize = 12,
        )
        img = CairoMakie.colorbuffer(fig; px_per_unit = 1)

        vertex_layers = filter(p -> p isa VertexLayer, lp.plots)
        @test length(vertex_layers) == 2
        @test vertex_layers[1].render_fill[] == true
        @test vertex_layers[1].render_stroke[] == false
        @test vertex_layers[2].render_fill[] == false
        @test vertex_layers[2].render_stroke[] == true

        geom = lp[:computed_geom][]
        for v in (_IT_ROOT.children[1], _IT_ROOT.children[2])
            junction_pixel = _it_sample_figure_pixel(img, lax.scene, geom.vertex_positions[v])
            r, g, b = _it_rgb_channels(junction_pixel)
            @test max(r, g, b) < 0.95f0
        end
    end

    @testset "full pipeline: all non-default attributes accepted without error" begin
        fig = Figure(; size = (800, 600))
        ax = Axis(fig[1, 1])
        acc = lineagegraph_accessor(
            _IT_ROOT;
            children = n -> n.children,
            edgelength = (u, v) -> 1.0,
        )
        @test_nowarn begin
            lineageplot!(
                ax, _IT_ROOT, acc;
                lineageunits = :edgelengths,
                edge_color = :steelblue,
                edge_linewidth = 2.0,
                edge_linestyle = :dash,
                edge_alpha = 0.8,
                vertex_color = :red,
                vertex_markersize = 6,
                leaf_color = :green,
                leaf_markersize = 10,
                leaf_label_func = n -> n.name,
                leaf_label_fontsize = 10,
                vertex_label_func = v -> "",
                vertex_label_threshold = v -> false,
                clade_vertices = [_IT_ROOT],
                clade_highlight_alpha = 0.1,
                clade_label_func = v -> "root",
                scalebar_auto_visible = true,
                scalebar_label = "1 unit",
            )
            CairoMakie.colorbuffer(fig)
        end
    end

    # ── Task 1: Smoke tests — all lineageunits × Axis and LineageAxis ──────────

    @testset "smoke/rectangular" begin
        # Each entry: (lineageunits symbol, string label for testset name, accessor kwargs)
        lu_cases = [
            (:edgelengths, "edgelengths", (edgelength = (u, v) -> 1.0,)),
            (:branchingtime, "branchingtime", (branchingtime = _it_branchingtime,)),
            (:coalescenceage, "coalescenceage", (coalescenceage = _it_coalescenceage,)),
            (:vertexdepths, "vertexdepths", NamedTuple()),
            (:vertexheights, "vertexheights", NamedTuple()),
            (:vertexlevels, "vertexlevels", NamedTuple()),
            (:vertexcoords, "vertexcoords", (vertexcoords = _it_vertexcoords,)),
            (:vertexpos, "vertexpos", (vertexpos = _it_vertexpos,)),
        ]

        for (lu_sym, lu_str, acc_extra) in lu_cases
            for (make_ax, ax_str) in [
                (fig -> Axis(fig[1, 1]), "Axis"),
                (fig -> LineageAxis(fig[1, 1]), "LineageAxis"),
            ]
                # Reconstruct accessor inside the loop body to avoid closure capture issues.
                @testset "smoke/rectangular/$lu_str/$ax_str" begin
                    tmpfile = tempname() * ".png"
                    try
                        fig = Figure(; size = (800, 600))
                        ax = make_ax(fig)
                        acc = lineagegraph_accessor(
                            _IT_ROOT;
                            children = n -> n.children,
                            acc_extra...,
                        )
                        lp = lineageplot!(ax, _IT_ROOT, acc; lineageunits = lu_sym)
                        @test lp isa LineagePlot
                        save(tmpfile, fig)
                        @test filesize(tmpfile) > 0
                    finally
                        isfile(tmpfile) && rm(tmpfile)
                    end
                end
            end
        end
    end

    # ── Task 2: Polarity matrix and lineage_orientation ────────────────────────

    @testset "polarity_matrix" begin
        # Pre-build accessors outside the loop; both are reusable across sub-testsets.
        acc_el = lineagegraph_accessor(
            _IT_ROOT;
            children = n -> n.children,
            edgelength = (u, v) -> 1.0,
        )
        acc_ca = lineagegraph_accessor(
            _IT_ROOT;
            children = n -> n.children,
            coalescenceage = _it_coalescenceage,
        )

        # Setting axis_polarity explicitly on LineageAxis locks inference (by design).
        for (ap, dp, lu, acc) in [
            (:forward, :standard, :edgelengths, acc_el),
            (:forward, :reversed, :edgelengths, acc_el),
            (:backward, :standard, :coalescenceage, acc_ca),
            (:backward, :reversed, :coalescenceage, acc_ca),
        ]
            @testset "$ap/$dp" begin
                fig = Figure(; size = (800, 600))
                lax = LineageAxis(fig[1, 1]; axis_polarity = ap, display_polarity = dp)
                @test_nowarn lineageplot!(lax, _IT_ROOT, acc; lineageunits = lu)
                @test_nowarn CairoMakie.colorbuffer(fig)
            end
        end
    end

    @testset "lineage_orientation" begin
        acc = lineagegraph_accessor(
            _IT_ROOT;
            children = n -> n.children,
            edgelength = (u, v) -> 1.0,
        )

        @testset "left_to_right" begin
            fig = Figure(; size = (800, 600))
            lax = LineageAxis(fig[1, 1]; lineage_orientation = :left_to_right)
            @test_nowarn lineageplot!(lax, _IT_ROOT, acc; lineageunits = :edgelengths)
            @test_nowarn CairoMakie.colorbuffer(fig)
        end

        @testset "right_to_left" begin
            fig = Figure(; size = (800, 600))
            lax = LineageAxis(fig[1, 1]; lineage_orientation = :right_to_left)
            @test_nowarn lineageplot!(lax, _IT_ROOT, acc; lineageunits = :edgelengths)
            @test_nowarn CairoMakie.colorbuffer(fig)
        end

        @testset "bottom_to_top" begin
            fig = Figure(; size = (800, 600))
            lax = LineageAxis(fig[1, 1]; lineage_orientation = :bottom_to_top)
            @test_nowarn lineageplot!(lax, _IT_ROOT, acc; lineageunits = :edgelengths)
            @test_nowarn CairoMakie.colorbuffer(fig)
        end

        @testset "top_to_bottom" begin
            fig = Figure(; size = (800, 600))
            lax = LineageAxis(fig[1, 1]; lineage_orientation = :top_to_bottom)
            @test_nowarn lineageplot!(lax, _IT_ROOT, acc; lineageunits = :edgelengths)
            @test_nowarn CairoMakie.colorbuffer(fig)
        end

        @testset "radial" begin
            fig = Figure(; size = (600, 600))
            lax = LineageAxis(fig[1, 1]; lineage_orientation = :radial)
            @test_nowarn lineageplot!(
                lax, _IT_ROOT, acc;
                lineageunits = :edgelengths,
                lineage_orientation = :radial,
            )
            @test_nowarn CairoMakie.colorbuffer(fig)
        end
    end

    # ── Task 3: Resize stability and Observable reactivity ─────────────────────

    @testset "resize_stability" begin
        fig = Figure(; size = (800, 600))
        lax = LineageAxis(fig[1, 1])
        acc = lineagegraph_accessor(_IT_ROOT; children = n -> n.children)
        lp = lineageplot!(lax, _IT_ROOT, acc)
        # VertexLayer renders at internal vertices with markerspace = :pixel.
        vl = first(p for p in lp.plots if p isa VertexLayer)
        markersize_before = vl.markersize[]
        # Simulate a viewport resize by updating the scene viewport Observable.
        lax.scene.viewport[] = CairoMakie.Makie.Rect2i(0, 0, 1200, 900)
        markersize_after = vl.markersize[]
        # Pixel-space markers must not be rescaled by CoordTransform on viewport change.
        @test markersize_before == markersize_after
    end

    @testset "observable_reactivity" begin
        fig = Figure(; size = (800, 600))
        lax = LineageAxis(fig[1, 1])
        # Same accessor works for both _IT_ROOT and _IT_ROOT6 (both IntegrationTestNode).
        acc = lineagegraph_accessor(_IT_ROOT; children = n -> n.children)
        root_obs = CairoMakie.Makie.Observable(_IT_ROOT)
        lp = lineageplot!(lax, root_obs, acc)
        # 4-leaf tree: leaf_order has 4 entries.
        @test length(lp[:computed_geom][].leaf_order) == 4
        # Update Observable → ComputeGraph recomputes geometry reactively.
        root_obs[] = _IT_ROOT6
        # 6-leaf tree: leaf_order has 6 entries after reactive recomputation.
        @test length(lp[:computed_geom][].leaf_order) == 6
    end

    @testset "2x2 LineageAxis example-style figure renders with panel-owned decorations" begin
        tmpfile = tempname() * ".png"
        try
            acc = lineagegraph_accessor(
                _IT_ROOT;
                children = n -> n.children,
                edgelength = (u, v) -> 1.0,
            )
            clade_a = _IT_ROOT.children[1]
            clade_b = _IT_ROOT.children[2]

            fig = Figure(; size = (1000, 800))
            lax1 = LineageAxis(fig[1, 1]; title = "Forward", show_x_axis = true, xlabel = "distance")
            lax2 = LineageAxis(fig[1, 2]; title = "Backward", show_x_axis = true, xlabel = "height")
            lax3 = LineageAxis(
                fig[2, 1];
                title = "Top-to-bottom",
                lineage_orientation = :top_to_bottom,
                show_y_axis = true,
                show_grid = true,
                ylabel = "distance",
            )
            lax4 = LineageAxis(fig[2, 2]; title = "Radial", lineage_orientation = :radial)

            @test_nowarn lineageplot!(
                lax1,
                _IT_ROOT,
                acc;
                lineageunits = :edgelengths,
                leaf_label_func = n -> n.name,
                clade_vertices = [clade_a, clade_b],
                clade_label_func = n -> n.name,
            )
            @test_nowarn lineageplot!(
                lax2,
                _IT_ROOT,
                acc;
                lineageunits = :vertexheights,
                leaf_label_func = n -> n.name,
                clade_vertices = [clade_a, clade_b],
                clade_label_func = n -> n.name,
            )
            @test_nowarn lineageplot!(
                lax3,
                _IT_ROOT,
                acc;
                lineageunits = :edgelengths,
                leaf_label_func = n -> n.name,
                clade_vertices = [clade_a, clade_b],
                clade_label_func = n -> n.name,
            )
            @test_nowarn lineageplot!(
                lax4,
                _IT_ROOT,
                acc;
                lineageunits = :edgelengths,
                lineage_orientation = :radial,
                leaf_label_func = n -> n.name,
            )

            @test_nowarn CairoMakie.colorbuffer(fig)
            save(tmpfile, fig)
            @test filesize(tmpfile) > 0

            for (lax, title_text) in [
                (lax1, "Forward"),
                (lax2, "Backward"),
                (lax3, "Top-to-bottom"),
                (lax4, "Radial"),
            ]
                @test title_text in _it_visible_blockscene_strings(lax)
            end

            @test !isempty(lax1._xaxis_tick_segments[])
            @test !isempty(lax2._xaxis_tick_segments[])
            @test !isempty(lax3._yaxis_tick_segments[])
            @test !isempty(lax3._grid_segments[])
            @test isempty(lax4._xaxis_tick_segments[])
        finally
            isfile(tmpfile) && rm(tmpfile)
        end
    end

end
