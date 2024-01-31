"""
    GenericMimeType

Indicates that code generation should use the unparametrized type `MIME` instead of a particular parametric instance `MIME{S}`
"""
struct GenericMimeType 
end

const mime_text_plain_type_expr = :(MIME"text/plain")
const default_custom_tile_expr = (propertyname)->nothing

const generic_mime_type_expr = :($Base.MIME)

mime_type_exprs(::GenericMimeType; add_text_plain::Bool=false) = add_text_plain ? Any[generic_mime_type_expr, mime_text_plain_type_expr] : Any[generic_mime_type_expr]
mime_type_exprs(mime_types::Vector{Symbol}; kwargs...) = Any[:($Base.MIME{$(QuoteNode(mime_t))}) for mime_t in mime_types]

function generate_base_show_expr(typename, mime_type; _sourceinfo::Union{LineNumberNode, Nothing}=nothing)
    body = Expr(:block)
    !isnothing(_sourceinfo) && push!(body.args, _sourceinfo)
    push!(body.args, :($AutoPrettyPrinting.pprint(io, mime, o)))

    return Expr(:block, _sourceinfo, Expr(:(=), :($Base.show(io::IO, mime::$(mime_type), o::$typename)), body))
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

function custom_tile_horiz_or_vert_body_expr(layout_expr, object_list; prefix="", parentheses, is_horiz::Bool, _sourceinfo::Union{LineNumberNode, Nothing}=nothing)
    return Expr(:block, something(_sourceinfo, :()), :(prefix = $PPRINT_SHOW_TYPENAME[] ? $(prefix) : ""), pprint_values_expr(Expr(:block, layout_expr, :($list_layout_prefer_horizontal($object_list; prefix, parentheses=$parentheses, allow_horiz=$is_horiz, allow_vert=$(!is_horiz), kwargs...))); parent_is_container=true, next_level=true, show_typename=true, _sourceinfo=something(_sourceinfo, not_provided)))
end

function default_custom_tile_def_expr(typename, mime_type, input_obj=:_obj_, input_mime=:_mime_; _sourceinfo::Union{LineNumberNode, Nothing}=nothing)
    body = Expr(:block) 
    if !isnothing(_sourceinfo)
        push!(body.args, _sourceinfo)
    end
    push!(body.args, :($custom_tile_horiz_or_vert($input_obj, $input_mime; kwargs...)))
    return Expr(:(=), :($AutoPrettyPrinting.custom_tile($input_obj::$typename, $input_mime::$mime_type; kwargs...)), body)
end

"""
    per_property_pprint_exprs([f_exprs], properties, typename; mime_types, generate_base_show, [typename_str], [vert_layout_rpad], [_sourceinfo], [add_text_plain::Bool])

Returns an expression providing default `custom_tile_horiz`, `custom_tile_vert`, and `custom_tile` definitions for type `typename` involving a list of `properties`. 

If provided, `f_exprs` must be a single-argument function which takes an argument `property_name::Symbol` and returns either a 2-tuple `(horizontal_expr, vertical_expr)` of the horizontal + vertical expressions, respectively, to use for that particular property, or `nothing` if the default expressions are to be used.

# Arguments 
- `mime_types::Union{Vector{Symbol}, GenericMimeType}`: List of `MIME` parameter `Symbol`s to generate. If a `GenericMimeType` is provided, will use an unparametrized `MIME` type. 
- `generate_base_show::Bool`: If `true`, will define the corresponding `Base.show` method for `typename` using this package's `pprint`
- `typename_str::String = string(typename)`: The generated code uses this string for the typename, if provided 
- `vert_layout_rpad::Int = 0`: Right-pads the aligned vertical layout keys by this amount
- `_sourceinfo::Union{LineNumberNode, Nothing} = nothing`: If provided, uses this line information when generating methods
- `add_text_plain::Bool = true`: If `mime_types` is a `GenericMimeType`, adds the `MIME"text/plain"` type to the list of generated mime types. Otherwise, this argument is ignored.
"""
function per_property_pprint_exprs(f_exprs, properties, typename; mime_types::Union{Vector{Symbol}, GenericMimeType}, generate_base_show::Bool, typename_str=typename isa Type ? string(nameof(typename)) : string(typename), vert_layout_rpad::Int=0, _sourceinfo::Union{LineNumberNode, Nothing}=nothing, add_text_plain::Bool=true)
    @nospecialize

    input_obj = :obj
    (; horizontal, vertical) = _per_property_pprint_exprs(f_exprs, properties; vert_layout_rpad, input_obj)
    layout_horizontal, object_list_compact_expr = horizontal
    layout_vertical, object_list_vert_expr = vertical
    parentheses = isempty(typename_str) ? empty_parentheses : dict_parentheses

    output = Expr(:block)
    _mime_types = mime_type_exprs(mime_types; add_text_plain)
    for mime_type in _mime_types 
        push!(output.args, Expr(:block, 
            Expr(:(=), :($AutoPrettyPrinting.custom_tile_horiz($input_obj::$typename, mime::$mime_type; kwargs...)), custom_tile_horiz_or_vert_body_expr(layout_horizontal, object_list_compact_expr; prefix=typename_str, parentheses, _sourceinfo, is_horiz=true)), 
            Expr(:(=), :($AutoPrettyPrinting.custom_tile_vert($input_obj::$typename, mime::$mime_type; kwargs...)), custom_tile_horiz_or_vert_body_expr(layout_vertical, object_list_vert_expr; prefix=typename_str, parentheses, _sourceinfo, is_horiz=false)), 
            default_custom_tile_def_expr(typename, mime_type, input_obj; _sourceinfo)))
    end
    if generate_base_show
        show_expr = Expr(:block)
        for mime_type in _mime_types
            push!(show_expr.args, generate_base_show_expr(typename, mime_type; _sourceinfo))
        end
        push!(output.args, show_expr)
    end
    return output
end

per_property_pprint_exprs(properties, typename; kwargs...) = per_property_pprint_exprs(default_custom_tile_expr, properties, typename; kwargs...)


@generated function custom_tile_horiz(x::NamedTuple, mime::MIME; kwargs...)
    (; horizontal) = _per_property_pprint_exprs(default_custom_tile_expr, fieldnames(x); input_obj=:x)
    layout, object_list_expr = horizontal
    return custom_tile_horiz_or_vert_body_expr(layout, object_list_expr; prefix="", parentheses=named_tuple_parentheses, is_horiz=true)
end


@generated function custom_tile_vert(x::NamedTuple, mime::MIME; kwargs...)
    (; vertical) = _per_property_pprint_exprs(default_custom_tile_expr, fieldnames(x); input_obj=:x)
    layout, object_list_expr = vertical
    return custom_tile_horiz_or_vert_body_expr(layout, object_list_expr; prefix="", parentheses=named_tuple_parentheses, is_horiz=false)
end

custom_tile(x::NamedTuple, mime::MIME; kwargs...) = custom_tile_horiz_or_vert(x, mime; kwargs...)