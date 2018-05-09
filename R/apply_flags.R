#' Apply all validation flags to an extracted data item
#'
#' Applies validation flags to an extracted data item. This is a wrapper function with conditional
#' logic to flag for:
#' data item out of value range
#' data item out of temporal range of the episode
#' duplication of item
#' periodicity
#'
#' periodicity checking is conditional on the preceding 3 flags, as ony those events that validate
#' are taking into consideration of periodicity checking
#'
#' @param x extracted data item
#' @param los_table episode length table
#'
#' @return a tibble with flags applied
#' @export
#'
#' @examples
flag_all <- function(x, los_table = NULL) {

  if (!(any(class(x) %in% preserved_classes))) {
    stop("this function is not defined for this class")
  }

  # check the availible methods for this class
  avail_methods <- methods(class = class(x)[1])
  event_class <- class(x)[1]

  # Apply this flag if an appropriate method exists, or return NA
  if (any(grepl("flag_range", avail_methods))) {
    rf <- x %>% flag_range()
  } else {
    rf <- x %>%
      dplyr::mutate(range_error = NA) %>%
      dplyr::select(internal_id, range_error)
  }

  if (any(grepl("flag_bounds", avail_methods))) {
    bf <- x %>% flag_bounds(los_table = los_table)
  } else {
    bf <- x %>%
      dplyr::mutate(out_of_bounds = NA) %>%
      dplyr::select(internal_id, out_of_bounds)
  }

  if (any(grepl("flag_duplicate", avail_methods))) {
    df <- x %>% flag_duplicate()
  } else {
    df <- x %>%
      dplyr::mutate(duplicate = NA) %>%
      dplyr::select(internal_id, duplicate)
  }

  # Join the flags above back to the original df
  # This step must be performed prior to periodicity checking
  x %<>%
    left_join(rf, by = "internal_id") %>%
    left_join(bf, by = "internal_id") %>%
    left_join(df, by = "internal_id")

  # Apply periodicity if a method exists
  if (any(grepl("flag_periodicity", avail_methods))) {
    x %<>% flag_periodicity(los_table = los_table)
  } else {
    x %<>%
      dplyr::mutate(periodicity = NA)
  }

  class(x) <- append(class(x), event_class, after = 0)

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
flag_range <- function(x) {
  UseMethod("flag_range", x)
}


#' @export
flag_range.default <- function(...) {

  print("there are no methods for this class")

}


#' @export
flag_range.real_2d <- function(x = NULL) {

  # joins to the quality refernce table to identify range errors
  x %<>%
    dplyr::left_join(qref, by = "code_name") %>%
    dplyr::mutate(range_error = ifelse(value > range_max, 1L,
                                       ifelse(value < range_min, -1L, 0L))) %>%
    dplyr::select(internal_id, range_error)

  class(x) <- append(class(x), "real_2d", after = 0)

  return(x)

}


#' @export
flag_range.real_1d <- function(x = NULL) {

  # joins to the quality refernce table to identify range errors
  x %<>%
    dplyr::left_join(qref, by = "code_name") %>%
    dplyr::mutate(range_error = ifelse(value > range_max, 1L,
                                       ifelse(value < range_min, -1L, 0L))) %>%
    dplyr::select(internal_id, range_error)

  class(x) <- append(class(x), "real_1d", after = 0)

  return(x)

}


#' @export
flag_range.integer_2d <- function(x = NULL) {

  # joins to the quality refernce table to identify range errors
  x %<>%
    dplyr::left_join(qref, by = "code_name") %>%
    dplyr::mutate(range_error = ifelse(value > range_max, 1L,
                                       ifelse(value < range_min, -1L, 0L))) %>%
    dplyr::select(internal_id, range_error)

  class(x) <- append(class(x), "integer_2d", after = 0)

  return(x)

}


#' @export
flag_range.integer_1d <- function(x = NULL) {

  # joins to the quality refernce table to identify range errors
  x %<>%
    dplyr::left_join(qref, by = "code_name") %>%
    dplyr::mutate(range_error = ifelse(value > range_max, 1L,
                                       ifelse(value < range_min, -1L, 0L))) %>%
    dplyr::select(internal_id, range_error)

  class(x) <- append(class(x), "integer_1d", after = 0)

  return(x)

}


#' @export
flag_range.string_2d <- function(x = NULL) {

  # joins to the quality refernce table to identify range errors
  x %<>%
    dplyr::mutate(range_error = if_else(str_length(value) <= 2, 0L, 1L)) %>%
    dplyr::select(internal_id, range_error)

  class(x) <- append(class(x), "string_2d", after = 0)

  return(x)

}


#' @export
flag_range.string_1d <- function(x = NULL) {

  # joins to the quality refernce table to identify range errors
  x %<>%
    dplyr::mutate(range_error = if_else(str_length(value) <= 2, 0L, 1L)) %>%
    dplyr::select(internal_id, range_error)

  class(x) <- append(class(x), "string_1d", after = 0)

  return(x)

}


#' @export
flag_range.date_1d <- function(x = NULL) {

  # joins to the quality refernce table to identify range errors
  x %<>%
    dplyr::mutate(range_error = if_else(value > Sys.Date(), 1L,
                                        if_else(value < lubridate::dmy("01/01/1900"), -1L, 0))) %>%
    dplyr::select(internal_id, range_error)

  class(x) <- append(class(x), "date_1d", after = 0)

  return(x)

}


#' @export
flag_range.datetime_1d <- function(x = NULL) {

  # joins to the quality refernce table to identify range errors
  x %<>%
    dplyr::mutate(range_error = if_else(value > Sys.time(), 1L,
                                        if_else(value < lubridate::dmy_hms("01/01/1900 00:00:00"), -1L, 0))) %>%
    dplyr::select(internal_id, range_error)

  class(x) <- append(class(x), "datetime_1d", after = 0)

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
flag_bounds <- function(x, los_table = NULL) {
  UseMethod("flag_bounds", x)
}


flag_bounds.default <- function(...) {

  print("there are no methods for this class")

}


#' @export
flag_bounds.real_2d <- function(x = NULL, los_table = NULL) {

  x %<>%
    left_join(los_table %>% select(-site), by = "episode_id") %>%

    # Applied -1 for before, 0 for within, +1 fpr after. NA if end date is missing
    mutate(out_of_bounds = ifelse(difftime(datetime, epi_start_dttm, units = "days") < -2, -1L,
                                  ifelse(difftime(datetime, epi_end_dttm, units = "days") > 2, 1L,
                                         ifelse(is.na(epi_start_dttm) | is.na(epi_end_dttm), NA, 0L)))) %>%
    select(internal_id, out_of_bounds)

  class(x) <- append(class(x), "real_2d", after = 0)

  return(x)

}


#' @export
flag_bounds.integer_2d <- function(x = NULL, los_table = NULL) {

  x %<>%
    left_join(los_table %>% select(-site), by = "episode_id") %>%

    # Applied -1 for before, 0 for within, +1 fpr after. NA if end date is missing
    mutate(out_of_bounds = ifelse(difftime(datetime, epi_start_dttm, units = "days") < -2, -1L,
                                  ifelse(difftime(datetime, epi_end_dttm, units = "days") > 2, 1L,
                                         ifelse(is.na(epi_start_dttm) | is.na(epi_end_dttm), NA, 0L)))) %>%
    select(internal_id, out_of_bounds)

  class(x) <- append(class(x), "integer_2d", after = 0)

  return(x)

}


#' @export
flag_bounds.string_2d <- function(x = NULL, los_table = NULL) {

    x %<>%
      left_join(los_table %>% select(-site), by = "episode_id") %>%
      # Applied -1 for before, 0 for within, +1 fpr after. NA if end date is missing
      mutate(out_of_bounds = ifelse(difftime(datetime, epi_start_dttm, units = "days") < -2, -1L,
                                  ifelse(difftime(datetime, epi_end_dttm, units = "days") > 2, 1L,
                                         ifelse(is.na(epi_start_dttm) | is.na(epi_end_dttm), NA, 0L)))) %>%

    select(internal_id, out_of_bounds)

  class(x) <- append(class(x), "string_2d", after = 0)

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
flag_duplicate <- function(x) {
  UseMethod("flag_duplicate", x)
}


flag_duplicate.default <- function(...) {

  print("no default methods are defined for this class")

}


#' @export
flag_duplicate.real_2d <- function(x = NULL) {

  x %<>%
    ungroup() %>%
    distinct(episode_id, datetime, value, .keep_all = TRUE) %>%
    mutate(duplicate = 0L) %>%
    select(internal_id, duplicate) %>%
    right_join(x, by = "internal_id") %>%
    mutate_at(.vars = vars(duplicate),
              .funs = funs(ifelse(is.na(.), 1L, .))) %>%
    select(internal_id, duplicate)

  class(x) <- append(class(x), "real_2d", after = 0)

  return(x)

}


#' @export
flag_duplicate.real_1d <- function(x = NULL) {

  x %<>%
    ungroup() %>%
    distinct(episode_id, value, .keep_all = TRUE) %>%
    mutate(duplicate = 0L) %>%
    select(internal_id, duplicate) %>%
    right_join(x, by = "internal_id") %>%
    mutate_at(.vars = vars(duplicate),
              .funs = funs(ifelse(is.na(.), 1L, .))) %>%
    select(internal_id, duplicate)

  class(x) <- append(class(x), "real_1d", after = 0)

  return(x)

}


#' @export
flag_duplicate.integer_2d <- function(x = NULL) {

  x %<>%
    ungroup() %>%
    distinct(episode_id, datetime, value, .keep_all = TRUE) %>%
    mutate(duplicate = 0L) %>%
    select(internal_id, duplicate) %>%
    right_join(x, by = "internal_id") %>%
    mutate_at(.vars = vars(duplicate),
              .funs = funs(ifelse(is.na(.), 1L, .))) %>%
    select(internal_id, duplicate)

  class(x) <- append(class(x), "integer_2d", after = 0)

  return(x)

}


#' @export
flag_duplicate.integer_1d <- function(x = NULL) {

  x %<>%
    ungroup() %>%
    distinct(episode_id, value, .keep_all = TRUE) %>%
    mutate(duplicate = 0L) %>%
    select(internal_id, duplicate) %>%
    right_join(x, by = "internal_id") %>%
    mutate_at(.vars = vars(duplicate),
              .funs = funs(ifelse(is.na(.), 1L, .))) %>%
    select(internal_id, duplicate)

  class(x) <- append(class(x), "integer_1d", after = 0)

  return(x)

}


#' @export
flag_duplicate.string_2d <- function(x = NULL) {

  x %<>%
    ungroup() %>%
    distinct(episode_id, datetime, value, .keep_all = TRUE) %>%
    mutate(duplicate = 0L) %>%
    select(internal_id, duplicate) %>%
    right_join(x, by = "internal_id") %>%
    mutate_at(.vars = vars(duplicate),
              .funs = funs(ifelse(is.na(.), 1L, .))) %>%
    select(internal_id, duplicate)

  class(x) <- append(class(x), "string_2d", after = 0)

  return(x)

}


#' @export
flag_duplicate.string_1d <- function(x = NULL) {

  x %<>%
    ungroup() %>%
    distinct(episode_id, value, .keep_all = TRUE) %>%
    mutate(duplicate = 0L) %>%
    select(internal_id, duplicate) %>%
    right_join(x, by = "internal_id") %>%
    mutate_at(.vars = vars(duplicate),
              .funs = funs(ifelse(is.na(.), 1L, .))) %>%
    select(internal_id, duplicate)

  class(x) <- append(class(x), "string_1d", after = 0)

  return(x)

}


#' @export
flag_duplicate.datetime_1d <- function(x = NULL) {

  x %<>%
    ungroup() %>%
    distinct(episode_id, value, .keep_all = TRUE) %>%
    mutate(duplicate = 0L) %>%
    select(internal_id, duplicate) %>%
    right_join(x, by = "internal_id") %>%
    mutate_at(.vars = vars(duplicate),
              .funs = funs(ifelse(is.na(.), 1L, .))) %>%
    select(internal_id, duplicate)

  class(x) <- append(class(x), "datetime_1d", after = 0)

  return(x)

}


#' @export
flag_duplicate.date_1d <- function(x = NULL) {

  x %<>%
    ungroup() %>%
    distinct(episode_id, value, .keep_all = TRUE) %>%
    mutate(duplicate = 0L) %>%
    select(internal_id, duplicate) %>%
    right_join(x, by = "internal_id") %>%
    mutate_at(.vars = vars(duplicate),
              .funs = funs(ifelse(is.na(.), 1L, .))) %>%
    select(internal_id, duplicate)

  class(x) <- append(class(x), "date_1d", after = 0)

  return(x)

}


#' @export
flag_duplicate.time_1d <- function(x = NULL) {

  x %<>%
    ungroup() %>%
    distinct(episode_id, value, .keep_all = TRUE) %>%
    mutate(duplicate = 0L) %>%
    select(internal_id, duplicate) %>%
    right_join(x, by = "internal_id") %>%
    mutate_at(.vars = vars(duplicate),
              .funs = funs(ifelse(is.na(.), 1L, .))) %>%
    select(internal_id, duplicate)

  class(x) <- append(class(x), "time_1d", after = 0)

  return(x)

}

#' Flags for Periodicity of a Data Item (S3 Generic)
#'
#' Takes a data item tibble that has been pre-flagged with range, boundary and duplicate errors
#' and provides a column indicating the periodicity of that data item stratified by each episode
#' number. This is a similar concept to the coverage mapping, although is looking at patient
#' level rather than site level.
#'
#' These are only defined for 2d data
#'
#' @param x
#' @param ...
#'
#' @return
#' @export
#'
#' @examples
flag_periodicity <- function(x, los_table = NULL) {
  UseMethod("flag_periodicity", x)
}


flag_periodicity.default <- function(x) {

  print("There are no default methods for this class")

}


flag_periodicity_numeric <- function(x, los_table = NULL) {

  x %<>%

    # filter out values that cannot be taken into consideration for this calculation
    dplyr::filter(out_of_bounds == 0,
                  range_error == 0,
                  duplicate == 0) %>%

    # only need 1 value of interest to track periodicity (we'll choose datetime)
    dplyr::select(episode_id, datetime) %>%
    dplyr::group_by(episode_id) %>%

    # count the number of events occurring
    dplyr::summarise(count = n()) %>%
    dplyr::left_join(los_table %>%
                       dplyr::filter(validity == 0) %>%
                       dplyr::select(episode_id, los),
                     by = "episode_id") %>%
    dplyr::mutate(periodicity = count/as.numeric(los)) %>%
    dplyr::select(episode_id, periodicity) %>%
    dplyr::right_join(x, by = "episode_id")

  return(x)

}


flag_periodicity.real_2d <- function(x, los_table = NULL) {

  x <- flag_periodicity_numeric(x, los_table = los_table)

  class(x) <- append(class(x), "real_2d", after = 0)

  return(x)

}


flag_periodicity.integer_2d <- function(x, los_table = NULL) {

  x <- flag_periodicity_numeric(x, los_table = los_table)

  class(x) <- append(class(x), "integer_2d", after = 0)

  return(x)

}


flag_periodicity.string_2d <- function(x, los_table = NULL) {

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

  class(x) <- append(class(x), "string_2d", after = 0)

  return(x)

}
