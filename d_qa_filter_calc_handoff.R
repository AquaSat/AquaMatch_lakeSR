# Source functions for this {targets} list
tar_source("d_qa_filter_calc_handoff/src/")

# High-level QA filter and handoff calculations -----------------------------

# This {targets} list applies some rudimentary QA to the Landsat stacks, and then
# calculates 'intermission handoffs' that standardize the SR values relative to LS7
# and to LS8.

d_qa_filter_calc_handoff <- list(
  
  # Check for folder architecture -------------------------------------------
  
  tar_target(
    name = d_check_dir_structure,
    command = {
      # make directories if needed
      directories = c("d_qa_filter_calc_handoff/mid/",
                      "d_qa_filter_calc_handoff/handoff/",
                      "d_qa_filter_calc_handoff/out/")
      walk(directories, function(dir) {
        if(!dir.exists(dir)){
          dir.create(dir)
        }
      })
    },
    cue = tar_cue("always"),
    deployment = "main",
  ),
  
  
  # collate each mission ---------------------------------------------------
  
  # Because the LS5 and 7 missions are absolutely huge data tables, and use 
  # nearly all of a 32GB memory limit within R, we continue to process the Landsat
  # data in chunks per mission. 
  
  tar_target(
    name = d_mission_identifiers,
    command = tibble(mission_id = c("LT04", "LT05", "LE07", "LC08", "LC09"),
                     mission_names = c("Landsat 4", "Landsat 5", "Landsat 7", "Landsat 8", "Landsat 9"))
  ),
  
  # walk through QA of missions and DSWE types
  tar_target(
    name = d_qa_Landsat_files,
    command = {
      d_check_dir_structure
      qa_and_document_LS(mission_info = d_mission_identifiers, 
                         dswe = c_dswe_types, 
                         collated_files = c_collated_files)
    },
    packages = c("arrow", "data.table", "tidyverse", "ggrepel", "viridis"),
    pattern = cross(d_mission_identifiers, c_dswe_types),
    deployment = "main"
  ),
  
  # get a list of the qa'd files
  tar_target(
    name = d_qa_Landsat_file_paths,
    command = list.files("d_qa_filter_calc_handoff/mid/", full.names = TRUE)
  ),
  
  # get the appropriate version date to filter files, just in case there is more
  # than one version
  tar_target(
    name = d_version_identifier,
    command = {
      if (lakeSR_config$run_GEE) {
        b_yml_poi$run_date 
      } else { 
        lakeSR_config$collated_version 
      }
    }
  ),
  
  
  # subset LS 5/7/8 for handoff date range ----------------------------------
  # the Landsat records are still to large to collate in targets (even using
  # data.table), so here, we're using the date-range subset that we need to 
  # calculate handoff coefficients. 
  
  tar_target(
    name = d_LS5_forLS57corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LT05",
                                  dswe = c_dswe_types,
                                  start_date = ymd("1999-04-15"), 
                                  end_date = ymd("2013-06-05"),
                                  for_corr = "LS5toLS7",
                                  record_length_prop = 0.75,
                                  # a little fancy footwork here to get at 75% of record
                                  bands = c("med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main", # these are still too large for multicore!
    iteration = "list"
  ),
  
  tar_target(
    name = d_LS7_forLS5corr_subset,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                   version = d_version_identifier,
                                   mission_id = "LE07",
                                   dswe = c_dswe_types,
                                   start_date = ymd("1999-04-15"), 
                                   end_date = ymd("2013-06-05")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main", # these are still too large for multicore!
    iteration = "list"
  )
  
)
