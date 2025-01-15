#' @title Create pie charts
#' 
#' @description
#' A function to streamline creation of pie charts
#' 
#' @param dataset A data frame containing the columns `n` (numeric
#'  count of `name`) and `name` (string describing the count)
#' @param col_name A string containing the name to be used for the title of the 
#' plot
#' 
#' @returns A ggplot object containing a pie chart
#' 
#' @note Adapted from https://stackoverflow.com/questions/69715282/how-to-adjust-ggrepel-label-on-pie-chart
#' 
plot_fail_pie <- function(dataset, col_name, text_size = 3){
  
  # Prepare the position info needed for the pie chart
  pie_prep <- dataset %>% 
    # Don't clutter with absent searches
    filter(n != 0) %>%
    mutate(perc = n / sum(n),
           labels = percent(n)) %>% 
    # Descending order of frequency
    arrange(desc(n)) %>%
    mutate(# Text label locations
           text_y = cumsum(n) - n / 2)
  
  pie_prep %>%
    ggplot(aes(x = "", y = n, fill = name)) + 
    geom_col(color = "black", linewidth = 0.35) +
    # Pie chart format
    coord_polar(theta = "y") +
    # Label with grepl text and record count
    geom_label_repel(
      aes(x = 1.4,
          label = paste0(name, "\n n = ", n),
          y = text_y), 
      nudge_x = 0.3,
      nudge_y = 0.6,
      size = text_size,
      max.overlaps = 25,
      show.legend = F) +
    # Avoid dark colors that would prevent legibility
    scale_fill_viridis_d(begin = 0.2) +
    ggtitle(paste0("Summary of ", col_name)) +
    theme_void() +
    theme(legend.position = "none",
          plot.title = element_text(hjust = 0.5),
          plot.subtitle = element_text(hjust = 0.5))
  
}
