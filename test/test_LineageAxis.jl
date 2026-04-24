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
const _LA_BALANCED_ROOT = LATestNode("root", [
    LATestNode("ab", [
        LATestNode("a", LATestNode[]),
        LATestNode("b", LATestNode[]),
    ]),
    LATestNode("cd", [
        LATestNode("c", LATestNode[]),
        LATestNode("d", LATestNode[]),
    ]),
])

const _LA_ACC = lineagegraph_accessor(_LA_BALANCED_ROOT; children = n -> n.children)
const _LA_NONROOT_CLADE = _LA_BALANCED_ROOT.children[1]

# ── Helpers ───────────────────────────────────────────────────────────────────

function _fresh_lax(; kwargs...)
    fig = Figure(; size = (400, 300))
    lax = LineageAxis(fig[1, 1]; kwargs...)
    return fig, lax
end

function _plotted_lax(; lineageunits = nothing, lax_kwargs...)
    fig, lax = _fresh_lax(; lax_kwargs...)
    lp = lineageplot!(lax, _LA_BALANCED_ROOT, _LA_ACC; lineageunits = lineageunits)
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

    @testset "lineageplot! on plain Axis (no regression)" begin
        fig = Figure(; size = (400, 300))
        ax = Axis(fig[1, 1])
        acc = lineagegraph_accessor(_LA_BALANCED_ROOT; children = n -> n.children)
        lp = lineageplot!(ax, _LA_BALANCED_ROOT, acc)
        @test lp isa LineagePlot
        @test_nowarn colorbuffer(fig)
    end

    @testset "plain Axis keeps plot-owned vertical orientation support" begin
        fig = Figure(; size = (400, 300))
        ax = Axis(fig[1, 1])
        lp = lineageplot!(
            ax,
            _LA_BALANCED_ROOT,
            _LA_ACC;
            lineageunits = :vertexlevels,
            lineage_orientation = :top_to_bottom,
        )
        geom = lp[:computed_geom][]
        leaf_positions = [geom.vertex_positions[v] for v in geom.leaf_order]
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
        lp = lineageplot!(lax, _LA_BALANCED_ROOT, _LA_ACC; lineageunits = :vertexlevels)
        geom = lp[:computed_geom][]
        leaf_positions = [geom.vertex_positions[v] for v in geom.leaf_order]
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
            _LA_BALANCED_ROOT,
            _LA_ACC;
            lineageunits = :vertexlevels,
            lineage_orientation = :top_to_bottom,
            rectangular_orientation_owner = :plot,
        )
        geom = lp[:computed_geom][]
        leaf_positions = [geom.vertex_positions[v] for v in geom.leaf_order]
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
        # :vertexheights and the default (which resolves to :vertexheights for a
        # children-only accessor) should produce :backward.
        fig1, lax1, _ = _plotted_lax(; lineageunits = :vertexheights)
        @test lax1.axis_polarity[] === :backward

        # Default (nothing) resolves to :vertexheights → :backward.
        fig2, lax2, _ = _plotted_lax()
        @test lax2.axis_polarity[] === :backward

        # :vertexlevels and :vertexdepths are forward and require no special accessor.
        fig3, lax3, _ = _plotted_lax(; lineageunits = :vertexlevels)
        @test lax3.axis_polarity[] === :forward

        fig4, lax4, _ = _plotted_lax(; lineageunits = :vertexdepths)
        @test lax4.axis_polarity[] === :forward
    end

    @testset "axis_polarity not overwritten after manual override" begin
        fig, lax = _fresh_lax()
        # Setting to :backward (different from default :forward) fires the lock observer.
        lax.axis_polarity[] = :backward
        @test lax._polarity_locked[]
        # lineageplot! with :vertexlevels would infer :forward, but lock prevents it.
        # :vertexlevels works with a children-only accessor.
        lineageplot!(lax, _LA_BALANCED_ROOT, _LA_ACC; lineageunits = :vertexlevels)
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
            _LA_BALANCED_ROOT,
            _LA_ACC;
            lineage_orientation = :diagonal,
        )
    end

    @testset "measured annotation layout reserves coordinated right-side lanes" begin
        fig, lax = _fresh_lax()
        lineageplot!(
            lax,
            _LA_BALANCED_ROOT,
            _LA_ACC;
            lineageunits = :vertexlevels,
            leaf_label_func = n -> "species_" * n.name,
            clade_vertices = [_LA_NONROOT_CLADE],
            clade_label_func = n -> "clade_" * n.name,
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
            _LA_BALANCED_ROOT,
            _LA_ACC;
            lineageunits = :vertexlevels,
            leaf_label_func = n -> "species_" * n.name,
            clade_vertices = [_LA_NONROOT_CLADE],
            clade_label_func = n -> "clade_" * n.name,
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
            _LA_BALANCED_ROOT,
            _LA_ACC;
            lineageunits = :vertexlevels,
            leaf_label_func = n -> "species_" * n.name,
            clade_vertices = [_LA_NONROOT_CLADE],
            clade_label_func = n -> "clade_" * n.name,
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
            _LA_BALANCED_ROOT,
            _LA_ACC;
            lineageunits = :vertexlevels,
            leaf_label_func = n -> "species_" * n.name,
            clade_vertices = [_LA_NONROOT_CLADE],
            clade_label_func = n -> "clade_" * n.name,
        )
        colorbuffer(fig)

        layout = lax._decoration_layout[]
        @test layout.active_annotation_side === :bottom
        @test layout.bottom_gutter_px > layout.top_gutter_px
        @test isfinite(layout.leaf_label_anchor_y)
        @test layout.leaf_label_outer_edge_y > layout.clade_bracket_y + layout.clade_tick_length_px
        @test layout.clade_label_anchor_y < layout.clade_bracket_y
    end

    @testset "radial annotation layout uses measured outer padding" begin
        fig, lax = _fresh_lax(; lineage_orientation = :radial)
        lineageplot!(
            lax,
            _LA_BALANCED_ROOT,
            _LA_ACC;
            lineage_orientation = :radial,
            leaf_label_func = n -> "species_" * n.name * "_label",
        )
        colorbuffer(fig)

        layout = lax._decoration_layout[]
        @test layout.active_annotation_side === :radial
        @test layout.left_gutter_px ≈ layout.right_gutter_px
        @test layout.radial_outer_pad_px > 24.0f0
    end

    @testset "scale bar reserves a bottom decoration band when visible" begin
        fig, lax = _fresh_lax(; show_x_axis = true)
        lp = lineageplot!(
            lax,
            _LA_BALANCED_ROOT,
            lineagegraph_accessor(
                _LA_BALANCED_ROOT;
                children = n -> n.children,
                edgelength = (u, v) -> 1.0,
            );
            lineageunits = :edgelengths,
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

    @testset "radial scale bar is auto-hidden when unlabeled" begin
        fig, lax = _fresh_lax(; lineage_orientation = :radial)
        lp = lineageplot!(
            lax,
            _LA_BALANCED_ROOT,
            lineagegraph_accessor(
                _LA_BALANCED_ROOT;
                children = n -> n.children,
                edgelength = (u, v) -> 1.0,
            );
            lineageunits = :edgelengths,
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
        acc = lineagegraph_accessor(_LA_BALANCED_ROOT; children = n -> n.children)
        @test_nowarn lineageplot!(lax, _LA_BALANCED_ROOT, acc)
        @test_nowarn lineageplot!(lax, _LA_BALANCED_ROOT, acc)
    end

    @testset "get_scene returns the plotting scene" begin
        fig, lax = _fresh_lax()
        @test Makie.get_scene(lax) === lax.scene
    end

    @testset "lineageplot! orientation-aware leaf label defaults" begin
        acc_el = lineagegraph_accessor(
            _LA_BALANCED_ROOT;
            children   = n -> n.children,
            edgelength = (u, v) -> 1.0,
        )

        # Backward (:vertexheights) + standard polarity → leaves on left →
        # labels offset leftward, right-aligned.
        fig1 = Figure()
        lax1 = LineageAxis(fig1[1, 1])
        lp1  = lineageplot!(lax1, _LA_BALANCED_ROOT, _LA_ACC;
                             leaf_label_func = v -> string(v.name))
        ll1  = only(filter(p -> p isa LeafLabelLayer, lp1.plots))
        @test ll1[:offset][] == Makie.Vec2f(-4, 0)
        @test ll1[:align][]  == (:right, :center)

        # Forward (:edgelengths) + standard polarity → leaves on right →
        # recipe defaults (4 px rightward, left-aligned).
        fig2 = Figure()
        lax2 = LineageAxis(fig2[1, 1])
        lp2  = lineageplot!(lax2, _LA_BALANCED_ROOT, acc_el;
                             leaf_label_func = v -> string(v.name))
        ll2  = only(filter(p -> p isa LeafLabelLayer, lp2.plots))
        @test ll2[:offset][] == Makie.Vec2f(4, 0)
        @test ll2[:align][]  == (:left, :center)

        # :right_to_left + backward (:vertexheights) → double reversal → leaves
        # on right → recipe defaults.
        fig3 = Figure()
        lax3 = LineageAxis(fig3[1, 1]; lineage_orientation = :right_to_left)
        lp3  = lineageplot!(lax3, _LA_BALANCED_ROOT, _LA_ACC;
                             leaf_label_func = v -> string(v.name))
        ll3  = only(filter(p -> p isa LeafLabelLayer, lp3.plots))
        @test ll3[:offset][] == Makie.Vec2f(4, 0)
        @test ll3[:align][]  == (:left, :center)

        # Forward + :bottom_to_top → leaves on top → upward labels.
        fig4 = Figure()
        lax4 = LineageAxis(fig4[1, 1]; lineage_orientation = :bottom_to_top)
        lp4  = lineageplot!(lax4, _LA_BALANCED_ROOT, acc_el;
                             leaf_label_func = v -> string(v.name))
        ll4  = only(filter(p -> p isa LeafLabelLayer, lp4.plots))
        @test ll4[:offset][] == Makie.Vec2f(0, 4)
        @test ll4[:align][]  == (:center, :bottom)

        # Forward + :top_to_bottom → leaves on bottom → downward labels.
        fig5 = Figure()
        lax5 = LineageAxis(fig5[1, 1]; lineage_orientation = :top_to_bottom)
        lp5  = lineageplot!(lax5, _LA_BALANCED_ROOT, acc_el;
                             leaf_label_func = v -> string(v.name))
        ll5  = only(filter(p -> p isa LeafLabelLayer, lp5.plots))
        @test ll5[:offset][] == Makie.Vec2f(0, -4)
        @test ll5[:align][]  == (:center, :top)
    end

    @testset "lineageplot! orientation-aware clade_label_side" begin
        acc_el = lineagegraph_accessor(
            _LA_BALANCED_ROOT;
            children   = n -> n.children,
            edgelength = (u, v) -> 1.0,
        )

        # Backward + standard → leaves on left → bracket on left.
        fig1 = Figure()
        lax1 = LineageAxis(fig1[1, 1])
        lp1  = lineageplot!(lax1, _LA_BALANCED_ROOT, _LA_ACC;
                             clade_vertices = [_LA_BALANCED_ROOT])
        @test lp1[:clade_label_side][] === :left

        # Forward + standard → leaves on right → bracket on right.
        fig2 = Figure()
        lax2 = LineageAxis(fig2[1, 1])
        lp2  = lineageplot!(lax2, _LA_BALANCED_ROOT, acc_el;
                             clade_vertices = [_LA_BALANCED_ROOT])
        @test lp2[:clade_label_side][] === :right

        # Forward + :bottom_to_top → leaves on top → bracket on top.
        fig3 = Figure()
        lax3 = LineageAxis(fig3[1, 1]; lineage_orientation = :bottom_to_top)
        lp3  = lineageplot!(lax3, _LA_BALANCED_ROOT, acc_el;
                             clade_vertices = [_LA_BALANCED_ROOT])
        @test lp3[:clade_label_side][] === :top

        # Forward + :top_to_bottom → leaves on bottom → bracket on bottom.
        fig4 = Figure()
        lax4 = LineageAxis(fig4[1, 1]; lineage_orientation = :top_to_bottom)
        lp4  = lineageplot!(lax4, _LA_BALANCED_ROOT, acc_el;
                             clade_vertices = [_LA_BALANCED_ROOT])
        @test lp4[:clade_label_side][] === :bottom
    end

    @testset "x-axis ticks in blockscene pixel space when show_x_axis = true" begin
        fig = Figure()
        lax = LineageAxis(fig[1, 1]; show_x_axis = true)
        lineageplot!(lax, _LA_BALANCED_ROOT, _LA_ACC)
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
        lp2  = lineageplot!(lax2, _LA_BALANCED_ROOT, _LA_ACC;
                            clade_vertices = [_LA_BALANCED_ROOT],
                            clade_label_func = v -> "root")
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
            _LA_BALANCED_ROOT,
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
            _LA_BALANCED_ROOT,
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
            _LA_BALANCED_ROOT,
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
            _LA_BALANCED_ROOT,
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

    @testset "non-root clade highlight remains narrower than full geometry on LineageAxis" begin
        fig = Figure(; size = (400, 300))
        lax = LineageAxis(fig[1, 1])
        acc = lineagegraph_accessor(
            _LA_BALANCED_ROOT;
            children = n -> n.children,
            edgelength = (u, v) -> 1.0,
        )
        lp = lineageplot!(
            lax,
            _LA_BALANCED_ROOT,
            acc;
            lineageunits = :edgelengths,
            clade_vertices = [_LA_NONROOT_CLADE],
        )
        colorbuffer(fig)

        chl = only(filter(p -> p isa CladeHighlightLayer, lp.plots))
        rect = only(chl[:highlight_rects][])
        geom = lp[:computed_geom][]

        clade_pts = [geom.vertex_positions[v] for v in leaves(acc, _LA_NONROOT_CLADE)]
        push!(clade_pts, geom.vertex_positions[_LA_NONROOT_CLADE])
        raw_span = maximum(pt[1] for pt in clade_pts) - minimum(pt[1] for pt in clade_pts)
        full_span = Float32(geom.boundingbox.widths[1])

        @test rect.widths[1] >= raw_span
        @test rect.widths[1] < full_span
    end

end
