# Source functions for this {targets} list
tar_source("c_collate_Landsat_data/src/")

# Collate data from GEE run -------------

# This {targets} list collates the data from the Google Earth Engine run 
# orchestrated in the {targets} group "b_pull_Landsat_SRST_poi" and creates 
# "stable" files for downstream use.

if (config::get(config = "admin_update")$run_GEE) {
  
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
      command = c("metadata", "LS457", "LS89"),
      deployment = "main"
    ),
    
    # set mission groups
    tar_target(
      name = c_mission_groups,
      command = c("LS457", "LS89"),
      deployment = "main"
    ),
    
    # set dswe types
    tar_target(
      name = c_dswe_types,
      command = {
        dswe = NULL
        if (grepl("1", b_yml_poi$DSWE_setting)) {
          dswe = c(dswe, "DSWE1")
        } 
        if (grepl("1a", b_yml_poi$DSWE_setting)) {
          dswe = c(dswe, "DSWE1a")
        } 
        if (grepl("3", b_yml_poi$DSWE_setting)) {
          dswe = c(dswe, "DSWE3")
        } 
        dswe
      },
      deployment = "main"
    ), 
    
    # download all files, branched by data segments
    tar_target(
      name = c_download_files,
      command = download_csvs_from_drive(local_folder = "c_collate_Landsat_data/down/",
                                         file_type = c_data_segments,
                                         drive_contents = c_Drive_folder_contents,
                                         yml = b_yml_poi,
                                         depends = c_check_dir_structure),
      packages = c("tidyverse", "googledrive"),
      pattern = map(c_data_segments)
    ),
    
    # collate all files - these end up being pretty big without filtering, so we 
    # need to break them up as metadata, then site pulls. The site pulls also need
    # to be split by dswe type and mission, otherwise the files are too big for R
    # to handle
    
    # make metadata file - this doesn't require filtering of dswe or mission
    tar_target(
      name = c_make_collated_metadata,
      command = collate_csvs_from_drive(file_type = "metadata",
                                        yml = b_yml_poi,
                                        dswe = NULL,
                                        separate_missions = FALSE,
                                        depends = c_download_files),
      packages = c("tidyverse", "arrow"),
      deployment = "main"
    ),
    
    tar_target(
      name = c_make_collated_point_files,
      command = collate_csvs_from_drive(file_type = c_mission_groups,
                                        yml = b_yml_poi,
                                        dswe = c_dswe_types,
                                        separate_missions = TRUE,
                                        depends = c_download_files),
      packages = c("tidyverse", "arrow"),
      pattern = cross(c_mission_groups, c_dswe_types)
    ),
    
    # Save collated files to Drive, create csv with ids -----------------------
    
    # get list of files to save to drive
    tar_target(
      name = c_collated_files,
      command = {
        c_make_collated_metadata
        c_make_collated_point_files
        list.files(file.path("c_collate_Landsat_data/mid/", 
                             b_yml_poi$run_date),
                   full.names = TRUE)
      },
      deployment = "main"
    ),
    
    tar_target(
      name = c_check_Drive_collated,
      command =  {
        b_check_Drive_parent_folder
        tryCatch({
          drive_auth(b_yml_poi$google_email)
          if (b_yml_poi$parent_folder != "") {
            path <- file.path(b_yml_poi$parent_folder, 
                              "collated_raw")
          } else {
            path <- paste0(b_yml_poi$proj_folder, 
                           "collated_raw")
          }
          drive_ls(path)
        }, error = function(e) {
          drive_mkdir(path)
        })
        return(path)
      },
      packages = "googledrive",
      cue = tar_cue("always")    
    ),
    
    tar_target(
      name = c_send_collated_files_to_drive,
      command = export_single_file(file_path = c_collated_files,
                                   drive_path = c_check_Drive_collated,
                                   google_email = b_yml_poi$google_email),
      packages = c("tidyverse", "googledrive"),
      pattern = c_collated_files
    ),
    
    tar_target(
      name = c_save_collated_drive_info,
      command = {
        drive_ids <- c_send_collated_files_to_drive %>% 
          select(name, id)
        write_csv(drive_ids,
                  "c_collate_Landsat_data/out/raw_collated_files_drive_ids.csv")
        drive_ids
      },
      packages = c("tidyverse", "googledrive"),
      deployment = "main"
    )
    
  )
  
} else {
  
  # if not re-running/collating the GEE pull, grab the drive info, download the
  # files and then store the list of files as a target
  c_collate_Landsat_data <- list(
    
    tar_file_read(
      name = c_save_collated_drive_info,
      command = "c_collate_Landsat_data/out/raw_collated_files_drive_ids.csv",
      read = read_csv(!!.x)
    ),
    
    tar_target(
      name = c_download_drive_files,
      command = retrieve_data(id_df = c_save_collated_drive_info, 
                              local_folder = "c_collate_Landsat_data/mid/", 
                              google_email = lakeSR_config$google_email, 
                              file_type = ".feather", 
                              version_date = lakeSR_config$collated_version)
    ),
    
    tar_target(
      name = c_collated_files,
      command = {
        c_download_drive_files
        list.files(file.path("c_collate_Landsat_data/mid/", 
                             lakeSR_config$collated_version),
                   full.names = TRUE)
      }
    )
    
  )
  
}
