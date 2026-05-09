module PhyloNetworksExt

using LineagesMakie
import LineagesMakie: lineageplot, lineageplot!
import Makie
import PhyloNetworks

using LineagesMakie.Layers: _edge_label_anchor_positions, _edge_shape_subset

struct _HybridEdgeMetadata
    edge::PhyloNetworks.Edge
    gamma::Float64
    ismajor::Bool
end

struct _HybridNetworkOverlayMetadata
    edge_metadata::Dict{Tuple{PhyloNetworks.Node, PhyloNetworks.Node}, Vector{_HybridEdgeMetadata}}
    hybrid_nodes::Vector{PhyloNetworks.Node}
end

const _RETICULATION_MAJOR_COLOR = Makie.RGBAf(0.73f0, 0.55f0, 0.18f0, 1.0f0)
const _RETICULATION_MINOR_COLOR = Makie.RGBAf(0.20f0, 0.56f0, 0.85f0, 1.0f0)
const _HYBRID_NODE_FILL_COLOR = Makie.RGBAf(0.98f0, 0.92f0, 0.62f0, 1.0f0)
const _HYBRID_NODE_STROKE_COLOR = Makie.RGBAf(0.30f0, 0.22f0, 0.08f0, 1.0f0)
const _ACCESSOR_KWARGS = (:nodevalue, :branchingtime, :coalescenceage, :nodecoordinates, :nodepos)

function _require_rooted_full_network(net::PhyloNetworks.HybridNetwork)::Nothing
    net.isrooted || throw(
        ArgumentError(
            "lineageplot(::PhyloNetworks.HybridNetwork) currently supports rooted full-network views only; " *
                "got net.isrooted = false. Major-tree, projected-tree, semidirected, and unrooted " *
                "display policies remain deferred.",
        ),
    )
    return nothing
end

function _hybridnetwork_edge_metadata(
        net::PhyloNetworks.HybridNetwork,
    )::_HybridNetworkOverlayMetadata
    edge_metadata = Dict{Tuple{PhyloNetworks.Node, PhyloNetworks.Node}, Vector{_HybridEdgeMetadata}}()
    for parent_node in net.node
        for edge in parent_node.edge
            PhyloNetworks.getparent(edge) === parent_node || continue
            child_node = PhyloNetworks.getchild(edge)
            push!(
                get!(
                    () -> _HybridEdgeMetadata[],
                    edge_metadata,
                    (parent_node, child_node),
                ),
                _HybridEdgeMetadata(edge, edge.gamma, edge.ismajor),
            )
        end
    end
    return _HybridNetworkOverlayMetadata(edge_metadata, collect(net.hybrid))
end

function _hybridnetwork_nodevalue(node)::String
    return isempty(node.name) ? string(node.number) : String(node.name)
end

function _namedtuple_without_keys(
        kwargs::NamedTuple,
        keys::Tuple,
    )::NamedTuple
    return (; (pair for pair in pairs(kwargs) if pair.first ∉ keys)...)
end

function _namedtuple_get(kwargs::NamedTuple, key::Symbol, default)
    return haskey(kwargs, key) ? kwargs[key] : default
end

function _duplicate_endpoint_edgeweight_error(
        edge_key::Tuple{PhyloNetworks.Node, PhyloNetworks.Node},
        edge_group::Vector{_HybridEdgeMetadata},
    )::ArgumentError
    src, dst = edge_key
    return ArgumentError(
        "lineageunits = :edgeweights cannot be supported honestly for rooted full-network duplicate-endpoint edges " *
            "under the current public edgeweight(src, dst) accessor contract; parent $(repr(src)) and child " *
            "$(repr(dst)) are connected by $(length(edge_group)) distinct upstream edges. Select node-based units, " *
            "explicit coordinates, or a future projected-tree contract instead.",
    )
end

function _require_unambiguous_edgeweights(
        metadata::_HybridNetworkOverlayMetadata,
        lineageunits::Symbol,
    )::Nothing
    lineageunits === :edgeweights || return nothing
    for (edge_key, edge_group) in metadata.edge_metadata
        length(edge_group) == 1 && continue
        throw(_duplicate_endpoint_edgeweight_error(edge_key, edge_group))
    end
    return nothing
end

