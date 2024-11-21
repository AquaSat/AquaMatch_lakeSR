#' @title Calcuate POI center for NHDPlus lakes by HUC4
#' 
#' @description
#' for each HUC4, access the NHDPlus waterbodies sf object, subset to lakes/res/
#' impoundments, subset to >= 1ha, and calculate POI for each polygon. POI will 
#' calculate distance in meters using the UTM coordinate system and the POI as
#' Latitude/Longitude in WGS84 decimal degrees.
#' 
#' @param HUC4 text string; 4-digit huc from NHDPlus
#' 
#' @returns silently saves .csv file in mid folder of the POI centers and 
#' associated WBD metadata
#' 
#' 
calculate_centers_HUC4 <- function(HUC4) {
  
  message(paste0("Beginning center calculation for HUC 4 ", HUC4))

  # grab the huc {sf} object
  huc <- get_huc(id = HUC4, type = "huc04") %>% 
    st_make_valid()
  
  # grab the nhdplus waterbodies for huc4
  wbd <- get_waterbodies(huc)
  
  # make sure the result isn't null (for HI and others), and run the poi calculation 
  if (!is.null(wbd)) {
    wbd_filter <- wbd %>% 
      mutate(comid = as.character(comid)) %>% 
      filter(
        # filter the waterbodies for ftypes of interest. 390 = lake/pond; 436 = res;
        # 361 = playa 
        ftype %in% c("LakePond", "Reservoir"),
        # ...and for area > 1 hectare (0.01 km^2)
        areasqkm >= 0.01) 
    
    # grab smaller (<4ha) lakes/ponds that are characterized as intermittent by NHD
    intermittent <- wbd_filter %>% 
      filter(areasqkm < 0.04,
             fcode %in% c(39001, 39005))
    # and remove from dataset for processing time
    wbd_filter <- wbd_filter %>% filter(!comid %in% intermittent$comid)
    
    # try to make valid polygons 
    wbd_filter <- wbd_filter %>% 
      st_make_valid()
    
    # pull out geometries that are still invalid, if any
    invalid <- wbd_filter[!st_is_valid(wbd_filter), ]
    # if there are any, simplify (st_simplify usually fails here, so using 
    # rmapshaper::ms_simplify())
    if (nrow(invalid) > 0) {
      sf_use_s2(TRUE) # make sure that we're using spherical geometry here
      wbd_less <- wbd_filter[!wbd_filter$comid %in% invalid$comid, ]
      # for the rare cases that this doesn't work, we include a little error
      # handling here
      try(fixed <- invalid %>% 
            ms_simplify(keep = 0.75))
      if ("fixed" %in% ls()) {
        wbd_filter <- bind_rows(wbd_less, fixed)
      } else {
        wbd_filter <- wbd_less
      }
    }
  
    # check (again) for valid geometry and drop z coords (if they exist)
    wbd_valid <- wbd_filter %>% 
      rowwise() %>% 
      # drop z coordinate for processing ease
      st_zm(drop = T) %>% 
      # union the geos by feature
      st_union(by_feature = TRUE) %>% 
      # add a rowid for future steps
      rowid_to_column("r_id") %>% 
      ungroup()
    
    # some HUC4s have very few waterbodies that meet the above filtering. If we try 
    # to do this next step and there are no rows in the wbd dataframe, the pipeline
    # will error out
    if (nrow(wbd_valid) > 0) {
      # for each polygon, calculate a center. Because sf doesn't map easily, using a 
      # loop. Each loop adds a row the the poi_df dataframe.
      poi_df <- tibble(
        r_id = numeric(),
        comid = character(),
        poi_Longitude = numeric(),
        poi_Latitude = numeric(),
        poi_dist_m = numeric()
      )
      for (i in 1:length(wbd_valid[[1]])) {
        poi_df  <- poi_df %>% add_row()
        one_wbd <- wbd_valid[i, ]
        # transform crs, NHD is already in EPSG:4326, but just in case there is an outlier
        one_wbd <- st_transform(one_wbd, crs = "EPSG:4326")
        # get coordinates to calculate UTM zone. This is an adaptation of code from
        # Xiao Yang's code in EE - Yang, Xiao. (2020). Deepest point calculation 
        # for any given polygon using Google Earth Engine JavaScript API 
        # (Version v 1). Zenodo. https://doi.org/10.5281/zenodo.4136755
        coord_for_UTM <- one_wbd %>% st_coordinates()
        mean_x <- mean(coord_for_UTM[, 1])
        mean_y <- mean(coord_for_UTM[, 2])
        # calculate the UTM zone using the mean value of Longitude for the polygon
        utm_suffix <- as.character(ceiling((mean_x + 180) / 6))
        utm_code <- if_else(mean_y >= 0,
                            # EPSG prefix for N hemisphere
                            paste0('EPSG:326', utm_suffix),
                            # for S hemisphere
                            paste0('EPSG:327', utm_suffix))
        # transform wbd to UTM
        one_wbd_utm <- st_transform(one_wbd, 
                                    crs = utm_code)
        # get UTM coordinates
        coord <- one_wbd_utm %>% st_coordinates()
        x <- coord[, 1]
        y <- coord[, 2]
        # using coordinates, get the poi distance
        poly_poi <- poi(x,y, precision = 0.01)
        # add info to poi_df
        poi_df$r_id[i] = wbd_valid[i, ]$r_id
        poi_df$comid[i] = wbd_valid[i, ]$comid
        poi_df$poi_dist_m[i] = poly_poi$dist
        # make a point feature and re-calculate decimal degrees in WGS84
        point <- st_point(x = c(as.numeric(poly_poi$x),
                                as.numeric(poly_poi$y)))
        point <- st_sfc(point, crs = utm_code)
        point <- st_transform(point, crs = 'EPSG:4326')
        
        new_coords <- point %>% st_coordinates()
        poi_df$poi_Longitude[i] = new_coords[, 1]
        poi_df$poi_Latitude[i] = new_coords[, 2]
      }
      
      # drop geometry of waterbodies
      wbd_df <- wbd_valid %>% 
        st_drop_geometry()
      
      # join back in with all the info from the wbd_valid file
      poi_df <- wbd_df %>%
        right_join(., poi_df) %>% 
        mutate(location_type = "poi_center") 
      
    }
    
    #return the dataframe with location info
    return(poi_df %>% 
      mutate(r_id = paste(HUC4, r_id, sep = '_')) %>% 
      select(r_id, comid, poi_Latitude, poi_Longitude, poi_dist_m))
    
  } else { # if the object is null note it in a text doc to come back to. 
    message(paste0("HUC4 ", HUC4, " contains no waterbodies, noting in 'a_Calculate_Centers/mid/no_wbd_huc4.txt'"))
    if (!file.exists("a_Calculate_Centers/mid/no_wbd_huc4.txt")) {
      write_lines(HUC4, file = "a_Calculate_Centers/mid/no_wbd_huc4.txt")
      return(NULL)
    } else {
      text <- read_lines("a_Calculate_Centers/mid/no_wbd_huc4.txt")
      new_text <- c(text, HUC4)
      write_lines(new_text, "a_Calculate_Centers/mid/no_wbd_huc4.txt")
      return(NULL)
    }
  }
}

