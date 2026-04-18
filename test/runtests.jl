using LineagesMakie
using Test
using Aqua
using JET

@testset "LineagesMakie.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(LineagesMakie)
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(LineagesMakie; target_defined_modules = true)
    end
    # Write your tests here.
end
