# Target reference capacities

Comprehensive inventory of visualization types, annotation layers, styling
options, and axis semantics that LineagesMakie.jl should ultimately support.
Derived from:

- **ggtree** (R/ggplot2) — the most complete existing phylogenetic visualization
  system; serves as the functional reference baseline
- **PhyloNetworks.jl / PhyloPlots.jl** — defines the extra visual vocabulary
  required for reticulate (non-tree) network structures
- **LineageAxis design** (described in section 0 below) — the semantic axis
  abstraction that grounds the coordinate system and makes the above correctly
  composable

## 0. LineageAxis — the semantic axis abstraction

LineagesMakie.jl is organized around `LineageAxis`, a custom Makie `Block`
that functions as a semantic axis for branching and merging processes. This
section describes the concept fully. Readers of this document do not need any
other source to understand `LineageAxis`; it is presented here as a foundational
design principle that all other capabilities in this document depend on.

### Why a semantic axis is needed

A phylogenetic tree is not simply a geometric object. It carries meaning: the
primary dimension of the tree represents a process (evolutionary time,
coalescent time, substitution count, branching rank, or any scalar index of
process state), and the layout on screen is a *rendering choice* that may or
may not align with the process direction.

Without an explicit semantic axis, three distinct concerns collapse into one
and become impossible to separate cleanly:

1. **Tree-centric:** What is the process coordinate of each vertex? Which
   direction does the process run (root-to-leaf or leaf-to-root)? This is
   determined by the data and the chosen `lineageunits` value.
2. **User-centric:** What does the process coordinate mean to the researcher?
   Is it "forward time" (species diversification) or "backward time"
   (coalescence)? Is it measured in millions of years, substitutions per site,
   or event ranks?
3. **Plotting-centric:** How is the process coordinate embedded in the 2D
   scene? Which screen axis carries it? Which end of that axis has the smaller
   values?

These three concerns are independent. A coalescent model with leaf-relative
process coordinates (user-centric: backward time) can be drawn with the
rootvertex at either the left or the right (plotting-centric choice), and the
researcher may think of it as "coalescent time increasing toward the past"
(user-centric) or simply as a clade graph display tool. Conflating these three
concerns leads to an API that either forces one convention on the user or
requires ad-hoc workarounds for every deviation from that convention.

`LineageAxis` separates them explicitly.

### The primary dimension

The primary dimension of `LineageAxis` is the one-dimensional index set of the
branching process. It is the distinguished coordinate along which the process
progresses.

In a standard rectangular tree layout with the rootvertex at the left and
leaves at the right, this is the x-axis. But this is a rendering convention,
not a structural requirement. The primary dimension can be mapped to any screen
axis in any direction.

The process coordinate values assigned to vertices are determined by the
active **`lineageunits`** value (see section below). The canonical process
coordinate types in LineagesMakie.jl are:

**`branchingtime`** — root-relative, forward polarity. Defined as the
cumulative sum of `edgelength` values on the directed path from the rootvertex
to a given vertex. `branchingtime(rootvertex) = 0`; the value increases toward
the leaves. This is equivalent to "divergence time" in phylogenetic prose and is
the x-coordinate produced by the `:edgelengths` and `:branchingtime` positioning
modes. The process runs in the forward direction: rootvertex is earliest, leaves
are latest.

**`coalescenceage`** — leaf-relative, backward polarity. Defined as the
cumulative sum of `edgelength` values on the directed path from a given vertex
down to any leaf. `coalescenceage(leaf) = 0`; the value increases toward the
rootvertex. This corresponds to "coalescent age" or "backward time" in
population-genetic prose. Requires an ultrametric tree (all root-to-leaf paths
have equal total `edgelength`) or an explicit non-ultrametric policy. The
process runs in the backward direction: leaves are earliest (age = 0), the
rootvertex is latest (age = maximum).

**Clade graph variants** — four clade graph-based `lineageunits` values do not
use edge-length data:
- `:vertexlevels` — integer level = edge count from rootvertex; forward polarity;
  clade graph (unweighted) analogue of `branchingtime`.
