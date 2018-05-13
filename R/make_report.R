#' Make HIC Report Data
#'
#' This is the main function for processing data from CC-HIC. It wraps all alther functions to evaluate
#' the whole database in one sweep.
#'
#' When running this function you should make the following folder heirachy availible:
#' plots
#' working_data
#'
#' report.rmd can be run after this function has successfully completed to produce a full report for CC-HIC
#'
#' @param database
#' @param username
#' @param path_name
#'
#' @return
#' @export
#'
#' @examples
make_report <- function(database = "lenient_dev",
                        username = "edward",
                       path_name = NULL,
                        useDeath = TRUE) {

  # Prepare Connections
  ctn <- inspectEHR::connect(database = database, username = username)
  tbls <- inspectEHR::retrieve(ctn)
  tbl_list <- dplyr::db_list_tables(ctn)

  # Collect small tables
  episodes <- collect(tbls[["episodes"]])
  provenance <- collect(tbls[["provenance"]])
  metadata <- collect(tbls[["variables"]])
  errors <- collect(tbls[["errors"]])

  # XML level errors
  xml_stats <- xml_stats(importstats = tbls[["importstats"]])
  empty_files <- empty_files(episodes, provenance)
  non_parsed <- non_parsed_files(provenance)
  error_summary <- error_summary(errors, provenance)

  error_grid <- error_summary %>%
    ggplot(aes(x = site, y = message_type, fill = count)) +
    geom_tile() +
    geom_text(aes(label = count), colour = "white") +
    theme_minimal()

  ggsave(error_grid, filename = paste0(path_name, "plots/error_grid.png"))
  rm(error_grid)

  # Reference Table
  # Left join is used here because we don't want to drag around NAs from empty files
  reference <- make_reference(episodes, provenance)

  all_sites <- reference %>% select(site) %>% distinct %>% pull

  # Generate a list of unique hic codes as name placeholders
  hic_codes <- qref$code_name

  # Core Table ----
  core <- make_core(tbls[["events"]], tbls[["episodes"]], tbls[["provenance"]])

  # Cases ----
  # Gives a tibble of admission numbers (patients/episodes) by week
  admitted_cases_all <- retrieve_unique_cases(episodes, provenance) %>%
    report_cases_all()

  # Gives overall admission numbers (totals) for patients/episodes
  admitted_cases_unit <- report_cases_unit(events_table = tbls[["events"]], reference_table = reference)

  # This isn't working inside a for loop - not sure why
  plot_heatcal(episodes, provenance, site = all_sites[[1]])
  ggsave(filename = paste0(path_name, "plots/site_a.png"))

  plot_heatcal(episodes, provenance, site = all_sites[[2]])
  ggsave(filename = paste0(path_name, "plots/site_b.png"))

  plot_heatcal(episodes, provenance, site = all_sites[[3]])
  ggsave(filename = paste0(path_name, "plots/site_c.png"))

  plot_heatcal(episodes, provenance, site = all_sites[[4]])
  ggsave(filename = paste0(path_name, "plots/site_d.png"))

  plot_heatcal(episodes, provenance, site = all_sites[[5]])
  ggsave(filename = paste0(path_name, "plots/site_e.png"))

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

  # Episode validity long term average
  # typical_admissions gives me the mean and sd for the long running admissions by wday

  invalid_months <- invalid_months(episodes, provenance)

# # this is for plotting this out
#
# for (i in 1:length(all_sites)) {
#
#   invalid_months %>%
#     mutate(x = (month*4.3)-1,
#            y = 4,
#            text = "!") %>%
#     filter(site == all_sites[i]) -> invalids
#
#   temp_data <-
#     retrieve_unique_cases(episodes, provenance) %>%
#     report_cases_byday(bysite = all_sites[i])
#
#   temp_cal <- create_calendar(temp_data)
#   temp_grid <- create_grid(temp_cal)
#
#   temp_cal %>%
#     ggplot() +
#     geom_tile(aes(x = week_of_year, y = day_of_week, fill = episodes), colour = "#FFFFFF") +
#     scale_fill_gradientn(colors = c("#B5E384", "#FFFFBD", "#FFAE63", "#D61818"), na.value = "grey90") +
#     facet_grid(year~.) +
#     geom_text(aes(x = x, y = y, label = text), colour = "red", data = invalids) +
#     theme_minimal() +
#     theme(panel.grid.major=element_blank(),
#           plot.title = element_text(hjust = 0.5),
#           axis.text.x = element_blank(),
#           axis.title.y = element_blank(),
#           axis.title.x = element_blank()) +
#     geom_segment(aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
#                  colour = "black", size = 0.5, data = temp_grid) +
#     labs(title = paste0("Admission Calendar Heatmap for " , names(all_sites[i]))) +
#     ylab(label = "Day of Week") +
#     xlab(label = "Month") +
#     coord_equal() -> temp_plot
#
#   ggsave(temp_plot,
#          filename = paste0("~/Projects/dataQuality/plots/admission_", all_sites[i], "_valid.png"),
#          dpi = 300)
#
#   rm(temp_data, temp_cal, temp_grid, temp_plot)
#
# }
#
# rm(i)

# provides an occupancy table but with missing data filled
# Takes a really long time
# occupancy <- calc_site_occupancy(episode_length_tbl = episode_length)

  ###############
  # Doubles =====
  ###############

  qref %>%
    select(code_name, primary_column) %>%
    filter(datatype == "real") %>%
    select(code_name) %>%
    pull -> all_dbls

  # Set up doubles
  hic_dbls <- vector(mode = "list", length = length(all_dbls))
  names(hic_dbls) <- all_dbls

  # And warinings
  hic_dbls_warnings <- vector(mode = "list", length = length(all_dbls))
  names(hic_dbls_warnings) <- all_dbls

  # create progress bar
  print("Starting Doubles")
  pb <- txtProgressBar(min = 0, max = length(all_dbls), style = 3)

  for (i in 1:length(all_dbls)) {

    # the basics
    hic_dbls[[all_dbls[i]]] <- try(validate_field(core, reference, input_field = all_dbls[i], qref, episode_length))

    # Plotting
    temp_plot <- try(plot(hic_dbls[[all_dbls[i]]]$flagged))
    try(ggsave(filename = paste0(path_name, "plots/", all_dbls[i], ".png"), plot = temp_plot))

    #Saving errors outside the main list
    hic_dbls_warnings[[all_dbls[i]]] <- try(hic_dbls[[all_dbls[i]]]$warnings)

    setTxtProgressBar(pb, i)

  }

  close(pb)
  print("finished doubles")

  rm(hic_dbls)

###############
# Integers ====
###############

qref %>%
  select(code_name, datatype) %>%
  distinct(code_name, .keep_all = TRUE) %>%
  filter(datatype == "hic_int") %>%
  select(code_name) %>%
  pull -> all_ints

# Set up vector for integers
hic_ints <- vector(mode = "list", length = length(all_ints))
names(hic_ints) <- all_ints

# Set up the vector for warning messages
# This is not ideal, but at this stage I cannot work out how to remove a list element and re-alocate the memory easily
hic_ints_warnings <- vector(mode = "list", length = length(all_ints))
names(hic_ints_warnings) <- all_ints

pb <- txtProgressBar(min = 0, max = length(all_ints), style = 3)

for (i in 1:length(all_ints)) {

  # Basic Work
  hic_ints[[all_ints[i]]] <- try(validate_field(core, reference, input_field = all_ints[i], qref, episode_length))

  # Plotting
  temp_plot <- try(plot(hic_ints[[all_ints[i]]]$flagged))
  try(ggsave(filename = paste0(path_name, "plots/", all_ints[i], ".png"), plot = temp_plot))

  #Saving errors outside the main list
  hic_ints_warnings[[all_ints[i]]] <- try(hic_ints[[all_ints[i]]]$warnings)

  setTxtProgressBar(pb, i)

}

close(pb)

rm(hic_ints)

###############
# Strings =====
###############

qref %>%
  select(code_name, datatype) %>%
  distinct(code_name, .keep_all = TRUE) %>%
  filter(datatype == "hic_str") %>%
  select(code_name) %>%
  pull -> all_strs

# Set up vector for integers
hic_strs <- vector(mode = "list", length = length(all_strs))
names(hic_strs) <- all_strs

# Set up the vector for warning messages
# This is not ideal, but at this stage I cannot work out how to remove a list element and re-alocate the memory easily
hic_strs_warnings <- vector(mode = "list", length = length(all_strs))
names(hic_strs_warnings) <- all_strs

pb <- txtProgressBar(min = 0, max = length(all_strs), style = 3)

for (i in 1:length(all_strs)) {

  # Basic Work
  hic_strs[[all_strs[i]]] <- try(validate_field(core, reference, input_field = all_strs[i], qref, episode_length))

  # Plotting
  temp_plot <- try(plot(hic_strs[[all_strs[i]]]$flagged))
  try(ggsave(filename = paste0(path_name, "plots/", all_strs[i], ".png"), plot = temp_plot))

  #Saving errors outside the main list
  hic_strs_warnings[[all_strs[i]]] <- try(hic_strs[[all_strs[i]]]$warnings)

  setTxtProgressBar(pb, i)

}

close(pb)

rm(hic_strs)

save.image(file = paste0(path_name, "working_data/report_data.RData"))




}

