#' Provides a raw table for extracted integer values
#'
#' This function processes the core table to pull out a specific named variable of the real class
#' As a demo, this runs for CRP (0557) if not supplied with defaults.
#' Outliers are determined by number of SD. This is a gross estimation as many variables are
#' not normally distributed in HIC
#'
#' @param outliers integer value for the number of standard deviations used for outlier detection
#' @param core_table
#' @param input
#'
#' @return A tibble of time series data in summary
#' @examples
#' \dontrun{process_int(core)}
process_int <- function(core_table = NULL,
                        input = "NIHR_HIC_ICU_0108",
                        outliers = 3) {

  if (is.null(core_table)) stop("You must include the tables")

  processed_int <- core_table %>%
    filter(code_name == input) %>%
    select(site, code_name, episode_id, datetime, integer) %>%
    collect() %>%
    group_by(code_name, site) %>%
    mutate(sd = sd(integer),
           mean = mean(integer)) %>%
    ungroup() %>%
    mutate(outlier = ifelse(integer >= mean + 3*sd | integer <= mean - 3*sd, TRUE, FALSE)) %>%
    select(-sd, -mean)

  attr(processed_int, "code") <- input

  return(processed_int)

}


#' Find episodes that did not have a record for this real
#'
#' Provides a tibble of the exact same form as process dbl, but with NAs where values are
#' not found. This is useful in understanding how many cases do not report on a certain field
#'
#' @param episode_table
#' @param processed_table
#' @param input
#'
#' @return
#' @export
#'
#' @examples
find_na_int <- function(processed_table = NULL,
                        keychain = NULL,
                        provenance_table = NULL) {

  havedata <- processed_table[["episode_id"]] %>%
    unique()

  nodata <- keychain %>%
    left_join(provenance_table, by = c("provenance" = "file_id")) %>%
    select(site, episode_id) %>%
    filter(!(episode_id %in% havedata)) %>%
    mutate(code_name = attr(processed_table, "code"),
           datetime = as.POSIXct(NA),
           integer = as.integer(NA),
           outlier = as.logical(NA))

  return(nodata)

}


#' Binds processed output table and NA table
#'
#' @param processed_table
#' @param na_table
#'
#' @return
#' @export
#'
#' @examples
bind_na_int <- function(processed_table = NULL,
                        na_table = NULL) {

  total_int <- rbind(processed_table, na_table)

  return(total_int)

}


#' Provides a summary for time-series data of "real"/"double" data type
#'
#' @param real_input character vector of NIHR codes for the reals that you wish to report
#' @param outliers integer value for the number of standard deviations used for outlier identification
#' @param inUnits character for duration based units to retunr
#' @param core_table
#' @param los_table
#'
#' @return A tibble of time series data in summary
#' @examples
#' \dontrun{summarise_dbl(c("events", "episodes", "provenance"), los, "NIHR_HIC_ICU_0108")}
summarise_int <- function(processed_table = NULL,
                          los_table = NULL,
                          inUnits = "hours") {

  if (is.null(processed_table)) stop("You must place a processed_table here")

  current <- processed_table %>%
    right_join(los_table, by = "episode_id") %>%
    group_by(site, episode_id) %>%
    summarise(first = min(datetime),
              last = max(datetime),
              min = min(integer),
              max = max(integer),
              count = sum(!is.na(integer))) %>%
    full_join(los_table, by = "episode_id") %>%
    mutate(lead = round(difftime(first, epi_start_dttm, units = inUnits), 2),
           lag = round(difftime(epi_end_dttm, last, units = inUnits), 2),
           freq = count / as.numeric(los)) %>%
    select(site, episode_id, min, max, count, lead, lag, freq)

  return(current)

}


#' Reports Double
#'
#' @param core_table
#' @param los_table
#' @param input
#' @param outliers
#'
#' @return
#' @export
#'
#' @examples
report_int <- function(core_table = NULL,
                       los_table = NULL,
                       keychain = NULL,
                       provenance_table = NULL,
                       input = "NIHR_HIC_ICU_0108",
                       outliers = 3) {

  # process > find_na > bind > (summarise)

  # Process
  report <- core_table %>%
    process_int(input = input, outliers = outliers)

  # Find NA
  intermediate <- find_na_int(processed_table = report,
                              keychain = keychain,
                              provenance_table = provenance_table)

  # Bind
  total <- bind_na_int(processed_table = report, na_table = intermediate)

  # Summarise
  report <- summarise_int(processed_table = total, los_table = los_table)

  return(report)

}



plot_int <- function(df, variable, type = "summary", outliers = FALSE) {

  df <- df %>% filter(outlier == outliers)

  if (type == "raw") {

    ggplot(data = df, aes(x = variable, fill = site)) +
      geom_density(alpha = 0.5)

  }

}