- `:vertexdepths` — cumulative path distance (edge count) from rootvertex;
  forward polarity.
- `:vertexheights` — per-vertex path distance to farthest leaf; backward
  polarity; clade graph (unweighted) analogue of `coalescenceage`. This is the
  default when no `edgelength` is supplied, because it aligns all leaves at the
  same x-coordinate (classic cladogram appearance).
- `:vertexcoords` / `:vertexpos` — user-supplied coordinates in data or pixel
  space respectively; polarity is user-defined.

### Axis polarity, display polarity, and orientation

Three attributes of `LineageAxis` govern the relationship between process
coordinates and the screen.

**`axis_polarity`** records the semantic direction of increasing process
coordinates. `:forward` means increasing process coordinate moves in the
root-to-leaf direction; `:backward` means it moves in the leaf-to-root
direction. `LineageAxis` infers this from the active `lineageunits` value:
`:edgelengths`, `:branchingtime`, `:vertexdepths`, and `:vertexlevels` are
`:forward`; `:coalescenceage` and `:vertexheights` are `:backward`. Users can
override this for axis labeling purposes.

**`display_polarity`** governs the mapping from process coordinates to screen
position. `:standard` maps increasing process coordinates to increasing screen
position along `lineage_orientation` (e.g., rightward with
`lineage_orientation = :left_to_right`). `:reversed` inverts this mapping. Display polarity is independent of
axis polarity.

**`lineage_orientation`** selects the screen embedding. `:left_to_right` places
the lineage axis along the x-axis with the origin at the left. `:right_to_left`
places it along x with the origin at the right. `:top_to_bottom` and
`:bottom_to_top` place it along y. `:radial` is the default for circular
layouts.

Some common combinations:

| `lineageunits` value | `display_polarity` | `lineage_orientation` | Result |
|---|---|---|---|
| `:edgelengths` (forward) | `:standard` | `:left_to_right` | Rootvertex at left, leaves at right (standard phylogram) |
| `:edgelengths` (forward) | `:reversed` | `:left_to_right` | Rootvertex at right, leaves at left (paleontological convention) |
| `:coalescenceage` (backward) | `:standard` | `:left_to_right` | Leaves at left (age = 0), rootvertex at right (maximum age) |
| `:coalescenceage` (backward) | `:reversed` | `:left_to_right` | Rootvertex at left, leaves at right (inverted coalescent, non-standard) |
| `:vertexheights` (backward) | `:standard` | `:top_to_bottom` | Leaves at top (height = 0), rootvertex at bottom (dendrogram-down) |

### The secondary dimension

The secondary dimension (transverse axis) governs leaf placement orthogonal to
the primary dimension. In rectangular layouts this is the y-axis; in circular
layouts it is the angular position. Leaf spacing along the transverse axis is
controlled by `leaf_spacing` (default `:equal` for even distribution).

Beyond leaf spacing, the transverse axis supports visual encodings attached to
edges: width, fill, border, cross-sectional geometry. These are the branch-
width gradients, ribbons, and uncertainty envelopes listed in section 2.1.

### Higher-dimensional embeddings and future extensions

`LineageAxis` is designed to generalize beyond 2D planar trees. The primary
dimension (process index) and the transverse dimensions form a product space
that can be extended to three or more dimensions:

- 3D tree renderings (branches as tubes; morphospace trajectories)
- Geographic tip coordinates (tips placed at latitude/longitude)
- Trait-space embeddings

The accessor-first input design does not prevent this: `vertexcoords` already
admits user-supplied 2D coordinates, and the same pattern extends to higher
dimensions. These capabilities are Tier 3 and Tier 4.

**Interval schemas** — named bins or ranges on the primary dimension (geological
epochs, coalescent levels, custom event ranges) — allow visual elements to be
placed by interval name rather than raw coordinate. An interval schema maps a
symbol (`:eocene`, `:pleistocene`) to a numeric range on the lineage axis, and
with transverse dimensions it induces cells or blocks that can hold arbitrary
overlay layers. This is Tier 4.

