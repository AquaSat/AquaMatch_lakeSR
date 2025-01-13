#' @title Collate downloaded csv files into a feather file
#' 
#' @description
#' Function to grab all downloaded .csv files from the c_collate_Landsat_Data/down/ 
#' folder, and collate them into .feather files subsetted per arguments in the
#' function. If left to default, this will create 3 files per DSWE setting: a 
#' metadata file, a LS457 file, and a LS89 file.
#'
#' @param file_type text string; unique string for filtering files to be 
#' downloaded from Drive. Some options: "LS457" (Landsat 4, 5, 7), "metadata", 
#' "LS89" (Landsat 8/9). Defaults to NULL. Use this arguemnt if using mulitcore.
#' @param yml dataframe; name of the target object from the -b- group that
#' stores the GEE run configuration settings as a data frame.
#' @param dswe text string; dswe value to filter input files by. Defaults to NULL.
#' Use this argument if multiple dswe settings have been extracted from GEE
#' @param separate_missions boolean; indication of whether the output should be
#' separated by individual Landsat missions. Defaults to FALSE. Use this if file
#' size is anticipated to be large. LS457 files will often push the limits of R 
#' memory on large GEE pulls.
#' @param depends target object; any target that must be run prior to this 
#' function. Defaults to NULL.
#' 
#' @returns none. Silently saves files to 'c_collate_Landsat_data/mid/'
#' 
#' 
collate_csvs_from_drive <- function(file_type = NULL, 
                                    yml, 
                                    dswe = NULL, 
                                    separate_missions = FALSE,
                                    depends = NULL) {
  
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
  
  # check to see if files need to subset for type
  if (!is.null(file_type)) {
    # subset for file type  
    type_subset <- files[grepl(file_type, files)]
    # if file type isn't metadata, then remove "metadata" from the filtered files,
    # since that has the LS label too
    if (file_type != "metadata") {
      type_subset <- type_subset[!grepl("metadata", type_subset)]
    }
    # make sure there are files present in this filter
    if (length(type_subset) == 0) {
      stop("You have used a `file_type` argument that is unrecognized.\n
              Acceptable `file_type` arguments are 'metadata', 'LS457', 'LS89'.",
           call. = TRUE)
    } 
    # rename to match workflow of non-subset files
    files <- type_subset
  }
  
  # check to see if files need to subset for dswe
  if (!is.null(dswe) & file_type != "metadata") {
    # subset for dswe - but need to add "_" before and after
    dswe <- paste0("_", dswe, "_")
    dswe_subset <- files[grepl(dswe, files)]
    # make sure there are files present in this filter
    if (length(dswe_subset) == 0) {
      stop("You have used a `dswe` argument that is unrecognized or you are\n
      attempting to subset metadata by DSWE, which is unnecessary.\n
      Acceptable `dswe` arguments are 'DSWE1', 'DSWE1a', 'DSWE3'.",
           call. = TRUE)
    } 
    # rename to match workflow of non-subset files
    files <- dswe_subset
  }
  
  # process metadata separately from site data
  metadata <- files[grepl("metadata", files)]
  
  if (length(metadata) > 0) {
    
    # process LS457 and LS89 mission groups separately
    mission_groups <- c("LS457", "LS89")
    walk(mission_groups,
         .f = \(mg) {
           if (any(grepl(mg, metadata))) {
             
             subset_mg <- metadata[grepl(mg, metadata)]
             
             # if separating missions, iterate over mission to save independent files
             if (separate_missions) {
               if (mg == "LS457") {
                 missions = c("LT04", "LT05", "LE07")
               } else {
                 missions = c("LC08", "LC09")
               }
               walk(missions,
                    .f = \(m) {
                      m_collated <- map(subset_mg, 
                                         .f = \(s) {
                                           read_csv(s) %>% 
                                             filter(grepl(m, `system:index`))
                                         }) %>% 
                        bind_rows()
                      write_feather(m_collated, file.path(to_directory,
                                                          paste0(yml$proj, 
                                                                 "_collated_metadata_",
                                                                 m,
                                                                 "_",
                                                                 yml$run_date, 
                                                                 ".feather")))
                    })
               
             } else { 
               
               # otherwise, read all the data and save the file
               data_mg <- map(subset_mg, read_csv) %>% 
                 bind_rows()
               
               write_feather(data_mg, file.path(to_directory,
                                                paste0(yml$proj, 
                                                       "_collated_metadata_",
                                                       mg, 
                                                       "_",
                                                       yml$run_date, 
                                                       ".feather")))
               
             }
             
           }
         })
    
  }
  
  
  # process sites separately from metadata
  sites <- files[!grepl("metadata", files)]
  
  if (length(sites) > 0) {
    
    # process LS457 and LS89 mission groups separately
    if (is.null(file_type)) {
      
      mission_groups <- c("LS457", "LS89")
      
      walk(mission_groups,
           .f = \(mg) {
             if (any(grepl(mg, sites))) {
               subset_mg <- sites[grepl(mg, sites)]
               
               # if separating missions, iterate over mission to save independent files
               if (separate_missions) {
                 if (mg == "LS457") {
                   missions = c("LT04", "LT05", "LE07")
                 } else {
                   missions = c("LC08", "LC09")
                 }
                 walk(missions,
                      .f = \(m) {
                        m_collated <- map(subset_mg, 
                                           .f = \(s) {
                                             df <- read_csv(s) %>% 
                                               filter(grepl(m, `system:index`))
                                             filename = last(str_split(s, pattern = "/")[[1]])
                                             # get column names that need to be 
                                             # coerced to numeric (all but index)
                                             df_names <- names(df)[2:length(names(df))]
                                             # coerce columns to numeric and add
                                             # source/file name
                                             df %>% 
                                               mutate(across(all_of(df_names),
                                                             ~ as.numeric(.))) %>% 
                                               mutate(source = filename)
                                           }) %>% 
                          bind_rows()
                        
                        # check for dswe subset
                        if (!is.null(dswe)) {
                          write_feather(m_collated, file.path(to_directory,
                                                              paste0(yml$proj, 
                                                                     "_collated_sites",
                                                                     dswe,
                                                                     m,
                                                                     "_",
                                                                     yml$run_date, 
                                                                     ".feather")))
                        } else {
                          write_feather(m_collated, file.path(to_directory,
                                                              paste0(yml$proj, 
                                                                     "_collated_sites_",
                                                                     m,
                                                                     "_",
                                                                     yml$run_date, 
                                                                     ".feather")))
                        }
                      })
                 
               } else {
                 
                 # otherwise, read all the data and save the file
                 data_mg <- map(subset_mg, 
                                .f = \(s) {
                                  df <- read_csv(s) 
                                  filename = last(str_split(s, pattern = "/")[[1]])
                                  # get column names that need to be 
                                  # coerced to numeric (all but index)
                                  df_names <- names(df)[2:length(names(df))]
                                  # coerce columns to numeric and add
                                  # source/file name
                                  df %>% 
                                    mutate(across(all_of(df_names),
                                                  ~ as.numeric(.))) %>% 
                                    mutate(source = filename)
                                }) %>% 
                   bind_rows()
                 
                 # check for dswe subset
                 if (!is.null(dswe)) {
                   write_feather(data_mg, file.path(to_directory,
                                                    paste0(yml$proj, 
                                                           "_collated_sites",
                                                           dswe,
                                                           mg, 
                                                           "_",
                                                           yml$run_date, 
                                                           ".feather")))
                 } else {
                   write_feather(data_mg, file.path(to_directory,
                                                    paste0(yml$proj, 
                                                           "_collated_sites_",
                                                           mg, 
                                                           "_",
                                                           yml$run_date, 
                                                           ".feather")))
                   
                 }
                 
               }
               
             }
           })
      
    } else {
      
      # if file_type specified, use that to define missions/filter
      if (any(grepl(file_type, sites))) {
        
        subset_mg <- sites[grepl(file_type, sites)]
        
        # if separating missions, iterate over mission to save independent files
        if (separate_missions) {
          
          if (file_type == "LS457") {
            missions = c("LT04", "LT05", "LE07")
          } else {
            missions = c("LC08", "LC09")
          }
          
          walk(missions,
               .f = \(m) {
                 m_collated <- map(subset_mg, 
                                   .f = \(s) {
                                     df <- read_csv(s) %>% 
                                       filter(grepl(m, `system:index`))
                                     filename = last(str_split(s, pattern = "/")[[1]])
                                     # get column names that need to be 
                                     # coerced to numeric (all but index)
                                     df_names <- names(df)[2:length(names(df))]
                                     # coerce columns to numeric and add
                                     # source/file name
                                     df %>% 
                                       mutate(across(all_of(df_names),
                                                     ~ as.numeric(.))) %>% 
                                       mutate(source = filename)
                                   }) %>% 
                   bind_rows()

                 # check for dswe subset
                 if (!is.null(dswe)) {
                   write_feather(m_collated, file.path(to_directory,
                                                       paste0(yml$proj, 
                                                              "_collated_sites",
                                                              dswe,
                                                              m,
                                                              "_",
                                                              yml$run_date, 
                                                              ".feather")))
                 } else {
                   write_feather(m_collated, file.path(to_directory,
                                                       paste0(yml$proj, 
                                                              "_collated_sites_",
                                                              m,
                                                              "_",
                                                              yml$run_date, 
                                                              ".feather")))
                 }
               })
          
        } else {
          
          # otherwise, read all the data and save the file
          data_mg <- map(subset_mg, 
                         .f = \(s) {
                           df <- read_csv(s) 
                           filename = last(str_split(s, pattern = "/")[[1]])
                           # get column names that need to be 
                           # coerced to numeric (all but index)
                           df_names <- names(df)[2:length(names(df))]
                           # coerce columns to numeric and add
                           # source/file name
                           df %>% 
                             mutate(across(all_of(df_names),
                                           ~ as.numeric(.))) %>% 
                             mutate(source = filename)
                         }) %>% 
            bind_rows()
          
          # check for dswe subset
          if (!is.null(dswe)) {
            write_feather(data_mg, file.path(to_directory,
                                             paste0(yml$proj, 
                                                    "_collated_sites",
                                                    dswe,
                                                    file_type, 
                                                    "_",
                                                    yml$run_date, 
                                                    ".feather")))
          } else {
            write_feather(data_mg, file.path(to_directory,
                                             paste0(yml$proj, 
                                                    "_collated_sites_",
                                                    file_type, 
                                                    "_",
                                                    yml$run_date, 
                                                    ".feather")))
            
          }
          
        }
      }
      
    }
  }    
  
  return ( NULL )
  
}