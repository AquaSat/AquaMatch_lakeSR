#' @title Apply Quality Assurance of Landsat data and document data loss
#' 
#' @description
#' The qa_and_document_LS function performs quality assurance (QA) filtering on 
#' Landsat data files based on specified thresholds. It processes a set of input 
#' files, applies multiple filtering criteria, saves the filtered data, and 
#' optionally generates a summary of dropped records with a visualization.
#'
#' @param mission_info data.frame/tibble/data.table containing the columns 'mission_id'
#' (e.g. 'LT05') and 'mission_names' (e.g. 'Landsat 5'). 
#' @param dswe character string indicating the DSWE setting to filter the files
#' by. 
#' @param metadata_files vector of file paths to the metadata files associated 
#' with the Landsat stack
#' @param collated_files vector of file paths to the collated Landsat data files 
#' to be processed. Assumed to be arrow::feather() files. 
#' @param min_no_pixels Minimum number of pixels contributing to the summary 
#' statistics in the pCount_*dswe* column required for a record to be retained. 
#' @param thermal_threshold Minimum acceptable value for the median surface 
#' temperature (in Kelvin). Default: 273.15.
#' @param thermal_maximum Maximum acceptable value for the median surface 
#' temperature (in Kelvin). Default: 313.15.
#' @param ir_threshold Maximum acceptable value for NIR/SWIR bands for glint 
#' filtering. Default: 0.1
#' @param document_drops Boolean, whether to generate a summary of dropped 
#' records and save it as a plot. Default: TRUE
#' @param out_path Directory where filtered files should be saved. Will be 
#' created if it doesn't exist. Default: `d_qa_filter_sort/qa/`
#' 
#' @returns None. Silently saves figures displaying dropped observations if 
#' `document_drops = TRUE` in `d_qa_filter_sort/out`. Silently saves filtered 
#' (QA) files to `out_path`.
#' 
qa_and_document_LS <- function(mission_info,
                               dswe, 
                               metadata_files,
                               collated_files,
                               min_no_pix = 8, 
                               thermal_threshold = 273.15,
                               thermal_maximum = 313.15,
                               ir_threshold = 0.1,
                               document_drops = TRUE,
                               out_path = "d_qa_filter_sort/qa/"
                               
) {
  
  # check DSWE arguments:
  if (!dswe %in% c("DSWE1", "DSWE1a", "DSWE3")) {
    stop("The provided dswe argument is not recognized. Check that it is one of\n
         the following and retry: `DSWE1`, `DSWE1a`, `DSWE3`",
         call. = TRUE)
  }
  
  # make sure specified out_path exists
  if (!dir.exists(out_path)) {
    dir.create(out_path, recursive = TRUE)
  }
  
  # filter collated files list to those with specified mission/dswe files 
  mission_files <- collated_files %>% 
    .[grepl(mission_info$mission_id, .)] %>% 
    .[grepl(paste0("_", dswe, "_"), .)]
  

  # make sure there are files that exist with those filters
  if (length(mission_files > 0)) {
    
    # read in appropriate metadata for filtering
    metadata_fn <- metadata_files %>% 
      .[grepl(str_extract(mission_info$mission_names, "\\d"), str_extract(basename(.), "LS\\d+"))]
    # make the name for image quality, since it changes through mission groups
    image_qual_name <- if (mission_info$mission_id %in% c("LT04", "LT05", "LE07")) {
      "IMAGE_QUALITY"
    } else {
      "IMAGE_QUALITY_OLI"
    }
    metadata <- read_feather(metadata_fn) %>% 
      select(c(`system:index`, all_of(image_qual_name)))
    names(metadata) <- c("sat_id", "image_qual")
    
    # store pcount column name via dswe designation
    pCount_column <- sym(paste0("pCount_", tolower(dswe)))
    
    
    # map qa process across designated files ----------------------------------
    
    # step through QA thresholds per file, track dropped rows
    row_df <- map(mission_files, 
                  \(fp) {
                    
                    data <- read_feather(fp) 
                    setDT(data)
                    data[, sat_id := stri_replace_last_regex(`system:index`, "_\\d{4}_\\d+$", "")]

                    all_data <- nrow(data)
                    # note, this workflow iteratively overwrites the 'data' 
                    # object to save memory.
                    
                    data <- data %>% 
                      left_join(., metadata) %>% 
                      filter(image_qual >= 8)
                    image_qual <- nrow(data)
                    data <- data %>% select(-image_qual)
                    
                    # filter for at least 8 pixels
                    data <- data %>% 
                      filter({{pCount_column}} >= min_no_pix)
                    valid_thresh <- nrow(data)
                    
                    # filter thermal for > 273.15 (above freezing)
                    data <- data %>% #glint_thresh %>% 
                      filter(med_SurfaceTemp > thermal_threshold)
                    temp_thresh <- nrow(data)
                    
                    # filter thermal for < 213.15 (below 40 deg C)
                    data <- data %>% #glint_thresh %>% 
                      filter(med_SurfaceTemp < thermal_maximum)
                    temp_max <- nrow(data)
                    
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
                           image_qual = image_qual,
                           valid_thresh = valid_thresh,
                           temp_thresh = temp_thresh,
                           temp_max = temp_max,
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
                            image_qual = "filtered for optical image quality >= 8",
                            valid_thresh = sprintf("minimum number of pixels threshold (%s) met", min_no_pix),
                            temp_thresh = sprintf("thermal band threshold (%s °K) met", thermal_threshold),
                            temp_max = sprintf("below thermal band maximum (%s °K)", thermal_maximum),
                            ir_glint_thresh = sprintf("NIR/SWIR threshold (%s) met", ir_threshold)) %>% 
        pivot_longer(cols = all_data:ir_glint_thresh,
                     values_to = "reason") 
      
      drops <- full_join(row_summary, drop_reason) %>% 
        mutate(name = factor(name, levels = c("ir_glint_thresh",
                                              "temp_max",
                                              "temp_thresh",
                                              "valid_thresh",
                                              "image_qual",
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
                        nudge_y = max(drops$value) * 0.01,
                        hjust = "left") +
        labs(title = paste0("Summary of lakeSR ", paste(mission_info$mission_names, toupper(dswe), sep = " "), " data QA records"), 
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
             filename = file.path("d_qa_filter_sort/out", plot_fn), 
             dpi = 300, width = 6, height = 3, units = "in")
    }
    
    return(NULL)
    
  } else {
    
    warning(sprintf("No files resulted when filtered by %s and %s. You should confirm this is an intended result.", 
                    mission_info$mission_id, 
                    dswe), 
            call. = TRUE)
    
  }
  
}
