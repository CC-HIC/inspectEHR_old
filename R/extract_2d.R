#' Reshapes timevarying events into hourly cadance table
#'
#' This is the workhorse function that transcribes 2d data from the DB
#' to a dense table with 1 column per variable (and metadata if relevent)
#' and 1 row per hour per patient.
#'
#' Choose what variables you want to pull out wisely. Whilst this is actually
#' pretty quick considering what it needs to do, it can take a long time, especially
#' if you do this on the whole database. Typically, for 1 variable that is very
#' well decribed within HIC (i.e. hear rate), this could take around 20 mins.
#' The whole database might take upward of 6 hours to complete.
#'
#' It is perfectly possible for this table to produce negative hours. If, for example
#' a patient had a measure taken in the hours before they were admitted, then this would
#' be added to the table with a negative time value. As a concrete example,
#' if a patient had a sodium measured at 08:00, and they were admitted to the
#' ICU at 20:00 the same day, then the sodium would present on the output table
#' at time = -12. This is normal behaviour it is left to the end user to
#' descibe how best they wish to account for this.
#'
#' @param events database events table
#' @param metadata database metadata table (collected)
#'
#' @return sparse tibble with hourly cadance as rows, and unique hic events as columns
#' @export
#'
#' @importFrom purrr map imap
#'
#' @examples
#' \dontrun{
#' extract_timevarying(tbls[["events"]], tbls[["variables"]] %>% collect)
#' extract_timevarying(tbls[["events"]] %>%
#'   filter(code_name %in% c("NIHR_HIC_ICU_0108", "NIHR_HIC_ICU_0411")),
#'   tbls[["variables"]] %>% collect)
#'   # returns just heart rates
#'   # you MUST include 0411 here as the start datetime is a mandatory field
#'
#' }
#'
extract_timevarying <- function(events, metadata, chunk_size = 5000) {

  episode_groups <- events %>%
    select(episode_id) %>%
    distinct() %>%
    collect() %>%
    mutate(group = as.integer(seq(n())/chunk_size)) %>%
    split(., .$group) %>%
    map(function(epi_ids) {

      collect_events <- events %>%
        filter(episode_id %in% epi_ids$episode_id) %>%
        collect()

      map(collect_events %>%
            select(episode_id) %>%
            distinct() %>%
            pull(), process_all, events = collect_events, metadata = metadata) %>%
          bind_rows()

      }) %>%
    bind_rows()



}

process_all <- function(epi_id, events, metadata) {

  pt <- events %>%
    filter(episode_id == epi_id)

  start_time <- pt %>%
    filter(code_name == "NIHR_HIC_ICU_0411") %>%
    mutate(datetime = as.POSIXct(datetime, origin = "1970-01-01 00:00:00")) %>%
    select(datetime) %>%
    pull

  imap(pt %>%
         filter(code_name %in% find_2d(metadata)$code_name) %>%
         arrange(code_name) %>%
         split(., .$code_name), process_episode, metadata = metadata, start_time = start_time) %>%
    reduce(full_join, by = "r_diff_time", .init = tibble(r_diff_time = as.integer(NULL))) %>%
    rename(time = r_diff_time) %>%
    mutate(episode_id = epi_id) %>%
    arrange(time)

}


process_episode <- function(df, var_name, metadata, start_time) {

  stopifnot(!is.na(df$datetime))

  prim_col <- metadata %>%
    filter(code_name == var_name) %>%
    select(primary_column) %>%
    pull

  meta_names <- find_2d_meta(metadata, var_name)

  tb_a <- df %>%
    mutate(datetime = as.POSIXct(datetime, origin = "1970-01-01 00:00:00")) %>%
    mutate(diff_time = difftime(datetime, start_time, units = "hours")) %>%
    mutate(r_diff_time = as.integer(round(diff_time))) %>%
    distinct(r_diff_time, .keep_all = TRUE) %>%
    select(-event_id, -episode_id, -datetime, -code_name, -diff_time) %>%
    rename(!! var_name := prim_col) %>%
    select(r_diff_time, !! var_name, !!! meta_names)

  if(length(meta_names) == 0) {

    return(tb_a)

  }

  names(meta_names) <- paste(var_name, "meta", 1:length(meta_names), sep = ".")
  rename(tb_a, !!! meta_names)

}


not_na <- function(x) {

  any(!is.na(x))

}


find_2d <- function(metadata) {
  metadata %>%
  dplyr::mutate(nas = metadata %>%
                  dplyr::select(-code_name, -long_name, -primary_column) %>%
                  collect() %>%
                  tibble::as.tibble() %>%
                  apply(1, function(x) sum(!is.na(x)))) %>%
  dplyr::filter(nas > 1) %>%
  dplyr::select(code_name, primary_column)
}


find_2d_meta <- function(metadata, c_name) {

  select_row <- metadata %>%
    filter(code_name == c_name)

  prim_col <- select_row %>%
    select(primary_column) %>%
    pull()

  select_row %>%
    select(-code_name, -long_name, -primary_column, -datetime, -!! prim_col) %>%
    select_if(.predicate = not_na) %>%
    names()

}



#' Fill in 2d Table to make a Sparse Table
#'
#' The extract_timevarying returns a non-sparse table (i.e. rows/hours with
#' no recorded information for a patient are not presented in the table)
#' This function serves to expand the table and fill missing rows with NAs.
#' This is useful when working with most time-series aware stats packages
#' that expect a regular cadance to the table.
#'
#' @param df a dense time series table produced from extract_timevarying
#'
#' @return a sparse time series table
#' @export
#'
#' @examples
#' \{dontrun
#' expand_missing(tb_1)
#' }
expand_missing <- function(df) {

  df %>%
    select(episode_id, time) %>%
    split(., .$episode_id) %>%
    imap(function(base_table, epi_id) {
      tibble(episode_id = epi_id,
            time = seq(min(base_table$time, 0), max(base_table$time, 0)))
        }
      ) %>%
    bind_rows() %>%
    left_join(df, by = c("episode_id", "time"))
}
