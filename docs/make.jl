using LineagesMakie
using Documenter

DocMeta.setdocmeta!(LineagesMakie, :DocTestSetup, :(using LineagesMakie); recursive=true)

makedocs(;
    modules=[LineagesMakie, LineagesMakie.Accessors, LineagesMakie.Geometry, LineagesMakie.Layers],
    authors="Jeet Sukumaran <jeetsukumaran@gmail.com>",
    sitename="LineagesMakie.jl",
    format=Documenter.HTML(;
        canonical="https://jeetsukumaran.github.io/LineagesMakie.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jeetsukumaran/LineagesMakie.jl",
    devbranch="main",
)
