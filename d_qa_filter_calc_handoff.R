# Source functions for this {targets} list
tar_source("d_qa_filter_calc_handoff/src/")

# High-level QA filter and handoff calculations -----------------------------

# This {targets} list applies some rudimentary QA to the Landsat stacks, and then
# calculates 'intermission handoffs' that standardize the SR values relative to LS7
# and to LS8.

d_qa_filter_calc_handoff <- list(
  
  # collate each mission ---------------------------------------------------
  
  # because of some limitations of Drive, the c_collated_files have to be chunked
  # within the scope of this workflow. Large files will often get corrupted when 
  # saving/downloading to/from Drive. Due to memory limitations within R itself
  # this is broken out by mission and intentionally does not use mapping
  
  # Landsat 4
  tar_target(
    name = d_Landsat4,
    command = {
      segmented <- c_collated_files %>% 
        .[grepl("LT04", .)] %>% 
        .[grepl(paste0("_", c_dswe_types, "_"), .)]
      if (length(segmented) > 1) {
        un_segmented <- lapply(segmented, read_feather) 
        un_segmented[, rbindlist(),
                     ]
          rbindlist() %>% 
          mutate(dswe = c_dswe_types)
        return(un_segmented)
      } else if (length(seg) == 1) {
        one_file <- read_feather(segmented) %>% mutate(dswe = c_dswe_types)
        return(one_file)
      } else {
        return(NULL)
      }
    },
    packages = c("arrow", "data.table", "tidyverse"),
    pattern = map(c_dswe_types),
    iteration = "list",
    deployment = "main"
  ), 
  
  # Landsat 5
  tar_target(
    name = d_Landsat5,
    command = {
      segmented <- c_collated_files %>% 
        .[grepl("LT05", .)] %>% 
        .[grepl(paste0("_", c_dswe_types, "_"), .)]
      if (length(segmented) > 1) {
        un_segmented <- lapply(segmented, read_feather) %>% 
          rbindlist() %>% 
          mutate(dswe = c_dswe_types)
        return(un_segmented)
      } else if (length(seg) == 1) {
        one_file <- read_feather(segmented) %>% mutate(dswe = c_dswe_types)
        return(one_file)
      } else {
        return(NULL)
      }
    },
    packages = c("arrow", "data.table", "tidyverse"),
    pattern = map(c_dswe_types),
    iteration = "list",
    deployment = "main"
  ),
  
  # Landsat 7
  tar_target(
    name = d_Landsat7,
    command = {
      segmented <- c_collated_files %>% 
        .[grepl("LE07", .)] %>% 
        .[grepl(paste0("_", c_dswe_types, "_"), .)]
      if (length(segmented) > 1) {
        un_segmented <- lapply(segmented, read_feather) %>% 
          rbindlist() %>% 
          mutate(dswe = c_dswe_types)
        return(un_segmented)
      } else if (length(seg) == 1) {
        one_file <- read_feather(segmented) %>% mutate(dswe = c_dswe_types)
        return(one_file)
      } else {
        return(NULL)
      }
    },
    packages = c("arrow", "data.table", "tidyverse"),
    pattern = map(c_dswe_types),
    iteration = "list",
    deployment = "main"
  ),
  
  # Landsat 8
  tar_target(
    name = d_Landsat8,
    command = {
      segmented <- c_collated_files %>% 
        .[grepl("LC08", .)] %>% 
        .[grepl(paste0("_", c_dswe_types, "_"), .)]
      if (length(segmented) > 1) {
        un_segmented <- lapply(segmented, read_feather) %>% 
          rbindlist() %>% 
          mutate(dswe = c_dswe_types)
        return(un_segmented)
      } else if (length(seg) == 1) {
        one_file <- read_feather(segmented) %>% mutate(dswe = c_dswe_types)
        return(one_file)
      } else {
        return(NULL)
      }
    },
    packages = c("arrow", "data.table", "tidyverse"),
    pattern = map(c_dswe_types),
    iteration = "list",
    deployment = "main"
  ),
  
  # Landsat 9
  tar_target(
    name = d_Landsat9,
    command = {
      segmented <- c_collated_files %>% 
        .[grepl("LC09", .)] %>% 
        .[grepl(paste0("_", c_dswe_types, "_"), .)]
      if (length(segmented) > 1) {
        un_segmented <- lapply(segmented, read_feather) %>% 
          rbindlist() %>% 
          mutate(dswe = c_dswe_types)
        return(un_segmented)
      } else if (length(seg) == 1) {
        one_file <- read_feather(segmented) %>% mutate(dswe = c_dswe_types)
        return(one_file)
      } else {
        return(NULL)
      }
    },
    packages = c("arrow", "data.table", "tidyverse"),
    pattern = map(c_dswe_types),
    iteration = "list",
    deployment = "main"
  )
  
  
  
  
  
  
)
