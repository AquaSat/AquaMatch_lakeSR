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
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths, 
                                     version_id = d_version_identifier,
                                     mission_info = d_mission_identifiers %>% 
                                       filter(mission_names == "Landsat 4"),
                                     dswe = c_dswe_types),
      pattern = map(c_dswe_types),
      packages = c("data.table", "tidyverse", "arrow")
    ),
    
    tar_target(
      name = e_collated_Landsat5_by_huc2,
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths,
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
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths,
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
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths,
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
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths, 
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
                                      paste0("QA_sorted_v", d_version_identifier, "/"))
          } else {
            version_path <- paste0("QA_sorted_v", d_version_identifier, "/")
          }
          drive_ls(version_path)
        }, error = function(e) {
          # if there is an error, check both the 'collated_raw' folder and the 'version'
          # folder
          if (lakeSR_config$parent_Drive_folder != "") {
            drive_mkdir(path = lakeSR_config$parent_Drive_folder, name = paste0("QA_sorted_v", d_version_identifier))
          } else {
            drive_mkdir(name = paste0("QA_sorted_v", d_version_identifier))
          }
        })
        return(version_path)
      },
      packages = "googledrive",
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = e_all_sorted_Landsat_files,
      command = as.vector(c(e_Landsat4_collated_data, e_Landsat5_collated_by_huc2,
                            e_Landsat7_collated_by_huc2, e_Landsat8_collated_by_huc2,
                            e_Landsat9_collated_data))
    ),
    
    tar_target(
      name = e_send_sorted_files_to_Drive,
      command = export_single_file(file_path = e_all_sorted_Landsat_files,
                                   drive_path = e_check_Drive_sorted_folder,
                                   google_email = lakeSR_config$google_email),
      packages = c("tidyverse", "googledrive"),
      pattern = map(e_all_sorted_Landsat_files)
    ), 
    
    tar_target(
      name = e_save_sorted_drive_info,
      command = {
        drive_ids <- e_send_sorted_files_to_Drive %>% 
          select(name, id)
        write_csv(drive_ids,
                  paste0("e_separate_by_huc2/out/Landsat_sorted_files_drive_ids_v",
                         d_version_identifier,
                         ".csv"))
        drive_ids
      },
      packages = c("tidyverse", "googledrive"),
      deployment = "main"
    )
    
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
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths, 
                                     version_id = d_version_identifier,
                                     mission_info = d_mission_identifiers %>% 
                                       filter(mission_names == "Landsat 4"),
                                     dswe = c_dswe_types),
      pattern = map(c_dswe_types),
      packages = c("data.table", "tidyverse", "arrow")
    ),
    
    tar_target(
      name = e_collated_Landsat5_by_huc2,
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths,
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
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths,
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
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths,
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
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths, 
                                     version_id = d_version_identifier,
                                     mission_info = d_mission_identifiers %>% 
                                       filter(mission_names == "Landsat 9"),
                                     dswe = c_dswe_types),
      pattern = map(c_dswe_types),
      packages = c("data.table", "tidyverse", "arrow")
    )
    
  )
  
}
