function pprint_values_expr(expr; level=nothing, next_level::Bool=false, parent_is_container=nothing, show_typename=nothing, _sourceinfo=not_provided)
    output_expr = Expr(:block)
    m = MacroCall(; name=:($AutoPrettyPrinting.$(Symbol("@with"))), line=_sourceinfo)
    if !isnothing(level)
        push!(m.args, :($AutoPrettyPrinting.PPRINT_NESTED_LEVEL => $(esc(level))))
    elseif next_level 
        push!(output_expr.args, :(local level = $AutoPrettyPrinting.PPRINT_NESTED_LEVEL[]))
        push!(m.args, :($AutoPrettyPrinting.PPRINT_NESTED_LEVEL => level+1))
    end
    if !isnothing(parent_is_container)
        push!(m.args, :($AutoPrettyPrinting.PPRINT_PARENT_IS_CONTAINER => $(esc(parent_is_container))))
    end
    if !isnothing(show_typename)
        push!(m.args, :($AutoPrettyPrinting.PPRINT_SHOW_TYPENAME => $(esc(show_typename))))
    end
    push!(output_expr.args, to_expr(m(expr)))
    return output_expr
end

"""
    @pprint_values [level=nothing] [next_level=false] [parent_is_container=nothing] [show_typename=nothing] expr
"""
macro pprint_values(args...)
    length(args) ≥ 2 || error("Must have at least two arguments")
    @parse_kwargs args[1:end-1]... begin 
        level::Union{Symbol, Expr, Int, Nothing} = nothing
        next_level::Bool = false
        parent_is_container::Union{Symbol, Expr, Bool, Nothing} = nothing 
        show_typename::Union{Symbol, Expr, Bool, Nothing} = nothing
    end
    return pprint_values_expr(esc(args[end]); level, next_level, parent_is_container, show_typename)
end

_is_atomic_type((@nospecialize T::Type)) = false
_is_atomic_type(::Type{Symbol}) = true

_is_atomic_type(x) = _is_atomic_type(typeof(x))

const simple_struct_nfields_threshold = 4

function is_simple_struct(t)
    T = typeof(t) 
    if isstructtype(T)
        return length(fieldnames(T)) ≤ simple_struct_nfields_threshold && all( (v = getfield(t, k); (_is_atomic_type(v) || is_simple_struct(v))) for k in fieldnames(T) )
    else
        return false 
    end
end

function is_simple_struct((@nospecialize t::Union{Tuple, NamedTuple}))
    return length(t) ≤ simple_struct_nfields_threshold && all( (_is_atomic_type( v ) || is_simple_struct(v)) for v in t )
end

function should_allow_horiz_container((@nospecialize x))
    if x isa AbstractDict 
        eT = valtype(x)
    else
        eT = eltype(x)
    end
    if isstructtype(eT) 
        level = PPRINT_NESTED_LEVEL[]
        level ≤ 2 && return true 
        level > 4 && return false 
        return @pprint_values next_level=true begin 
            all(should_allow_horiz(xi) for xi in values(x))
        end
    else
        return true
    end
end
should_allow_horiz(x::Union{AbstractVector, AbstractSet, AbstractDict}) = should_allow_horiz_container(x)

function should_allow_horiz((@nospecialize x)) 
    T = typeof(x)
    if isstructtype(T)
        level = PPRINT_NESTED_LEVEL[]
        level < 0 && return false 
        is_simple_struct(x) && return true 
        _fields = fieldnames(T)
        length(_fields) > 3 && return false 
        return @pprint_values next_level=true begin 
            all(should_allow_horiz(getfield(x,k)) for k in _fields)
        end
    else
        return true
    end
end

function should_allow_vert((@nospecialize x))
    T = typeof(x)
    if isstructtype(T)
        return !PPRINT_PARENT_IS_CONTAINER[] || !should_allow_horiz(x)
    else
        return true
    end
end

function should_allow_vert_container((@nospecialize x))
    PPRINT_PARENT_IS_CONTAINER[] && return true 
    if x isa AbstractDict 
        eT = valtype(x)
    else
        eT = eltype(x)
    end
    if isstructtype(eT) 
        level = PPRINT_NESTED_LEVEL[]
        level ≥ 2 || (length(x) ≥ 3 || any(!is_simple_struct(xi) for xi in values(x))) && return true 
        # Allow vertical layout if there's a singleton element which also allows a vertical layout
        return @pprint_values parent_is_container=true next_level=true  begin 
            length(x) == 1 && should_allow_vert(only(x))
        end
    else
        return true
    end
end

should_allow_vert(x::Union{AbstractVector, AbstractSet, AbstractDict}) = should_allow_vert_container(x)

