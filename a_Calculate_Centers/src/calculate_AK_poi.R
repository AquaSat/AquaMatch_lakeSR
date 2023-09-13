#' @title Calcuate POI center for NHD Best Resolution waterbodies from The 
#' National Map
#' 
#' @description
#' for the Best Resolution NHD file for the state of Alaska, download the 
#' National Map file, subset to lakes/res/impoundments, subset to >= 1ha, and 
#' calculate POI for each polygon
#' 
#' @returns silently saves .csv file in mid folder of the POI centers and 
#' associated WBD metadata
#' 
#' 
calculate_AK_poi <- function() {
  # set timeout so that... this doesn't timeout
  options(timeout = 60000)
  # url for the NHD Best Resolutoin for 
  url = "https://prd-tnm.s3.amazonaws.com/StagedProducts/Hydrography/NHD/State/GPKG/NHD_H_Alaska_State_GPKG.zip"
  download.file(url, destfile = file.path("a_Calculate_Centers/nhd/", 
                                          "Alaska_NHD.zip"))
  unzip("a_Calculate_Centers/nhd/Alaska_NHD.zip", exdir = "a_Calculate_Centers/nhd/")
  # remove zip
  unlink("a_Calculate_Centers/nhd/Alaska_NHD.zip")
  
  # open the NHDWaterbody layer, coerce to a {sf} object
  wbd <- st_read(file.path("a_Calculate_Centers/nhd/",
                                 "NHD_H_Alaska_State_GPKG.gpkg"),
                 layer = 'NHDWaterbody')
  
  # filter the waterbodies for ftypes of interest. 390 = lake/pond; 436 = res;
  # 361 = playa
  wbd <- wbd %>% 
    filter(ftype %in% c(390, 436, 361)) 
  
  # filter for area > 1 hectare (0.01 km^2)
  wbd <- wbd %>% 
    filter(areasqkm >= 0.01) 
  
  # check for valid geometry and drop z coords (if they exist)
  wbd <- wbd %>% 
    # there are a few weirdos that are multisurface geometires that {sf} doesn't
    # know what to do with, so we're dropping those. as a note, st_cast() will 
    # not reclassify, nor st_union() for that geometry type. 
    rowwise() %>% 
    # drop z coordinate for processing ease
    st_zm(drop = T) %>% 
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
    poi_dist = numeric()
  )
  for (i in 1:length(wbd[[1]])) {
    coord = wbd[i,] %>% st_coordinates()
    x = coord[,1]
    y = coord[,2]
    poly_poi = poi(x,y, precision = 0.00001)
    poi_df  <- poi_df %>% add_row()
    poi_df$rowid[i] = wbd[i,]$rowid
    poi_df$Permanent_Identifier[i] = as.character(wbd[i,]$permanent_identifier)
    poi_df$poi_Longitude[i] = poly_poi$x
    poi_df$poi_Latitude[i] = poly_poi$y
    poi_df$poi_dist[i] = poly_poi$dist
  }
    
  # sometimes there is more than one geometry per PermId. Let's limit this to the 
  # one that is the furthest distance from a shoreline (poi_dist)
  poi_df <- poi_df %>% 
    group_by(Permanent_Identifier) %>% 
    arrange(desc(poi_dist), .by_group = TRUE) %>% 
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
