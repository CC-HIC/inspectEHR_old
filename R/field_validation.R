#' Validate HIC Field
#'
#' Wraps the following workflow:
#' Extract > Flag > Summarise > Plot
#'
#' @param core_table core table
#' @param reference_table reference table
#' @param input_field character vecotr of input field
#' @param qref quality reference table
#' @param los_table episode length table
#'
#' @return a list with:
#' \enumerate{
#'   \item flagged events
#'   \item warning summaries
#'   \item
#' }
#'
#' @export
#'
#' @examples
#' validate_field(core, reference, "NIHR_HIC_ICU_0108", qref, episode_length)
validate_field <- function(core_table = NULL,
                      reference_table = NULL,
                          input_field = NULL,
                                 qref = NULL,
                            los_table = NULL) {

  field_report <- vector(mode = "list", length = 3)
  names(field_report) <- c("flagged", "warnings", "na")

  try(field_report$flagged <-
    extract(core_table = core_table, qref = qref, input = input_field) %>%
    flag_all(qref = qref, los_table = los_table))

  try(field_report$warnings <-
    warning_summary(field_report$flagged))

  try(field_report$na <- add_na(field_report$flagged, reference_table = reference_table) %>%
      group_by(site) %>%
      summarise(count = n()))

  return(field_report)

}

