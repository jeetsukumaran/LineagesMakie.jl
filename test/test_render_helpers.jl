function _rt_text_payload_strings(payload)::Vector{String}
    if payload isa AbstractVector
        return String[string(item) for item in payload]
    end
    return String[string(payload)]
end

function _rt_matching_text_plots(scene, expected_strings::Vector{String})
    return [
        plot for plot in scene.plots
        if plot isa CairoMakie.Makie.Text &&
           _rt_text_payload_strings(plot.text[]) == expected_strings
    ]
end

function _rt_only_text_plot(scene, expected_strings::Vector{String})
    return only(_rt_matching_text_plots(scene, expected_strings))
end

function _rt_rect2_ranges(rect)
    xmin = Float64(rect.origin[1])
    ymin = Float64(rect.origin[2])
    xmax = xmin + Float64(rect.widths[1])
    ymax = ymin + Float64(rect.widths[2])
    return (xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
end

function _rt_string_bbox_ranges(plot)::Vector
    plot.markerspace[] === :pixel || throw(
        ArgumentError(
            "expected text plot markerspace :pixel for render-level checks; got $(repr(plot.markerspace[]))",
        ),
    )
    return [_rt_rect2_ranges(rect) for rect in CairoMakie.Makie.string_boundingboxes(plot)]
end

function _rt_rects_overlap(a, b; atol::Float64 = 1.0e-3)::Bool
    overlap_x = min(a.xmax, b.xmax) - max(a.xmin, b.xmin) > atol
    overlap_y = min(a.ymax, b.ymax) - max(a.ymin, b.ymin) > atol
    return overlap_x && overlap_y
end

function _rt_rects_all_nonoverlapping(rects; atol::Float64 = 1.0e-3)::Bool
    for i in eachindex(rects)
        for j in (i + 1):length(rects)
            _rt_rects_overlap(rects[i], rects[j]; atol = atol) && return false
        end
    end
    return true
end

function _rt_rects_collections_disjoint(as, bs; atol::Float64 = 1.0e-3)::Bool
    for a in as, b in bs
        _rt_rects_overlap(a, b; atol = atol) && return false
    end
    return true
end

function _rt_rects_within_viewport(rects, scene; padding::Float64 = 0.0)::Bool
    vp = CairoMakie.Makie.viewport(scene)[]
    xmin = Float64(vp.origin[1]) + padding
    ymin = Float64(vp.origin[2]) + padding
    xmax = Float64(vp.origin[1] + vp.widths[1]) - padding
    ymax = Float64(vp.origin[2] + vp.widths[2]) - padding
    return all(rect -> begin
        rect.xmin >= xmin &&
        rect.ymin >= ymin &&
        rect.xmax <= xmax &&
        rect.ymax <= ymax
    end, rects)
end
