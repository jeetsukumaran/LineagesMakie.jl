# Tests for CoordTransform
#
# All tests use real CairoMakie scenes to exercise the actual Makie coordinate
# transform paths. CairoMakie re-exports all Makie types; geometric types are
# imported through it.

import CairoMakie
using CairoMakie: Figure, Axis, scatter!
using CairoMakie: colorbuffer
using CairoMakie: Point2f, Vec2f, Rect2i, on

@testset "CoordTransform" begin
    # ── Shared fixture: a rendered non-isotropic axis ─────────────────────────
    #
    # x range 0–100, y range 0–1 gives very different pixel-per-data-unit
    # scales in each dimension. colorbuffer forces rendering so the axis scene's
    # camera and viewport are fully initialised before any test runs.
    _CT_FIG = Figure(; size = (800, 600))
    _CT_AX = Axis(_CT_FIG[1, 1]; limits = (0.0f0, 100.0f0, 0.0f0, 1.0f0))
    colorbuffer(_CT_FIG)
    _CT_SC = _CT_AX.scene

    @testset "data_to_pixel / pixel_to_data round-trip" begin
        for p in [Point2f(0, 0), Point2f(50, 0.5), Point2f(100, 1)]
            px = data_to_pixel(_CT_SC, p)
            p_rt = pixel_to_data(_CT_SC, px)
            @test p ≈ p_rt atol = 1.0f-2
        end
    end

    @testset "Non-isotropic axes" begin
        # 1 data unit in x and 1 data unit in y must produce different pixel
        # distances: x covers a range of 100 while y covers a range of 1, yet
        # both map to the same physical pixel extent of the axis.
        px_00 = data_to_pixel(_CT_SC, Point2f(0, 0))
        px_10 = data_to_pixel(_CT_SC, Point2f(1, 0))     # +1 in x data units
        px_01 = data_to_pixel(_CT_SC, Point2f(0, 0.01f0)) # small +y step
        dist_x = abs(px_10[1] - px_00[1])
        dist_y = abs(px_01[2] - px_00[2])
        # x pixels per unit << y pixels per unit because x has 100x larger range
        @test !isapprox(dist_x, dist_y; rtol = 0.01)
    end

    @testset "pixel_offset_to_data_delta" begin
        p = Point2f(50.0, 0.5)
        offset10 = Vec2f(10.0, 0.0)        # 10-pixel horizontal offset
        delta = pixel_offset_to_data_delta(_CT_SC, p, offset10)
        # Positive x pixel offset → positive x data delta; no y component.
        @test delta[1] > 0.0
        @test abs(delta[2]) < 1.0f-4
        # Consistency with the round-trip definition.
        px_base = data_to_pixel(_CT_SC, p)
        expected = pixel_to_data(_CT_SC, px_base + offset10) - p
        @test delta ≈ Vec2f(expected) atol = 1.0f-4
    end

    @testset "Degenerate viewport" begin
        # Use a separate figure so modifying the viewport does not affect the
        # shared fixture.
        _degen_fig = Figure(; size = (400, 300))
        _degen_ax = Axis(_degen_fig[1, 1])
        colorbuffer(_degen_fig)
        sc_degen = _degen_ax.scene
        # Force a zero-width viewport to trigger the degenerate-viewport path.
        sc_degen.viewport[] = Rect2i(0, 0, 0, 300)
        p = Point2f(0.5, 0.5)
        # Each function must emit a warning and return a safe identity fallback.
        r_d2p = @test_warn "degenerate viewport" data_to_pixel(sc_degen, p)
        @test r_d2p == p
        r_p2d = @test_warn "degenerate viewport" pixel_to_data(sc_degen, p)
        @test r_p2d == p
        r_delta = @test_warn "degenerate viewport" pixel_offset_to_data_delta(
            sc_degen, p, Vec2f(10, 0),
        )
        @test r_delta == Vec2f(10, 0)
    end

    @testset "register_pixel_projection!" begin
        pl = scatter!(_CT_AX, [50.0f0], [0.5f0])
        register_pixel_projection!(pl.attributes, _CT_SC)
        # Both reactive inputs must be present in the ComputeGraph.
        # haskey(graph, key) checks attr.outputs (the union of plain inputs and
        # Computed nodes), which covers both registration paths.
        @test haskey(pl.attributes, :viewport)
        @test haskey(pl.attributes, :projectionview)
        # The derived :pixel_projection node must exist.
        @test haskey(pl.attributes, :pixel_projection)
        # Changing the scene viewport must trigger the :pixel_projection node.
        # on(computed) uses get_observable! which deepcopies the value by default;
        # the closure captures a Scene (which holds Module refs) so deepcopy fails.
        # Use get_observable!(; use_deepcopy=false) to get a plain Observable we
        # can observe without triggering that path.
        _CP = CairoMakie.Makie.ComputePipeline
        pp_obs = _CP.get_observable!(pl.attributes[:pixel_projection]; use_deepcopy = false)
        notified = Ref(false)
        on(pp_obs) do _
            notified[] = true
        end
        orig_vp = _CT_SC.viewport[]
        _CT_SC.viewport[] = Rect2i(0, 0, 200, 150)
        @test notified[]
        _CT_SC.viewport[] = orig_vp     # restore to avoid leaking state
    end
end
