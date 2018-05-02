#' Provides a summary for time-series data of "real"/"double" data type
#'
#' @param real_input character vector of NIHR codes for the reals that you wish to report
#' @param outliers integer value for the number of standard deviations used for outlier identification
#' @param inUnits character for duration based units to retunr
#' @param core_table
#' @param los_table
#'
#' @return A tibble of time series data in summary
#' @examples
#' \dontrun{summarise_dbl(c("events", "episodes", "provenance"), los, "NIHR_HIC_ICU_0557")}
summarise_dbl <- function(coverage_list = NULL,
                              los_table = NULL) {

  if (is.null(coverage_list)) stop("You must place a coverage list here")

  # Can only use "in bounds cases" to identify periodicity
  coverage_list[["complete"]] %>%
    dplyr::filter(out_of_bounds == "Within") %>%
    dplyr::left_join(los_table %>%
      dplyr::filter(validity == "valid") %>%
      dplyr::select(episode_id:los), by = "episode_id") %>%
    dplyr::group_by(episode_id) %>%
    dplyr::summarise(first = min(datetime),
                      last = max(datetime),
                     count = n()) %>%
    dplyr::left_join(los_table %>%
      dplyr::filter(validity == "valid"), by = "episode_id") %>%
    dplyr::ungroup() %>%
    dplyr::mutate(lead = round(difftime(first, epi_start_dttm, units = "days"), 2),
                   lag = round(difftime(epi_end_dttm, last, units = "days"), 2),
           periodicity = count/as.numeric(los)) %>%
    dplyr::mutate(within24 = ifelse(lead >= -2 & lead <= 2, "valid", "invalid")) -> coverage_list[["summary"]]

  return(coverage_list)

}
