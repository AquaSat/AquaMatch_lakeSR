# Source functions for this {targets} list
tar_source("f_separate_by_huc2/src/")

# split files for long-term storage/data release -----------------------------

# This {targets} list separates the LS RS data by HUC2 for long-term storage in Drive
# and for data pubs. Metadata left as-is for data pub.

# if collating the sorted files in Drive admin update configuration
if (config::get(config = general_config)$update_and_share) {
  
  f_save_to_Drive <- list(
    # check for Drive folders and architecture per config setup
    tar_target(
      name = f_check_Drive_parent_folder,
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
      name = f_check_Drive_sorted_folder,
      command =  {
        f_check_Drive_parent_folder
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
      name = f_send_sorted_files_to_Drive,
      command = export_single_file(file_path = f_all_sorted_Landsat_files,
                                   drive_path = f_check_Drive_sorted_folder,
                                   google_email = lakeSR_config$google_email),
      packages = c("tidyverse", "googledrive"),
      pattern = map(e_all_sorted_Landsat_files)
    ), 
    
    tar_target(
      name = f_save_sorted_drive_info,
      command = {
        drive_ids <- f_send_sorted_files_to_Drive %>% 
          select(name, id)
        write_csv(drive_ids,
                  paste0("f_separate_by_huc2/out/Landsat_sorted_files_drive_ids_v",
                         d_version_identifier,
                         ".csv"))
        drive_ids
      },
      packages = c("tidyverse", "googledrive"),
      deployment = "main"
    )
    
    ## save handoffs ##
    
  )
  
} else { # no -f- group targets
 
  f_save_to_Drive <- NULL
  
}
