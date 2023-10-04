# Source functions for this {targets} list
tar_source("b_pull_Landsat_SRST_poi/src/")

# Initiate pull of Landsat C2 SRST -------------

# This {targets} list initiates the pull of Landsat SRST for all POI calculated
# in the {targets} group 'a_Calculate_Centers'.

# create folder structure
dir.create("b_pull_Landsat_SRST_poi/in/")
dir.create("b_pull_Landsat_SRST_poi/out/")


# create list of targets to perform this task
b_pull_Landsat_SRST_poi <- list(
  # read and track the config file
  tar_file_read(
    name = config_file_poi,
    command = "config_files/config_poi.yml",
    read = read_yaml(!!.x),
    packages = 'yaml'
  ),
  
  # load, format, save yml as a csv
  tar_target(
    name = yml_save_poi,
    command = {
      # make sure that {targets} runs the config_file target before this target
      config_file_poi 
      format_yaml("config_files/config_poi.yml")
    },
    packages = c("yaml", "tidyverse") #for some reason, you have to load TV.
  ),
  
  # read in and track the formatted yml .csv file
  tar_file_read(
    name = yml_poi,
    command = yml_save_poi,
    read = read_csv(!!.x),
    packages = "readr"
  ),
  
  # reformat location file for run_GEE_per_tile using the combined_poi_points
  # from the a_Calculate_Centers group
  tar_target(
    name = reformatted_locations_poi,
    command = reformat_locations(combined_poi_points), 
    packages = "tidyverse"
  ),
  
  # get WRS tile acquisition method from yaml
  tar_target(
    name = WRS_detection_method_poi,
    command = {
      reformatted_locations_poi
      get_WRS_detection(yml_poi)
    },
    packages = "readr"
  ),
  
  # get WRS tiles
  tar_target(
    name = WRS_tiles_poi,
    command = get_WRS_tiles(WRS_detection_method_poi, yml_poi),
    packages = c("readr", "sf")
  ),
  
  # run the landsat pull as function per tile
  tar_target(
    name = eeRun_poi,
    command = {
      yml_poi
      locs_poi
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
    pattern = map(WRS_tiles),
    packages = "reticulate"
  )
)
