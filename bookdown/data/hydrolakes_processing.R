# hydrolakes v10 downloaded from https://www.hydrosheds.org/products/hydrolakes#downloads
hydrolakes <- read_sf("/Users/steeleb/Downloads/HydroLAKES_polys_v10.gdb/HydroLAKES_polys_v10.gdb/")
hydrolakes <- st_make_valid(hydrolakes)
not_valid <- hydrolakes[!st_is_valid(hydrolakes), ]
valid_hydrolakes <- hydrolakes %>% filter(!Hylak_id %in% not_valid$Hylak_id)
WI_hydrolakes <- valid_hydrolakes[WI, ]
write_sf(WI_hydrolakes, "bookdown/data/WI_hydrolakes.gpkg")
