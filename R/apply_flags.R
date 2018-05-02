# ==== APPLY ALL FLAGS


#' Apply warning flags to extracted data item
#'
#' Applies warning flags to an extracted HIC data item. This is a wrapper function
#' to flag_range, flag_bounds and flag duplicate
#'
#' @param x extracted data item
#' @param qref quality reference table
#' @param los_table episode length table
#'
#' @return a tibble with flags applied
#' @export
#'
#' @examples
flag_all <- function(x, qref = NULL, los_table = NULL) {

  rf <- x %>% flag_range(qref = qref)
  bf <- x %>% flag_bounds(los_table = los_table)
  df <- x %>% flag_duplicate()

  x %<>%
    left_join(rf, by = "internal_id") %>%
    left_join(bf, by = "internal_id") %>%
    left_join(df, by = "internal_id") %>%
    flag_periodicity(los_table = los_table)

  return(x)

}


# ==== FLAG BY EPISODE REFERENCE RANGE


#' Flag Events by Reference Range (S3 Generic)
#'
#' S3 generic
#' Flags each event as being in range (0), out of range high (+1) or out of range low (-1)
#'
#' @param x an extracted event table
#' @param ... further arguments to pass to the S3 method
#'
#' @return a tibble of the same length as x with the following features:
#' \item{1}{event is a duplicate}
#' \item{0}{event is not a duplicate}
#' @export
#'
#'
#' @examples
flag_range <- function(x, ...) {
  UseMethod("flag_range", x)
}


#' @export
flag_range.hic_dbl <- function(x = NULL, qref = NULL) {

  # joins to the quality refernce table to identify range errors
  x %<>%
    dplyr::left_join(qref, by = "code_name") %>%
    dplyr::mutate(range_error = ifelse(value > range_max, 1L,
                                       ifelse(value < range_min, -1L, 0L))) %>%
    dplyr::select(internal_id, range_error)

  class(x) <- append(class(x), "hic_dbl")

  return(x)

}


#' @export
flag_range.hic_int <- function(x = NULL, qref = NULL) {

  # joins to the quality refernce table to identify range errors
  x %<>%
    dplyr::left_join(qref, by = "code_name") %>%
    dplyr::mutate(range_error = ifelse(value > range_max, 1L,
                                       ifelse(value < range_min, -1L, 0L))) %>%
    dplyr::select(internal_id, range_error)

  class(x) <- append(class(x), "hic_int")

  return(x)

}


#' @export
flag_range.hic_str <- function(x = NULL, qref = NULL) {

  data_item <- x[1, "code_name"] %>% pull

  permitted <- qref %>%
    filter(code_name == data_item) %>%
    select(data) %>%
    unnest() %>%
    select(metadata_labels) %>%
    pull

  # joins to the quality refernce table to identify range errors
  x %<>%
    dplyr::mutate(range_error = ifelse(value %in% permitted, 0L, 1L)) %>%
    dplyr::select(internal_id, range_error)

  class(x) <- append(class(x), "hic_str")

  return(x)

}


# ==== FLAG BY EPISODE BOUNDARIES


#' Flag Events by Episode Boundaries (S3 Generic)
#'
#' If the event of concern is a string, since only Airway and Organism are time varying string fields
#' the behavior on hic_str differs.
#'
#' @param x an extracted tibble
#' @param ...
#'
#' @return a tibble of the same length as x with the following values
#' \item{-1}{event occurred significantly before ICU episode}
#' \item{0}{event occurred during ICU episode}
#' \item{+1}{event occurred significantly after ICU episode}
#' \item{NA}{Foundation elements were not availible and so this parameter could not be calculated}
#' @export
#'
#' @examples
#'
#' flag_bounds(x, los_table)
flag_bounds <- function(x, ...) {
  UseMethod("flag_bounds", x)
}


#' @export
flag_bounds.hic_dbl <- function(x = NULL, los_table = NULL) {

  x %<>%
    left_join(los_table %>% select(-site), by = "episode_id") %>%

    # Applied -1 for before, 0 for within, +1 fpr after. NA if end date is missing
    mutate(out_of_bounds = ifelse(difftime(datetime, epi_start_dttm, units = "days") < -2, -1L,
                                  ifelse(difftime(datetime, epi_end_dttm, units = "days") > 2, 1L,
                                         ifelse(is.na(epi_start_dttm) | is.na(epi_end_dttm), NA, 0L)))) %>%
    select(internal_id, out_of_bounds)

  class(x) <- append(class(x), "hic_dbl")

  return(x)

}


#' @export
flag_bounds.hic_int <- function(x = NULL, los_table = NULL) {

  x %<>%
    left_join(los_table %>% select(-site), by = "episode_id") %>%

    # Applied -1 for before, 0 for within, +1 fpr after. NA if end date is missing
    mutate(out_of_bounds = ifelse(difftime(datetime, epi_start_dttm, units = "days") < -2, -1L,
                                  ifelse(difftime(datetime, epi_end_dttm, units = "days") > 2, 1L,
                                         ifelse(is.na(epi_start_dttm) | is.na(epi_end_dttm), NA, 0L)))) %>%
    select(internal_id, out_of_bounds)

  class(x) <- append(class(x), "hic_int")

  return(x)

}


