# Pretty printing penalty factor for top-level struct when spilling current line onto next line
# Higher number encourages top-level struct to render in vertical mode, if it does not fit on the current line
const PP_SPILL_FACTOR = Ref(10)

const PP_DEFAULT_INDENT_NUM_SPACES = Ref(2)

# Pretty printing penalty factor for top-level struct when breaking current line into multiple lines
# Higher number encourages top-level struct to render in horizontal mode, if it does not fit on the current line
const PP_BREAK_FACTOR = Ref(1)

default_indent_width() = PP_DEFAULT_INDENT_NUM_SPACES[]
_indent(width::Int=default_indent_width()) = literal(' '^width)

"""
    KeyValue(key, value)

Represents a generic `(key, value)` pair, with custom tile representation `key = value` (as opposed to `key => value` for the built-in `Pair` type).
"""
struct KeyValue{K, V}
    key::K 
    value::V
end
Base.first(x::KeyValue) = x.key
Base.last(x::KeyValue) = x.value

const KV_SEPARATOR = ScopedValue(" = ")
const PAIR_SEPARATOR = ScopedValue(" => ")

kv_separator_horiz((@nospecialize T::Type{<:KeyValue})) = literal(KV_SEPARATOR[])
kv_separator_vert((@nospecialize T::Type{<:KeyValue})) = literal(KV_SEPARATOR[])
kv_separator_horiz((@nospecialize T::Type{<:Pair})) = literal(PAIR_SEPARATOR[])
kv_separator_vert((@nospecialize T::Type{<:Pair})) = literal(PAIR_SEPARATOR[])

kv_separator_horiz((@nospecialize x)) = kv_separator_horiz(typeof(x))
kv_separator_vert((@nospecialize x)) = kv_separator_vert(typeof(x))

const vector_parentheses = ScopedValue(("[", "]"))
const set_parentheses = ScopedValue(("{", "}"))
const dict_parentheses = ScopedValue(("(", ")"))
const tuple_parentheses = ScopedValue(("(", ")"))
const named_tuple_parentheses = ScopedValue(("(; ", ")"))
const empty_parentheses = ("", "")

const default_horiz_separator = ScopedValue(", ")
const default_vert_separator = ScopedValue("")
const empty_layout = Union{Layout, Nothing}[]

"""
    @hide_typename custom_tile(...)

Hides the top-level typename generated by invoking the provided `custom_tile` expression. Only relevant for top-level types that include their own typename in their `custom_tile` expression. 
"""
macro hide_typename(ex)
    return :($AutoPrettyPrinting.@with $AutoPrettyPrinting.PPRINT_SHOW_TYPENAME => false $(esc(ex)))
end

function decorators_expr(expr; horiz_separator=nothing, kv_separator=nothing, pair_separator=nothing, vector_parentheses=nothing, set_parentheses=nothing, dict_parentheses=nothing, tuple_parentheses=nothing, named_tuple_parentheses=nothing, _sourceinfo=not_provided)
    @nospecialize

    output_expr = Expr(:block)
    m = MacroCall(; name=:($AutoPrettyPrinting.$(Symbol("@with"))), line=_sourceinfo)
    if !isnothing(horiz_separator)
        push!(m.args, :($AutoPrettyPrinting.default_horiz_separator => $(esc(horiz_separator))))
    end
    if !isnothing(kv_separator)
        push!(m.args, :($AutoPrettyPrinting.KV_SEPARATOR => $(esc(kv_separator))))
    end
    if !isnothing(pair_separator)
        push!(m.args, :($AutoPrettyPrinting.PAIR_SEPARATOR => $(esc(pair_separator))))
    end
    if !isnothing(vector_parentheses)
        push!(m.args, :($AutoPrettyPrinting.vector_parentheses => $(esc(vector_parentheses))))
    end
    if !isnothing(set_parentheses)
        push!(m.args, :($AutoPrettyPrinting.set_parentheses => $(esc(set_parentheses))))
    end
    if !isnothing(dict_parentheses)
        push!(m.args, :($AutoPrettyPrinting.dict_parentheses => $(esc(dict_parentheses))))
    end
    if !isnothing(tuple_parentheses)
        push!(m.args, :($AutoPrettyPrinting.tuple_parentheses => $(esc(tuple_parentheses))))
    end
    if !isnothing(named_tuple_parentheses)
        push!(m.args, :($AutoPrettyPrinting.named_tuple_parentheses => $(esc(named_tuple_parentheses))))
    end
    push!(output_expr.args, to_expr(m(expr)))
    return output_expr
