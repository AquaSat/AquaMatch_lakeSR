
library(reticulate)

# NOTE, IF YOU ALTER THIS SCRIPT, YOU WILL NEED TO DELETE THE "ENV" FOLDER
# SO THAT CHANGES ARE REBUILT IN NEW VENV

# activate conda env or create conda env and modules for the venv
tryCatch({
  use_condaenv(file.path(getwd(), "env/"))
  print("conda environment activated")
},
warning = function(w){
  # when running this function, it will always produce a warning, if
  # your RStudio is set up in some configurations
  print("conda environment activated")
},
error = function(e) {
  # install miniconda if necessary
  try(install_miniconda())
  #create a conda environment named "mod_env" with the packages you need
  conda_create(envname = file.path(getwd(), "env/"), 
               python_version = "3.10.13")
  conda_install(envname = file.path(getwd(), "env/"),
                python_version = "3.10.13",  
                packages = c("earthengine-api==1.4.0", 
                             "pandas==2.0.3", 
                             "pyreadr==0.5.2", 
                             "pyyaml==6.0.2",
                             "numpy==1.24.4"))
  # set the new python environment
  use_condaenv(file.path(getwd(), "env/"))
  print("conda environment created and activated")
})
