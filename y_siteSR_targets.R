
# check to see if rendering bookdown
if (config::get(config = general_config)$update_bookdown) {
  
  tar_source("src/")
  
  y_siteSR_list <- list(
    
    tar_target(
      name = y_siteSR_targets,
      command = read_csv(file.path(config_siteSR_directory, 
                                   "99_compile_drive_ids/out/",
                                   "target_drive_ids.csv")),
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = p4_WQP_site_NHD_info,
      command = retrieve_data(target = "p4_WQP_site_NHD_info",
                              id_df = y_siteSR_targets,
                              local_folder = tempdir(),
                              stable = FALSE,
                              google_email = b_yml_poi$google_email),
      packages = c("tidyverse", "googledrive"),
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = p5_visible_sites,
      command = retrieve_data(target = "p5_visible_sites",
                              id_df = y_siteSR_targets,
                              local_folder = tempdir(),
                              stable = FALSE,
                              google_email = b_yml_poi$google_email),
      packages = c("tidyverse", "googledrive"),
      cue = tar_cue("always")
    )
    
  )
  
} else { # return an empty -y- list
  
  y_siteSR_list <- list(
    NULL
  )
  
}
