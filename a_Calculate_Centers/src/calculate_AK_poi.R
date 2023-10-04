#' @title Calcuate POI center for NHD Best Resolution waterbodies from The 
#' National Map for the state of Alaksa
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
calculate_AK_poi <- function() {
  # open the NHDWaterbody layer, coerce to a {sf} object
  wbd <- st_read(file.path("a_Calculate_Centers/nhd/",
                                 "NHD_H_Alaska_State_GPKG.gpkg"),
                 layer = 'NHDWaterbody')
  
 wbd <- wbd %>% 
  filter(
    # filter the waterbodies for ftypes of interest. 390 = lake/pond; 436 = res;
    # 361 = playa
    ftype %in% c(390, 436, 361),
    # ...and for area > 1 hectare (0.01 km^2)
    areasqkm >= 0.01) 
  
  # check for valid geometry and drop z coords (if they exist)
  wbd <- wbd %>% 
    # drop z coordinate for processing ease
    st_zm(drop = T) %>% 
    rowwise() %>% 
    # make sure the geos are valid
    st_make_valid() %>% 
    # union the geos by feature
    st_union(by_feature = TRUE) %>% 
    # add a rowid for future steps
    rowid_to_column()
  

  # for each polygon, calculate a center. Because sf doesn't map easily, using a 
  # loop. Each loop adds a row the the poi_df dataframe.
  poi_df <- tibble(
    rowid = numeric(),
    Permanent_Identifier = character(),
    poi_Longitude = numeric(),
    poi_Latitude = numeric(),
    poi_dist_m = numeric()
  )
  for (i in 1:length(wbd[[1]])) {
    poi_df  <- poi_df %>% add_row()
    one_wbd = wbd[i,]
    # get coordinates to calculate UTM zone
    coord_for_UTM = one_wbd %>% st_coordinates()
    mean_x = mean(coord_for_UTM[,1])
    mean_y = mean(coord_for_UTM[,2])
    utm_suffix = as.character(ceiling((mean_x + 180) / 6))
    utm_code = if_else(mean_y >= 0,
                       paste0('EPSG:326', utm_suffix),
                       paste0('EPSG:327', utm_suffix))
    # transform wbd to UTM
    one_wbd_utm = st_transform(one_wbd, 
                               crs = utm_code)
    # get UTM coordinates
    coord = one_wbd_utm %>% st_coordinates()
    x = coord[,1]
    y = coord[,2]
    # using coordinates, get the poi distance
    poly_poi = poi(x,y, precision = 0.01)
    # add info to poi_df
    poi_df$rowid[i] = wbd[i,]$rowid
    poi_df$Permanent_Identifier[i] = as.character(wbd[i,]$permanent_identifier)
    poi_df$poi_dist_m[i] = poly_poi$dist
    # make a point feature and re-calculate decimal degrees in WGS84
    point = st_point(x = c(as.numeric(poly_poi$x),
                           as.numeric(poly_poi$y)))
    point = st_sfc(point, crs = utm_code)
    point = st_transform(st_sfc(point), crs = 'EPSG:4326')
    
    new_coords = point %>% st_coordinates()
    poi_df$poi_Longitude[i] = new_coords[,1]
    poi_df$poi_Latitude[i] = new_coords[,2]
    }
    
  # sometimes there is more than one geometry per PermId. Let's limit this to the 
  # one that is the furthest distance from a shoreline (poi_dist)
  poi_df <- poi_df %>% 
    group_by(Permanent_Identifier) %>% 
    arrange(desc(poi_dist_m), .by_group = TRUE) %>% 
    slice(1)
  
  # create a simplified df aggregated if there are multiple features for any 
  # given PermID
  wbd_df <- wbd %>% 
    st_drop_geometry() %>% 
    group_by(permanent_identifier) %>% 
    summarise(AreaSqKM = sum(areasqkm, na.rm = TRUE),
              n_feat = n(),
              across(all_of(c("gnis_id", "gnis_name", "reachcode",
                     "ftype", "fcode")),
                     ~ toString(unique(.)))) %>% 
    rename(Permanent_Identifier = permanent_identifier)
  
  # join back in with all the info from the wbd file
  poi_df <- wbd_df %>%
    right_join(., poi_df) %>% 
    mutate(location_type = "poi_center",
           data_source = "NHD Best Resolution") 
  
  # and now, we'll coerce to a {sf} using the poi lat/lon so we can recalc the
  # lat/long to WGS84 - these CRS are usually interoperable, but because I'm not
  # a GIS expert, I'm going to add this extra step.
  poi_geo <- st_as_sf(poi_df, 
                      coords = c("poi_Longitude", "poi_Latitude"), 
                      crs = st_crs(wbd)) %>% 
    st_transform(., "EPSG:4326")
  
  # then we'll grab the Lat/Lon in the updated CRS, drop the geo column and 
  # export as a .csv
  poi_geo <- poi_geo %>% 
    rowwise() %>% 
    mutate(poi_Longitude = geometry[[1]][1],
           poi_Latitude = geometry[[1]][2]) %>% 
    st_drop_geometry()
  
  write_feather(poi_geo, file.path("a_Calculate_Centers/out/",
                               paste0("AK_NHD_BestRes_POI_center_locs.feather")))
    
  # clean up workspace for quicker processing
  # remove the fp and all contents completely before next HUC4
  unlink("a_Calculate_Centers/nhd/NHD_H_Alaska_State_GPKG.gpkg")
  unlink("a_Calculate_Centers/nhd/NHD_H_Alaska_State_GPKG.jpg")
  unlink("a_Calculate_Centers/nhd/NHD_H_Alaska_State_GPKG.xml")
  
  # and clear unused mem
  rm(wbd, poi_geo, poi_df)

}
