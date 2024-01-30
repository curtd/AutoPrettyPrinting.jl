mime_type_to_generate(::MIME"text/plain") = "text/plain"

const all_mime_types_to_generate = Ref{Union{Nothing,Vector{Symbol}}}(nothing)

_mime_type(::Type{MIME{S}}) where {S} = S 
_mime_types_to_generate() = Symbol[_mime_type(fieldtype(m.sig, 2)) for m in methods(AutoPrettyPrinting.mime_type_to_generate)]

@inline mime_types_to_generate(::Nothing) = _mime_types_to_generate()
@inline mime_types_to_generate(input) = input
@inline mime_types_to_generate() = mime_types_to_generate(all_mime_types_to_generate[])

function set_mime_types_to_generate(mime_types=nothing)
    if isnothing(mime_types)
        all_mime_types_to_generate[] = nothing 
    else
        all_mime_types_to_generate[] = unique(collect(mime_types))
    end
    return nothing
end

"""
    @mime_type "type"

Registers `"type"` as a `MIME` type registered with this package at package definition time. Future calls to `@custom_tile` and `@pprint` with no provided `mime_types` arguments will generate methods corresponding to this type, along with previously declared mime types.
"""
macro mime_type(str)
    str isa String || error("`@mime_type`: Input must be a string, got $(typeof(str))")
    return Expr(:block, __source__, :($AutoPrettyPrinting.mime_type_to_generate(::MIME{$(QuoteNode(Symbol(str)))}) = $str)) |> esc
end