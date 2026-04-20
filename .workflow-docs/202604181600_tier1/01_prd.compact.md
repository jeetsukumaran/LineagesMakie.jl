---
date-created: 2026-04-20T00:00:00
source: 01_prd.md
supplements:
  - .workflow-docs/00-design/controlled-vocabulary.md
  - .workflow-docs/00-design/design.md
  - .workflow-docs/00-design/target-reference-capacities.md
  - STYLE-julia.md
  - STYLE-git.md
  - STYLE-docs.md
  - CONTRIBUTING.md
---

# LineagesMakie.jl — Tier 1 MVP (compact PRD)

**Scope:** Tier 1 only. Full background in `01_prd.md`; supplements above for
context. This document is self-contained for implementation.

**Makie version floor:** ≥ 0.24. `map!` / `register_computation!` (ComputeGraph)
throughout. Set `"Makie" = "0.24"` in `[compat]` before writing any recipe or
Block code.

**Central invariant:** Three views are always independently addressable.
`Geometry` (tree-centric) produces process coordinates with no screen knowledge.
`CoordTransform` (plotting-centric) converts coordinates with no semantic
knowledge. `LineageAxis` joins them. No module may cross these boundaries.

---

## Controlled vocabulary (quick reference)

Full definitions and proscribed alternates in `controlled-vocabulary.md`.

| Canonical | Definition |
|---|---|
| `vertex` / `vertices` | Any graph element |
| `leaf` / `leaves` | Terminal vertex (`children` returns empty) |
| `rootvertex` | Unique vertex with no parent; first positional arg |
| `edge` | Directed connection `fromvertex → tovertex` |
| `fromvertex` / `tovertex` | Source / destination in edge accessor |
| `edgelength` | Scalar edge measure; also the accessor callable |
| `vertexvalue` | Per-vertex data accessor `vertex -> Any` |
| `branchingtime` | Cumulative `edgelength` from `rootvertex`; root = 0 |
| `coalescenceage` | Cumulative `edgelength` to leaf; leaf = 0 |
| `height` | Per-vertex: path distance to farthest leaf |
| `clade graph` / `cladegraph` | Branching structure as label-preserving isomorphism class (the phylogenetic "topology"); `cladological` = adjective |
| `process_coordinate` | Doc term: scalar that positions a vertex along lineage axis |
| `lineageunits` | Keyword selecting how process coordinates are determined |
| `axis_polarity` | `:forward` or `:backward`; semantic direction of increasing process coords |
| `display_polarity` | `:standard` or `:reversed`; screen direction of increasing process coords |
| `lineage_orientation` | How lineage axis is embedded in scene |
| `vertex_positions` | `Dict` mapping vertex → `Point2f` in layout space |
| `edge_paths` | Geometric paths for edge rendering |
| `leaf_order` | Ordered leaf sequence along transverse axis |
| `leaf_spacing` | Inter-leaf spacing; default `:equal` |
| `boundingbox` | Smallest axis-aligned enclosing rectangle |
| `interval_schema` | Named axis bins — Tier 4; reserved |

**Compound-word rule:** One-word accessor names: `edgelength`, `vertexvalue`,
`coalescenceage`, `branchingtime`, `fromvertex`, `tovertex`, `rootvertex`,
`boundingbox`, `lineageunits`. Multi-word struct fields keep underscores:
`vertex_positions`, `edge_paths`, `leaf_order`, `leaf_spacing`, `axis_polarity`,
`display_polarity`, `lineage_orientation`.

---

## Accessor contract

All input routes reduce to these callable keywords. Internal code depends only
on these; never on source tree type.

| Keyword | Signature | Required when |
|---|---|---|
| `children` | `vertex -> iterable` | Always |
| `edgelength` | `(fromvertex, tovertex) -> Float64` or `-> (; value::Float64, units::Symbol)` | `lineageunits = :edgelengths` |
| `vertexvalue` | `vertex -> Any` | Optional; drives label/color layers |
| `branchingtime` | `vertex -> Float64` | `lineageunits = :branchingtime` |
| `coalescenceage` | `vertex -> Float64` | `lineageunits = :coalescenceage` |
| `vertexcoords` | `vertex -> Point2f` | `lineageunits = :vertexcoords` |
| `vertexpos` | `vertex -> Point2f` | `lineageunits = :vertexpos` |

