warning_summary <- function(x) {
  UseMethod("warning_summary", x)
}

warning_summary.hic_dbl <- function(x) {

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


warning_summary.hic_int <- function(x) {

  df <- warning_summary.hic_dbl(x)

  return(df)

}
