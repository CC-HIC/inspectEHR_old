#' Make HIC Report Data
#'
#' This is the main function for processing data from CC-HIC. It wraps all alther functions to evaluate
#' the whole database in one sweep.
#'
#' When running this function, path_name should be made availible with the following folders:
#' plots
#' working_data
#'
#' report.rmd can be run after this function has successfully completed to produce a full report for CC-HIC
#'
#' @param database
#' @param username
#' @param path_name
#'
#' @importFrom dplyr select arrange pull
#'
#' @return
#' @export
#'
#' @examples
make_report <- function(database = "lenient_dev",
                        username = "edward",
                        password = "superdb",
                       path_name = NULL,
                        useDeath = TRUE) {


  # Folder set up
  if(!dir.exists(paste0(path_name, "plots"))) dir.create(paste0(path_name, "plots"))
  if(!dir.exists(paste0(path_name, "working_data"))) dir.create(paste0(path_name, "working_data"))
  if(!dir.exists(paste0(path_name, "validation_data"))) dir.create(paste0(path_name, "validation_data"))

  cat("Starting Set-Up")

  pb <- txtProgressBar(min = 0, max = 10, style = 3)

  setTxtProgressBar(pb, 1)

  hic_codes <- qref %>%
    dplyr::select(code_name) %>%
    dplyr::arrange(code_name) %>%
    dplyr::pull()

  # Prepare Connections
  ctn <- connect(database = database, username = username, password = password)
  tbls <- retrieve(ctn)
  tbl_list <- dplyr::db_list_tables(ctn)

  # Collect small tables
  episodes <- collect(tbls[["episodes"]])
  provenance <- collect(tbls[["provenance"]])
  metadata <- collect(tbls[["variables"]])
  # errors <- collect(tbls[["errors"]])

  setTxtProgressBar(pb, 2)

  # XML level errors
  # xml_stats <- xml_stats(importstats = tbls[["importstats"]])
  # empty_files <- empty_files(episodes, provenance)
  # non_parsed <- non_parsed_files(provenance)
  # error_summary <- error_summary(errors, provenance)

  setTxtProgressBar(pb, 3)

  # error_grid <- error_summary %>%
  #   ggplot(aes(x = site, y = message_type, fill = count)) +
  #   geom_tile() +
  #   geom_text(aes(label = count), colour = "white") +
  #   theme_minimal()
  #
  # ggsave(error_grid, filename = paste0(path_name, "plots/error_grid.png"))
  # rm(error_grid)

  ## Missing fields
  # we want to identify fields that are entirely uncontributed by site

  unique_events <- tbls[["events"]] %>%
    dplyr::left_join(tbls[["episodes"]], by = "episode_id") %>%
    dplyr::left_join(tbls[["provenance"]], by = c("provenance" = "file_id")) %>%
    dplyr::select(site, code_name) %>%
    dplyr::distinct() %>%
    dplyr::collect()

  setTxtProgressBar(pb, 4)

  unique_events_plot <- unique_events %>%
    ggplot(aes(x = site, y = code_name)) +
    geom_tile(fill = "blue") +
    theme_minimal() +
    scale_y_discrete(labels = hic_codes)

  ggsave(filename = paste0(
    path_name,
    "plots/",
    "missing_events.png"),
    plot = unique_events_plot,
    height = 40)

  missing_events <- base::setdiff(hic_codes, unique_events %>%
                                    select(code_name) %>%
                                    pull() %>%
                                    unique())

  setTxtProgressBar(pb, 5)

  # Reference Table
  # Left join is used here because we don't want to drag around NAs from empty files
  reference <- make_reference(episodes, provenance)

  all_sites <- reference %>% select(site) %>% distinct %>% pull

  ## Capture colour profile for consistency

  all_sites.col <- c("#66C2A5", "#FC8D62", "#8DA0CB", "#E78AC3", "#A6D854")
  names(all_sites.col)  <- all_sites

  # Core Table ----
  core <- make_core(tbls[["events"]], tbls[["episodes"]], tbls[["provenance"]])

  # Cases ----
  # Gives a tibble of admission numbers (patients/episodes) by week
  admitted_cases_all <- retrieve_unique_cases(episodes, provenance) %>%
    report_cases_all()

  setTxtProgressBar(pb, 6)

  # Gives overall admission numbers (totals) for patients/episodes
  admitted_cases_unit <- report_cases_unit(events_table = tbls[["events"]], reference_table = reference)

  setTxtProgressBar(pb, 7)

  for (i in seq_along(all_sites)) {
    plot_heatcal(episodes, provenance, site = all_sites[i])
    ggsave(filename = paste0(
      path_name,
      "plots/",
      all_sites[i],
      "_admissions.png"),
      dpi = 300, width = 10, height = 7, units = "in")
  }

  setTxtProgressBar(pb, 8)

  # Length of Stay "Episode Length" ----

  ## This calculates the episode length for an admission
  ## This is calculated by using the discharge unit time, which is not completed universally
  ## So date and time of death is used where possible to supplement
  ## This is a complete table with a validation column, so don't use without
  ## filtering out invalid records

  # Epsiode_length
  episode_length <- epi_length(core, useDeath = useDeath)

  # Seplls
  spells <- identify_spells(episode_length = episode_length, episodes = episodes) %>%
    group_by(site) %>%
    summarise(patients = n_distinct(nhs_number),
              episodes = n_distinct(episode_id),
                spells = n_distinct(spell_id))

  setTxtProgressBar(pb, 9)

  # Episode validity long term average
  # typical_admissions gives me the mean and sd for the long running admissions by wday

  invalid_months <- invalid_months(episodes, provenance, all_sites = all_sites)

  validated_episodes <- validate_episode(episode_length_tbl = episode_length, invalidated_months = invalid_months)

  save(validated_episodes, file = paste0(path_name, "validation_data/validated_episodes.RData"))

  setTxtProgressBar(pb, 10)

  # provides an occupancy table but with missing data filled
  # Takes a really long time
  # occupancy <- calc_site_occupancy(episode_length_tbl = episode_length)

  close(pb)

  cat("Finished Set-Up")

  ###############
  # Events =====
  ###############

  # Set up events
  hic_event_summary <- vector(mode = "list", length = length(hic_codes))
  names(hic_event_summary) <- hic_codes

  hic_event_validation <- vector(mode = "list", length = length(hic_codes))
  names(hic_event_validation) <- hic_codes

  # create progress bar
  cat("Starting Event Level Evaluation")

  pb <- txtProgressBar(min = 0, max = length(hic_codes), style = 3)

  for (i in seq_along(hic_codes)) {

    # the basics
    temp_df <- extract(core, input = hic_codes[i]) %>%
      flag_all(episode_length)

    # Plotting
    try(plot_hic(temp_df, path_name, all_sites.col))

    print(paste0("finished plotting: ", hic_codes[i]))

    #Saving errors outside the main list
    try(hic_event_summary[[hic_codes[i]]] <- summary_main(temp_df, reference))

    try(hic_event_validation[[hic_codes[i]]] <- validate_event(validated_episodes, temp_df))

    print(paste0("finished validating: ", hic_codes[i]))

    rm(temp_df)

    print(paste0("totally finished: ", hic_codes[i]))

    setTxtProgressBar(pb, i)

  }

  close(pb)

  print("Finished Event Level Evaluation")

  save(hic_event_summary, file = paste0(path_name, "working_data/hic_event_summary.RData"))
  save(hic_event_validation, file = paste0(path_name, "working_data/hic_event_validation.RData"))


}

