# Source functions for this {targets} list
tar_source("a_Calculate_Centers/src/")


# Calculate POI Centers for all US and Territories Lakes -------------

# This {targets} list calculates "Point of Inaccessibility", also known as Cheybyshev 
# Center for all lakes/reservoirs/impoundments greater than 1ha in surface area 
# using the NHDPlus polygons using the {nhdplusTools} package and the `poi()` 
# function in the {polylabelr} package. At some point, this workflow will need
# to be updated to the new USGS 3DHP data, but that isn't complete right now. 
# Additionally, we are intentionally using NHDPlusV2 instead of NHDPlusHR because
# of computational time within the scope of this workflow. For HUC4s that are not
# included in the NHDPlusV2, we access the NHD Best Resolution product directly
# from the NHD from the National Map url.

# create list of targets to perform this task
a_Calculate_Centers_list <- list(
  tar_target(
    name = a_check_dir_structure,
    command = {
      # make directories if needed
      directories = c("a_Calculate_Centers/mid/",
                      "a_Calculate_Centers/nhd/",
                      "a_Calculate_Centers/out/")
      walk(directories, function(dir) {
        if(!dir.exists(dir)){
          dir.create(dir)
        }
      })
    },
    cue = tar_cue("always"),
    deployment = "main"
    ),
  
  # get {sf}s for all US states and territories from {tigris} to grab all the HUC4s
  tar_target(
    name = a_US_states_territories,
    command = states() %>% st_make_valid(),
    packages = c("tigris", "sf", "tidyverse")
    ),
  
  # for each state/territory, get a list of HUC4s
  # while this is not the most efficient (HUC4s cross state boundaries),
  # this is a good framework to break up HUC acquisition. If you run on the 
  # boundary of the US, this will completely fail and timeout.
  tar_target(
    name = a_HUC4_dataframe,
    command = get_huc(a_US_states_territories, type = "huc04") %>% 
      st_drop_geometry(),
    packages = c("nhdplusTools", "sf", "tidyverse"),
    pattern = map(a_US_states_territories)
  ),
  
  # get distinct HUC4s as a list from the previous target
  tar_target(
    name = a_HUC4_list,
    command = a_HUC4_dataframe %>% 
      pull("huc4") %>% 
      unique(),
    packages = "tidyverse",
    deployment = "main"
  ),
  
  # now filter out for HUC4s that are in CONUS (and have NHDPlusV2 waterbodies)
  tar_target(
    name = a_CONUS_HUC4,
    command = a_HUC4_list[as.numeric(a_HUC4_list) < 1900],
    deployment = "main"
  ),
  
  # for each HUC4, grab the NHDPlus waterbodies, subset to lakes/res/
  # impoundments, subset to >= 1ha, and calculate POI for each polygon
  # run time for this target is ~ 45 min - 1 hour
  tar_target(
    name = a_CONUS_poi,
    command = {
      # need to make sure that the directory structure has been created prior
      # to running this target
      a_check_dir_structure
      calculate_centers_HUC4(a_CONUS_HUC4)
      },
    packages = c("nhdplusTools", "sf", "tidyverse", "polylabelr", "rmapshaper"),
    pattern = map(a_CONUS_HUC4)
  ),
  
  # and then grab the non-CONUS HUC4s
  tar_target(
    name = a_nonCONUS_HUC4,
    command = a_HUC4_list[as.numeric(a_HUC4_list) >= 1900],
    deployment = "main"
  ),
  
  # now download the NHD Best Resolution file from the National Map, filter
  # waterbodies, and calculate POIs
  # run time for this target is > 1h
  tar_target(
    name = a_nonCONUS_poi,
    command = {
      # need to make sure that the directory structure has been created prior
      # to running this target
      a_check_dir_structure
      calculate_bestres_centers(a_nonCONUS_HUC4)
      },
    packages = c("tidyverse", "sf", "polylabelr"),
    pattern = map(a_nonCONUS_HUC4)
  ), 
  
  # and now we'll join together the two POI files, retaining source information
  # and the unique identifier from NHD
  tar_target(
    name = a_combined_poi,
    command = {
      CONUS <- a_CONUS_poi %>% 
        mutate(nhd_source = "NHDPlusv2")
      nonCONUS <- a_nonCONUS_poi %>% 
        mutate(nhd_source = "NHDBestRes")
      full_join(CONUS, nonCONUS) %>% 
        mutate(nhd_id = if_else(!is.na(comid), comid, permanent_identifier)) %>% 
        select(-c(comid, permanent_identifier))
    },
    packages = c("tidyverse", "feather"),
    deployment = "main"
  )
)
