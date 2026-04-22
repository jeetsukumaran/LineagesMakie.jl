module LineagesMakie

include("Accessors.jl")
using .Accessors: LineageGraphAccessor, lineagegraph_accessor, abstracttrees_accessor, is_leaf, leaves, preorder
export LineageGraphAccessor, lineagegraph_accessor, abstracttrees_accessor, is_leaf, leaves, preorder

include("Geometry.jl")
using .Geometry: LineageGraphGeometry, boundingbox, rectangular_layout, circular_layout
export LineageGraphGeometry, boundingbox, rectangular_layout, circular_layout

include("CoordTransform.jl")
using .CoordTransform:
    data_to_pixel, pixel_to_data, pixel_offset_to_data_delta, register_pixel_projection!
export data_to_pixel, pixel_to_data, pixel_offset_to_data_delta, register_pixel_projection!

include("Layers.jl")
using .Layers:
    LineagePlot,
    lineageplot!,
    EdgeLayer,
    edgelayer!,
    VertexLayer,
    vertexlayer!,
    LeafLayer,
    leaflayer!,
    LeafLabelLayer,
    leaflabellayer!,
    VertexLabelLayer,
    vertexlabellayer!,
    CladeHighlightLayer,
    cladehighlightlayer!,
    CladeLabelLayer,
    cladelabellayer!,
    ScaleBarLayer,
    scalebarlayer!
export LineagePlot,
    lineageplot!,
    EdgeLayer,
    edgelayer!,
    VertexLayer,
    vertexlayer!,
    LeafLayer,
    leaflayer!,
    LeafLabelLayer,
    leaflabellayer!,
    VertexLabelLayer,
    vertexlabellayer!,
    CladeHighlightLayer,
    cladehighlightlayer!,
    CladeLabelLayer,
    cladelabellayer!,
    ScaleBarLayer,
    scalebarlayer!

# LineageAxis.jl is a plain include (not a submodule): Makie.@Block generates
# esc(q) that references Makie internals by unqualified name, so everything must
# be in the including module's scope. LineageAxis (type) is auto-exported by
# the @Block macro; reset_limits! is exported manually below.
include("LineageAxis.jl")
export reset_limits!

end