### Tier classification for LineageAxis capacities

| Capacity | Tier |
|---|---|
| `LineageAxis` custom Makie `Block` with sensible tree defaults | 1 |
| `axis_polarity` attribute (inferred from `lineageunits`; overridable) | 1 |
| `display_polarity` attribute (`:standard` / `:reversed`) | 1 |
| `lineage_orientation` (`:left_to_right`, `:right_to_left`, `:top_to_bottom`, `:bottom_to_top`) | 1 |
| `lineage_orientation = :radial` (circular layouts) | 1 |
| Optional x-axis with tick marks for quantitative `lineageunits` values | 1 |
| `CoordTransform` module for non-isotropic pixel↔data conversion | 1 |
| Viewport-reactive pixel↔data mapping (correct resize behavior) | 1 |
| Dendrogram orientation (`:top_to_bottom` / `:bottom_to_top`) | 2 |
| Interval schemas and geological timescale bands | 4 |
| 3D lineage embeddings (tubes, morphospace) | 4 |
| Geographic tip coordinate constraints | 3 |
| Interval-indexed overlay layers (background fills, annotations by epoch) | 4 |

## 1. Tree and network layout styles

The `layout` argument selects the global coordinate system. All layers and
annotations must respect the active layout.

### 1.1 Rooted layouts

| Layout | Description | Reference |
|---|---|---|
| Rectangular (cladogram) | Standard horizontal; rootvertex left, leaves right; edges at right angles; default `lineageunits = :vertexheights` | ggtree `rectangular` |
| Rectangular (phylogram) | Same but edge horizontal length proportional to `edgelength`; `lineageunits = :edgelengths` or `:branchingtime` | ggtree `rectangular` + `branch.length` |
| Slanted | Diagonal (non-rectangular) edges forming a V-shape | ggtree `slanted` |
| Dendrogram | Rootvertex at top, leaves at bottom; hierarchical-clustering style; `lineage_orientation = :top_to_bottom` | ggtree `dendrogram` |
| Circular | Radial from centre; leaves at outer ring; `lineage_orientation = :radial` | ggtree `circular` |
| Fan | Circular with configurable opening angle (subtree of a circular) | ggtree `fan(angle=)` |
| Inward circular | Circular with leaves pointing inward, rootvertex at outer ring | ggtree `inward_circular` |

### 1.2 Unrooted layouts

| Layout | Description |
|---|---|
| Equal-angle | Classic unrooted; equal angle subtended per subtree |
| Daylight | Iteratively maximises angular space; better for imbalanced trees |

### 1.3 Edge rendering variants

Independent of coordinate layout; controls how edge segments are drawn.

| Style | Description |
|---|---|
| Right-angle | Horizontal + vertical segments (default for rectangular) |
| Diagonal / slanted | Straight lines between parent and child coordinates |
| Ellipse | Curved arcs instead of segments |
| Rounded-rect | Rounded corners on right-angle bends |

### 1.4 Layout transformations

Functions that reproject or rearrange an already-rendered tree.

| Operation | Description |
|---|---|
| `rotate_tree(angle)` | Rotate entire circular/fan layout |
| `open_tree(angle)` | Open a circular tree to fan with given gap angle |
| `flip(vertex1, vertex2)` | Swap position of two sister clades at a vertex |
| `rotate(vertex)` | Swap left/right children at an internal vertex |
| `ladderise(direction)` | Sort children by clade size (left-heavy or right-heavy) |

### Tier classification for layouts

| Capacity | Tier |
|---|---|
| Rectangular (cladogram) | 1 |
| Rectangular (phylogram) | 1 |
| Circular | 1 |
| Fan layout | 2 |
| Slanted layout | 2 |
| Dendrogram (`:top_to_bottom`) | 2 |
| Equal-angle unrooted | 2 |
| Daylight unrooted | 4 |
| Inward circular | 3 |
| Layout transformations (flip, rotate, ladderise) | 2 |

## 2. Core visual layers

Each layer corresponds to an independent Makie `@recipe`. Every layer is
independently togglable and composable.

