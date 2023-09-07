# Source functions for this {targets} list
tar_source("a_Calculate_Centers/src/")


#  -------------

# this collates a few different polygon and point files into a single
# file of each type as needed for the RS workflow. CLP = Cache La Poudre, 
# NW = Northern Water.

# create folder structure
dir.create("a_Calculate_Centers/mid/")
dir.create("a_Calculate_Centers/out/")
dir.create("a_Calculate_Centers/nhd/")

# create list of targets to perform this task
a_Calculate_Centers_list <- list(
  # get {sf}s for all US states and territories from {tigris}
  tar_target(
    name = US_states_territories,
    command = states() %>% st_make_valid(),
    packages = c("tigris", "sf")
    ),
  
  # for each state/territory, get a list of HUC4s
  # while this is not the most efficient (HUC4s cross state boundaries),
  # this is a good framework to break up HUC acquisition. If you run on the 
  # boundary of the US, this will completely fail and timeout.
  tar_target(
    name = HUC4_dataframe,
    command = get_huc(US_states_territories, type = "huc04") %>% 
      st_drop_geometry(),
    packages = c("nhdplusTools", "sf"),
    pattern = map(US_states_territories)
  ),
  
  # get distinct HUC4s as a list
  tar_target(
    name = HUC4_list,
    command = HUC4_dataframe %>% 
      distinct() %>% 
      pull("huc4")
  ),
  
  # for each HUC4, download the NHDPlusHR waterbody file, subset to lakes/res/
  # impoundments, subset to >= 1ha, and calculate POI for each polygon
  tar_target(
    name = all_poi_points,
    command = calculate_centers_HUC4(HUC4_list),
    packages = c("nhdplusTools", "sf", "tidyverse", "polylabelr"),
    pattern = map(HUC4_list)
  )
  
)
    