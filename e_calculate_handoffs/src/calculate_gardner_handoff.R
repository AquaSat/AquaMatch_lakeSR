calculate_gardner_handoff <- function(quantile_from, quantile_to, 
                                      mission_from, mission_to,
                                      location_info,
                                      DSWE, band) {
  
  # filter list for dswe and band
  type <- if (band == "med_SurfaceTemp") { "thermal" } else { "optical" }
  # get the list name
  list_name_to <- names(quantile_to) %>% 
    .[grepl(type, .)] %>% 
    .[endsWith(., DSWE)]
  list_name_from <- names(quantile_from) %>% 
    .[grepl(type, .)] %>% 
    .[endsWith(., DSWE)]
  
  y <- quantile_to[list_name_to][[1]]
  x <- quantile_from[list_name_from][[1]]
  
  # pull the specific band quantiles
  y_q <- y %>%
    pull(band) 
  
  x_q <- x %>%
    pull(band) 
  
  # calculate the poly model
  gard <- lm(y_q ~ poly(x_q, 2, raw = T))
  
  # store the unit info
  unit <- if (band == "med_SurfaceTemp") { " deg K" } else { " Rrs" }
  
  # plot and save handoff fig
  quant_plot <- ggplot() +
    geom_abline(intercept = 0, slope = 1, lty = 2, color = "grey") +
    geom_point(aes(x = x_q, y = y_q)) +
    geom_smooth(aes(x = x_q, y = y_q), method = "lm", 
                formula = y ~ poly(x, 2), color = "red") +
    labs(main = paste(band, mission_from, "to", mission_to, "handoff", DSWE),
         x = paste0("0.01 Quantile Values for ", mission_from, unit),
         y = paste0("0.01 Quantile Values for ", mission_to, unit)) +
    coord_cartesian(xlim = c(min(x_q, y_q), max(x_q, y_q)),
                    ylim = c(min(x_q, y_q), max(x_q, y_q))) +
    theme_bw()
  
  ggsave(plot = quant_plot,
         filename = file.path("e_calculate_handoffs/gardner/", 
                              paste(band,
                                    mission_from, 
                                    "to",
                                    mission_to,
                                    DSWE,
                                    "gard_handoff.jpg",
                                    sep = "_")), 
         width = 6, height = 5, units = 'in')
  
  residuals <- ggplot() +
    geom_point(aes(x = x_q, y = gard$residuals)) +
    geom_abline(intercept = 0, slope = 0, color = "grey", lty = 2) + 
    labs(title = paste(band, mission_from, "to", 
                       mission_to, "residuals", DSWE), 
         x = paste(band, unit), 
         y = "linear model residual") +
    theme_bw()
  
  ggsave(plot = residuals, 
         filename = file.path("e_calculate_handoffs/gardner/", 
                              paste(band,
                                    mission_from, 
                                    "to",
                                    mission_to,
                                    DSWE,
                                    "gard_residuals.jpg",
                                    sep = "_")), 
         width = 6, height = 3, units = 'in')

  # return a summary table
  tibble(band = band, 
         intercept = gard$coefficients[[1]], 
         B1 = gard$coefficients[[2]], 
         B2 = gard$coefficients[[3]],
         min_in_val = min(x_q),
         max_in_val = max(x_q),
         sat_corr = mission_from,
         sat_to = mission_to,
         dswe = DSWE) 
  
}

