LineageAxis

Overview

`LineageAxis` is the axis abstraction for representing a branching or merging process along its principal direction of progression.
It defines the coordinate system for the process index itself, independent of any particular screen orientation or plotting convention.

In a conventional rectangular tree layout with the root on the left and leaves on the right, the `LineageAxis` usually corresponds to the horizontal plotting axis, with increasing coordinate values extending to the right.
In many phylogenetic applications, this coordinate is interpreted as time, but the abstraction is intentionally broader.
The axis may represent any one-dimensional index on the process, including time, age, mutation count, expected substitutions, branching depth, event order, or any other scalar quantity that can be mapped into $\mathbb{R}$.
It may also represent ordinal scales such as “first branching event”, “second branching event”, and so on.

The key design principle is that `LineageAxis` models the branching process itself rather than any particular visual convention for displaying it.

Conceptual views

The package should distinguish three related but non-identical views of the same object.

Plotting-centric view

This view concerns the mapping from process coordinates into scene coordinates.
It answers questions such as:

- Which plotting axis corresponds to lineage progression?
- Do increasing process coordinates map to increasing or decreasing screen coordinates?
- Is the tree drawn horizontally, vertically, radially, or in some other embedding?

This is a rendering concern.

Tree-centric view

This view concerns the combinatorial or geometric structure of the tree or network itself.
It answers questions such as:

- Which direction is from root to leaves?
- Which axis parameterizes branch extent?
- What quantity is attached to positions along that direction?

This is a structural concern.

User-centric view

This view concerns the interpretation the user assigns to the process.
It answers questions such as:

- Is the process conceived as moving forward in time or backward in time?
- Does increasing process index correspond to increasing real-world time?
- Is the index measured in time, evolutionary distance, event rank, or something else?

This is a semantic concern.

These three views must be separable.
A user may think in forward time, while the plot places the present at the origin and the past at increasing coordinate values.
Likewise, a coalescent process may be semantically backward-time while still being drawn along an axis that increases from rootward to leafward or vice versa depending on the layout.

Primary dimension

The primary dimension of `LineageAxis` is the one-dimensional index set of the branching process.
It is the distinguished coordinate along which the process progresses.

The package should treat this axis as carrying a monotone ordering of process states.
That ordering may or may not agree with real-world time.
More precisely:

- In a forward-time conception, increasing process index is order-preserving with respect to increasing real-world time.
- In a backward-time conception, increasing process index *could be*, depending on schema, order-reversing with respect to increasing real-world time.

“Order-preserving” and “order-reversing” are the right concepts here.

Forward-time processes

Many evolutionary models are naturally conceived in forward time.
In such cases, the process begins near the root and progresses toward the leaves as the process index increases.
A higher axis value corresponds to a later state in the modeled process.

This does not imply that every structural statistic of the tree is monotone in time.
For example, the number of extant lineages or the cardinality of the leaf set is monotone increasing in a pure-birth process, but not in general birth-death models.
The semantics of `LineageAxis` therefore should not be tied to any particular monotonicity property of a derived tree statistic.
It indexes the process directly, not incidental summaries of the process.

Backward-time processes

Some models, most notably coalescent models, are conceived in backward time.
In cases where the indexing reflects the advancement of the process, increasing process index corresponds to decreasing real-world time, so the relationship between process index and real-world time is order-reversing
Note that many conceptions of the model assign monotonically descending labels to the process index, resulting in net order preserving mapping

However, this reversal is semantic, not structural.
The fact that a model is formulated backward in time does not imply that the rendered tree must be flipped, nor does it imply that branch geometry must obey a different API.
It only means that the interpretation of increasing axis values differs.

A coalescent process typically begins with a leaf set and terminates at a rootward common ancestor.
This can be viewed as a pure-death process on the number of extant lineages.
But even here, the tree-like object is still parameterized by a one-dimensional progression variable.
The package should represent that progression uniformly through `LineageAxis`, regardless of whether the user interprets it as forward-time or backward-time.

In other words, the polarity of the probabilistic model and the polarity of the plotting axis must not be conflated.

Axis polarity versus plotting polarity

A central requirement is to distinguish process polarity from plotting polarity.

