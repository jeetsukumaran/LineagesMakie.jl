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

function _pn_2cycle_net()
    return PhyloNetworks.readnewick(
        "((((((a:1)#H1:1::.9)#H2:1::.8)#H3:1::.7,#H3:0.5):1,#H2:1):1,(#H1:1,b:1):1,c:1);",
    )
end

function _pn_minimal_2cycle_net()
    return PhyloNetworks.readnewick("((t1:1)#H22:1::0.8,#H22:1::0.2);")
end

function _pn_edge_groups(net)
    edge_groups = Dict{Tuple{PhyloNetworks.Node, PhyloNetworks.Node}, Vector{PhyloNetworks.Edge}}()
    for parent_node in net.node
        for edge in parent_node.edge
            PhyloNetworks.getparent(edge) === parent_node || continue
            child_node = PhyloNetworks.getchild(edge)
            push!(get!(() -> PhyloNetworks.Edge[], edge_groups, (parent_node, child_node)), edge)
        end
    end
    return edge_groups
end

function _pn_duplicate_endpoint_pair(net)
    return only([(edge_key, edge_group) for (edge_key, edge_group) in _pn_edge_groups(net) if length(edge_group) > 1])
end

function _pn_root_error(err)
    return hasproperty(err, :error) ? getproperty(err, :error) : err
end

function _pn_edge_shape_chunks(points)::Vector{Vector{Makie.Point2f}}
    return [collect(@view points[i:(i + 3)]) for i in 1:4:length(points)]
end

function _pn_contains_edge_shape(points, edge_shape)::Bool
    return any(chunk -> isequal(chunk, collect(edge_shape)), _pn_edge_shape_chunks(points))
end

function _pn_hybrid_edge_labels(net)::Vector{String}
    return sort([string(round(edge.gamma; digits = 3)) for edge in net.edge if edge.hybrid])
end

function _pn_weighted_edge_map(net)::Dict{Tuple{PhyloNetworks.Node, PhyloNetworks.Node}, Float64}
    edge_lengths = Dict{Tuple{PhyloNetworks.Node, PhyloNetworks.Node}, Float64}()
    for (edge_key, edge_group) in _pn_edge_groups(net)
        lengths = unique([edge.length for edge in edge_group])
        length(lengths) == 1 || throw(
            ArgumentError(
                "test helper requires representable duplicate-endpoint groups; got conflicting lengths $(repr(lengths))",
            ),
        )
        edge_lengths[edge_key] = only(lengths)
    end
    return edge_lengths
end

function _pn_generic_weighted_plot!(ax, net)::LineagePlot
    root = PhyloNetworks.getroot(net)
    edge_lengths = _pn_weighted_edge_map(net)
    accessor = lineagegraph_accessor(
        root;
        children = PhyloNetworks.getchildren,
        edgeweight = (src, dst) -> edge_lengths[(src, dst)],
    )
    return lineageplot!(ax, root, accessor; lineageunits = :edgeweights, leaf_label_visible = false)
end

function _pn_major_tree(net)::PhyloNetworks.HybridNetwork
    return PhyloNetworks.majortree(net; unroot = false)
end

function _pn_generic_tree_plot!(ax, net)::LineagePlot
    root = PhyloNetworks.getroot(net)
    accessor = lineagegraph_accessor(root; children = PhyloNetworks.getchildren)
    return lineageplot!(
        ax,
        root,
        accessor;
        lineageunits = :nodelevels,
        leaf_label_visible = false,
        node_label_visible = false,
    )
end

function _pn_geom_signature(geom)
    node_positions = sort(
        [(node.number, geom.node_positions[node]) for node in keys(geom.node_positions)];
        by = first,
    )
    edges = [(src.number, dst.number) for (src, dst) in geom.edges]
    leaf_order = [node.number for node in geom.leaf_order]
    return (; node_positions, edge_shapes = geom.edge_shapes, edges, leaf_order, boundingbox = geom.boundingbox)
end

function _pn_same_geom(lhs, rhs)::Bool
    return isequal(_pn_geom_signature(lhs), _pn_geom_signature(rhs))
end

