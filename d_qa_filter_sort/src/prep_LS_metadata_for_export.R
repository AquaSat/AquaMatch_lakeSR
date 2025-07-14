#' @title Prep Landsat metadata data for export
#' 
#' @description
#' This function filters metadata columns and optionally stores the file
#' in a version other than .feather. 
#'
#' @param file file path to feather file to be updated and prepared for export.
#' File name must include `metadata`.
#' @param file_type output file type (either "csv" or "feather")
#' @param qa_identifier date string formatted yyyy-mm-dd used to version the 
#' qa process. This is set in the general configuration yaml under `qa_version`
#' @param gee_identifier date string formatted yyyy-mm-dd used to version the
#' original gee pull. This is set in the general configuration yaml under 
#' `collated_version`
#' @param out_path Directory where updated files should be saved. 
#' 
#' @returns full relative file path of saved file.
#' 
prep_LS_metadata_for_export <- function(file, 
                                        file_type, 
                                        qa_identifier, 
                                        gee_identifier,
                                        out_path) {
  
  # make sure file type is accepted
  if (!file_type %in% c("csv", "feather")) {
    stop("file_type argument unrecognized, only 'csv' and 'feather' are acceptable")
  }
  
  if (!grepl("metadata", file)) {
    stop("File type not recognized from file name, this function does not operate
         without a valid DSWE type or `metadata` in the file name.")
  }
  
  data <- read_feather(file)
  # use set to silence warnings and increase efficiency
  setDT(data)
  
  setnames(data, "system:index", "sat_id")
  
  # filter out images with poor Image Quality (we do this for all sites)
  # make the name for image quality, since it changes through mission groups
  image_qual_name <- if (grepl("LS457", file)) {
    "IMAGE_QUALITY"
  } else {
    "IMAGE_QUALITY_OLI"
  }
  
  data[image_qual_name >= 8]
  
  # we'll export a handful of columns of the metadata that may be useful in 
  # diagnostics/modeling
  
  column_names <- names(data)
  
  pull_cols <- c("sat_id", "ALGORITHM_SOURCE_SURFACE_REFLECTANCE",
                 "ALGORITHM_SOURCE_SURFACE_TEMPERATURE", "CLOUD_COVER",
                 "CLOUD_COVER_LAND", "DATA_SOURCE_REANALYSIS", "DATE_ACQUIRED",
                 "EARTH_SUN_DISTANCE", 
                 column_names[startsWith(column_names, "GEOMETRIC_RMSE")],
                 column_names[startsWith(column_names, "GROUND_CONTROL")],
                 "PROCESSING_SOFTWARE_VERSION", "NADIROFFNADIR", 
                 "IMAGE_QUALITY", "IMAGE_QUALITY_OLI", "IMAGE_QUALITY_TIRS",
                 "UTM", "WRS_ROW", "WRS_PATH", "SUN_AZIMUTH", "SUN_ELEVATION")
  
  # Filter drop_cols to include only existing columns for transfer between data groups
  pull_cols <- pull_cols[pull_cols %in% names(data)]
  
  # select desired columns
  data <- data %>% select(all_of(pull_cols))
  
  # get the basename of the file, without the extension
  fn <- basename(file)
  
  # make ext
  ext <- paste0(".", file_type)
  
  # do some string-replace to create the new fn
  new_fn <- str_replace(fn, 
                        "LSC2_poi_collated_metadata", 
                        "lakeSR_metadata") %>% 
    str_replace(., 
                paste0(gee_identifier, ".feather"), 
                paste0("export_", qa_identifier, ext)) 
  
  # store the new file path
  full_file_path <- file.path(out_path, new_fn)
  
  if (file_type == "csv") {
    write_csv(data, full_file_path)
  }
  if (file_type == "feather") {
    write_feather(data,
                  full_file_path,
                  compression = "lz4")
  }
  
  full_file_path
  
}