AbstractTrees adapter: wraps `AbstractTrees.children`; forwards to above contract.

---

## `lineageunits`

Default: `:edgelengths` if `edgelength` supplied; `:vertexheights` otherwise.

| Value | Accessor | Process coordinate | `axis_polarity` |
|---|---|---|---|
| `:edgelengths` | `edgelength` | Cumulative `edgelength` from `rootvertex` | `:forward` |
| `:branchingtime` | `branchingtime` | `branchingtime(vertex)` directly | `:forward` |
| `:coalescenceage` | `coalescenceage` | `coalescenceage(vertex)`; leaf = 0 | `:backward` |
| `:vertexdepths` | none | Cumulative path distance (edge count) from `rootvertex` | `:forward` |
| `:vertexheights` | none | Path distance to farthest leaf; leaf = 0 | `:backward` |
| `:vertexlevels` | none | Integer level from `rootvertex`; equal spacing | `:forward` |
| `:vertexcoords` | `vertexcoords` | User `(x, y)` in data coords | User-defined |
| `:vertexpos` | `vertexpos` | User `(x, y)` in pixel coords | User-defined |

**Polarity summary:** Forward values (`:edgelengths`, `:branchingtime`,
`:vertexdepths`, `:vertexlevels`) → rootvertex = 0, increases toward leaves.
Backward values (`:coalescenceage`, `:vertexheights`) → leaves = 0, increases
toward root. With `display_polarity = :standard` + `lineage_orientation =
:left_to_right`: forward → leaves at right; backward → root at right.

**Traversal sharing:** `:branchingtime` and `:edgelengths` share preorder
cumulative-sum pass. `:coalescenceage` uses postorder. `:vertexdepths`,
`:vertexheights`, `:vertexlevels` share single depth-first pass.
`:vertexcoords` and `:vertexpos` bypass layout entirely.

---

## Behavioral requirements

Requirements not fully specified by module interfaces below.

1. `edgelength` returning `nothing` / `missing` → unit-length fallback for that
   edge + warning identifying it. Negative value → `ArgumentError` immediately.
2. `lineageunits = :coalescenceage` with non-ultrametric tree → `ArgumentError`
   by default. Controlled by `nonultrametric` keyword: `:error` (default) |
   `:minimum` | `:maximum`.
3. Zero-leaf tree → `ArgumentError` before layout.
4. Cycle in `children` traversal → `ArgumentError` before layout.
5. `vertexvalue` returning unexpected type for a label layer → informative error
   at plot time.
6. `ScaleBarLayer` omitted by default when `lineageunits ∈ {:vertexheights,
   :vertexlevels, :vertexdepths}` (no meaningful unit to display).
7. All fixed-size elements (markers, labels, padding) must be sized in pixel
   space. No layer may assume `x_scale == y_scale`. Use `CoordTransform`
   utilities or `markerspace = :pixel`. Violation is a correctness bug.
8. Resize must not distort fixed-size elements. `CoordTransform` observables
   update reactively on viewport change.
9. `rootvertex` may be plain value or `Observable`; layout recomputes reactively.
   All attributes are Observables (standard Makie contract).
10. `lineageplot!` dispatches on `Union{LineageAxis, Axis}`; both work.

---

## Layout algorithms

Pure functions in `Geometry`; no Makie dependency; return immutable `TreeGeometry`.

**Rectangular:** Leaves equally spaced on transverse axis (or `leaf_spacing::Float64`
for explicit inter-leaf distance). Process coordinate from active `lineageunits`.
Right-angle edge segments: horizontal from parent position to child transverse
position, then along primary axis to child process coordinate.

**Circular:** Leaves equally spaced angularly (default) or `leaf_spacing::Float64`
for explicit angular separation. Radial position from active `lineageunits`.
Edge geometry controlled by `circular_edge_style` (see Module 2 interface).
`lineage_orientation` defaults to `:radial`.

---

## Module 1 — `Accessors`

**Responsibility:** Accessor protocol + AbstractTrees.jl adapter.

**Interface:**
- `TreeAccessor` struct: fields `children`, `edgelength`, `vertexvalue`,
  `branchingtime`, `coalescenceage`, `vertexcoords`, `vertexpos` (all except
  `children` optional, default `nothing`)
