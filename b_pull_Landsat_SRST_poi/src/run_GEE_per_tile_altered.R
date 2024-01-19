#' @title Run GEE script per tile
#' 
#' @description
#' Function to run the Landsat Pull for a specified WRS2 tile, but without the
#' sr_cloud_qa mask for LS 4-7
#' 
#' @param WRS_tile tile to run the GEE pull on
#' @returns Silently writes a text file of the current tile (for use in the
#' Python script). Silently triggers GEE to start stack acquisition per tile.
#' 
#' 
run_GEE_per_tile_altered <- function(WRS_tile) {
  # document WRS tile for python script
  write_lines(WRS_tile, "b_pull_Landsat_SRST_poi/out/current_tile.txt", sep = "")
  # run the python script
  source_python("b_pull_Landsat_SRST_poi/py/runGEEperTile_altered.py")
}