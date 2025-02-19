#' @title Get Matched Landsat Data for Paired Missions
#'
#' @description
#' This function loads, processes, and matches Landsat data from paired missions 
#' ('early' and 'late') based on specified criteria. This function uses data.table
#' syntax for efficiency and memory use minimization.
#'
#' @param dir Character string specifying the directory path where the input files are located.
#' @param dswe Character string specifying the Dynamic Surface Water Extent (DSWE) criteria.
#' @param version Character string specifying the version of the data.
#' @param early_LS_mission Character string specifying the early Landsat mission (e.g., "LT05", "LE07").
#' @param late_LS_mission Character string specifying the late Landsat mission (e.g., "LC08", "LC09").
#' @param early_path_prefix Character string specifying the path prefix for early period data (e.g., "00", "01").
#' @param late_path_prefix Character string specifying the path prefix for late period data (e.g., "00", "01").
#'
#' @returns A data.table containing matched Landsat data from early and late periods.
#'
#'
get_matches <- function(dir, dswe, version,
                        early_LS_mission, late_LS_mission, 
                        early_path_prefix, late_path_prefix){
  
  # load filtered data ------------------------------------------------------
  
  early <- read_feather(file.path(dir, paste0("LSC2_poi_collated_sites_",
                                              early_LS_mission, 
                                              "_",
                                              early_path_prefix,
                                              "_",
                                              dswe,
                                              "_",
                                              version, 
                                              "_filtered.feather")))
  late <- read_feather(file.path(dir, paste0("LSC2_poi_collated_sites_",
                                             late_LS_mission, 
                                             "_",
                                             late_path_prefix,
                                             "_",
                                             dswe,
                                             "_",
                                             version, 
                                             "_filtered.feather")))
  
  
  # prep data ---------------------------------------------------------------
  
  # convert to DT by reference
  setDT(early)
  # add date column
  early[, early_date := ymd(str_extract(`system:index`, "(?<=_)\\d{8}(?=_)"))] 
  # add lakeSR_id column
  early[, lakeSR_id := str_extract(`system:index`, "\\d{4}_\\d+$")]
  # and reformat `system:index`
  early[, early_sat_id := str_extract(`system:index`, ".*(?=_\\d{4}_\\d+$)")]
  # grab pathrow from source
  early[, early_pathrow := str_extract(source, "(?<=_)\\d{6}(?=_)")]
  
  # convert to DT by reference
  setDT(late)
  # add date column
  late[, late_date := ymd(str_extract(`system:index`, "(?<=_)\\d{8}(?=_)"))] 
  # add lakeSR_id column
  late[, lakeSR_id := str_extract(`system:index`, "\\d{4}_\\d+$")]
  # and reformat `system:index`
  late[, late_sat_id := str_extract(`system:index`, ".*(?=_\\d{4}_\\d+$)")]
  # grab pathrow from source
  late[, late_pathrow := str_extract(source, "(?<=_)\\d{6}(?=_)")]
  
  
  # make paired dataset ------------------------------------------------------
  
  # set keys by date range for matching
  early[, start := early_date - days(1)]
  early[, end := early_date + days(1)]
  setkeyv(early, c("lakeSR_id", "start", "end"))
  
  late[, start := late_date]
  late[, end := late_date]
  setkeyv(late, c("lakeSR_id", "start", "end"))
  
  matched <-foverlaps(x = early, y = late, 
                      by.x=key(early),
                      by.y=key(late), 
                      type="any", nomatch=NULL, mult="all")
  
  # do some cache-clearing
  rm(early, late)
  gc()
  
  # add dswe info
  matched[, dswe := dswe]

  matched
  
}