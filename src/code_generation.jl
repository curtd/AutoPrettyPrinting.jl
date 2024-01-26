function generate_base_show_expr(typename, mime_sym; _sourceinfo=nothing)
    body = Expr(:block)
    !isnothing(_sourceinfo) && push!(body.args, _sourceinfo)
    push!(body.args, :($AutoPrettyPrinting.pprint(io, mime, o)))

    return :($Base.show(io::IO, mime::MIME{$(mime_sym)}, o::$typename) = $body)
end

function per_property_pprint_exprs(f_exprs, properties, typename; mime_types::Vector{Symbol}, generate_base_show::Bool, typename_str=typename isa Type ? string(nameof(typename)) : string(typename), vert_layout_rpad::Int=0)
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
            value_compact_horiz = :($custom_tile_horiz($Base.getproperty(o, $(property)), mime; kwargs...) )
            value_compact_vert = :($custom_tile($Base.getproperty(o, $(property)), mime; kwargs...) )
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
    parentheses = isempty(typename_str) ? empty_parentheses : dict_parentheses

    output = Expr(:block)
    for mime_type in mime_types 
        mime_q = QuoteNode(mime_type)
        push!(output.args, quote 
            function $AutoPrettyPrinting.custom_tile_horiz(o::$typename, mime::$Base.MIME{$mime_q}; kwargs...)
                prefix = $PPRINT_SHOW_TYPENAME[] ? $(typename_str) : ""
                return $AutoPrettyPrinting.@pprint_values parent_is_container=false next_level=true show_typename=true begin
                    $layout_horizontal
                    $list_layout_prefer_horizontal($object_list_compact_expr; prefix, parentheses=$parentheses, allow_horiz=true, allow_vert=false, kwargs...)
                end
            end
            function $AutoPrettyPrinting.custom_tile_vert(o::$typename, mime::$Base.MIME{$mime_q}; kwargs...)
                prefix = $PPRINT_SHOW_TYPENAME[] ? $(typename_str) : ""
                return $AutoPrettyPrinting.@pprint_values parent_is_container=false next_level=true show_typename=true begin
                    $layout_aligned_vertical
                    $list_layout_prefer_horizontal($object_list_aligned_expr; prefix, parentheses=$parentheses, allow_horiz=false, allow_vert=true, kwargs...)
                end
            end
            $AutoPrettyPrinting.custom_tile(o::$typename, mime::$Base.MIME{$mime_q}; kwargs...) = $custom_tile_horiz_or_vert(o, mime; kwargs...)
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

per_property_pprint_exprs(properties, typename; kwargs...) = per_property_pprint_exprs((propertyname)->nothing, properties, typename; kwargs...)

