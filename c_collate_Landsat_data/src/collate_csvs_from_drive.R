#' @title Collate downloaded csv files into a feather file
#' 
#' @description
#' Function to grab all downloaded .csv files from the data_acquisition/in/ folder with a specific
#' file prefix, collate them into a .feather files with version identifiers
#'
#' @param file_type text string; unique string for filtering files to be 
#' downloaded from Drive. Some options: "457" (Landsat 4, 5, 7), "metadata", 
#' "89" (Landsat 8/9). Defaults to NULL.
#' @param yml dataframe; name of the target object from the -b- group that
#' stores the GEE run configuration settings as a data frame.
#' @param requries target object; any target that must be run prior to this 
#' function. Defaults to NULL.

#' @returns list of feather files created by this function. This function  
#' collates all .csv's containing the file_prefix, and saves up to 4 files
#' by type of data summarized within the file (polygon, point, center). The types
#' of data are automatically detected. Data type is created in the config.yml 
#' file of the associated Landsat-C2-SRST branch. 
#' 
#' 
collate_csvs_from_drive <- function(file_type = NULL, yml, requires = NULL) {
  
  # make directory path based on function arguments
  if (is.null(file_type)) {
    from_directory <- file.path("c_collate_Landsat_data/down/", yml$run_date)
  } else {
    from_directory <- file.path("c_collate_Landsat_data/down/", yml$run_date, file_type)
  }
  
  # make and store directory for collated files
  to_directory <- file.path("c_collate_Landsat_data/mid/", yml$run_date)
  if (!dir.exists(to_directory)) {
    dir.create(to_directory)
  }
  
  # get the list of files in the `in` directory 
  files <- list.files(from_directory,
                      full.names = TRUE) 
  
  # check for metadata files
  meta_files <- files[grepl("metadata", files)]
  if (length(meta_files) > 0) {
    meta_457 <- meta_files[grepl("457", meta_files)]
    if (length(meta_457) > 0) {
      all_meta_457 <- map_dfr(meta_457, read_csv) 
      write_feather(all_meta_457, file.path(to_directory,
                                            paste0(yml$proj, "_collated_metadata_457_",
                                                   yml$run_date, ".feather")))
    }
    meta_89 <- meta_files[grepl("89", meta_files)]
    if (length(meta_89) > 0) {
      all_meta_89 <- map_dfr(meta_89, read_csv) 
      write_feather(all_meta_89, file.path(to_directory,
                                           paste0(yml$proj, "_collated_metadata_89_",
                                                  yml$run_date, ".feather")))
    }
  }
  
  # if data from 457 (and not metatdata) are present, save those per mission group
  LS457_files <- files[grepl("457", files)]
  LS457_files <- LS457_files[!grepl("metadata", LS457_files)]
  if (length(LS457_files) > 0) {
    # collate files, but add the filename, since this *could be* is DSWE 1 + 3
    all_457_points <- map_dfr(.x = LS457_files, 
                              .f = function(.x) {
                                file_name = last(str_split(.x, "/")[[1]])
                                df <- read_csv(.x) 
                                # grab all column names except system:index
                                df_names <- colnames(df)[2:length(colnames(df))]
                                # and coerce those columns to numeric for joining later
                                df %>% 
                                  mutate(across(all_of(df_names),
                                                ~ as.numeric(.)))%>% 
                                  mutate(source = file_name)
                              }) 
    write_feather(all_457_points, file.path(to_directory,
                                            paste0(file_prefix, "_collated_points_457_",
                                                   version_identifier, ".feather")))
  }
  
  # if data from 89 (and not metatdata) are present, save those per mission group
  LS89_files <- files[grepl("89", files)]
  LS89_files <- LS89_files[!grepl("metadata", LS89_files)]
  if (length(LS89_files) > 0) {
    # collate files, but add the filename, since this *could be* is DSWE 1 + 3
    all_89_points <- map_dfr(.x = LS89_files, 
                             .f = function(.x) {
                               file_name = last(str_split(.x, "/")[[1]])
                               df <- read_csv(.x) 
                               # grab all column names except system:index
                               df_names <- colnames(df)[2:length(colnames(df))]
                               # and coerce those columns to numeric for joining later
                               df %>% 
                                 mutate(across(all_of(df_names),
                                               ~ as.numeric(.)))%>% 
                                 mutate(source = file_name)
                             }) 
    write_feather(all_89_points, file.path(to_directory,
                                           paste0(file_prefix, "_collated_points_89_",
                                                  version_identifier, ".feather")))
  }
  
  # return the list of files from this process
  list.files(to_directory,
             pattern = file_type,
             full.names = TRUE) 
}