z_render_bookdown <- list(
  tar_target(name = render_bookdown,
             command = {
               poi_tasks_complete #this should always be the last target!
               render_book(input = "bookdown/",
                           params = list(
                             all_pts = combined_poi_points,
                             ak_pts = AK_poi_points
                           ))
             },
             packages = "bookdown")
)