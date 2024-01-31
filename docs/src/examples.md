```@meta
DocTestSetup = nothing
```

# Example usage 
## Basic package macros
If we're not particular about the particular layout or format of the pretty printing layouts of our custom types, we can use the `@def_pprint` macro to define our `Base.show` method for the default `"text/plain"` MIME type.

```jldoctest examples
julia> using AutoPrettyPrinting

julia> struct A 
           key1::Int 
           key2::String
       end

julia> @def_pprint mime_types="text/plain" base_show=true A

julia> a = A(10, "abcd")
A(key1 = 10, key2 = abcd)
```

Once we've registered a custom type `A` with this package, we can also register custom types that use `A` as a sub-field

```jldoctest examples 
julia> struct B 
           data::Vector{A}
       end

julia> @def_pprint mime_types="text/plain" base_show=true B 

julia> b = B([A(i, "a"^i) for i in 1:10])
B(
  data = [
           A(key1 = 1, key2 = a)
           A(key1 = 2, key2 = aa)
           A(key1 = 3, key2 = aaa)
           A(key1 = 4, key2 = aaaa)
           A(key1 = 5, key2 = aaaaa)
           A(key1 = 6, key2 = aaaaaa)
           A(key1 = 7, key2 = aaaaaaa)
           A(key1 = 8, key2 = aaaaaaaa)
           A(key1 = 9, key2 = aaaaaaaaa)
           A(key1 = 10, key2 = aaaaaaaaaa)
         ]
)
```

Internal heuristics defined in this package automatically use a more compact representation when the objects don't contain too many elements and are sufficient simple.

```jldoctest examples
julia> b = B([A(i, "a"^i) for i in 1:2])
B(data = [A(key1 = 1, key2 = a), A(key1 = 2, key2 = aa)])
```

Out of the box, `AutoPrettyPrinting` supports rendering of `AbstractVector`, `AbstractDict`, and `AbstractSet` types. Via package extensions, `AbstractDictionary` objects from [`Dictionaries.jl`](https://github.com/andyferris/Dictionaries.jl), and types from [`TimeZones.jl`](https://github.com/JuliaTime/TimeZones.jl) and from the `Dates` and `Sockets` standard library packages are also supported.

```jldoctest examples 
julia> using Dates, Dictionaries, Sockets, TimeZones

julia> struct C
           timezones::Dictionary{Symbol, TimeZone}
           ips::Set{IPv4}
           dt::DateTime
       end

julia> @def_pprint mime_types="text/plain" base_show=true C

julia> c = C(dictionary((:a => tz"America/Los_Angeles", :b => tz"America/New_York")), Set((ip"0.0.0.0", ip"127.0.0.1")), DateTime(2024, 1, 25))
C(
  timezones = Dictionary( :a => America/Los_Angeles, :b => America/New_York )
  ips       = { 0.0.0.0, 127.0.0.1 }
  dt        = 2024-01-25T00:00:00
)
```

If you'd like more control over the generated layout behaviour for an object than the default provided by `@def_pprint`, you can define your own via the `@custom_tile` macro as follows.

```jldoctest examples 
julia> struct D 
           value::Int
       end

julia> @custom_tile mime_types="text/plain" base_show=true D => AutoPrettyPrinting.literal("CustomD $(_obj_.value^2)")

julia> d = D(10)
CustomD 100
```

You can register your own `MIME` types with this package using the `@mime_type` macro. Subsequent calls to `@custom_tile` or `@def_pprint` without a `mime_types` argument specified will use all of the mime types previously defined. 

```jldoctest examples 
julia> @mime_type "text/testing"

```
```jldoctest examples
julia> struct E 
           value::Int
       end

julia> @custom_tile base_show=true E => AutoPrettyPrinting.literal("CustomE $(_obj_.value-1) - $(_mime_)")

julia> e = E(10)
CustomE 9 - text/plain

julia> repr(MIME("text/plain"), e), repr(MIME("text/testing"), e)
("CustomE 9 - text/plain", "CustomE 9 - text/testing")
```

!!! note
    Prior to the registration of the `"text/testing"` mime type above, the previously defined layout methods for, e.g., type `D`, would only have been generated for the `"text/plain"` MIME type. 

    ```jldoctest examples 
    julia> repr(MIME("text/testing"), d)
    ERROR: MethodError: no method matching show(::IOBuffer, ::MIME{Symbol("text/testing")}, ::D)
    ```
