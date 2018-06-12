#' Validate CC-HIC Episodes
#'
#' This function removes episodes that occur during particularly sparse periods (as this is likely that these
#' months are contributing poor data) and return only episodes that have a logical consistency in non-sparse months
#'
#'
#' @param episode_length_tbl tibble containing episode characteristics from epi_length()
#' @param invalidated_months tibble containing months with sparse data contribution from invalid_months()
#'
#' @return a tibble with a single column containing episodes that have passed basic (level 1) validation checks
#' @export
#'
#' @import dplyr
#' @importFrom lubridate year month
#' @importFrom magrittr %>%
#'
#' @examples
validate_episode <- function(episode_length_tbl, invalidated_months) {

  df <- episode_length_tbl %>%
    mutate(year = lubridate::year(epi_start_dttm),
          month = lubridate::month(epi_end_dttm)) %>%
    dplyr::left_join(invalidated_months, by = c(
      "site" = "site",
      "year" = "year",
      "month" = "month"
    )) %>%
    dplyr::filter(is.na(count),
                  validity == 0) %>%
    dplyr::select(episode_id)

  return(df)

}


#' Validate CC-HIC Events
#'
#' Validates a CC-HIC event. This should be applied after event flagging has taken place
#'
#' @param validated_episodes a tibble with 1 column of validated episodes
#' @param flagged_data_item a tibble of a CC-HIC event with full condition flagging
#'
#' @return a character vector with event IDs for validated episodes
#'
#' @export
#'
#' @importFrom rlang !! .data
#'
#' @examples
#' validate_field(core, reference, "NIHR_HIC_ICU_0108", qref, episode_length)
validate_event <- function(validated_episodes = NULL, flagged_events = NULL) {

  x <- flagged_events %>%
    dplyr::filter(.data$range_error == 0 | is.na(.data$range_error),
                  .data$out_of_bounds == 0 | is.na(.data$out_of_bounds),
                  .data$duplicate == 0 | is.na(.data$duplicate)) %>%
    dplyr::select(.data$episode_id, .data$internal_id) %>%
    dplyr::inner_join(validated_episodes, by = "episode_id") %>%
    dplyr::select(.data$internal_id) %>%
    dplyr::pull()

  return(x)

}
