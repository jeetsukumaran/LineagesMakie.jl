# Target Reference Capacities

Comprehensive inventory of visualization types, annotation layers, and styling
options that PhyloMakie.jl should ultimately support. Derived from:

- **ggtree** (R/ggplot2) — the most complete existing phylogenetic visualization
  system; serves as the functional reference baseline
- **PhyloNetworks.jl / PhyloPlots.jl** — defines the extra visual vocabulary
  required for reticulate (non-tree) network structures

---

## 1. Tree / Network Layout Styles

The `layout` argument selects the global coordinate system. All layers and
annotations must respect the active layout.

### 1.1 Rooted Layouts

| Layout | Description | ggtree analogue |
|---|---|---|
| **Rectangular** (cladogram) | Standard horizontal; root left, tips right; branches at right angles | `rectangular` |
| **Rectangular** (phylogram) | Same but branch horizontal length proportional to edge length | `rectangular` + `branch.length` |
| **Slanted** | Diagonal (non-rectangular) branches forming a V-shape | `slanted` |
| **Dendrogram** | Root at top, tips at bottom; hierarchical-clustering style | `dendrogram` |
| **Circular** | Radial from centre; tips at outer ring | `circular` |
| **Fan** | Circular with configurable opening angle (subtree of a circular) | `fan(angle=)` |
| **Inward circular** | Circular with tips pointing inward, root at outer ring | `inward_circular` |

### 1.2 Unrooted Layouts

| Layout | Description | ggtree analogue |
|---|---|---|
| **Equal-angle** | Classic unrooted; equal angle subtended per subtree | `equal_angle` |
| **Daylight** | Iteratively maximises angular space; better for imbalanced trees | `daylight` / `unrooted` |

### 1.3 Edge Rendering Variants

Independent of coordinate layout; controls how branch segments are drawn.

| Style | Description |
|---|---|
| **Right-angle** | Horizontal + vertical segments (default for rectangular) |
| **Diagonal / slanted** | Straight lines between parent and child coordinates |
| **Ellipse** | Curved arcs instead of segments (aesthetic variant) |
| **Rounded-rect** | Rounded corners on right-angle bends |

### 1.4 Layout Transformations

Functions that reproject or rearrange an already-plotted tree.

| Operation | Description | ggtree analogue |
|---|---|---|
| `rotate_tree(angle)` | Rotate entire circular/fan layout | `rotate_tree()` |
| `open_tree(angle)` | Open a circular tree to fan with given gap angle | `open_tree()` |
| `flip(node1, node2)` | Swap position of two sister clades at a node | `flip()` |
| `rotate(node)` | Swap left/right children at an internal node | `rotate()` |
| `ladderise(direction)` | Sort children by clade size (left-heavy or right-heavy) | `ladderize()` (via ape) |

---

## 2. Core Visual Layers

Analogous to ggplot2 `geom_*` layers. In Makie these become recipe components
or composable `plot!` calls. Each layer should be independently togglable.

### 2.1 Branch / Edge Layer

The fundamental tree structure.

| Property | Options / Notes |
|---|---|
| **Color** | Uniform; mapped to continuous data (e.g. evolutionary rate, posterior); mapped to discrete group |
| **Line width / thickness** | Uniform; mapped to data (e.g. bootstrap support, γ weight) |
| **Line style** | Solid, dashed, dotted, etc. |
| **Transparency (alpha)** | Uniform or mapped |
| **Continuous color gradient along branch** | Color interpolated from parent value to child value along branch (ggtree `continuous="color"`) |
| **Continuous width gradient along branch** | Width interpolated along branch (ggtree `continuous="size"`) |
| **Directionality arrow** | Arrow head at child end; configurable size and style; critical for hybrid edges in networks |
| **Root edge** | Optional stub branch extending from root node (ggtree `geom_rootedge`) |

### 2.2 Node Layer (Internal Nodes)

| Property | Options / Notes |
|---|---|
| **Marker / glyph** | Circle, square, diamond, triangle, etc.; or no marker |
| **Color** | Uniform; mapped to data |
| **Fill** | For hollow markers |
| **Size** | Uniform; mapped to data (e.g. posterior probability) |
| **Transparency** | Uniform or mapped |
| **Visibility** | Show all / show only nodes with data / hide all |
| **Subset filtering** | Apply marker only to nodes meeting a predicate |

### 2.3 Tip / Leaf Layer

| Property | Options / Notes |
|---|---|
| **Marker / glyph** | Same options as node layer |
| **Color / fill / size / alpha** | Same options |
| **Visibility** | Show all tips / subset |

### 2.4 Root Node Layer

Separate addressable layer for the root node (distinct styling from other
internal nodes — e.g. an outgroup marker or an open circle).

