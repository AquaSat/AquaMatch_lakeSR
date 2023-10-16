#' @title Read and format yaml file
#' 
#' @description 
#' Function to read in yaml, reformat and pivot for easy use in scripts
#' 
#' @param yml yaml file loaded as {target} config_file_poi
#' @returns filepath for the .csv of the reformatted yaml file. Silently saves 
#' the .csv in the `b_pull_Landsat_SRST_poi/in` directory path.
#' 
#' 
format_yaml <-  function(yml) {
  yaml <- yml
  # create a nested tibble from the yaml file
  nested <-  map_dfr(names(yaml), 
                     function(x) {
                       tibble(set_name = x,
                              param = yaml[[x]])
                     })
  # create a new column to contaitn the nested parameter name and unnest the name
  nested$desc <- NA_character_
  unnested <- map_dfr(seq(1:length(nested$param)),
                      function(x) {
                        name <- names(nested$param[[x]])
                        nested$desc[x] <- name
                        nested <- nested %>% 
                          unnest(param) %>% 
                          mutate(param = as.character(param))
                        nested[x, ]
                      })
  # re-orient to make it easy to grab necessary info in future functions
  unnested <- unnested %>% 
    select(desc, param) %>% 
    pivot_wider(names_from = desc, values_from = param)
  write_csv(unnested, "b_pull_Landsat_SRST_poi/mid/yml.csv")
  "b_pull_Landsat_SRST_poi/mid/yml.csv"
}

