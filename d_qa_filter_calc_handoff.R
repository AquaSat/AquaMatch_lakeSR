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
      directories = c("d_qa_filter_calc_handoff/mid/",
                      "d_qa_filter_calc_handoff/out/")
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
  
  tar_target(
    name = d_mission_identifiers,
    command = tibble(mission_id = c("LT04", "LT05", "LE07", "LC08", "LC09"),
                     mission_names = c("Landsat 4", "Landsat 5", "Landsat 7", "Landsat 8", "Landsat 9"))
  ),
  
  # Landsat 4
  tar_target(
    name = d_qa_Landsat_files,
    command = qa_and_document_LS(mission_info = d_mission_identifiers, 
                                 dswe = c_dswe_types, 
                                 collated_files = c_collated_files,
                                 min_no_pix = 8, 
                                 thermal_threshold = 273.15,
                                 ir_threshold = 0.1,
                                 max_glint_threshold = 0.2,
                                 max_unreal_threshold = 0.2,
                                 document_drops = TRUE),
    packages = c("arrow", "data.table", "tidyverse"),
    pattern = cross(d_mission_identifiers, c_dswe_types),
    iteration = "list",
    deployment = "main"
  ),
  

  
  
  
  
  
  
)
