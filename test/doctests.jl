using Test, Documenter, AutoPrettyPrinting 

DocMeta.setdocmeta!(AutoPrettyPrinting, :DocTestSetup, :(using AutoPrettyPrinting); recursive=true)

doctest(AutoPrettyPrinting, manual=joinpath(pkgdir(AutoPrettyPrinting), "docs/src"))