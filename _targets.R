# Load packages required to define the pipeline:
library(targets)
library(tarchetypes) 

# Set target options: ---------------------------------------

tar_option_set(
  packages = c("tidyverse") # packages that your targets need to run
)

# Point to config files: ---------------------------------------

poi_config <- "config_files/config_poi.yml"

# Source targets groups: ---------------------------------------
# Run the R scripts in the R/ folder with your custom functions:
tar_source(
  "a_Calculate_Centers.R"
)

# Collate targets groups: ---------------------------------------
list(
  a_Calculate_Centers_list
)
