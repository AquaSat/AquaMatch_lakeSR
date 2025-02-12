#' @title Retrieve data from Google Drive
#' 
#' @description
#' A function to retrieve one or multiple datasets from Google Drive after having 
#' been uploaded in a previous step.
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
#' @param version_date A string containing a date in the format YYYY-MM-DD that 
#' should be used to identify the correct file version on Google Drive.
#' 
#' @returns 
#' None. Silently saves files in the `local_folder`.
#' 
retrieve_data <- function(id_df, 
                          local_folder, 
                          google_email, 
                          file_type = ".feather", 
                          version_date){
  
  message("Depending on the number and size of files, this may take some time.")
  
  # Authorize using the google email provided
  drive_auth(google_email)
  
  # make sure local folder path exists
  if (!dir.exists(local_folder)) {
    dir.create(local_folder, recursive = TRUE)
  }
  
  # Filter the contents of the id_df to the desired version date
  drive_file_ids <- id_df %>%
    filter(grepl(pattern = version_date, x = name))
  
  # Run the download
  walk2(.x = drive_file_ids$id,
        .y = drive_file_ids$name, 
        .f = function(.x, .y) {
          try(drive_download(file = as_id(.x),
                             path = file.path(local_folder,
                                              .y),
                             overwrite = FALSE)) # just pass if already downloaded
        })
  
}
