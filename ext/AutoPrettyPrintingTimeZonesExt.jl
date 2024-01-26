module AutoPrettyPrintingTimeZonesExt
    using AutoPrettyPrinting, TimeZones 

    @def_pprint_atomic all_mime_types=true TimeZones.TimeZone
end