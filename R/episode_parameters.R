#' Retrieve all unique cases
#'
#' Pulls unique record numbers from the CC-HIC database. This requires only that an "episode" has
#' been correctly parsed from the xml and added to the database and so doesn't rely on, or infer that
#' there is any, event level data. This is the most accurate measure of the actual number of "patients"
#' in the system.
#'
#' @param episodes
#' @param provenance
#'
#' @return a tibble with fields for site, nhs_number, episode_id and start
#' @export
#'
#' @examples
retrieve_unique_cases <- function(episodes = NULL, provenance = NULL) {

  stopifnot(!is.null(episodes), !is.null(provenance))

  # Note - there ARE protentially cases in the provennace table that DO NOT
  # feaure in the episodes table. i.e. a file that was parsed, but contained no
  # interpretable "episodes"

  cases <- episodes %>%

    # left join due to the reasons above
    left_join(provenance, by = c("provenance" = "file_id")) %>%
    select(site, nhs_number, episode_id, start_date) %>%
    distinct()

  return(cases)

}


#' Reports Case Numbers by Site
#'
#' @param unique_cases_tbl from \code{pull_cases_all}
#'
#' @return
#' @export
#'
#' @examples
report_cases_all <- function(unique_cases_tbl = NULL) {

  cases <- unique_cases_tbl %>%
    mutate(year = year(start_date),
           month = month(start_date, label = TRUE),
           week_of_month = as.integer(ceiling(day(start_date)/7)),
           wday = wday(start_date, label = TRUE)) %>%
    group_by(site, year, month, week_of_month) %>%
    summarise(patients = n_distinct(nhs_number),
              episodes = n_distinct(episode_id))

  return(cases)

}


#' Reports Case Numbers according to day
#'
#' @param unique_cases_tbl from \code{pull_cases_all}
#'
#' @return
#' @export
#'
#' @examples
report_cases_daily <- function(unique_cases_tbl = NULL) {

  cases <- unique_cases_tbl %>%
    mutate(year = year(start_date),
           month = month(start_date, label = TRUE),
           week_of_month = as.integer(ceiling(day(start_date)/7)),
           wday = wday(start_date, label = TRUE)) %>%
    group_by(site, year, month, week_of_month, wday) %>%
    summarise(patients = n_distinct(nhs_number),
              episodes = n_distinct(episode_id))

  return(cases)

}


#' Reports Case Numbers by Site and Day
#'
#' @param unique_cases_tbl from \code{pull_cases_all}
#' @param site
#'
#' @return
#' @export
#'
#' @examples
report_cases_byday <- function(unique_cases_tbl = NULL, bysite = NULL) {

  cases <- unique_cases_tbl %>%
    filter(site == bysite) %>%
    mutate(date = lubridate::date(start_date)) %>%
    group_by(date) %>%
    summarise(episodes = n_distinct(episode_id)) %>%
    filter(episodes > 0)

  return(cases)

}



#' Reports Case Numbers by Unit
#'
#' Reports on ICNARC CMP unit codes to describe the numbers of reported cases by site.
#' This is dependent on accurate parsing of the xml schema for hic code 0002 (INCARC CMP
#' unit code). And as such, may dramatically under-report. To see a comprehensive list
#' of acual cases, see the \code{pull_unique_cases()} function.
#'
#' @param events_table the events table
#' @param reference_table the reference table
#'
#' @return
#' @export
#'
#' @examples
report_cases_unit <- function(events_table = NULL, reference_table = NULL){

  events_table %>%
    dplyr::filter(code_name == "NIHR_HIC_ICU_0002") %>%
    dplyr::select(episode_id, string) %>%
    collect() %>%
    dplyr::right_join(reference_table, by = "episode_id") %>%
    dplyr::select(episode_id, nhs_number, string, site) %>%
    dplyr::group_by(site, string) %>%
    dplyr::summarise(patients = n_distinct(nhs_number),
                     episodes = n_distinct(episode_id)) %>%
    dplyr::rename(unit = string) -> unit_numbers

  return(unit_numbers)

}


