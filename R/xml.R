
#' XML Parsing Errors
#'
#' Interrogates and summarises XML parsing errors
#'
#' @param importstats uncollected importstats postGres table
#'
#' @return a tibble containing summary of XML errors
#' @export
#'
#' @examples
#' xml_stats(tbls[["importstats"]])
xml_stats <- function(importstats) {

  collect(importstats) %>%
  left_join(provenance %>%
              select(file_id, site), by = c("provenance_id" = "file_id")) %>%
  group_by(site) %>%
  summarise(episodes_read = sum(episodes_read),
     episodes_missing_key = sum(episodes_missing_key),
           events_dropped = sum(events_dropped))

}


#' Show Non Parsed XML
#'
#' Returns a character vector of file names for XML that would not be parsed
#'
#' @param provenance provenance table - containing details of what was parsed
#'
#' @return a character vector of filenames
#' @export
#'
#' @examples
#' non_pased_files(provenance)
non_parsed_files <- function(provenance = NULL) {

  position_slash <- dir(path = "S:/NIHR_HIC/current_xml/", recursive = TRUE) %>%
    str_locate("/")

  position_slash <- position_slash[,"start"]

  xml_files <- dir(path = "S:/NIHR_HIC/current_xml/", recursive = TRUE) %>%
    str_sub(start = position_slash)

  xml_files <- paste0("/data", xml_files)

  xml_files <- str_replace(xml_files, " ", "_")

  return(xml_files[!(xml_files %in% (provenance %>% select(filename) %>% pull))])

}


#' Empty XML Files
#'
#' Details XML that has successfully parsed, but contains no episode level data
#'
#' @param episodes collected episodes postgres table
#' @param provenance collected provenance postgres table
#'
#' @return a tibble containing the site and filename of XML with no episodes
#' @export
#'
#' @examples
#' empty_files(episodes, provenance)
empty_files <- function(episodes, provenance) {

  full_join(episodes, provenance, by = c("provenance" = "file_id")) %>%
  filter(is.na(episode_id)) %>%
  select(site, filename)

}


#' Summarise Event Level Errors
#'
#' returns a summary table grouped by site with a breakdown of the errors seen.
#' This is for overview purposes, so scope out the magnitude of problems and help
#' direct xml fixes
#'
#' @param errors error table
#' @param provenance provenance table
#'
#' @return a tibble with summary details of errors
#' @export
#'
#' @examples
#' error_summary(errors, provenance)
error_summary <- function(errors = NULL, provenance = NULL) {

  errors %>%
    left_join(provenance %>% select(file_id, site), by = c("provenance_id" = "file_id")) %>%
    mutate(message_type = if_else(grepl("clock change", message), "Clock Change",
                          if_else(grepl("nhs number", message), "Missing NHS / Start",
                          if_else(grepl("empty tags|Empty tags", message), "Empty Tags",
                          if_else(grepl("primary value", message), "Primary Value",
                          if_else(grepl("Rejected patient", message), "Rejected",
                          if_else(grepl("integer value is out of range", message), "Int OOR",
                          if_else(grepl("Got float, expected int", message), "Got float, Expected Int",
                          if_else(grepl("not a valid value of the atomic type \'xs:integer\'", message), "Got float, Expected Int",
                          if_else(grepl("could not convert string to float", message), "Got string, Expected float",
                          if_else(grepl("is not an element of the set", message), "Category OOR",
                            "Other"
                          ))))))))))) %>%
    group_by(site, message_type) %>%
    summarise(count = n())

}





