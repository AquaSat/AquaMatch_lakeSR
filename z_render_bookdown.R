z_render_bookdown <- list(
  tar_target(name = render_bookdown,
             command = {
               #poi_tasks_complete #this should always be the last target!
               render_book(input = "bookdown/",
                           params = list(
                             poi = combined_poi
                           ))
             },
             packages = c("tidyverse", "bookdown", "sf", "tigris", "nhdplusTools", "tmap"),
             deployment = "main")
)