### 2.1 Edge layer

The fundamental tree structure.

| Property | Options |
|---|---|
| Color | Uniform; mapped per-edge via a callable `(fromvertex, tovertex) -> color` |
| Line width / thickness | Uniform; mapped per-edge |
| Line style | Solid, dashed, dotted |
| Alpha | Uniform or mapped |
| Continuous color gradient along edge | Color interpolated from parent to child value along edge |
| Continuous width gradient along edge | Width interpolated along edge |
| Directionality arrow | Arrow head at child end; configurable size; critical for hybrid edges |
| Root edge | Optional stub extending from rootvertex |

### 2.2 Vertex layer (internal vertices)

| Property | Options |
|---|---|
| Marker | Circle, square, diamond, triangle, or no marker |
| Color | Uniform; mapped per-vertex |
| Fill | For hollow markers |
| Size | Uniform; mapped per-vertex |
| Alpha | Uniform or mapped |
| Visibility | Show all / show only vertices with data / hide all |
| Subset filtering | Apply marker only to vertices meeting a predicate |

### 2.3 Leaf layer

Same properties as vertex layer; applied to leaf vertices only.

### 2.4 Rootvertex layer

Separate addressable layer for the rootvertex (distinct styling from other
internal vertices).

### 2.5 Leaf label layer

| Property | Options |
|---|---|
| Text content | Taxon name; or any leaf-associated value via `text_func` |
| Font | Family, size, style (bold, italic), color |
| Offset | Gap between leaf marker and label start |
| Alignment | Left / right / centre; `align = true` draws a connecting dotted line |
| Angle | Rotate labels (important for circular/fan layouts) |
| Connector line | Dotted/dashed line from leaf to aligned label margin |
| Rendering mode | Plain text; framed label; image (e.g. PhyloPic silhouette) |
| Italic | Species names conventionally italicised |
| Subset filtering | Label only a subset of leaves |

### 2.6 Vertex label layer (internal vertices)

| Property | Options |
|---|---|
| Text content | Bootstrap; posterior; name; any per-vertex value via `value_func` |
| Position | At vertex; offset toward parent; offset toward children |
| Font / color / size | Standard |
| Threshold filter | Show label only if value meets predicate |

### 2.7 Edge label layer

| Property | Options |
|---|---|
| Edge length | Numeric value placed at edge midpoint |
| Bootstrap / support | Placed near child vertex or at midpoint |
| Gamma (γ) | Inheritance weight on hybrid edges |
| Custom data | Any edge-associated scalar mapped to text |
| Color / size | Major vs. minor hybrid edges distinguished by color |

### 2.8 Scale bar layer

| Property | Options |
|---|---|
| Position | (x, y) in data coordinates or corner anchor |
| Length | In edge-length data units |
| Label | Numeric value and optional unit string |
| Color / line width / font | Standard |

### Tier classification for core layers

| Layer | Tier |
|---|---|
| `EdgeLayer` (color, linewidth, linestyle, alpha) | 1 |
| `VertexLayer` (internal vertices) | 1 |
| `LeafLayer` | 1 |
| `LeafLabelLayer` | 1 |
| `VertexLabelLayer` with threshold filter | 1 |
| `ScaleBarLayer` | 1 |
| Rootvertex layer | 2 |
| Edge label layer | 2 |
| Continuous color/width gradient along edge | 2 |
| Directionality arrow on edges | 3 |
| Root edge stub | 2 |
| Image rendering in leaf label layer | 4 |
| Connector line / aligned margin labels | 2 |

## 3. Clade and group annotation layers

### 3.1 Clade highlight

Shade the background region occupied by a monophyletic clade.

| Shape | Notes |
|---|---|
| Rectangle | Axis-aligned bounding box around clade |
| Rounded rectangle | Softened corners |
| Encircle / blob | Smooth spline enclosing clade leaves and edges |
| Gradient fill | Radial or linear gradient |

Key parameters: MRCA vertex, fill, color, alpha, padding, `extendto`
(extend to a fixed x value or outer margin).

