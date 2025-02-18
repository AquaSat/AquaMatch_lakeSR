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
    command = {
      d_qa_Landsat_files
      list.files("d_qa_filter_calc_handoff/mid/", full.names = TRUE)
    }
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
  
  
  # subset LS 4/5/7/8/9 for Roy adapted handoff date range -----------------------
  
  # the Landsat records are still to large to collate in targets (even using
  # data.table), so here, we're subsetting by date range and returning the 
  # 1-99 quantiles to keep things efficient with targets. This is the adapted
  # Roy et al 2016 method used in Gardner et al (Color of Rivers)
  
  tar_target(
    name = d_LS4_forLS45corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LT04",
                                  dswe = c_dswe_types,
                                  start_date = ymd("1984-05-01"), 
                                  end_date = ymd("1993-08-01"),
                                  for_corr = "LS5",
                                  record_length_prop = 0.4, #no data here until between 0.5-0.6
                                  # a little fancy footwork here to get at 75% of record
                                  bands = c("med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  tar_target(
    name = d_LS5_forLS45corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LT05",
                                  dswe = c_dswe_types,
                                  start_date = ymd("1984-05-01"), 
                                  end_date = ymd("1993-08-01"),
                                  for_corr = "LS4",
                                  record_length_prop = 0.4,
                                  # a little fancy footwork here to get at 75% of record
                                  bands = c("med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),  
  
  tar_target(
    name = d_LS5_forLS57corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LT05",
                                  dswe = c_dswe_types,
                                  start_date = ymd("1999-04-15"), 
                                  end_date = ymd("2013-06-05"),
                                  for_corr = "LS7",
                                  record_length_prop = 0.75,
                                  # a little fancy footwork here to get at 75% of record
                                  bands = c("med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  tar_target(
    name = d_LS7_forLS57corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LE07",
                                  dswe = c_dswe_types,
                                  start_date = ymd("1999-04-15"), 
                                  end_date = ymd("2013-06-05"),
                                  for_corr = "LS5",
                                  record_length_prop = 0.75,
                                  # a little fancy footwork here to get at 75% of record
                                  bands = c("med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  tar_target(
    name = d_LS7_forLS78corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LE07",
                                  dswe = c_dswe_types,
                                  start_date = ymd("2013-02-11"), 
                                  end_date = ymd("2022-04-16"),
                                  for_corr = "LS8",
                                  record_length_prop = 0.75,
                                  # a little fancy footwork here to get at 75% of record
                                  bands = c("med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  tar_target(
    name = d_LS8_forLS78corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LC08",
                                  dswe = c_dswe_types,
                                  start_date = ymd("2013-02-11"), 
                                  end_date = ymd("2022-04-16"),
                                  for_corr = "LS7",
                                  record_length_prop = 0.75,
                                  # a little fancy footwork here to get at 75% of record
                                  bands = c("med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  tar_target(
    name = d_LS8_forLS89corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LC08",
                                  dswe = c_dswe_types,
                                  start_date =ymd("2021-09-27"), 
                                  end_date = ymd("2024-12-31"),
                                  for_corr = "LS9",
                                  record_length_prop = 0.75,
                                  # a little fancy footwork here to get at 75% of record
                                  bands = c("med_Aerosol", "med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  tar_target(
    name = d_LS9_forLS89corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LC09",
                                  dswe = c_dswe_types,
                                  start_date = ymd("2021-09-27"), 
                                  end_date = ymd("2024-12-31"),
                                  for_corr = "LS8",
                                  record_length_prop = 0.75,
                                  # a little fancy footwork here to get at 75% of record
                                  bands = c("med_Aerosol", "med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  
  # Roy quantiles -----------------------------------------------------------
  
  # This section calculates the Roy quantiles paired data from mission flyovers
  
  # make a matrix of possible path prefix overlaps (aka 00 overlaps with 00 and 01, 
  # 03 overlaps with 02, 03, 04, etc)
  tar_target(
    name = d_path_prefix_table,
    command = tibble(early_prefix = c("00", "00", 
                                      "01", "01", "01", 
                                      "02", "02", "02",
                                      "03", "03", "03",
                                      "04", "04", "04",
                                      "05", "05", "05",
                                      "06", "06", "06",
                                      "07", "07","07",
                                      "08", "08",
                                      "10"),
                     late_prefix = c("00", "01", 
                                     "00", "01", "02",
                                     "01", "02", "03",
                                     "02", "03", "04",
                                     "03", "04", "05",
                                     "04", "05", "06",
                                     "05", "06", "07",
                                     "06", "07", "08",
                                     "07", "08",
                                     "10"))
  ),
  
  # these are too large to do both dswe at the same time, so break out into indiv
  # matches per dswe type:
  
  tar_target(
    name = d_LS45_DSWE1_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_calc_handoff/mid/", 
                  dswe = "DSWE1", version = d_version_identifier,
                  early_LS_mission = "LT04", late_LS_mission = "LT05",
                  early_path_prefix = d_path_prefix_table$early_prefix, 
                  late_path_prefix =  d_path_prefix_table$late_prefix)
    },
    pattern = map(d_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),

  tar_target(
    name = d_LS57_DSWE1_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_calc_handoff/mid/", 
                  dswe = "DSWE1", version = d_version_identifier,
                  early_LS_mission = "LT05", late_LS_mission = "LE07",
                  early_path_prefix = d_path_prefix_table$early_prefix, 
                  late_path_prefix =  d_path_prefix_table$late_prefix)
    },
    pattern = map(d_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  tar_target(
    name = d_LS78_DSWE1_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_calc_handoff/mid/", 
                  dswe = "DSWE1", version = d_version_identifier,
                  early_LS_mission = "LE07", late_LS_mission = "LC08",
                  early_path_prefix = d_path_prefix_table$early_prefix, 
                  late_path_prefix =  d_path_prefix_table$late_prefix)
    },
    pattern = map(d_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  tar_target(
    name = d_LS89_DSWE1_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_calc_handoff/mid/", 
                  dswe = "DSWE1", version = d_version_identifier,
                  early_LS_mission = "LC08", late_LS_mission = "LC09",
                  early_path_prefix = d_path_prefix_table$early_prefix, 
                  late_path_prefix =  d_path_prefix_table$late_prefix)
    },
    pattern = map(d_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  # and dswe1a
  tar_target(
    name = d_LS45_DSWE1a_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_calc_handoff/mid/", 
                  dswe = "DSWE1a", version = d_version_identifier,
                  early_LS_mission = "LT04", late_LS_mission = "LT05",
                  early_path_prefix = d_path_prefix_table$early_prefix, 
                  late_path_prefix =  d_path_prefix_table$late_prefix)
    },
    pattern = map(d_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  tar_target(
    name = d_LS57_DSWE1a_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_calc_handoff/mid/", 
                  dswe = "DSWE1a", version = d_version_identifier,
                  early_LS_mission = "LT05", late_LS_mission = "LE07",
                  early_path_prefix = d_path_prefix_table$early_prefix, 
                  late_path_prefix =  d_path_prefix_table$late_prefix)
    },
    pattern = map(d_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  tar_target(
    name = d_LS78_DSWE1a_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_calc_handoff/mid/", 
                  dswe = "DSWE1a", version = d_version_identifier,
                  early_LS_mission = "LE07", late_LS_mission = "LC08",
                  early_path_prefix = d_path_prefix_table$early_prefix, 
                  late_path_prefix =  d_path_prefix_table$late_prefix)
    },
    pattern = map(d_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  tar_target(
    name = d_LS89_DSWE1a_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_calc_handoff/mid/", 
                  dswe = "DSWE1a", version = d_version_identifier,
                  early_LS_mission = "LC08", late_LS_mission = "LC09",
                  early_path_prefix = d_path_prefix_table$early_prefix, 
                  late_path_prefix =  d_path_prefix_table$late_prefix)
    },
    pattern = map(d_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  )
  
  
  
)
