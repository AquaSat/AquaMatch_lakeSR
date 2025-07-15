#' @title Export a single target to Google Drive
#' 
#' @description
#' A function to export a single target (as a file) to Google Drive and return
#' the shareable Drive link as a file path.
#' 
#' @param file_path string; file.path() for file to be exported to Drive
#' 
#' @param drive_path A path to the folder on Google Drive where the file
#' should be exported to. This must begin with "~/", the path relative to the 
#' root directory
#' 
#' @param google_email A string containing the gmail address to use for
#' Google Drive authentication.
#' 
#' @returns Drive information about the uploaded file in a 'dribble'
#' 
#' 
export_single_file <- function(file_path, 
                               drive_path,
                               google_email) {
  
  # Authorize using the google email provided
  drive_auth(google_email)
  
  # get the file name we care about
  file = last(str_split(file_path, "/")[[1]])
  
  # check to see if path exists, if it doesn't, create it
  with_drive_quiet({
    tryCatch({
      return <- drive_get(path = drive_path)
    },
    error = function(e) {
      folders <- unlist(str_split(drive_path, "/"))
      folders <- folders[nchar(folders)>1]
      walk(
        # make a variable of position
        .x = 1:length(folders),
        .f = \(p) {
          current_path <- str_replace(drive_path, paste0("^(([^/]*/){", p+1, "}).*"), "\\1") 
          return <- drive_get(path = current_path)
          if (nrow(return) == 0) {
            drive_mkdir(name = folders[p], # current folder name
                        path = str_replace(drive_path, paste0("^(([^/]*/){", p, "}).*"), "\\1")) # one parent folder path
          }
        })
    })
  })
  
  # send to Google Drive
  out_file <- drive_put(media = file_path,
                        # The folder on Google Drive
                        path = drive_path,
                        # The filename on Google Drive
                        name = file)
  
  # Make the Google Drive link shareable: anyone can view
  drive_share_anyone(out_file)
  
  # return the information about the uploaded file
  out_file
  
}