function _hybridnetwork_accessor(
        net::PhyloNetworks.HybridNetwork,
        kwargs::NamedTuple,
    )::Tuple{PhyloNetworks.Node, LineagesMakie.LineageGraphAccessor, _HybridNetworkOverlayMetadata}
    metadata = _hybridnetwork_edge_metadata(net)
    edge_lookup = metadata.edge_metadata
    root = PhyloNetworks.getroot(net)

    edgeweight = function (src, dst)
        edge_key = (src, dst)
        edge_group = get(edge_lookup, edge_key, nothing)
        edge_group === nothing && throw(
            ArgumentError(
                "could not resolve upstream edge metadata for parent $(repr(src)) and child $(repr(dst))",
            ),
        )
        length(edge_group) == 1 || throw(_duplicate_endpoint_edgeweight_error(edge_key, edge_group))
        return edge_group[1].edge.length
    end

    nodevalue = _namedtuple_get(kwargs, :nodevalue, _hybridnetwork_nodevalue)
    branchingtime = _namedtuple_get(kwargs, :branchingtime, nothing)
    coalescenceage = _namedtuple_get(kwargs, :coalescenceage, nothing)
    nodecoordinates = _namedtuple_get(kwargs, :nodecoordinates, nothing)
    nodepos = _namedtuple_get(kwargs, :nodepos, nothing)

    accessor = LineagesMakie.lineagegraph_accessor(
        root;
        children = PhyloNetworks.getchildren,
        edgeweight = edgeweight,
        nodevalue = nodevalue,
        branchingtime = branchingtime,
        coalescenceage = coalescenceage,
        nodecoordinates = nodecoordinates,
        nodepos = nodepos,
    )

    return root, accessor, metadata
end

function _resolved_lineageunits(lineageunits)::Symbol
    return lineageunits === nothing ? :nodelevels : lineageunits
end

function _geometry_edge_metadata(
        geom,
        metadata::_HybridNetworkOverlayMetadata,
    )::Vector{_HybridEdgeMetadata}
    edge_offsets = Dict{Tuple{PhyloNetworks.Node, PhyloNetworks.Node}, Int}()
    ordered_metadata = _HybridEdgeMetadata[]
    sizehint!(ordered_metadata, length(geom.edges))

    for edge_key in geom.edges
        edge_group = get(metadata.edge_metadata, edge_key, nothing)
        edge_group === nothing && throw(
            ArgumentError(
                "could not align geometry-owned edge $(repr(edge_key)) with upstream edge metadata",
            ),
        )
        edge_offset = get(edge_offsets, edge_key, 0) + 1
        edge_offsets[edge_key] = edge_offset
        edge_offset <= length(edge_group) || throw(
            ArgumentError(
                "geometry-owned edge order for $(repr(edge_key)) exceeded the available upstream edge multiplicity",
            ),
        )
        push!(ordered_metadata, edge_group[edge_offset])
    end

    return ordered_metadata
end

function _reticulation_edge_indices(
        geom,
        metadata::_HybridNetworkOverlayMetadata,
        ismajor::Bool,
    )::Vector{Int}
    edge_indices = Int[]
    for (i, edge_meta) in enumerate(_geometry_edge_metadata(geom, metadata))
        edge_meta.edge.hybrid || continue
        edge_meta.ismajor === ismajor || continue
        push!(edge_indices, i)
    end
    return edge_indices
end

function _reticulation_gamma_payload(
        geom,
        metadata::_HybridNetworkOverlayMetadata,
    )::NamedTuple{(:edge_indices, :labels, :colors), Tuple{Vector{Int}, Vector{String}, Vector{Makie.RGBAf}}}
    edge_indices = Int[]
    labels = String[]
    colors = Makie.RGBAf[]
    for (i, edge_meta) in enumerate(_geometry_edge_metadata(geom, metadata))
        edge_meta.edge.hybrid || continue
        push!(edge_indices, i)
        push!(labels, string(round(edge_meta.gamma; digits = 3)))
        push!(colors, edge_meta.ismajor ? _RETICULATION_MAJOR_COLOR : _RETICULATION_MINOR_COLOR)
    end
    return (; edge_indices, labels, colors)
end

function _hybrid_node_positions(
        geom,
        metadata::_HybridNetworkOverlayMetadata,
    )::Vector{Makie.Point2f}
    return Makie.Point2f[
        geom.node_positions[node] for node in metadata.hybrid_nodes if haskey(geom.node_positions, node)
    ]
