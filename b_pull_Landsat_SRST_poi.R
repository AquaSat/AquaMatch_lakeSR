# Source functions for this {targets} list
tar_source("b_pull_Landsat_SRST_poi/src/")
source_python("b_pull_Landsat_SRST_poi/py/gee_functions.py")

# Initiate pull of Landsat C2 SRST -------------

# This {targets} list initiates the pull of Landsat SRST for all POI calculated
# in the {targets} group 'a_Calculate_Centers'.

# create folder structure
suppressWarnings({
  dir.create("b_pull_Landsat_SRST_poi/mid/")
  dir.create("b_pull_Landsat_SRST_poi/out/")
})

# create list of targets to perform this task
b_pull_Landsat_SRST_poi_list <- list(
  # read and track the config file
  tar_file_read(
    name = config_file_poi,
    command = poi_config,
    read = read_yaml(!!.x),
    packages = 'yaml'
  ),

  # load, format, save yml as a csv
  tar_target(
    name = yml_file_poi,
    command = format_yaml(config_file_poi),
    packages = c("yaml", "tidyverse")
  ),

  # read in and track the formatted yml .csv file
  tar_file_read(
    name = yml_poi,
    command = yml_file_poi,
    read = read_csv(!!.x),
    packages = "readr"
  ),

  # reformat location file for run_GEE_per_tile using the combined_poi_points
  # from the a_Calculate_Centers group
  tar_target(
    name = ref_locs_poi_file,
    command = reformat_locations(yml_poi, combined_poi_points),
    packages = c("tidyverse", "feather")
  ),
  
  # read/track that file
  tar_file_read(
    name = ref_locations_poi,
    command = ref_locs_poi_file,
    read = read_feather(!!.x),
    packages = "feather"
  ),
  
  # get WRS tiles
  tar_target(
    name = WRS_tiles_poi,
    command = get_WRS_tiles_poi(ref_locations_poi, yml_poi),
    packages = c("readr", "sf", "feather")
  ),
  
  # add WRS pathrows to the locations
  tar_target(
    name = poi_locs_WRS_file,
    command = add_WRS_tile_to_locs(WRS_tiles_poi, ref_locations_poi, yml_poi),
    packages = c("tidyverse", "sf", "feather")
  ),
  
  # track/load that file
  tar_file_read(
    name = poi_locs_with_WRS,
    command = poi_locs_WRS_file,
    read = read_feather(!!.x),
    packages = "feather"
  ),
  
  # join back with upstream to get lat/lon
  tar_target(
    name = poi_locs_WRS_latlon,
    command = {
      full_join(ref_locations_poi, poi_locs_with_WRS) %>%
        write_feather(., "b_pull_Landsat_SRST_poi/out/locations_with_WRS2_pathrows_latlon.feather")
    },
    packages = c("tidyverse", "feather")
  ),
  
  # run the Landsat pull as function per tile
  tar_target(
    name = eeRun_poi,
    command = {
      poi_locs_WRS_latlon
      csv_to_eeFeat
      apply_scale_factors
      dp_buff
      DSWE
      Mbsrv
      Ndvi
      Mbsrn
      Mndwi
      Awesh
      add_rad_mask
      sr_cloud_mask
      sr_aerosol
      cf_mask
      calc_hill_shadows
      calc_hill_shades
      remove_geo
      maximum_no_of_tasks
      ref_pull_457_DSWE1
      ref_pull_89_DSWE1
      ref_pull_457_DSWE3
      ref_pull_89_DSWE3
      run_GEE_per_tile(WRS_tiles_poi)
    },
    pattern = map(WRS_tiles_poi),
    packages = "reticulate"
  ),
  
  # run the Landsat pull as function per tile
  tar_target(
    name = eeRun_poi,
    command = {
      poi_locs_WRS_latlon
      csv_to_eeFeat
      apply_scale_factors
      dp_buff
      DSWE
      Mbsrv
      Ndvi
      Mbsrn
      Mndwi
      Awesh
      add_rad_mask
      sr_cloud_mask
      sr_aerosol
      cf_mask
      calc_hill_shadows
      calc_hill_shades
      remove_geo
      maximum_no_of_tasks
      ref_pull_457_DSWE1_altered
      ref_pull_457_DSWE3_altered
      run_GEE_per_tile_altered(WRS_tiles_poi)
    },
    pattern = map(WRS_tiles_poi),
    packages = "reticulate"
  ),
  
  # check to see that all tasks are complete! This target will run until all
  # cued GEE tasks from the previous target are complete.
  tar_target(
    name = poi_tasks_complete,
    command = {
      eeRun_poi
      source_python("b_pull_Landsat_SRST_poi/py/poi_wait_for_completion.py")
    },
    packages = "reticulate"
  )
)
