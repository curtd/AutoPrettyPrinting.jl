const default_custom_tile_expr = (propertyname)->nothing

function generate_base_show_expr(typename, mime_sym; _sourceinfo=nothing)
    body = Expr(:block)
    !isnothing(_sourceinfo) && push!(body.args, _sourceinfo)
    push!(body.args, :($AutoPrettyPrinting.pprint(io, mime, o)))

    return :($Base.show(io::IO, mime::MIME{$(mime_sym)}, o::$typename) = $body)
end

function _per_property_pprint_exprs(f_exprs, properties; vert_layout_rpad::Int=0, input_obj::Symbol)
    max_property_length = maximum(textwidth.(string.(properties)))+max(vert_layout_rpad, 0)
    
    layout_horizontal = Expr(:block)
    layout_aligned_vertical = Expr(:block)
    
    object_list_compact_expr = Expr(:vect)
    object_list_aligned_expr = Expr(:vect)
    for _property in properties
        property = QuoteNode(_property)
        property_kv = Symbol(_property, :_kv)
        property_kv_aligned = Symbol(_property, :_kv_aligned)

        y = f_exprs(_property)
        if isnothing(y)
            value_compact_horiz = :($custom_tile_horiz($Base.getproperty($input_obj, $(property)), mime; kwargs...) )
            value_compact_vert = :($custom_tile($Base.getproperty($input_obj, $(property)), mime; kwargs...) )
        elseif length(y) == 2 
            value_compact_horiz, value_compact_vert = y
        else
            error("Invalid custom expression $y -- must return a 2-length iterator")
        end

        push!(layout_horizontal.args, :($(property_kv) = $custom_tile_horiz($KeyValue($(property), $value_compact_horiz), mime; kwargs...)))

        push!(object_list_compact_expr.args, property_kv)
     
        push!(layout_aligned_vertical.args, :($(property_kv_aligned) = $_custom_tile_padded_key($property, $kv_separator_vert($KeyValue), $value_compact_vert, $max_property_length)))

        push!(object_list_aligned_expr.args, property_kv_aligned)
    end
    return (; horizontal=(layout_horizontal, object_list_compact_expr), vertical=(layout_aligned_vertical, object_list_aligned_expr))
end

function custom_tile_horiz_or_vert_body_expr(layout_expr, object_list; prefix="", parentheses, is_horiz::Bool, _sourceinfo=nothing)
    return Expr(:block, :(prefix = $PPRINT_SHOW_TYPENAME[] ? $(prefix) : ""), :( $AutoPrettyPrinting.@pprint_values parent_is_container=false next_level=true show_typename=true begin
        $(something(_sourceinfo, :()))
        $layout_expr
        $list_layout_prefer_horizontal($object_list; prefix, parentheses=$parentheses, allow_horiz=$(is_horiz), allow_vert=$(!is_horiz), kwargs...)
    end ))
end

function per_property_pprint_exprs(f_exprs, properties, typename; mime_types::Vector{Symbol}, generate_base_show::Bool, typename_str=typename isa Type ? string(nameof(typename)) : string(typename), vert_layout_rpad::Int=0, _sourceinfo=nothing)
    input_obj = :obj
    (; horizontal, vertical) = _per_property_pprint_exprs(f_exprs, properties; vert_layout_rpad, input_obj)
    layout_horizontal, object_list_compact_expr = horizontal
    layout_vertical, object_list_vert_expr = vertical
    parentheses = isempty(typename_str) ? empty_parentheses : dict_parentheses

    output = Expr(:block)
    for mime_type in mime_types 
        mime_q = QuoteNode(mime_type)
        push!(output.args, quote 
            function $AutoPrettyPrinting.custom_tile_horiz($input_obj::$typename, mime::$Base.MIME{$mime_q}; kwargs...)
                return $(custom_tile_horiz_or_vert_body_expr(layout_horizontal, object_list_compact_expr; prefix=typename_str, parentheses, _sourceinfo, is_horiz=true))
            end
            function $AutoPrettyPrinting.custom_tile_vert($input_obj::$typename, mime::$Base.MIME{$mime_q}; kwargs...)
                return $(custom_tile_horiz_or_vert_body_expr(layout_vertical, object_list_vert_expr; prefix=typename_str, parentheses, _sourceinfo,is_horiz=false))
            end
            $AutoPrettyPrinting.custom_tile($input_obj::$typename, mime::$Base.MIME{$mime_q}; kwargs...) = $custom_tile_horiz_or_vert($input_obj, mime; kwargs...)
        end)
    end
    if generate_base_show
        show_expr = Expr(:block)
        for mime_type in mime_types
            push!(show_expr.args, generate_base_show_expr(typename, QuoteNode(mime_type)))
        end
        push!(output.args, show_expr)
      
    end
    return output
end

per_property_pprint_exprs(properties, typename; kwargs...) = per_property_pprint_exprs(default_custom_tile_expr, properties, typename; kwargs...)


@generated function custom_tile_horiz(x::NamedTuple{T}, mime::MIME; kwargs...) where {T}
    (; horizontal) = _per_property_pprint_exprs(default_custom_tile_expr, fieldnames(x); input_obj=:x)
    layout, object_list_expr = horizontal
    return custom_tile_horiz_or_vert_body_expr(layout, object_list_expr; prefix="", parentheses=named_tuple_parentheses, is_horiz=true)
end


@generated function custom_tile_vert(x::NamedTuple{T}, mime::MIME; kwargs...) where {T}
    (; vertical) = _per_property_pprint_exprs(default_custom_tile_expr, fieldnames(x); input_obj=:x)
    layout, object_list_expr = vertical
    return custom_tile_horiz_or_vert_body_expr(layout, object_list_expr; prefix="", parentheses=named_tuple_parentheses, is_horiz=false)
end

custom_tile(x::NamedTuple, mime::MIME; kwargs...) = custom_tile_horiz_or_vert(x, mime; kwargs...)