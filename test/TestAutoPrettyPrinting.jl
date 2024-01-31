module TestAutoPrettyPrinting 
    using AutoPrettyPrinting
    using Dictionaries, Dates, Sockets
    using JET, Test, TestingUtilities 

    import AutoPrettyPrinting: literal

    @Test Set(AutoPrettyPrinting.mime_types_to_generate()) == Set((Symbol("text/plain"), ))

    @mime_type "text/test_auto_pretty_printing"

    @Test Set(AutoPrettyPrinting.mime_types_to_generate()) == Set((Symbol("text/plain"), Symbol("text/test_auto_pretty_printing")))

    mime_plain = MIME("text/plain")
    mime_testing = MIME("text/test_auto_pretty_printing")
    mime_testing2 = MIME("text/test_auto_pretty_printing2")

    struct SimpleStruct1 
        key1::Int
    end
    @custom_tile mime_types="text/test_auto_pretty_printing" base_show=true SimpleStruct1 => literal(string(_obj_.key1*2))

    struct SimpleStruct2
        key1::Int
        key2::String
    end

    @def_pprint mime_types="text/test_auto_pretty_printing" base_show=true SimpleStruct2

    struct TooManyFields
        key1::Int
        key2::Int
        key3::Int
        key4::Int
        key5::Int
    end
    @def_pprint mime_types="text/plain" base_show=false TooManyFields

    struct TupleFields 
        t::Tuple 
        nt::NamedTuple
    end

    @def_pprint base_show=true TupleFields

    struct AllMimeTypes 
        t::Tuple 
    end
    @def_pprint generic_mime=true base_show=true AllMimeTypes

    @custom_tile mime_types="text/test_auto_pretty_printing2" base_show=true AllMimeTypes => literal("AllMimeTypes - $(_mime_)")

    struct AtomicType 
        value::Int 
    end

    @def_pprint_atomic mime_types="" AtomicType 

    struct CustomTileFunc
        value::Int
    end
    @custom_tile base_show=true CustomTileFunc => (p, mime::MIME"text/plain") -> literal("CustomTileFunc($(p.value^2))")
    @custom_tile base_show=true CustomTileFunc => (p, mime::MIME"text/test_auto_pretty_printing") -> literal("CustomTileFunc($(p.value-1))")

    struct VertAligned 
        values::Vector{Pair{Symbol, Int}}
    end
    @custom_tile base_show=true VertAligned => (p, mime::MIME"text/plain") -> AutoPrettyPrinting.custom_tile_vert_aligned(p.values, mime)

    struct VertAlignedKV
        values::Vector{KeyValue{Symbol, Int}}
    end
    @custom_tile base_show=true VertAlignedKV => (p, mime::MIME"text/plain") -> AutoPrettyPrinting.custom_tile_vert_aligned(p.values, mime)

    @testset "AutoPrettyPrinting" begin 
        include("tests/test_util.jl")
        include("tests/test_macros.jl")
        include("tests/test_printing.jl")
    end
   
end