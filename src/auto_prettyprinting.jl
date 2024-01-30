const generic_mime_docstr = "`generic_mime::Bool=false`: If `true`, ignores `mime_types` input and use a generic (untemplated) MIME type for all code generation."
const mime_types_docstr = "`mime_types=nothing`: The `MIME` types to generate. If this value is the empty string, no mime types will be generated. If this value is a non-empty `String` or a `vect` or `tuple` expression of `String`s, these mime types will be used when generating code. Otherwise, if this value is `nothing`, the code generated will use the mime types previously registered with `@mime_type.`"

const base_show_docstr = "`base_show::Bool=false`: If `true`, will define `Base.show(io::IO, ::MIME(mime), ::T)` for each `mime` in `mime_types`"

_normalize_mime_type_args(::Nothing) = collect(mime_types_to_generate())
function _normalize_mime_type_args(mime_types::Vector{String}) 
    if length(mime_types) == 1 && only(mime_types) == ""
        return Symbol[]
    else
        return Symbol.(unique(mime_types))
    end
end
function normalize_mime_type_args(mime_types; generic_mime::Bool)
    if generic_mime
        return GenericMimeType()
    else
        return _normalize_mime_type_args(mime_types)
    end
end
function mime_from_type_expr(expr)
    if expr === :MIME 
        return GenericMimeType()
    elseif (g = from_expr(MacroCall, expr); !isnothing(g))
        g.name === Symbol("@MIME_str") || throw(@arg_error expr "Expected an expression of the form `MIME\"mime_type\"`")
        length(g.args) == 1 || throw(@arg_error expr "Expected expression to have a single argument")
        arg = only(g.args)
        arg isa String || throw(@arg_error expr "Expected expression to have a `String` argument, got typeof(arg) = $(typeof(arg))")
        return arg
    elseif (g = from_expr(CurlyExpr{:MIME, Any}, expr); !isnothing(g))
        length(g.args) == 1 || throw(@arg_error expr "Expected expression to have a single argument")
        arg = only(g.args)
        if arg isa QuoteNode
            return String(arg.value)
        elseif (f = from_expr(FuncCall, arg); !isnothing(f))
            (f.funcname ∉ (:(Symbol), :(Base.Symbol)) || length(f.args) != 1) && throw(@arg_error arg "Function call expression must be of the form `Symbol(str)`")
            f_arg = only(f.args).value
            if f_arg isa String 
                return f_arg
            elseif f_arg isa Symbol
                return string(f_arg)
            else
                throw(@arg_error arg "Function call expression must have a `String` or `QuoteNode` inner argument -- got typeof(arg) = $(typeof(f_arg))") 
            end
        else
            throw(@arg_error arg "Expression must be a `Symbol` or an expression of the form `Symbol(str)`")
        end
    else
        throw(@arg_error expr "Expression must be of the form `MIME`, `MIME\"str\"`, or `MIME{symbol_or_str}`")
    end
end

function custom_tile_func_def_expr(tile_expr, mime_types, generic_mime)
    object_arg = :_obj_
    mime_arg = :_mime_
    g = from_expr(FuncDef, tile_expr)
    object_arg = :_obj_
    mime_arg = :_mime_
    if !isnothing(g)
        length(g.args) == 2 || throw(@arg_error tile_expr "Must have exactly two arguments")
        arg1 = g.args[1]
        if is_provided(arg1.name)
            object_arg = arg1.name 
        end
        arg2 = g.args[2]
        if is_provided(arg2.name)
            mime_arg = arg2.name 
        end
        if is_provided(arg2.type)
            mime_type = mime_from_type_expr(arg2.type)
            if mime_type isa GenericMimeType
                generic_mime = true
            else
                mime_types = [mime_type]
            end
        end
        tile_expr = g.body
    end
    return object_arg, mime_arg, tile_expr, mime_types, generic_mime
