# Tasks for Issue 9: Label layers

Parent issue: Issue 9
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `STYLE-vocabulary.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

Canonical terms: `leaf`/`leaves`, `vertex`/`vertices`, `vertexvalue`. The
`text_func` attribute takes a `vertex -> String` callable; `value_func` takes a
`vertex -> Any` callable. Do not use `node`, `tip`, or other proscribed
alternates anywhere.

If any helper `struct` is introduced alongside the `@recipe` types, all fields
must be concretely typed or parameterized (STYLE-julia.md §1.12).

---

## Tasks

### 1. `LeafLabelLayer` recipe with pixel-space offset

**Type**: WRITE
**Output**: `LeafLabelLayer` / `leaflabellayer!` renders one text label per leaf
at the leaf position plus a pixel-space offset; `italic` attribute applies; the
layer is wired into `lineageplot!`.
**Depends on**: none

Implement `LeafLabelLayer` in `src/Layers.jl` using `@recipe`. Positional input:
a `LineageGraphGeometry` and a `LineageGraphAccessor`. Attributes: `text_func` (a callable
`vertex -> String`; default: `string` applied to `vertexvalue` if present,
otherwise the vertex itself), `font` (default Makie's default font), `fontsize`
(default `12`), `color` (default `:black`), `offset` (default `Vec2f(4, 0)` in
pixels — a small rightward shift), `italic` (default `false`), `align` (default
`(:left, :center)`), `visible` (default `true`).

In the `plot!` method, collect leaf positions from `geom.vertex_positions`
filtered by `is_leaf(accessor, vertex)`. Use `CoordTransform.register_pixel_projection!`
so that `offset`, which is in pixel space, is correctly converted to data-space
deltas at each leaf's position before calling `text!`. This conversion must use
`pixel_offset_to_data_delta` from `CoordTransform`. Apply `italic` by passing
`font = Makie.to_font(:italic)` or the equivalent — look up the correct Makie
API for italic text rendering in `src/basic_recipes/text.jl` in the local Makie
source before implementing. Write a docstring. Export `LeafLabelLayer` and
`leaflabellayer!`. Wire into `lineageplot!` stub after the leaf layer call.

---

### 2. `VertexLabelLayer` recipe with threshold and type-error guard

**Type**: WRITE
**Output**: `VertexLabelLayer` / `vertexlabellayer!` renders labels only at
vertices passing the threshold predicate; non-renderable `value_func` output
raises an informative error at plot time.
**Depends on**: Task 1

Implement `VertexLabelLayer` in `src/Layers.jl` using `@recipe`. Positional
input: a `LineageGraphGeometry` and a `LineageGraphAccessor`. Attributes: `value_func` (a
callable `vertex -> Any`; default: `v -> ""`, i.e., empty string), `threshold`
(a predicate callable `vertex -> Bool`; default: `v -> true`, meaning show all),
`position` (`:vertex` | `:toward_parent`; default `:vertex`), `font` (default
Makie's default), `fontsize` (default `10`), `color` (default `:gray50`),
`visible` (default `true`).

In the `plot!` method, iterate all vertices in `geom.vertex_positions`. For each
vertex, apply `threshold(vertex)` — include only vertices returning `true`. For
included vertices, call `value_func(vertex)`. Before passing the value to
`text!`, check whether it is renderable: attempt `string(value)` inside a
`try/catch` or check `isa(value, Union{AbstractString, Number, Symbol})`;
if non-renderable, raise an `ArgumentError` naming the vertex and the returned
value type. For `:toward_parent` position, offset the label slightly along the
direction of the parent's transverse coordinate. Write a docstring. Export
`VertexLabelLayer` and `vertexlabellayer!`. Wire into the `lineageplot!` stub.

---

### 3. Extend `test_Layers.jl` for label layers

**Type**: TEST
**Output**: All label layer test assertions green; type-error is raised at plot
time for non-renderable values; no regression in earlier tests.
**Depends on**: Task 2

Extend `test/test_Layers.jl` with `@testset "LeafLabelLayer"` and
`@testset "VertexLabelLayer"` blocks.

Cover:
- `leaflabellayer!` with `text_func = v -> "label"` on the 4-leaf fixture: plot
  object created without error; text positions match leaf positions (within
  offset).
- `italic = true`: verify the `font` attribute on the resulting text plot encodes
  italic style (inspect the attribute rather than rendering to pixels).
- `visible = false`: plot created but `visible == false`.
- `vertexlabellayer!` with `threshold = v -> false`: zero text entries in the
  plot (all filtered out).
- `threshold = v -> true` (default): all internal vertices get labels.
- `value_func` returning a non-renderable type (e.g., a `Dict`): use
  `@test_throws ArgumentError` to confirm the error is raised at plot time.
- Pixel-space offset: after a viewport change, label positions shift to remain
  at the same pixel offset from their leaf (use `register_pixel_projection!`
  reactive update — verify that triggering the viewport Observable causes the
  `offset`-derived positions to update).

All tests use `CairoMakie`. All deterministic.
