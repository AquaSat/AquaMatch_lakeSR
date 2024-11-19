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
    cue = tar_cue("always")
    ),
  
  # get {sf}s for all US states and territories from {tigris} to grab all the HUC4s
  tar_target(
    name = US_states_territories,
    command = states() %>% st_make_valid(),
    packages = c("tigris", "sf", "tidyverse")
    ),
  
  # for each state/territory, get a list of HUC4s
  # while this is not the most efficient (HUC4s cross state boundaries),
  # this is a good framework to break up HUC acquisition. If you run on the 
  # boundary of the US, this will completely fail and timeout.
  tar_target(
    name = HUC4_dataframe,
    command = get_huc(US_states_territories, type = "huc04") %>% 
      st_drop_geometry(),
    packages = c("nhdplusTools", "sf", "tidyverse"),
    pattern = map(US_states_territories)
  ),
  
  # get distinct HUC4s as a list from the previous target
  tar_target(
    name = HUC4_list,
    command = HUC4_dataframe %>% 
      distinct() %>% 
      pull("huc4"),
    packages = "tidyverse"
  ),
  
  # for each HUC4, grab the NHDPlus waterbodies, subset to lakes/res/
  # impoundments, subset to >= 1ha, and calculate POI for each polygon
  # run time for this target is ~ 45 min
  tar_target(
    name = NHD_poi_points,
    command = {
      # need to make sure that the directory structure has been created prior
      # to running this target
      a_check_dir_structure
      calculate_centers_HUC4(HUC4_list)
      },
    packages = c("nhdplusTools", "sf", "tidyverse", "polylabelr", "rmapshaper"),
    pattern = map(HUC4_list)
  ),
  
  # Using the HUC list where there were no waterbodies (HI, Guam, AK, etc),
  # get a list of states to download the NHD Best Resolution from the National
  # Map using a url.
  tar_target(
    name = need_wbd_HUC4,
    command = {
      NHD_poi_points
      read_lines("a_Calculate_Centers/mid/no_wbd_huc4.txt")
    },
    packages = c("tidyverse", "sf")
  ),
  
  # now download the NHD Best Resolution file from the National Map, filter
  # waterbodies, and calculate POIs
  # run time for this target is > 1h
  tar_target(
    name = NHD_bestres_poi,
    command = calculate_bestres_centers(need_wbd_HUC4),
    pattern = need_wbd_HUC4,
    packages = c("tidyverse", "sf", "polylabelr")
  ), 
  
  # and now we'll join together the two POI files, retaining source information
  # and the unique identifier from NHD
  tar_target(
    name = combined_poi,
    command = {
      NHDv2 <- NHD_poi_points %>% 
        mutate(nhd_source = "NHDPlusv2")
      NHDbestres <- NHD_bestres_poi %>% 
        mutate(nhd_source = "NHDBestRes")
      full_join(NHDv2, NHDbestres) %>% 
        mutate(nhd_id = if_else(!is.na(comid), comid, permanent_identifier)) %>% 
        select(-c(comid, permanent_identifier))
    },
    packages = c("tidyverse", "feather")
  )
)