#' @export
flag_bounds.hic_str <- function(x = NULL, los_table = NULL) {

    x %<>%
      left_join(los_table %>% select(-site), by = "episode_id") %>%
      # Applied -1 for before, 0 for within, +1 fpr after. NA if end date is missing
      mutate(out_of_bounds = ifelse(difftime(datetime, epi_start_dttm, units = "days") < -2, -1L,
                                  ifelse(difftime(datetime, epi_end_dttm, units = "days") > 2, 1L,
                                         ifelse(is.na(epi_start_dttm) | is.na(epi_end_dttm), NA, 0L)))) %>%

    select(internal_id, out_of_bounds)

  class(x) <- append(class(x), "hic_str")

  return(x)

}


# ==== FLAG DUPLICATE


#' Flag Duplicates (S3 Generic)
#'
#' @param x
#' @param ...
#'
#' @return
#' @export
#'
#' @examples
flag_duplicate <- function(x, ...) {
  UseMethod("flag_duplicate", x)
}


#' @export
flag_duplicate.hic_dbl <- function(x = NULL) {

  x %<>%
    ungroup() %>%
    distinct(episode_id, datetime, value, .keep_all = TRUE) %>%
    mutate(duplicate = 0L) %>%
    select(internal_id, duplicate) %>%
    right_join(x, by = "internal_id") %>%
    mutate_at(.vars = vars(duplicate),
              .funs = funs(ifelse(is.na(.), 1L, .))) %>%
    select(internal_id, duplicate)

  class(x) <- append(class(x), "hic_dbl")

  return(x)

}


#' @export
flag_duplicate.hic_int <- function(x = NULL) {

  x %<>%
    ungroup() %>%
    distinct(episode_id, datetime, value, .keep_all = TRUE) %>%
    mutate(duplicate = 0L) %>%
    select(internal_id, duplicate) %>%
    right_join(x, by = "internal_id") %>%
    mutate_at(.vars = vars(duplicate),
              .funs = funs(ifelse(is.na(.), 1L, .))) %>%
    select(internal_id, duplicate)

  class(x) <- append(class(x), "hic_int")

  return(x)

}


#' @export
flag_duplicate.hic_str <- function(x = NULL) {

  x %<>%
    ungroup() %>%
    distinct(episode_id, datetime, value, .keep_all = TRUE) %>%
    mutate(duplicate = 0L) %>%
    select(internal_id, duplicate) %>%
    right_join(x, by = "internal_id") %>%
    mutate_at(.vars = vars(duplicate),
              .funs = funs(ifelse(is.na(.), 1L, .))) %>%
    select(internal_id, duplicate)

  class(x) <- append(class(x), "hic_str")

  return(x)

}


#' Flags for Periodicity of a Data Item (S3 Generic)
#'
#' Takes a data item tibble that has been pre-flagged with range, boundary and duplicate errors
#' and provides a column indicating the periodicity of that data item stratified by each episode
#' number. This is a similar concept to the coverage mapping, although is looking at patient
#' level rather than site level.
#'
#' @param x
#' @param ...
#'
#' @return
#' @export
#'
#' @examples
flag_periodicity <- function(x, ...) {
  UseMethod("flag_periodicity", x)
}


#' @export
flag_periodicity.default <- function(x) {

  print("There are no default methods for this class")

}


#' @export
flag_periodicity.hic_dbl <- function(x, los_table = NULL) {

  x %<>%
    dplyr::filter(out_of_bounds == 0,
                  range_error == 0,
                  duplicate == 0) %>%
    dplyr::select(episode_id, datetime) %>%
    dplyr::group_by(episode_id) %>%
    dplyr::summarise(count = n()) %>%
    dplyr::left_join(los_table %>%
                       dplyr::filter(validity == 0) %>%
                       dplyr::select(episode_id, los),
                     by = "episode_id") %>%
    dplyr::mutate(periodicity = count/as.numeric(los)) %>%
    dplyr::select(episode_id, periodicity) %>%
    dplyr::right_join(x, by = "episode_id")

  class(x) <- append(class(x), "hic_dbl")

  return(x)

}


#' @export
flag_periodicity.hic_int <- function(x, los_table = NULL) {

  x %<>%
    dplyr::filter(out_of_bounds == 0,
                  range_error == 0,
                  duplicate == 0) %>%
    dplyr::select(episode_id, datetime) %>%
    dplyr::group_by(episode_id) %>%
    dplyr::summarise(count = n()) %>%
    dplyr::left_join(los_table %>%
                       dplyr::filter(validity == 0) %>%
                       dplyr::select(episode_id, los),
                     by = "episode_id") %>%
    dplyr::mutate(periodicity = count/as.numeric(los)) %>%
    dplyr::select(episode_id, periodicity) %>%
    dplyr::right_join(x, by = "episode_id")

  class(x) <- append(class(x), "hic_int")

  return(x)

}


#' @export
flag_periodicity.hic_str <- function(x, los_table = NULL) {

  x %<>%
    dplyr::filter(out_of_bounds == 0,
                  range_error == 0,
                  duplicate == 0) %>%
    dplyr::group_by(episode_id) %>%
    dplyr::summarise(events = n()) %>%
    dplyr::left_join(los_table, by = "episode_id") %>%
    dplyr::mutate(periodicity = events/(as.numeric(los)*24)) %>%
    dplyr::select(episode_id, events, periodicity, epi_start_dttm) %>%
    dplyr::right_join(x, by = "episode_id")

## label any value without a periodicity as suspicious

  class(x) <- append(class(x), "hic_str")

  return(x)

}




