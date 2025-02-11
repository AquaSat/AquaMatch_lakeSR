# Source functions for this {targets} list
tar_source("d_qa_filter_calc_handoff/src/")

# High-level QA filter and handoff calculations -----------------------------

# This {targets} list applies some rudimentary QA to the Landsat stacks, and then
# calculates 'intermission handoffs' that standardize the SR values relative to LS7
# and to LS8.

d_qa_filter_calc_handoff <- list(
  
  # Check for folder architecture -------------------------------------------
  
  tar_target(
    name = d_check_dir_structure,
    command = {
      # make directories if needed
      directories = c("d_qa_filter_calc_handoff/out/")
      walk(directories, function(dir) {
        if(!dir.exists(dir)){
          dir.create(dir)
        }
      })
    },
    cue = tar_cue("always"),
    deployment = "main",
  ),
  
  
  # collate each mission ---------------------------------------------------
  
  # because of some limitations of Drive, the c_collated_files have to be chunked
  # within the scope of this workflow. Large files will often get corrupted when 
  # saving/downloading to/from Drive. Additionally, LS 5 and 7 are particularly 
  # large memory hounds, even when using all data.table functions to reduce 
  # memory intense processes. 
  
  # Landsat 4
  tar_target(
    name = d_Landsat4_qa,
    command = qa_and_document_LS(mission = "LT05", 
                                 landsat_name = "Landsat 5", 
                                 dswe = c_dswe_types[1], 
                                 collated_files = c_collated_files,
                                 min_no_pix = 8, 
                                 thermal_threshold = 273.15,
                                 ir_threshold = 0.1,
                                 max_glint_threshold = 0.2,
                                 max_unreal_threshold = 0.2,
                                 document_drops = TRUE),
    packages = c("arrow", "data.table", "tidyverse"),
    pattern = map(c_dswe_types),
    iteration = "list",
    deployment = "main"
  )
  
  
  
  
  
  
  
)
