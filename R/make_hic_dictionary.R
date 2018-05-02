# This function take a metadata table and produces a list of NIHR codes describing whether the data
# is static (i.e. only measured once) or time-varying (described here as "dynamic")

makeDict <- function(metadata = NULL) {

  if (is.null(metadata)) stop("You need to provide an UNcollected metadata (variables) table")

  data_columns <- metadata %>%
    dplyr::select(-code_name, -long_name, -primary_column) %>%
    colnames

  statics <- metadata %>%
    collect()

  statics <- statics %>%
    dplyr::mutate(nas = statics %>%
    dplyr::select(data_columns) %>%
    base::apply(1, function(x) sum(!is.na(x)))) %>%
    dplyr::filter(nas == 1) %>%
    dplyr::select(code_name, long_name) %>%
    dplyr::mutate(type = "statics")

  dynamics <- metadata %>%
    dplyr::filter(!(code_name %in% statics$code_name)) %>%
    dplyr::select(code_name, long_name, type = primary_column) %>%
    collect

  dict <- rbind(statics, dynamics)

  return(dict)

}