### 3.2 Clade label / bar

Bracket + text annotation spanning a clade.

| Property | Options |
|---|---|
| Bar | Vertical bracket spanning clade extent |
| Label text | Clade name, beside or at centre of bar |
| Offset | Distance from leaves to bar |
| Text offset | Gap between bar and text |
| Angle | Rotate text |
| Font / color / size | Standard |

### 3.3 Taxa-range strip

Like clade label but defined by two arbitrary leaf names rather than an MRCA
vertex — useful for paraphyletic groupings.

### 3.4 Balance highlight

Highlights the two sister clades descending from a given internal vertex with
alternating fills.

### 3.5 Clade collapse

Replace a clade with a triangle glyph.

| Property | Options |
|---|---|
| Triangle width / height | Proportional to leaf count or fixed |
| Fill / color / alpha | Standard |
| Label | Collapsed clade name |

### 3.6 Clade zoom / inset

Show a zoomed view of a clade alongside the full tree.

### Tier classification for clade layers

| Layer | Tier |
|---|---|
| `CladeHighlightLayer` (rectangle) | 1 |
| `CladeLabelLayer` (bracket + text) | 1 |
| Taxa-range strip | 2 |
| Balance highlight | 2 |
| Clade collapse (triangle) | 2 |
| Clade zoom / inset | 2 |
| Clade highlight (rounded rect, encircle, gradient) | 3 |

## 4. Cross-taxon link layers

Curved or straight lines connecting two arbitrary leaves or vertices.

| Layer | Use case | Key parameters |
|---|---|---|
| Taxa link | Co-evolution, host–parasite, gene transfer | `leaf1`, `leaf2`, `curvature`, `color`, `linestyle`, `arrow` |
| Tanglegram link | Paired tree comparison | Same |

Tier: 4

## 5. Network-specific layers

Required when the input is a phylogenetic network (has reticulations).

### 5.1 Hybrid vertex marker

| Property | Options |
|---|---|
| Marker | Distinct shape (filled diamond, double circle) |
| Color / fill / size | May differ from tree-vertex defaults |
| Label | Hybrid tag (e.g. `#H1`) |

### 5.2 Hybrid / reticulation edge rendering

Each reticulation has two parent edges converging on the same child vertex.

| Property | Options |
|---|---|
| Major edge | Primary inheritance path (γ > 0.5) |
| Minor edge | Secondary path (γ < 0.5); conventionally dashed or lighter |
| Color (major) | e.g. dark blue |
| Color (minor) | e.g. light blue / sky blue |
| Line weight | May be proportional to γ |
| Arrow / directionality | Required to show gene-flow direction |
| Curve / routing | Curved arc to avoid overlap with tree edges |

### 5.3 Gamma (γ) label layer

| Property | Options |
|---|---|
| Value displayed | γ (raw), percentage, or both |
| Position | Below edge (convention), at midpoint |
| Color | Matches edge color (major/minor) |

### 5.4 Network view modes

| Mode | Description |
|---|---|
| Full network | All edges rendered, including major and minor hybrid edges |
| Major tree | Only major edges shown; minor hybrid edges omitted or indicated by arrows |

### 5.5 Rooting / direction display

| Mode | Options |
|---|---|
| Rooted | Rootvertex marked; all edges directed away from rootvertex |
| Semi-directed | Hybrid edges directed; tree edges undirected |
| Unrooted | No directional arrows on tree edges |

### Tier classification for network layers

| Layer | Tier |
|---|---|
| All network-specific layers | 3 |

## 6. External data overlay layers

### 6.1 Aligned heatmap panel

A rectangular heatmap aligned to leaf order, appended adjacent to the tree.

| Property | Options |
|---|---|
| Data | Matrix with rows = taxa, columns = traits/sites |
| Color scale | Low/high colors; diverging; categorical |
| Column labels | Position, angle, font |
| Width / offset | Relative width and gap from tree |
| Multiple panels | Stack multiple heatmaps |
| Legend | Color bar per heatmap |

### 6.2 Multiple sequence alignment panel

