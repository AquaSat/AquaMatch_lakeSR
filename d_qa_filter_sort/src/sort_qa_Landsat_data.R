#' @title Sort/collate QA'd Landsat data for data sharing
#' 
#' @description
#' This function sorts large Landsat mission data sets (LS 5-8) into .csv data sets by
#' HUC2 and smaller Landsat mission data sets (LS4/9) into a single .csv file per
#' mission for data publication
#' 
#' @param qa_files vector of file paths to the qa'd Landsat data files 
#' to be processed. Assumed to be arrow::feather() files. 
#' @param version_id Character string specifying the version of the data.
#' @param mission_info data.frame/tibble/data.table containing the columns 'mission_id'
#' (e.g. 'LT05') and 'mission_names' (e.g. 'Landsat 5'). 
#' @param dswe character string indicating the DSWE setting to filter the files
#' by.
#' @param HUC2 character string indicating the HUC2 the data belong to
#' 
#' @returns file path name where output file is stored. Silently saves a .csv file
#' of the data in the folder path `d_qa_filter_sort/sort`.
#' 
sort_qa_Landsat_data <- function(qa_files,
                         version_id,
                         mission_info, 
                         dswe, 
                         HUC2 = NULL) {
  
  # filter files for those in arguments
  fps <- qa_files %>% 
    .[grepl(mission_info$mission_id, .)] %>% 
    .[grepl(version_id, .)] %>% 
    .[grepl(paste0("_", dswe, "_"), .)]
  
  # quick reality check
  if (length(fps) > 0) {
    
    if (!is.null(HUC2)) {
      
      # get and process data, filter by HUC2
      data <- map(fps, 
                  \(fp) {
                    dt <- read_feather(fp) 
                    # convert to DT by reference
                    setDT(dt)
                    dt[, `:=`(
                      lakeSR_id = stri_extract_last_regex(`system:index`, "\\d{4}_\\d+$"), 
                      dswe_filter = stri_extract_first_regex(fp, "DSWE\\d+a?"),
                      mission = stri_extract_first_regex(`system:index`, "L[A-Z]0\\d"), 
                      date = as.IDate(stri_extract_first_regex(`system:index`, "\\d{8}"), format = "%Y%m%d")
                    )]
                    dt[, huc2 := str_sub(lakeSR_id, 1, 2)]
                    # filter for desired huc2
                    dt[huc2 == HUC2]
                  }) %>% 
        rbindlist() 
      
      # and now pull those new columns to the front
      new_cols <- c("lakeSR_id", "dswe_filter", "mission", "sat_id", "date", "huc2")
      setcolorder(data, c(new_cols, setdiff(names(data), new_cols)))
      
      #make a file path name
      save_to_fpn <- file.path("d_qa_filter_sort/sort/",
                               paste0("HUC2_",
                                      HUC2,
                                      "_", 
                                      str_replace(mission_info$mission_names, " ", ""),
                                      "_", 
                                      dswe,
                                      "_v",
                                      version_id, 
                                      ".csv"))
      
      # write that feather file in the out folder
      write_csv(data, save_to_fpn)
      
      return(save_to_fpn)
      
    } else {
      
      # get and process data
      data <- map(fps, 
                  \(fp) {
                    dt <- read_feather(fp) 
                    # convert to DT by reference
                    setDT(dt)
                    dt[, `:=`(
                      lakeSR_id = stri_extract_last_regex(`system:index`, "\\d{4}_\\d+$"), 
                      dswe_filter = stri_extract_first_regex(fp, "DSWE\\d+a?"),
                      mission = stri_extract_first_regex(`system:index`, "L[A-Z]0\\d"), 
                      date = as.IDate(stri_extract_first_regex(`system:index`, "\\d{8}"), format = "%Y%m%d")
                    )]
                    dt[, huc2 := str_sub(lakeSR_id, 1, 2)]
                  }) %>% 
        rbindlist() 
      
      # and now pull those new columns to the front
      new_cols <- c("lakeSR_id", "dswe_filter", "mission", "sat_id", "date", "huc2")
      setcolorder(data, c(new_cols, setdiff(names(data), new_cols)))
      
      
      #make a file path name
      save_to_fpn <- file.path("d_qa_filter_sort/sort/",
                               paste0(str_replace(mission_info$mission_names, " ", ""),
                                      "_", 
                                      dswe,
                                      "_v",
                                      version_id, 
                                      ".csv"))
      
      # write that feather file in the out folder
      write_csv(data, save_to_fpn)
      
      return(save_to_fpn)
    } 
    
  }
  
}