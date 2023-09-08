# Source functions for this {targets} list
tar_source("a_Calculate_Centers/src/")


#  -------------

# 

# create folder structure
dir.create("a_Calculate_Centers/mid/")
dir.create("a_Calculate_Centers/multisurface/")
dir.create("a_Calculate_Centers/out/")
dir.create("a_Calculate_Centers/nhd/")


# create list of targets to perform this task
a_Calculate_Centers_list <- list(
  # get {sf}s for all US states and territories from {tigris}
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
  
  # get distinct HUC4s as a list
  tar_target(
    name = HUC4_list,
    command = HUC4_dataframe %>% 
      distinct() %>% 
      pull("huc4"),
    packages = "tidyverse"
  ),
  
  # make an empty text file to store empty NHD Plus HR files when they come up 
  # in the all_poi_points target.
  tar_target(
    name = make_empty_huc_file,
    command = write_lines("", file.path("a_Calculate_Centers/out/",
                                        "empty_hucs.txt")),
    packages = "readr"
  ),
  
  # for each HUC4, download the NHDPlusHR waterbody file, subset to lakes/res/
  # impoundments, subset to >= 1ha, and calculate POI for each polygon
  tar_target(
    name = all_poi_points,
    command = calculate_centers_HUC4(HUC4_list),
    packages = c("nhdplusTools", "sf", "tidyverse", "polylabelr"),
    pattern = map(HUC4_list)
  ),
  
  # we'll track the empty hucs file now that it's not empty!
  tar_file_read(
    name = empty_hucs_file,
    command = {
      all_poi_points
      "a_Calculate_Centers/out/empty_hucs.txt"
    },
    read = read_lines(!!.x),
    packages = "readr"
  ),
  
  # collate the csv's into a single feather file for use in pull
  tar_target(
    name = collated_poi_points,
    command = {
      all_poi_points
      list.files("a_Calculate_Centers/mid/", full.names = T) %>% 
        map_dfr(., read_csv) %>% 
        write_feather(., file.path("a_Calculate_Centers/out/",
                                   "NHDPlusHR_POI_center_locs.feather"))
    },
    packages = c("tidyverse", "feather")
  )
)
    