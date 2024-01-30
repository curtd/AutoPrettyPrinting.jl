module TestAutoPrettyPrinting 
    using AutoPrettyPrinting
    using JET, Test, TestingUtilities 

    struct SimpleStruct1 
        key1::Int
    end

    struct SimpleStruct2
        key1::Int
        key2::String
    end
    struct TooManyFields
        key1::Int
        key2::Int
        key3::Int
        key4::Int
        key5::Int
    end
    struct TupleFields 
        t::Tuple 
        nt::NamedTuple
    end
    struct AllMimeTypes 
        t::Tuple 
    end
    struct AtomicType 
        value::Int 
    end

    @Test Set(AutoPrettyPrinting.mime_types_to_generate()) == Set((Symbol("text/plain"), ))

    @mime_type "text/test_auto_pretty_printing"

    @Test Set(AutoPrettyPrinting.mime_types_to_generate()) == Set((Symbol("text/plain"), Symbol("text/test_auto_pretty_printing")))

    @custom_tile mime_types="text/test_auto_pretty_printing" base_show=true SimpleStruct1 => AutoPrettyPrinting.literal(string(_obj_.key1*2))
    @def_pprint mime_types="text/test_auto_pretty_printing" base_show=true SimpleStruct2

    @def_pprint mime_types="text/plain" base_show=false TooManyFields
    @def_pprint generic_mime=true base_show=true AllMimeTypes
    @custom_tile mime_types="text/test_auto_pretty_printing2" base_show=true AllMimeTypes => AutoPrettyPrinting.literal("AllMimeTypes - $(_mime_)")

    @def_pprint base_show=true TupleFields

    mime_plain = MIME("text/plain")
    mime_testing = MIME("text/test_auto_pretty_printing")
    mime_testing2 = MIME("text/test_auto_pretty_printing2")

    @def_pprint_atomic mime_types="" AtomicType 

    @testset "AutoPrettyPrinting" begin 
        @testset "Utilities" begin 
            @test_cases begin 
                x                                    |   output
                SimpleStruct1(1)                     | true 
                SimpleStruct2(1, "abc")              | true 
                TooManyFields(1,2,3,4,5)             | false 
                TupleFields((1,2), (; key1=1))       | true 
                TupleFields((1,2,3,4,5), (; key1=1)) | false
                @test AutoPrettyPrinting.is_simple_struct(x) == output
            end
            show_typename = AutoPrettyPrinting.PPRINT_SHOW_TYPENAME[]
            @Test show_typename
            show_typename = @hide_typename AutoPrettyPrinting.PPRINT_SHOW_TYPENAME[]
            @Test !show_typename
            show_typename = AutoPrettyPrinting.PPRINT_SHOW_TYPENAME[]
            @Test show_typename
        end
        @Test AutoPrettyPrinting.normalize_mime_type_args(["text/plain"]; generic_mime=true) isa AutoPrettyPrinting.GenericMimeType
        @Test AutoPrettyPrinting.normalize_mime_type_args(nothing; generic_mime=true) isa AutoPrettyPrinting.GenericMimeType
        @Test AutoPrettyPrinting.normalize_mime_type_args(["text/plain"]; generic_mime=false) == [Symbol("text/plain")]
        @Test AutoPrettyPrinting.normalize_mime_type_args([""]; generic_mime=false) == Symbol[]
        @Test AutoPrettyPrinting.normalize_mime_type_args(nothing; generic_mime=false) == AutoPrettyPrinting.mime_types_to_generate()
    end
    @testset "@custom_tile" begin 
        s = SimpleStruct1(1)
        @Test repr(mime_plain, s) == "$SimpleStruct1(1)"
        @Test repr(mime_testing, s) == "2"
    end
    @testset "@def_pprint" begin 
        s = SimpleStruct2(1, "abc")
        @Test repr(mime_plain, s) == "$SimpleStruct2(1, \"abc\")"
        @Test repr(mime_testing, s) == "SimpleStruct2(key1 = 1, key2 = \"abc\")"

        t = AllMimeTypes(tuple(s))
        @Test repr(mime_plain, t) == "AllMimeTypes(t = ($SimpleStruct2(1, \"abc\")))"
        @Test repr(mime_testing, t) == "AllMimeTypes(t = (SimpleStruct2(key1 = 1, key2 = \"abc\")))"
        @Test repr(mime_testing2, t) == "AllMimeTypes - text/test_auto_pretty_printing2"

    end
    @testset "@def_pprint_atomic" begin 
        @Test AutoPrettyPrinting._is_atomic_type(AtomicType)
        
    end
    @testset "Printing" begin 
        @testset "Tuples + NamedTuples" begin 
            x = SimpleStruct1(1)
            y = SimpleStruct2(2, "b")
            t = tuple(x, y)
            @Test repr_pretty(mime_testing, t) == "(2, SimpleStruct2(key1 = 2, key2 = \"b\"))"

            z = TupleFields(t, (; key1=1:3))
             # Original text/plain mime show has not been overwritten
            @Test repr("text/plain", z) == """TupleFields(t = ($SimpleStruct1(1), $SimpleStruct2(2, "b")), nt = (; key1 = [1, 2, 3]))"""
            @Test repr("text/test_auto_pretty_printing", z) == """TupleFields(t = (2, SimpleStruct2(key1 = 2, key2 = "b")), nt = (; key1 = [1, 2, 3]))"""

            # Original text/plain mime show has not been overwritten
            x = TooManyFields(1,2,3,4,5)
            @Test repr("text/plain", x) == "$TooManyFields(1, 2, 3, 4, 5)"

            t = (; x=x)
            ref_repr = """(; x = TooManyFields(key1 = 1, key2 = 2, key3 = 3, key4 = 4, key5 = 5))"""
            @Test repr("text/plain", t) == "(x = $TooManyFields(1, 2, 3, 4, 5),)"
            @Test repr_pretty(t)  == ref_repr
        end 
        @testset "PrintContext" begin 
            x = TooManyFields(1,2,3,4,5)
            io = IOBuffer()
            context = PPrintContext(io)
            show(context, mime_plain, x)
            str = String(take!(io))
            ref_repr = "TooManyFields(\n  key1 = 1\n  key2 = 2\n  key3 = 3\n  key4 = 4\n  key5 = 5\n)"
            @Test str == ref_repr
            @Test repr_pretty(x) == ref_repr
        end

    end
end