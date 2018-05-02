#' Provides a raw table for extracted datetime values
#'
#'
#' @param outliers integer value for the number of standard deviations used for outlier detection
#' @param core_table
#' @param input
#'
#' @return A tibble of time series data in summary
#' @examples
#' \dontrun{process_dbl(core)}
process_dttm <- function(core_table = NULL, input = "NIHR_HIC_ICU_0411") {

  if (is.null(core_table)) stop("You must include the tables")

  processed_dttm <- core_table %>%
    filter(code_name == input) %>%
    select(site, code_name, episode_id, datetime) %>%
    collect()

  return(processed_dttm)

}
