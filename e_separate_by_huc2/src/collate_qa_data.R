collate_qa_data <- function(qa_files,
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
                    # filter for dates and return
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
                                      ".feather"))
      
      # write that feather file in the out folder
      write_feather(data, save_to_fpn, compression = "lz4")
      
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
                                      ".feather"))
      
      # write that feather file in the out folder
      write_feather(data, save_to_fpn, compression = "lz4")
      
      return(save_to_fpn)
    } 
    
  }
  
}