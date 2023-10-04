#' @title Make list of WRS tiles to map over
#' 
#' @description
#' Function to use the optimal shapefile from get_WRS_detection() to define
#' the list of WRS2 tiles for branching
#' 
#' @param detection_method optimal shapefile from get_WRS_detection()
#' @param yaml contents of the yaml .csv file
#' @returns list of WRS2 tiles
#' 
#' 
get_WRS_tiles <- function(detection_method, yaml) {
  WRS <- read_sf("b_pull_Landsat_SRST_poi/in/WRS2_descending.shp")
  if (detection_method == "site") {
    locations <- tar_read(locs)
    locs <- st_as_sf(locations, 
                     coords = c("Longitude", "Latitude"), 
                     crs = yaml$location_crs[1])
    if (st_crs(locs) == st_crs(WRS)) {
      WRS_subset <- WRS[locs,]
    } else {
      locs = st_transform(locs, st_crs(WRS))
      WRS_subset <- WRS[locs,]
    }
    write_csv(st_drop_geometry(WRS_subset), "b_pull_Landsat_SRST_poi/out/WRS_subset_list.csv")
    return(WRS_subset$PR)
  } else {
    if (detection_method == "centers") {
      centers <- tar_read(centers)
      centers_cntrd <- st_centroid(centers)
      if (st_crs(centers_cntrd) == st_crs(WRS)) {
        WRS_subset <- WRS[centers_cntrd,]
      } else {
        centers_cntrd = st_transform(centers_cntrd, st_crs(WRS))
        WRS_subset <- WRS[centers_cntrd,]
      }
      write_csv(st_drop_geometry(WRS_subset), "b_pull_Landsat_SRST_poi/out/WRS_subset_list.csv")
      return(WRS_subset$PR)
    } else {
      if (detection_method == "polygon") {
        poly <- tar_read(polygons)
        poly_cntrd <- st_centroid(poly)
        if (st_crs(poly_cntrd) == st_crs(WRS)) {
          WRS_subset <- WRS[poly_cntrd,]
        } else {
          poly_cntrd = st_transform(poly_cntrd, st_crs(WRS))
          WRS_subset <- WRS[poly_cntrd,]
        }
        write_csv(st_drop_geometry(WRS_subset), "b_pull_Landsat_SRST_poi/out/WRS_subset_list.csv")
        return(WRS_subset$PR)
      }
    }
  }
}

