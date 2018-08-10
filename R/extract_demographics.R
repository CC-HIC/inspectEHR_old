#' Extract 1d data from CC-HIC
#'
#' @param metadata a database metadata table
#' @param events a database events table
#'
#' @export
#'
#' @return A tibble of 1d data
#' @examples
#' extract_demographics(metadata, events, cast_style = "wide")
#' extract_demographics(metadata, events, cast_style = "tall")
extract_demographics <- function(metadata = NULL, events = NULL, cast_style = "tall") {

  stopifnot(!is.null(metadata) & !is.null(events))

  data_columns <- metadata %>%
    dplyr::select(-code_name, -long_name, -primary_column) %>%
    colnames

  demographics <- metadata %>%
    dplyr::mutate(nas = metadata %>%
             dplyr::select(data_columns) %>%
             tibble::as.tibble() %>%
             apply(1, function(x) sum(!is.na(x)))) %>%
    dplyr::filter(nas == 1) %>%
    dplyr::select(code_name)

  demographics <- dplyr::inner_join(events, demographics, by = "code_name")

  if (cast_style == "tall") {

    return(demographics)

  }

  if (cast_style == "wide") {

    wide_demographics <- demographics %>%
      spread(key = code_name,
             value = value)

    return(wide_demographics)

  }


}
