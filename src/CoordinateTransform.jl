module CoordinateTransform

# Coordinate conversion approach:
# data_to_pixel uses Makie.project(scene, point) from
#   Makie/src/camera/projection_math.jl:461–472, which applies
#   scene.camera.projectionview[] and viewport(scene)[] to transform a
#   data-space point into pixel coordinates (origin at bottom-left of the scene
#   viewport, y increasing upward).
# pixel_to_data uses Makie.to_world(scene, point) from
#   Makie/src/camera/projection_math.jl:326–339, which is the inverse.
# register_pixel_projection! follows the pattern established in
#   GraphMakie.jl/src/recipes.jl:226–234:
#   add_input! registers viewport and projectionview as ComputeGraph inputs;
#   map! creates a derived :pixel_projection computation cell as a reactive closure.

using Makie: Scene, Point2f, Vec2f, project, to_world, add_input!, viewport, widths

# ── data_to_pixel ─────────────────────────────────────────────────────────────

"""
    data_to_pixel(scene::Makie.Scene, point::Point2f) -> Point2f

Convert `point` from data coordinates to pixel (screen) coordinates using the
current camera matrices of `scene`.

Pixel coordinates have their origin at the bottom-left of the scene viewport,
with x increasing rightward and y increasing upward. This is the coordinate
space used internally by Makie for marker sizes, label offsets, and other
fixed-screen-size elements.

Implemented via `Makie.project(scene, point)`, confirmed from
`Makie/src/camera/projection_math.jl:461–472`.

Non-isotropic axes (where x and y data scales differ) are handled correctly
because the projection uses the scene's full camera matrix, not an assumed
uniform scale.

# Arguments
- `scene::Makie.Scene`: the scene whose camera and viewport define the
  coordinate mapping.
- `point::Point2f`: a point in data space.

# Returns
`Point2f` in pixel space relative to the scene viewport's bottom-left corner.

# Throws
Emits `@warn` if either dimension of the scene viewport is zero (degenerate
viewport) and returns `point` unchanged as an identity-transform fallback.
"""
function data_to_pixel(scene::Scene, point::Point2f)::Point2f
    vp = viewport(scene)[]
    w, h = widths(vp)
    if iszero(w) || iszero(h)
        @warn "degenerate viewport (width=$(Int(w)), height=$(Int(h))); " *
            "returning identity transform for data_to_pixel"
        return point
    end
    return Point2f(project(scene, point))
end

# ── pixel_to_data ─────────────────────────────────────────────────────────────

"""
    pixel_to_data(scene::Makie.Scene, point::Point2f) -> Point2f

Convert `point` from pixel (screen) coordinates to data coordinates using the
inverse of the current camera matrices of `scene`.

This is the exact inverse of `data_to_pixel`. For a 2D orthographic projection,
the two functions are mutually inverse up to floating-point precision.

Implemented via `Makie.to_world(scene, point)`, confirmed from
`Makie/src/camera/projection_math.jl:326–339`.

# Arguments
- `scene::Makie.Scene`: the scene whose camera and viewport define the
  coordinate mapping.
- `point::Point2f`: a point in pixel space (bottom-left origin).

# Returns
`Point2f` in data space.

# Throws
Emits `@warn` if either dimension of the scene viewport is zero and returns
`point` unchanged as an identity-transform fallback.
"""
function pixel_to_data(scene::Scene, point::Point2f)::Point2f
    vp = viewport(scene)[]
    w, h = widths(vp)
    if iszero(w) || iszero(h)
        @warn "degenerate viewport (width=$(Int(w)), height=$(Int(h))); " *
            "returning identity transform for pixel_to_data"
        return point
    end
    return Point2f(to_world(scene, point))
end

# ── pixel_offset_to_data_delta ────────────────────────────────────────────────

