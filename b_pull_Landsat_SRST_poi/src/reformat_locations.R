#' @title Reformat location file for GEE
#' 
#' @description
#' Generalize column names of location file for GEE script use using the yaml file
#' 
#' @param yaml contents of the yaml .csv file
#' @param locations dataframe of locations for earth engine pull which must have
#' a latitude, longitude and unique id column, specified in the yaml config file
#' 
#' @returns reformatted dataframe with generalized names for earth engine run
#' 
#' 
reformat_locations <- function(yaml, locations) {
  # store yaml info as objects
  lat <- yaml$latitude
  lon <- yaml$longitude
  id <- yaml$unique_id
  # apply objects to tibble and return
  locations %>% 
    rename_with(~c("Latitude", "Longitude", "id"), 
                any_of(c(lat, lon, id)))
}

