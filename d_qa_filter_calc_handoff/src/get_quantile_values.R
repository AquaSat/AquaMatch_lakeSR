# use data.table syntax for efficiency

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
             mission = mission_id, 
             to_mission = to_mission_id,
             dswe = dswe,
             version = version_id)
    
  }
  
}
