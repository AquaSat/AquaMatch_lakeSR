#' @title Collate the NHDPlusHR POI data (with AK removed) with the AK NHD Best
#' Resolution data
#' 
#' @param NHDHR_data target name of NHDPlusHR POI data with AK removed
#' @param AK_best_res_data target name of NHD Best Resolution POI data of AK
#' 
#' @returns filepath of feather file of collated NHDPlusHR and NHD Best
#' Resolution POI data 
#' 
#' 
collate_NHDHR_AK <- function(NHDHR_data, AK_best_res_data) {
  # add data source to the nhdplushr data
  NHDHR <- NHDHR_data %>% 
    mutate(data_source = 'NHDPlusHR') %>% 
    # and let's un coerce some of these columns from character to numeric
    mutate(across(c(AreaSqKM, n_feat, rowid, poi_dist, poi_Latitude, poi_Longitude),
                  ~ as.numeric(.)))
  # rename columns to match NHDPlusHR data
  AK <- AK_best_res_data %>% 
    rename(GNIS_ID = gnis_id,
           GNIS_Name = gnis_name,
           REACHCODE = reachcode,
           FTYPE = ftype,
           FCODE = fcode)
  # join and save!
  full_join(NHDHR, AK) %>% 
    write_feather(., 
                  file.path("a_Calculate_Centers/out/",
                            "NHDPlusHR_NHDBestRes_POI_center_locs.feather"))
  # return filepath for target
  file.path("a_Calculate_Centers/out/",
            "NHDPlusHR_NHDBestRes_POI_center_locs.feather")
}
