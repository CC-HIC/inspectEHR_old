#' Extract NHIC Events
#'
#' Extracts NHIC events and labels them with the correct class for future processing
#'
#' @param core_table core table
#' @param input the input variable of choice
#'
#' @return A tibble 1 row per event
extract <- function(core_table = NULL, input = "NIHR_HIC_ICU_0557") {

  # ensure the core table is provided
  if (is.null(core_table) | is.null(qref)) stop("You must include both the core table and quality reference")

  # Identify the correct column type to pull out
  dataitem <- makeDict(metadata) %>%
    mutate(class = paste(primary_column, type, sep = "_")) %>%
    filter(code_name == input) %>%
    select(class) %>%
    pull

  # extract chosen input variable from the core table

  extracted_table <- dataitem %>%
    switch(integer_1d = extract_integer_1d(core_table, input),
           integer_2d = extract_integer_2d(core_table, input),
           real_1d = extract_real_1d(core_table, input),
           real_2d = extract_real_2d(core_table, input),
           string_1d = extract_string_1d(core_table, input),
           string_2d = extract_string_2d(core_table, input),
           datetime_1d = extract_datetime_1d(core_table, input),
           date_1d = extract_date_1d(core_table, input),
           time_1d = extract_time_1d(core_table, input))

  class(extracted_table) <- append(class(extracted_table), dataitem, after = 0)

  return(extracted_table)

}


#' Extract 1d Integers
#'
#' @param core_table
#' @param input
#'
#' @return
#' @export
#'
#' @examples
extract_integer_1d <- function(core_table = NULL, input = NULL) {

  extracted_table <- core_table %>%
    dplyr::filter(code_name == input) %>%
    dplyr::select(event_id, site, code_name, episode_id, integer) %>%
    dplyr::collect() %>%
    dplyr::rename(value = integer,
                  internal_id = event_id) %>%
    dplyr::arrange(episode_id)

  return(extracted_table)

}


#' Extract 2d Integers
#'
#' @param core_table
#' @param input
#'
#' @return
#' @export
#'
#' @examples
extract_integer_2d <- function(core_table = NULL, input = NULL) {

  extracted_table <- core_table %>%
    dplyr::filter(code_name == input) %>%
    dplyr::select(event_id, site, code_name, episode_id, datetime, integer) %>%
    dplyr::collect() %>%
    dplyr::rename(value = integer,
                  internal_id = event_id) %>%
    dplyr::arrange(episode_id, datetime)

  return(extracted_table)

}


#' Extract 1d Reals
#'
#' @param core_table
#' @param input
#'
#' @return
#' @export
#'
#' @examples
extract_real_1d <- function(core_table = NULL, input = NULL) {

  extracted_table <- core_table %>%
    dplyr::filter(code_name == input) %>%
    dplyr::select(event_id, site, code_name, episode_id, real) %>%
    dplyr::collect() %>%
    dplyr::rename(value = real,
                  internal_id = event_id) %>%
    dplyr::arrange(episode_id)

  return(extracted_table)

}


#' Extract 2d Reals
#'
#' @param core_table
#' @param input
#'
#' @return
#' @export
#'
#' @examples
extract_real_2d <- function(core_table = NULL, input = NULL) {

  extracted_table <- core_table %>%
    dplyr::filter(code_name == input) %>%
    dplyr::select(event_id, site, code_name, episode_id, datetime, real) %>%
    dplyr::collect() %>%
    dplyr::rename(value = real,
                  internal_id = event_id) %>%
    dplyr::arrange(episode_id, datetime)

  return(extracted_table)

}


#' Extract 1d String
#'
#' @param core_table
#' @param input
#'
#' @return
#' @export
#'
#' @examples
extract_string_1d <- function(core_table = NULL, input = NULL) {

  extracted_table <- core_table %>%
    dplyr::filter(code_name == input) %>%
    dplyr::select(event_id, site, code_name, episode_id, string) %>%
    dplyr::collect() %>%
    dplyr::rename(value = string,
                  internal_id = event_id) %>%
    dplyr::arrange(episode_id)

  return(extracted_table)

}

#' Extract 2d String
#'
#' @param core_table
#' @param input
#'
#' @return
#' @export
#'
#' @examples
extract_string_2d <- function(core_table = NULL, input = NULL) {

  extracted_table <- core_table %>%
    dplyr::filter(code_name == input) %>%
    dplyr::select(event_id, site, code_name, episode_id, datetime, string) %>%
    dplyr::collect() %>%
    dplyr::rename(value = string,
                  internal_id = event_id) %>%
    dplyr::arrange(episode_id, datetime)

  return(extracted_table)

}


#' Extract 1d DateTime
#'
#' @param core_table
#' @param input
#'
#' @return
#' @export
#'
#' @examples
extract_datetime_1d <- function(core_table = NULL, input = NULL) {

  extracted_table <- core_table %>%
    dplyr::filter(code_name == input) %>%
    dplyr::select(event_id, site, code_name, episode_id, datetime) %>%
    dplyr::collect() %>%
    dplyr::rename(value = datetime,
                  internal_id = event_id) %>%
    dplyr::arrange(episode_id, datetime)

  return(extracted_table)

}


#' Extract 1d Date
#'
#' @param core_table
#' @param input
#'
#' @return
#' @export
#'
#' @examples
extract_date_1d <- function(core_table = NULL, input = NULL) {

  extracted_table <- core_table %>%
    dplyr::filter(code_name == input) %>%
    dplyr::select(event_id, site, code_name, episode_id, date) %>%
    dplyr::collect() %>%
    dplyr::rename(value = date,
                  internal_id = event_id) %>%
    dplyr::arrange(episode_id, date)

  return(extracted_table)

}


#' Extract 1d Time
#'
#' @param core_table
#' @param input
#'
#' @return
#' @export
#'
#' @examples
extract_time_1d <- function(core_table = NULL, input = NULL) {

  extracted_table <- core_table %>%
    dplyr::filter(code_name == input) %>%
    dplyr::select(event_id, site, code_name, episode_id, time) %>%
    dplyr::collect() %>%
    dplyr::rename(value = time,
                  internal_id = event_id) %>%
    dplyr::arrange(episode_id, time)

  return(extracted_table)

}
