#' @title Reformat location file for GEE
#' 
#' @description
#' Generalize dataset for GEE script use using the yaml file
#' 
#' @param yaml contents of the yaml .csv file
#' @returns filepath for the .csv of the reformatted location data or the message
#' 'Not configured to use site locations'. Silently saves 
#' the .csv in the `b_pull_Landsat_SRST_poi/in` directory path if configured for site
#' acquisition.
#' 
#' 
reformat_locations <- function(yaml, location_file) {
  locs <- location_file
  # store yaml info as objects
  lat <- yaml$latitude
  lon <- yaml$longitude
  id <- yaml$unique_id
  # apply objects to tibble
  locs <- locs %>% 
    rename_with(~c("Latitude", "Longitude", "id"), 
                any_of(c(lat, lon, id)))
  write_feather(locs, "b_pull_Landsat_SRST_poi/mid/locs.feather")
  "b_pull_Landsat_SRST_poi/mid/locs.feather"
}

