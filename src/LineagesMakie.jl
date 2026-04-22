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
    scalebarlayer!,
    lineageplot!
export EdgeLayer,
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
    scalebarlayer!,
    lineageplot!

include("LineageAxis.jl")

end