#' Calculate Episode Length
#'
#' Calculates length of stay from:
#' \itemize{
#'   \item episode start date time: NHIC 0411
#'   \item episode end date timeL NHIC 0412
#'   \item date of in unit death: NHIC 0042
#'   \item time of in unit death: NHIC 0043
#' }
#' For cases where there is a discharge date, time and death date and time, we use the
#' mortality data if this occurs earlier than the discharge data.
#'
#' @param core core table from \code{make_core()}
#'
#' @return
#' @export
#'
#' @examples
#' epi_length(core, reference)
epi_length <- function(core = NULL) {

  alive <- epi_end_alive(core = core)

  deceased <- resolve_date_time(core = core, "NIHR_HIC_ICU_0042", "NIHR_HIC_ICU_0043")()

  alive %>%
    left_join(deceased, by = "episode_id", suffix = c(".A", ".D")) %>%
    mutate(final_end = if_else(is.na(epi_end_dttm.A) |
                                 ((epi_end_dttm.D < epi_end_dttm.A) & !is.na(epi_end_dttm.D)),
                             epi_end_dttm.D, epi_end_dttm.A)) %>%
    select(episode_id, site, epi_start_dttm, final_end) %>%
    rename(epi_end_dttm = final_end) %>%
    dplyr::mutate(los = difftime(epi_end_dttm, epi_start_dttm, units = "days")) %>%
    dplyr::mutate(validity = ifelse(is.na(epi_end_dttm), 1L,
                               ifelse(los <= 0, 2L, 0L)))

}


#' Indentify Spells
#'
#' some sites have patients check out of one ICU and into another (for example ICU stepdown to HDU).
#' This checks to see if patients are discharged from 1 unit and admitted to another wihtin a pre-defined
#' time period, specified in the minutes argument.
#'
#' This only evaluates episodes that have already been flagged as valid by the episode_length function.
#'
#' @param episode_length episode length tibble
#' @param episodes episodes tibble
#' @param minutes numeric value to define transition period
#'
#' @return
#' @export
#'
#' @examples
#' identify_spells(episode_length, episodes)
identify_spells <- function(episode_length = NULL, episodes = NULL, minutes = 60) {

  episode_length %>%
    filter(validity == 0) %>%
    left_join(episodes %>%
                select(episode_id, nhs_number),
              by = "episode_id") %>%
    arrange(nhs_number, epi_start_dttm) %>%
    group_by(nhs_number) %>%
    mutate(time_out = epi_start_dttm[-1] %>%
             difftime(epi_end_dttm[-length(epi_end_dttm)], units = "mins") %>%
             as.integer() %>%
             c(NA)) %>%
    mutate(new_spell = if_else(lag(time_out) > minutes | is.na(lag(time_out)), TRUE, FALSE)) %>%
    ungroup() %>%
    mutate(spell_id = cumsum(new_spell)) %>%
    select(spell_id, episode_id, nhs_number, site, epi_start_dttm, epi_end_dttm, los, validity)

}


#' Collect Unit Discharge Status
#'
#' pulls the discharge status
#'
#' @param event_table
#'
#' @return
#' @export
#'
#' @examples
unit_discharge_status <- function(event_table) {

  event_table %>%
    filter(code_name == "NIHR_HIC_ICU_0097") %>%
    select(string, episode_id) %>%
    collect()

}


#' Collect Episode End Datetime
#'
#' Collects episodes end datetime for further processing
#'
#' @param core_table core table from \code{make_core()}
#'
#' @return a tibble with mandatory episode defining characteristics.

