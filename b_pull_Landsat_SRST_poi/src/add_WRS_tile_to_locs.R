#' @title Add pathrow to locations file
#' 
#' @description
#' Using the output of the previous target `WRS_tiles_poi`, and the output of 
#' the target `ref_locations_poi`, add WRS pathrow information to the locations 
#' file.
#' 
#' @param WRS_pathrows list of pathrows to iterate over, output of target `WRS_tiles_poi`
#' @param locations dataframe of locations, output of target `ref_locations_poi`
#' @param yaml contents of the yaml .csv file
#' 
#' @returns silently saves a .feather file containing the location information 
#' with the WRS2 pathrow and returns the filepath of resulting .feather file
#' 
#' @note
#' This step will result in more rows than the locations file, because a single 
#' location in space can fall into multiple pathrows.
#' 
#' 
add_WRS_tile_to_locs <- function(WRS_pathrows, locations, yaml) {
  # get the WRS2 shapefile
  WRS <- read_sf("b_pull_Landsat_SRST_poi/in/WRS2_descending.shp")
  # make locations into a {sf} object
  locs <- st_as_sf(locations, 
                   coords = c("Longitude", "Latitude"), 
                   crs = yaml$location_crs[1])
  # map over each path-row, adding the pathrow to the site. Note, this will create
  # a larger number of rows than the upstream file, because sites can be in more
  # than one pathrow. 
  locs_with_WRS <- map(WRS_pathrows, function(path_row) {
    one_PR <- WRS %>% filter(PR == path_row)
    x <- locs[one_PR, ]
    x$WRS2_PR = path_row
    st_drop_geometry(x)
    }) %>% 
    bind_rows()
  #save the file
  write_feather(locs_with_WRS, "b_pull_Landsat_SRST_poi/out/locations_with_WRS2_pathrows.feather")
  "b_pull_Landsat_SRST_poi/out/locations_with_WRS2_pathrows.feather"
}