end
function custom_tile_expr(typename, mime_type, tile_expr; _sourceinfo=nothing, generate_base_show::Bool, object_arg::Symbol, mime_arg::Symbol)
    output = Any[]
    body = Expr(:block, _sourceinfo, tile_expr)
    push!(output, :($AutoPrettyPrinting.custom_tile($(object_arg)::$(typename), $(mime_arg)::$(mime_type); kwargs...) = $(body)))
    append!(output, [:($AutoPrettyPrinting.$f($(object_arg)::$(typename), $(mime_arg)::$(mime_type); kwargs...) = $custom_tile($object_arg, $mime_arg; kwargs...)) for f in (:custom_tile_horiz, :custom_tile_vert)])
    if generate_base_show
        push!(output, generate_base_show_expr(typename, mime_type; _sourceinfo))
    end
    return output
end

"""
    @custom_tile [mime_types=nothing] [generic_mime=false] [base_show=false] T => custom_tile_expr

Defines a `AutoPrettyPrinting.custom_tile` method for type `T` and optionally provided `mime_types` using `custom_tile_expr` as the function's body. 

# Arguments 
- $mime_types_docstr
- $generic_mime_docstr
- $base_show_docstr
- `custom_tile_expr`: Expression to be used for the body of the `custom_tile` method. If this value is a `block` expression, it should contain a `_obj_` placeholder to indicate the object of type `T` and a `_mime_` placeholder to indicate the mime type. Otherwise, it can be a function definition expression of the form `(object, mime_type)->expr`.
"""
macro custom_tile(args...)
    length(args) ≥ 1 || error("Need at least one argument for @custom_tile")
    @parse_kwargs args[1:end-1]... begin 
        base_show::Bool = false 
        generic_mime::Bool = false
        mime_types::Union{Vector{String}, Nothing} = nothing
    end
    expr = args[end]
    f = from_expr(PairExpr{Any, Any}, expr; throw_error=true)
    typename = f.lhs
    object_arg, mime_arg, tile_expr, mime_types, generic_mime = custom_tile_func_def_expr(f.rhs, mime_types, generic_mime)
    mime_types = normalize_mime_type_args(mime_types; generic_mime)

    _sourceinfo = __source__
    output = Expr(:block, _sourceinfo)
    
    for mime_type in mime_type_exprs(mime_types) 
        append!(output.args, custom_tile_expr(typename, mime_type, tile_expr; _sourceinfo, generate_base_show=base_show, object_arg, mime_arg))
    end

    return output |> esc
end

function def_pprint_expr(type, _mod; properties::Union{Vector{Symbol}, Nothing}, mime_types::Union{Vector{Symbol}, GenericMimeType}, generate_base_show::Bool)
    mime_types_expr = mime_types isa GenericMimeType ? :($GenericMimeType()) : Expr(:vect, QuoteNode.(mime_types)...)
    return Base.remove_linenums!(quote 
        let 
            local _properties = $(isnothing(properties) ? :($Base.fieldnames($type)) : Expr(:tuple, QuoteNode.(properties)...))
            local expr = $per_property_pprint_exprs(_properties, $type; generate_base_show=$generate_base_show, mime_types=$(mime_types_expr))
            $Core.eval($_mod, expr)
        end
    end)
end

"""
    @def_pprint [properties=nothing] [mime_types=nothing] [generic_mime=false] [base_show=false] T

Auto generates pretty printing methods for type `T` and optionally provided `mime_types`. 

# Arguments 
- `properties=nothing`: Either a `Symbol` or a `vect` expression of `Symbol`s corresponding to the properties to use from `x::T`. Will default to using the fieldnames of `x` if unspecified
- $mime_types_docstr
- $generic_mime_docstr
- $base_show_docstr
"""
macro def_pprint(args...)
    length(args) ≥ 1 || error("Need at least one argument for @def_pprint")
    @parse_kwargs args[1:end-1]... begin 
        base_show::Bool = false 
        properties::Union{Vector{Symbol}, Nothing} = nothing
        mime_types::Union{Vector{String}, Nothing} = nothing
        generic_mime::Bool = false
    end
    mime_types = normalize_mime_type_args(mime_types; generic_mime)
    type = args[end]
    _sourceinfo = __source__
    return Expr(:block, _sourceinfo, def_pprint_expr(type, __module__; mime_types, generate_base_show=base_show, properties)) |> esc
