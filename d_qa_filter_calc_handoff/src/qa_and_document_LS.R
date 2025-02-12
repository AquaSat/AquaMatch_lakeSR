

qa_and_document_LS <- function(mission_info,
                               dswe, 
                               collated_files,
                               min_no_pix = 8, 
                               thermal_threshold = 273.15,
                               ir_threshold = 0.1,
                               max_glint_threshold = 0.2,
                               max_unreal_threshold = 0.2,
                               document_drops = TRUE,
                               out_path = "d_qa_filter_calc_handoff/mid/"
                               
) {
  
  # make sure specified out_path exists (if anything but default)
  if (!dir.exists(out_path)) {
    dir.create(out_path, recursive = TRUE)
  }
  
  # filter collated files list to those with specified mission/dswe files 
  mission_files <- collated_files %>% 
    .[grepl(mission_info$mission_id, .)] %>% 
    .[grepl(paste0("_", dswe, "_"), ., ignore.case = T)]
  
  if (length(mission_files > 0)) {
    # store pcount column name via dswe designation
    pCount_column <- sym(paste0("pCount_", tolower(dswe)))
    
    
    # map qa process across designated files ----------------------------------
    
    # step through QA thresholds per file, track dropped rows
    row_df <- map(mission_files, 
                  \(fp) {
                    
                    data <- read_feather(fp)
                    all_data <- nrow(data)
                    # note, this workflow iteratively overwrites the 'data' 
                    # object to save memory.
                    
                    # filter for at least 8 pixels
                    data <- data %>% 
                      filter({{pCount_column}} >= min_no_pix)
                    valid_thresh <- nrow(data)
                   
                     # filter for realistic proportional threshold
                    data <- data %>% 
                      filter(pCount_unreal_val/{{pCount_column}} < max_unreal_threshold)
                    real_thresh <- nrow(data)
                    
                    # # filter for glint proportional threshold
                    # data <- data %>% 
                    #   filter(pCount_sun_glint/{{pCount_column}} < max_glint_threshold)
                    # glint_thresh <- nrow(data)
                    
                    # filter thermal for > 273.15 (above freezing)
                    data <- data %>% #glint_thresh %>% 
                      filter(med_SurfaceTemp > thermal_threshold)
                    temp_thresh <- nrow(data)
                    
                    # filter for nir/swir thresholds
                    data <- data %>% 
                      filter(med_Nir < ir_threshold | (med_Swir1 < ir_threshold & med_Swir2 < ir_threshold))
                    ir_glint_thresh <- nrow(data)
                    
                    # make a new file name using fp from mission_files
                    out_fn <- last(unlist(str_split(fp, '/')))
                    out_fn <- str_replace(out_fn, ".feather", "_filtered.feather")
                    
                    write_feather(data, 
                                  file.path(out_path, out_fn),
                                  compression = "lz4")
                    
                    # return row summary of filtered data
                    tibble(all_data = all_data,
                           valid_thresh = valid_thresh,
                           real_thresh = real_thresh,
                           # glint_thresh = nrow(glint_thresh),
                           temp_thresh = temp_thresh,
                           ir_glint_thresh = ir_glint_thresh) %>% 
                      pivot_longer(cols = all_data:ir_glint_thresh) 
                    
                  })
    
    
    # make/save row drop summary ----------------------------------------------
    
    if (document_drops) {
      # collate row_summary from list
      row_summary <- row_df %>% 
        bind_rows() %>% 
        summarize(value = sum(value),
                  .by = name)
      
      drop_reason <- tibble(all_data = "unfiltered Landsat data",
                            valid_thresh = sprintf("minium number of pixels threshold (%s) met", min_no_pix),
                            real_thresh = sprintf("non-realistic values pixel threshold (%s) met", max_unreal_threshold),
                            # glint_thresh = sprintf("glint pixel threshold (%s) met", max_glint_threshold),
                            temp_thresh = sprintf("thermal band threshold (%s) met", thermal_threshold),
                            ir_glint_thresh = sprintf("NIR/SWIR threshold (%s) met", ir_threshold)) %>% 
        pivot_longer(cols = all_data:ir_glint_thresh,
                     values_to = "reason") 
      
      drops <- full_join(row_summary, drop_reason) %>% 
        mutate(name = factor(name, levels = c("ir_glint_thresh",
                                              "temp_thresh",
                                              # "glint_thresh",
                                              "real_thresh",
                                              "valid_thresh",
                                              "all_data")),
               lab = paste0(reason, ": ", format(value, big.mark = ","), " records"))
      
      drops_plot <- ggplot(drops) +
        geom_bar(aes(x = name, y = value, fill = name),
                 stat = "identity")  +
        geom_text_repel(aes(x = name, y = 0.1, label = lab),
                        bg.color = "white", bg.r = 0.15, size = 2.5,
                        point.size = NA,
                        xlim = c(-Inf, Inf),
                        ylim =  c(-Inf, Inf),
                        nudge_y = max(drops$value)*0.01,
                        hjust = "left") +
        labs(title = paste0("Summary of ", paste(mission_info$mission_names, toupper(dswe), sep = " "), " data QA records"), 
             x = NULL, y = NULL) +
        scale_fill_manual(values = viridis(n = nrow(drops),
                                           direction = -1)) +
        scale_x_discrete(drop = F) +
        coord_flip() +
        theme_bw() +
        theme(axis.text.x = element_blank(),
              axis.text.y = element_blank(),
              plot.title = element_text(size = 12, face = "bold", hjust = 0.5), 
              legend.position = "none")
      
      plot_fn <- paste0(mission_info$mission_id, "_", dswe, "_drop_summary.png")
      
      ggsave(plot = drops_plot, 
             filename = file.path("d_qa_filter_calc_handoff/out", plot_fn), 
             dpi = 300, width = 6, height = 3, units = "in")
    }
    
  } else {
    return(NULL)
  }
  
}