end

"""
    @decorators [separators=nothing] [parentheses=nothing] expr

Executes `expr` using the prescribed decorator strings specified in `kwargs`.

If provided, `separators` must be of the form `(key1=value1, ...)` and the provided values must resolve to a `String` type
If provided, `parentheses` must be of the form `(key1=value1, ...)` and the provided values must resolve to a `Tuple{String, String}` type

# Arguments 
## Separators
- `horiz` - separator string used when joining items horizontally
- `kv` - separator string used when rendering `KeyValue` pairs
- `pair` - separator string used when rendering `Pair` objects

## Parentheses
- `vector` - start + end parentheses used when rendering `AbstractVector`s
- `set` - start + end parentheses used when rendering `AbstractSet`s
- `dict` - start + end parentheses used when rendering `AbstractDict` and `AbstractDictionary`s
- `tuple` - start + end parentheses used when rendering `Tuple`s
- `named_tuple` - start + end parentheses used when rendering `NamedTuple`s
"""
macro decorators(args...)
    length(args) ≥ 2 || error("Must have at least two arguments")
    @parse_kwargs args[1:end-1]... begin 
        separators::Union{Expr, Nothing} = nothing
        parentheses::Union{Expr, Nothing} = nothing 
    end
    horiz_separator = kv_separator = pair_separator = nothing
    if !isnothing(separators)
        f = from_expr(NamedTupleExpr, separators; throw_error=true)
        if haskey(f, :horiz)
            horiz_separator = f[:horiz].value 
        end
        if haskey(f, :kv)
            kv_separator = f[:kv].value 
        end
        if haskey(f, :pair)
            pair_separator = f[:pair].value 
        end
    end
    vector_parentheses = set_parentheses = dict_parentheses = tuple_parentheses = named_tuple_parentheses = nothing
    if !isnothing(parentheses)
        f = from_expr(NamedTupleExpr, parentheses; throw_error=true)
        if haskey(f, :vector)
            vector_parentheses = f[:vector].value 
        end
        if haskey(f, :set)
            set_parentheses = f[:set].value 
        end
        if haskey(f, :dict)
            dict_parentheses = f[:dict].value 
        end
        if haskey(f, :tuple)
            tuple_parentheses = f[:tuple].value 
        end
        if haskey(f, :named_tuple)
            named_tuple_parentheses = f[:named_tuple].value 
        end
    end

    return decorators_expr(esc(args[end]); horiz_separator, kv_separator, pair_separator, vector_parentheses, set_parentheses, dict_parentheses, tuple_parentheses, named_tuple_parentheses, _sourceinfo=__source__)
end