"""
    pixel_offset_to_data_delta(scene::Makie.Scene, data_point::Point2f,
                               pixel_offset::Vec2f) -> Vec2f

Return the data-space displacement that corresponds to applying `pixel_offset`
(in pixel coordinates) at `data_point` (in data coordinates).

For a 2D orthographic projection this is a spatially constant linear map, but
x and y components differ for non-isotropic axes where the x and y data scales
are unequal. This function is therefore the correct way to compute, for example,
a fixed-pixel label offset in data units — `markerspace = :pixel` in Makie is
the rendering counterpart.

Computed as:
    pixel_to_data(scene, data_to_pixel(scene, data_point) + pixel_offset) - data_point

# Arguments
- `scene::Makie.Scene`: the scene whose camera and viewport define the
  coordinate mapping.
- `data_point::Point2f`: the anchor point in data space.
- `pixel_offset::Vec2f`: the desired offset in pixel coordinates.

# Returns
`Vec2f` giving the equivalent displacement in data space.

# Throws
Emits `@warn` if either dimension of the scene viewport is zero and returns
`pixel_offset` unchanged as a fallback.
"""
function pixel_offset_to_data_delta(
        scene::Scene,
        data_point::Point2f,
        pixel_offset::Vec2f,
    )::Vec2f
    vp = viewport(scene)[]
    w, h = widths(vp)
    if iszero(w) || iszero(h)
        @warn "degenerate viewport (width=$(Int(w)), height=$(Int(h))); " *
            "returning pixel_offset as fallback for pixel_offset_to_data_delta"
        return pixel_offset
    end
    px_base = Point2f(project(scene, data_point))
    data_shifted = Point2f(to_world(scene, px_base + pixel_offset))
    return data_shifted - data_point
end

# ── register_pixel_projection! ────────────────────────────────────────────────

"""
    register_pixel_projection!(plot_attrs, scene::Makie.Scene) -> Nothing

Register `scene.viewport` and `scene.camera.projectionview` as reactive inputs
in the Makie `ComputeGraph` `plot_attrs`, and create a derived `:pixel_projection`
computation cell holding a closure `(Point2f) -> Point2f` for converting data
coordinates to pixel coordinates.

When `scene.viewport` changes (e.g., on window resize or figure layout change),
the `:pixel_projection` computation cell and any downstream `map!` computations that depend
on it are automatically marked for recomputation. This is the correct way to make
fixed-screen-size elements (markers, label offsets, padding) respond to resize
events.

Pattern follows `GraphMakie.jl/src/recipes.jl:226–234`:
`add_input!(plot_attrs, :viewport, scene.viewport)` and
`add_input!(plot_attrs, :projectionview, scene.camera.projectionview)` register
the reactive observables; `map!` creates the derived computation cell.

Typical usage inside a Makie `@recipe` plot function:

```julia
sc = Makie.parent_scene(plot)
register_pixel_projection!(plot.attributes, sc)
map!(plot.attributes, [:pixel_projection, :some_data], :pixel_positions) do to_px, data
    [to_px(p) for p in data]
end
```

# Arguments
- `plot_attrs`: a Makie `ComputeGraph` — typically a recipe's `plot.attributes`.
- `scene::Makie.Scene`: the scene whose viewport drives the reactive updates.

# Returns
`nothing`.
"""
function register_pixel_projection!(plot_attrs, scene::Scene)::Nothing
    # Guard against double-registration: Makie plots (e.g. scatter!) already
    # register :viewport and :projectionview via register_camera! in
    # Makie/src/camera/camera.jl:352, adding them as Computed nodes (not plain
    # inputs), so they appear in attr.outputs but NOT attr.inputs. Use
    # haskey(plot_attrs, key) which resolves to haskey(attr.outputs, key) so
    # both registration paths are correctly detected.
    haskey(plot_attrs, :viewport) ||
        add_input!(plot_attrs, :viewport, scene.viewport)
    haskey(plot_attrs, :projectionview) ||
        add_input!(plot_attrs, :projectionview, scene.camera.projectionview)
    map!(plot_attrs, [:viewport, :projectionview], :pixel_projection) do _vp, _pv
        (point::Point2f) -> data_to_pixel(scene, point)
    end
    return nothing
end

# ── Exports ───────────────────────────────────────────────────────────────────

export data_to_pixel, pixel_to_data, pixel_offset_to_data_delta, register_pixel_projection!

end # module CoordinateTransform
