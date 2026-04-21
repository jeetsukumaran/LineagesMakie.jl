# Tests for Layers
#
# All tests use real CairoMakie scenes. CairoMakie re-exports all Makie types.

import CairoMakie
using CairoMakie: Figure, Axis
using CairoMakie: colorbuffer

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

end