Examples:

- A user may model the process in forward time, with larger axis values meaning later times, while choosing a plot where the present is at the left and the past is at the right.
- A paleontological plot may place the present at coordinate $0$ and the past at larger positive values, even though the underlying branching process is still conceived from ancestor to descendant.
- A vertical plot may place the present at the top and the past at the bottom, again reversing the relation between semantic time direction and screen-coordinate increase.

Therefore the API should explicitly separate:

- process direction: how the process index relates to the modeled phenomenon
- coordinate direction: how process coordinates relate to plotting coordinates
- screen orientation: how plotting coordinates are embedded in the rendered scene

This separation is necessary to avoid hard-coding assumptions such as “increasing $x$ means forward time” or “root-to-leaf always means left-to-right”.

Domain of the primary axis

`LineageAxis` should support primary coordinates drawn from any scalar or ordinal domain that can be embedded into a one-dimensional ordered coordinate system.

Examples include:

- absolute time
- relative time
- age before present
- branch length
- expected substitutions
- mutation count
- event depth
- event rank
- coalescent level
- arbitrary ordered categories

The implementation should not require that the domain be metrically meaningful in all cases.
Some use cases require only order.
Others require affine or nonlinear coordinate transformations.
The axis abstraction should therefore support both numeric scales and ordered categorical scales, provided they can be mapped into display coordinates.

Secondary dimensions

If the primary axis regulates progression along the branching process, then secondary dimensions regulate placement transverse to that progression.

In standard 2D rectangular tree layouts, this is usually the orthogonal axis, often the nominal $y$-axis in a horizontal tree.
Unlike the primary axis, this dimension is usually controlled mainly by layout rather than intrinsic process semantics.

Examples of secondary-dimension uses include:

- tip ordering
- subtree spacing
- clade separation
- collision avoidance
- bundling or untangling heuristics

Even when this dimension is primarily layout-driven, it can still carry visual encodings.
The package should support attaching orthogonal-channel encodings to branches or nodes, such as:

- branch width
- branch fill
- branch border or stroke
- local cross-sectional size
- band, ribbon, or tube geometry
- uncertainty envelopes

This suggests that the abstraction should not treat the secondary dimension merely as a scalar offset, but more generally as a geometric support for visual structure attached to the lineage.

Higher-dimensional growth

The abstraction should also admit trees, graphs, or networks embedded in more than two dimensions.

Examples include:

- 3D tree renderings where branches are tubes in space
- morphospace trajectories
- ecological or trait-space embeddings
- lineage objects embedded in arbitrary $n$-dimensional coordinate systems

In these cases, the primary lineage index still parameterizes progression along the process, but the embedded geometry may occupy two, three, or more spatial dimensions.
Conceptually, each branch becomes a map from lineage index into an ambient space, possibly with additional cross-sectional geometry attached along that map.

For 3D, one possible interpretation is that each branch is a centerline together with a radius or cross-sectional profile, yielding a tube-like geometry.
For higher dimensions, the same principle generalizes: the lineage index determines position along the process, while an ambient embedding defines where that position lies in the target space.

Coordinate transformations

`LineageAxis` should support explicit coordinate transformations between at least three layers:

- process coordinates
- axis coordinates
- display coordinates

Process coordinates are the native values attached to the modeled object, such as time before present, substitutions, or event rank.
Axis coordinates are normalized coordinates on the conceptual axis.
Display coordinates are the final coordinates used for plotting.

This layered model allows the package to support:

- reversed axes
- rescaled axes
- nonlinear transformations
- binned or discretized layouts
- custom display conventions such as geological timescales

Binning and interval schemes

A useful extension is support for named intervals or bins along the primary axis.
Geological timescales are the motivating example, but the abstraction should be more general.

This would allow users to place visual elements by interval key rather than always specifying raw coordinates.
It would also support visual grammars in which annotations, backgrounds, or overlays are attached to regions of the axis rather than to exact numeric positions.
It would also support an interval-based visual grammar in which backgrounds, overlays, annotations, and region-scoped encodings are attached to axis intervals rather than to exact point locations.

