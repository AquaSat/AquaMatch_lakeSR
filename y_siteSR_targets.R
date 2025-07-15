# Grab files from siteSR for bookdown -----------------------------

# This {targets} group pulls information from the siteSR workflow to use in the 
# Bookdown. If the configuration setting `update_bookown` is set to FALSE, this 
# list will be empty.

# check to see if bookdown should be updated, 
# otherwise these targets are not needed
if (config::get(config = general_config)$update_bookdown) {
  
  y_siteSR_list <- list(
    
    # Grab location of the local {targets} siteSR pipeline OR error if
    # the location doesn't exist yet
    tar_target(
      name = config_siteSR_directory,
      command = if(dir.exists(lakeSR_config$siteSR_repo_directory)) {
        lakeSR_config$siteSR_repo_directory
      } else {
        #Throw an error if the pipeline does not exist
        stop("The siteSR pipeline is not at the location specified in the
             config.yml file. Check the location specified as `siteSR_repo_directory`
             in the config.yml file and rerun the pipeline.")
      },
      cue = tar_cue("always")
    ), 
    
    tar_file_read(
      name = a_sites_Drive_id,
      command = file.path(config_siteSR_directory, 
                          "a_compile_sites/out/all_site_locations_drive_id.csv"),
      read = read_csv(!!.x),
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = a_all_site_locations,
      command = {
        # filter for most recent id
        most_recent <- a_sites_Drive_id %>% 
          arrange(desc(name)) %>% 
          slice(1)
        retrieve_target(target = "a_all_site_locations",
                        id_df = most_recent, 
                        local_folder = "y_siteSR_targets/out/", 
                        google_email = lakeSR_config$google_email,
                        version_date = str_sub(most_recent$name, -14 , -5),
                        file_type = ".rds")
      },
      packages = c("sf", "tidyverse", "googledrive")
    ),
    
    tar_file_read(
      name = a_sites_with_NHD_drive_id,
      command = file.path(config_siteSR_directory, 
                          "a_compile_sites/out/sites_with_NHD_drive_id.csv"),
      read = read_csv(!!.x),
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = a_sites_with_NHD_info,
      command = {
        most_recent <- a_sites_with_NHD_drive_id %>% 
          arrange(desc(name)) %>% 
          slice(1)
        retrieve_target(target = "a_sites_with_NHD_info",
                        id_df = most_recent, 
                        local_folder = "y_siteSR_targets/out/", 
                        google_email = lakeSR_config$google_email,
                        version_date = str_sub(most_recent$name, -14 , -5),
                        file_type = ".rds")
      },
      packages = c("tidyverse", "googledrive")
    ), 
    
    
    # load visible sites
    tar_file_read(
      name = b_visible_site_Drive_id,
      command = file.path(config_siteSR_directory, 
                          "b_determine_RS_visibility/out/visible_site_id.csv"),
      read = read_csv(!!.x),
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = b_visible_sites,
      command = {
        most_recent <- b_visible_site_Drive_id %>% 
          arrange(desc(name)) %>% 
          slice(1)
        retrieve_target(target = "b_visible_sites",
                        id_df = most_recent, 
                        local_folder = "y_siteSR_targets/out/", 
                        google_email = lakeSR_config$google_email,
                        version_date = str_sub(most_recent$name, -14 , -5),
                        file_type = ".rds")
      },
      packages = c("tidyverse", "googledrive")
    )
    
  )
  
} else { # return an empty -y- list
  
  y_siteSR_list <- list(
    NULL
  )
  
}
