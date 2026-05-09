# Planned capacities

This roadmap lists planned capacities for LineagesMakie.jl. It is not an API
commitment. The README and documentation describe the current supported public
surface.

## Current foundation

LineagesMakie.jl currently provides the core Makie-native plotting foundation:

- generic `LineageGraphAccessor` input with a required `children` accessor
- `abstracttrees_accessor` for AbstractTrees.jl-compatible data
- rectangular rooted-tree and shared-parent DAG lineage-graph layouts,
  including edgeweight-proportional displays when the graph satisfies the
  current coordinate contract
- radial layout with chord-style circular edges
- all current `lineageunits` values
- `LineageAxis` with `axis_polarity`, `display_polarity`, and
  `lineage_orientation`
- quantitative x-axis and y-axis decorations, labels, and grid lines
- optional rooted full-network `PhyloNetworks.HybridNetwork` plotting with
  hybrid-node markers, major/minor reticulation-edge distinction, and gamma
  labels
- edge, node, leaf, leaf-label, node-label, clade-highlight, clade-label,
  graph-capable node-group highlight, graph-capable node-group label, and
  scale-bar layers
- Observable-aware Makie recipe composition

## Near-term planned capacities

These capacities extend the standard 2D rooted-tree plotting surface:

- fan layout with configurable opening angle
- slanted layout with diagonal edge rendering
- equal-angle unrooted layout
- rounded or curved edge variants
- basenode-specific styling
- basenode edge stub
- edge label layer for edgeweights, support values, or other edge data
- continuous color and width mapping along edges
- clade collapse with triangle glyphs
- clade zoom and inset views
- leaf-range strips for groups that are not represented by one MRCA node
- aligned heatmap panels keyed to `leaf_order`
- layout transformations such as rotating or ladderising child order
- Graphs.jl adapter

## Network and advanced layout capacities

These capacities target reticulate lineage graphs and richer layout control:

- major-tree projection and other projected-tree network views
- semidirected and unrooted network display policies
- inward circular layout
- geographic leaf coordinate constraints

## Advanced planned capacities

These capacities are larger extensions and may require new ownership or
verification design before implementation:

- daylight unrooted layout
- tanglegram-style links between leaves or nodes in paired lineage graphs
- multiple sequence alignment panel
- faceted data panels aligned to `leaf_order`
- node inset layers such as pie or bar summaries
- tree-density overlays
- interval schemas for named coordinate ranges
- geological time scale bands driven by interval schemas
- hover tooltips
- click-to-collapse and lazy expansion
- 3D lineage embeddings with edges as tubes or trait-space trajectories
- image-backed leaf labels

## Roadmap rules

- Planned capacities must not appear in README examples as current behavior.
- New public terms must be added to `STYLE-vocabulary.md` before implementation.
- Visual capacities require rendered verification artifacts.
- Host-framework behavior must follow Makie contracts rather than local
  workarounds.