#' @export
#'
#' @examples
#' epi_end_alive(core)
epi_end_alive <- function(core_table = NULL) {

    core_table %>%
      dplyr::select(episode_id, site, code_name, datetime) %>%
      dplyr::filter(code_name %in% c("NIHR_HIC_ICU_0411", "NIHR_HIC_ICU_0412")) %>%
      dplyr::collect() %>%
      tidyr::spread(key = code_name, value = datetime) %>%
      dplyr::rename(epi_start_dttm = NIHR_HIC_ICU_0411,
                    epi_end_dttm = NIHR_HIC_ICU_0412) %>%
      dplyr::mutate_if(.predicate = is.POSIXct,
                       .funs = funs(lubridate::ymd_hms(., tz = "Europe/London")))

}


#' Calculate Date and time of events
#'
#' Many events in CC-HIC are stored in separate date and time columns. What is more,
#' this information is not always stored with consistent rules. For example,
#' death date and time, are stored for every patient in every episode, even though
#' the patient can obviously only die once. This has most likely been born out of
#' the ease of writing an xml extract to encompass this information. The following
#' are some date and time pairings that denote a singular event:
#' \itemize{
#'   \item "NIHR_HIC_ICU_0042", "NIHR_HIC_ICU_0043" - Unit Death
#'   \item "NIHR_HIC_ICU_0038", "NIHR_HIC_ICU_0039" - Body Removal
#'   \item "NIHR_HIC_ICU_0044", "NIHR_HIC_ICU_0045" - Brain stem death
#'   \item "NIHR_HIC_ICU_0048", "NIHR_HIC_ICU_0049" - Treatment Withdrawal
#'   \item "NIHR_HIC_ICU_0050", "NIHR_HIC_ICU_0051" - Discharge ready
#' }
#' This closure returns a function for the particular date time pairing that you
#' are interested in so that it can be incorporated into a mapping function
#'
#' Since we are only interested in datetimes, any occurances where a date or a time
#' occur in isolation are dropped - This is largely because one piece of information
#' wihtout the other is not useful to us.
#'
#' @param core core table from \code{make_core()}
#'
#' @return a function to encapsulate paired date and time variables stored separately
#' @export
#'
#' @examples
#' resolve_death <- resolve_date_time(core, "NIHR_HIC_ICU_0042", "NIHR_HIC_ICU_0043")
#' dt <- resolve_death()
resolve_date_time <- function(core, date_code, time_code) {

  function(...) {

    core %>%
      dplyr::select(episode_id, code_name, date, time) %>%
      dplyr::filter(code_name %in% c(date_code, time_code)) %>%
      collect() %>%
      align_dttm("time", "date", "episode_id") %>%
      dplyr::mutate(epi_end_dttm = lubridate::ymd_hms(paste0(date, time, sep = " "), tz = "Europe/London")) %>%
      dplyr::select(episode_id, epi_end_dttm)

  }

}



#' Validate episodes
#'
#' #' validity is coded as:
#' \itemize{
#'   \0 - Validated
#'   \1 - Invalid: no end date to episode length
#'   \2 - Invalid: negative length of stay
#'   \3 = Invalid: length of stay under 6 hours
#' }
#'
#' @param x
#'
#' @return
#' @export
#'
#' @examples
episode_validity <- function(x) {

  x %<>%
    group_by(site, validity) %>%
    summarise(episodes = n()) %>%
    spread(key = validity, value = episodes)

}


