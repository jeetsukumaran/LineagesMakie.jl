using LineagesMakie
using Test
using Aqua
using JET

@testset "LineagesMakie.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        # Makie and AbstractTrees are declared deps but not yet imported in module stubs;
        # ignore list is removed once module bodies are implemented (Issue 2+).
        Aqua.test_all(LineagesMakie; stale_deps = (; ignore = [:Makie, :AbstractTrees]))
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(LineagesMakie; target_modules = (LineagesMakie,))
    end
    # Write your tests here.
end
