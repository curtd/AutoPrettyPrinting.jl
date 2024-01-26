const mime_types_docstr = "`mime_types=nothing`: The `MIME` types to generate. Either a `String`, a `vect` expression of `String`s, or `nothing`, which will use the package defaults."

const base_show_docstr = "`base_show::Bool=false`: If `true`, will define `Base.show(io::IO, ::MIME(mime), ::T)` for each `mime` in `mime_types`"

"""
    @custom_tile [mime_types=nothing] [base_show=false] T => custom_tile_expr

Defines a `AutoPrettyPrinting.custom_tile` method for type `T` and optionally provided `mime_types` using `custom_tile_expr` as the function's body. 

# Arguments 
- $mime_types_docstr
- $base_show_docstr
- `custom_tile_expr`: Expression to be used for the body of the `custom_tile` method. Each expression should use a `_obj_` placeholder to indicate the object of type `T` and a `_mime_` placeholder to indicate the mime type. 
"""
macro custom_tile(args...)
    length(args) ≥ 1 || error("Need at least one argument for @custom_tile")
    @parse_kwargs args[1:end-1]... begin 
        base_show::Bool = false 
        mime_types::Union{Vector{String}, Nothing} = nothing
    end
    if isnothing(mime_types)
        mime_types = mime_types_to_generate()
    else 
        mime_types = Symbol.(unique(mime_types))
    end
    expr = args[end]
    f = from_expr(PairExpr{Any, Any}, expr; throw_error=true)
    typename = f.lhs
    custom_tile_expr = f.rhs

    object_arg = :_obj_
    mime_arg = :_mime_
   
    _sourceinfo = __source__
    output = Expr(:block, _sourceinfo)
    for mime_type in mime_types 
        mime_q = QuoteNode(mime_type)
        body = Expr(:block, _sourceinfo, custom_tile_expr)
        push!(output.args, :($AutoPrettyPrinting.custom_tile($(object_arg)::$(typename), $(mime_arg)::MIME{$mime_q}; kwargs...) = $(body)))
        if base_show
            push!(output.args, generate_base_show_expr(typename, mime_q; _sourceinfo))
        end
    end
    return output |> esc
end

function def_pprint_expr(type, _mod; properties::Union{Vector{Symbol}, Nothing}, mime_types::Vector{Symbol}, generate_base_show::Bool)
    return Base.remove_linenums!(quote 
        let 
            local _properties = $(isnothing(properties) ? :($Base.fieldnames($type)) : Expr(:tuple, QuoteNode.(properties)...))
            local expr = $per_property_pprint_exprs(_properties, $type; generate_base_show=$generate_base_show, mime_types=$(Expr(:vect, QuoteNode.(mime_types)...)))
            $Core.eval($_mod, expr)
        end
    end)
end

"""
    @def_pprint [properties=nothing] [mime_types=nothing] [base_show=false] T

Auto generates pretty printing methods for type `T` and optionally provided `mime_types`. 

# Arguments 
- `properties=nothing`: Either a `Symbol` or a `vect` expression of `Symbol`s corresponding to the properties to use from `x::T`. Will default to using the fieldnames of `x` if unspecified
- $mime_types_docstr
- $base_show_docstr
"""
macro def_pprint(args...)
    length(args) ≥ 1 || error("Need at least one argument for @def_pprint")
    @parse_kwargs args[1:end-1]... begin 
        base_show::Bool = false 
        properties::Union{Vector{Symbol}, Nothing} = nothing
        mime_types::Union{Vector{String}, Nothing} = nothing
    end
    if isnothing(mime_types)
        mime_types = collect(mime_types_to_generate())
    else 
        mime_types = Symbol.(unique(mime_types))
    end
    type = args[end]
    _sourceinfo = __source__
    return Expr(:block, _sourceinfo, def_pprint_expr(type, __module__; mime_types, generate_base_show=base_show, properties)) |> esc
end

"""
    @def_pprint_atomic [to_string=nothing] [mime_types=nothing] T 

Registers type `T` as an atomic type (i.e., one with no subfields nor subelements) and defines `custom_tile(x::T, mime::MIME{S}) = to_string(x)` for each `mime` type. 

# Arguments 
- `to_string=nothing`: Function expression that returns the string representation of `x`. Defaults to `Base.string` if not provided.
- $mime_types_docstr
- `all_mime_types::Bool=false`: If `true`, ignores any provided `mime_types` and defines `custom_tile(x::T, mime::MIME)` for a generic `MIME` input
"""
macro def_pprint_atomic(args...)
    length(args) ≥ 1 || error("Need at least one argument for @atomic_type")
    @parse_kwargs args[1:end-1]... begin 
        to_string::Union{Symbol, Expr, Nothing} = nothing
        mime_types::Union{Vector{String}, Nothing} = nothing
        all_mime_types::Bool = false
    end
    if isnothing(to_string)
        to_string = :((x,)->$Base.string(x))
    end
    x = gensym(:x)
    f = from_expr(FuncDef, to_string; throw_error=true)
    length(f.args) != 1 && throw(@arg_error to_string "`to_string` must have exactly one argument")
    arg_name = only(f.args).name
    to_string_expr, _ = replace_symbols(f.body, [arg_name => x])
    
    T = esc(args[end])
    if all_mime_types
        custom_tile_exprs = [:($AutoPrettyPrinting.custom_tile($x::$T, ::MIME; kwargs...) = $literal($to_string_expr))]
    else
        if isnothing(mime_types)
            mime_types = collect(mime_types_to_generate())
        else 
            mime_types = Symbol.(unique(mime_types))
        end
        custom_tile_exprs = [:($AutoPrettyPrinting.custom_tile($x::$T, ::MIME{$(QuoteNode(m))}; kwargs...) = $literal($to_string_expr)) for m in mime_types]
    end
    
    return Expr(:block, __source__, :($AutoPrettyPrinting._is_atomic_type(::Type{<:$T}) = true), custom_tile_exprs...)
end


for T in (:(AbstractString), :(Real), :Bool, :(Vector{UInt8}))
    @eval begin
        @def_pprint_atomic all_mime_types=true $T
    end
end

for T in (:(Period), :(Instant), :(TimeType))
    @eval begin 
        @def_pprint_atomic all_mime_types=true $Dates.$T
    end
end

for T in (:IPv4, :IPv6)
    @eval @def_pprint_atomic all_mime_types=true Sockets.$T 
end