#' Show Invalid Months
#'
#' Determines which months are invalid based on a low contribution of data
#' This is based upon the long term daily average for admissions. Days that
#' fall below 2 SD of the long term mean are tagged. If more than the
#' threshold value occur in a single month, the month is removed from
#' further analysis
#'
#' @param episodes collected episodes table
#' @param provenance collected provenance table
#' @param threshold threshold number of days to use in calculation
#'
#' @return a tibble of months that are to be excluded from future analysis
#' @export
#'
#' @examples
#' invalid_months(episodes, provenance)
#' invalid_months(episodes, provenance, theshold = 15)
invalid_months <- function(episodes, provenance, threshold = 10) {

  x <- retrieve_unique_cases(episodes, provenance)

  x %>%
    mutate(date = lubridate::date(start_date)) %>%
    group_by(site, date) %>%
    summarise(episode_count = n_distinct(episode_id)) %>%
    mutate(year = year(date),
           month = month(date, label = TRUE),
           wday = wday(date, label = TRUE)) %>%
    group_by(site, year, wday) %>%
    summarise(mean_episodes = mean(episode_count),
              sd_episode = sd(episode_count)) -> typical_admissions

  # too_few tells me the days when admissions fell under the expected

  x %>%
    mutate(date = lubridate::date(start_date)) %>%
    group_by(site, date) %>%
    summarise(episodes = n()) %>%
    mutate(year = year(date),
           wday = wday(date, label = TRUE)) %>%
    left_join(typical_admissions, by = c("site" = "site",
                                         "year" = "year",
                                         "wday" = "wday")) %>%
    mutate(too_few = ifelse(episodes < (mean_episodes - 2*sd_episode), TRUE, FALSE)) %>%
    filter(too_few == TRUE) %>%
    select(site, date) -> too_few

  # what we don't capture properly is days when there is no data - i.e. NAs
  # this is what we will fix here

  x %>%
    mutate(date = lubridate::date(start_date)) %>%
    select(site, date) %>%
    distinct(.keep_all = TRUE) %>%
    mutate(admission = TRUE) -> na_days

  # This is fragile and needs to be fixed as we get data into 2018

  ds <- tibble(date = rep(seq.Date(from = lubridate::date("2014-01-01"),
                                   to = lubridate::date("2018-01-01"), by = "day"),
                          times = length(all_sites)))

  ds %<>%
    mutate(site = rep(all_sites, each = nrow(ds)/length(all_sites)))

  na_days %>%
    right_join(ds,
               by = c("date" = "date",
                      "site" = "site")) %>%
    filter(is.na(admission)) %>%
    select(-admission) %>%
    bind_rows(too_few) -> too_few_all

  ## Too few all now contains all the months where we will be excluding episodes

  too_few_all %>%
    mutate(
      year = as.integer(year(date)),
      month = month(date)) %>%
    group_by(site, year, month) %>%
    summarise(count = n()) %>%
    filter(count >= threshold) -> invalid_months

  return(invalid_months)

}


#' Calculate Estimated Site Occupancy
#'
#' @param episode_length_tbl episode length table
#' @param episodes_tbl episodes table
#' @param provenance_tbl provenance table
#'
#' @return a table of similar structure to date_skelaton, but with estimated occupancies attached
#' @export
#'
#' @examples
calc_site_occupancy <- function(episode_length_tbl = NULL, impute = TRUE) {

  all_sites = c("Oxford", "RYJ", "GSTT", "UCL", "RGT")

  date_skelaton <- make_date_skelaton()

  occupancy_vec <- c()

  for (i in 1:nrow(date_skelaton)) {

    insert_this <- episode_length_tbl %>%
      dplyr::filter(site == date_skelaton$site[i],
                    date_skelaton$date[i] >= epi_start_dttm & date_skelaton$date[i] <= epi_end_dttm) %>%
      nrow()

    occupancy_vec <- c(occupancy_vec, insert_this)

  }

  date_skelaton$est_occupancy <- occupancy_vec

  occupancy <- date_skelaton

  if (!impute) {
    return(occupancy)
  } else {
    occupancy$est_occupancy <- ifelse(occupancy$est_occupancy == 0 & occupancy$site == "RGT", 38,
                             ifelse(occupancy$est_occupancy == 0 & occupancy$site == "UCL", 24,
                             ifelse(occupancy$est_occupancy == 0 & occupancy$site == "Oxford", 11,
                             ifelse(occupancy$est_occupancy == 0 & occupancy$site == "RYJ", 23,
                             occupancy$est_occupancy))))

    return(occupancy)

  }


}


