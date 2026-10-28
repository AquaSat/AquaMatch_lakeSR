library(reticulate)

# NOTE, IF YOU ALTER THIS SCRIPT, YOU WILL NEED TO DELETE THE "env" FOLDER
# SO THAT CHANGES ARE REBUILT IN A NEW ENVIRONMENT

# Python and package versions for the conda environment. Leave a version as ""
# to let conda choose the latest compatible version (only for a fresh install
# when updating versions); otherwise pin every version so the environment is
# reproducible. After an unpinned install, the installed versions are printed
# in this format to copy back in here.
py_versions <- c(
  "python" = "3.12.15",
  "earthengine-api" = "1.7.48",
  "pandas" = "3.0.6",
  "numpy" = "2.5.3",
  "pyyaml" = "6.0.3"
)

env_path <- file.path(getwd(), "env/")

# conda's single "=" matches as a prefix (e.g. "3.12" matches 3.12.x)
py_specs <- ifelse(py_versions == "",
                   names(py_versions),
                   paste0(names(py_versions), "=", py_versions))

# create the conda environment if needed
if (!dir.exists(env_path)) {
  try(install_miniconda(), silent = TRUE)
  conda_create(envname = env_path, packages = py_specs[1],
               channel = "conda-forge")
}

# activate the environment. reticulate can only bind to one Python per R
# session, so this fails if a different Python has already been initialized
tryCatch(
  use_condaenv(env_path, required = TRUE),
  error = function(e) {
    message(conditionMessage(e))
    stop("There was an error initializing Python. Restart your R session and try again.")
  }
)

# install packages if missing (this also catches an environment that was
# created but never had its packages installed)
if (!py_module_available("ee")) {
  conda_install(envname = env_path, packages = py_specs[-1],
                channel = "conda-forge")
  # report installed versions so unpinned versions can be pinned above
  installed <- py_list_packages(envname = env_path, type = "conda")
  installed <- installed[installed$package %in% names(py_versions), ]
  message("Installed versions (copy into py_versions in python/pySetup.R):\n",
          paste0('  "', installed$package, '" = "', installed$version, '"',
                 collapse = ",\n"))
}

message("conda environment activated")