### 2.5 Tip Label Layer

| Property | Options / Notes |
|---|---|
| **Text content** | Taxon name; or any tip-associated data field |
| **Font** | Family, size, style (bold, italic), colour |
| **Offset** | Gap between tip marker and label start |
| **Alignment** | Left / right / centre; `align=true` draws a connecting dotted line to an aligned margin |
| **Angle** | Rotate labels (important for circular/fan layouts) |
| **Connector line** | Dotted/dashed line from tip to aligned label margin |
| **Rendering mode** | Plain text; framed label (box); image (e.g. PhyloPic silhouette) |
| **Italic rendering** | Species names conventionally italicised |
| **Subset filtering** | Label only a subset of tips |

### 2.6 Node / Internal Label Layer

| Property | Options / Notes |
|---|---|
| **Text content** | Bootstrap value; posterior probability; node name; any node-associated data field |
| **Position** | At node; offset toward parent; offset toward children |
| **Font / colour / size** | Same as tip label |
| **Subset / threshold** | Show label only if value > threshold (e.g. bootstrap ≥ 70) |

### 2.7 Edge Label Layer

| Property | Options / Notes |
|---|---|
| **Branch length** | Numeric value placed along branch midpoint |
| **Bootstrap / support** | Placed near child node or branch midpoint |
| **Gamma (γ)** | Inheritance weight on hybrid edges; by convention placed below edge |
| **Edge number** | Internal identifier (for development/debugging) |
| **Custom data** | Any edge-associated scalar mapped to text |
| **Colour / size** | Major vs. minor hybrid edges distinguished by colour |

### 2.8 Scale Bar Layer

Phylogenetic distance scale bar (not a full axis); shows a reference length
and its numeric value.

| Property | Options / Notes |
|---|---|
| **Position** | (x, y) in data coordinates or corner anchor |
| **Width** | Length in branch-length units |
| **Label** | Numeric value and optional unit string |
| **Colour / line width / font** | Standard styling |

---

## 3. Clade & Group Annotation Layers

### 3.1 Clade Highlight

Shade the background region occupied by a monophyletic clade.

| Shape | Notes |
|---|---|
| **Rectangle** | Axis-aligned bounding box around clade |
| **Rounded rectangle** | Softened corners |
| **Encircle / blob** | Smooth spline enclosing clade tips and branches |
| **Gradient fill** | Radial or linear gradient for aesthetic effect |

Key parameters: `node` (MRCA), `fill`, `colour`, `alpha`, `extend`
(padding), `extendto` (extend to a fixed x value / outer margin).

### 3.2 Clade Label / Bar

Bracket + text annotation spanning a clade, typically placed to the right of
tips (ggtree `geom_cladelabel`, `geom_strip`).

| Property | Options / Notes |
|---|---|
| **Bar** | Vertical bracket spanning clade extent |
| **Label text** | Clade name, placed beside or at centre of bar |
| **Offset** | Distance from tips to bar |
| **Text offset** | Gap between bar and text |
| **Angle** | Rotate text (e.g. vertical for space saving) |
| **Font / colour / size** | Standard |
| **Horizontal vs. vertical** | Orientation of bar and text |

### 3.3 Taxa-Range Strip

Like clade label but defined by two arbitrary tip names rather than an MRCA
node — useful for paraphyletic groupings (ggtree `geom_strip`).

### 3.4 Balance Highlight

Highlights the two sister clades descending from a given internal node with
alternating fills — useful for visualising evolutionary "balance"
(ggtree `geom_balance`).

### 3.5 Clade Collapse

Replace a clade with a triangle glyph, optionally sized proportional to the
number of tips or some summary statistic.

| Property | Options / Notes |
|---|---|
| **Triangle width / height** | Proportional to tip count or fixed |
| **Fill / colour / alpha** | |
| **Label** | Collapsed clade name |

### 3.6 Clade Zoom / Inset

Show a zoomed view of a clade alongside the full tree (ggtree `viewClade`,
`zoomClade`).

---

## 4. Cross-Taxon Link Layers

Curved or straight lines connecting two arbitrary tips or nodes.

| Layer | Use Case | Key Parameters |
|---|---|---|
| **Taxa link** | Co-evolution, host–parasite, gene transfer | `tip1`, `tip2`, `curvature`, `colour`, `linetype`, `arrow` |
| **Tanglegram link** | Paired tree comparison; connects same taxon in mirrored trees | Same |

---

## 5. Network-Specific Layers

Required when the input is a phylogenetic network (has reticulations) rather
than a bifurcating tree. These have no analogue in standard tree visualization.

### 5.1 Hybrid Node Marker

Reticulation nodes must be visually distinguished from tree nodes.

