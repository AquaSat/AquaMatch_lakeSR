# Source functions for this {targets} list
tar_source("e_separate_by_huc4/src/")

# split files for long-term storage/data release -----------------------------

# This {targets} list separates the LS RS data by HUC4 for long-term storage in Drive
# and for data pubs. Metadata left as-is for data pub.

e_separate_by_huc4 <- list(
  tar_target(
    name = check directory
  ),
  tar_target(
    name = check Drive folder 
  ),
  tar_target(
    name = separate_by_huc4, 
    pattern = huc4
  ), 
  tar_target(
    name = save_huc4_files
  ),
  tar_target(
    name = store drive_ids
  )
  
  
)
  