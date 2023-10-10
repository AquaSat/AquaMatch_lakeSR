#' @title Make list of WRS tiles to map over
#' 
#' @description
#' Using the reformatted locations for the POI data, get the list of pathrows to 
#' iterate over and add pathrow to location file in order to subset and speed up
#' the python workflow in `run_GEE_per_tile`
#' 
#' @param formatted_locations the POI locations for lakeSR acquisition
#' @param yaml contents of the yaml .csv file
#' @returns list of WRS2 tiles, silently outputs a .feather file with an added
#' column containing the pathrow for subsetting in the python workflow
#' 
#' 
get_WRS_tiles_poi <- function(formatted_locations, yaml) {
  # get the WRS2 shapefile
  WRS <- read_sf("b_pull_Landsat_SRST_poi/in/WRS2_descending.shp")
  # and the poi locations
  locs <- st_as_sf(formatted_locations, 
                   coords = c("Longitude", "Latitude"), 
                   crs = yaml$location_crs[1])
  # get the list of WRS tiles that intersect
  if (st_crs(locs) == st_crs(WRS)) {
    WRS_subset <- WRS[locs,]
  } else {
    locs = st_transform(locs, st_crs(WRS))
    WRS_subset <- WRS[locs,]
  }
  # save the file for use later (we don't track this, but need it for the python
  # workflow)
  write_csv(st_drop_geometry(WRS_subset), "b_pull_Landsat_SRST_poi/out/WRS_subset_list.csv")
  
  # return the unique PR list
  unique(WRS_subset$PR)
}

