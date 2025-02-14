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
  
  rm(early, late)
  gc()
  
  matched
}