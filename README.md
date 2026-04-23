# LineagesMakie

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jeetsukumaran.github.io/LineagesMakie.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jeetsukumaran.github.io/LineagesMakie.jl/dev/)
[![Build Status](https://github.com/jeetsukumaran/LineagesMakie.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jeetsukumaran/LineagesMakie.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

Makie-native lineage-graph plotting for Julia.

Use `lineageplot(rootvertex, accessor; kwargs...)` for a non-mutating,
display-ready plotting result, and `lineageplot!(ax, rootvertex, accessor;
kwargs...)` when plotting into an existing `Axis` or `LineageAxis`.
