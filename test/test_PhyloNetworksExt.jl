import CairoMakie
const Makie = CairoMakie.Makie
using CairoMakie: Axis, Figure, colorbuffer
import PhyloNetworks

if !isdefined(@__MODULE__, :_rt_text_payload_strings)
    include("test_render_helpers.jl")
end

const _PN_EXT = Base.get_extension(LineagesMakie, :PhyloNetworksExt)

function _pn_net1()
    return PhyloNetworks.readnewick(
        joinpath(dirname(pathof(PhyloNetworks)), "..", "examples", "net1.out"),
    )
end

function _pn_inconsistent_lengths!(net)::Nothing
    for edge in net.edge
        edge.length = 1.0
    end
    for edge in net.edge
        if edge.number in (11, 12)
            edge.length = 10.0
        end
    end
    return nothing
end

function _pn_branchingtime_map(net)::IdDict
    values = IdDict{PhyloNetworks.Node, Float64}()
    for node in net.node
        values[node] = if node.number == -2
            0.0
        elseif node.number == -3
            1.0
        elseif node.number in (-4, -6)
            2.0
        elseif node.number == -5
            3.0
        elseif node.number == 5
            4.0
        elseif node.number in (4, 7)
            5.0
        elseif node.number in (3, 6)
            3.0
        else
            1.0
        end
    end
    return values
end

function _pn_coalescenceage_map(net)::IdDict
    values = IdDict{PhyloNetworks.Node, Float64}()
    for node in net.node
        values[node] = if node.number == -2
            5.0
        elseif node.number == -3
            4.0
        elseif node.number in (-4, -6)
            3.0
        elseif node.number == -5
            2.0
        elseif node.number == 5
            1.0
        else
            0.0
        end
    end
    return values
end

function _pn_overlay_text_plot(lp)
    return only(filter(plot -> plot isa CairoMakie.Makie.Text, lp.plots))
end

