module LineagesMakie

include("Accessors.jl")
using .Accessors: LineageGraphAccessor, lineagegraph_accessor, abstracttrees_accessor, is_leaf, leaves, preorder
export LineageGraphAccessor, lineagegraph_accessor, abstracttrees_accessor, is_leaf, leaves, preorder

include("Geometry.jl")
using .Geometry: LineageGraphGeometry, boundingbox, rectangular_layout
export LineageGraphGeometry, boundingbox, rectangular_layout

include("CoordTransform.jl")
include("Layers.jl")
include("LineageAxis.jl")

end