end

function _add_reticulation_overlays!(
        lp::LineagesMakie.LineagePlot,
        metadata::_HybridNetworkOverlayMetadata,
    )::Nothing
    Makie.map!(lp.attributes, [:computed_geom], :reticulation_major_shapes) do geom
        _edge_shape_subset(geom, _reticulation_edge_indices(geom, metadata, true))
    end
    Makie.map!(lp.attributes, [:computed_geom], :reticulation_minor_shapes) do geom
        _edge_shape_subset(geom, _reticulation_edge_indices(geom, metadata, false))
    end
    Makie.map!(lp.attributes, [:computed_geom], :reticulation_hybrid_positions) do geom
        _hybrid_node_positions(geom, metadata)
    end
    Makie.map!(lp.attributes, [:computed_geom], :reticulation_gamma_payload) do geom
        _reticulation_gamma_payload(geom, metadata)
    end

    Makie.map!(
        lp.attributes,
        [:computed_geom, :reticulation_gamma_payload],
        :reticulation_gamma_positions,
    ) do geom, payload
        _edge_label_anchor_positions(geom, payload.edge_indices)
    end
    Makie.map!(lp.attributes, [:reticulation_gamma_payload], :reticulation_gamma_labels) do payload
        payload.labels
    end
    Makie.map!(lp.attributes, [:reticulation_gamma_payload], :reticulation_gamma_colors) do payload
        payload.colors
    end

    Makie.lines!(
        lp,
        lp[:reticulation_major_shapes];
        color = _RETICULATION_MAJOR_COLOR,
        linewidth = 3.0,
        visible = lp[:edge_visible],
        alpha = lp[:edge_alpha],
    )

    Makie.lines!(
        lp,
        lp[:reticulation_minor_shapes];
        color = _RETICULATION_MINOR_COLOR,
        linewidth = 3.0,
        linestyle = :dash,
        visible = lp[:edge_visible],
        alpha = lp[:edge_alpha],
    )

    Makie.scatter!(
        lp,
        lp[:reticulation_hybrid_positions];
        marker = :diamond,
        color = _HYBRID_NODE_FILL_COLOR,
        strokecolor = _HYBRID_NODE_STROKE_COLOR,
        markersize = 16,
        markerspace = :pixel,
        visible = lp[:node_visible],
        alpha = lp[:node_alpha],
    )

    Makie.text!(
        lp,
        lp[:reticulation_gamma_positions];
        text = lp[:reticulation_gamma_labels],
        color = lp[:reticulation_gamma_colors],
        fontsize = 10,
        align = (:center, :baseline),
        offset = Makie.Vec2f(0, -6),
        visible = lp[:edge_visible],
    )

    return nothing
end

function lineageplot!(
        ax,
        net::PhyloNetworks.HybridNetwork;
        lineageunits = nothing,
        kwargs...,
    )::LineagesMakie.LineagePlot
    _require_rooted_full_network(net)
    keyword_args = (; kwargs...)
    resolved_lineageunits = _resolved_lineageunits(lineageunits)
    root, accessor, metadata = _hybridnetwork_accessor(net, keyword_args)
    _require_unambiguous_edgeweights(metadata, resolved_lineageunits)
    plot_kwargs = _namedtuple_without_keys(keyword_args, _ACCESSOR_KWARGS)
    lp = LineagesMakie.lineageplot!(
        ax,
        root,
        accessor;
        lineageunits = resolved_lineageunits,
        plot_kwargs...,
    )
    _add_reticulation_overlays!(lp, metadata)
    return lp
end

function lineageplot(
        net::PhyloNetworks.HybridNetwork;
        figure = NamedTuple(),
        axis = NamedTuple(),
        kwargs...,
    )::Makie.FigureAxisPlot
    figure_kwargs = LineagesMakie._layout_kwargs_namedtuple(figure, "figure")
    axis_kwargs = LineagesMakie._layout_kwargs_namedtuple(axis, "axis")
    fig = Makie.Figure(; figure_kwargs...)
    lax = LineagesMakie.LineageAxis(fig[1, 1]; axis_kwargs...)
    lp = lineageplot!(lax, net; kwargs...)
    return Makie.FigureAxisPlot(fig, lax, lp)
end

end # module PhyloNetworksExt
