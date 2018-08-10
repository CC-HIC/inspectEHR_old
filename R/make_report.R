#' Make HIC Report Data
#'
#' This is the main function for processing data from CC-HIC. It wraps all
#' other functions to evaluate the whole database in one sweep.
#' This can take some time!
#'
#' Specify the output folder in "path_name" when running this function,
#' path_name should be made availible with the following folders:
#' plots
#' working_data
#'
#' report.rmd can be run after this function has successfully completed to
#' produce a full report for CC-HIC
#'
#' When calculating spells. This will automatiically check against your
#' contraint +/- 60 mins so you can see how sensitive your calcuation is.
#'
#' @param database
#'
#' @param username
#' @param path_name
#' @param spell_boundary_mins the time gap you are willing to allow for the
#' definition of spells
#'
#' @importFrom dplyr select arrange pull left_join distinct collect tibble
#' anti_join mutate
#' @importFrom ggplot2 ggplot aes geom_tile theme element_blank element_rect
#' ylab ggtitle ggsave
#' @importFrom DBI dbWriteTable
#'
#' @return
#' @export
#'
#' @examples
make_report <- function(database = "lenient_dev",
                        username = "edward",
                        password = "superdb",
                        host = "localhost",
                        system = "postgres",
                        file = NULL,
                       path_name = NULL,
                spell_boundary_mins = 60) {

  # Folder set up ====
  if (str_sub(path_name, -1) != "/") {
    path_name <- paste0(path_name, "/")
  }

  if (!dir.exists(path_name)) {
    dir.create(path_name)
    cat("path:", paste(path_name), "does not exist. Creating directory")
  }

  if(!dir.exists(paste0(path_name,"plots"))) {
    dir.create(paste0(path_name, "plots")) }
  if(!dir.exists(paste0(path_name, "working_data"))) {
    dir.create(paste0(path_name, "working_data")) }
  if(!dir.exists(paste0(path_name, "validation_data"))) {
    dir.create(paste0(path_name, "validation_data"))}

  cat("Starting Set-Up")

  pb <- txtProgressBar(min = 0, max = 10, style = 3)

  setTxtProgressBar(pb, 1)

  hic_codes <- qref %>%
    dplyr::select(code_name) %>%
    dplyr::arrange(code_name) %>%
    dplyr::pull()

  # Prepare Connections
  ctn <- connect(database = database,
                 username = username,
                 password = password,
                 system = system,
                 host = host, file = file)
  tbls <- retrieve_tables(ctn)
  #tbl_list <- dplyr::db_list_tables(ctn)

  setTxtProgressBar(pb, 2)

  # Collect small tables
  episodes <- collect(tbls[["episodes"]])
  provenance <- collect(tbls[["provenance"]])
  metadata <- collect(tbls[["variables"]])
  # errors <- collect(tbls[["errors"]])

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
  # we want to identify fields that are not contributed by a site
  # so we must retrive the unique events that each site contributes first
  unique_events <- tbls[["events"]] %>%
    dplyr::left_join(tbls[["episodes"]], by = "episode_id") %>%
    dplyr::left_join(tbls[["provenance"]], by = c("provenance" = "file_id")) %>%
    dplyr::select(site, code_name) %>%
    dplyr::distinct() %>%
    dplyr::collect()

  setTxtProgressBar(pb, 4)

  # Capture all the sites currently contributing to the project
  all_sites <- provenance %>%
    dplyr::select(site) %>%
    dplyr::distinct() %>%
    dplyr::pull()

  # Make a new data frame with codes replicated for each site
  all_events <- dplyr::tibble(site = rep(all_sites, each = nrow(qref)),
                       code_name = rep(hic_codes, length(all_sites)))

  # use anti_join to find which sites aren't providing certain codes
  missing_events <- dplyr::anti_join(
    all_events, unique_events,
    by = c("site" = "site",
           "code_name" = "code_name")) %>%
    dplyr::left_join(qref %>%
                dplyr::select(code_name, short_name),
              by = c("code_name" = "code_name")) %>%
    dplyr::mutate(new_name = paste0(
      str_sub(
        code_name, -4, -1), ": ", short_name))

  # make a plot highlighting missing data
  missing_events_plot <- missing_events %>%
    ggplot2::ggplot(
      ggplot2::aes(x = site, y = new_name)) +
    ggplot2::geom_tile(fill = "red", colour = "black") +
    ggplot2::theme(panel.grid.major.x = ggplot2::element_blank(),
          panel.grid.minor.x = ggplot2::element_blank(),
          panel.background = ggplot2::element_rect(fill = NA)) +
    ggplot2::ylab("Code and Name of Missing Item") +
    ggplot2::ggtitle("Missing Events")

  ggplot2::ggsave(filename = paste0(
    path_name,
    "plots/",
    "missing_events.png"),
    plot = missing_events_plot,
    height = 40)

  # missing_events <- base::setdiff(hic_codes, unique_events %>%
  #                                   select(code_name) %>%
  #                                   pull() %>%
  #                                   unique())

  setTxtProgressBar(pb, 5)

  # Reference Table
  # Left join is used here because we don't want to drag around NAs from empty
  # files
  reference <- make_reference(connection = ctn)

  ## Capture colour profile for consistency
  all_sites.col <- c("#66C2A5", "#FC8D62", "#8DA0CB", "#E78AC3", "#A6D854")
  names(all_sites.col)  <- all_sites

  # Cases ----
  # Gives a tibble of admission numbers (patients/episodes) by week
  admissions_weekly <- reference %>%
    dplyr::distinct() %>%
    weekly_admissions()

  setTxtProgressBar(pb, 6)

  # Gives overall admission numbers (totals) for patients/episodes
  admissions_by_unit <-
    unit_admissions(events_table = tbls[["events"]],
                    reference_table = reference)

  setTxtProgressBar(pb, 7)

  for (i in seq_along(all_sites)) {
    plot_heatcal(reference_table = reference, site = all_sites[i])
    ggplot2::ggsave(filename = paste0(
      path_name,
      "plots/",
      all_sites[i],
      "_admissions.png"),
      dpi = 300, width = 10, height = 7, units = "in")
  }

  setTxtProgressBar(pb, 8)

  # Length of Stay "Episode Length" ----

  ## This calculates the episode length for an admission
  ## This is calculated by using the discharge unit time, which is not completed
  ## universally
  ## So date and time of death is used where possible to supplement
  ## This is a complete table with a validation column, so don't use without
  ## filtering out invalid records

  # Core Table ----
  core <- make_core(ctn)

  # Epsiode_length
  episode_length <- epi_length(core_table = core,
                               reference_table = reference,
                               events_table = tbls[["events"]])

  # Write out this validation to the database
  episode_validation <- episode_length %>%
    dplyr::select(episode_id, validity)

  DBI::dbWriteTable(
    conn =  ctn,
    name = "episode_validation",
    value = episode_validation,
    append = FALSE,
    overwrite = TRUE)

  # Seplls
  spells_user_defined <- identify_spells(
    episode_length = episode_length,
    episodes = episodes,
    minutes = spell_boundary_mins) %>%
      group_by(site) %>%
      summarise(patients = n_distinct(nhs_number),
                episodes = n_distinct(episode_id),
                spells_user = n_distinct(spell_id))

  spells_50_under <- identify_spells(
    episode_length = episode_length,
    episodes = episodes,
    minutes = spell_boundary_mins/2) %>%
      group_by(site) %>%
      summarise(spells_50_under = n_distinct(spell_id))

  spells_50_over <- identify_spells(
    episode_length = episode_length,
    episodes = episodes,
    minutes = (spell_boundary_mins+(spell_boundary_mins/2))) %>%
      group_by(site) %>%
      summarise(spells_50_over = n_distinct(spell_id))

  # This is to help give a better understanding of how sensitive our
  # decisions around
  # What defines a spell are.
  spells <- spells_user_defined %>%
    left_join(spells_50_over, by = "site") %>%
    left_join(spells_50_under, by = "site")

  setTxtProgressBar(pb, 9)

  # Episode validity long term average
  # typical_admissions gives me the mean and sd for the long running admissions
  # by wday

  de_validated <- devalidate_episodes(episode_length_table = episode_length,
                                          reference_table = reference,
                                          all_sites = all_sites,
                                          threshold = 10)

  #save(validated_episodes, file = paste0(path_name,
  # "validation_data/validated_episodes.RData"))
  DBI::dbWriteTable(ctn, "episode_validation", de_validated, append = TRUE,
                    overwrite = FALSE)

  setTxtProgressBar(pb, 10)

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

    temp_df <- extract(core_table = core, input = hic_codes[i]) %>%
      flag_all(episode_length)

    # Plotting
    plot_hic(x = temp_df, path_name = path_name, all_sites.col = all_sites.col)

    print(paste0("finished plotting: ", hic_codes[i]))

    #Saving errors outside the main list
    try(hic_event_summary[[hic_codes[i]]] <- summary_main(temp_df, reference))

    # try(hic_event_validation[[hic_codes[i]]] <- validate_event(
    # validated_episodes, temp_df))

    print(paste0("finished validating: ", hic_codes[i]))

    rm(temp_df)

    print(paste0("totally finished: ", hic_codes[i]))

    setTxtProgressBar(pb, i)

  }

  close(pb)

  print("Finished Event Level Evaluation")

  # save(hic_event_summary,
  #      file = paste0(path_name,
  #                    "working_data/hic_event_summary.RData"))
  # save(hic_event_validation,
  #      file = paste0(path_name,
  #                    "working_data/hic_event_validation.RData"))

  # close the connection

  DBI::dbDisconnect(ctn)


}