# Adapted from PrettyPrinting.jl
function list_layout_prefer_horizontal(horizontal_items::Vector{<:Union{Nothing,Layout}}, vertical_items::Vector{<:Union{Nothing,Layout}};
    prefix::Union{String,Symbol,Layout}="",
    parentheses::Union{Tuple{String,String}, ScopedValue{Tuple{String,String}}}=vector_parentheses,
    horizontal_sep::String=default_horiz_separator[],
    vertical_sep::String=default_vert_separator[],
    sep_brk=:end,
    indent_width::Int=PP_DEFAULT_INDENT_NUM_SPACES[], 
    break_factor::Int=1,
    spill_factor::Int=1, 
    allow_horiz::Bool=false,
    allow_vert::Bool=false, 
    horiz_header_footer_spacing::Int=0,
     kwargs...)
    if !allow_horiz && !allow_vert
        allow_horiz = true 
    end
    if parentheses isa ScopedValue 
        parentheses = parentheses[]
    end
    prefix_lt = prefix isa Layout ? prefix : literal(prefix)
    header = prefix_lt * literal(parentheses[1])
    parenthesis_empty = isempty(parentheses[1]) && isempty(parentheses[2])
    footer = literal(parentheses[2])
    header_footer_empty = prefix isa String && isempty(prefix) && parenthesis_empty
    !(isempty(horizontal_items) && isempty(vertical_items)) || return header * footer
    horizontal_sep = literal(horizontal_sep)
    sepl_lt = literal(sep_brk == :start || sep_brk == :both ? lstrip(vertical_sep) : "")
    sepr_lt = literal(sep_brk == :end || sep_brk == :both ? rstrip(vertical_sep) : "")
    left_indent = _indent(indent_width)

    if !isempty(vertical_items) && allow_vert
        first_vert_item_index = findfirst(!isnothing, vertical_items)
        if !isnothing(first_vert_item_index)
            vlt = @inbounds vertical_items[first_vert_item_index]
            for item_v in (@view vertical_items[first_vert_item_index+1:end])
                vlt = (vlt * sepr_lt) / (sepl_lt * item_v)
            end
            if !header_footer_empty
                vlt = header / (left_indent*vlt) /  footer
            end
        else
            vlt = nothing 
        end
    else 
        vlt = nothing
    end
    if !isempty(horizontal_items) && allow_horiz
        first_horiz_item_index = findfirst(!isnothing, horizontal_items)
        if !isnothing(first_horiz_item_index)
            hlt = @inbounds horizontal_items[first_horiz_item_index]
            for item_h in (@view horizontal_items[first_horiz_item_index+1:end])
                if !isnothing(item_h)
                    hlt = hlt * horizontal_sep * item_h
                end
            end
            if horiz_header_footer_spacing > 0
                hlt = header * literal(' '^horiz_header_footer_spacing) * hlt * literal(' '^horiz_header_footer_spacing) * footer
            else
                hlt = header * hlt * footer
            end
        else 
            hlt = header * footer 
        end
    else 
        hlt = nothing
    end
    if !isnothing(hlt)
        if !isnothing(vlt) 
            return PrettyPrinting.penalize(hlt | vlt; break_factor, spill_factor)
        else
            return hlt 
        end
    else
        return isnothing(vlt) ? literal("") : vlt
    end
end

list_layout_prefer_horizontal(items::Vector{<:Union{Nothing,Layout}}; kwargs...) = list_layout_prefer_horizontal(items, items; kwargs...)

"""
    custom_tile(x, mime::MIME; kwargs...)

Returns the layout associated with `x` for a given `mime` type. 
    
Defaults to `PrettyPrinting.tile(x)` if unspecified.

You can override this method for objects `x::T` of your own custom type `T` to control how the objects of type `T` are rendered by this package for a given `MIME` type.

See also [`@custom_tile`](@ref)
"""
custom_tile(x, ::MIME; kwargs...) = PrettyPrinting.tile(x)

"""
    custom_tile_horiz(x, mime::MIME; kwargs...)

Returns the horizontal layout associated with `x` for a given `mime` type.
    
Defaults to `custom_tile(x, mime; kwargs...)` if unspecified.
"""
custom_tile_horiz(x, mime::MIME; kwargs...) = custom_tile(x, mime; kwargs...)


"""
    custom_tile_vert(x, mime::MIME; kwargs...)

Returns the vertical layout associated with `x` for a given `mime` type.
    
Defaults to `custom_tile(x, mime; kwargs...)` if unspecified.
"""
custom_tile_vert(x, mime::MIME; kwargs...) = custom_tile(x, mime; kwargs...)

custom_tile(x::Symbol, mime::MIME; kwargs...) = literal(repr(x))
custom_tile_horiz(x::Layout, mime::MIME; kwargs...) = x
custom_tile_vert(x::Layout, mime::MIME; kwargs...) = x
custom_tile(x::Layout, mime::MIME; kwargs...) = x

custom_tile_horiz(x::Union{Pair, KeyValue}, mime::MIME; kwargs...) = custom_tile_horiz(first(x), mime; kwargs...)*kv_separator_horiz(x)*custom_tile_horiz(last(x), mime; kwargs...)
custom_tile_vert(x::Union{Pair, KeyValue}, mime::MIME; kwargs...) = custom_tile_vert(first(x), mime; kwargs...)*kv_separator_vert(x)*custom_tile_vert(last(x), mime; kwargs...)
custom_tile_horiz(x::KeyValue{Symbol, <:Any}, mime::MIME; kwargs...) = literal(string(first(x)))*kv_separator_horiz(x)*custom_tile_horiz(last(x), mime; kwargs...)
custom_tile_vert(x::KeyValue{Symbol, <:Any}, mime::MIME; kwargs...) = literal(string(first(x)))*kv_separator_vert(x)*custom_tile_vert(last(x), mime; kwargs...)

