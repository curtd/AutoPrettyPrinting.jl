# AutoPrettyPrinting

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://curtd.github.io/AutoPrettyPrinting.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://curtd.github.io/AutoPrettyPrinting.jl/dev/)
[![Build Status](https://github.com/curtd/AutoPrettyPrinting.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/curtd/AutoPrettyPrinting.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage Status](https://coveralls.io/repos/github/curtd/AutoPrettyPrinting.jl/badge.svg)](https://coveralls.io/github/curtd/AutoPrettyPrinting.jl)

The goal of `AutoPrettyPrinting` is to remove some of the tedium of rolling your own custom pretty printing code for your custom types. To a given object `x`, this package associates a horizontally-oriented layout (akin to the default `Base.show` layout) as well as a vertically-oriented layout. The choice of whether to use one or both of these layouts when rendering an object `x` is made dynamically, both by the heuristics defined in this package, as well as of the dynamic block choice given in . 

`AutoPrettyPrinting` provides macros that enable straightforward pretty printing of custom types using [`PrettyPrinting.jl`](https://github.com/MechanicalRabbit/PrettyPrinting.jl). Custom pretty printing code can be specified on a per-`MIME` type basis and, for a given type, can either be automatically generated using the `@def_pprint` macro or custom-provided by the user with the `@custom_tile` macro. 

## Examples
```julia
julia> using AutoPrettyPrinting

julia> struct A 
           key1::Int 
           key2::String
       end

julia> @def_pprint mime_types="text/plain" base_show=true A

julia> a = A(10, "abcd")
A(key1 = 10, key2 = abcd)
```
