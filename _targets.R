# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)
library(reticulate)

# Set up python virtual environment ---------------------------------------

if (!dir.exists("env")) {
  tar_source("python/pySetup.R")
} else {
  use_condaenv(file.path(getwd(), "env"))
}

# Set target options: ---------------------------------------

tar_option_set(
  packages = c("tidyverse") # packages that your targets need to run
)

# Point to config files: ---------------------------------------

poi_config <- "b_pull_Landsat_SRST_poi/config_files/config_poi.yml"

# Source targets groups: ---------------------------------------
# Run the R scripts with custom functions:
tar_source(files = c(
  "a_Calculate_Centers.R",
  "b_pull_Landsat_SRST_poi.R"
  )
)

# Collate targets groups: ---------------------------------------
list(
  a_Calculate_Centers_list,
  b_pull_Landsat_SRST_poi_list,
  tar_target(name = render_bookdown,
             command = {
               poi_tasks_complete #this should always be the last target!
               render_book(input = "bookdown/",
                           params = list(
                             all_pts = combined_poi_points,
                             ak_pts = AK_poi_points
                           ))
               },
             packages = "bookdown")
)
