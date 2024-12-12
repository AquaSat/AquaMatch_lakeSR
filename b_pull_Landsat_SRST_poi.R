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
    cue = tar_cue("always"),
    deployment = "main"
  ),
  
  # read and track the config file
  tar_file_read(
    name = b_config_file_poi,
    command = poi_config,
    read = read_yaml(!!.x),
    packages = "yaml",
    deployment = "main"
  ),

  # load, format, save yml as a csv
  tar_target(
    name = b_yml_poi,
    command = {
      # need to make sure that the directory structure has been created prior
      # to running this target
      b_check_dir_structure
      format_yaml(yml = b_config_file_poi)
      },
    packages = c("yaml", "tidyverse"),
    deployment = "main"
  ),

  # reformat location file for run_GEE_per_tile using the combined_poi_points
  # from the a_Calculate_Centers group
  tar_target(
    name = b_ref_locations_poi,
    command = reformat_locations(yml = b_yml_poi, 
                                 locations = a_combined_poi),
    deployment = "main"
  ),
  
  # get WRS tiles/indication of whether buffered points are contained by them
  tar_target(
    name = b_WRS_tiles_poi,
    command = get_WRS_tiles_poi(locations = b_ref_locations_poi, 
                                yml = b_yml_poi),
    deployment = "main"
  ),
  
  # check to see if geometry is completely contained in pathrow
  tar_target(
    name = b_poi_locs_filtered,
    command = check_if_fully_within_pr(WRS_pathrow = b_WRS_tiles_poi, 
                                       locations = b_ref_locations_poi, 
                                       yml = b_yml_poi),
    pattern = map(b_WRS_tiles_poi),
    packages = c("tidyverse", "sf", "feather")
  ),
  
  # run the Landsat pull as function per tile - this is the longest step and can
  # not be run by multiple crew workers because the bottleneck is on the end of
  # GEE, not local compute.
  tar_target(
    name = b_eeRun_poi,
    command = {
      run_GEE_per_pathrow(WRS_pathrow = b_WRS_tiles_poi)
      },
    pattern = map(b_WRS_tiles_poi),
    packages = "reticulate",
    # note, this can not/should not be used in mulitcore processing mode - the
    # bottleneck here is at GEE, not local processing, and the way the {targets}
    # and python workflow work together requires only a single `run_GEE_per_tile`
    # at a time.
    deployment = "main"
  ),
  
  # check to see that all tasks are complete! This target will run until all
  # cued GEE tasks from the previous target are complete.
  tar_target(
    name = b_poi_tasks_complete,
    command = {
      b_eeRun_poi
      source_python("b_pull_Landsat_SRST_poi/py/poi_wait_for_completion.py")
    },
    packages = "reticulate"
  ),
  
  # since we can't easily track if tasks have failed, and we send a lot of tasks
  # in this process, let's check for any failed tasks and add them to 
  # b_pull_Landsat_SRST_poi/out/GEE_failed_tasks_vRUN_DATE.txt
  tar_target(
    name = b_check_for_failed_tasks,
    command = {
      b_poi_tasks_complete
      source_python("b_pull_Landsat_SRST_poi/py/check_for_failed_tasks.py")
    },
    packages = "reticulate"
  )
)

