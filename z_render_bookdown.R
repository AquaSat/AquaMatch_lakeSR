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
  tar_file(name = refs,
           command = "bookdown/z-Refs.Rmd"),
  # render bookdown, add req's of the above files in command prompt 
  tar_target(name = render_bookdown,
             command = {
               index
               background
               locations
               settings
               landsat_background
               srst_pull
               refs
               render_book(input = "bookdown/",
                           params = list(
                             poi = a_combined_poi,
                             locs_run_date = "November 2024"
                           ))
             },
             packages = c("tidyverse", "bookdown", "sf", "tigris", "nhdplusTools", "tmap"),
             deployment = "main")
)