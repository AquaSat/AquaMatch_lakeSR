#' @title Calcuate POI center for NHDPlusHR lakes by HUC4
#' 
#' @description
#' for each HUC4, download the HR NHDPlus waterbody file, subset to lakes/res/
#' impoundments, subset to >= 1ha, and calculate POI for each polygon
#' 
#' @param HUC4 text string; 4-digit huc from NHDPlus
#' 
#' @returns silently saves .csv file in mid folder of the POI centers and 
#' associated WBD metadata
#' 
#' 
calculate_centers_HUC4 <- function(HUC4) {
  #set timeout for longer per issue #341: https://github.com/DOI-USGS/nhdplusTools/issues
  options(timeout = 60000)
  
  # download the nhdplushr huc4, and note the filepath
  fp <- download_nhdplushr(nhd_dir = "a_Calculate_Centers/nhd/", HUC4)
  
  # open the NHDWaterbody layer, coerce to a {sf} object
  wbd <- get_nhdplushr(fp, layers = "NHDWaterbody") %>%
    bind_rows() %>% 
    st_as_sf() 
  
  # filter the waterbodies for ftypes of interest. 390 = lake/pond; 436 = res;
  # 361 = playa
  wbd <- wbd %>% 
    filter(FTYPE %in% c(390, 436, 361)) 
  
  # filter for area > 1 hectare (0.01 km^2)
  wbd <- wbd %>% 
    filter(AreaSqKM >= 0.01) 
  
  # check for valid geometry and drop z coords (if they exist)
  wbd <- wbd %>% 
    # there are a few weirdos that are multisurface geometires that {sf} doesn't
    # know what to do with, so we're dropping those. 
    filter(!grepl('SURFACE', st_geometry_type(Shape))) %>% 
    rowwise() %>% 
    st_zm(drop = T) %>% 
    st_make_valid() 
  
  # for each polygon, calculate a center. Because sf doesn't map easily, using a 
  # loop. Each loop adds a row the the poi_df dataframe.
  poi_df <- tibble(
    Permanent_Identifier = character(),
    poi_Longitude = numeric(),
    poi_Latitude = numeric(),
    poi_dist = numeric()
  )
  for (i in 1:length(wbd[[1]])) {
    coord = wbd[i,] %>% st_coordinates()
    x = coord[,1]
    y = coord[,2]
    poly_poi = poi(x,y, precision = 0.00001)
    poi_df  <- poi_df %>% add_row()
    poi_df$Permanent_Identifier[i] = wbd[i,]$Permanent_Identifier
    poi_df$poi_Longitude[i] = poly_poi$x
    poi_df$poi_Latitude[i] = poly_poi$y
    poi_df$poi_dist[i] = poly_poi$dist
  }
  # join back in with all the info from the wbd file
  poi_df <- wbd %>%
    st_drop_geometry() %>% 
    left_join(., poi_df) %>% 
    mutate(location_type = "poi_center") %>% 
    # remove some columns that are no longer pertinent
    select(-c(Shape_Length, Shape_Area, Elevation, Resolution, VisibilityFilter))
  
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
  
  write_csv(poi_geo, file.path('a_Calculate_Centers/mid/',
                               paste0('poi_centers_huc4_', HUC4, '.csv')))
  
  # clean up workspace for quicker processing
  # remove the fp and all contents completely before next HUC4
  unlink(fp, recursive = T, force = T, expand = T)
  # and clear unused mem
  rm(wbd, poi_geo, poi_df)
}
