#' Extract non-time series data from CC-HIC
#'
#' @param metadata An uncollected postgres metadata table
#' @param events An uncollected postgres events table
#' @return A tibble of non time series data in the same form as \code{events}
#' @examples
#' extract_demographics(metadata, events)
extract_demographics <- function(metadata = NULL, events = NULL) {

  stopifnot(!is.null(metadata) & !is.null(events))

  data_columns <- metadata %>%
    select(-code_name, -long_name, -primary_column) %>%
    colnames

  statics <- metadata %>%
    mutate(nas = metadata %>%
             select(data_columns) %>%
             as.data.table %>%
             apply(1, function(x) sum(!is.na(x)))) %>%
    filter(nas == 1) %>%
    select(code_name)

  statics <- inner_join(table, statics, by = "code_name")

  return(statics)
}
