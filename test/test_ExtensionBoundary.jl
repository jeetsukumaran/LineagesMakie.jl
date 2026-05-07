# Tests for extension boundary

using Pkg
using TOML
using UUIDs

const _LINEAGESMAKIE_UUID = UUID("442c8a50-53a9-4dd6-b3a1-02ab81198c2d")
const _PHYLONETWORKS_UUID = UUID("33ad39ac-ed31-50eb-9b15-43d0656eaa72")

function _write_extension_probe_project(tmpdir::String, repo_root::String)
    project_path = joinpath(tmpdir, "Project.toml")
    open(project_path, "w") do io
        println(io, "[deps]")
        println(io, "LineagesMakie = ", repr(string(_LINEAGESMAKIE_UUID)))
        println(io)
        println(io, "[sources]")
        println(io, "LineagesMakie = {path = ", repr(repo_root), "}")
    end
    return project_path
end

function _run_absence_case_probe(repo_root::String)::Tuple{Int, String}
    return mktempdir() do tmpdir
        _write_extension_probe_project(tmpdir, repo_root)
        script = """
        using Pkg, UUIDs

        empty!(LOAD_PATH)
        push!(LOAD_PATH, "@")
        push!(LOAD_PATH, "@stdlib")

        Pkg.offline(true)
        Pkg.instantiate()

        @assert Base.find_package("PhyloNetworks") === nothing

        lineagesmakie_id = Base.PkgId(UUID("442c8a50-53a9-4dd6-b3a1-02ab81198c2d"), "LineagesMakie")
        Base.require(lineagesmakie_id)
        lineagesmakie = Base.loaded_modules[lineagesmakie_id]
        @assert lineagesmakie !== nothing
        @assert Base.get_extension(lineagesmakie, :PhyloNetworksExt) === nothing

        println("absence-ok")
        """
        cmd = `$(Base.julia_cmd()) --startup-file=no --project=$tmpdir -e $script`
        output = IOBuffer()
        proc = run(pipeline(ignorestatus(cmd), stdout = output, stderr = output))
        return proc.exitcode, String(take!(output))
    end
end

@testset "Extension boundary" begin
    repo_root = normpath(joinpath(@__DIR__, ".."))
    exitcode, output = _run_absence_case_probe(repo_root)
    @test exitcode == 0
    @test occursin("absence-ok", output)

    @test Base.get_extension(LineagesMakie, :PhyloNetworksExt) === nothing

    Base.require(Base.PkgId(_PHYLONETWORKS_UUID, "PhyloNetworks"))
    extension_module = Base.get_extension(LineagesMakie, :PhyloNetworksExt)
    @test extension_module !== nothing
    @test nameof(extension_module) === :PhyloNetworksExt

    project = TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
    weakdeps = get(project, "weakdeps", Dict{String, Any}())
    extensions = get(project, "extensions", Dict{String, Any}())
    deps = get(project, "deps", Dict{String, Any}())

    @test !haskey(deps, "PhyloNetworks")
    @test weakdeps["PhyloNetworks"] == string(_PHYLONETWORKS_UUID)
    @test extensions["PhyloNetworksExt"] == "PhyloNetworks"

    test_project = TOML.parsefile(joinpath(@__DIR__, "Project.toml"))
    test_sources = get(test_project, "sources", Dict{String, Any}())
    @test test_sources["PhyloNetworks"]["path"] ==
        "/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/PhyloNetworks.jl"
end