DNA or protein alignment visualized alongside the tree.

| Property | Options |
|---|---|
| Color scheme | Nucleotide (A/C/G/T), amino acid, or custom |
| Window | Column range to display |
| Width / offset | Layout parameters |

### 6.3 Faceted data panel

Generic additional panel aligned to leaf order, rendered with an arbitrary
plot type (bar, dot, box, line).

| Property | Options |
|---|---|
| Panel label | Strip text |
| Data | Per-leaf values |
| Plot type | Bar, point, segment, density, etc. |
| Relative width | Width relative to tree panel |
| Multiple panels | Arbitrary number with independent widths |

### 6.4 Vertex pie chart insets

Pie charts embedded at vertex or leaf positions showing compositional data
(ancestral state probabilities, population mixture proportions).

### 6.5 Vertex bar chart insets

Same as pie but rendered as stacked or grouped bars.

### 6.6 Arbitrary subplot insets

Embed any plot object at a vertex or edge position.

### 6.7 Uncertainty / range bars

Horizontal bars expressing uncertainty at leaves or vertices (95% HPD intervals
for divergence-time estimates).

| Property | Options |
|---|---|
| Interval | Min / max values |
| Centre | Mean, median, or vertex coordinate |
| Color / line width / alpha | Standard |

### Tier classification for data overlay layers

| Layer | Tier |
|---|---|
| Uncertainty / range bars | 2 |
| Aligned heatmap panel | 2 |
| Tanglegram / paired-tree layout | 2 |
| Faceted data panel | 4 |
| MSA panel | 4 |
| Vertex pie / bar chart insets | 4 |
| Arbitrary subplot insets | 4 |

## 7. Multi-panel and comparative layouts

### 7.1 Tanglegram (paired trees)

Two mirrored trees connected by association lines.

| Property | Options |
|---|---|
| Ladderise / optimise | Minimise link crossings |
| Link style | Straight, curved, sigmoid |
| Link color / alpha | Uniform or mapped to association strength |
| Gap | Space between the two trees |

### 7.2 Tree density plot

Overlay of many trees (e.g. MCMC posterior sample) showing clade graph
(branching structure) and edge-length uncertainty.

| Property | Options |
|---|---|
| Color / alpha | Per-tree or global translucency |
| Alignment | Align at leaves, rootvertex, or internal vertex |
| Summary tree overlay | Consensus or MCC tree drawn on top |

### Tier classification

| Capacity | Tier |
|---|---|
| Tanglegram (paired trees) | 2 |
| Tree density overlay | 4 |

## 8. Axes, time scale, and legends

### 8.1 Primary axis

The `LineageAxis` primary dimension axis (see section 0 for full description).

| Property | Options |
|---|---|
| Direction | Controlled by `axis_polarity` + `display_polarity` (see section 0) |
| Geological time scale | Named interval bands with labels (Tier 4; `interval_schema`) |
| Custom tick positions and labels | Override auto ticks |
| Reversed display | Controlled by `display_polarity = :reversed` |

### 8.2 Scale bar

Standalone scale bar as an alternative to a full axis.

### 8.3 Color legend / color bar

For any continuous data mapped to color.

### 8.4 Theme

| Element | Options |
|---|---|
| Background | White, transparent, custom color |
| Grid lines | None (standard for trees), horizontal, both |
| Axis visibility | No axes (classic tree), x-axis only, both |
| Panel border | On/off |
| Legend position | Standard Makie options |

### Tier classification

| Capacity | Tier |
|---|---|
| Primary axis with optional tick marks | 1 |
| Scale bar layer | 1 |
| Reversed axis (`display_polarity`) | 1 |
| Dendrogram y-axis | 2 |
| Color legend / color bar | 2 |
| Geological time scale bands (`interval_schema`) | 4 |

## 9. Aesthetic mapping summary

All layers support mapping any of the following aesthetics to data callables
applied per-vertex, per-leaf, or per-edge.

