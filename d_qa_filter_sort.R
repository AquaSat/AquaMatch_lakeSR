# Source functions for this {targets} list
tar_source("d_qa_filter_sort/src/")

# High-level QA filter and handoff calculations -----------------------------

# This {targets} list applies some rudimentary QA to the Landsat stacks and saves
# them as sorted files locally. LS 4/9 are complete .csv files, LS 578 are broken
# up by HUC2 for memory and space considerations. If `update_and_share` is set 
# to TRUE, the workflow will send dated, publicly available files to Google 
# Drive and save Drive file information in the `d_qa_filter_sort/out/` folder. 
# If set to FALSE, no files will be sent to Drive.

if (config::get(config = general_config)$update_and_share) {
  
  d_qa_filter_sort <- list(
    
    # Check for folder architecture -------------------------------------------
    
    tar_target(
      name = d_check_dir_structure,
      command = {
        # make directories if needed
        directories <- c("d_qa_filter_sort/qa/",
                         "d_qa_filter_sort/sort/",
                         "d_qa_filter_sort/out/")
        walk(directories, function(dir) {
          if(!dir.exists(dir)){
            dir.create(dir)
          }
        })
      },
      cue = tar_cue("always"),
      deployment = "main",
    ),
    
    # get the appropriate version date to filter files, just in case there is more
    # than one version
    tar_target(
      name = d_gee_version_identifier,
      command = {
        if (lakeSR_config$run_GEE) {
          b_yml_poi$run_date 
        } else { 
          lakeSR_config$collated_version 
        }
      }
    ),
    
    # get the appropriate date for the qa/filtered files
    tar_target(
      name = d_qa_version_identifier,
      command = lakeSR_config$qa_version
    ),
    
    
    # collate and qa each mission ---------------------------------------------------
    
    # Because the LS5 and 7 missions are absolutely huge data tables, and use 
    # nearly all of a 32GB memory limit within R, we continue to process the Landsat
    # data in chunks per mission. 
    
    tar_target(
      name = d_mission_identifiers,
      command = tibble(mission_id = c("LT04", "LT05", "LE07", "LC08", "LC09"),
                       mission_names = c("Landsat 4", "Landsat 5", "Landsat 7", "Landsat 8", "Landsat 9"))
    ),
    
    # track metadata files, we'll use those in the filtering process
    tar_files(
      name = d_metadata_files,
      command = list.files(file.path("c_collate_Landsat_data/mid/", d_gee_version_identifier), 
                           full.names = TRUE) %>% 
        .[grepl("metadata", .)]
    ),
    
    # walk through QA of missions and DSWE types
    tar_target(
      name = d_qa_Landsat_files,
      command = {
        d_check_dir_structure
        qa_and_document_LS(mission_info = d_mission_identifiers, 
                           dswe = c_dswe_types, 
                           metadata_files = d_metadata_files,
                           collated_files = c_collated_files,
                           qa_identifier = d_qa_version_identifier)
      },
      packages = c("arrow", "data.table", "tidyverse", "ggrepel", "viridis", "stringi"),
      pattern = cross(d_mission_identifiers, c_dswe_types),
      deployment = "main"
    ),
    
    # get a list of the qa'd files
    tar_files(
      name = d_qa_Landsat_file_paths,
      command = {
        d_qa_Landsat_files
        list.files("d_qa_filter_sort/qa/", full.names = TRUE) %>% 
          .[grepl(paste0("filtered_", d_qa_version_identifier), .)]
      }
    ),
    
    
    # collate qa'd data and sort as needed ------------------------------------
    
    # here, we collate small datasets (Landsat 4/9) into a single .csv file, and 
    # collate larger datasets (Landsat 5-7-8) into multiple .csv's, sorted by HUC2.
    
    # create a list of HUC2's to map over
    tar_target(
      name = d_unique_huc2,
      command = unique(str_sub(a_poi_with_flags$lakeSR_id, 1, 2))
    ),
    
    # Landsat 4 is small enough for a single file
    tar_target(
      name = d_Landsat4_collated_data,
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths, 
                                     qa_identifier = d_qa_version_identifier,
                                     mission_info = d_mission_identifiers %>% 
                                       filter(mission_names == "Landsat 4"),
                                     dswe = c_dswe_types),
      pattern = map(c_dswe_types),
      packages = c("data.table", "tidyverse", "arrow", "stringi")
    ),
    
    # Landsat 5, 7, 8 need to be separated by HUC2
    tar_target(
      name = d_collated_Landsat5_by_huc2,
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths,
                                     qa_identifier = d_qa_version_identifier,
                                     mission_info = d_mission_identifiers %>% 
                                       filter(mission_names == "Landsat 5"), 
                                     dswe = c_dswe_types, 
                                     HUC2 = d_unique_huc2),
      pattern = cross(c_dswe_types, d_unique_huc2), 
      packages = c("data.table", "tidyverse", "arrow", "stringi"),
      deployment = "main" # too big for multicore
    ),
    
    tar_target(
      name = d_collated_Landsat7_by_huc2,
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths,
                                     qa_identifier = d_qa_version_identifier,
                                     mission_info = d_mission_identifiers %>% 
                                       filter(mission_names == "Landsat 7"), 
                                     dswe = c_dswe_types, 
                                     HUC2 = d_unique_huc2),
      pattern = cross(c_dswe_types, d_unique_huc2), 
      packages = c("data.table", "tidyverse", "arrow", "stringi"),
      deployment = "main" # too big for multicore
    ),
    
    tar_target(
      name = d_collated_Landsat8_by_huc2,
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths,
                                     qa_identifier = d_qa_version_identifier,
                                     mission_info = d_mission_identifiers %>% 
                                       filter(mission_names == "Landsat 8"), 
                                     dswe = c_dswe_types, 
                                     HUC2 = d_unique_huc2),
      pattern = cross(c_dswe_types, d_unique_huc2), 
      packages = c("data.table", "tidyverse", "arrow", "stringi"),
      deployment = "main" # too big for multicore
    ),
    
    # Landsat 9 is small enough to be a single file.
    tar_target(
      name = d_Landsat9_collated_data,
      command = sort_qa_Landsat_data(qa_files = d_qa_Landsat_file_paths, 
                                     qa_identifier = d_qa_version_identifier,
                                     mission_info = d_mission_identifiers %>% 
                                       filter(mission_names == "Landsat 9"),
                                     dswe = c_dswe_types),
      pattern = map(c_dswe_types),
      packages = c("data.table", "tidyverse", "arrow", "stringi")
    ),
    
    # metadata
    tar_target(
      name = d_Landsat_metadata_formatted,
      command = prep_LS_metadata_for_export(file = d_metadata_files, 
                                            file_type = "csv", 
                                            qa_identifier = d_qa_version_identifier,
                                            gee_identifier = d_gee_version_identifier,
                                            out_path = "d_qa_filter_sort/sort/"),
      pattern = map(d_metadata_files), 
      packages = c("data.table", "tidyverse", "arrow", "stringi")
    ),
    
    # make a list of the collated and sorted files created
    tar_target(
      name = d_all_sorted_Landsat_files,
      command = as.vector(c(d_Landsat4_collated_data, d_collated_Landsat5_by_huc2,
                            d_collated_Landsat7_by_huc2, d_collated_Landsat8_by_huc2,
                            d_Landsat9_collated_data, d_Landsat_metadata_formatted))
    ),
    
    tar_target(
      name = d_lakeSR_feather_files,
      command = {
        if (!dir.exists(file.path("d_qa_filter_sort/out/", d_qa_version_identifier))) {
          dir.create(file.path("d_qa_filter_sort/out/", d_qa_version_identifier))
        }
        
        # filter for identifier/dswe
        fns  <- d_all_sorted_Landsat_files[grepl(gsub(" ", "", d_mission_identifiers$mission_names),
                                                 d_all_sorted_Landsat_files)]
        fns_dswe <- fns[grepl(paste0(c_dswe_types, "_"), fns)]
        
        # create the output filepath
        out_fp <- paste0("d_qa_filter_sort/out/", 
                         d_qa_version_identifier, 
                         "/lakeSR_", 
                         str_replace(d_mission_identifiers$mission_names," ", ""),
                         "_", c_dswe_types, "_", 
                         d_qa_version_identifier, ".feather")
        
        # check to see if this is a single file, or multiple and needs additional
        # data handling
        if (length(fns_dswe > 1)) {
          
          # create a temp directory for the temporary Arrow dataset
          temp_dataset_dir <- tempfile("arrow_ds_")
          dir.create(temp_dataset_dir)
          # these files need to be processed by chunk to deal with memory issues
          walk(fns_dswe, function(fn) {
            # read chunk
            chunk <- fread(fn)
            setDT(chunk)
            
            # add source_file column to partition by
            chunk[, source_file := tools::file_path_sans_ext(basename(fn))]
            
            # write chunk using partitioning (otherwise we hit memory issues)
            write_dataset(chunk,
                          path = temp_dataset_dir,
                          format = "feather",
                          partitioning = "source_file",
                          existing_data_behavior = "delete_matching")
          })
          
          # connect to the arrow-partitioned file
          ds <- open_dataset(temp_dataset_dir, format = "feather")
          
          # and grab all the data and write the feather file
          ds %>% 
            collect() %>% 
            select(-source_file) %>% 
            write_feather(., out_fp, compression = "lz4")
          
          # housekeeping
          unlink(temp_dataset_dir, recursive = TRUE)
          gc()
          Sys.sleep(5)
          
        } else {
          
          data <- fread(fn)
          write_feather(data, out_fp, compression = "lz4")
          
        }
        
        # return filepath
        out_fp
        
      },
      pattern = cross(c_dswe_types, d_mission_identifiers),
      packages = c("arrow", "data.table", "tidyverse"),
      deployment = "main" # these are huge, so make sure this runs solo
    ), 
    
    # check for Drive folders and architecture per config setup
    tar_target(
      name = d_check_Drive_parent_folder,
      command = if (lakeSR_config$parent_Drive_folder != "") {
        tryCatch({
          drive_auth(lakeSR_config$google_email)
          drive_ls(lakeSR_config$parent_Drive_folder)
        }, error = function(e) {
          drive_mkdir(lakeSR_config$parent_Drive_folder)
        })
      },
      packages = "googledrive",
      cue = tar_cue("always")
    ),
    
    tar_target(
      name = d_check_Drive_sorted_folder,
      command =  {
        d_check_Drive_parent_folder
        tryCatch({
          drive_auth(lakeSR_config$google_email)
          if (lakeSR_config$parent_Drive_folder != "") {
            version_path <- paste0(lakeSR_config$parent_Drive_folder,
                                   paste0("QA_sorted_v", d_qa_version_identifier, "/"))
          } else {
            version_path <- paste0("QA_sorted_v", d_qa_version_identifier, "/")
          }
          drive_ls(version_path)
        }, error = function(e) {
          # if there is an error indicating the path does not exist, make directory path
          if (lakeSR_config$parent_Drive_folder != "") {
            drive_mkdir(path = lakeSR_config$parent_Drive_folder, name = paste0("QA_sorted_v", d_qa_version_identifier))
          } else {
            drive_mkdir(name = paste0("QA_sorted_v", d_qa_version_identifier))
          }
        })
        return(version_path)
      },
      packages = "googledrive",
      cue = tar_cue("always"),
      deployment = "main" # this ends up making a million folders if you use multicore
    ),
    
    tar_target(
      name = d_send_sorted_files_to_Drive,
      command = export_single_file(file_path = d_all_sorted_Landsat_files,
                                   drive_path = d_check_Drive_sorted_folder,
                                   google_email = lakeSR_config$google_email),
      packages = c("tidyverse", "googledrive"),
      pattern = map(d_all_sorted_Landsat_files)
    ), 
    
    tar_target(
      name = d_save_sorted_drive_info,
      command = {
        d_check_dir_structure
        drive_ids <- d_send_sorted_files_to_Drive %>% 
          select(name, id)
        write_csv(drive_ids,
                  paste0("d_qa_filter_sort/out/Landsat_sorted_files_drive_ids_v",
                         d_qa_version_identifier,
                         ".csv"))
        drive_ids
      },
      packages = c("tidyverse", "googledrive"),
      deployment = "main"
    ),
    
    tar_target(
      name = d_check_Drive_feather_folder,
      command =  {
        d_check_Drive_parent_folder
        tryCatch({
          drive_auth(lakeSR_config$google_email)
          if (lakeSR_config$parent_Drive_folder != "") {
            version_path <- paste0(lakeSR_config$parent_Drive_folder,
                                   paste0("QA_feather_v", d_qa_version_identifier, "/"))
          } else {
            version_path <- paste0("QA_feather_v", d_qa_version_identifier, "/")
          }
          drive_ls(version_path)
        }, error = function(e) {
          # if there is an error indicating the path does not exist, make directory path
          if (lakeSR_config$parent_Drive_folder != "") {
            drive_mkdir(path = lakeSR_config$parent_Drive_folder, 
                        name = paste0("QA_feather_v", d_qa_version_identifier))
          } else {
            drive_mkdir(name = paste0("QA_feather_v", d_qa_version_identifier))
          }
        })
        return(version_path)
      },
      packages = "googledrive",
      cue = tar_cue("always"),
      deployment = "main" # this ends up making a million folders if you use multicore
    ),
    
    tar_target(
      name = d_send_feather_files_to_Drive,
      command = export_single_file(file_path = d_lakeSR_feather_files,
                                   drive_path = d_check_Drive_feather_folder,
                                   google_email = lakeSR_config$google_email),
      packages = c("tidyverse", "googledrive"),
      pattern = map(d_lakeSR_feather_files)
    ),
    
    tar_target(
      name = d_save_feather_drive_info,
      command = {
        d_check_dir_structure
        drive_ids <- d_send_feather_files_to_Drive %>% 
          select(name, id)
        write_csv(drive_ids,
                  paste0("d_qa_filter_sort/out/Landsat_QA_feather_files_drive_ids_v",
                         d_qa_version_identifier,
                         ".csv"))
        drive_ids
      },
      packages = c("tidyverse", "googledrive"),
      deployment = "main"
    )
    
  )
  
} else {
  
  d_qa_filter_sort <- list(
    
    # Check for folder architecture -------------------------------------------
    
    tar_target(
      name = d_check_dir_structure,
      command = {
        # make directories if needed
        directories <- c("d_qa_filter_sort/sort/",
                         file.path("d_qa_filter_sort/out/", d_qa_version_identifier))
        walk(directories, function(dir) {
          if(!dir.exists(dir)){
            dir.create(dir)
          }
        })
      },
      cue = tar_cue("always"),
      deployment = "main",
    ),
    
    # get the appropriate version date to filter files, just in case there is more
    # than one version
    tar_target(
      name = d_gee_version_identifier,
      command = {
        if (lakeSR_config$run_GEE) {
          b_yml_poi$run_date 
        } else { 
          lakeSR_config$collated_version 
        }
      }
    ),
    
    # get the appropriate date for the qa/filtered files
    tar_target(
      name = d_qa_version_identifier,
      command = lakeSR_config$qa_version
    ), 
    
    tar_target(
      name = d_save_sorted_drive_info,
      command = {
        d_check_dir_structure
        read_csv(paste0("d_qa_filter_sort/out/Landsat_sorted_files_drive_ids_v",
                        d_qa_version_identifier,
                        ".csv"))
      }
    ),
    
    tar_target(
      name = d_save_feather_drive_info,
      command = {
        d_check_dir_structure
        read_csv(paste0("d_qa_filter_sort/out/Landsat_QA_feather_files_drive_ids_v",
                        d_qa_version_identifier,
                        ".csv"))
      }
    ),
    
    tar_target(
      name = d_retrieve_sorted_files,
      command = {
        d_check_dir_structure
        retrieve_data(id_df = d_save_sorted_drive_info,
                      local_folder = "d_qa_filter_sort/sort/",
                      google_email = lakeSR_config$google_email,
                      file_type = ".feather",
                      version_date = d_qa_version_identifier)
      },
      pattern = map(d_save_sorted_drive_info),
      packages = c("tidyverse", "googledrive")
    ),
    
    tar_target(
      name = d_retrieve_feather_files,
      command = {
        d_check_dir_structure
        retrieve_data(id_df = d_save_feather_drive_info,
                      local_folder = file.path("d_qa_filter_sort/out/", d_qa_version_identifier),
                      google_email = lakeSR_config$google_email,
                      file_type = ".feather",
                      version_date = d_qa_version_identifier)
      },
      pattern = map(d_save_feather_drive_info),
      packages = c("tidyverse", "googledrive")
    ), 
    
    # get a list of the qa'd files
    tar_files(
      name = d_all_sorted_Landsat_files,
      command = {
        d_retrieve_sorted_files
        list.files("d_qa_filter_sort/sort/", full.names = TRUE) %>% 
          .[grepl(d_qa_version_identifier, .)]
      }
    ),
    
    # get a list of the qa'd feather files
    tar_files(
      name = d_lakeSR_feather_files,
      command = {
        d_retrieve_feather_files
        list.files(file.path("d_qa_filter_sort/out", d_qa_version_identifier), full.names = TRUE) %>% 
          .[grepl(d_qa_version_identifier, .)]
      }
    )
    
  )
  
}

