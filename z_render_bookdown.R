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
    # render bookdown, add req's of the above files in command prompt 
    tar_target(name = render_bookdown,
               command = {
                 # needed for row drop figs
                 d_qa_Landsat_files
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
                               cfg = lakeSR_config,
                               poi = a_combined_poi,
                               locs_run_date = "November 2024",
                               sites = p4_WQP_site_NHD_info,
                               visible_sites = p5_visible_sites,
                               yml = b_yml_poi,
                               LS5_for57 = e_LS5_forLS57corr_quantiles,
                               LS7_for57 = e_LS7_forLS57corr_quantiles,
                               LS7_for78 = e_LS7_forLS78corr_quantiles,
                               LS8_for78 = e_LS8_forLS78corr_quantiles,
                               LS8_for89 = e_LS8_forLS89corr_quantiles,
                               LS9_for89 = e_LS9_forLS89corr_quantiles,
                               LS57_match = e_LS57_DSWE1_matches,
                               LS78_match = e_LS78_DSWE1_matches,
                               LS89_match = e_LS89_DSWE1_matches
                             ))
               },
               packages = c("tidyverse", "bookdown", "sf", "tigris", "nhdplusTools", 
                            "tmap", "googledrive", "feather"),
               deployment = "main")
  )
  
} else {
  
  z_render_bookdown <- list(
    NULL
  )
  
}
