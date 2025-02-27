# Source functions for this {targets} list
tar_source("e_separate_by_huc2/src/")

# split files for long-term storage/data release -----------------------------

# This {targets} list separates the LS RS data by HUC2 for long-term storage in Drive
# and for data pubs. Metadata left as-is for data pub.

# if collating the sorted files in Drive admin update configuration
if (config::get(config = general_config)$update_sorted_in_Drive) {
  
  e_separate_by_huc2 <- list(
    
    tar_target(
      name = e_check_dir_structure,
      command = {
        # make directories if needed
        directories = c("e_separate_by_huc2/out/")
        walk(directories, function(dir) {
          if(!dir.exists(dir)){
            dir.create(dir)
          }
        })
      },
      cue = tar_cue("always"),
      deployment = "main",
    ),
    
    tar_target(
      name = e_unique_huc2,
      command = unique(str_sub(a_combined_poi$lakeSR_id, 1, 2))
    ),
    
    tar_target(
      name = e_Landsat4_collated_data,
      command = collate_qa_data(qa_files = d_qa_Landsat_file_paths, 
                                version_id = d_version_identifier,
                                mission_info = d_mission_identifiers %>% 
                                  filter(mission_names == "Landsat 4"),
                                dswe = c_dswe_types),
      pattern = map(c_dswe_types),
      packages = c("data.table", "tidyverse", "arrow")
    ),
    
    tar_target(
      name = e_collated_Landsat5_by_huc2,
      command = collate_qa_data(qa_files = d_qa_Landsat_file_paths,
                                version_id = d_version_identifier,
                                mission_info = d_mission_identifiers %>% 
                                  filter(mission_names == "Landsat 5"), 
                                dswe = c_dswe_types, 
                                HUC2 = e_unique_huc2),
      pattern = cross(c_dswe_types, e_unique_huc2), 
      packages = c("data.table", "tidyverse", "arrow"),
      deployment = "main" # too big for multicore
    ),
    
    tar_target(
      name = e_collated_Landsat7_by_huc2,
      command = collate_qa_data(qa_files = d_qa_Landsat_file_paths,
                                version_id = d_version_identifier,
                                mission_info = d_mission_identifiers %>% 
                                  filter(mission_names == "Landsat 7"), 
                                dswe = c_dswe_types, 
                                HUC2 = e_unique_huc2),
      pattern = cross(c_dswe_types, e_unique_huc2), 
      packages = c("data.table", "tidyverse", "arrow"),
      deployment = "main" # too big for multicore
    ),
    
    tar_target(
      name = e_collated_Landsat8_by_huc2,
      command = collate_qa_data(qa_files = d_qa_Landsat_file_paths,
                                version_id = d_version_identifier,
                                mission_info = d_mission_identifiers %>% 
                                  filter(mission_names == "Landsat 8"), 
                                dswe = c_dswe_types, 
                                HUC2 = e_unique_huc2),
      pattern = cross(c_dswe_types, e_unique_huc2), 
      packages = c("data.table", "tidyverse", "arrow"),
      deployment = "main" # too big for multicore
    ),
    
    tar_target(
      name = e_Landsat9_collated_data,
      command = collate_qa_data(qa_files = d_qa_Landsat_file_paths, 
                                version_id = d_version_identifier,
                                mission_info = d_mission_identifiers %>% 
                                  filter(mission_names == "Landsat 9"),
                                dswe = c_dswe_types),
      pattern = map(c_dswe_types),
      packages = c("data.table", "tidyverse", "arrow")
    ),
    
    # check for Drive folders and architecture per config setup
    tar_target(
      name = e_check_Drive_parent_folder,
      command = if (lakeSR_config$parent_Drive_folder != "") {
        tryCatch({
          drive_auth(lakeSR_config$google_email)
          drive_ls(lakeSR_config$parent_Drive_folder)
        }, error = function(e) {
          drive_mkdir(lakeSR_config$parent_Drive_folder)
        })
      },
      packages = "googledrive",
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = e_check_Drive_sorted_folder,
      command =  {
        e_check_Drive_parent_folder
        tryCatch({
          drive_auth(lakeSR_config$google_email)
          if (lakeSR_config$parent_Drive_folder != "") {
            version_path <- file.path(lakeSR_config$parent_Drive_folder,
                                      paste0("QA_sorted_v", lakeSR_config$run_date, "/"))
          } else {
            version_path <- paste0("QA_sorted_v", lakeSR_config$run_date, "/")
          }
          drive_ls(version_path)
        }, error = function(e) {
          # if there is an error, check both the 'collated_raw' folder and the 'version'
          # folder
          if (lakeSR_config$parent_Drive_folder != "") {
            drive_mkdir(path = lakeSR_config$parent_Drive_folder, name = paste0("QA_sorted_v", b_yml_poi$run_date))
          } else {
            drive_mkdir(name = paste0("QA_sorted_v", b_yml_poi$run_date))
          }
        })
        return(version_path)
      },
      packages = "googledrive",
      cue = tar_cue("always")
    )

        #   , 
    #   tar_target(
    #     name = save_huc2_files
    #   ),
    #   tar_target(
    #     name = store drive_ids
    #   )
    #   
  ) 
  
} else { # just create files locally
  
  e_separate_by_huc2 <- list(
    
    tar_target(
      name = e_check_dir_structure,
      command = {
        # make directories if needed
        directories = c("e_separate_by_huc2/out/")
        walk(directories, function(dir) {
          if(!dir.exists(dir)){
            dir.create(dir)
          }
        })
      },
      cue = tar_cue("always"),
      deployment = "main",
    ),
    
    tar_target(
      name = e_unique_huc2,
      command = unique(str_sub(a_combined_poi$lakeSR_id, 1, 2))
    ),
    
    tar_target(
      name = e_Landsat4_collated_data,
      command = collate_qa_data(qa_files = d_qa_Landsat_file_paths, 
                                version_id = d_version_identifier,
                                mission_info = d_mission_identifiers %>% 
                                  filter(mission_names == "Landsat 4"),
                                dswe = c_dswe_types),
      pattern = map(c_dswe_types),
      packages = c("data.table", "tidyverse", "arrow")
    ),
    
    tar_target(
      name = e_collated_Landsat5_by_huc2,
      command = collate_qa_data(qa_files = d_qa_Landsat_file_paths,
                                version_id = d_version_identifier,
                                mission_info = d_mission_identifiers %>% 
                                  filter(mission_names == "Landsat 5"), 
                                dswe = c_dswe_types, 
                                HUC2 = e_unique_huc2),
      pattern = cross(c_dswe_types, e_unique_huc2), 
      packages = c("data.table", "tidyverse", "arrow"),
      deployment = "main" # too big for multicore
    ),
    
    tar_target(
      name = e_collated_Landsat7_by_huc2,
      command = collate_qa_data(qa_files = d_qa_Landsat_file_paths,
                                version_id = d_version_identifier,
                                mission_info = d_mission_identifiers %>% 
                                  filter(mission_names == "Landsat 7"), 
                                dswe = c_dswe_types, 
                                HUC2 = e_unique_huc2),
      pattern = cross(c_dswe_types, e_unique_huc2), 
      packages = c("data.table", "tidyverse", "arrow"),
      deployment = "main" # too big for multicore
    ),
    
    tar_target(
      name = e_collated_Landsat8_by_huc2,
      command = collate_qa_data(qa_files = d_qa_Landsat_file_paths,
                                version_id = d_version_identifier,
                                mission_info = d_mission_identifiers %>% 
                                  filter(mission_names == "Landsat 8"), 
                                dswe = c_dswe_types, 
                                HUC2 = e_unique_huc2),
      pattern = cross(c_dswe_types, e_unique_huc2), 
      packages = c("data.table", "tidyverse", "arrow"),
      deployment = "main" # too big for multicore
    ),
    
    tar_target(
      name = e_Landsat9_collated_data,
      command = collate_qa_data(qa_files = d_qa_Landsat_file_paths, 
                                version_id = d_version_identifier,
                                mission_info = d_mission_identifiers %>% 
                                  filter(mission_names == "Landsat 9"),
                                dswe = c_dswe_types),
      pattern = map(c_dswe_types),
      packages = c("data.table", "tidyverse", "arrow")
    )
    
  )
  
}
