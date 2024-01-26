```@meta
CurrentModule = AutoPrettyPrinting
```

# AutoPrettyPrinting

The [AutoPrettyPrinting](https://github.com/curtd/AutoPrettyPrinting.jl) package provides macros that remove much of the boilerplate involved in defining pretty printing methods for custom types. 

Most of this package involves manipulating the layout representations provided by [PrettyPrinting.jl](https://github.com/MechanicalRabbit/PrettyPrinting.jl), along with some additional logic to nicely render containers + composite fields. 
