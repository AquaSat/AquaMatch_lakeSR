
# check to see if bookdown should be updated, 
# otherwise these targets are not needed
if (config::get(config = general_config)$update_bookdown) {
  
  y_siteSR_list <- list(
    
    tar_file_read(
      name = p4_harmonized_sites_Drive_id,
      command = file.path(config_siteSR_directory, 
                          "4_compile_sites/out/harmonized_sites_drive_id.csv"),
      read = read_csv(!!.x),
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = p4_harmonized_sites,
      command = {
        # filter for most recent id
        most_recent <- p4_harmonized_sites_Drive_id %>% 
          arrange(desc(name)) %>% 
          slice(1)
        retrieve_target(target = "p4_harmonized_sites",
                        id_df = most_recent, 
                        local_folder = "y_siteSR_targets/out/", 
                        google_email = lakeSR_config$google_email,
                        version_date = str_sub(most_recent$name, -14 , -5),
                        file_type = ".rds")
      },
      packages = c("sf", "tidyverse", "googledrive")
    ),
    
    tar_file_read(
      name = p4_collated_sites_Drive_id,
      command = file.path(config_siteSR_directory, 
                          "4_compile_sites/out/collated_sites_drive_id.csv"),
      read = read_csv(!!.x),
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = p4_WQP_site_NHD_info,
      command = {
        most_recent <- p4_collated_sites_Drive_id %>% 
          arrange(desc(name)) %>% 
          slice(1)
        retrieve_target(target = "p4_WQP_site_NHD_info",
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
      name = p5_visible_site_Drive_id,
      command = file.path(config_siteSR_directory, 
                          "5_determine_RS_visibility/out/visible_site_id.csv"),
      read = read_csv(!!.x),
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = p5_visible_sites,
      command = {
        most_recent <- p5_visible_site_Drive_id %>% 
          arrange(desc(name)) %>% 
          slice(1)
        retrieve_target(target = "p5_visible_sites",
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
