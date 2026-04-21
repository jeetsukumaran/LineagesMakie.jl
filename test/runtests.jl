using LineagesMakie
using Test
using Aqua
using JET

@testset "LineagesMakie.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        # Makie not yet imported in module stubs; removed once Issue 7 is implemented.
        Aqua.test_all(LineagesMakie; stale_deps = (; ignore = [:Makie]))
    end
    @testset "Code linting (JET.jl)" begin
        JET.test_package(LineagesMakie; target_modules = (LineagesMakie,))
    end
    include("test_Accessors.jl")
    include("test_Geometry.jl")
    include("test_CoordTransform.jl")
    include("test_Layers.jl")
    include("test_LineageAxis.jl")
    include("test_Integration.jl")
end
