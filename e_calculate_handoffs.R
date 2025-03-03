# Source functions for this {targets} list
tar_source("e_calculate_handoffs/src/")

# High-level QA filter and handoff calculations -----------------------------

# This {targets} list applies some rudimentary QA to the Landsat stacks, and then
# calculates 'intermission handoffs' that standardize the SR values relative to LS7
# and to LS8.

e_calculate_handoffs <- list(
  
  tar_target(
    name = e_check_dir_structure,
    command = {
      # make directories if needed
      directories = c("e_calculate_handoffs/roy/",
                      "e_calculate_handoffs/gardner/",
                      "e_calculate_handoffs/out/")
      walk(directories, function(dir) {
        if(!dir.exists(dir)){
          dir.create(dir)
        }
      })
    },
    cue = tar_cue("always"),
    deployment = "main",
  ),
  
  # subset LS 4/5/7/8/9 for Roy adapted handoff date range -----------------------
  
  # the Landsat records are still too large to collate in targets (even using
  # data.table), so here, we're subsetting by date range and returning the 
  # 1-99 quantiles to keep things efficient with targets. This is the adapted
  # Roy et al 2016 method used in Gardner et al (Color of Rivers)
  
  tar_target(
    name = e_LS4_forLS45corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LT04",
                                  dswe = c_dswe_types,
                                  start_date = ymd("1984-05-01"), 
                                  end_date = ymd("1993-08-01"),
                                  for_corr = "LS5",
                                  record_length_prop = 0.4, # no data here until between 0.5-0.6
                                  bands = c("med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  tar_target(
    name = e_LS5_forLS45corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LT05",
                                  dswe = c_dswe_types,
                                  start_date = ymd("1984-05-01"), 
                                  end_date = ymd("1993-08-01"),
                                  for_corr = "LS4",
                                  record_length_prop = 0.4,
                                  bands = c("med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),  
  
  tar_target(
    name = e_LS5_forLS57corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LT05",
                                  dswe = c_dswe_types,
                                  start_date = ymd("1999-04-15"), 
                                  end_date = ymd("2013-06-05"),
                                  for_corr = "LS7",
                                  record_length_prop = 0.75,
                                  bands = c("med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  tar_target(
    name = e_LS7_forLS57corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LE07",
                                  dswe = c_dswe_types,
                                  start_date = ymd("1999-04-15"), 
                                  end_date = ymd("2013-06-05"),
                                  for_corr = "LS5",
                                  record_length_prop = 0.75,
                                  bands = c("med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  tar_target(
    name = e_LS7_forLS78corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LE07",
                                  dswe = c_dswe_types,
                                  start_date = ymd("2013-02-11"), 
                                  end_date = ymd("2022-04-16"),
                                  for_corr = "LS8",
                                  record_length_prop = 0.75,
                                  bands = c("med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  tar_target(
    name = e_LS8_forLS78corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LC08",
                                  dswe = c_dswe_types,
                                  start_date = ymd("2013-02-11"), 
                                  end_date = ymd("2022-04-16"),
                                  for_corr = "LS7",
                                  record_length_prop = 0.75,
                                  bands = c("med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  tar_target(
    name = e_LS8_forLS89corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LC08",
                                  dswe = c_dswe_types,
                                  start_date = ymd("2021-09-27"), 
                                  end_date = ymd("2024-12-31"),
                                  for_corr = "LS9",
                                  record_length_prop = 0.75,
                                  bands = c("med_Aerosol", "med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  tar_target(
    name = e_LS9_forLS89corr_quantiles,
    command = get_quantile_values(qa_files = d_qa_Landsat_file_paths,
                                  version_id = d_version_identifier,
                                  mission_id = "LC09",
                                  dswe = c_dswe_types,
                                  start_date = ymd("2021-09-27"), 
                                  end_date = ymd("2024-12-31"),
                                  for_corr = "LS8",
                                  record_length_prop = 0.75,
                                  bands = c("med_Aerosol", "med_Red", "med_Green", "med_Blue", 
                                            "med_Nir", "med_Swir1", "med_Swir2",
                                            "med_SurfaceTemp")),
    pattern = map(c_dswe_types), 
    packages = c("data.table", "tidyverse", "arrow"), 
    deployment = "main" # these are still too large for multicore!
  ),
  
  
  # Roy matches -----------------------------------------------------------
  
  # This section creates paired data from mission flyovers using the Roy et al.
  # 2016 method
  
  # make a matrix of possible path prefix overlaps (aka 00 overlaps with 00 and 01, 
  # 03 overlaps with 02, 03, 04, etc)
  tar_target(
    name = e_path_prefix_table,
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
    name = e_LS45_DSWE1_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_sort/qa/", 
                  dswe = "DSWE1", version = d_version_identifier,
                  early_LS_mission = "LT04", late_LS_mission = "LT05",
                  early_path_prefix = e_path_prefix_table$early_prefix, 
                  late_path_prefix =  e_path_prefix_table$late_prefix)
    },
    pattern = map(e_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  tar_target(
    name = e_LS57_DSWE1_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_sort/qa/", 
                  dswe = "DSWE1", version = d_version_identifier,
                  early_LS_mission = "LT05", late_LS_mission = "LE07",
                  early_path_prefix = e_path_prefix_table$early_prefix, 
                  late_path_prefix =  e_path_prefix_table$late_prefix)
    },
    pattern = map(e_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  tar_target(
    name = e_LS78_DSWE1_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_sort/qa/", 
                  dswe = "DSWE1", version = d_version_identifier,
                  early_LS_mission = "LE07", late_LS_mission = "LC08",
                  early_path_prefix = e_path_prefix_table$early_prefix, 
                  late_path_prefix =  e_path_prefix_table$late_prefix)
    },
    pattern = map(e_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  tar_target(
    name = e_LS89_DSWE1_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_sort/qa/", 
                  dswe = "DSWE1", version = d_version_identifier,
                  early_LS_mission = "LC08", late_LS_mission = "LC09",
                  early_path_prefix = e_path_prefix_table$early_prefix, 
                  late_path_prefix =  e_path_prefix_table$late_prefix)
    },
    pattern = map(e_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  # and dswe1a
  tar_target(
    name = e_LS45_DSWE1a_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_sort/qa/", 
                  dswe = "DSWE1a", version = d_version_identifier,
                  early_LS_mission = "LT04", late_LS_mission = "LT05",
                  early_path_prefix = e_path_prefix_table$early_prefix, 
                  late_path_prefix = e_path_prefix_table$late_prefix)
    },
    pattern = map(e_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  tar_target(
    name = e_LS57_DSWE1a_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_sort/qa/", 
                  dswe = "DSWE1a", version = d_version_identifier,
                  early_LS_mission = "LT05", late_LS_mission = "LE07",
                  early_path_prefix = e_path_prefix_table$early_prefix, 
                  late_path_prefix = e_path_prefix_table$late_prefix)
    },
    pattern = map(e_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  tar_target(
    name = e_LS78_DSWE1a_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_sort/qa/", 
                  dswe = "DSWE1a", version = d_version_identifier,
                  early_LS_mission = "LE07", late_LS_mission = "LC08",
                  early_path_prefix = e_path_prefix_table$early_prefix, 
                  late_path_prefix =  e_path_prefix_table$late_prefix)
    },
    pattern = map(e_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  tar_target(
    name = e_LS89_DSWE1a_matches,
    command = {
      d_qa_Landsat_files
      get_matches(dir = "d_qa_filter_sort/qa/", 
                  dswe = "DSWE1a", version = d_version_identifier,
                  early_LS_mission = "LC08", late_LS_mission = "LC09",
                  early_path_prefix = e_path_prefix_table$early_prefix, 
                  late_path_prefix =  e_path_prefix_table$late_prefix)
    },
    pattern = map(e_path_prefix_table),
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main"
  ),
  
  
  # calculate handoffs ----------------------------------
  
  tar_target(
    name = e_bands_for_correction,
    command = c("med_Blue", "med_Green", "med_Red", "med_Nir", "med_SurfaceTemp")
  ), 
  
  # calculate Gardner method
  
  tar_target(
    name = e_calculate_gardner_LS5_to_LS7,
    command = calculate_gardner_handoff(quantile_from = e_LS5_forLS57corr_quantiles, 
                                        quantile_to = e_LS7_forLS57corr_quantiles, 
                                        mission_from = "LS5", 
                                        mission_to = "LS7",
                                        DSWE = c_dswe_types, 
                                        band = e_bands_for_correction),
    pattern = cross(c_dswe_types, e_bands_for_correction)
  ),
  
  tar_target(
    name = e_calculate_gardner_LS8_to_LS7,
    command = calculate_gardner_handoff(quantile_from = e_LS8_forLS78corr_quantiles, 
                                        quantile_to = e_LS7_forLS78corr_quantiles, 
                                        mission_from = "LS8", 
                                        mission_to = "LS7",
                                        DSWE = c_dswe_types, 
                                        band = e_bands_for_correction),
    pattern = cross(c_dswe_types, e_bands_for_correction)
  ),
  
  tar_target(
    name = e_calculate_gardner_LS7_to_LS8,
    command = calculate_gardner_handoff(quantile_from = e_LS7_forLS78corr_quantiles, 
                                        quantile_to = e_LS8_forLS78corr_quantiles, 
                                        mission_from = "LS7", 
                                        mission_to = "LS8",
                                        DSWE = c_dswe_types, 
                                        band = e_bands_for_correction),
    pattern = cross(c_dswe_types, e_bands_for_correction)
  ),
  
  tar_target(
    name = e_calculate_gardner_LS9_to_LS8,
    command = calculate_gardner_handoff(quantile_from = e_LS9_forLS89corr_quantiles, 
                                        quantile_to = e_LS8_forLS89corr_quantiles, 
                                        mission_from = "LS9", 
                                        mission_to = "LS8",
                                        DSWE = c_dswe_types, 
                                        band = e_bands_for_correction),
    pattern = cross(c_dswe_types, e_bands_for_correction)
  ), 
  
  # and calculate for Roy method
  
  tar_target(
    name = e_Roy_LS5_to_LS7_DSWE1_handoff,
    command = calculate_roy_handoff(matched_data = e_LS57_DSWE1_matches, 
                                    mission_from = "LS5",
                                    mission_to = "LS7",
                                    invert_mission_match = FALSE,
                                    bands = e_bands_for_correction,
                                    DSWE = "DSWE1"),
    packages = c("tidyverse", "deming"),
    deployment = "main"
  ),
  
  tar_target(
    name = e_Roy_LS8_to_LS7_DSWE1_handoff,
    command = calculate_roy_handoff(matched_data = e_LS78_DSWE1_matches, 
                                    mission_from = "LS8",
                                    mission_to = "LS7",
                                    invert_mission_match = TRUE,
                                    bands = e_bands_for_correction,
                                    DSWE = "DSWE1"),
    packages = c("tidyverse", "deming"),
    deployment = "main"
  ),
  
  tar_target(
    name = e_Roy_LS7_to_LS8_DSWE1_handoff,
    command = calculate_roy_handoff(matched_data = e_LS78_DSWE1_matches, 
                                    mission_from = "LS7",
                                    mission_to = "LS8",
                                    invert_mission_match = FALSE,
                                    bands = e_bands_for_correction,
                                    DSWE = "DSWE1"),
    packages = c("tidyverse", "deming"),
    deployment = "main"
  ),
  
  tar_target(
    name = e_Roy_LS9_to_LS8_DSWE1_handoff,
    command = calculate_roy_handoff(matched_data = e_LS89_DSWE1_matches, 
                                    mission_from = "LS9",
                                    mission_to = "LS8",
                                    invert_mission_match = FALSE,
                                    bands = e_bands_for_correction,
                                    DSWE = "DSWE1"),
    packages = c("tidyverse", "deming"),
    deployment = "main"
  ), 
  
  tar_target(
    name = e_Roy_LS5_to_LS7_DSWE1a_handoff,
    command = calculate_roy_handoff(matched_data = e_LS57_DSWE1a_matches, 
                                    mission_from = "LS5",
                                    mission_to = "LS7",
                                    invert_mission_match = FALSE,
                                    bands = e_bands_for_correction,
                                    DSWE = "DSWE1a"),
    packages = c("tidyverse", "deming"),
    deployment = "main"
  ),
  
  tar_target(
    name = e_Roy_LS8_to_LS7_DSWE1a_handoff,
    command = calculate_roy_handoff(matched_data = e_LS78_DSWE1a_matches, 
                                    mission_from = "LS8",
                                    mission_to = "LS7",
                                    invert_mission_match = TRUE,
                                    bands = e_bands_for_correction,
                                    DSWE = "DSWE1a"),
    packages = c("tidyverse", "deming"),
    deployment = "main"
  ),
  
  tar_target(
    name = e_Roy_LS7_to_LS8_DSWE1a_handoff,
    command = calculate_roy_handoff(matched_data = e_LS78_DSWE1a_matches, 
                                    mission_from = "LS7",
                                    mission_to = "LS8",
                                    invert_mission_match = FALSE,
                                    bands = e_bands_for_correction,
                                    DSWE = "DSWE1a"),
    packages = c("tidyverse", "deming"),
    deployment = "main"
  ),
  
  tar_target(
    name = e_Roy_LS9_to_LS8_DSWE1a_handoff,
    command = calculate_roy_handoff(matched_data = e_LS89_DSWE1a_matches, 
                                    mission_from = "LS9",
                                    mission_to = "LS8",
                                    invert_mission_match = FALSE,
                                    bands = e_bands_for_correction,
                                    DSWE = "DSWE1a"),
    packages = c("tidyverse", "deming"),
    deployment = "main"
  ),
  
  # collate all the Gardner and Roy coefficients for ease of use
  tar_target(
    name = e_Roy_handoffs,
    command = list(e_Roy_LS5_to_LS7_DSWE1_handoff,
                   e_Roy_LS8_to_LS7_DSWE1_handoff,
                   e_Roy_LS7_to_LS8_DSWE1_handoff, 
                   e_Roy_LS9_to_LS8_DSWE1_handoff,
                   e_Roy_LS5_to_LS7_DSWE1a_handoff,
                   e_Roy_LS8_to_LS7_DSWE1a_handoff,
                   e_Roy_LS7_to_LS8_DSWE1a_handoff, 
                   e_Roy_LS9_to_LS8_DSWE1a_handoff) %>% 
      bind_rows() %>% 
      mutate(correction = "Roy")
  ),
  
  tar_target(
    name = e_Gardner_handoffs,
    command = list(e_calculate_gardner_LS5_to_LS7,
                   e_calculate_gardner_LS8_to_LS7,
                   e_calculate_gardner_LS7_to_LS8,
                   e_calculate_gardner_LS9_to_LS8) %>% 
      bind_rows() %>% 
      mutate(method = "poly",
             correction = "Gardner")
  ),
  
  tar_target(
    name = e_collated_handoffs,
    command = {
      handoffs <- bind_rows(e_Roy_handoffs, e_Gardner_handoffs) %>%
        select(band, correction, dswe, sat_corr, sat_to, method, intercept, slope, B1, B2, min_in_val, max_in_val)
      write_csv(handoffs, paste0("e_calculate_handoffs/out/collated_handoffs_v",
                                 b_yml_poi$run_date,
                                 ".csv"))
    }
  )
  
)