_custom_tile_padded_key(key, separator, value, max_width::Int; kwargs...) = literal(rpad(key, max_width))*separator*value

custom_tile_padded_key(custom_tile_value_f, x::Union{Pair, KeyValue}, mime::MIME, max_width::Int; kwargs...) = _custom_tile_padded_key((x isa Pair{Symbol, <:Any} ? repr(first(x)) : first(x)), kv_separator_vert(x), custom_tile_value_f(last(x), mime; kwargs...), max_width)

max_align_key_width(x) = mapfoldl(t->textwidth(string(first(t))), max, x; init=0)

should_sort_keys((@nospecialize x::AbstractDict)) = true
should_sort_keys((@nospecialize x::AbstractSet)) = true
should_sort_keys((@nospecialize x::AbstractVector)) = true
should_sort_keys((@nospecialize x)) = false


function sorted_keys(x, x_keys)
    x_keys_v = collect(x_keys)
    if should_sort_keys(x)
        return sort(x_keys_v; by=string)
    else 
        return x_keys_v
    end
end

function custom_tile_horiz(x::AbstractVector{<:KeyValue}, mime::MIME; kwargs...)
    if isempty(x)
        return list_layout_prefer_horizontal(empty_layout; kwargs..., allow_horiz=true, allow_vert=false, parentheses=empty_parentheses)
    else
        @pprint_values parent_is_container=true next_level=true show_typename=true begin 
            data_horiz = [custom_tile_horiz(xi, mime; kwargs...) for xi in x]
         
            return list_layout_prefer_horizontal(data_horiz; kwargs..., allow_horiz=true, allow_vert=false, parentheses=empty_parentheses)
        end
    end
end

function custom_tile_vert(x::AbstractVector{<:KeyValue}, mime::MIME; kwargs...)
    if isempty(x)
        return list_layout_prefer_horizontal(empty_layout; kwargs..., allow_horiz=false, allow_vert=true, parentheses=empty_parentheses)
    else
        @pprint_values parent_is_container=true next_level=true show_typename=true begin  
            max_width = max_align_key_width(x)
            data_vert = [custom_tile_padded_key(custom_tile, xi, mime, max_width; kwargs...) for xi in x]
            return list_layout_prefer_horizontal(empty_layout, data_vert; kwargs..., allow_horiz=false, allow_vert=true, parentheses=empty_parentheses, sep="")
        end
    end
end

