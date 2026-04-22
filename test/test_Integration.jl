# Integration smoke tests
#
# Exercises the full public entry-point path: lineageplot! → edgelayer! → CairoMakie render.

import CairoMakie
using CairoMakie: Figure, Axis, save

struct IntegrationTestNode
    name::String
    children::Vector{IntegrationTestNode}
end

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

    @testset "lineageplot! on LineageAxis returns LineagePlot and sets last_geom" begin
        fig = Figure(; size = (800, 600))
        lax = LineageAxis(fig[1, 1])
        acc = lineagegraph_accessor(_IT_ROOT; children = n -> n.children)
        lp = lineageplot!(lax, _IT_ROOT, acc)
        @test lp isa LineagePlot
        @test lax.last_geom[] !== nothing
        @test_nowarn CairoMakie.colorbuffer(fig)
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

end
