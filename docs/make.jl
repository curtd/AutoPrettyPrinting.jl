using Pkg
#src_dir = abspath(joinpath(@__DIR__, ".."))
#Pkg.develop(path=src_dir)

using AutoPrettyPrinting
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Documenter
using AutoPrettyPrinting

DocMeta.setdocmeta!(AutoPrettyPrinting, :DocTestSetup, :(using AutoPrettyPrinting); recursive=true)
withenv("LINES" => "77", "COLUMNS" => "80") do 
    makedocs(;
        modules=[AutoPrettyPrinting],
        authors="Curt Da Silva",
        repo="https://github.com/curtd/AutoPrettyPrinting.jl/blob/{commit}{path}#{line}",
        sitename="AutoPrettyPrinting.jl",
        format=Documenter.HTML(;
            prettyurls=get(ENV, "CI", "false") == "true",
            canonical="https://curtd.github.io/AutoPrettyPrinting.jl",
            edit_link="main",
            assets=String[],
            ansicolor=true
        ),
        pages=[
            "Home" => "index.md",
            "Example Usage" => "examples.md",
            "API" => "api.md"
        ],
        warnonly=:missing_docs
    )
end
deploydocs(;
    repo="github.com/curtd/AutoPrettyPrinting.jl",
    devbranch="main", push_preview=true
)