| Property | Options / Notes |
|---|---|
| **Glyph** | Distinct shape (e.g. filled diamond, double circle) |
| **Colour / fill / size** | May differ from tree-node defaults |
| **Label** | Hybrid tag (e.g. `#H1`) |

### 5.2 Hybrid / Reticulation Edge Rendering

Each reticulation has two parent edges converging on the same child node.
Both must be rendered, even though this creates a non-tree path.

| Property | Options / Notes |
|---|---|
| **Major edge** | Primary inheritance path (`γ > 0.5`); drawn like a tree edge but colour-distinguished |
| **Minor edge** | Secondary path (`γ < 0.5`); conventionally lighter colour or dashed |
| **Colour (major)** | e.g. dark blue |
| **Colour (minor)** | e.g. light blue / sky blue |
| **Line weight** | May be proportional to γ |
| **Arrow / directionality** | Required to show gene flow direction; essential on minor edges |
| **Arrow size** | Configurable (`arrowlen`) |
| **Curve / routing** | Curved arc to avoid overlap with tree edges; routing must handle crossing |

### 5.3 Gamma (γ) Label Layer

Numeric inheritance weight labels on hybrid edges.

| Property | Options / Notes |
|---|---|
| **Value displayed** | γ (raw), percentage, or both |
| **Position** | Below edge (convention), at midpoint |
| **Colour** | Matches edge colour (major/minor) |
| **Font size / family** | Standard |
| **Toggle** | On/off independently of edge rendering |

### 5.4 Network View Modes

| Mode | Description |
|---|---|
| **Full network** (`:fulltree`) | All edges rendered, including both major and minor hybrid edges |
| **Major tree** (`:majortree`) | Only major edges shown; minor hybrid edges indicated by small arrows or omitted |

### 5.5 Rooting / Direction Model Display

| Property | Options / Notes |
|---|---|
| **Rooted** | Root node marked; all edges directed away from root |
| **Semi-directed** | Hybrid edges directed; tree edges undirected or ambiguously directed |
| **Unrooted** | No directional arrows on tree edges |

---

## 6. External Data Overlay Layers

Panels and glyphs that attach external data to tips or nodes without altering
the tree geometry.

### 6.1 Aligned Heatmap Panel

A rectangular heatmap aligned to tip order, appended to the right of the tree
(ggtree `gheatmap`).

| Property | Options / Notes |
|---|---|
| **Data** | Matrix of values; columns are traits/sites, rows are taxa (aligned by tip label) |
| **Colour scale** | Low / high colours; diverging; categorical |
| **Column labels** | Position (top/bottom), angle, font |
| **Width / offset** | Relative width and gap from tree |
| **Multiple panels** | Stack multiple heatmaps side by side |
| **Legend** | Colourbar per heatmap |

### 6.2 Multiple Sequence Alignment Panel

Visualise an aligned DNA/protein sequence matrix alongside the tree (ggtree
`msaplot`).

| Property | Options / Notes |
|---|---|
| **Colour scheme** | Nucleotide (A/C/G/T), amino acid, or custom |
| **Window** | Column range to display |
| **Width / offset** | Layout parameters |

### 6.3 Faceted Data Panel

Generic additional panel aligned to tip order, rendered with an arbitrary plot
type (bar, dot, box, line) — ggtree `facet_plot` / `geom_facet`.

| Property | Options / Notes |
|---|---|
| **Panel name** | Label for the panel strip |
| **Data** | Data frame with tip labels and value columns |
| **Plot type** | Bar, point, segment, density, etc. |
| **Relative width** | Width of panel relative to tree panel |
| **Multiple panels** | Arbitrary number of panels with independent widths |

### 6.4 Node Pie Chart Insets

Pie charts embedded at node or tip positions, showing compositional data
(e.g. ancestral state probabilities, population mixture proportions) —
ggtree `nodepie` + `geom_inset`.

| Property | Options / Notes |
|---|---|
| **Data** | One row per node; columns are proportions (summing to 1) |
| **Size** | Width and height of inset |
| **Position** | At node coordinate; at branch midpoint |
| **Colours** | One per category |
| **Outline** | Border colour and width |

### 6.5 Node Bar Chart Insets

Same as pie but rendered as stacked or grouped bars — ggtree `nodebar`.

### 6.6 Arbitrary Subplot Insets

Embed any plot object at a node or branch position — ggtree `geom_inset`.

### 6.7 Uncertainty / Range Bars

Horizontal bars at tip or node positions expressing uncertainty (e.g. 95%
HPD interval for a divergence time estimate) — ggtree `geom_range`.

| Property | Options / Notes |
|---|---|
| **Interval** | Min / max values |
| **Centre** | Mean, median, or node coordinate |
| **Colour / line width / alpha** | Standard |

