# Source functions for this {targets} list
tar_source("b_pull_Landsat_SRST_poi/src/")

# Initiate pull of Landsat C2 SRST -------------

# This {targets} list initiates the pull of Landsat SRST for all POI calculated
# in the {targets} group "a_Calculate_Centers".

# create list of targets to perform this task
b_pull_Landsat_SRST_poi_list <- list(
  tar_target(
    name = b_check_dir_structure,
    command = {
      # make directories if needed
      directories = c("b_pull_Landsat_SRST_poi/mid/",
                      "b_pull_Landsat_SRST_poi/out/")
      walk(directories, function(dir) {
        if(!dir.exists(dir)){
          dir.create(dir)
        }
      })
    },
    cue = tar_cue("always")
  ),
  
  # read and track the config file
  tar_file_read(
    name = config_file_poi,
    command = poi_config,
    read = read_yaml(!!.x),
    packages = "yaml"
  ),

  # load, format, save yml as a csv
  tar_target(
    name = yml_poi,
    command = {
      # need to make sure that the directory structure has been created prior
      # to running this target
      b_check_dir_structure
      format_yaml(config_file_poi)
      },
    packages = c("yaml", "tidyverse")
  ),

  # reformat location file for run_GEE_per_tile using the combined_poi_points
  # from the a_Calculate_Centers group
  tar_target(
    name = ref_locations_poi,
    command = reformat_locations(yml_poi, combined_poi)
  ),
  
  # get WRS tiles/indication of whether buffered points are contained by them
  tar_target(
    name = WRS_tiles_poi,
    command = get_WRS_tiles_poi(ref_locations_poi, yml_poi),
    packages = c("readr", "sf")
  ),
  
  # check to see if geometry is completely contained in pathrow
  tar_target(
    name = poi_locs_filtered,
    command = check_if_fully_within_pr(WRS_tiles_poi, ref_locations_poi, yml_poi),
    pattern = WRS_tiles_poi,
    packages = c("tidyverse", "sf", "feather")
  ),
  
  # run the Landsat pull as function per tile
  tar_target(
    name = eeRun_poi,
    command = {
      poi_locs_filtered
      run_GEE_per_tile(WRS_tiles_poi)
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

