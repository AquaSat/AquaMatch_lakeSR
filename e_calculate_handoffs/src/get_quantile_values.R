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
#' @param location_info dataframe that includes location information and flags 
#' from the -a- group (a_calculate_centers)
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
get_quantile_values <- function(qa_files, mission_id, version_id, location_info, 
                                dswe, start_date, end_date, for_corr,
                                record_length_prop, bands) {
  
  mission_name <- switch(EXPR = mission_id,
                         LT04 = "Landsat4",
                         LT05 = "Landsat5", 
                         LE07 = "Landsat7", 
                         LC08 = "Landsat8", 
                         LC09 = "Landsat9")
  
  # filter files for those in arguments
  fp <- qa_files %>% 
    .[grepl(mission_name, .)] %>% 
    .[grepl(version_id, .)] %>% 
    .[grepl(paste0("_", dswe, "_"), .)]
  
  # quick reality check, return null if no files
  if (length(fp) == 0) { return( NULL ) }
  
  # read in and filter for date range of overlap
  data <- read_feather(fp) 
  # convert to DT by reference
  setDT(data)
  # filter for dates and return
  data[date >= start_date & date <= end_date]

  # make sure all the band data are numeric values
  walk(.x = bands[bands %in% names(data)], 
       .f = ~ set(data, j = .x, value = as.numeric(data[[.x]])))
  
  # calculate record length needed for inclusion
  record_length <- round(time_length(interval(start_date, end_date),
                                     "years")*record_length_prop, 0)
  
  # perform some quick filters based on the flags we created upstream
  # grab the sites that are in this dataset
  sites <- location_info %>% 
    filter(lakeSR_id %in% data$lakeSR_id)
  
  # calculate quantile values for each band
  quantile_seq <- seq(0.01, 0.99, 0.01)
  optical_bands <- bands[bands != "med_SurfaceTemp"]
  
  # check to make sure there are bands from argument input and run for optical
  if (length(optical_bands) > 0) {
    
    # grab sites most certainly without shoreline contamination for optical bands
    optical_no_shore <- sites %>% 
      filter(flag_optical_shoreline == 0)
    # and now filter the optical data for those sites with less possible shoreline
    # contamination
    filtered_optical_data <- data %>% 
      filter(lakeSR_id %in% optical_no_shore$lakeSR_id)
    # get ids that have the necessary record length of data - need to specify lubridate here
    ids_optical <- filtered_optical_data[, .(n_years = uniqueN(lubridate::year(date))), by = .(lakeSR_id)][n_years >= record_length]
    # filter data for those ids
    filtered_optical_data <- filtered_optical_data[ids_optical, on = .(lakeSR_id)]
    # determine number of scenes in summary
    optical_scenes <- filtered_optical_data[, .(n_scenes = uniqueN(sat_id))]
    optical_quantiles <- map(optical_bands,
                             \(b) {
                               q_vec <- filtered_optical_data %>% 
                                 .[[b]] %>%
                                 quantile(., quantile_seq)
                               q_dt <- data.table(quantile = names(q_vec), value = unname(q_vec))
                               setnames(q_dt, "value", b)
                               return( q_dt )
                             }) 
    
    optical_quantiles <- optical_quantiles %>% 
      reduce(., full_join) %>% 
      mutate(n_scenes = optical_scenes$n_scenes,
             n_rows = nrow(filtered_optical_data),
             mission = mission_id, 
             for_corr = for_corr,
             dswe = dswe,
             version = version_id)
    
  } else {
    
    optical_quantiles <- NULL
    
  }
  
  # and also check for thermal
  thermal_band <- bands[bands == "med_SurfaceTemp"] 
  
  # check to make sure there are bands from argument input and run for optical
  if (length(thermal_band) > 0) {
    
    # define the column to assess visibility
    thermal_flag <- switch(EXPR = mission_id, 
                           LT04 = "flag_thermal_MSS_shoreline",
                           LT05 = "flag_thermal_MSS_shoreline",
                           LE07 = "flag_thermal_ETM_shoreline",
                           LC08 = "flag_thermal_TIRS_shoreline",
                           LC09 = "flag_thermal_TIRS_shoreline")
    
    # filter sites for no flag in thermal band, no clouds in buffered area
    thermal_no_shore <- filter(sites, .data[[thermal_flag]] == 0)
    filtered_thermal_data <- data %>% 
      filter(lakeSR_id %in% thermal_no_shore$lakeSR_id,
             !is.na(med_SurfaceTemp), 
             prop_clouds == 0)
    
    # get ids that have the necessary length of data - need to specify lubridate here
    ids_thermal <- filtered_thermal_data[, .(n_years = uniqueN(lubridate::year(date))), by = .(lakeSR_id)][n_years >= record_length]
    # filter data for those ids
    filtered_thermal_data <- filtered_thermal_data[ids_thermal, on = .(lakeSR_id)]
    # determine number of scenes in summary
    thermal_scenes <- filtered_thermal_data[, .(n_scenes = uniqueN(sat_id))]
    
    # define thermal quantiles
    q_vec <- filtered_thermal_data %>% 
      .[[thermal_band]] %>%
      quantile(., quantile_seq)
    q_dt <- data.table(quantile = names(q_vec), value = unname(q_vec))
    setnames(q_dt, "value", thermal_band)
    
    thermal_quantiles <- q_dt %>%                        
      mutate(n_scenes = thermal_scenes$n_scenes,
             n_rows = nrow(filtered_thermal_data),
             mission = mission_id, 
             for_corr = for_corr,
             dswe = dswe,
             version = version_id)
    
  } else {
    
    thermal_quantiles = NULL
    
  }
  
  outlist <- list(optical_quantiles, thermal_quantiles)
  names(outlist) <- c(paste0("optical_", dswe), paste0("thermal_", dswe))
  
  outlist
  
}
