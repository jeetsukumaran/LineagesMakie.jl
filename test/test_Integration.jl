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
            @test_nowarn lineageplot!(ax, _IT_ROOT, acc)
            save(tmpfile, fig)
            @test filesize(tmpfile) > 0
        finally
            isfile(tmpfile) && rm(tmpfile)
        end
    end

end
