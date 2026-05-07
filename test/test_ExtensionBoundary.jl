# Tests for extension boundary

using TOML
using UUIDs

@testset "Extension boundary" begin
    @test Base.get_extension(LineagesMakie, :PhyloNetworksExt) === nothing

    Base.require(Base.PkgId(UUID("33ad39ac-ed31-50eb-9b15-43d0656eaa72"), "PhyloNetworks"))
    extension_module = Base.get_extension(LineagesMakie, :PhyloNetworksExt)
    @test extension_module !== nothing
    @test nameof(extension_module) === :PhyloNetworksExt

    project = TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
    weakdeps = get(project, "weakdeps", Dict{String, Any}())
    extensions = get(project, "extensions", Dict{String, Any}())
    deps = get(project, "deps", Dict{String, Any}())

    @test !haskey(deps, "PhyloNetworks")
    @test weakdeps["PhyloNetworks"] == "33ad39ac-ed31-50eb-9b15-43d0656eaa72"
    @test extensions["PhyloNetworksExt"] == "PhyloNetworks"

    test_project = TOML.parsefile(joinpath(@__DIR__, "Project.toml"))
    test_sources = get(test_project, "sources", Dict{String, Any}())
    @test test_sources["PhyloNetworks"]["path"] ==
        "/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl"
end
