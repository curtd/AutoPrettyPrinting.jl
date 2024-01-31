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

## Layout/Printing

### Functions
```@docs 
AutoPrettyPrinting.custom_tile(x, mime::MIME; kwargs...)
AutoPrettyPrinting.custom_tile_horiz(x, mime::MIME; kwargs...)
AutoPrettyPrinting.custom_tile_vert(x, mime::MIME; kwargs...)
AutoPrettyPrinting.pprint(io::IO, mime::MIME, obj)
repr_pretty
```

### Types 
```@docs 
KeyValue
PPrintContext
```

## Code Generation
### Functions
```@docs 
AutoPrettyPrinting.per_property_pprint_exprs
```

### Types 
```@docs
AutoPrettyPrinting.GenericMimeType
```

