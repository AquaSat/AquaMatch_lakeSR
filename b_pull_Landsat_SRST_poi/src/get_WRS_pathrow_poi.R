#' @title Make list of WRS pathrow to map over
#' 
#' @description
#' Using the reformatted locations for the POI data, get the list of pathrows to 
#' iterate over and add pathrow to location file in order to subset and speed up
#' the python workflow in `run_GEE_per_tile`
#' 
#' @param locations the POI locations for lakeSR acquisition
#' @param yml contents of the yml .csv file
#' 
#' @returns list of WRS2 tiles, silently outputs a csv file with the subset of WRS
#' tiles
#' 
#' 
get_WRS_pathrow_poi <- function(locations, yml) {
  # get the WRS2 shapefile
  WRS <- read_sf("b_pull_Landsat_SRST_poi/in/WRS2_descending.shp")
  # and the poi locations
  locs <- st_as_sf(locations, 
                   coords = c("Longitude", "Latitude"), 
                   crs = yml$location_crs)
  # get the list of WRS tiles that intersect
  if (st_crs(locs) == st_crs(WRS)) {
    WRS_subset <- WRS[locs, ]
  } else {
    locs = st_transform(locs, st_crs(WRS))
    WRS_subset <- WRS[locs, ]
  }
  # save the file for use later (we don't track this, but need it for the python
  # workflow)
  write_csv(st_drop_geometry(WRS_subset), "b_pull_Landsat_SRST_poi/out/WRS_subset_list.csv")
  
  # return the unique PR list
  unique(WRS_subset$PR)
}

