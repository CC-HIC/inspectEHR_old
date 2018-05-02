#' Provides a summary for "string" data type
#'
#' @param table_list a character vector for the uncollected tables of events, episodes and provenance (in that order)
#' @param string_input a character vector of the strings you want to extract
#'
#' @return
#' @export
#'
#' @examples
summarise_string <- function(table_list = NULL,
                             string_input = c("NIHR_HIC_ICU_0058",
                                              "NIHR_HIC_ICU_0098")) {

  stopifnot(!is.null(table_list))

  evnts <- table_list[1]
  episd <- table_list[2]
  provn <- table_list[3]

  # Creates the skeleton for the tibble we will ultimately merge into
  summarytbl <- tibble(site = as.character(),
                       string = as.character(),
                       count = as.integer(),
                       code_name = as.character(),
                       percent = as.double())

  core <- inner_join(get(episd), get(provn), by = c("provenance" = "file_id")) %>%
    select(episode_id, site)

  string <- get(evnts) %>% filter(code_name %in% string_input)

  working <- left_join(core, string, by = "episode_id") %>%
    select(episode_id, code_name, string, site) %>%
    collect()

  for (i in 1:length(string_input)) {

    string_summary <- working %>%
      filter(code_name == string_input[i]) %>%
      group_by(site) %>%
      count(string) %>%
      mutate(code_name = string_input[i],
             percent = n / sum(n)) %>%
      ungroup()

    summarytbl <- rbind(summarytbl, string_summary)

  }

  return(summarytbl)

}
