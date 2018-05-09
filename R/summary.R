#' @export
summary.real_2d <- function(x) {

  bounds <- x %>%
    group_by(site) %>%
    summarise(early_event = sum(if_else(out_of_bounds == -1, 1L, 0L)),
              late_event = sum(if_else(out_of_bounds == 1, 1L, 0L)))

  range <- x %>%
    group_by(site) %>%
    summarise(low_value = sum(if_else(range_error == -1, 1L, 0L)),
              high_value = sum(if_else(range_error == 1, 1L, 0L)))

  dup <- hrf %>%
    group_by(site) %>%
    summarise(duplicate_events = sum(if_else(duplicate == 1, 1L, 0L)))

  df <- bounds %>%
    full_join(range, by = "site") %>%
    full_join(dup, by = "site") %>%
    gather("error_type", "n", -site)

  return(df)

}

#' @export
summary.integer_2d <- function(x) {

  df <- summary.real_2d(x)

  return(df)

}

#' @export
summary.string_2d <- function(x) {


}


#' @export
summary.real_1d <- function(x) {

  range <- x %>%
    group_by(site) %>%
    summarise(low_value = sum(if_else(range_error == -1, 1L, 0L)),
              high_value = sum(if_else(range_error == 1, 1L, 0L)))

  dup <- hrf %>%
    group_by(site) %>%
    summarise(duplicate_events = sum(if_else(duplicate == 1, 1L, 0L)))

  df <- range %>%
    full_join(dup, by = "site") %>%
    gather("error_type", "n", -site)

  return(df)

}


#' @export
summary.integer_1d <- function(x) {

  df <- summary.real_1d(x)

  return(df)

}


#' @export
summary.string_1d <- function(x) {

  df <- summary.real_1d(x)

  return(df)

}


#' @export
summary.time_1d <- function(x) {

  dup <- hrf %>%
    group_by(site) %>%
    summarise(duplicate_events = sum(if_else(duplicate == 1, 1L, 0L)))

  df <- dup %>%
    gather("error_type", "n", -site)

  return(df)

}
