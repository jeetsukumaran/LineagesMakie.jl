# Tests for LineageAxis
#
# All tests use real CairoMakie scenes. CairoMakie re-exports all Makie types.

import CairoMakie
# Makie is a transitive dependency via CairoMakie; access it through CairoMakie.Makie
# rather than declaring it as a direct test dependency.
const Makie = CairoMakie.Makie
using CairoMakie: Figure, Axis
using CairoMakie: colorbuffer

# ── Fixtures ──────────────────────────────────────────────────────────────────

struct LATestNode
    name::String
    children::Vector{LATestNode}
end

#   root
#   ├── ab
#   │   ├── a
#   │   └── b
#   └── cd
#       ├── c
#       └── d
const _LA_BALANCED_BASENODE = LATestNode("root", [
    LATestNode("ab", [
        LATestNode("a", LATestNode[]),
        LATestNode("b", LATestNode[]),
    ]),
    LATestNode("cd", [
        LATestNode("c", LATestNode[]),
        LATestNode("d", LATestNode[]),
    ]),
])

const _LA_ACC = lineagegraph_accessor(_LA_BALANCED_BASENODE; children = node -> node.children)
const _LA_NONBASENODE_CLADE = _LA_BALANCED_BASENODE.children[1]
const _LA_LARGE_COALESCENCEAGES = Dict(
    "root" => 20.0,
    "ab" => 10.0,
    "cd" => 10.0,
    "a" => 0.0,
    "b" => 0.0,
    "c" => 0.0,
    "d" => 0.0,
)
const _LA_COALESCENCE_ACC_LARGE = lineagegraph_accessor(
    _LA_BALANCED_BASENODE;
    children = node -> node.children,
    coalescenceage = node -> _LA_LARGE_COALESCENCEAGES[node.name],
)
const _LA_REORDERED_NODEPOS = Dict{String, Makie.Point2f}(
    "root" => Makie.Point2f(0, 250),
    "ab" => Makie.Point2f(10, 150),
    "cd" => Makie.Point2f(10, 350),
    "a" => Makie.Point2f(20, 400),
    "b" => Makie.Point2f(20, 100),
    "c" => Makie.Point2f(20, 300),
    "d" => Makie.Point2f(20, 200),
)
const _LA_REORDERED_LEAF_ORDER = ["b", "d", "c", "a"]

mutable struct LADagNode
    name::String
    children::Vector{LADagNode}
end

const _LA_SHARED_DESCENDANT_DAG = let
    shared = LADagNode("shared", LADagNode[])
    left = LADagNode("left", LADagNode[shared])
    right = LADagNode("right", LADagNode[shared])
    LADagNode("root", LADagNode[left, right])
end

const _LA_DAG_ACC = lineagegraph_accessor(
    _LA_SHARED_DESCENDANT_DAG;
    children = node -> node.children,
)

# ── Helpers ───────────────────────────────────────────────────────────────────

function _fresh_lax(; kwargs...)
    fig = Figure(; size = (400, 300))
    lax = LineageAxis(fig[1, 1]; kwargs...)
    return fig, lax
end

function _plotted_lax(; lineageunits = nothing, lax_kwargs...)
    fig, lax = _fresh_lax(; lax_kwargs...)
    lp = lineageplot!(lax, _LA_BALANCED_BASENODE, _LA_ACC; lineageunits = lineageunits)
    return fig, lax, lp
end

function _visible_blockscene_strings(lax::LineageAxis)::Vector{String}
    strings = String[]
    for plot in lax.blockscene.plots
        plot isa Makie.Text || continue
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

function _tick_labels_for_rect(rect::Makie.Rect2f, axis::Symbol)::Vector{String}
    lower = axis === :x ? Float32(Makie.minimum(rect)[1]) : Float32(Makie.minimum(rect)[2])
    upper = axis === :x ? Float32(Makie.maximum(rect)[1]) : Float32(Makie.maximum(rect)[2])
    values = LineagesMakie._axis_tick_values(lower, upper)
    return LineagesMakie._axis_tick_labels(values)
end

function _displayed_extent_tick_labels(geom, axis::Symbol)::Vector{String}
    return _tick_labels_for_rect(LineagesMakie.Geometry._plot_envelope(geom), axis)
end

function _node_envelope_tick_labels(geom, axis::Symbol)::Vector{String}
    return _tick_labels_for_rect(geom.boundingbox, axis)
end

function _grid_line_axis_coords(segments::Vector{Makie.Point2f})
    vertical = Float32[]
    horizontal = Float32[]
    i = 1
    while i <= length(segments) - 2
        p1 = segments[i]
        p2 = segments[i + 1]
        p3 = segments[i + 2]
        @test isnan(p3[1]) && isnan(p3[2])
        if isapprox(p1[1], p2[1]; atol = 1.0f-3)
            push!(vertical, Float32(p1[1]))
        else
            push!(horizontal, Float32(p1[2]))
        end
        i += 3
    end
    return vertical, horizontal
end

function _expected_yaxis_band_width_px(labels::Vector{String})::Float32
    tick_width_px, _ = LineagesMakie._max_text_size_px(
        labels,
        Makie.defaultfont(),
        LineagesMakie._LINEAGEAXIS_TICK_FONTSIZE,
    )
    return max(
        LineagesMakie._LINEAGEAXIS_YAXIS_MIN_BAND_PX,
        tick_width_px +
        LineagesMakie._LINEAGEAXIS_TICK_LENGTH_PX +
        LineagesMakie._LINEAGEAXIS_YAXIS_LABEL_GAP_PX +
        6.0f0,
    )
