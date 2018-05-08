#' Extract NHIC Events
#'
#' Extracts NHIC events and labels them with the correct class for future processing
#'
#' @param core_table core table
#' @param input the input variable of choice
#' @param qref the quality reference table
#'
#' @return A tibble 1 row per event
extract <- function(core_table = NULL,
                          qref = NULL,
                         input = "NIHR_HIC_ICU_0557") {

  # ensure the core table is provided
  if (is.null(core_table) | is.null(qref)) stop("You must include both the core table and quality reference")

  # Identify the correct column type to pull out
  dataitem <- qref %>%
    filter(code_name == input) %>%
    select(datatype) %>%
    pull %>%
    unique

  # extract chosen input variable from the core table

  extracted_table <- dataitem %>%
    switch(hic_int = extract_int(core_table, input),
           hic_dbl = extract_dbl(core_table, input),
           hic_str = extract_str(core_table, input),
           hic_dttm = extract_dttm(core_table, input),
           hic_date = extract_date(core_table, input),
           hic_time = extract_time(core_table, input))

  class(extracted_table) <- append(class(extracted_table), dataitem, after = 0)

  return(extracted_table)

}


extract_dbl <- function(core_table = NULL, input = NULL) {

  extracted_table <- core_table %>%
    dplyr::filter(code_name == input) %>%
    dplyr::select(event_id, site, code_name, episode_id, datetime, real) %>%
    dplyr::collect() %>%
    dplyr::rename(value = real,
                  internal_id = event_id) %>%
    dplyr::arrange(episode_id, datetime)

  return(extracted_table)

}


extract_int <- function(core_table = NULL, input = NULL) {

  extracted_table <- core_table %>%
    dplyr::filter(code_name == input) %>%
    dplyr::select(event_id, site, code_name, episode_id, datetime, integer) %>%
    dplyr::collect() %>%
    dplyr::rename(value = integer,
                  internal_id = event_id) %>%
    dplyr::arrange(episode_id, datetime)

  return(extracted_table)

}


extract_str <- function(core_table = NULL, input = NULL) {

  extracted_table <- core_table %>%
    dplyr::filter(code_name == input) %>%
    dplyr::select(event_id, site, code_name, episode_id, datetime, string) %>%
    dplyr::collect() %>%
    dplyr::rename(value = string,
                  internal_id = event_id) %>%
    dplyr::arrange(episode_id, datetime)

  return(extracted_table)

}

