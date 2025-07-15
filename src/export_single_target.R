#' @title Export a single target to Google Drive
#' 
#' @description
#' A function to export a single target (as a file) to Google Drive and return
#' the shareable Drive link as a file path.
#' 
#' @param target The target to be exported (as an object not a string).
#' 
#' @param drive_path A path to the folder on Google Drive where the file
#' should be saved.
#' 
#' @param google_email A string containing the gmail address to use for
#' Google Drive authentication.
#' 
#' @param date_stamp A string to version the upload by. default is NULL
#'
#' @param file_type Character string. Options to export file: '.feather', '.rds', 
#' or '.csv'. Defaults to rds.
#' 
#' @returns 
#' The contents of the folder indicated in the `drive_path` argument.
#' 
export_single_target <- function(target, drive_path, google_email,
                                 date_stamp = NULL, file_type = ".rds"){
  
  # file type
  if (!file_type %in% c(".rds", ".feather", ".csv")) {
    stop("file_type argument not recognized. Must be one of: '.feather', '.rds', 
           or '.csv'.")
  }
  
  # Authorize using the google email provided
  drive_auth(google_email)
  
  # Get target name as a string
  target_string <- deparse(substitute(target))
  
  # Create a temporary file exported locally, which can then be used to upload
  # to Google Drive
  file_local_path <- tempfile(fileext = file_type)
  
  if (file_type == ".feather") {
    write_feather(x = target,
                  path = file_local_path)
  } 
  if (file_type == ".rds") {
    write_rds(x = target,
              file = file_local_path)
  }
  if (file_type == ".csv") {
    write_csv(x = target,
              file = file_local_path)
  }
  
  filename <- if (!is.null(date_stamp)) {
    paste0(target_string, "_v", date_stamp, file_type)
  } else {
    paste0(target_string, file_type)
  }
  
  # Once locally exported, send to Google Drive
  out_file <- drive_put(media = file_local_path,
                        # The folder on Google Drive
                        path = drive_path,
                        # The filename on Google Drive
                        name = filename)
  
  # Make the Google Drive link shareable: anyone can view
  drive_share_anyone(out_file)
  
  # Now remove the local file after upload is complete
  file.remove(file_local_path)
  
  # return the contents of the drive path
  drive_ls(drive_path) %>% 
    filter(grepl(target_string, name))
  
}

