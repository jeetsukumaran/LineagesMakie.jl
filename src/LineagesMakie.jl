module LineagesMakie

include("Accessors.jl")
using .Accessors: TreeAccessor, tree_accessor, abstracttrees_accessor, is_leaf, leaves, preorder
export TreeAccessor, tree_accessor, abstracttrees_accessor, is_leaf, leaves, preorder

include("Geometry.jl")
using .Geometry: TreeGeometry, boundingbox, rectangular_layout
export TreeGeometry, boundingbox, rectangular_layout

include("CoordTransform.jl")
include("Layers.jl")
include("LineageAxis.jl")

end
