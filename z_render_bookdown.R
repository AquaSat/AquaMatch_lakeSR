# Render bookdown -----------------------------

# check to see if rendering bookdown
if (config::get(config = general_config)$update_bookdown) {
  
  z_render_bookdown <- list(
    # track files for changes
    tar_file(name = index,
             command = "bookdown/index.Rmd"),
    tar_file(name = background,
             command = "bookdown/01-Background.Rmd"),
    tar_file(name = locations,
             command = "bookdown/02-Data_Acquisition_Locations.Rmd"),
    tar_file(name = settings,
             command = "bookdown/03-Acquisition_Software_Settings.Rmd"), 
    tar_file(name = landsat_background,
             command = "bookdown/04-Landsat_C2_SRST.Rmd"),
    tar_file(name = srst_pull,
             command = "bookdown/05-lakeSR_LS_C2_SRST.Rmd"),
    tar_file(name = post_hoc_qa,
             command = "bookdown/06-post_hoc_qa.Rmd"),
    tar_file(name = handoffs,
             command = "bookdown/07-intermission_handoffs.Rmd"),
    tar_file(name = refs,
             command = "bookdown/z-Refs.Rmd"),
    
    # knitr::include_graphics() is not working in the context of targets and the
    # bookdown, so the next few targets manually move images created in the 
    # workflow to reference in the bookdown.
    tar_target(
      name = move_lakeSR_drop_images,
      command = {
        # Define source and destination directories
        source_dir <- "d_qa_filter_sort/out/"
        lake_dir <- "bookdown/images/lakeSR/"
        dir.create(lake_dir, recursive = T, showWarnings = FALSE)
        # Get list of files to copy
        files_to_copy <- list.files(source_dir, full.names = TRUE)
        # Copy files
        file.copy(from = files_to_copy, to = lake_dir, overwrite = TRUE)
      },
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = move_siteSR_drop_images,
      command = {
        # Define source and destination directories
        source_dir <- file.path(config_siteSR_directory, "7_qa_stack/out/")
        site_dir <- "bookdown/images/siteSR/"
        dir.create(site_dir, recursive = TRUE, showWarnings = FALSE)
        # Get list of files to copy
        files_to_copy <- list.files(source_dir, full.names = TRUE)
        # Copy files
        file.copy(from = files_to_copy, to = site_dir, overwrite = TRUE)
      },
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = move_gardner_DSWE1_images,
      command = {
        # Define source and destination directories
        source_dir <- "e_calculate_handoffs/gardner/"
        handoff_dir <- "bookdown/images/gardner/handoffs/"
        resid_dir <- "bookdown/images/gardner/residuals/"
        dir.create(handoff_dir, recursive = T, showWarnings = FALSE)
        dir.create(resid_dir, recursive = T, showWarnings = FALSE)
        # Get list of files to copy
        handoff_to_copy <- list.files(source_dir, full.names = TRUE) %>% 
          .[grepl("DSWE1_", .)] %>% 
          .[grepl("handoff.jpg", .)]
        resid_to_copy <- list.files(source_dir, full.names = TRUE) %>% 
          .[grepl("DSWE1_", .)] %>% 
          .[grepl("residual", .)] 
        # Copy files
        file.copy(from = handoff_to_copy, to = handoff_dir, overwrite = TRUE)
        file.copy(from = resid_to_copy, to = resid_dir, overwrite = TRUE)
      },
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = move_roy_dem_DSWE1_images,
      command = {
        # Define source and destination directories
        source_dir <- "e_calculate_handoffs/roy/"
        handoff_dir <- "bookdown/images/roy/handoffs/"
        resid_dir <- "bookdown/images/roy/residuals/"
        dir.create(handoff_dir, recursive = T)
        dir.create(resid_dir, recursive = T)
        # Get list of files to copy
        handoff_to_copy <- list.files(source_dir, full.names = TRUE) %>% 
          .[grepl("DSWE1_", .)] %>% 
          .[grepl("handoff.jpg", .)]
        resid_to_copy <- list.files(source_dir, full.names = TRUE) %>% 
          .[grepl("DSWE1_", .)] %>% 
          .[grepl("residual", .)] %>% 
          .[grepl("deming", .)]
        # Copy files
        file.copy(from = handoff_to_copy, to = handoff_dir, overwrite = TRUE)
        file.copy(from = resid_to_copy, to = resid_dir, overwrite = TRUE)      
      },
      cue = tar_cue("always")
    ),
    
    # render bookdown, add req's of the above files in command prompt 
    tar_target(name = render_bookdown,
               command = {
                 # needed for row drop figs
                 d_qa_Landsat_files
                 move_siteSR_drop_images
                 move_lakeSR_drop_images
                 # needed for correction figs
                 e_calculate_gardner_LS5_to_LS7
                 e_calculate_gardner_LS8_to_LS7
                 e_calculate_gardner_LS7_to_LS8
                 e_Roy_LS5_to_LS7_DSWE1_handoff
                 e_Roy_LS8_to_LS7_DSWE1_handoff
                 e_Roy_LS7_to_LS8_DSWE1_handoff 
                 e_Roy_LS5_to_LS7_DSWE1a_handoff
                 e_Roy_LS8_to_LS7_DSWE1a_handoff
                 e_Roy_LS7_to_LS8_DSWE1a_handoff 
                 move_gardner_DSWE1_images
                 move_roy_dem_DSWE1_images
                 # list chapters
                 index
                 background
                 locations
                 settings
                 landsat_background
                 srst_pull
                 post_hoc_qa
                 handoffs
                 refs
                 render_book(input = "bookdown/",
                             params = list(
                               poi = a_poi_with_flags,
                               locs_run_date = lakeSR_config$collated_version,
                               sites = a_sites_with_NHD_info,
                               visible_sites = b_visible_sites,
                               LS5_for57 = e_LS5_forLS57corr_quantiles,
                               LS7_for57 = e_LS7_forLS57corr_quantiles,
                               LS7_for78 = e_LS7_forLS78corr_quantiles,
                               LS8_for78 = e_LS8_forLS78corr_quantiles,
                               LS57_match = e_LS57_DSWE1_matches,
                               LS78_match = e_LS78_DSWE1_matches,
                               coefficients = e_collated_handoffs
                             ))
               },
               packages = c("tidyverse", "bookdown", "sf", "tigris", "nhdplusTools", 
                            "tmap", "googledrive", "feather", "kableExtra", "cowplot",
                            "ggthemes"),
               deployment = "main")
  )
  
} else {
  
  z_render_bookdown <- list(
    NULL
  )
  
}
