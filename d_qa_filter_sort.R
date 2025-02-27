# Source functions for this {targets} list
tar_source("d_qa_filter_sort/src/")

# High-level QA filter and handoff calculations -----------------------------

# This {targets} list applies some rudimentary QA to the Landsat stacks, and then
# calculates 'intermission handoffs' that standardize the SR values relative to LS7
# and to LS8.

d_qa_filter_sort <- list(
  
  # Check for folder architecture -------------------------------------------
  
  tar_target(
    name = d_check_dir_structure,
    command = {
      # make directories if needed
      directories = c("d_qa_filter_sort/qa/",
                      "d_qa_filter_sort/sort/",
                      "d_qa_filter_sort/out/")
      walk(directories, function(dir) {
        if(!dir.exists(dir)){
          dir.create(dir)
        }
      })
    },
    cue = tar_cue("always"),
    deployment = "main",
  ),
  
  
  # collate and qa each mission ---------------------------------------------------
  
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
  
  # get a list of the qa'd files
  tar_target(
    name = d_qa_Landsat_file_paths,
    command = {
      d_qa_Landsat_files
      list.files("d_qa_filter_sort/qa/", full.names = TRUE) %>% 
        .[grepl(d_version_identifier, .)]
    }
  ),
  
  
  # collate qa'd data and sort as needed ------------------------------------
  
  # here, we collate small datasets (Landsat 4/9) into a single .csv file, and 
  # collate larger datasets (Landsat 5-7-8) into multiple .csv's, sorted by HUC2.
  
  # create a list of HUC2's to map over
  tar_target(
    name = d_unique_huc2,
    command = unique(str_sub(a_combined_poi$lakeSR_id, 1, 2))
  ),
  
  # Landsat 4 is small enough for a single file
  tar_target(
    name = d_Landsat4_collated_data,
    command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths, 
                                   version_id = d_version_identifier,
                                   mission_info = d_mission_identifiers %>% 
                                     filter(mission_names == "Landsat 4"),
                                   dswe = c_dswe_types),
    pattern = map(c_dswe_types),
    packages = c("data.table", "tidyverse", "arrow")
  ),
  
  # Landsat 5, 7, 8 need to be separated by HUC2
  tar_target(
    name = d_collated_Landsat5_by_huc2,
    command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths,
                                   version_id = d_version_identifier,
                                   mission_info = d_mission_identifiers %>% 
                                     filter(mission_names == "Landsat 5"), 
                                   dswe = c_dswe_types, 
                                   HUC2 = d_unique_huc2),
    pattern = cross(c_dswe_types, d_unique_huc2), 
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main" # too big for multicore
  ),
  
  tar_target(
    name = d_collated_Landsat7_by_huc2,
    command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths,
                                   version_id = d_version_identifier,
                                   mission_info = d_mission_identifiers %>% 
                                     filter(mission_names == "Landsat 7"), 
                                   dswe = c_dswe_types, 
                                   HUC2 = d_unique_huc2),
    pattern = cross(c_dswe_types, d_unique_huc2), 
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main" # too big for multicore
  ),
  
  tar_target(
    name = d_collated_Landsat8_by_huc2,
    command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths,
                                   version_id = d_version_identifier,
                                   mission_info = d_mission_identifiers %>% 
                                     filter(mission_names == "Landsat 8"), 
                                   dswe = c_dswe_types, 
                                   HUC2 = d_unique_huc2),
    pattern = cross(c_dswe_types, d_unique_huc2), 
    packages = c("data.table", "tidyverse", "arrow"),
    deployment = "main" # too big for multicore
  ),
  
  # Landsat 9 is small enough to be a single file.
  tar_target(
    name = d_Landsat9_collated_data,
    command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths, 
                                   version_id = d_version_identifier,
                                   mission_info = d_mission_identifiers %>% 
                                     filter(mission_names == "Landsat 9"),
                                   dswe = c_dswe_types),
    pattern = map(c_dswe_types),
    packages = c("data.table", "tidyverse", "arrow")
  ),
  
  # make a list of the collated and sorted files created
  tar_target(
    name = d_all_sorted_Landsat_files,
    command = as.vector(c(d_Landsat4_collated_data, d_collated_Landsat5_by_huc2,
                          d_collateD_Landsat7_by_huc2, d_collated_Landsat8_by_huc2,
                          d_Landsat9_collated_data))
  )
  
)



