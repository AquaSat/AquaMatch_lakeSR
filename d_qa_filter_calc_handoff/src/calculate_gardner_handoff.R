calculate_gardner_handoff <- function(quantile_summary, corr_name, bands) {
  # make quantile summary of band, dropping 0 and 1
  y_q <- y %>%
    pull(band) %>%
    as.numeric(.) %>% 
    quantile(., seq(.01,.99, .01))
  
  # make quantile summary of band, dropping 0 and 1
  x_q <- x %>%
    pull(band) %>%
    as.numeric(.) %>% 
    quantile(., seq(.01,.99, .01))
  
  poly <- lm(y_q ~ poly(x_q, 2, raw = T))
  
  # plot and save handoff fig
  jpeg(file.path("e_calculate_handoff_coefficients/figs/", 
                 paste0(band, "_7_8_poly_handoff.jpg")), 
       width = 350, height = 350)
  plot(y_q ~ x_q,
       main = paste0(band, " LS 7-8 handoff"),
       xlab = "0.01 Quantile Values for LS8 Rrs",
       ylab = "0.01 Quantile Values for LS7 Rrs")
  lines(sort(x_q),
        fitted(poly)[order(x_q)],
        col = "blue",
        type = "l")
  dev.off()
  
  # plot and save residuals from fit
  jpeg(file.path("e_calculate_handoff_coefficients/figs/", 
                 paste0(band, "_7_8_poly_residuals.jpg")), 
       width = 350, height = 200)
  plot(poly$residuals,
       main = paste0(band, " LS 7-8 poly handoff residuals"))
  dev.off()
  
  # create a summary table
  summary <- tibble(band = band, 
                    intercept = poly$coefficients[[1]], 
                    B1 = poly$coefficients[[2]], 
                    B2 = poly$coefficients[[3]],
                    min_in_val = min(x_q),
                    max_in_val = max(x_q),
                    sat_corr = "LANDSAT_7",
                    sat_to = "LANDSAT_8",
                    L8_scene_count = length(unique(y$system.index)),
                    L7_scene_count = length(unique(x$system.index))) 
  write_csv(summary, file.path("e_calculate_handoff_coefficients/mid/",
                               paste0(band, "_7_8_poly_handoff.csv")))
}
  