end

"""
    @def_pprint_atomic [to_string=nothing] [mime_types=nothing] [generic_mime=false] T 

Registers type `T` as an atomic type (i.e., one with no subfields nor subelements) and defines `custom_tile(x::T, mime::MIME{S}) = to_string(x)` for each `mime` type. 

# Arguments 
- `to_string=nothing`: Function expression that returns the string representation of `x`. Defaults to `Base.string` if not provided.
- $mime_types_docstr
- $generic_mime_docstr
"""
macro def_pprint_atomic(args...)
    length(args) ≥ 1 || error("Need at least one argument for @atomic_type")
    @parse_kwargs args[1:end-1]... begin 
        to_string::Union{Symbol, Expr, Nothing} = nothing
        mime_types::Union{Vector{String}, Nothing} = nothing
        all_mime_types::Union{Nothing, Bool} = nothing
        generic_mime::Bool = false
    end
    if isnothing(to_string)
        to_string = :((x,)->$Base.string(x))
    end
    all_mime_types = something(all_mime_types, generic_mime)

    x = gensym(:x)
    f = from_expr(FuncDef, to_string; throw_error=true)
    length(f.args) != 1 && throw(@arg_error to_string "`to_string` must have exactly one argument")
    arg_name = only(f.args).name
    to_string_expr, _ = replace_symbols(f.body, [arg_name => x])
    
    T = esc(args[end])
    _mime_types = normalize_mime_type_args(mime_types; generic_mime)

    custom_tile_exprs = [:($AutoPrettyPrinting.custom_tile($x::$T, ::$mime_type; kwargs...) = $literal($to_string_expr)) for mime_type in mime_type_exprs(_mime_types)]
    
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

"""
    PPrintContext(io::IO, [mime::MIME])

Create a `PPrintContext` that wraps a given stream. 

Subsequent calls to `Base.show(context::PPrintContext, ::MIME, x)` will use the pretty printing machinery provided in this package to render `x`. This type is useful primarily when `x` has a `custom_tile` method defined (or provided by this package), but the primary `Base.show` methods are defined outside of this package and should not be overridden. 

Additionally, if a `mime::MIME` type is provided, subsequent calls to `Base.show(context::PPrintContext, x)` will dispatch using the provided `mime` instance. 
"""
struct PPrintContext{IO_t <: IO, M<:Union{MIME, Nothing}} 
    io::IO_t
    mime::M
end
PPrintContext(io::IO) = PPrintContext{typeof(io), Nothing}(io, nothing)
PPrintContext(io::IO, mime::MIME) = PPrintContext{typeof(io), typeof(mime)}(io, mime)
PPrintContext(io::IO, mime::AbstractString) = PPrintContext(io, MIME(mime))
Base.show(context::PPrintContext, mime::MIME, x) = pprint(context.io, mime, x)

Base.show(context::PPrintContext{<:IO, <:MIME}, x) = show(context, context.mime, x)

"""
    repr_pretty([mime], x; context=nothing)

If `istextmime(mime)` is `true`, returns an `AbstractString` containing the representation of `x` in the requested `mime` type rendered with the `AutoPrettyPrinting.pprint` method. 

Otherwise returns `repr(mime, x; context)`.

If `mime` is not provided, defaults to `MIME"text/plain"`.
"""
function repr_pretty(mime, x; context=nothing) 
    if istextmime(mime)
        io = IOBuffer()
        if context === nothing 
            show(PPrintContext(io, mime), x)
        else
            show(PPrintContext(IOContext(io, context), mime), x)
        end
        return String(take!(io))
    else
        return repr(mime, x; context)
    end
end
repr_pretty(x; context=nothing) = repr_pretty(MIME"text/plain"(), x; context)