end

# ── Tests ─────────────────────────────────────────────────────────────────────

@testset "LineageAxis" begin

    @testset "construction and default attributes" begin
        fig, lax = _fresh_lax()
        @test lax isa LineageAxis
        @test lax.display_polarity[] === :standard
        @test lax.lineage_orientation[] === :left_to_right
        @test lax.axis_polarity[] === :forward
        @test lax.show_x_axis[] === false
        @test lax.show_y_axis[] === false
        @test lax.show_grid[] === false
        @test lax.title[] == ""
        @test lax.xlabel[] == ""
        @test lax.ylabel[] == ""
    end

    @testset "lineageplot! on LineageAxis renders without error" begin
        fig, lax, lp = _plotted_lax()
        @test lp isa LineagePlot
        @test lax.last_geom[] !== nothing
        @test_nowarn colorbuffer(fig)
    end

    @testset "shared-descendant DAG lineageplot! on LineageAxis renders without error" begin
        fig, lax = _fresh_lax()
        lp = lineageplot!(
            lax,
            _LA_SHARED_DESCENDANT_DAG,
            _LA_DAG_ACC;
            lineageunits = :nodelevels,
        )
        geom = lax.last_geom[]
        @test lp isa LineagePlot
        @test geom !== nothing
        @test length(geom.node_positions) == 4
        @test [(src.name, dst.name) for (src, dst) in geom.edges] ==
            [("root", "left"), ("left", "shared"), ("root", "right"), ("right", "shared")]
        @test_nowarn colorbuffer(fig)
    end

    @testset "lineageplot! on plain Axis (no regression)" begin
        fig = Figure(; size = (400, 300))
        ax = Axis(fig[1, 1])
        acc = lineagegraph_accessor(_LA_BALANCED_BASENODE; children = node -> node.children)
        lp = lineageplot!(ax, _LA_BALANCED_BASENODE, acc)
        @test lp isa LineagePlot
        @test_nowarn colorbuffer(fig)
    end

    @testset "plain Axis keeps plot-owned vertical orientation support" begin
        fig = Figure(; size = (400, 300))
        ax = Axis(fig[1, 1])
        lp = lineageplot!(
            ax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            lineageunits = :nodelevels,
            lineage_orientation = :top_to_bottom,
        )
        geom = lp[:computed_geom][]
        leaf_positions = [geom.node_positions[node] for node in geom.leaf_order]
        leaf_ys = unique(round(pos[2]; digits = 5) for pos in leaf_positions)
        leaf_xs = unique(round(pos[1]; digits = 5) for pos in leaf_positions)
        @test lp[:lineage_orientation][] === :top_to_bottom
        @test lp[:rectangular_orientation_owner][] === :plot
        @test length(leaf_ys) == 1
        @test length(leaf_xs) > 1
        @test_nowarn colorbuffer(fig)
    end

    @testset "reset_limits! with :standard display_polarity" begin
        fig, lax, _ = _plotted_lax(; display_polarity = :standard)
        proj = Makie.camera(lax.scene).projection[]
        # orthographic x-scale > 0: left < right (standard direction)
        @test proj[1, 1] > 0
    end

    @testset "reset_limits! with :reversed display_polarity" begin
        fig, lax, _ = _plotted_lax(; display_polarity = :reversed)
        proj = Makie.camera(lax.scene).projection[]
        # orthographic x-scale < 0: left > right (reversed direction)
        @test proj[1, 1] < 0
    end

    @testset "lineage_orientation :right_to_left matches :reversed on :left_to_right" begin
        fig_rtl, lax_rtl, _ = _plotted_lax(; lineage_orientation = :right_to_left)
        fig_rev, lax_rev, _ = _plotted_lax(; display_polarity = :reversed)
        proj_rtl = Makie.camera(lax_rtl.scene).projection[]
        proj_rev = Makie.camera(lax_rev.scene).projection[]
        # Both should have x-scale < 0; exact values match because the same
        # geometry is used and the same effective_reversed=true path is taken.
        @test proj_rtl[1, 1] < 0
        @test proj_rev[1, 1] < 0
        @test proj_rtl[1, 1] ≈ proj_rev[1, 1]
    end

    @testset "lineage_orientation :bottom_to_top uses positive y projection" begin
        fig, lax, _ = _plotted_lax(; lineage_orientation = :bottom_to_top)
        proj = Makie.camera(lax.scene).projection[]
        @test proj[2, 2] > 0
    end

    @testset "lineage_orientation :top_to_bottom uses negative y projection" begin
        fig, lax, _ = _plotted_lax(; lineage_orientation = :top_to_bottom)
        proj = Makie.camera(lax.scene).projection[]
        @test proj[2, 2] < 0
    end

    @testset "axis-owned vertical orientation propagates into computed geometry" begin
        fig, lax = _fresh_lax(; lineage_orientation = :top_to_bottom)
        lp = lineageplot!(lax, _LA_BALANCED_BASENODE, _LA_ACC; lineageunits = :nodelevels)
        geom = lp[:computed_geom][]
        leaf_positions = [geom.node_positions[node] for node in geom.leaf_order]
        leaf_ys = unique(round(pos[2]; digits = 5) for pos in leaf_positions)
        leaf_xs = unique(round(pos[1]; digits = 5) for pos in leaf_positions)
        @test lp[:lineage_orientation][] === :top_to_bottom
        @test length(leaf_ys) == 1
        @test length(leaf_xs) > 1
    end

    @testset "lineageplot! keyword orientation normalizes through LineageAxis ownership" begin
        fig, lax = _fresh_lax(; lineage_orientation = :left_to_right)
        lp = lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            lineageunits = :nodelevels,
            lineage_orientation = :top_to_bottom,
            rectangular_orientation_owner = :plot,
        )
        geom = lp[:computed_geom][]
        leaf_positions = [geom.node_positions[node] for node in geom.leaf_order]
        leaf_ys = unique(round(pos[2]; digits = 5) for pos in leaf_positions)
        leaf_xs = unique(round(pos[1]; digits = 5) for pos in leaf_positions)
        @test lax.lineage_orientation[] === :top_to_bottom
        @test lp[:lineage_orientation][] === :top_to_bottom
        @test lp[:rectangular_orientation_owner][] === :lineageaxis
        @test length(leaf_ys) == 1
        @test length(leaf_xs) > 1
    end

    @testset "lineage_orientation :radial produces equal x and y extents" begin
        fig, lax, _ = _plotted_lax(; lineage_orientation = :radial)
        proj = Makie.camera(lax.scene).projection[]
        # For a square viewport, x-scale == y-scale in the projection.
        # Both are 1/half = 2/(right-left) = 2/(top-bottom).
        @test proj[1, 1] ≈ proj[2, 2] atol = 1f-5
    end

    @testset "axis_polarity inferred from lineageunits when unlocked" begin
        # :nodeheights and the default (which resolves to :nodeheights for a
        # children-only accessor) should produce :backward.
        fig1, lax1, _ = _plotted_lax(; lineageunits = :nodeheights)
        @test lax1.axis_polarity[] === :backward

        # Default (nothing) resolves to :nodeheights → :backward.
        fig2, lax2, _ = _plotted_lax()
        @test lax2.axis_polarity[] === :backward

        # :nodelevels and :nodedepths are forward and require no special accessor.
        fig3, lax3, _ = _plotted_lax(; lineageunits = :nodelevels)
        @test lax3.axis_polarity[] === :forward

        fig4, lax4, _ = _plotted_lax(; lineageunits = :nodedepths)
        @test lax4.axis_polarity[] === :forward
    end

    @testset "axis_polarity not overwritten after manual override" begin
        fig, lax = _fresh_lax()
        # Setting to :backward (different from default :forward) fires the lock observer.
        lax.axis_polarity[] = :backward
        @test lax._polarity_locked[]
        # lineageplot! with :nodelevels would infer :forward, but lock prevents it.
        # :nodelevels works with a children-only accessor.
        lineageplot!(lax, _LA_BALANCED_BASENODE, _LA_ACC; lineageunits = :nodelevels)
        @test lax.axis_polarity[] === :backward
    end

    @testset "_polarity_locked fires on user change, not on default init" begin
        fig, lax = _fresh_lax()
        # Default attribute assignment (:forward) must NOT trigger the lock.
        @test !lax._polarity_locked[]
        # Explicit user assignment triggers the lock.
        lax.axis_polarity[] = :backward
        @test lax._polarity_locked[]
    end

    @testset "show_x_axis = false (default) — no visible tick marks" begin
        fig, lax, _ = _plotted_lax()
        @test lax.show_x_axis[] === false
        # colorbuffer should succeed without tick-related errors.
        @test_nowarn colorbuffer(fig)
    end

    @testset "show_x_axis = true — tick elements become visible" begin
        fig, lax, _ = _plotted_lax()
        lax.show_x_axis[] = true
        # Render confirms no error when ticks are active.
        @test_nowarn colorbuffer(fig)
        @test !isempty(lax._xaxis_tick_segments[])
        line_plots = filter(p -> p isa Makie.Lines, lax.blockscene.plots)
        @test !isempty(line_plots)
        @test any(p -> p.visible[], line_plots)
    end

    @testset "show_x_axis reactive toggle" begin
        fig, lax, _ = _plotted_lax()
        lax.show_x_axis[] = true
        @test !isempty(lax._xaxis_tick_segments[])
        # Toggling back to false hides the ticks.
        lax.show_x_axis[] = false
        @test isempty(lax._xaxis_tick_segments[])
        @test isempty(lax._xaxis_tick_positions[])
    end

    @testset "show_y_axis = true renders tick elements and ylabel" begin
        fig, lax, _ = _plotted_lax(; lineage_orientation = :top_to_bottom)
        lax.show_y_axis[] = true
        lax.ylabel[] = "Lineage distance"
        @test_nowarn colorbuffer(fig)
        @test !isempty(lax._yaxis_tick_segments[])
        @test "Lineage distance" in _visible_blockscene_strings(lax)
    end

    @testset "show_y_axis reactive toggle" begin
        fig, lax, _ = _plotted_lax(; lineage_orientation = :top_to_bottom)
        lax.show_y_axis[] = true
        @test !isempty(lax._yaxis_tick_segments[])
        lax.show_y_axis[] = false
        @test isempty(lax._yaxis_tick_segments[])
        @test isempty(lax._yaxis_tick_positions[])
    end

    @testset "show_grid follows visible screen axes" begin
        fig, lax, _ = _plotted_lax(; lineage_orientation = :top_to_bottom)
        lax.show_y_axis[] = true
        lax.show_grid[] = true
        @test_nowarn colorbuffer(fig)
        @test !isempty(lax._grid_segments[])
        lax.show_grid[] = false
        @test isempty(lax._grid_segments[])
    end

    @testset "invalid lineage_orientation fails fast" begin
        fig, lax = _fresh_lax()
        @test_throws r"unsupported lineage_orientation" lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            lineage_orientation = :diagonal,
        )
    end

    @testset "measured annotation layout reserves coordinated right-side lanes" begin
        fig, lax = _fresh_lax()
        lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            lineageunits = :nodelevels,
            leaf_label_func = node -> "species_" * node.name,
            clade_nodes = [_LA_NONBASENODE_CLADE],
            clade_label_func = node -> "clade_" * node.name,
        )
        colorbuffer(fig)

        layout = lax._decoration_layout[]
        @test layout.active_annotation_side === :right
        @test layout.right_gutter_px > layout.left_gutter_px
        @test isfinite(layout.leaf_label_anchor_x)
        @test layout.leaf_label_outer_edge_x < layout.clade_bracket_x - layout.clade_tick_length_px
        @test layout.clade_bracket_x < layout.clade_label_anchor_x
    end

    @testset "measured annotation layout mirrors to the left side" begin
        fig, lax = _fresh_lax(; lineage_orientation = :right_to_left)
        lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            lineageunits = :nodelevels,
            leaf_label_func = node -> "species_" * node.name,
            clade_nodes = [_LA_NONBASENODE_CLADE],
            clade_label_func = node -> "clade_" * node.name,
        )
        colorbuffer(fig)

        layout = lax._decoration_layout[]
        @test layout.active_annotation_side === :left
        @test layout.left_gutter_px > layout.right_gutter_px
        @test isfinite(layout.leaf_label_anchor_x)
        @test layout.leaf_label_outer_edge_x > layout.clade_bracket_x + layout.clade_tick_length_px
        @test layout.clade_label_anchor_x < layout.clade_bracket_x
    end

    @testset "measured annotation layout reserves coordinated top-side lanes" begin
        fig, lax = _fresh_lax(; lineage_orientation = :bottom_to_top)
        lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            lineageunits = :nodelevels,
            leaf_label_func = node -> "species_" * node.name,
            clade_nodes = [_LA_NONBASENODE_CLADE],
            clade_label_func = node -> "clade_" * node.name,
        )
        colorbuffer(fig)

        layout = lax._decoration_layout[]
        @test layout.active_annotation_side === :top
        @test layout.top_gutter_px > layout.bottom_gutter_px
        @test isfinite(layout.leaf_label_anchor_y)
        @test layout.leaf_label_outer_edge_y < layout.clade_bracket_y - layout.clade_tick_length_px
        @test layout.clade_bracket_y < layout.clade_label_anchor_y
    end

    @testset "measured annotation layout reserves coordinated bottom-side lanes" begin
        fig, lax = _fresh_lax(; lineage_orientation = :top_to_bottom)
        lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            lineageunits = :nodelevels,
            leaf_label_func = node -> "species_" * node.name,
            clade_nodes = [_LA_NONBASENODE_CLADE],
            clade_label_func = node -> "clade_" * node.name,
        )
        colorbuffer(fig)

        layout = lax._decoration_layout[]
        @test layout.active_annotation_side === :bottom
        @test layout.bottom_gutter_px > layout.top_gutter_px
        @test isfinite(layout.leaf_label_anchor_y)
        @test layout.leaf_label_outer_edge_y > layout.clade_bracket_y + layout.clade_tick_length_px
        @test layout.clade_label_anchor_y < layout.clade_bracket_y
    end

    @testset "node-group labels share measured annotation lanes on shared-parent DAG displays" begin
        fig, lax = _fresh_lax()
        group_nodes = _LA_SHARED_DESCENDANT_DAG.children
        lp = lineageplot!(
            lax,
            _LA_SHARED_DESCENDANT_DAG,
            _LA_DAG_ACC;
            lineageunits = :nodelevels,
            leaf_label_func = node -> "node_" * node.name,
            group_nodes = group_nodes,
            nodegroup_label_func = nodes -> join(String[node.name for node in nodes], " + "),
        )
        colorbuffer(fig)

        layout = lax._decoration_layout[]
        ngl = only(filter(p -> p isa NodeGroupLabelLayer, lp.plots))

        @test layout.active_annotation_side === :right
        @test all(
            pos -> isapprox(pos[1], layout.clade_label_anchor_x; atol = 1.0f-3),
            ngl[:bracket_label_pixel_positions][],
        )

        bracket_xs = unique(Float32[pt[1] for pt in ngl[:bracket_pixel_shapes][] if isfinite(pt[1])])
        @test any(x -> isapprox(x, layout.clade_bracket_x; atol = 1.0f-3), bracket_xs)
    end

    @testset "radial annotation layout uses measured outer padding" begin
        fig, lax = _fresh_lax(; lineage_orientation = :radial)
        lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            lineage_orientation = :radial,
            leaf_label_func = node -> "species_" * node.name * "_label",
        )
        colorbuffer(fig)

        layout = lax._decoration_layout[]
        @test layout.active_annotation_side === :radial
        @test layout.left_gutter_px ≈ layout.right_gutter_px
        @test layout.radial_outer_pad_px > 24.0f0
    end

    @testset "LineageAxis keeps explicit nodepos leaf labels aligned with rendered order" begin
        fig, lax = _fresh_lax()
        acc = lineagegraph_accessor(
            _LA_BALANCED_BASENODE;
            children = node -> node.children,
            nodepos = node -> _LA_REORDERED_NODEPOS[node.name],
        )
        lp = lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            acc;
            lineageunits = :nodepos,
            leaf_label_func = node -> node.name,
        )
        colorbuffer(fig)

        geom = lax.last_geom[]
        labels = only(filter(p -> p isa LeafLabelLayer, lp.plots))
        geom_leaf_ys = [Float32(geom.node_positions[node][2]) for node in geom.leaf_order]
        label_ys = [Float32(pt[2]) for pt in labels[:leaf_label_positions][]]
        @test [node.name for node in geom.leaf_order] == _LA_REORDERED_LEAF_ORDER
        @test labels[:leaf_label_strings][] == _LA_REORDERED_LEAF_ORDER
        @test _visible_blockscene_strings(lax) == _LA_REORDERED_LEAF_ORDER
        @test issorted(geom_leaf_ys)
        @test issorted(label_ys)
    end

    @testset "scale bar reserves a bottom decoration band when visible" begin
        fig, lax = _fresh_lax(; show_x_axis = true)
        lp = lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            lineagegraph_accessor(
                _LA_BALANCED_BASENODE;
                children = node -> node.children,
                edgeweight = (src, dst) -> 1.0,
            );
            lineageunits = :edgeweights,
            scalebar_auto_visible = true,
            scalebar_label = "1 unit",
        )
        colorbuffer(fig)

        layout = lax._decoration_layout[]
        scalebar = only(filter(p -> p isa ScaleBarLayer, lp.plots))
        @test layout.scalebar_visible
        @test layout.scalebar_band_rect.widths[2] > 0.0f0
        @test length(scalebar[:scalebar_line_pixel_pts][]) == 2
        @test all(pt -> isfinite(pt[1]) && isfinite(pt[2]), scalebar[:scalebar_line_pixel_pts][])
        line_y = scalebar[:scalebar_line_pixel_pts][][1][2]
        band_bottom = layout.scalebar_band_rect.origin[2]
        band_top = band_bottom + layout.scalebar_band_rect.widths[2]
        @test band_bottom <= line_y <= band_top
        xaxis_top = layout.xaxis_band_rect.origin[2] + layout.xaxis_band_rect.widths[2]
        @test xaxis_top <= layout.scalebar_band_rect.origin[2]
    end

    @testset "radial limits contain full rendered backward-time geometry" begin
        fig, lax = _fresh_lax(; lineage_orientation = :radial)
        lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            lineageunits = :nodeheights,
            lineage_orientation = :radial,
        )
        colorbuffer(fig)

        geom = lax.last_geom[]
        plot_bb = LineagesMakie.Geometry._plot_envelope(geom)
        vp = Makie.viewport(lax.scene)[]
        vp_w = Float32(Makie.widths(vp)[1])
        vp_h = Float32(Makie.widths(vp)[2])
        @test plot_bb.widths[1] > geom.boundingbox.widths[1] ||
            plot_bb.widths[2] > geom.boundingbox.widths[2]
        for pt in geom.edge_shapes
            isfinite(pt[1]) && isfinite(pt[2]) || continue
            px = data_to_pixel(lax.scene, pt)
            @test -1.0f-3 <= px[1] <= vp_w + 1.0f-3
            @test -1.0f-3 <= px[2] <= vp_h + 1.0f-3
        end
    end

    @testset "radial quantitative axes and grid share the displayed extent owner" begin
        fig, lax = _fresh_lax(;
            lineage_orientation = :radial,
            show_x_axis = true,
            show_y_axis = true,
            show_grid = true,
        )
        lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            lineageunits = :nodeheights,
            lineage_orientation = :radial,
        )
        colorbuffer(fig)

        geom = lax.last_geom[]
        plot_bb = LineagesMakie.Geometry._plot_envelope(geom)
        expected_xlabels = _displayed_extent_tick_labels(geom, :x)
        expected_ylabels = _displayed_extent_tick_labels(geom, :y)
        @test plot_bb.widths[1] > geom.boundingbox.widths[1] ||
            plot_bb.widths[2] > geom.boundingbox.widths[2]
        @test expected_xlabels != _node_envelope_tick_labels(geom, :x)
        @test expected_ylabels != _node_envelope_tick_labels(geom, :y)
        @test lax._xaxis_tick_labels[] == expected_xlabels
        @test lax._yaxis_tick_labels[] == expected_ylabels

        vertical_xs, horizontal_ys = _grid_line_axis_coords(lax._grid_segments[])
        x_tick_xs = sort(Float32[pt[1] for pt in lax._xaxis_tick_positions[]])
        y_tick_ys = sort(Float32[pt[2] for pt in lax._yaxis_tick_positions[]])
        @test length(vertical_xs) == length(x_tick_xs)
        @test length(horizontal_ys) == length(y_tick_ys)
        for (actual, expected) in zip(sort(vertical_xs), x_tick_xs)
            @test actual ≈ expected atol = 1.0f-3
        end
        for (actual, expected) in zip(sort(horizontal_ys), y_tick_ys)
            @test actual ≈ expected atol = 1.0f-3
        end
    end

    @testset "radial y-axis band measurement follows the displayed extent owner" begin
        fig, lax = _fresh_lax(; lineage_orientation = :radial, show_y_axis = true)
        lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_COALESCENCE_ACC_LARGE;
            lineageunits = :coalescenceage,
            lineage_orientation = :radial,
        )
        colorbuffer(fig)

        geom = lax.last_geom[]
        expected_labels = _displayed_extent_tick_labels(geom, :y)
        stale_labels = _node_envelope_tick_labels(geom, :y)
        expected_width = _expected_yaxis_band_width_px(expected_labels)
        stale_width = _expected_yaxis_band_width_px(stale_labels)
        actual_width = lax._decoration_layout[].yaxis_band_rect.widths[1]
        @test expected_labels != stale_labels
        @test !isapprox(expected_width, stale_width; atol = 0.5f0)
        @test actual_width ≈ expected_width atol = 1.0f-3
        @test !isapprox(actual_width, stale_width; atol = 0.5f0)
    end

    @testset "radial scale bar is auto-hidden when unlabeled" begin
        fig, lax = _fresh_lax(; lineage_orientation = :radial)
        lp = lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            lineagegraph_accessor(
                _LA_BALANCED_BASENODE;
                children = node -> node.children,
                edgeweight = (src, dst) -> 1.0,
            );
            lineageunits = :edgeweights,
            lineage_orientation = :radial,
        )
        colorbuffer(fig)

        layout = lax._decoration_layout[]
        scalebar = only(filter(p -> p isa ScaleBarLayer, lp.plots))
        @test !layout.scalebar_visible
        @test layout.scalebar_band_rect.widths[2] == 0.0f0
        @test scalebar[:resolved_visible][] == false
    end

    @testset "autolimits! re-applies limits from stored geometry" begin
        fig, lax, _ = _plotted_lax()
        proj_before = Makie.camera(lax.scene).projection[]
        Makie.autolimits!(lax)
        proj_after = Makie.camera(lax.scene).projection[]
        @test proj_before ≈ proj_after
    end

    @testset "tightlimits! is a no-op" begin
        fig, lax, _ = _plotted_lax()
        proj_before = Makie.camera(lax.scene).projection[]
        Makie.tightlimits!(lax)
        proj_after = Makie.camera(lax.scene).projection[]
        @test proj_before ≈ proj_after
    end

    @testset "reset_limits! one-arg no-ops before lineageplot!" begin
        fig, lax = _fresh_lax()
        @test_nowarn Makie.reset_limits!(lax)
        @test lax.last_geom[] === nothing
    end

    @testset "data_to_pixel consistent with projection after lineageplot!" begin
        fig, lax, _ = _plotted_lax()
        colorbuffer(fig)   # force scene layout / viewport computation
        scene = lax.scene
        vp = Makie.viewport(scene)[]
        # Only test if viewport is non-degenerate (CairoMakie assigns real pixels).
        if !iszero(Makie.widths(vp)[1]) && !iszero(Makie.widths(vp)[2])
            geom = lax.last_geom[]
            bb = geom.boundingbox
            left_pt  = Makie.Point2f(Makie.minimum(bb)[1], (Makie.minimum(bb)[2] + Makie.maximum(bb)[2]) / 2)
            right_pt = Makie.Point2f(Makie.maximum(bb)[1], (Makie.minimum(bb)[2] + Makie.maximum(bb)[2]) / 2)
            px_left  = data_to_pixel(scene, left_pt)
            px_right = data_to_pixel(scene, right_pt)
            # For :standard, leftward data maps to smaller pixel x.
            @test px_left[1] < px_right[1]
        end
    end

    @testset "display_polarity :reversed flips data_to_pixel ordering" begin
        fig, lax, _ = _plotted_lax(; display_polarity = :reversed)
        colorbuffer(fig)
        scene = lax.scene
        vp = Makie.viewport(scene)[]
        if !iszero(Makie.widths(vp)[1]) && !iszero(Makie.widths(vp)[2])
            geom = lax.last_geom[]
            bb = geom.boundingbox
            left_pt  = Makie.Point2f(Makie.minimum(bb)[1], (Makie.minimum(bb)[2] + Makie.maximum(bb)[2]) / 2)
            right_pt = Makie.Point2f(Makie.maximum(bb)[1], (Makie.minimum(bb)[2] + Makie.maximum(bb)[2]) / 2)
            px_left  = data_to_pixel(scene, left_pt)
            px_right = data_to_pixel(scene, right_pt)
            # For :reversed, leftward data maps to larger pixel x.
            @test px_left[1] > px_right[1]
        end
    end

    @testset "multiple lineageplot! calls do not error" begin
        fig, lax = _fresh_lax()
        acc = lineagegraph_accessor(_LA_BALANCED_BASENODE; children = node -> node.children)
        @test_nowarn lineageplot!(lax, _LA_BALANCED_BASENODE, acc)
        @test_nowarn lineageplot!(lax, _LA_BALANCED_BASENODE, acc)
    end

    @testset "get_scene returns the plotting scene" begin
        fig, lax = _fresh_lax()
        @test Makie.get_scene(lax) === lax.scene
    end

    @testset "lineageplot! orientation-aware leaf label defaults" begin
        acc_el = lineagegraph_accessor(
            _LA_BALANCED_BASENODE;
            children   = node -> node.children,
            edgeweight = (src, dst) -> 1.0,
        )

        # Backward (:nodeheights) + standard polarity → leaves on left →
        # labels offset leftward, right-aligned.
        fig1 = Figure()
        lax1 = LineageAxis(fig1[1, 1])
        lp1  = lineageplot!(lax1, _LA_BALANCED_BASENODE, _LA_ACC;
                             leaf_label_func = node -> string(node.name))
        ll1  = only(filter(p -> p isa LeafLabelLayer, lp1.plots))
        @test ll1[:offset][] == Makie.Vec2f(-4, 0)
        @test ll1[:align][]  == (:right, :center)

        # Forward (:edgeweights) + standard polarity → leaves on right →
        # recipe defaults (4 px rightward, left-aligned).
        fig2 = Figure()
        lax2 = LineageAxis(fig2[1, 1])
        lp2  = lineageplot!(lax2, _LA_BALANCED_BASENODE, acc_el;
                             leaf_label_func = node -> string(node.name))
        ll2  = only(filter(p -> p isa LeafLabelLayer, lp2.plots))
        @test ll2[:offset][] == Makie.Vec2f(4, 0)
        @test ll2[:align][]  == (:left, :center)

        # :right_to_left + backward (:nodeheights) → double reversal → leaves
        # on right → recipe defaults.
        fig3 = Figure()
        lax3 = LineageAxis(fig3[1, 1]; lineage_orientation = :right_to_left)
        lp3  = lineageplot!(lax3, _LA_BALANCED_BASENODE, _LA_ACC;
                             leaf_label_func = node -> string(node.name))
        ll3  = only(filter(p -> p isa LeafLabelLayer, lp3.plots))
        @test ll3[:offset][] == Makie.Vec2f(4, 0)
        @test ll3[:align][]  == (:left, :center)

        # Forward + :bottom_to_top → leaves on top → upward labels.
        fig4 = Figure()
        lax4 = LineageAxis(fig4[1, 1]; lineage_orientation = :bottom_to_top)
        lp4  = lineageplot!(lax4, _LA_BALANCED_BASENODE, acc_el;
                             leaf_label_func = node -> string(node.name))
        ll4  = only(filter(p -> p isa LeafLabelLayer, lp4.plots))
        @test ll4[:offset][] == Makie.Vec2f(0, 4)
        @test ll4[:align][]  == (:center, :bottom)

        # Forward + :top_to_bottom → leaves on bottom → downward labels.
        fig5 = Figure()
        lax5 = LineageAxis(fig5[1, 1]; lineage_orientation = :top_to_bottom)
        lp5  = lineageplot!(lax5, _LA_BALANCED_BASENODE, acc_el;
                             leaf_label_func = node -> string(node.name))
        ll5  = only(filter(p -> p isa LeafLabelLayer, lp5.plots))
        @test ll5[:offset][] == Makie.Vec2f(0, -4)
        @test ll5[:align][]  == (:center, :top)
    end

    @testset "lineageplot! orientation-aware clade_label_side" begin
        acc_el = lineagegraph_accessor(
            _LA_BALANCED_BASENODE;
            children   = node -> node.children,
            edgeweight = (src, dst) -> 1.0,
        )

        # Backward + standard → leaves on left → bracket on left.
        fig1 = Figure()
        lax1 = LineageAxis(fig1[1, 1])
        lp1  = lineageplot!(lax1, _LA_BALANCED_BASENODE, _LA_ACC;
                             clade_nodes = [_LA_BALANCED_BASENODE])
        @test lp1[:clade_label_side][] === :left

        # Forward + standard → leaves on right → bracket on right.
        fig2 = Figure()
        lax2 = LineageAxis(fig2[1, 1])
        lp2  = lineageplot!(lax2, _LA_BALANCED_BASENODE, acc_el;
                             clade_nodes = [_LA_BALANCED_BASENODE])
        @test lp2[:clade_label_side][] === :right

        # Forward + :bottom_to_top → leaves on top → bracket on top.
        fig3 = Figure()
        lax3 = LineageAxis(fig3[1, 1]; lineage_orientation = :bottom_to_top)
        lp3  = lineageplot!(lax3, _LA_BALANCED_BASENODE, acc_el;
                             clade_nodes = [_LA_BALANCED_BASENODE])
        @test lp3[:clade_label_side][] === :top

        # Forward + :top_to_bottom → leaves on bottom → bracket on bottom.
        fig4 = Figure()
        lax4 = LineageAxis(fig4[1, 1]; lineage_orientation = :top_to_bottom)
        lp4  = lineageplot!(lax4, _LA_BALANCED_BASENODE, acc_el;
                             clade_nodes = [_LA_BALANCED_BASENODE])
        @test lp4[:clade_label_side][] === :bottom
    end

    @testset "x-axis ticks in blockscene pixel space when show_x_axis = true" begin
        fig = Figure()
        lax = LineageAxis(fig[1, 1]; show_x_axis = true)
        lineageplot!(lax, _LA_BALANCED_BASENODE, _LA_ACC)
        colorbuffer(fig)
        vp = Makie.viewport(lax.scene)[]
        # After rendering, scene viewport must have non-zero width.
        @test !iszero(Makie.widths(vp)[1])
        @test !isempty(lax._xaxis_tick_segments[])
        @test !isempty(lax._xaxis_tick_positions[])
    end

    @testset "clade bracket pixel shapes non-empty after lineageplot! on LineageAxis" begin
        fig2 = Figure(; size = (400, 300))
        lax2 = LineageAxis(fig2[1, 1])
        lp2  = lineageplot!(lax2, _LA_BALANCED_BASENODE, _LA_ACC;
                            clade_nodes = [_LA_BALANCED_BASENODE],
                            clade_label_func = node -> "basenode")
        colorbuffer(fig2)
        cll2 = only(filter(p -> p isa CladeLabelLayer, lp2.plots))
        @test !isempty(cll2[:bracket_pixel_shapes][])
        for pt in cll2[:bracket_pixel_shapes][]
            isnan(pt[1]) && continue
            @test isfinite(pt[1]) && isfinite(pt[2])
        end
    end

    @testset "title text exists when title != \"\"" begin
        fig = Figure(; size = (400, 300))
        lax = LineageAxis(fig[1, 1]; title = "Panel title")
        lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            leaf_label_visible = false,
        )
        colorbuffer(fig)
        @test "Panel title" in _visible_blockscene_strings(lax)
    end

    @testset "xlabel text exists when xlabel != \"\"" begin
        fig = Figure(; size = (400, 300))
        lax = LineageAxis(fig[1, 1]; xlabel = "distance")
        lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            leaf_label_visible = false,
        )
        colorbuffer(fig)
        @test "distance" in _visible_blockscene_strings(lax)
    end

    @testset "inner plotting viewport is inset from full block bbox" begin
        fig = Figure(; size = (400, 300))
        lax = LineageAxis(
            fig[1, 1];
            title = "Inset",
            xlabel = "distance",
            show_x_axis = true,
        )
        lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            leaf_label_visible = false,
        )
        colorbuffer(fig)
        vp = Makie.viewport(lax.scene)[]
        bbox = lax.layoutobservables.computedbbox[]
        @test vp.origin[1] > bbox.origin[1]
        @test vp.origin[2] > bbox.origin[2]
        @test vp.widths[1] < bbox.widths[1]
        @test vp.widths[2] < bbox.widths[2]
    end

    @testset "x-axis tick marks and labels live in the panel-owned x-axis band" begin
        fig = Figure(; size = (800, 600))
        lax = LineageAxis(
            fig[2, 1];
            title = "Bottom panel",
            show_x_axis = true,
            xlabel = "distance",
        )
        lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            _LA_ACC;
            leaf_label_visible = false,
        )
        colorbuffer(fig)

        vp = Makie.viewport(lax.scene)[]
        bbox = lax.layoutobservables.computedbbox[]
        @test !isempty(lax._xaxis_tick_segments[])
        @test !isempty(lax._xaxis_tick_positions[])
        @test !isempty(lax._xaxis_tick_labels[])

        for pt in lax._xaxis_tick_positions[]
            @test pt[2] < Float32(vp.origin[2])
            @test pt[2] >= Float32(bbox.origin[2])
            @test pt[1] >= Float32(bbox.origin[1])
            @test pt[1] <= Float32(bbox.origin[1] + bbox.widths[1])
        end

        for pt in lax._xaxis_tick_segments[]
            isnan(pt[1]) && continue
            @test pt[2] < Float32(vp.origin[2])
            @test pt[2] >= Float32(bbox.origin[2])
        end
    end

    @testset "non-basenode-clade highlight remains narrower than full geometry on LineageAxis" begin
        fig = Figure(; size = (400, 300))
        lax = LineageAxis(fig[1, 1])
        acc = lineagegraph_accessor(
            _LA_BALANCED_BASENODE;
            children = node -> node.children,
            edgeweight = (src, dst) -> 1.0,
        )
        lp = lineageplot!(
            lax,
            _LA_BALANCED_BASENODE,
            acc;
            lineageunits = :edgeweights,
            clade_nodes = [_LA_NONBASENODE_CLADE],
        )
        colorbuffer(fig)

        chl = only(filter(p -> p isa CladeHighlightLayer, lp.plots))
        rect = only(chl[:highlight_rects][])
        geom = lp[:computed_geom][]

        clade_pts = [geom.node_positions[node] for node in leaves(acc, _LA_NONBASENODE_CLADE)]
        push!(clade_pts, geom.node_positions[_LA_NONBASENODE_CLADE])
        raw_span = maximum(pt[1] for pt in clade_pts) - minimum(pt[1] for pt in clade_pts)
        full_span = Float32(geom.boundingbox.widths[1])

        @test rect.widths[1] >= raw_span
        @test rect.widths[1] < full_span
    end

end
