# API 

## Macros
```@docs 
@mime_type 
@custom_tile
@def_pprint
@def_pprint_atomic
@hide_typename
@decorators
```

## Functions 
```@docs 
AutoPrettyPrinting.custom_tile(x, mime::MIME; kwargs...)
AutoPrettyPrinting.custom_tile_horiz(x, mime::MIME; kwargs...)
AutoPrettyPrinting.custom_tile_vert(x, mime::MIME; kwargs...)
AutoPrettyPrinting.pprint(io::IO, mime::MIME, obj)
repr_pretty
```

## Types 
```@docs 
KeyValue
PPrintContext
```