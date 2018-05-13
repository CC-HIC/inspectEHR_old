#' Extract NHIC Events
#'
#' Extracts NHIC events and appends them with the correct class for
#' further processing. This is essentially the creator method for
#' the S3 classes associated with the inspectEHR package
#'
#' @param core_table core table
#' @param input the input variable of choice
#'
#' @importFrom rlang .data !!
#' @importFrom magrittr %>%
#'
#' @return A tibble with 1 row per event
extract <- function(core_table = NULL, input = "NIHR_HIC_ICU_0557") {

  # ensure the core table is provided
  if (is.null(core_table)) stop("You must include the core table")

  # Identify the correct column type to pull out
  dataitem <- qref %>%
    dplyr::filter(.data$code_name == input) %>%
    dplyr::select(.data$class) %>%
    dplyr::pull()

  # extract chosen input variable from the core table

  extracted_table <- dataitem %>%
    switch(integer_1d = extract_1d(core_table, input, data_location = "integer"),
           integer_2d = extract_2d(core_table, input, data_location = "integer"),
           real_1d = extract_1d(core_table, input, data_location = "real"),
           real_2d = extract_2d(core_table, input, data_location = "real"),
           string_1d = extract_1d(core_table, input, data_location = "string"),
           string_2d = extract_2d(core_table, input, data_location = "string"),
           datetime_1d = extract_1d(core_table, input, data_location = "datetime"),
           date_1d = extract_1d(core_table, input, data_location = "date"),
           time_1d = extract_1d(core_table, input, data_location = "time"))

  class(extracted_table) <- append(class(extracted_table), dataitem, after = 0)

  return(extracted_table)

}


#' Extract 1d Values
#'
#' This function extracts the correct column from the CC-HIC database
#' depending upon what type of data is called for
#'
#' @param core_table
#' @param input
#'
#' @return
#' @export
#'
#' @importFrom rlang .data !!
#' @importFrom magrittr %>%
#'
#' @examples
#' extract_1d(core, input = "NIHR_HIC_ICU_0409", data_location = "integer")
extract_1d <- function(core_table = NULL, input = NULL, data_location = NULL) {

  sym_code_name <- rlang::sym("code_name")
  quo_column <- enquo(data_location)

  extracted_table <- core_table %>%
    dplyr::filter(!! sym_code_name == input) %>%
    dplyr::collect() %>%
    dplyr::select(.data$event_id,
                  .data$site,
                  .data$code_name,
                  .data$episode_id,
                  !! quo_column) %>%
    dplyr::rename(value = !! quo_column,
                  internal_id = .data$event_id) %>%
    dplyr::arrange(episode_id)

  return(extracted_table)

}


#' Extract 2d Values
#'
#' This function extracts the correct column from the CC-HIC database
#' depending upon what type of data is called for. It additionally pulls
#' out the datetime column, which accompanies any data for this class
#'
#' @param core_table a core table
#' @param input the input variable of choice
#' @param data_location the column name that stores the primary data for this variable
#'
#' @return
#' @export
#'
#' @importFrom rlang .data !!
#' @importFrom magrittr %>%
#'
#' @examples
#' extract_2d(core, input = "NIHR_HIC_ICU_0108", data_location = "integer")
extract_2d <- function(core_table = NULL, input = NULL, data_location = NULL) {

  sym_code_name <- rlang::sym("code_name")
  quo_column <- rlang::enquo(data_location)

  extracted_table <- core_table %>%
    dplyr::filter(!! sym_code_name == input) %>%
    dplyr::collect() %>%
    dplyr::select(.data$event_id,
                  .data$site,
                  .data$code_name,
                  .data$episode_id,
                  .data$datetime,
                  !! quo_column) %>%
    dplyr::rename(value = !! quo_column,
                  internal_id = .data$event_id) %>%
    dplyr::arrange(.data$episode_id, .data$datetime)

  return(extracted_table)

}


#' Extract 1d Integers
#'
#'
#'
#' @param core_table
#' @param input
#'
#' @return
#' @export
#'
#' @importFrom rlang .data
#'
#' @examples
#' extract_integer_1d(core, input = "NIHR_HIC_ICU_0409")
extract_integer_1d <- function(core_table = NULL, input = NULL) {

  sym_code_name <- rlang::sym("code_name")

  extracted_table <- core_table %>%
    dplyr::filter(!! sym_code_name == input) %>%
    dplyr::collect() %>%
    dplyr::select(.data$event_id,
                  .data$site,
                  .data$code_name,
                  .data$episode_id,
                  .data$integer) %>%
    dplyr::rename(value = .data$integer,
                  internal_id = .data$event_id) %>%
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

  sym_code_name <- rlang::sym("code_name")

  extracted_table <- core_table %>%
    dplyr::filter(!! sym_code_name == input) %>%
    dplyr::collect() %>%
    dplyr::select(event_id, site, code_name, episode_id, datetime, integer) %>%
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
    dplyr::arrange(episode_id)

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
    dplyr::arrange(episode_id)

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
    dplyr::arrange(episode_id)

  return(extracted_table)

}
