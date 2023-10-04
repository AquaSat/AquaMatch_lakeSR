# Load packages required to define the pipeline:
library(targets)
library(tarchetypes) 
library(reticulate)

# Set up python virtual environment ---------------------------------------

if (!dir.exists("env")) {
  tar_source("py/pySetup.R")
} else {
  use_condaenv(file.path(getwd(), "env"))
}

# Set target options: ---------------------------------------

tar_option_set(
  packages = c("tidyverse") # packages that your targets need to run
)

# Source targets groups: ---------------------------------------
# Run the R scripts in the R/ folder with your custom functions:
tar_source(
  "a_Calculate_Centers.R"
)

# Collate targets groups: ---------------------------------------
list(
  a_Calculate_Centers_list
)
