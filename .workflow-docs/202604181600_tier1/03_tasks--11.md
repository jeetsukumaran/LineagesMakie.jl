# Tasks for Issue 11: `LineageAxis` block

Parent issue: Issue 11
Parent PRD: `.workflow-docs/202604181600_tier1/01_prd.md`

## Governance

All tasks must comply with `STYLE-julia.md`, `STYLE-git.md`, `STYLE-docs.md`,
`CONTRIBUTING.md`, and `VOCABULARY.md`.
Read-only git and shell commands may be used freely. Mutating git operations
(commit, merge, push, branch) are the human project owner's responsibility.

Canonical terms: `axis_polarity`, `display_polarity`, `lineage_orientation`,
`lineageunits`. These are public attributes of `LineageAxis` and must match
exactly. No attribute aliasing or alternative spellings.

The three-view model must be respected: `LineageAxis` joins the three views but
must not re-derive process coordinates (`Geometry`'s job) or interpret
pixel↔data mappings beyond applying them (`CoordTransform`'s job).

**Concrete struct fields** — if any helper `struct` is introduced alongside the
`@Block` type, all fields must be concretely typed or parameterized
(STYLE-julia.md §1.12 "Concrete struct fields and parametric type design").
Bare `Dict`, `Vector`, and abstract types are not acceptable field types
without an explicit, justified comment. The `@Block` macro generates its own
internal type; do not add raw `struct` fields to the generated block type.

---

## Tasks

### 1. Read Makie `@Block` source; define `LineageAxis` with all attributes and naked lineage graph defaults

**Type**: WRITE
**Output**: `LineageAxis` is defined with `Makie.@Block`; all nine attributes
are declared; naked lineage graph defaults (no ticks, no grid, no spines) are active;
`julia --project -e 'using LineagesMakie; using CairoMakie; fig = Figure();
LineageAxis(fig[1,1])'` succeeds.
**Depends on**: none

Before writing any code, read the following files in the local Makie source at
`/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/src/makielayout/`:
- The file defining the `@Block` macro (likely `blocks.jl` or `layoutables.jl`
  — search for `macro Block`).
- The `Axis` block definition (likely `axis.jl`) — study its attribute
  declaration pattern and how `initialize_block!` / `notify` patterns work.
- Any existing custom `Block` examples in `src/makielayout/blocks/`.
Also resolve PRD Open Q4: search for `xreversed` in `src/makielayout/axis.jl`
and related files to determine whether reversed axis limits are implemented via
a `reversed` attribute flag, by swapping limit values, or another mechanism.
Document the chosen approach in a comment citing source file and line number
before the `reset_limits!` implementation (Task 2).

Define `LineageAxis` in `src/LineageAxis.jl` using `Makie.@Block LineageAxis <:
AbstractAxis`. Declare all nine Tier-1 attributes as documented in the PRD:
`axis_polarity` (`:forward` | `:backward`; default `:forward`), `display_polarity`
(`:standard` | `:reversed`; default `:standard`), `lineage_orientation`
(`:left_to_right` | `:right_to_left` | `:radial`; default `:left_to_right`),
`show_x_axis` (`Bool`; default `false`), `show_y_axis` (`Bool`; default
`false`), `show_grid` (`Bool`; default `false`), `title`, `xlabel`, `ylabel`.

In `initialize_block!`, configure the inner `Axis` (or equivalent) to suppress
tick marks, grid lines, and axis spines by default (naked lineage graph appearance).
`show_x_axis = true` must activate the quantitative x-axis; implement this as
a reactive connection (`on` or `map!`) on the `show_x_axis` attribute.

Write a triple-quoted docstring on `LineageAxis`. Export it. Import from Makie
using explicit `using Makie: @Block, AbstractAxis` (confirm the exact names from
source). Confirm the module loads without error.

---

### 2. `reset_limits!` and `autolimits!` with `display_polarity` logic

**Type**: WRITE
**Output**: `reset_limits!(ax::LineageAxis, geom::LineageGraphGeometry)` sets axis
limits fitting the lineage graph bounding box; `display_polarity = :reversed` correctly
flips the primary axis; `autolimits!` delegates to `reset_limits!`.
**Depends on**: Task 1

Implement `reset_limits!(ax::LineageAxis, geom::LineageGraphGeometry) -> Nothing`. This
function must: (1) extract the bounding box from `geom.boundingbox`; (2) apply
`display_polarity`: if `:standard`, set `xlims!` (or equivalent) to
`(bbox_xmin, bbox_xmax)`; if `:reversed`, use the idiom confirmed from the Makie
source in Task 1 (whether that is reversed limit order, `xreversed = true`, or
another mechanism — cite the source). (3) apply `lineage_orientation`: for
`:left_to_right`, process coordinates map to the x-axis; for `:right_to_left`,
use the same reversal mechanism as `:reversed` display polarity (Task 1's
research finding applies here too — this is where the DRY delegation documented
in `02_issues.md` is implemented); for `:radial`, set equal x and y limits
fitting the circular bounding box. Write a docstring explaining each branch and
citing the Makie idiom used.

Implement `autolimits!(ax::LineageAxis) -> Nothing` as a one-liner delegating to
`reset_limits!` with the last-known `LineageGraphGeometry` (store it on the block during
`lineageplot!` dispatch, Task 4). Export both functions.

---

### 3. `lineage_orientation` dispatch including `:right_to_left` delegation

**Type**: WRITE
**Output**: `:left_to_right`, `:right_to_left`, and `:radial` orientations all
produce correct axis configurations; `:right_to_left` delegates to the
`:left_to_right` + `display_polarity = :reversed` path (DRY).
**Depends on**: Task 2

Extend the `lineage_orientation` handling in `reset_limits!` and in
`initialize_block!`. For `:right_to_left`: rather than implementing a separate
reversal path, set `ax.display_polarity = :reversed` then call the
`:left_to_right` branch. This is the DRY delegation agreed upon in `02_issues.md`.
Add a comment explaining this delegation. For `:radial`: configure equal x and y
axis scales (use `aspect = DataAspect()` or equivalent — confirm from Makie
`Axis` attribute docs in the local source).

Add `axis_polarity` inference from `lineageunits`: implement a private
`_infer_axis_polarity(lineageunits::Symbol) -> Symbol` helper that returns
`:forward` for `:edgelengths`, `:branchingtime`, `:vertexdepths`, `:vertexlevels`,
`:vertexcoords`, `:vertexpos` and `:backward` for `:coalescenceage`,
`:vertexheights`. This helper is called during `lineageplot!` dispatch (Task 4)
to set `ax.axis_polarity` when it has not been manually overridden.

---

### 4. `axis_polarity` inference, CoordTransform wiring, and `lineageplot!` Union dispatch

**Type**: WRITE
**Output**: `lineageplot!` dispatches on both `LineageAxis` and `Axis`; on
`LineageAxis`, `axis_polarity` is inferred from `lineageunits` if not manually
set; pixel↔data CoordTransform infrastructure is registered on the block.
**Depends on**: Task 3

Wire `CoordTransform.register_pixel_projection!` into `initialize_block!` so
that the block's pixel↔data mappings update reactively when the figure is
resized. Use the scene accessible from the block (confirm the accessor from the
Makie `@Block` API in Task 1's research).

Extend `lineageplot!` in `src/Layers.jl` to dispatch on
`Union{LineageAxis, Makie.Axis}`. When the axis is a `LineageAxis`: (1) call
`_infer_axis_polarity(lineageunits)` and set `ax.axis_polarity` if not already
overridden by the user; (2) call `reset_limits!(ax, geom)` after layout to fit
the lineage graph; (3) delegate to the same layer calls as the `Makie.Axis` path.

Store the last `LineageGraphGeometry` on the `LineageAxis` block in a field or
observable so `autolimits!` can use it. Write a docstring update on
`lineageplot!` documenting the `LineageAxis` path. Export nothing new (both
dispatch methods are already exported under `lineageplot!`).

---

### 5. Write `test/test_LineageAxis.jl`

**Type**: TEST
**Output**: All `test_LineageAxis` assertions green; pixel↔data correctness
after resize; all three orientations render without error; no Aqua or JET
regressions.
**Depends on**: Task 4

Write `test/test_LineageAxis.jl` using `CairoMakie`. Organize with `@testset`
blocks.

Cover:
- Default attribute values: `display_polarity == :standard`, `lineage_orientation
  == :left_to_right`, `show_x_axis == false`, `show_grid == false`.
- `display_polarity = :standard`: after `reset_limits!`, x-axis min is the
  minimum process coordinate.
- `display_polarity = :reversed`: after `reset_limits!`, x-axis is flipped
  (minimum process coordinate is at visual right).
- `lineage_orientation = :right_to_left`: produces the same axis limit
  configuration as `display_polarity = :reversed` + `:left_to_right`.
- `lineage_orientation = :radial`: axis has equal x and y scales.
- `axis_polarity` inference: pass `lineageunits = :coalescenceage`; verify
  `ax.axis_polarity == :backward`.
- `axis_polarity` manual override: set `ax.axis_polarity = :forward` explicitly;
  verify it is not overwritten by inference.
- `show_x_axis = true`: axis has visible x-axis ticks after setting.
- `lineageplot!` on a plain `Axis`: completes without error using the 4-leaf
  fixture.
- `lineageplot!` on a `LineageAxis`: completes without error; `reset_limits!`
  is called and axis limits are non-default.
- Resize: trigger the scene viewport Observable and verify
  `CoordTransform.data_to_pixel` returns updated coordinates.

All tests deterministic.
