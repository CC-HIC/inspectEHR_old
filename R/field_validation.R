validate_core_fields <- function(core_table = NULL,
                                 reference_table = NULL,
                                 qref = NULL,
                                 los_table = NULL) {

  pb <- txtProgressBar(1, nrow(core_fields), style = 3)

  core_fields <-
    tribble(
      ~hic_code,            ~min_periodicity,
      "NIHR_HIC_ICU_0108",  6,               # HR
      "NIHR_HIC_ICU_0129",  6,               # SpO2
      "NIHR_HIC_ICU_0141",  1,               # Temp
      "NIHR_HIC_ICU_0166",  0.5,             # Creatinine
      "NIHR_HIC_ICU_0179",  0.5              # Hb
    )

  report <- vector(mode = "list", length = nrow(core_fields))
  names(report) <- core_fields$hic_code

  for (i in 1:nrow(core_fields)) {

    report[[core_fields$hic_code[i]]] <-
      validate_field(
           core_table = core_table,
      reference_table = reference_table,
          input_field = core_fields$hic_code[i],
                 qref = qref,
            los_table = los_table
    )

    setTxtProgressBar(pb, i)

  }

return(report)

}



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
#' \enume{
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

