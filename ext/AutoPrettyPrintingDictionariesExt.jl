module AutoPrettyPrintingDictionariesExt
    using AutoPrettyPrinting, Dictionaries 

    AutoPrettyPrinting.should_allow_horiz(x::AbstractDictionary) = AutoPrettyPrinting.should_allow_horiz_container(x)
    AutoPrettyPrinting.should_allow_vert(x::AbstractDictionary) = AutoPrettyPrinting.should_allow_vert_container(x)

    AutoPrettyPrinting.should_sort_keys((@nospecialize x::AbstractDictionary)) = false
    AutoPrettyPrinting.custom_tile_horiz(x::AbstractDictionary, mime::MIME; kwargs...) = AutoPrettyPrinting.custom_tile_horiz_dict(x, mime; kwargs...)
    AutoPrettyPrinting.custom_tile_vert(x::AbstractDictionary, mime::MIME; kwargs...) = AutoPrettyPrinting.custom_tile_vert_dict(x, mime; kwargs...)
    AutoPrettyPrinting.custom_tile(x::AbstractDictionary, mime::MIME; kwargs...) = AutoPrettyPrinting.custom_tile_container(x, mime; kwargs...)


end