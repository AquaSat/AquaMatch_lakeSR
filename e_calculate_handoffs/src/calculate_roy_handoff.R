calculate_roy_handoff <- function(matched_data, 
                                  mission_from,
                                  mission_to,
                                  location_info,
                                  invert_mission_match = FALSE,
                                  bands,
                                  DSWE) {
  
  binwidth <- list(c(0.001, 0.001), c(0.001, 0.001),
                   c(0.001, 0.001), c(0.001, 0.001),
                   c(0.1, 0.1))
  
  # perform some quick filters based on the flags we created upstream
  # grab the sites that are in this dataset
  sites <- location_info %>% 
    filter(lakeSR_id %in% matched_data$lakeSR_id)
  
  # now iterate through to calculate handoffs per band
  map2(bands,
       binwidth,
       \(band, bw) {
         
         # apply data filtering based on optical/thermal flags
         if (band == "med_SurfaceTemp") {
           # define the column to assess visibility
           thermal_flag_from <- switch(EXPR = mission_from, 
                                       LS4 = "flag_thermal_TM_shoreline",
                                       LS5 = "flag_thermal_TM_shoreline",
                                       LS7 = "flag_thermal_ETM_shoreline",
                                       LS8 = "flag_thermal_TIRS_shoreline",
                                       LS9 = "flag_thermal_TIRS_shoreline")
           thermal_flag_to <- switch(EXPR = mission_to, 
                                     LS4 = "flag_thermal_TM_shoreline",
                                     LS5 = "flag_thermal_TM_shoreline",
                                     LS7 = "flag_thermal_ETM_shoreline",
                                     LS8 = "flag_thermal_TIRS_shoreline",
                                     LS9 = "flag_thermal_TIRS_shoreline")
           
           # filter sites for no flag in thermal band
           thermal_no_shore <- filter(sites, !!sym(thermal_flag_from) == 0 & !!sym(thermal_flag_to) == 0)
           filtered_matched_data <- matched_data %>% 
             filter(lakeSR_id %in% thermal_no_shore$lakeSR_id,
                    !is.na(med_SurfaceTemp) & !is.na(i.med_SurfaceTemp),
                    prop_clouds == 0 & i.prop_clouds == 0)
         } else {
           # grab sites most certainly without shoreline contamination for optical bands
           optical_no_shore <- sites %>% 
             filter(flag_optical_shoreline == 0)
           # and now filter the optical data for those sites with less possible shoreline
           # contamination
           filtered_matched_data <- matched_data %>% 
             filter(lakeSR_id %in% optical_no_shore$lakeSR_id)
         }
         
         # store x/y based on invert argument
         if (invert_mission_match) {
           y <- filtered_matched_data %>% 
             pull(band)
           x <- filtered_matched_data %>% 
             pull(paste0("i.",band))
         } else {
           x <- filtered_matched_data %>% 
             pull(band)
           y <- filtered_matched_data %>% 
             pull(paste0("i.",band))
         }
         
         # calculate models
         roy <- lm(y ~ x)
         
         set.seed(57) # just for some local reproducibility in the random sample
         # need a sample here, deming is slowwww
         random <- tibble(y = y, x = x) %>% 
           slice_sample(., n = 10000)
         roy_dem <- deming(y ~ x, random)
         
         unit <- if (band == "med_SurfaceTemp") { " deg K" } else { " Rrs" }
         
         # plot and save handoff fig
         linear_plot <- ggplot() +
           geom_bin2d(aes(x = x, y = y, fill = after_stat(count)), binwidth = bw) + 
           scale_fill_viridis_c(name = "Density", alpha = 0.5) + 
           geom_abline(intercept = 0, slope = 1, color = "grey", lty = 2) + 
           geom_abline(intercept = roy_dem$coefficients[1], slope = roy_dem$coefficients[2], color = "blue") +
           geom_smooth(aes(x = x, y = y), method = "lm", se = FALSE, color = "red", lty = 3) +
           coord_fixed(ratio = 1,
                       xlim = c(min(x, y), max(x, y)),
                       ylim = c(min(x, y), max(x, y))) +
           labs(title = paste(band, mission_from, "to", 
                              mission_to, "handoff", DSWE), 
                x = paste0(mission_from, unit), 
                y = paste0(mission_to, unit)) +
           theme_bw()
         
         ggsave(plot = linear_plot, 
                filename = file.path("e_calculate_handoffs/roy/", 
                                     paste(band,
                                           mission_from, 
                                           "to",
                                           mission_to,
                                           DSWE,
                                           "roy_handoff.jpg",
                                           sep = "_")), 
                width = 6, height = 5, units = 'in')
         
         residuals <- ggplot() +
           geom_bin2d(aes(x = x, y = roy$residuals, fill = after_stat(count)), binwidth = bw) +
           scale_fill_viridis_c(name = "Density", alpha = 0.5) + 
           geom_abline(intercept = 0, slope = 0, color = "grey", lty = 2) + 
           labs(title = paste(band, mission_from, "to", 
                              mission_to, "residuals", DSWE), 
                x = paste0(band, unit), 
                y = "linear model residual") +
           theme_bw()
         
         ggsave(plot = residuals, 
                filename = file.path("e_calculate_handoffs/roy/", 
                                     paste(band,
                                           mission_from, 
                                           "to",
                                           mission_to,
                                           DSWE,
                                           "roy_residuals.jpg",
                                           sep = "_")), 
                width = 6, height = 3, units = 'in')
         
         
         deming_residuals <- y - (x*roy_dem$coefficients[[2]] + roy_dem$coefficients[[1]])
         
         deming_resid_plot <- ggplot() +
           geom_bin2d(aes(x = x, y = deming_residuals, fill = after_stat(count)), binwidth = bw) +
           scale_fill_viridis_c(name = "Density", alpha = 0.5) + 
           geom_abline(intercept = 0, slope = 0, color = "grey", lty = 2) + 
           labs(title = paste(band, mission_from, "to", 
                              mission_to, "residuals", DSWE), 
                x = paste0(band, unit), 
                y = "deming model residual") +
           theme_bw()
         
         ggsave(plot = deming_resid_plot, 
                filename = file.path("e_calculate_handoffs/roy/", 
                                     paste(band,
                                           mission_from, 
                                           "to",
                                           mission_to,
                                           DSWE,
                                           "roy_deming_residuals.jpg",
                                           sep = "_")), 
                width = 6, height = 3, units = 'in')
         
         # return a summary table
         ols <- tibble(band = band, 
                       intercept = roy$coefficients[[1]], 
                       slope = roy$coefficients[[2]], 
                       method = "lm",
                       min_in_val = min(x),
                       max_in_val = max(x),
                       sat_corr = mission_from,
                       sat_to = mission_to,
                       dswe = DSWE) 
         deming <- tibble(band = band, 
                          intercept = roy_dem$coefficients[[1]], 
                          slope = roy_dem$coefficients[[2]], 
                          method = "deming",
                          min_in_val = min(x),
                          max_in_val = max(x),
                          sat_corr = mission_from,
                          sat_to = mission_to,
                          dswe = DSWE) 
         
         bind_rows(ols, deming)
         
       }) %>% 
    bind_rows()
  
}
