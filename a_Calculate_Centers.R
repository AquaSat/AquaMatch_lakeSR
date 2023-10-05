# Source functions for this {targets} list
tar_source("a_Calculate_Centers/src/")


# Calculate POI Centers for all US and Territories Lakes -------------

# This {targets} list calculates "Point of Inaccessibility", also known as
# Cheybyshev Center for all lakes/reservoirs/impoundments greater than 1ha in 
# surface area using the NHDPlusHR polygons using the {nhdplusTools} package
# and the `poi()` function in the {polylabelr} package. For all waterbodies in
# Alaska, POI were calculated based on the NHD Best Resolution file for the entire
# state because the NHDPlusHR is not complete for AK. **Note**: this group of
# targets will take up to 4h to complete.

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
  # run time for this target is > 3 h
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
        map_dfr(., 
                function(file) { 
                  read_csv(file, 
                           col_types = cols(.default = 'c')) # coerce all cols to character
                  }) %>% 
        write_feather(., file.path("a_Calculate_Centers/out/",
                                   "NHDPlusHR_POI_center_locs.feather"))
    },
    packages = c("tidyverse", "feather")
  ),
  
  # and let's load/track that file
  tar_file_read(
    name = NHDHR_poi_points,
    command = {
      collated_poi_points
      "a_Calculate_Centers/out/NHDPlusHR_POI_center_locs.feather"
      },
    read = read_feather(!!.x),
    packages = "feather"
  ), 
  
  # most of Alaska is not available in NHDPlusHR. Because of this, we will ditch
  # all NHDPlusHR data in AK (HUC04s that start with 19) and then download the
  # NHD Best Resolution file for AK from the National Map. 
  
  # first, drop the AK lakes
  tar_target(
    name = NHDHR_poi_points_noAK,
    command = {
      #make a list of incomplete VPUIDs
      incomplete_list <- unique(NHDHR_poi_points$VPUID) %>% 
        # there are a few HUC8s in Alaska with data that we want to drop, these
        # are indicated by VPUIDs that are 8 characters - and there are a few that
        # were concatenated in a previous step, resulting in 18 characters. All 
        # other VPUIDs are either 4, 5, 6, 10, or 11 characters in length.
        .[nchar(.) == 8 | nchar(.) == 18]
      NHDHR_poi_points %>% 
        filter(!VPUID %in% incomplete_list)  
    },
    packages = "tidyverse"
  ),
  
  # now download the AK NHD Best Resolution file from the National Map 
  # and calculate POI for each WBD
  # run time for this target is > 1h
  tar_target(
    name = make_AK_poi_points,
    command = calculate_AK_poi(),
    packages = c("tidyverse", "sf", "polylabelr", "feather")
  ), 
  
  # and load/track the resulting file
  tar_file_read(
    name = AK_poi_points,
    command = {
      make_AK_poi_points
      "a_Calculate_Centers/out/AK_NHD_BestRes_POI_center_locs.feather"
      },
    read = read_feather(!!.x),
    packages = "feather"
  ),

  # and now we'll join together the two POI files
  tar_target(
    name = combined_poi_file,
    command = collate_NHDHR_AK(NHDHR_poi_points_noAK,
                               AK_poi_points),
    packages = c("tidyverse", "feather")
  ),
  
  # and track/load that file
  tar_file_read(
    name = combined_poi_points,
    command = combined_poi_file,
    read = read_feather(!!.x),
    packages = "feather"
  )
)
