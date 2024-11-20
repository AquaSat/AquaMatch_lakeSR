#' @title Calcuate POI center for NHD Best Resolution waterbodies from The 
#' National Map for States that had no waterbodies in the HUC4s via NHDPlus v2
#' 
#' @description
#' using the downloaded NHD file subset to lakes/res/impoundments, subset to >= 1ha, and 
#' calculate POI for each polygon. POI will calculate distance in meters using 
#' the UTM coordinate system and the POI as Latitude/Longitude in WGS84 decimal 
#' degrees.
#' 
#' @returns silently saves .csv file in mid folder of the POI centers and 
#' associated WBD metadata
#' 
#' 
calculate_bestres_centers <- function(HUC4) {
  
  # set timeout so that... this doesn't timeout
  options(timeout = 60000)

  # url for the NHD Best Resolution for HUC4
  url = paste0("https://prd-tnm.s3.amazonaws.com/StagedProducts/Hydrography/NHD/HU4/GPKG/NHD_H_", HUC4, "_HU4_GPKG.zip")
  download.file(url, destfile = file.path("a_Calculate_Centers/nhd/", 
                                          paste0(HUC4, ".zip")))
  unzip(file.path("a_Calculate_Centers/nhd/", 
                  paste0(HUC4, ".zip")), 
        exdir = "a_Calculate_Centers/nhd/")
  # remove zip
  unlink(file.path("a_Calculate_Centers/nhd/", 
                   paste0(HUC4, ".zip")))
  
  # open the NHDWaterbody layer, coerce to a {sf} object
  wbd <- st_read(file.path("a_Calculate_Centers/nhd/",
                           paste0("NHD_H_", HUC4, "_HU4_GPKG.gpkg")),
                 layer = "NHDWaterbody")
  
  wbd <- wbd %>% 
    filter(
      # filter the waterbodies for ftypes of interest. 390 = lake/pond; 436 = res
      ftype %in% c(390, 436),
      # ...and for area > 1 hectare (0.01 km^2)
      areasqkm >= 0.01) 
  
  # subset smaller (<4ha) lakes/ponds that are characterized as intermittent
  intermittent <- wbd %>% 
    filter(
      areasqkm < 0.04,
      fcode %in% c(39001, 39005)
    )
  # remove intermittent from wbd for processing ease
  wbd_filter <- wbd %>% filter(!permanent_identifier %in% intermittent$permanent_identifier)
  
  # check for valid polygons
  wbd_filter <- wbd_filter %>% 
    st_make_valid()
  
  # pull out geometries that are still invalid, if any
  invalid <- wbd_filter[!st_is_valid(wbd_filter), ]
  # if there are any, simplify (st_simplify usually fails here, so using 
  # rmapshaper::ms_simplify())
  if (nrow(invalid) > 0) {
    sf_use_s2(TRUE) # make sure that we're using spherical geometry here
    wbd_less <- wbd_filter[!wbd_filter$comid %in% invalid$comid, ]
    fixed <- invalid %>% 
      ms_simplify(keep = 0.75)
    wbd_filter <- bind_rows(wbd_less, fixed)
  }
  
  # check for valid geometry and drop z coords (if they exist)
  wbd_valid <- wbd_filter %>% 
    rowwise() %>% 
    # drop z coordinate for processing ease
    st_zm(drop = T) %>% 
    # union the geos by feature
    st_union(by_feature = TRUE) %>% 
    # add a rowid for future steps
    rowid_to_column("r_id") %>% 
    ungroup()
  
  # for each polygon, calculate a center. Because sf doesn't map easily, using a 
  # loop. Each loop adds a row the the poi_df dataframe.
  poi_df <- tibble(
    r_id = numeric(),
    permanent_identifier = character(),
    poi_Longitude = numeric(),
    poi_Latitude = numeric(),
    poi_dist_m = numeric()
  )
    if(nrow(wbd_valid) > 0) {
    for (i in 1:length(wbd_valid[[1]])) {
      poi_df  <- poi_df %>% add_row()
      one_wbd <- wbd_valid[i, ]
      # transform crs, NHD is already in EPSG:4326, but just in case there is an outlier
      one_wbd <- st_transform(one_wbd, crs = "EPSG:4326")
      # get coordinates to calculate UTM zone. This is an adaptation of code from
      # Xiao Yang's code in EE - Yang, Xiao. (2020). Deepest point calculation 
      # for any given polygon using Google Earth Engine JavaScript API 
      # (Version v1). Zenodo. https://doi.org/10.5281/zenodo.4136755
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
      poi_df$permanent_identifier[i] = as.character(wbd_valid[i, ]$permanent_identifier)
      poi_df$poi_dist_m[i] = poly_poi$dist
      # make a point feature and re-calculate decimal degrees in WGS84
      point <- st_point(x = c(as.numeric(poly_poi$x),
                              as.numeric(poly_poi$y)))
      point <- st_sfc(point, crs = utm_code)
      point <- st_transform(st_sfc(point), crs = 'EPSG:4326')
      
      new_coords <- point %>% st_coordinates()
      poi_df$poi_Longitude[i] = new_coords[, 1]
      poi_df$poi_Latitude[i] = new_coords[, 2]
    }
    
    # create a simplified df aggregated if there are multiple features for any 
    # given PermID
    wbd_df <- wbd %>% 
      st_drop_geometry() 
    
    # join back in with all the info from the wbd file
    poi_df <- wbd_df %>%
      right_join(., poi_df) %>% 
      mutate(location_type = "poi_center",
             data_source = "NHD Best Resolution") 
    
    # clean up workspace for quicker processing
    # remove the fp and all contents completely before next HUC4
    unlink(file.path("a_Calculate_Centers/nhd/", paste0("NHD_H_", HUC4, "_HU4_GPKG.gpkg")))
    unlink(file.path("a_Calculate_Centers/nhd/", paste0("NHD_H_", HUC4, "_HU4_GPKG.xml")))
    unlink(file.path("a_Calculate_Centers/nhd/", paste0("NHD_H_", HUC4, "_HU4_GPKG.jpg")))
  
    #return the dataframe with location info
    return(poi_df %>% 
             mutate(r_id = paste(HUC4, r_id, sep = "_")) %>% 
             select(r_id, permanent_identifier, poi_Latitude, poi_Longitude, poi_dist_m))
    } else { # if there are no waterbodies that meet criteria, return null
      NULL
    }

}
