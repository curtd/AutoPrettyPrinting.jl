module AutoPrettyPrinting

    using Dates, Sockets
    using MacroUtilities, PrettyPrinting, ScopedValues
    import PrettyPrinting: literal, Layout

    export KeyValue 
    
    export @mime_type, @custom_tile, @def_pprint, @hide_typename, @def_pprint_atomic

    const PPRINT_NESTED_LEVEL = ScopedValue{Int}(0)
    const PPRINT_PARENT_IS_CONTAINER = ScopedValue{Bool}(false)
    const PPRINT_SHOW_TYPENAME = ScopedValue{Bool}(true)

    include("mime_types.jl")
    include("auto_layout.jl")
    include("prettyprinting.jl")
    include("code_generation.jl")
    include("auto_prettyprinting.jl")
end 
