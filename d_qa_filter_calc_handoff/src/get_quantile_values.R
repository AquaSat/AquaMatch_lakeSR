#' @title Calculate Quantile Values for Landsat Data
#'
#' @description
#' This function processes Landsat data files, filters them based on specified criteria,
#' and calculates quantile values for selected bands. This function uses data.table
#' syntax for efficiency and memory use minimization.
#'
#' @param qa_files Character vector of file paths to quality-assured Landsat data files.
#' @param mission_id Character string specifying the Landsat mission ID (e.g., "LT05", "LC08").
#' @param version_id Character string specifying the version of the data.
#' @param dswe Character string specifying the Dynamic Surface Water Extent (DSWE) criteria.
#' @param start_date Date object specifying the start of the date range for analysis.
#' @param end_date Date object specifying the end of the date range for analysis.
#' @param for_corr Character string indicating which mission these data are meant
#' to be paired with.
#' @param record_length_prop Numeric value specifying the proportion of the date range required for inclusion.
#' @param bands Character vector specifying the band names to analyze.
#'
#' @returns A data.table containing quantile values for each specified band, along with metadata.
#' Returns NULL if no matching files are found.
#'
get_quantile_values <- function(qa_files, mission_id, version_id, 
                                dswe, start_date, end_date, for_corr,
                                record_length_prop, bands) {
  
  # filter files for those in arguments
  fps <- qa_files %>% 
    .[grepl(mission_id, .)] %>% 
    .[grepl(version_id, .)] %>% 
    .[grepl(paste0("_", dswe, "_"), .)]
  
  # quick reality check
  if (length(fps) > 0) {
    
    # get and filter data
    data <- map(fps, 
                \(fp) {
                  dt <- read_feather(fp) 
                  # convert to DT by reference
                  setDT(dt)
                  # add date column
                  dt[, date := ymd(str_extract(`system:index`, "(?<=_)\\d{8}(?=_)"))] 
                  # add lakeSR_id column
                  dt[, lakeSR_id := str_extract(`system:index`, "\\d{4}_\\d+$")]
                  # and reformat `system:index`
                  dt[, sat_id := str_extract(`system:index`, ".*(?=_\\d{4}_\\d+$)")]
                  # filter for dates and return
                  dt[date >= start_date & date <= end_date]
                }) %>% 
      rbindlist() 
    
    # calculate record length needed for inclusion
    record_length = round(time_length(interval(start_date,
                                               end_date),
                                      "years")*record_length_prop, 0)
    
    # get ids that have more than 10yrs of data
    ids <- data[, .(n_years = uniqueN(year(date))), by = .(lakeSR_id)][n_years >= record_length]
    # filter data for those ids
    data <- data[ids, on = .(lakeSR_id)]
    # determine number of scenes in summary
    scenes <- data[, .(n_scenes = uniqueN(sat_id))]
    # calculate quantile values for each band
    quantile_seq <- seq(0.01, 0.99, 0.01)
    map(bands,
        \(b) {
          q_dt <- data %>% 
            pull(!!b) %>%
            quantile(quantile_seq) %>% 
            as.data.table(., keep.rownames = TRUE)
          set_names(q_dt, c("quantile", b))
        }) %>% 
      reduce(., full_join) %>% 
      mutate(n_scenes = scenes$n_scenes,
             n_rows = nrow(data),
             mission = mission_id, 
             for_corr = for_corr,
             dswe = dswe,
             version = version_id)
    
  }
  
}
