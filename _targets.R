# Load packages required to define the pipeline:
library(targets)
library(tarchetypes) 

# Set target options:
tar_option_set(
  packages = c("tidyverse") # packages that your targets need to run
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source(
  "a_Calculate_Centers.R"
)

# Replace the target list below with your own:
list(
  a_Calculate_Centers_list
)
