#' Align Date and Time Fields
#'
#'
#' This function takes two fields that are perfectly disjoint with NAs and combines them into 1
#' This is useful where you have details like date and time of death stored in different columns
#'
#' @param tble extraction from core with date and time of death in separate rows
#' @param date date column
#' @param time time column
#' @param key key linking date and time (usually episode_id)
#'
#' @return a tibble
#' @export
#'
#' @examples
#' align_dttm(tble, date, time, key)
align_dttm <- function(tble, date, time, key) {

  date_tbl <- tble %>% select(key, date) %>% na.omit()
  time_tbl <- tble %>% select(key, time) %>% na.omit()

  # an inner join is performed, as if we don't have both sides, it is completely
  # irrelevent to our needs whether or not we have a single component
  # we need to whole date time object
  aligned <- inner_join(date_tbl, time_tbl, by = key)

  return(aligned)

}
