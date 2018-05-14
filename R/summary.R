#' @export
summary <- function(x = NULL) {
  UseMethod("summary", x)
}


#' Summary for flagged data item
#'
#' @param x
#'
#' @return
#' @export
#'
#' @importFrom magrittr %>% %<>%
#' @importFrom rlang .data
#'
#' @examples
summary_main <- function(x) {

  bounds <- x %>%
    group_by(.data$site) %>%
    summarise(
      early_event = sum(
        ifelse(.data$out_of_bounds == -1, 1L, 0L)),
      late_event = sum(
        ifelse(.data$out_of_bounds == 1, 1L, 0L)))

  range <- x %>%
    group_by(.data$site) %>%
    summarise(
      low_value = sum(
        ifelse(.data$range_error == -1, 1L, 0L)),
      high_value = sum(
        ifelse(.data$range_error == 1, 1L, 0L)))

  dup <- x %>%
    group_by(.data$site) %>%
    summarise(
      duplicate_events = sum(
        ifelse(.data$duplicate == 1, 1L, 0L)))

  df <- bounds %>%
    full_join(range, by = "site") %>%
    full_join(dup, by = "site") %>%
    gather("error_type", "n", -.data$site)

  return(df)

}


summary.real_2d <- function(x) {

  x %<>% summary_main()

  return(x)

}


summary.integer_2d <- function(x) {

  x %<>% summary_main()

  return(x)

}


summary.string_2d <- function(x) {

  x %<>% summary_main()

  return(x)

}


summary.real_1d <- function(x) {

  x %<>% summary_main()

  return(x)

}


summary.integer_1d <- function(x) {

  x %<>% summary_main()

  return(x)

}


summary.string_1d <- function(x) {

  x %<>% summary_main()

  return(x)

}


summary.time_1d <- function(x) {

  x %<>% summary_main()

  return(x)

}


summary.date_1d <- function(x) {

  x %<>% summary_main()

  return(x)

}



summary.datetime_1d <- function(x) {

  x %<>% summary_main()

  return(x)

}