function _pn_make_duplicate_lengths_conflict!(net, new_length::Float64)::Nothing
    _, duplicate_edges = _pn_duplicate_endpoint_pair(net)
    duplicate_edges[2].length = new_length
    return nothing
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

    @testset "extension metadata preserves distinct upstream duplicate-endpoint groups" begin
        net = _pn_2cycle_net()
        metadata = _PN_EXT._hybridnetwork_edge_metadata(net)
        duplicate_pair, duplicate_edges = _pn_duplicate_endpoint_pair(net)

        @test sum(length, values(metadata.edge_metadata)) == length(net.edge)
        @test Set(metadata.hybrid_nodes) == Set(net.hybrid)
        @test length(metadata.edge_metadata[duplicate_pair]) == 2
        @test [item.edge.number for item in metadata.edge_metadata[duplicate_pair]] ==
            [edge.number for edge in duplicate_edges]
        @test [item.ismajor for item in metadata.edge_metadata[duplicate_pair]] ==
            [edge.ismajor for edge in duplicate_edges]
        @test [item.gamma for item in metadata.edge_metadata[duplicate_pair]] ==
            [edge.gamma for edge in duplicate_edges]
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

    @testset "explicit networkview surface preserves rooted full-network default and adds a distinct major-tree projection" begin
        net_default = _pn_net1()
        default_result = lineageplot(
            net_default;
            figure = (; size = (760, 420)),
            axis = (; title = "Default rooted full-network view"),
            leaf_label_visible = false,
            node_label_visible = false,
        )
        @test default_result isa CairoMakie.Makie.FigureAxisPlot
        fig_default, _, lp_default = default_result
        colorbuffer(fig_default)
        default_geom = lp_default[:computed_geom][]

        net_named = _pn_net1()
        named_result = lineageplot(
            net_named;
            figure = (; size = (760, 420)),
            axis = (; title = "Explicit rooted full-network view"),
            networkview = :fullnetwork,
            displaypolicy = :rooted,
            leaf_label_visible = false,
            node_label_visible = false,
        )
        @test named_result isa CairoMakie.Makie.FigureAxisPlot
        fig_named, _, lp_named = named_result
        colorbuffer(fig_named)
        named_geom = lp_named[:computed_geom][]

        net_major = _pn_net1()
        major_result = lineageplot(
            net_major;
            figure = (; size = (760, 420)),
            axis = (; title = "Rooted major-tree projection"),
            networkview = :majortree,
            displaypolicy = :rooted,
            leaf_label_visible = false,
            node_label_visible = false,
        )
        @test major_result isa CairoMakie.Makie.FigureAxisPlot
        fig_major, _, lp_major = major_result
        colorbuffer(fig_major)
        major_geom = lp_major[:computed_geom][]

        expected_major_tree = _pn_major_tree(_pn_net1())
        fig_expected = Figure(; size = (760, 420))
        ax_expected = Axis(fig_expected[1, 1])
        lp_expected = _pn_generic_tree_plot!(ax_expected, expected_major_tree)
        colorbuffer(fig_expected)
        expected_major_geom = lp_expected[:computed_geom][]

        @test lp_default[:resolved_lineageunits][] == :nodelevels
        @test lp_named[:resolved_lineageunits][] == :nodelevels
        @test lp_major[:resolved_lineageunits][] == :nodelevels
        @test _pn_same_geom(default_geom, named_geom)
        @test !_pn_same_geom(default_geom, major_geom)
        @test _pn_same_geom(major_geom, expected_major_geom)
        @test length(major_geom.edges) < length(default_geom.edges)
        @test isempty(filter(plot -> plot isa CairoMakie.Makie.Text, lp_major.plots))
        @test isempty(
            filter(
                plot ->
                    plot isa CairoMakie.Makie.Lines &&
                        plot.color[] in (_PN_EXT._RETICULATION_MAJOR_COLOR, _PN_EXT._RETICULATION_MINOR_COLOR),
                lp_major.plots,
            ),
        )
    end

    @testset "mutating plotting works on Axis and LineageAxis for unique and duplicate endpoint rooted networks" begin
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

        net_dup_axis = _pn_2cycle_net()
        fig_dup_axis = Figure(; size = (760, 420))
        ax_dup = Axis(fig_dup_axis[1, 1])
        lp_dup_axis = @test_nowarn lineageplot!(ax_dup, net_dup_axis; leaf_label_visible = false)
        colorbuffer(fig_dup_axis)
        @test lp_dup_axis isa LineagePlot

        net_dup_lax = _pn_2cycle_net()
        fig_dup_lax = Figure(; size = (760, 420))
        lax_dup = LineageAxis(fig_dup_lax[1, 1]; show_x_axis = true, xlabel = "node levels")
        lp_dup_lax = @test_nowarn lineageplot!(lax_dup, net_dup_lax; leaf_label_visible = false)
        colorbuffer(fig_dup_lax)
        @test lp_dup_lax isa LineagePlot
    end

    @testset "major-tree projection works on Axis and LineageAxis" begin
        net_axis = _pn_net1()
        fig_axis = Figure(; size = (760, 420))
        ax = Axis(fig_axis[1, 1])
        lp_axis = @test_nowarn lineageplot!(
            ax,
            net_axis;
            networkview = :majortree,
            displaypolicy = :rooted,
            leaf_label_visible = false,
            node_label_visible = false,
        )
        colorbuffer(fig_axis)
        @test lp_axis isa LineagePlot

        net_lax = _pn_net1()
        fig_lax = Figure(; size = (760, 420))
        lax = LineageAxis(fig_lax[1, 1]; show_x_axis = true, xlabel = "node levels")
        lp_lax = @test_nowarn lineageplot!(
            lax,
            net_lax;
            networkview = :majortree,
            displaypolicy = :rooted,
            leaf_label_visible = false,
            node_label_visible = false,
        )
        colorbuffer(fig_lax)
        @test lp_lax isa LineagePlot
    end

    @testset "networkview and displaypolicy diagnostics are explicit" begin
        fig_bad_view = Figure(; size = (600, 360))
        ax_bad_view = Axis(fig_bad_view[1, 1])
        err_bad_view = try
            lineageplot!(ax_bad_view, _pn_net1(); networkview = :displayedtrees, leaf_label_visible = false)
            nothing
        catch caught_error
            caught_error
        end
        @test err_bad_view isa ArgumentError
        @test occursin("unsupported networkview", sprint(showerror, err_bad_view))
        @test occursin(":fullnetwork", sprint(showerror, err_bad_view))
        @test occursin(":majortree", sprint(showerror, err_bad_view))

        fig_bad_policy = Figure(; size = (600, 360))
        ax_bad_policy = Axis(fig_bad_policy[1, 1])
        err_bad_policy = try
            lineageplot!(
                ax_bad_policy,
                _pn_net1();
                networkview = :fullnetwork,
                displaypolicy = :semidirected,
                leaf_label_visible = false,
            )
            nothing
        catch caught_error
            caught_error
        end
        @test err_bad_policy isa ArgumentError
        @test occursin("unsupported displaypolicy", sprint(showerror, err_bad_policy))
        @test occursin(":rooted", sprint(showerror, err_bad_policy))

        net_unrooted = _pn_net1()
        net_unrooted.isrooted = false
        fig_unrooted = Figure(; size = (600, 360))
        ax_unrooted = Axis(fig_unrooted[1, 1])
        err_unrooted = try
            lineageplot!(
                ax_unrooted,
                net_unrooted;
                networkview = :majortree,
                displaypolicy = :rooted,
                leaf_label_visible = false,
            )
            nothing
        catch caught_error
            caught_error
        end

        @test err_unrooted isa ArgumentError
        @test occursin("displaypolicy = :rooted requires net.isrooted = true", sprint(showerror, err_unrooted))
        @test occursin("semidirected and unrooted display policies are not yet supported", sprint(showerror, err_unrooted))
    end

    @testset "rooted displaypolicy still rejects non-rooted HybridNetwork defaults" begin
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
        @test occursin("displaypolicy = :rooted requires net.isrooted = true", sprint(showerror, err))
    end

    @testset "weighted direct entrypoints keep the settled full-network validation owner and add the named major-tree escape hatch" begin
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

        root_err = _pn_root_error(err)
        @test root_err isa ArgumentError
        @test occursin("full-network consistency", sprint(showerror, root_err))

        projected_net = _pn_net1()
        _pn_inconsistent_lengths!(projected_net)
        projected_major_tree = _pn_major_tree(projected_net)

        fig_projected = Figure(; size = (600, 360))
        ax_projected = Axis(fig_projected[1, 1])
        lp_projected = @test_nowarn lineageplot!(
            ax_projected,
            projected_net;
            networkview = :majortree,
            displaypolicy = :rooted,
            lineageunits = :edgeweights,
            leaf_label_visible = false,
            node_label_visible = false,
        )
        colorbuffer(fig_projected)
        projected_geom = lp_projected[:computed_geom][]

        fig_expected = Figure(; size = (600, 360))
        ax_expected = Axis(fig_expected[1, 1])
        lp_expected = _pn_generic_weighted_plot!(ax_expected, projected_major_tree)
        colorbuffer(fig_expected)
        expected_geom = lp_expected[:computed_geom][]

        @test lp_projected[:resolved_lineageunits][] == :edgeweights
        @test _pn_same_geom(projected_geom, expected_geom)
    end

    @testset "equal-length duplicate-endpoint weighted requests stay aligned with the generic core path" begin
        net = _pn_minimal_2cycle_net()
        duplicate_pair, duplicate_edges = _pn_duplicate_endpoint_pair(net)

        @test net.isrooted
        @test length(duplicate_edges) == 2
        @test all(edge.length == 1.0 for edge in duplicate_edges)

        fig_generic = Figure(; size = (600, 360))
        ax_generic = Axis(fig_generic[1, 1])
        lp_generic = @test_nowarn _pn_generic_weighted_plot!(ax_generic, net)
        colorbuffer(fig_generic)
        generic_geom = lp_generic[:computed_geom][]

        fig_axis = Figure(; size = (600, 360))
        ax = Axis(fig_axis[1, 1])
        lp_axis = @test_nowarn lineageplot!(ax, net; lineageunits = :edgeweights, leaf_label_visible = false)
        colorbuffer(fig_axis)
        axis_geom = lp_axis[:computed_geom][]

        fig_lax = Figure(; size = (600, 360))
        lax = LineageAxis(fig_lax[1, 1]; show_x_axis = true, xlabel = "edge weights")
        lp_lax = @test_nowarn lineageplot!(lax, net; lineageunits = :edgeweights, leaf_label_visible = false)
        colorbuffer(fig_lax)
        lax_geom = lp_lax[:computed_geom][]

        plot_result = lineageplot(
            net;
            figure = (; size = (600, 360)),
            axis = (; title = "Equal-length duplicate-endpoint weighted 2-cycle"),
            lineageunits = :edgeweights,
            leaf_label_visible = false,
        )
        @test plot_result isa CairoMakie.Makie.FigureAxisPlot
        fig_nonmut, lax_nonmut, lp_nonmut = plot_result
        @test lax_nonmut isa LineageAxis
        colorbuffer(fig_nonmut)
        nonmut_geom = lp_nonmut[:computed_geom][]

        @test duplicate_pair in generic_geom.edges
        @test lp_axis[:resolved_lineageunits][] == :edgeweights
        @test lp_lax[:resolved_lineageunits][] == :edgeweights
        @test lp_nonmut[:resolved_lineageunits][] == :edgeweights
        @test _pn_same_geom(axis_geom, generic_geom)
        @test _pn_same_geom(lax_geom, generic_geom)
        @test _pn_same_geom(nonmut_geom, generic_geom)
    end

    @testset "conflicting duplicate-endpoint weighted direct entrypoints fail with an honest ambiguity diagnostic" begin
        net = _pn_minimal_2cycle_net()
        _pn_make_duplicate_lengths_conflict!(net, 2.0)
        fig = Figure(; size = (600, 360))
        ax = Axis(fig[1, 1])

        err = try
            lineageplot!(ax, net; lineageunits = :edgeweights, leaf_label_visible = false)
            colorbuffer(fig)
            nothing
        catch caught_error
            caught_error
        end

        root_err = _pn_root_error(err)
        @test root_err isa ArgumentError
        @test occursin("duplicate-endpoint", sprint(showerror, root_err))
        @test occursin("edgeweight(src, dst)", sprint(showerror, root_err))
        @test occursin("conflicting lengths", sprint(showerror, root_err))
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

    @testset "upstream-tested rooted 2-cycle fixture stays a genuine 2-cycle" begin
        net = _pn_2cycle_net()
        duplicate_pair, duplicate_edges = _pn_duplicate_endpoint_pair(net)

        @test PhyloNetworks.shrink2cycles!(deepcopy(net)) == true
        @test length(duplicate_edges) == 2
        @test all(edge -> edge.hybrid, duplicate_edges)
        @test [edge.ismajor for edge in duplicate_edges] == [true, false]
        @test isapprox(duplicate_edges[1].gamma, 0.7; atol = 1.0e-8)
        @test isapprox(duplicate_edges[2].gamma, 0.3; atol = 1.0e-8)
        @test duplicate_pair[1] === PhyloNetworks.getparent(duplicate_edges[1])
        @test duplicate_pair[2] === PhyloNetworks.getchild(duplicate_edges[1])
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

        major_index = only(_PN_EXT._reticulation_edge_indices(geom, metadata, true))
        minor_index = only(_PN_EXT._reticulation_edge_indices(geom, metadata, false))
        major_plot = only(filter(plot -> plot.color[] == _PN_EXT._RETICULATION_MAJOR_COLOR, line_plots))
        minor_plot = only(filter(plot -> plot.color[] == _PN_EXT._RETICULATION_MINOR_COLOR, line_plots))
        gamma_payload = _PN_EXT._reticulation_gamma_payload(geom, metadata)

        @test length(line_plots) == 2
        @test isequal(major_plot[1][], LineagesMakie.Layers._edge_shape_subset(geom, (major_index,)))
        @test isequal(minor_plot[1][], LineagesMakie.Layers._edge_shape_subset(geom, (minor_index,)))
        @test hybrid_plot[1][] == [geom.node_positions[only(net.hybrid)]]
        @test text_plot[1][] == LineagesMakie.Layers._edge_label_anchor_positions(geom, gamma_payload.edge_indices)

        @test sort(_rt_text_payload_strings(text_plot.text[])) == _pn_hybrid_edge_labels(net)
        @test text_plot.color[] == gamma_payload.colors
    end

    @testset "rooted 2-cycle render proof keeps both duplicate-endpoint partner edges separately styled and labeled" begin
        net = _pn_2cycle_net()
        duplicate_pair, duplicate_edges = _pn_duplicate_endpoint_pair(net)

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
        major_plot = only(filter(plot -> plot.color[] == _PN_EXT._RETICULATION_MAJOR_COLOR, line_plots))
        minor_plot = only(filter(plot -> plot.color[] == _PN_EXT._RETICULATION_MINOR_COLOR, line_plots))
        duplicate_pair_indices = findall(edge_key -> edge_key == duplicate_pair, geom.edges)

        @test length(duplicate_pair_indices) == 2
        @test length(line_plots) == 2
        @test length(major_plot[1][]) ÷ 4 == count(edge -> edge.hybrid && edge.ismajor, net.edge)
        @test length(minor_plot[1][]) ÷ 4 == count(edge -> edge.hybrid && !edge.ismajor, net.edge)
        @test length(hybrid_plot[1][]) == length(net.hybrid)
        @test length(text_plot.text[]) == count(edge -> edge.hybrid, net.edge)
        @test sort(_rt_text_payload_strings(text_plot.text[])) == _pn_hybrid_edge_labels(net)
        @test _pn_contains_edge_shape(
            major_plot[1][],
            LineagesMakie.Layers._edge_shape_subset(geom, (duplicate_pair_indices[1],)),
        )
        @test _pn_contains_edge_shape(
            minor_plot[1][],
            LineagesMakie.Layers._edge_shape_subset(geom, (duplicate_pair_indices[2],)),
        )
        @test sort([string(round(edge.gamma; digits = 3)) for edge in duplicate_edges]) ⊆
            Set(_rt_text_payload_strings(text_plot.text[]))
    end

end
