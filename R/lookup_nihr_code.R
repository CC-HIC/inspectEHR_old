#' Lookup HIC Value
#'
#' Performs a quick search of the HIC data catalogue
#'
#' @param search search term as either a code (numeric) or name (character)
#'
#' @return a pander table with query results
#' @export
#'
#' @importFrom pander pander
#'
#' @examples
#' lookup_hic()
lookup_hic <- function(search = 0108) {

  if (is.numeric(search)) {

    search_result <- qref %>%
      filter(grepl(search, code_name))

  } else if (is.character(search)) {

    search_result <- qref %>%
      filter(grepl(search, short_name))

  }

  if (nrow(search_result) == 0) {
    print("no search results")
  } else {
    pander(search_result)
  }

}

