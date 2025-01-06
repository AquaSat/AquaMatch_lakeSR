# Source functions for this {targets} list
tar_source("c_collate_Landsat_data/src/")

# Collate data from GEE run -------------

# This {targets} list collates the data from the Google Earth Engine run 
# orchestrated in the {targets} group "b_pull_Landsat_SRST_poi" and creates 
# "stable" files for downstream use.

c_collate_Landsat_data <- list(
  
  # to make this a bit more efficient and end-user friendly, we'll download
  # and collate the Landsat 4/5/7 files separate from the 8/9 and metatdata 
  # files and save the resulting raw, unfiltered files by Landsat mission group.
  # The resulting collated files will be stored in Google Drive as will their 
  # id's for downstream users to pick up after this point in the workflow.
  
  # Check for folder architecture -------------------------------------------
  
  tar_target(
    name = c_check_dir_structure,
    command = {
      # make directories if needed
      directories = c("c_collate_Landsat_data/down/",
                      "c_collate_Landsat_data/mid/",
                      "c_collate_Landsat_data/out/")
      walk(directories, function(dir) {
        if(!dir.exists(dir)){
          dir.create(dir)
        }
      })
    },
    cue = tar_cue("always"),
    deployment = "main",
  ),
  
  # Get Google Drive Folder Contents ----------------------------------------
  
  tar_target(
    name = c_Drive_folder_contents,
    command = {
      # make sure b group is done
      b_check_for_failed_tasks
      # authorize Google
      drive_auth(email = b_yml_poi$google_email)
      # create the folder path as proj_folder and run_date
      drive_folder = paste0(b_yml_poi$proj_folder, 
                            "_v", 
                            b_yml_poi$run_date)
      # get a list of files in the project file
      drive_ls(path = drive_folder)
    },
    packages = "googledrive",
    deployment = "main"
  ),
  
  # Download and collate files from Drive --------------------------
  
  # target with list of data segments:
  tar_target(
    name = c_data_segments,
    command = c("metadata", "LS457", "LS89")
  ),
  
  # download all files, branched by data segments
  tar_target(
    name = c_download_files,
    command = download_csvs_from_drive(file_type = c_data_segments,
                                       drive_contents = c_Drive_folder_contents,
                                       yml = b_yml_poi,
                                       requires = c_check_dir_structure),
    packages = c("tidyverse", "googledrive"),
    pattern = map(c_data_segments)
  ),
  
  # collate all metadata files into one file
  tar_target(
    name = c_make_collated_files,
    command = collate_csvs_from_drive(file_type = c_data_segments,
                                      yml = b_yml_poi,
                                      requires = c_download_files),
    packages = c("tidyverse", "feather"),
    pattern = map(c_data_segments)
  ),
   

  # Save collated files to Drive, create csv with ids -----------------------

  
  # # and collate the data with metadata
  # tar_target(
  #   name = make_files_with_metadata,
  #   command = {
  #     make_collated_data_files
  #     add_metadata(yaml = yml,
  #                  file_prefix = yml$proj,
  #                  version_identifier = yml$run_date)
  #   },
  #   packages = c("tidyverse", "feather")
  # )
  
)


