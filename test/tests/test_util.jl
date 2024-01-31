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

    @Test AutoPrettyPrinting.normalize_mime_type_args(["text/plain"]; generic_mime=true) isa AutoPrettyPrinting.GenericMimeType
    @Test AutoPrettyPrinting.normalize_mime_type_args(nothing; generic_mime=true) isa AutoPrettyPrinting.GenericMimeType
    @Test AutoPrettyPrinting.normalize_mime_type_args(["text/plain"]; generic_mime=false) == [Symbol("text/plain")]
    @Test AutoPrettyPrinting.normalize_mime_type_args([""]; generic_mime=false) == Symbol[]
    @Test AutoPrettyPrinting.normalize_mime_type_args(nothing; generic_mime=false) == AutoPrettyPrinting.mime_types_to_generate()
end
@testset "Expr parsing" begin 
    @test_cases begin 
        expr        |       result 
        (expr=:(MIME), result=AutoPrettyPrinting.GenericMimeType())
        (expr=:(MIME"text/plain"), result="text/plain")
        (expr=:(MIME{Symbol("text/plain")}), result="text/plain")
        (expr=:(MIME{:a}), result="a")
        @test AutoPrettyPrinting.mime_from_type_expr(expr) == result
    end
    expr = :((p, mime)->literal(p))
    obj_arg, mime_arg, tile_expr, mime_types, generic_mime = AutoPrettyPrinting.custom_tile_func_def_expr(expr, nothing, false)
    @Test obj_arg == :p 
    @Test mime_arg == :mime 
    @Test tile_expr === expr.args[2]
    @Test mime_types |> isnothing 
    @Test generic_mime == false 

    expr = :((p, mime::MIME)->literal(p))
    obj_arg, mime_arg, tile_expr, mime_types, generic_mime = AutoPrettyPrinting.custom_tile_func_def_expr(expr, nothing, false)
    @Test obj_arg == :p 
    @Test mime_arg == :mime 
    @Test tile_expr === expr.args[2]
    @Test mime_types |> isnothing 
    @Test generic_mime == true

    expr = :((_p, _mime::MIME"text/plain")->literal(_p))
    obj_arg, mime_arg, tile_expr, mime_types, generic_mime = AutoPrettyPrinting.custom_tile_func_def_expr(expr, nothing, false)
    @Test obj_arg == :_p 
    @Test mime_arg == :_mime 
    @Test tile_expr === expr.args[2]
    @Test mime_types == ["text/plain"]
    @Test generic_mime == false

end