#' @title Get Matched Landsat Data for Paired Missions
#'
#' @description
#' This function loads, processes, and matches Landsat data from paired missions 
#' ('early' and 'late') based on specified criteria. This function uses data.table
#' syntax for efficiency and memory use minimization.
#'
#' @param files Character string specifying the directory path and file names of the feather files.
#' @param dswe Character string specifying the Dynamic Surface Water Extent (DSWE) criteria.
#' @param qa_version Character string specifying the qa version identifier (YYYY-MM-DD)
#' @param early_LS_mission Character string specifying the early Landsat mission (e.g., "Landsat5", "Landsat7").
#' @param late_LS_mission Character string specifying the late Landsat mission (e.g., "Landsat8", "Landsat9").
#'
#' @returns A data.table containing matched Landsat data from early and late periods.
#'
#'
get_matches <- function(files, dswe, gee_version, qa_version,
                        early_LS_mission, late_LS_mission){
  
  # load filtered data ------------------------------------------------------
  
  early <- files[grepl(early_LS_mission, files)] %>% 
    .[grepl(qa_version, .)] %>%
    .[grepl(paste0("_", dswe, "_"), .)] %>% 
    read_feather(.)
  
  late <- files[grepl(late_LS_mission, files)] %>% 
    .[grepl(qa_version, .)] %>% 
    .[grepl(paste0("_", dswe, "_"), .)] %>% 
    read_feather(.)
  
  
  # prep data ---------------------------------------------------------------
  
  # convert to DT by reference
  setDT(early)
  # rename date and sat_id columns for join
  setnames(early, old = c("date", "sat_id"), new = c("early_date", "early_sat_id"))
  # grab pathrow from source
  early[, early_pathrow := str_extract(source, "(?<=_)\\d{6}(?=_)")]
  
  # convert to DT by reference
  setDT(late)
  # rename date and sat_id columns for join
  setnames(late, old = c("date", "sat_id"), new = c("late_date", "late_sat_id"))
  # grab pathrow from source
  late[, late_pathrow := str_extract(source, "(?<=_)\\d{6}(?=_)")]
  
  # filter conservatively ---------------------------------------------------
  
  metadata_file_early <- switch(EXPR = early_LS_mission,
                                Landsat4 = paste0("d_qa_filter_sort/sort/lakeSR_metadata_LS457_export_", qa_version, ".csv"),
                                Landsat5 = paste0("d_qa_filter_sort/sort/lakeSR_metadata_LS457_export_", qa_version, ".csv"), 
                                Landsat7 = paste0("d_qa_filter_sort/sort/lakeSR_metadata_LS457_export_", qa_version, ".csv"), 
                                Landsat8 = paste0("d_qa_filter_sort/sort/lakeSR_metadata_LS89_export_", qa_version, ".csv"), 
                                Landsat9 = paste0("d_qa_filter_sort/sort/lakeSR_metadata_LS89_export_", qa_version, ".csv"))
  
  metadata_file_late <- switch(EXPR = late_LS_mission,
                               Landsat4 = paste0("d_qa_filter_sort/sort/lakeSR_metadata_LS457_export_", qa_version, ".csv"),
                               Landsat5 = paste0("d_qa_filter_sort/sort/lakeSR_metadata_LS457_export_", qa_version, ".csv"), 
                               Landsat7 = paste0("d_qa_filter_sort/sort/lakeSR_metadata_LS457_export_", qa_version, ".csv"), 
                               Landsat8 = paste0("d_qa_filter_sort/sort/lakeSR_metadata_LS89_export_", qa_version, ".csv"), 
                               Landsat9 = paste0("d_qa_filter_sort/sort/lakeSR_metadata_LS89_export_", qa_version, ".csv"))
  
  
  ## do some additional conservative filtering for best quality data
  # filter for scene-level cloud cover < 50
  metadata_early <- read_csv(metadata_file_early) %>% 
    filter(sat_id %in% early$early_sat_id, CLOUD_COVER <= 50)
  metadata_late <- read_csv(metadata_file_late) %>% 
    filter(sat_id %in% late$late_sat_id, CLOUD_COVER <= 50)
  
  # filter in place using data.table syntax - low cloud cover, no clouds
  # in aoi, no flags for temp min/max
  early <- early[
    early_sat_id %in% metadata_early$sat_id &
      prop_clouds == 0 &
      flag_temp_min == 0 &
      flag_temp_max == 0
  ]
  setnames(early, "mission", "early_mission")
  late <- late[
    late_sat_id %in% metadata_late$sat_id &
      prop_clouds == 0 &
      flag_temp_min == 0 &
      flag_temp_max == 0
  ]
  setnames(late, "mission", "early_mission")
  
  
  # make paired dataset ------------------------------------------------------
  
  # set keys by date range for matching
  early[, start := early_date - days(1)]
  early[, end := early_date + days(1)]
  setkeyv(early, c("lakeSR_id", "start", "end"))
  
  late[, start := late_date]
  late[, end := late_date]
  setkeyv(late, c("lakeSR_id", "start", "end"))
  
  matched <- foverlaps(x = early, y = late, 
                       by.x = key(early),
                       by.y = key(late), 
                       type = "any", nomatch = NULL, mult = "all")
  
  # do some cache-clearing
  rm(early, late)
  gc()
  
  # add dswe info
  matched[, dswe := dswe]
  
  matched
  
}