- `tree_accessor(rootvertex; children, edgelength=nothing, vertexvalue=nothing,
  branchingtime=nothing, coalescenceage=nothing, vertexcoords=nothing,
  vertexpos=nothing) -> TreeAccessor`
- `abstracttrees_accessor(rootvertex; edgelength=nothing, vertexvalue=nothing,
  branchingtime=nothing, coalescenceage=nothing) -> TreeAccessor`
- `is_leaf(accessor, vertex) -> Bool`
- `leaves(accessor, rootvertex) -> iterator`
- `preorder(accessor, rootvertex) -> iterator`

**Failure modes:** `children` not callable → `ArgumentError` at construction.
Cycle detected during traversal → `ArgumentError` before layout.

**Tested:** Yes

---

## Module 2 — `Geometry`

**Responsibility:** 2D layout coordinates from tree structure + `lineageunits`.
Pure functional; no Makie dependency. Produces process coordinates in natural
direction only — screen direction applied later by `LineageAxis`.

**Interface:**
- `TreeGeometry` struct (immutable): `vertex_positions::Dict`, `edge_paths`,
  `leaf_order`, `boundingbox`. Element type of `edge_paths` follows Makie's
  line-data conventions; derive from local Makie source (see References) —
  specifically how `lines!` / `linesegments!` consume path data. Do not invent
  a bespoke representation.
- `rectangular_layout(rootvertex, accessor::TreeAccessor;
  leaf_spacing=:equal, lineageunits=:vertexheights) -> TreeGeometry`
- `circular_layout(rootvertex, accessor::TreeAccessor;
  leaf_spacing=:equal, lineageunits=:vertexheights,
  circular_edge_style=:chord) -> TreeGeometry`
- `boundingbox(geom::TreeGeometry) -> Rect2f`

`circular_edge_style` values:
- `:chord` **(Tier 1, default)** — angular connectors are straight line segments
  (chords) between parent angular position and each child angular position at
  parent's radial distance; radial segments are straight lines outward to child's
  radial position.
- `:arc` **(Tier 2, do not implement)** — proper circular arc segments using
  `BezierPath` / arc primitives from Makie's `src/bezier.jl`.

All eight `lineageunits` values implemented. `:vertexcoords` / `:vertexpos`
bypass layout computation.

**Failure modes:** negative `edgelength` → `ArgumentError` (identify edge);
zero-leaf tree → `ArgumentError`; missing `edgelength` in `:edgelengths` →
warning + unit-length fallback; non-ultrametric + `:coalescenceage` →
`ArgumentError` by default (see `nonultrametric` keyword).

**Tested:** Yes

---

## Module 3 — `CoordTransform`

**Responsibility:** Pixel↔data coordinate utilities for non-isotropic axes.
No semantic knowledge of process coordinates.

**Interface:**
- `data_to_pixel(scene, point::Point2f) -> Point2f`
- `pixel_to_data(scene, point::Point2f) -> Point2f`
- `pixel_offset_to_data_delta(scene, data_point::Point2f, pixel_offset::Vec2f) -> Vec2f`
- `register_pixel_projection!(plot_attrs, scene)` — registers `viewport` and
  `projectionview` as ComputeGraph inputs; pixel↔data mappings update
  reactively on resize

**Failure modes:** degenerate viewport (zero size) → identity transform + warning.

**Tested:** Yes

---

## Module 4 — `Layers`

**Responsibility:** All composable `@recipe` types + composite `LineagePlot`.
All use `ComputeGraph` for reactive attribute derivation (Makie 0.24+).
All use `CoordTransform.register_pixel_projection!`.

**Recipe table:**

| Type | Function | Responsibility |
|---|---|---|
| `EdgeLayer` | `edgelayer!` | Edges as right-angle or diagonal segments (rectangular); chord or arc (circular) |
| `VertexLayer` | `vertexlayer!` | Markers at internal vertices |
| `LeafLayer` | `leaflayer!` | Markers at leaf vertices |
| `LeafLabelLayer` | `leaflabellayer!` | Text labels at leaves |
| `VertexLabelLayer` | `vertexlabellayer!` | Per-vertex values with threshold filter |
| `CladeHighlightLayer` | `cladehighlightlayer!` | Colored rectangles behind named clades |
| `CladeLabelLayer` | `cladelabellayer!` | Bracket + text for clade annotation |
| `ScaleBarLayer` | `scalebarlayer!` | Edge-length reference bar |
| `LineagePlot` | `lineageplot!` | Composite; assembles all layers above |