for horiz in (false, true)
    if horiz
        f_name = :custom_tile_horiz 
        f_child = :custom_tile_horiz 
        allow_horiz = true
        allow_vert = false
    else
        f_name = :custom_tile_vert
        f_child = :custom_tile
        allow_horiz = false
        allow_vert = true
    end
    f_name_dict = Symbol(f_name, :_dict)
    @eval begin 
        function $f_name(x::Tuple, mime::MIME; kwargs...) 
            if isempty(x)
                return list_layout_prefer_horizontal(empty_layout; kwargs..., allow_horiz=$allow_horiz, allow_vert=$allow_vert, parentheses = tuple_parentheses)
            else
                data = @pprint_values parent_is_container=true next_level=true show_typename=true begin 
                    [$f_child(xi, mime; kwargs...) for xi in x]
                end
                return list_layout_prefer_horizontal(data; kwargs..., allow_horiz=$allow_horiz, allow_vert=$allow_vert, parentheses = tuple_parentheses)
            end
        end
        function $f_name(x::AbstractVector, mime::MIME; kwargs...) 
            if isempty(x)
                return list_layout_prefer_horizontal(empty_layout; kwargs..., allow_horiz=$allow_horiz, allow_vert=$allow_vert, parentheses = vector_parentheses)
            else
                data = @pprint_values parent_is_container=true next_level=true show_typename=true begin 
                    [$f_child(xi, mime; kwargs...) for xi in x]
                end
                return list_layout_prefer_horizontal(data; kwargs..., allow_horiz=$allow_horiz, allow_vert=$allow_vert, parentheses = vector_parentheses)
            end
        end

        function $f_name(x::AbstractSet, mime::MIME; kwargs...) 
            if isempty(x)
                return list_layout_prefer_horizontal(empty_layout; kwargs..., allow_horiz=$allow_horiz, allow_vert=$allow_vert, parentheses=set_parentheses)
            else
                x_sorted = sorted_keys(x, x)
                
                data = @pprint_values parent_is_container=true next_level=true show_typename=true begin 
                    [$f_child(xi, mime; kwargs...) for xi in x_sorted]
                end
                return list_layout_prefer_horizontal(data; kwargs..., allow_horiz=$allow_horiz, allow_vert=$allow_vert, parentheses=set_parentheses, horiz_header_footer_spacing=1)
            end
            
        end

        function $f_name_dict(x, mime::MIME; kwargs...)
            T = typeof(x)
            unionall_type = nameof(T)
            if PPRINT_SHOW_TYPENAME[]
                prefix = string(unionall_type)
            else 
                prefix = ""
            end
            if isempty(x) 
                return list_layout_prefer_horizontal(empty_layout; kwargs..., allow_horiz=$allow_horiz, allow_vert=$allow_vert, parentheses=dict_parentheses, prefix)
            else
                ks_sorted = sorted_keys(x, keys(x))

                data_horiz = @pprint_values parent_is_container=true next_level=true show_typename=true begin 
                    [$f_child(Pair(k,x[k]), mime; kwargs...) for k in ks_sorted]
                end
                $( !horiz ? (quote 
                    max_width = max_align_key_width(pairs(x))
                    data_vert = @pprint_values parent_is_container=true next_level=true show_typename=true begin 
                        [custom_tile_padded_key($f_child, Pair(k, x[k]), mime, max_width; kwargs...) for k in ks_sorted]
                    end
                end) : :(data_vert=nothing) )
            end
            horiz_header_footer_spacing = 1
            if !isnothing(data_vert)
                return list_layout_prefer_horizontal(data_horiz, data_vert; kwargs..., allow_horiz=$allow_horiz, allow_vert=$allow_vert, parentheses=dict_parentheses, prefix, horiz_header_footer_spacing)
            else
                return list_layout_prefer_horizontal(data_horiz; kwargs..., allow_horiz=$allow_horiz, allow_vert=$allow_vert, parentheses=dict_parentheses, prefix, horiz_header_footer_spacing)
            end
        end
        $f_name(x::AbstractDict, mime::MIME; kwargs...) = $f_name_dict(x, mime; kwargs...)
    end
end

function custom_tile_horiz_or_vert(o, mime::MIME; kwargs...)
    if should_allow_horiz(o)
        horiz_layout = custom_tile_horiz(o, mime; kwargs...)
        if should_allow_vert(o)
            vert_layout = custom_tile_vert(o, mime; kwargs...,)
            return PrettyPrinting.penalize(horiz_layout | vert_layout; break_factor=PP_BREAK_FACTOR[], spill_factor=PP_SPILL_FACTOR[])
        else
            return horiz_layout
        end
    else
        return custom_tile_vert(o, mime; kwargs...,)
    end
end

custom_tile(x::Union{Pair, KeyValue}, mime::MIME; kwargs...) = custom_tile_horiz_or_vert(x, mime; kwargs...)

function custom_tile_container(x, mime::MIME; kwargs...) 
    @pprint_values parent_is_container=true begin 
        custom_tile_horiz_or_vert(x, mime; kwargs...)
    end
end

custom_tile(x::Union{AbstractVector, AbstractSet, AbstractDict, Tuple}, mime::MIME; kwargs...) = custom_tile_container(x, mime; kwargs...)

"""
    pprint(io::IO, mime::MIME, obj)

Pretty prints `obj` to `io` according to its `custom_tile` + `mime` representation.
"""
function pprint(io::IO, mime::MIME, obj)
    if displaysize(io) == (24, 80) # Treat unset displaysize as infinite width
        iob = IOContext(io, :displaysize => (1_000_000, 1_000_000))
    else
        iob = io 
    end

    layout = @pprint_values parent_is_container=false level=0 begin 
        custom_tile(obj, mime)
    end
    formatter = PrettyPrinting.Formatter(iob, PP_BREAK_FACTOR[], PP_SPILL_FACTOR[])
    PrettyPrinting.render(iob, PrettyPrinting.best_fit(formatter, layout))
    return nothing
end