---

## 7. Multi-Panel / Comparative Layouts

### 7.1 Tanglegram (Paired Trees)

Two mirrored trees connected by association lines — ggtree `ggdoubletree`.

| Property | Options / Notes |
|---|---|
| **Ladderise / optimise** | Minimise link crossings by rotating nodes |
| **Link style** | Straight, curved, sigmoid |
| **Link colour / alpha** | Uniform or mapped to association strength |
| **Gap** | Space between the two trees |

### 7.2 Tree Density Plot

Overlay of many trees (e.g. MCMC posterior sample) to show topological and
branch-length uncertainty — ggtree `ggdensitree`.

| Property | Options / Notes |
|---|---|
| **Colour / alpha** | Per-tree colouring or global translucency |
| **Alignment** | Align at tips, root, or internal node |
| **Summary tree overlay** | Consensus or MCC tree drawn on top |

---

## 8. Axes, Time Scale, and Legends

### 8.1 Time / Branch-Length Axis

| Property | Options / Notes |
|---|---|
| **Direction** | Forward (root → tips) or reverse (present time at right) |
| **Geological time scale** | Optional coloured epoch/period bands with labels |
| **Custom tick positions and labels** | Override auto ticks |
| **Reverse time scale** | ggtree `revts()` — flip x-axis so present is at right |

### 8.2 Scale Bar

Standalone bar (section 2.8 above); alternative to a full axis for
unlabelled phylograms.

### 8.3 Colour Legend / Colourbar

For any continuous data mapped to colour.

### 8.4 Theme

Overall plot appearance.

| Element | Options |
|---|---|
| **Background** | White, transparent, custom colour |
| **Grid lines** | None (standard for trees), horizontal, both |
| **Axis visibility** | No axes (classic tree), x-axis only (phylogram), both |
| **Panel border** | On/off |
| **Legend position** | Standard Makie options |

---

## 9. Aesthetic Mapping Summary

All layers should support mapping any of the following aesthetics to data
columns attached to nodes, tips, or edges.

| Aesthetic | Applicable Layers |
|---|---|
| **colour** | branches, nodes, tips, labels, highlights |
| **fill** | node/tip markers, clade highlights, bars |
| **size / linewidth** | branches, markers |
| **linetype / dash pattern** | branches, connector lines |
| **alpha** | all layers |
| **shape / marker** | node and tip markers |
| **label (text)** | tip labels, node labels, edge labels |
| **font size** | label layers |
| **font style** | label layers (bold, italic) |

Data can originate from:
- Node / tip / edge attributes in the tree object itself
- External data joined by tip label or node identifier (analogous to ggtree's
  `%<+%` operator)

---

## 10. Interactivity (Aspirational)

Not required for initial release but should be architecturally possible via
Makie's native interaction system (no external JS dependency, unlike D3Trees).

| Feature | Description |
|---|---|
| **Hover tooltip** | Show node/tip name, branch length, γ, or any attribute on hover |
| **Click to select** | Select a clade or tip for further inspection |
| **Click to collapse/expand** | Interactive clade folding |
| **Pan and zoom** | Standard Makie axis interaction |
| **Lazy expansion** | For very large trees: render subtrees on demand (analogous to D3Trees lazy loading) |

---

## 11. Priority / Tier Classification

To guide implementation order.

### Tier 1 — Core (must have at initial release)

- Rectangular (cladogram + phylogram) and circular layouts
- Branch layer with colour, width, linetype, alpha
- Tip and node marker layers
- Tip label layer (text, offset, italic)
- Node label layer (bootstrap/posterior display with threshold filter)
- Clade highlight (rectangle)
- Clade label / bar
- Scale bar
- Basic theme (no axes / x-axis only)

### Tier 2 — Standard annotation

- Fan layout; slanted layout; equal-angle (unrooted)
- Edge labels (branch length, bootstrap, γ)
- Clade collapse (triangle)
- Clade zoom / inset view
- Continuous colour / width gradient along branches
- Aligned heatmap panel
- Uncertainty / range bars
- Tanglegram layout

### Tier 3 — Network-specific

- Hybrid node marker layer
- Hybrid / reticulation edge rendering (major + minor, with colour distinction)
- Gamma (γ) label layer
- Full-network vs. major-tree view mode toggle
- Arrow / directionality rendering on reticulation edges

### Tier 4 — Advanced / aspirational

- Taxa-link / cross-taxon curve layer
- Node pie / bar insets
- MSA panel
- Faceted generic data panel
- Tree density overlay
- Time-scale axis with geological periods
- Interactive features (tooltip, click, lazy expand)
- Daylight / tree-and-leaf unrooted layouts
