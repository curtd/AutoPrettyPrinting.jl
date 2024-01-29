using Test, Documenter, AutoPrettyPrinting 

DocMeta.setdocmeta!(AutoPrettyPrinting, :DocTestSetup, :(using AutoPrettyPrinting); recursive=true)

@testset "DocTests" begin 
    withenv("LINES" => "77", "COLUMNS" => "80") do 
        doctest(AutoPrettyPrinting)
    end
end