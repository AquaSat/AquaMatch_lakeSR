#' @title Download TNM NHD for AK
#' 
#' @description
#' Download the National Map file for the Best Resolution NHD file for the 
#' state of Alaska
#' 
#' @returns silently unzips the Alaska NHD file and deletes zip folder
#' 
#' 
download_AK = function() {
  # set timeout so that... this doesn't timeout
  options(timeout = 60000)
  # url for the NHD Best Resolution for 
  url = "https://prd-tnm.s3.amazonaws.com/StagedProducts/Hydrography/NHD/State/GPKG/NHD_H_Alaska_State_GPKG.zip"
  download.file(url, destfile = file.path("a_Calculate_Centers/nhd/", 
                                          "Alaska_NHD.zip"))
  unzip("a_Calculate_Centers/nhd/Alaska_NHD.zip", exdir = "a_Calculate_Centers/nhd/")
  # remove zip
  unlink("a_Calculate_Centers/nhd/Alaska_NHD.zip")
}