| Aesthetic | Applicable layers |
|---|---|
| `color` | Edges, vertices, leaves, labels, highlights |
| `fill` | Vertex/leaf markers, clade highlights, bars |
| `linewidth` | Edges, markers (stroke) |
| `linestyle` | Edges, connector lines |
| `alpha` | All layers |
| `marker` | Vertex and leaf markers |
| `text` (via `text_func` / `value_func`) | Leaf labels, vertex labels, edge labels |
| `fontsize` | Label layers |
| `italic` | Label layers |

Data sources:
- Per-vertex, per-leaf, or per-edge attributes in the tree object itself
  (accessed via `vertexvalue`, `edgelength`, or any accessor callable)
- External data joined to the tree before calling `lineageplot` (no bespoke
  join operator; users join prior to plotting, consistent with
  STYLE-julia.md's prohibition on bespoke operators)

## 10. Interactivity

Not required for Tier 1 but architecturally possible via Makie's native
interaction system. All recipes are Observable-native; the interaction layer
is just a matter of wiring.

| Feature | Description | Tier |
|---|---|---|
| Hover tooltip | Show vertex/leaf name, edge length, γ, or any attribute on hover | 4 |
| Click to select | Select a clade or leaf for further inspection | 4 |
| Click to collapse/expand | Interactive clade folding | 4 |
| Pan and zoom | Standard Makie axis interaction (provided by `Axis` / `LineageAxis`) | 1 |
| Lazy expansion | For very large trees: render subtrees on demand | 4 |
| Observable-reactive re-layout | Wrapping tree in Observable; updating triggers full re-render | 1 |
| Observable-reactive attributes | Per-attribute Observables (color, alpha, etc.) update without re-calling `lineageplot!` | 1 |

## 11. Priority and tier classification summary

### Tier 1 — Core MVP

- `LineageAxis` with full semantic axis abstraction (axis_polarity,
  display_polarity, lineage_orientation, CoordTransform, viewport-reactive
  pixel↔data mapping)
- Rectangular (cladogram + phylogram) and circular layouts
- All eight `lineageunits` values (`:edgelengths`, `:branchingtime`,
  `:coalescenceage`, `:vertexdepths`, `:vertexheights`, `:vertexlevels`,
  `:vertexcoords`, `:vertexpos`)
- `EdgeLayer`, `VertexLayer`, `LeafLayer`, `LeafLabelLayer`,
  `VertexLabelLayer`, `CladeHighlightLayer` (rectangle), `CladeLabelLayer`,
  `ScaleBarLayer`
- `LineagePlot` composite recipe
- Observable-native reactivity throughout
- Primary axis with optional tick marks for quantitative `lineageunits` values
- AbstractTrees.jl adapter
- Full test coverage (unit, integration, smoke, Aqua, JET)

### Tier 2 — Standard annotation

- Fan layout; slanted layout; equal-angle (unrooted); dendrogram orientation
- Layout transformations (flip, rotate, ladderise)
- Edge labels (edge length, bootstrap, γ)
- Clade collapse (triangle)
- Clade zoom / inset view
- Continuous color / width gradient along edges
- Root edge stub
- Aligned heatmap panel
- Uncertainty / range bars
- Tanglegram layout
- Rootvertex layer
- Graphs.jl adapter

### Tier 3 — Network-specific and advanced layout

- Hybrid vertex marker layer
- Hybrid / reticulation edge rendering (major + minor, color distinction)
- Gamma (γ) label layer
- Full-network vs. major-tree view mode toggle
- Arrow / directionality rendering on reticulation edges
- Inward circular layout
- Geographic tip coordinate constraints
- PhyloNetworks.jl adapter

### Tier 4 — Advanced and aspirational

- Taxa-link / cross-taxon curve layer
- Vertex pie / bar chart insets
- MSA panel
- Faceted generic data panel
- Tree density overlay
- Geological time scale axis with interval schema
- Hover tooltip; click-to-collapse; lazy expand
- Daylight / tree-and-leaf unrooted layouts
- 3D lineage embeddings (tubes, morphospace)
- Interval-indexed overlay layers (backgrounds, fills, annotations by epoch)
- Arbitrary subplot insets at vertices
