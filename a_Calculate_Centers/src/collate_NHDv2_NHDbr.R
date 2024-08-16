#' @title Collate the NHDPlus POI data with the AK NHD Best
#' Resolution data
#' 
#' @param NHD_data target name of NHDPlus POI data
#' @param best_res_data target name of NHD Best Resolution POI data 
#' 
#' @returns filepath of feather file of collated NHDPlus and NHD Best
#' Resolution POI data 
#' 
#' 
collate_NHDv2_NHDbr <- function(NHD_poi, best_res_poi) {
  # add data source to the nhdplus data
  NHD <- NHD_poi %>% 
    mutate(data_source = 'NHDPlus')

  # join and save!
  full_join(NHD, best_res) %>% 
    write_feather(., 
                  file.path("a_Calculate_Centers/out/",
                            "NHDPlus_NHDBestRes_POI_center_locs.feather"))
  # return filepath for target
  file.path("a_Calculate_Centers/out/",
            "NHDPlus_NHDBestRes_POI_center_locs.feather")
}
