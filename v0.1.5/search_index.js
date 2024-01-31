var documenterSearchIndex = {"docs":
[{"location":"api/#API","page":"API","title":"API","text":"","category":"section"},{"location":"api/#Macros","page":"API","title":"Macros","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"@mime_type \n@custom_tile\n@def_pprint\n@def_pprint_atomic\n@hide_typename\n@decorators","category":"page"},{"location":"api/#AutoPrettyPrinting.@mime_type","page":"API","title":"AutoPrettyPrinting.@mime_type","text":"@mime_type \"type\"\n\nRegisters \"type\" as a MIME type registered with this package at package definition time. Future calls to @custom_tile and @pprint with no provided mime_types arguments will generate methods corresponding to this type, along with previously declared mime types.\n\n\n\n\n\n","category":"macro"},{"location":"api/#AutoPrettyPrinting.@custom_tile","page":"API","title":"AutoPrettyPrinting.@custom_tile","text":"@custom_tile [mime_types=nothing] [generic_mime=false] [base_show=false] T => custom_tile_expr\n\nDefines a AutoPrettyPrinting.custom_tile method for type T and optionally provided mime_types using custom_tile_expr as the function's body. \n\nArguments\n\nmime_types=nothing: The MIME types to generate. If this value is the empty string, no mime types will be generated. If this value is a non-empty String or a vect or tuple expression of Strings, these mime types will be used when generating code. Otherwise, if this value is nothing, the code generated will use the mime types previously registered with @mime_type.\ngeneric_mime::Bool=false: If true, ignores mime_types input and use a generic (untemplated) MIME type for all code generation.\nbase_show::Bool=false: If true, will define Base.show(io::IO, ::MIME(mime), ::T) for each mime in mime_types\ncustom_tile_expr: Expression to be used for the body of the custom_tile method. If this value is a block expression, it should contain a _obj_ placeholder to indicate the object of type T and a _mime_ placeholder to indicate the mime type. Otherwise, it can be a function definition expression of the form (object, mime_type)->expr.\n\n\n\n\n\n","category":"macro"},{"location":"api/#AutoPrettyPrinting.@def_pprint","page":"API","title":"AutoPrettyPrinting.@def_pprint","text":"@def_pprint [properties=nothing] [mime_types=nothing] [generic_mime=false] [base_show=false] T\n\nAuto generates pretty printing methods for type T and optionally provided mime_types. \n\nArguments\n\nproperties=nothing: Either a Symbol or a vect expression of Symbols corresponding to the properties to use from x::T. Will default to using the fieldnames of x if unspecified\nmime_types=nothing: The MIME types to generate. If this value is the empty string, no mime types will be generated. If this value is a non-empty String or a vect or tuple expression of Strings, these mime types will be used when generating code. Otherwise, if this value is nothing, the code generated will use the mime types previously registered with @mime_type.\ngeneric_mime::Bool=false: If true, ignores mime_types input and use a generic (untemplated) MIME type for all code generation.\nbase_show::Bool=false: If true, will define Base.show(io::IO, ::MIME(mime), ::T) for each mime in mime_types\n\n\n\n\n\n","category":"macro"},{"location":"api/#AutoPrettyPrinting.@def_pprint_atomic","page":"API","title":"AutoPrettyPrinting.@def_pprint_atomic","text":"@def_pprint_atomic [to_string=nothing] [mime_types=nothing] [generic_mime=false] T\n\nRegisters type T as an atomic type (i.e., one with no subfields nor subelements) and defines custom_tile(x::T, mime::MIME{S}) = to_string(x) for each mime type. \n\nArguments\n\nto_string=nothing: Function expression that returns the string representation of x. Defaults to Base.string if not provided.\nmime_types=nothing: The MIME types to generate. If this value is the empty string, no mime types will be generated. If this value is a non-empty String or a vect or tuple expression of Strings, these mime types will be used when generating code. Otherwise, if this value is nothing, the code generated will use the mime types previously registered with @mime_type.\ngeneric_mime::Bool=false: If true, ignores mime_types input and use a generic (untemplated) MIME type for all code generation.\n\n\n\n\n\n","category":"macro"},{"location":"api/#AutoPrettyPrinting.@hide_typename","page":"API","title":"AutoPrettyPrinting.@hide_typename","text":"@hide_typename custom_tile(...)\n\nHides the top-level typename generated by invoking the provided custom_tile expression. Only relevant for top-level types that include their own typename in their custom_tile expression. \n\n\n\n\n\n","category":"macro"},{"location":"api/#AutoPrettyPrinting.@decorators","page":"API","title":"AutoPrettyPrinting.@decorators","text":"@decorators [separators=nothing] [parentheses=nothing] expr\n\nExecutes expr using the prescribed decorator strings specified in kwargs.\n\nIf provided, separators must be of the form (key1=value1, ...) and the provided values must resolve to a String type If provided, parentheses must be of the form (key1=value1, ...) and the provided values must resolve to a Tuple{String, String} type\n\nArguments\n\nSeparators\n\nhoriz - separator string used when joining items horizontally\nkv - separator string used when rendering KeyValue pairs\npair - separator string used when rendering Pair objects\n\nParentheses\n\nvector - start + end parentheses used when rendering AbstractVectors\nset - start + end parentheses used when rendering AbstractSets\ndict - start + end parentheses used when rendering AbstractDict and AbstractDictionarys\ntuple - start + end parentheses used when rendering Tuples\nnamed_tuple - start + end parentheses used when rendering NamedTuples\n\n\n\n\n\n","category":"macro"},{"location":"api/#Functions","page":"API","title":"Functions","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"AutoPrettyPrinting.custom_tile(x, mime::MIME; kwargs...)\nAutoPrettyPrinting.custom_tile_horiz(x, mime::MIME; kwargs...)\nAutoPrettyPrinting.custom_tile_vert(x, mime::MIME; kwargs...)\nAutoPrettyPrinting.pprint(io::IO, mime::MIME, obj)\nrepr_pretty","category":"page"},{"location":"api/#AutoPrettyPrinting.custom_tile-Tuple{Any, MIME}","page":"API","title":"AutoPrettyPrinting.custom_tile","text":"custom_tile(x, mime::MIME; kwargs...)\n\nReturns the layout associated with x for a given mime type. \n\nDefaults to PrettyPrinting.tile(x) if unspecified.\n\nYou can override this method for objects x::T of your own custom type T to control how the objects of type T are rendered by this package for a given MIME type.\n\nSee also @custom_tile\n\n\n\n\n\n","category":"method"},{"location":"api/#AutoPrettyPrinting.custom_tile_horiz-Tuple{Any, MIME}","page":"API","title":"AutoPrettyPrinting.custom_tile_horiz","text":"custom_tile_horiz(x, mime::MIME; kwargs...)\n\nReturns the horizontal layout associated with x for a given mime type.\n\nDefaults to custom_tile(x, mime; kwargs...) if unspecified.\n\n\n\n\n\n","category":"method"},{"location":"api/#AutoPrettyPrinting.custom_tile_vert-Tuple{Any, MIME}","page":"API","title":"AutoPrettyPrinting.custom_tile_vert","text":"custom_tile_vert(x, mime::MIME; kwargs...)\n\nReturns the vertical layout associated with x for a given mime type.\n\nDefaults to custom_tile(x, mime; kwargs...) if unspecified.\n\n\n\n\n\n","category":"method"},{"location":"api/#AutoPrettyPrinting.pprint-Tuple{IO, MIME, Any}","page":"API","title":"AutoPrettyPrinting.pprint","text":"pprint(io::IO, mime::MIME, obj)\n\nPretty prints obj to io according to its custom_tile + mime representation.\n\n\n\n\n\n","category":"method"},{"location":"api/#AutoPrettyPrinting.repr_pretty","page":"API","title":"AutoPrettyPrinting.repr_pretty","text":"repr_pretty([mime], x; context=nothing)\n\nIf istextmime(mime) is true, returns an AbstractString containing the representation of x in the requested mime type rendered with the AutoPrettyPrinting.pprint method. \n\nOtherwise returns repr(mime, x; context).\n\nIf mime is not provided, defaults to MIME\"text/plain\".\n\n\n\n\n\n","category":"function"},{"location":"api/#Types","page":"API","title":"Types","text":"","category":"section"},{"location":"api/","page":"API","title":"API","text":"KeyValue\nPPrintContext","category":"page"},{"location":"api/#AutoPrettyPrinting.KeyValue","page":"API","title":"AutoPrettyPrinting.KeyValue","text":"KeyValue(key, value)\n\nRepresents a generic (key, value) pair, with custom tile representation key = value (as opposed to key => value for the built-in Pair type).\n\n\n\n\n\n","category":"type"},{"location":"api/#AutoPrettyPrinting.PPrintContext","page":"API","title":"AutoPrettyPrinting.PPrintContext","text":"PPrintContext(io::IO, [mime::MIME])\n\nCreate a PPrintContext that wraps a given stream. \n\nSubsequent calls to Base.show(context::PPrintContext, ::MIME, x) will use the pretty printing machinery provided in this package to render x. This type is useful primarily when x has a custom_tile method defined (or provided by this package), but the primary Base.show methods are defined outside of this package and should not be overridden. \n\nAdditionally, if a mime::MIME type is provided, subsequent calls to Base.show(context::PPrintContext, x) will dispatch using the provided mime instance. \n\n\n\n\n\n","category":"type"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"DocTestSetup = nothing","category":"page"},{"location":"examples/#Example-usage","page":"Example Usage","title":"Example usage","text":"","category":"section"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"If we're not particular about the particular layout or format of the pretty printing layouts of our custom types, we can use the @def_pprint macro to define our Base.show method for the default \"text/plain\" MIME type.","category":"page"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"julia> using AutoPrettyPrinting\n\njulia> struct A \n           key1::Int \n           key2::String\n       end\n\njulia> @def_pprint mime_types=\"text/plain\" base_show=true A\n\njulia> a = A(10, \"abcd\")\nA(key1 = 10, key2 = abcd)","category":"page"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"Once we've registered a custom type A with this package, we can also register custom types that use A as a sub-field","category":"page"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"julia> struct B \n           data::Vector{A}\n       end\n\njulia> @def_pprint mime_types=\"text/plain\" base_show=true B \n\njulia> b = B([A(i, \"a\"^i) for i in 1:10])\nB(\n  data = [\n           A(key1 = 1, key2 = a)\n           A(key1 = 2, key2 = aa)\n           A(key1 = 3, key2 = aaa)\n           A(key1 = 4, key2 = aaaa)\n           A(key1 = 5, key2 = aaaaa)\n           A(key1 = 6, key2 = aaaaaa)\n           A(key1 = 7, key2 = aaaaaaa)\n           A(key1 = 8, key2 = aaaaaaaa)\n           A(key1 = 9, key2 = aaaaaaaaa)\n           A(key1 = 10, key2 = aaaaaaaaaa)\n         ]\n)","category":"page"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"Internal heuristics defined in this package automatically use a more compact representation when the objects don't contain too many elements and are sufficient simple.","category":"page"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"julia> b = B([A(i, \"a\"^i) for i in 1:2])\nB(data = [A(key1 = 1, key2 = a), A(key1 = 2, key2 = aa)])","category":"page"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"Out of the box, AutoPrettyPrinting supports rendering of AbstractVector, AbstractDict, and AbstractSet types. Via package extensions, AbstractDictionary objects from Dictionaries.jl, and types from TimeZones.jl and from the Dates and Sockets standard library packages are also supported.","category":"page"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"julia> using Dates, Dictionaries, Sockets, TimeZones\n\njulia> struct C\n           timezones::Dictionary{Symbol, TimeZone}\n           ips::Set{IPv4}\n           dt::DateTime\n       end\n\njulia> @def_pprint mime_types=\"text/plain\" base_show=true C\n\njulia> c = C(dictionary((:a => tz\"America/Los_Angeles\", :b => tz\"America/New_York\")), Set((ip\"0.0.0.0\", ip\"127.0.0.1\")), DateTime(2024, 1, 25))\nC(\n  timezones = Dictionary( :a => America/Los_Angeles, :b => America/New_York )\n  ips       = { 0.0.0.0, 127.0.0.1 }\n  dt        = 2024-01-25T00:00:00\n)","category":"page"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"If you'd like more control over the generated layout behaviour for an object than the default provided by @def_pprint, you can define your own via the @custom_tile macro as follows.","category":"page"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"julia> struct D \n           value::Int\n       end\n\njulia> @custom_tile mime_types=\"text/plain\" base_show=true D => AutoPrettyPrinting.literal(\"CustomD $(_obj_.value^2)\")\n\njulia> d = D(10)\nCustomD 100","category":"page"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"You can register your own MIME types with this package using the @mime_type macro. Subsequent calls to @custom_tile or @def_pprint without a mime_types argument specified will use all of the mime types previously defined. ","category":"page"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"julia> @mime_type \"text/testing\"\n","category":"page"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"julia> struct E \n           value::Int\n       end\n\njulia> @custom_tile base_show=true E => AutoPrettyPrinting.literal(\"CustomE $(_obj_.value-1) - $(_mime_)\")\n\njulia> e = E(10)\nCustomE 9 - text/plain\n\njulia> repr(MIME(\"text/plain\"), e), repr(MIME(\"text/testing\"), e)\n(\"CustomE 9 - text/plain\", \"CustomE 9 - text/testing\")","category":"page"},{"location":"examples/","page":"Example Usage","title":"Example Usage","text":"note: Note\nPrior to the registration of the \"text/testing\" mime type above, the previously defined layout methods for, e.g., type D, would only have been generated for the \"text/plain\" MIME type. julia> repr(MIME(\"text/testing\"), d)\nERROR: MethodError: no method matching show(::IOBuffer, ::MIME{Symbol(\"text/testing\")}, ::D)","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = AutoPrettyPrinting","category":"page"},{"location":"#AutoPrettyPrinting","page":"Home","title":"AutoPrettyPrinting","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The AutoPrettyPrinting package provides macros that remove much of the boilerplate involved in defining pretty printing methods for custom types. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"Most of this package involves manipulating the layout representations provided by PrettyPrinting.jl, along with some additional logic to nicely render containers + composite fields. ","category":"page"}]
}