**Attributes by recipe:**

- `EdgeLayer`: `color`, `linewidth`, `linestyle`, `alpha`, `edge_style`
  (`:right_angle` | `:diagonal`; rectangular), `circular_edge_style`
  (`:chord` | `:arc`; circular; Tier 1 = `:chord` only)
- `VertexLayer` / `LeafLayer`: `marker`, `color`, `markersize`, `strokecolor`,
  `alpha`, `visible`
- `LeafLabelLayer`: `text_func` (vertex → String), `font`, `fontsize`, `color`,
  `offset`, `italic`, `align`
- `VertexLabelLayer`: `value_func`, `threshold`, `position` (`:vertex` |
  `:toward_parent`)
- `CladeHighlightLayer`: `clade_vertices` (MRCA vertices), `color`, `alpha`,
  `padding`
- `CladeLabelLayer`: `clade_vertices`, `label_func`, `color`, `fontsize`,
  `offset`
- `ScaleBarLayer`: `position`, `length`, `label`, `color`, `linewidth`;
  omitted by default for clade graph `lineageunits` values
- `LineagePlot`: `rootvertex` + all accessor keywords; delegates to layers above

**Tested:** Yes

---

## Module 5 — `LineageAxis`

**Responsibility:** Custom Makie `Block` (`Makie.@Block LineageAxis <:
AbstractAxis`). Joins three-view model to Makie rendering system. Applies
`display_polarity` and `lineage_orientation` at axis setup; provides
viewport-managed pixel↔data infrastructure.

**Attributes:**

| Attribute | Type / values | Default | Notes |
|---|---|---|---|
| `axis_polarity` | `:forward` \| `:backward` | Inferred from `lineageunits` | Overridable; drives axis labeling |
| `display_polarity` | `:standard` \| `:reversed` | `:standard` | Applied via axis limits in `reset_limits!` — see Open Q4 |
| `lineage_orientation` | `:left_to_right` \| `:radial` (Tier 1); `:right_to_left` pending Open Q5 | `:left_to_right` | `:radial` default for circular |
| `show_x_axis` | `Bool` | `false` | Enable for quantitative `lineageunits` |
| `show_y_axis` | `Bool` | `false` | |
| `show_grid` | `Bool` | `false` | |
| `title`, `xlabel`, `ylabel` | Standard Makie | — | |

**Interface:**
- `LineageAxis(figure_position; kwargs...)` — standard Block constructor
- `reset_limits!(ax::LineageAxis)` — fits to `TreeGeometry.boundingbox`;
  applies `display_polarity` by setting limits direction. **Read
  `src/makielayout/` in local Makie source before implementing** (Open Q4).
- `autolimits!(ax::LineageAxis)` — equivalent to `reset_limits!`

`lineageplot!` dispatches on `Union{LineageAxis, Axis}`.

**Tested:** Yes (including smoke test per `axis_polarity` × `display_polarity`
combination)

---

## Style

All code follows `STYLE-julia.md` exactly. Key rules:
- Accessor-pattern arguments: unannotated (§1.13.1 exception)
- All other public function args: annotated at correct abstract level with
  explicit return type (§1.13.1, §1.13.2)
- `struct` default; `mutable struct` only with justification
- File-per-module; 400–600 LOC per file (§8)
- `using Package: name` only; never bare `using Package` (§1.16.6)
- Runic.jl formatting (§3.1)

API names and signatures are derived from first principles per `STYLE-julia.md`,
controlled vocabulary, and current Makie idioms. `target-reference-capacities.md`
is the functional reference, not the API specification.

---

## Testing

Tests exercise documented public contract, not internals. Tree fixtures built
inline from simple clade graphs: 4-leaf balanced, 6-leaf unbalanced, polytomy,
single-leaf. No wall-clock time; no network.

```
test/
  runtests.jl              # Aqua, JET, includes all test_*.jl
  test_Accessors.jl
  test_Geometry.jl
  test_CoordTransform.jl
  test_Layers.jl
  test_LineageAxis.jl
  test_Integration.jl      # end-to-end via CairoMakie
```

