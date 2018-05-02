warning_summary <- function(x) {
  UseMethod("warning_summary", x)
}

warning_summary.hic_dbl <- function(x) {

  bounds <- x %>%
    group_by(site, out_of_bounds) %>%
    filter(out_of_bounds == -1 | out_of_bounds == 1) %>%
    summarise(intermediate = n()) %>%
    group_by(site) %>%
    summarise(count = sum(intermediate)) %>%
    mutate(filter_type = "boundary_48")

  range <- x %>%
    group_by(site, range_error) %>%
    filter(range_error == -1 | range_error == 1) %>%
    summarise(intermediate = n()) %>%
    group_by(site) %>%
    summarise(count = sum(intermediate)) %>%
    mutate(filter_type = "range_error")

  duplicates <- x %>%
    filter(duplicate == 1) %>%
    group_by(site) %>%
    summarise(count = n()) %>%
    mutate(filter_type = "duplicates")

  df <- rbind(range, bounds, duplicates) %>%
    select(site, filter_type, count) %>%
    arrange(site, filter_type) %>%
    spread(key = filter_type, value = count)

  return(df)

}


warning_summary.hic_int <- function(x) {

  bounds <- x %>%
    group_by(site, out_of_bounds) %>%
    filter(out_of_bounds == -1 | out_of_bounds == 1) %>%
    summarise(intermediate = n()) %>%
    group_by(site) %>%
    summarise(count = sum(intermediate)) %>%
    mutate(filter_type = "boundary_48")

  range <- x %>%
    group_by(site, range_error) %>%
    filter(range_error == -1 | range_error == 1) %>%
    summarise(intermediate = n()) %>%
    group_by(site) %>%
    summarise(count = sum(intermediate)) %>%
    mutate(filter_type = "range_error")

  duplicates <- x %>%
    filter(duplicate == 1) %>%
    group_by(site) %>%
    summarise(count = n()) %>%
    mutate(filter_type = "duplicates")

  df <- rbind(range, bounds, duplicates) %>%
    select(site, filter_type, count) %>%
    arrange(site, filter_type) %>%
    spread(key = filter_type, value = count)

  return(df)

}
