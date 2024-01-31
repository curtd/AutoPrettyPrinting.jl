@testset "Macros" begin 
    @testset "@custom_tile" begin 
        s = SimpleStruct1(1)
        @Test repr(mime_plain, s) == "$SimpleStruct1(1)"
        @Test repr(mime_testing, s) == "2"

        s = CustomTileFunc(10)
        @Test repr(mime_plain, s) == "CustomTileFunc(100)"
        @Test repr(mime_testing, s) == "CustomTileFunc(9)"
        @Test AutoPrettyPrinting.custom_tile(s, mime_plain) == literal("CustomTileFunc(100)")
        @Test AutoPrettyPrinting.custom_tile_horiz(s, mime_plain) == literal("CustomTileFunc(100)")
        @Test AutoPrettyPrinting.custom_tile_vert(s, mime_plain) == literal("CustomTileFunc(100)")

        @Test AutoPrettyPrinting.custom_tile(s, mime_testing) == literal("CustomTileFunc(9)")
        @Test AutoPrettyPrinting.custom_tile_horiz(s, mime_testing) == literal("CustomTileFunc(9)")
        @Test AutoPrettyPrinting.custom_tile_vert(s, mime_testing) == literal("CustomTileFunc(9)")
        
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
    @testset "@decorators" begin 
        v = [CustomTileFunc(2), CustomTileFunc(3)]
        printed = @decorators separators=(horiz="_") parentheses=(vector=("<",">")) repr_pretty(mime_plain, v)
        @Test printed == "<CustomTileFunc(4)_CustomTileFunc(9)>"
        printed = repr_pretty(mime_plain, v)
        @Test printed == "[CustomTileFunc(4), CustomTileFunc(9)]"

        v = [:key1 => CustomTileFunc(2), :key2 => CustomTileFunc(3)]
        printed = @decorators separators=(pair="->") parentheses=(vector=("] "," [")) repr_pretty(mime_plain, v)
        @Test printed == "] :key1->CustomTileFunc(4), :key2->CustomTileFunc(9) ["

        v = Dict(:key1 => CustomTileFunc(2))
        printed = @decorators separators=(pair="->") parentheses=(dict=("[","]")) repr_pretty(mime_plain, v)
        @Test printed == "Dict[ :key1->CustomTileFunc(4) ]"

        v = Set([CustomTileFunc(2)])
        printed = @decorators parentheses=(set=("[","]")) repr_pretty(mime_plain, v)
        @Test printed == "[ CustomTileFunc(4) ]"

        v = tuple(CustomTileFunc(2), CustomTileFunc(3))
        printed = @decorators separators=(horiz="_") parentheses=(tuple=("[","]")) repr_pretty(mime_plain, v)
        @Test printed == "[CustomTileFunc(4)_CustomTileFunc(9)]"

        v = (; key1=CustomTileFunc(2), key2=CustomTileFunc(3))
        printed = @decorators parentheses=(named_tuple=("[","]")) repr_pretty(mime_plain, v)
        @Test printed == "[key1 = CustomTileFunc(4), key2 = CustomTileFunc(9)]"

        v = KeyValue(:key1, CustomTileFunc(2))
        printed = @decorators separators=(kv=">>") repr_pretty(mime_plain, v)
        @Test printed == "key1>>CustomTileFunc(4)"
    end

end