@testset "PhyloNetworks extension" begin

    @testset "extension metadata is keyed by exact upstream parent and child nodes" begin
        net = _pn_net1()
        metadata = _PN_EXT._hybridnetwork_edge_metadata(net)

        @test length(metadata.edge_metadata) == length(net.edge)
        @test Set(metadata.hybrid_nodes) == Set(net.hybrid)

        minor_edge = only(filter(edge -> edge.hybrid && !edge.ismajor, net.edge))
        major_edge = only(filter(edge -> edge.hybrid && edge.ismajor, net.edge))
        minor_key = (PhyloNetworks.getparent(minor_edge), PhyloNetworks.getchild(minor_edge))
        major_key = (PhyloNetworks.getparent(major_edge), PhyloNetworks.getchild(major_edge))

        @test metadata.edge_metadata[minor_key].gamma == minor_edge.gamma
        @test metadata.edge_metadata[minor_key].ismajor == false
        @test metadata.edge_metadata[major_key].gamma == major_edge.gamma
        @test metadata.edge_metadata[major_key].ismajor == true
    end

    @testset "non-mutating lineageplot activates rooted full-network plotting" begin
        net = _pn_net1()
        plot_result = lineageplot(
            net;
            figure = (; size = (760, 420)),
            axis = (; title = "Rooted full-network PhyloNetworks fixture"),
            leaf_label_visible = false,
        )

        @test plot_result isa CairoMakie.Makie.FigureAxisPlot
        fig, lax, lp = plot_result
        @test lax isa LineageAxis
        @test lp isa LineagePlot
        @test lp[:resolved_lineageunits][] == :nodelevels
        colorbuffer(fig)
        @test any(plot -> plot isa CairoMakie.Makie.Lines, lp.plots)
        @test any(plot -> plot isa CairoMakie.Makie.Scatter, lp.plots)
        @test any(plot -> plot isa CairoMakie.Makie.Text, lp.plots)
    end

    @testset "mutating plotting works on Axis and LineageAxis" begin
        net_axis = _pn_net1()
        fig_axis = Figure(; size = (760, 420))
        ax = Axis(fig_axis[1, 1])
        lp_axis = @test_nowarn lineageplot!(ax, net_axis; leaf_label_visible = false)
        colorbuffer(fig_axis)
        @test lp_axis isa LineagePlot

        net_lax = _pn_net1()
        fig_lax = Figure(; size = (760, 420))
        lax = LineageAxis(fig_lax[1, 1]; show_x_axis = true, xlabel = "node levels")
        lp_lax = @test_nowarn lineageplot!(lax, net_lax; leaf_label_visible = false)
        colorbuffer(fig_lax)
        @test lp_lax isa LineagePlot
    end

    @testset "direct rooted-scope diagnostic rejects non-rooted HybridNetwork inputs" begin
        net = _pn_net1()
        net.isrooted = false
        fig = Figure(; size = (600, 360))
        ax = Axis(fig[1, 1])

        err = try
            lineageplot!(ax, net; leaf_label_visible = false)
            nothing
        catch caught_error
            caught_error
        end

        @test err isa ArgumentError
        @test occursin("rooted full-network views only", sprint(showerror, err))
    end

    @testset "weighted direct entrypoints keep the settled full-network validation owner" begin
        net = _pn_net1()
        _pn_inconsistent_lengths!(net)
        fig = Figure(; size = (600, 360))
        ax = Axis(fig[1, 1])

        err = try
            lineageplot!(ax, net; lineageunits = :edgeweights, leaf_label_visible = false)
            colorbuffer(fig)
            nothing
        catch caught_error
            caught_error
        end

        @test err !== nothing
        @test occursin("full-network consistency", sprint(showerror, err))
    end

    @testset "branchingtime and coalescenceage requests remain available on direct HybridNetwork entrypoints" begin
        net_bt = _pn_net1()
        branchingtime = _pn_branchingtime_map(net_bt)
        fig_bt = Figure(; size = (600, 360))
        ax_bt = Axis(fig_bt[1, 1])
        lp_bt = @test_nowarn lineageplot!(
            ax_bt,
            net_bt;
            lineageunits = :branchingtime,
            branchingtime = node -> branchingtime[node],
            leaf_label_visible = false,
        )
        colorbuffer(fig_bt)
        @test lp_bt isa LineagePlot

        net_ca = _pn_net1()
        coalescenceage = _pn_coalescenceage_map(net_ca)
        fig_ca = Figure(; size = (600, 360))
        ax_ca = Axis(fig_ca[1, 1])
        lp_ca = @test_nowarn lineageplot!(
            ax_ca,
            net_ca;
            lineageunits = :coalescenceage,
            coalescenceage = node -> coalescenceage[node],
            leaf_label_visible = false,
        )
        colorbuffer(fig_ca)
        @test lp_ca isa LineagePlot
    end

    @testset "render-level rooted full-network proof keeps minor edges, hybrid markers, and upstream gamma labels" begin
        net = _pn_net1()
        metadata = _PN_EXT._hybridnetwork_edge_metadata(net)

        fig = Figure(; size = (900, 520))
        ax = Axis(fig[1, 1])
        lp = lineageplot!(
            ax,
            net;
            leaf_label_visible = false,
            node_label_visible = false,
            edge_color = :gray45,
            edge_linewidth = 1.0,
            node_color = (:white, 0.0),
            node_strokecolor = (:white, 0.0),
            leaf_color = (:white, 0.0),
            leaf_strokecolor = (:white, 0.0),
        )

        colorbuffer(fig)
        geom = lp[:computed_geom][]
        line_plots = filter(plot -> plot isa CairoMakie.Makie.Lines, lp.plots)
        text_plot = _pn_overlay_text_plot(lp)
        hybrid_plot = only(filter(plot -> plot isa CairoMakie.Makie.Scatter, lp.plots))

        major_key = only(filter(edge_key -> metadata.edge_metadata[edge_key].edge.hybrid && metadata.edge_metadata[edge_key].ismajor, keys(metadata.edge_metadata)))
        minor_key = only(filter(edge_key -> metadata.edge_metadata[edge_key].edge.hybrid && !metadata.edge_metadata[edge_key].ismajor, keys(metadata.edge_metadata)))
        major_plot = only(filter(plot -> plot.color[] == _PN_EXT._RETICULATION_MAJOR_COLOR, line_plots))
        minor_plot = only(filter(plot -> plot.color[] == _PN_EXT._RETICULATION_MINOR_COLOR, line_plots))
        gamma_payload = _PN_EXT._reticulation_gamma_payload(geom, metadata)

        @test length(line_plots) == 2
        @test isequal(major_plot[1][], LineagesMakie.Layers._edge_shape_subset(geom, (major_key,)))
        @test isequal(minor_plot[1][], LineagesMakie.Layers._edge_shape_subset(geom, (minor_key,)))
        @test hybrid_plot[1][] == [geom.node_positions[only(net.hybrid)]]
        @test text_plot[1][] == LineagesMakie.Layers._edge_label_anchor_positions(geom, gamma_payload.edge_keys)

        rendered_labels = sort(_rt_text_payload_strings(text_plot.text[]))
        expected_labels = sort([
            string(round(edge.gamma; digits = 3)) for edge in net.edge if edge.hybrid
        ])

        @test rendered_labels == expected_labels
        @test text_plot.color[] == gamma_payload.colors
    end

end
