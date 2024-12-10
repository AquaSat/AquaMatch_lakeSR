z_render_bookdown <- list(
  # track files for changes
  tar_file(name = index,
           command = "bookdown/index.Rmd"),
  tar_file(name = intro,
           command = "bookdown/01-Introduction.Rmd"),
  tar_file(name = locations,
           command = "bookdown/02-Data_Acquisition_Locations.Rmd"),
  # render bookdwon, 
  tar_target(name = render_bookdown,
             command = {
               index
               intro
               locations
               #poi_tasks_complete #this should always be the last target!
               render_book(input = "bookdown/",
                           params = list(
                             poi = a_combined_poi
                           ))
             },
             packages = c("tidyverse", "bookdown", "sf", "tigris", "nhdplusTools", "tmap"),
             deployment = "main")
)