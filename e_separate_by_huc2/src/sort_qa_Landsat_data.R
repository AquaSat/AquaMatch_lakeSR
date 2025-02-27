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
#' @returns file path name where output file is stored
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
                    # add date column
                    dt[, date := ymd(str_extract(`system:index`, "(?<=_)\\d{8}(?=_)"))] 
                    # add lakeSR_id column
                    dt[, lakeSR_id := str_extract(`system:index`, "\\d{4}_\\d+$")]
                    # add huc2
                    dt[, huc2 := str_sub(lakeSR_id, 1, 2)]
                    # and reformat `system:index`
                    dt[, sat_id := str_extract(`system:index`, ".*(?=_\\d{4}_\\d+$)")]
                    # filter for desired huc2
                    dt[huc2 == HUC2]
                  }) %>% 
        rbindlist() 
      
      #make a file path name
      save_to_fpn <- file.path("e_separate_by_huc2/out",
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
                    # add date column
                    dt[, date := ymd(str_extract(`system:index`, "(?<=_)\\d{8}(?=_)"))] 
                    # add lakeSR_id column
                    dt[, lakeSR_id := str_extract(`system:index`, "\\d{4}_\\d+$")]
                    # add huc2
                    dt[, huc2 := str_sub(lakeSR_id, 1, 2)]
                    # and reformat `system:index`
                    dt[, sat_id := str_extract(`system:index`, ".*(?=_\\d{4}_\\d+$)")]
                  }) %>% 
        rbindlist() 
      
      #make a file path name
      save_to_fpn <- file.path("e_separate_by_huc2/out",
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