Reference: `GraphMakie.jl/src/recipes.jl` (per-element attribute handling,
ComputeGraph pixel-projection pattern).

---

## Out of scope (Tier 1)

- Graphs.jl adapter — Tier 2
- PhyloNetworks.jl adapter, reticulation vertices/edges — Tier 3
- Fan, slanted, unrooted layouts — Tier 2
- Dendrogram orientation (`:top_to_bottom`, `:bottom_to_top`) — Tier 2
- Circular `circular_edge_style = :arc` — Tier 2
- Clade collapse, zoom/inset — Tier 2
- Continuous color/width gradient along edges — Tier 2
- Aligned heatmap panel, tanglegram — Tier 2
- Vertex pie/bar chart insets, MSA panel — Tier 4
- Tree density overlay, interval schemas — Tier 4
- 3D lineage embeddings — Tier 4
- Geographic tip constraints — Tier 3
- Interactive features (tooltip, click-to-collapse) — Tier 4
- File I/O (Newick, Nexus) — not in scope for this package
- Layout transforms (flip, rotate, ladderise) — Tier 2

Architecture must not foreclose any of the above. The three-view separation in
`LineageAxis` and the accessor-first input design must remain clean.

---

## Open questions

1. ~~RESOLVED~~ **Makie version floor:** ≥ 0.24 confirmed. Use ComputeGraph
   throughout. Set `[compat]` accordingly.

2. **Runic.jl CI:** Add `runic --check` to `.github/workflows/CI.yml`.
   *Owner:* implementation phase.

3. **Circular `min_leaf_angle` floor:** May be needed for large trees. Applies
   to both `:chord` and `:arc` variants.
   *Owner:* `Geometry` implementation. *Resolution:* decide during
   `circular_layout`; document the parameter.

4. **`display_polarity` Makie idiom:** Reversed limits vs. `xreversed = true`
   must be confirmed from Makie source before writing `reset_limits!`.
   *Owner:* `LineageAxis` implementation. *Resolution:* read
   `src/makielayout/` in local Makie source (see References below).

5. **`lineage_orientation = :right_to_left`:** May be redundant with
   `display_polarity = :reversed` + `:left_to_right`. **Do not implement as a
   distinct value without explicit project-owner approval.** Implementing agent
   must evaluate, propose recommendation, and get approval before committing
   `LineageAxis` attribute API. Affects Tier 2+ additions.

---

## References and governance

All implementation must comply with — and all downstream issues must reference:

| Document | Path | Scope |
|---|---|---|
| Julia style | `STYLE-julia.md` | All Julia code; mandatory; every PR |
| Git conventions | `STYLE-git.md` | Branching, commit messages; mandatory |
| Docs style | `STYLE-docs.md` | All documentation; mandatory |
| Contribution process | `CONTRIBUTING.md` | All contributions |
| Controlled vocabulary | `.workflow-docs/00-design/controlled-vocabulary.md` | All identifiers, types, symbols, prose; no amendment without owner approval |
| Full PRD | `.workflow-docs/202604181600_tier1/01_prd.md` | Background, user stories, rationale |
| Design doc | `.workflow-docs/00-design/design.md` | Conceptual architecture, examples |
| Target capacities | `.workflow-docs/00-design/target-reference-capacities.md` | Feature vocabulary, tier classification, `LineageAxis` full spec |

### Makie documentation

Docs:
`/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/`
- `docs/src/explanations/recipes.md`
- `docs/src/explanations/conversion_pipeline.md`
- `docs/src/explanations/architecture.md`
- `GraphMakie.jl/src/recipes.jl` — ComputeGraph pixel-projection reference

Source **(must be read before implementing any Makie-dependent module)**:
`/home/jeetsukumaran/site/storage/local/00_resources/codebases-and-documentation/Makie.jl/Makie/`
- `src/makielayout/` — Block API, `Axis`, custom Block patterns (required for Open Q4)
- `src/compute-plots.jl` — ComputeGraph patterns
- `src/basic_recipes/` — `@recipe` reference implementations
- `src/bezier.jl` — `BezierPath` / arc primitives (circular `:arc`, Tier 2)
