#' @title Retrieve a target from Google Drive
#' 
#' @description
#' A function to retrieve a target from Google Drive after it has been uploaded
#' in a previous step.
#' 
#' @param target A string containing the name of the target to be retrieved.
#' 
#' @param id_df A dataframe containing the cols `name` and `id` to use for
#' retrieving the uploaded dataset from Google Drive.
#' 
#' @param local_folder A string specifying the folder where the file should be
#' downloaded to.
#' 
#' @param google_email A string containing the gmail address to use for
#' Google Drive authentication.
#' 
#' @param file_type A string giving the file extension to be used. (".rds" or 
#' ".feather")
#' 
#' @param version_date A string containing an eight-digit date (i.e., in
#' ISO 8601 "basic" format: YYYYMMDD) that should be used to identify the
#' correct file version on Google Drive.
#' 
#' @returns 
#' The dataset after being downloaded and read into the pipeline from Google Drive.
#' 
retrieve_target <- function(target, id_df, local_folder, 
                          google_email, file_type = ".rds", 
                          version_date = NULL){
  
  # Authorize using the google email provided
  drive_auth(google_email)
  
  # Local file download location
  local_path <- file.path(local_folder, paste0(target, file_type))
  
  if(!is.null(version_date)){
    
    file_name <- paste0(target, "_v", version_date, file_type)
    
  } else {
    
    file_name <- paste0(target, file_type)
    
  }
  
  # Filter the contents to the file requested and obtain its ID
  drive_file_id <- id_df %>%
    filter(name == file_name) %>%
    pull(id) %>%
    as_id(.)
  
  # Run the download
  drive_download(file = drive_file_id,
                 path = local_path,
                 overwrite = TRUE)
  
  # Read dataset into pipeline
  if(file_type == ".rds"){
    
    return(read_rds(local_path))
    
  } else if(file_type == ".feather"){
    
    return(read_feather(local_path))   
    
  } else {
    
    stop("file_type does not appear to be either .rds or .feather.")
    
  }
  
  unlink(local_path)
  
}
