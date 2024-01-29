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

    @Test Set(AutoPrettyPrinting.mime_types_to_generate()) == Set((Symbol("text/plain"), ))

    @mime_type "text/test_auto_pretty_printing"

    @Test Set(AutoPrettyPrinting.mime_types_to_generate()) == Set((Symbol("text/plain"), Symbol("text/test_auto_pretty_printing")))

    @custom_tile mime_types="text/test_auto_pretty_printing" base_show=true SimpleStruct1 => AutoPrettyPrinting.literal(string(_obj_.key1*2))
    @def_pprint mime_types="text/test_auto_pretty_printing" base_show=true SimpleStruct2

    @def_pprint mime_types="text/plain" base_show=false TooManyFields

    @testset "AutoPrettyPrinting" begin 
        @testset "Utilities" begin 
            @test_cases begin 
                T             |   output
                SimpleStruct1 | true 
                SimpleStruct2 | true 
                TooManyFields | false 
                @test AutoPrettyPrinting.is_simple_struct(T) == output
            end
            show_typename = AutoPrettyPrinting.PPRINT_SHOW_TYPENAME[]
            @Test show_typename
            show_typename = @hide_typename AutoPrettyPrinting.PPRINT_SHOW_TYPENAME[]
            @Test !show_typename
            show_typename = AutoPrettyPrinting.PPRINT_SHOW_TYPENAME[]
            @Test show_typename
        end
    end
    @testset "@custom_tile" begin 
        s = SimpleStruct1(1)
        @Test repr(MIME("text/plain"), s) == "$SimpleStruct1(1)"
        @Test repr(MIME("text/test_auto_pretty_printing"), s) == "2"
    end
    @testset "@def_pprint" begin 
        s = SimpleStruct2(1, "abc")
        @Test repr(MIME("text/plain"), s) == "$SimpleStruct2(1, \"abc\")"
        @Test repr(MIME("text/test_auto_pretty_printing"), s) == "SimpleStruct2(key1 = 1, key2 = abc)"
    end
    @testset "Printing" begin 
        x = TooManyFields(1,2,3,4,5)
        @Test repr("text/plain", x) == "$TooManyFields(1, 2, 3, 4, 5)"

        io = IOBuffer()
        context = PPrintContext(io)
        show(context, MIME("text/plain"), x)
        str = String(take!(io))
        ref_repr = "TooManyFields(\n  key1 = 1\n  key2 = 2\n  key3 = 3\n  key4 = 4\n  key5 = 5\n)"
        @Test str == ref_repr
        @Test repr_pretty(x) == ref_repr


    end
end