Once secondary or tertiary axes are introduced, these intervals naturally induce cells or blocks in a higher-dimensional coordinate lattice.
In 2D, such intervals naturally correspond to span-like regions on an axis.
That opens the door to heatmap-like or panel-like encodings indexed by lineage position and auxiliary dimensions.
More generally, with additional transverse dimensions inducing cells or blocks in a higher-dimensional coordinate lattice,
the cells could serve as addressable regions for placing or rendering visual layers such as fills, bands, glyph collections, text annotations, heatmap-like values, or other plot objects, with configurable anchors and bounding regions.

Non-tree lineage structures

The package should support, or be designed to admit, lineage structures that are not strictly trees, including reticulate and network-like processes such as migration, hybridization, introgression, recombination, and lateral gene transfer.

These structures introduce edges or correspondences that connect distinct lineage paths across the primary lineage axis and across transverse dimensions.
This requires explicit handling of cross-lineage intersections, non-parental adjacency relations, and visual rules for rendering reticulate connections without conflating them with ordinary ancestor-descendant branches.

The core `LineageAxis` abstraction remains valid in this setting, but the surrounding geometry and topology are no longer purely tree-like.
Accordingly, the package should distinguish between:

- lineage-progressing edges, which follow the primary process axis
- reticulation or transfer edges, which connect otherwise distinct lineage trajectories
- layout-induced intersections, which are visual artifacts
- semantic intersections, which represent actual modeled relationships


Layout mappings and external coordinate systems

The package should support layouts in which lineage objects are mapped into external coordinate systems that are not determined purely by tree structure.

Examples include:

- mapping tips to geographic coordinates
- embedding nodes or branches in morphospace
- projecting clades into ecological or trait space
- constraining subsets of nodes to user-specified locations

In such layouts, the primary lineage axis still governs process progression, but one or more transverse dimensions may be determined by external data rather than by layout heuristics alone.
This introduces additional constraints on routing, spacing, collision handling, and annotation placement.

Core scope
- `LineageAxis`
- coordinate semantics
- polarity/orientation separation
- 2D and 3D lineage embeddings

Extended scope
- reticulate/network lineage structures
- external-coordinate-constrained layouts
- interval schemas and domain overlays
- rich branch geometry and cross-sections

Design implications

The PRD should make the following requirements explicit.

1. `LineageAxis` is a semantic axis abstraction, not merely a plotting convenience.

2. The package must separate:
   - process order
   - semantic time interpretation
   - coordinate polarity
   - screen orientation

3. The primary axis must support both order-preserving and order-reversing relationships to real-world time.

4. The axis domain must support both metric and ordinal data.

5. Secondary dimensions must support both layout coordinates and additional visual encodings attached to branches and nodes.

6. The abstraction must generalize beyond planar trees to higher-dimensional embedded lineage objects.

7. The axis system must support user-defined coordinate transformations and interval schemas.

Possible API vocabulary

You may want the PRD to standardize a small vocabulary early so the implementation does not drift.

Recommended terms:

- lineage axis: the primary process axis
- process coordinate: the native index of the model
- axis polarity: whether increasing axis values are interpreted as forward or backward with respect to some semantic reference
- display polarity: whether increasing axis values map to increasing or decreasing plotting coordinates
- embedding orientation: left-to-right, right-to-left, bottom-to-top, radial, etc.
- transverse dimension: any dimension orthogonal or auxiliary to the lineage axis
- interval schema: named bins or ranges defined on the axis


`LineageAxis` represents the ordered one-dimensional parameterization of a branching or merging process.
It is independent of screen orientation and independent of whether the process is interpreted in forward time or backward time.
It supports arbitrary scalar or ordinal domains, reversible and transformed coordinate mappings, auxiliary transverse dimensions for layout and visual encodings, and generalization to higher-dimensional embeddings of lineage objects.


A rendered lineage object is determined by coordinates in the product of:

$$
\text{LineageIndex} \times \text{TransverseSpace}_1 \times \cdots \times \text{TransverseSpace}_k
$$

where:

- $k = 0$ gives a one-dimensional abstract cladogram-like parameterization
- $k = 1$ gives ordinary 2D layouts
- $k = 2$ gives ordinary 3D layouts
- larger $k$ gives embeddings into general ambient spaces

