@testset "Printing" begin 
    @testset "Atomic types" begin 
        @Test repr_pretty(mime_plain, Date(2024, 1, 1)) == "2024-01-01"
        @Test repr_pretty(mime_plain, DateTime(2024, 1, 1, 12, 30)) == "2024-01-01T12:30:00"
        @Test repr_pretty(mime_plain, Time(12, 31)) == "12:31:00"
        @Test repr_pretty(mime_plain, ip"127.0.0.1") == "127.0.0.1"
        @Test repr_pretty(mime_plain, ip"::") == "::"
    end
    @testset "Pairs + KeyValues" begin 
        x = CustomTileFunc(2)
        @Test repr_pretty(:x => x) == ":x => CustomTileFunc(4)"
        @Test repr_pretty(mime_testing, :x => x) == ":x => CustomTileFunc(1)"

        @Test repr_pretty(KeyValue(:x, x)) == "x = CustomTileFunc(4)"
        @Test repr_pretty(KeyValue("x", x)) == "x = CustomTileFunc(4)"
        @Test repr_pretty(mime_testing, KeyValue(:x, x)) == "x = CustomTileFunc(1)"
        @Test repr_pretty(mime_testing, KeyValue("x", x)) == "\"x\" = CustomTileFunc(1)"
    end
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
    @testset "Dictionaries" begin 
        d = dictionary((i => CustomTileFunc(i) for i in 1:3))
        @Test repr_pretty(mime_plain, d) == "Dictionary( 1 => CustomTileFunc(1), 2 => CustomTileFunc(4), 3 => CustomTileFunc(9) )"
        @Test repr_pretty(mime_testing, d) == "Dictionary( 1 => CustomTileFunc(0), 2 => CustomTileFunc(1), 3 => CustomTileFunc(2) )"
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