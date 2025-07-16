# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)
library(reticulate)
library(crew)

# Source general functions ------------------------------------------------

tar_source("src/")

# Set up crew controller for multicore processing ------------------------
controller_cores <- crew_controller_local(
  workers = parallel::detectCores()-1,
  seconds_idle = 12
)

# Set target options: ---------------------------------------

tar_option_set(
  # packages that {targets} need to run for this workflow
  packages = c("tidyverse", "sf"),
  # set up crew controller
  controller = controller_cores,
  # add memory helpers
  garbage_collection = TRUE,
  memory = "transient"
)


# Point to config files: ---------------------------------------

poi_config <- "b_pull_Landsat_SRST_poi/config_files/config_poi.yml"

# Set general configuration setting: -----------------------------

general_config <- "default"

# Create configuration targets:  ------------------------------------------

config_list <- list(
  
  # store general configuration file
  tar_target(
    name = lakeSR_config,
    command = config::get(config = general_config),
    cue = tar_cue("always")
  )

)

# Source targets groups: ---------------------------------------

tar_source(files = c(
  "a_Calculate_Centers.R",
  "b_pull_Landsat_SRST_poi.R",
  "c_collate_Landsat_data.R",
  "d_qa_filter_calc_handoff.R",
  "y_siteSR_targets.R",
  "z_render_bookdown.R"
  )
)

# Collate targets groups: ---------------------------------------

list(
  config_list,
  a_Calculate_Centers_list,
  b_pull_Landsat_SRST_poi_list,
  c_collate_Landsat_data,
  d_qa_filter_calc_handoff,
  y_siteSR_list,
  z_render_bookdown
)
