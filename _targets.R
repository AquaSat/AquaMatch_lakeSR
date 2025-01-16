# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)
library(reticulate)
library(crew)

# Set up python virtual environment ---------------------------------------

tar_source("python/pySetup.R")

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


# Create configuration targets:  ------------------------------------------

config_list = list(
  
  # Grab location of the local {targets} siteSR pipeline OR error if
  # the location doesn't exist yet
  tar_target(
    name = config_siteSR_directory,
    # command = if(dir.exists(p0_siteSR_config$harmonize_repo_directory)) {
    #   p0_siteSR_config$harmonize_repo_directory
    # } else {
    #   # Throw an error if the pipeline does not exist
    #   stop("The WQP download pipeline is not at the location specified in the 
    #        config.yml file. Check the location specified as `harmonize_repo_directory`
    #        in the config.yml file and rerun the pipeline.")
    # },
    command = if(dir.exists("../AquaMatch_siteSR_WQP/")) {
      "../AquaMatch_siteSR_WQP/"
    } else {
      # Throw an error if the pipeline does not exist
      stop("The siteSR pipeline is not located at `../AquaMatch_siteSR_WQP/` and 
           the pipeline can not continue.")
    },
    cue = tar_cue("always")
  )

)

# Source targets groups: ---------------------------------------

tar_source(files = c(
  "a_Calculate_Centers.R",
  "b_pull_Landsat_SRST_poi.R",
  "c_collate_Landsat_data.R",
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
  y_siteSR_list,
  z_render_bookdown
)
