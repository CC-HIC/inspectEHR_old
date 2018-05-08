# This file contains the main workflow to prepare data for the data quality report

## Description

## The typical flow is:
## Extract > Flag > Summarise > Plot

## Load Required Packages

library(tidyverse)
library(devtools)
library(dbplyr)
library(lubridate)
library(magrittr)

# detach("package:chron")
# detach("package:lubridate")

# library(hicreportr) / load_all() (if within the package)

# ## Quality Reference Table
# ## This contains reference ranges etc. that are required to flag hic events
# ## You only need to run this if the QREF has changed and you are building
# ## the package again
# qref <- prepare_qref()
# use_data(qref, internal = TRUE, overwrite = TRUE)

path_name <- "/Users/edward/Documents/_dev/dataQualityReport/"

#  "N:/My Documents/Projects/dataQuality/"

# Prepare Connections
ctn <- connect(database = "lenient_dev", username = "edward")
tbls <- retrieve(ctn)
tbl_list <- dplyr::db_list_tables(ctn)

## Collect small tables
episodes <- collect(tbls[["episodes"]])
provenance <- collect(tbls[["provenance"]])
metadata <- collect(tbls[["variables"]])
errors <- collect(tbls[["errors"]])

## XML level errors
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

## Reference Table
## Left join is used here because we don't want to drag around NAs from empty files
reference <- make_reference(episodes, provenance)

all_sites <- reference %>% select(site) %>% distinct %>% pull

# Generate a list of unique hic codes as name placeholders
hic_codes <- na.omit(unique(qref$code_name))

# write the report list
# report <- vector("list", length(hic_codes))
# names(report) <- hic_codes

## Core Table ----
core <- make_core(tbls[["events"]], tbls[["episodes"]], tbls[["provenance"]])

## Cases ----
## Gives a tibble of admission numbers (patients/episodes) by week
admitted_cases_all <- retrieve_unique_cases(episodes, provenance) %>%
  report_cases_all()

## Gives overall admission numbers (totals) for patients/episodes
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
episode_length <- epi_length(core, useDeath = FALSE)

# Seplls
spells <- identify_spells(episode_length = episode_length, episodes = episodes)

spells %<>%
  group_by(site) %>%
  summarise(patients = n_distinct(nhs_number),
            episodes = n_distinct(episode_id),
            spells = n_distinct(spell_id))

# Episode validity long term average

# Calculate the days that have an uncharacteristically low number of admissions
# for a given day in the year
# those + any NAs will count toward a scoring day.
# if > 30% of the month has a score, then the whole month is removed

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
occupancy <- calc_site_occupancy(episode_length_tbl = episode_length)

# different data types to tackle:
#   - Numerics; Longitudinal
#   - String; longitudinal
#   - Numerics; static
#   - String; static

##  Ints and Doubles -> Longitudinal
qref %>%
  filter(datatype == "hic_int" | datatype == "hic_dbl",
         longitudinal == TRUE) %>%
  select(code_name) %>% pull -> hic_long_numerical

# Now lets go for broke

qref %>%
  select(code_name, datatype) %>%
  distinct(code_name, .keep_all = TRUE) %>%
  filter(datatype == "hic_dbl") %>%
  select(code_name) %>%
  pull -> all_dbls

qref %>%
  select(code_name, datatype) %>%
  distinct(code_name, .keep_all = TRUE) %>%
  filter(datatype == "hic_int") %>%
  select(code_name) %>%
  pull -> all_ints

hic_dbls <- vector(mode = "list", length = length(all_dbls))
names(hic_dbls) <- all_dbls

# create progress bar
pb <- txtProgressBar(min = 0, max = length(all_dbls), style = 3)

for (i in 1:length(all_dbls)) {

  hic_dbls[[all_dbls[i]]] <- try(validate_field(core, reference, input_field = all_dbls[i], qref, episode_length))

  temp_plot <- try(plot(hic_dbls[[all_dbls[i]]]$flagged))

  try(ggsave(filename = paste0(path_name, "plots/", all_dbls[i], ".png"), plot = temp_plot))

  setTxtProgressBar(pb, i)

}

close(pb)

hic_ints <- vector(mode = "list", length = length(all_ints))
names(hic_ints) <- all_ints

pb <- txtProgressBar(min = 0, max = length(all_ints), style = 3)

for (i in 1:length(all_ints)) {

  hic_ints[[all_ints[i]]] <- try(validate_field(core, reference, input_field = all_ints[i], qref, episode_length))
  setTxtProgressBar(pb, i)

}

close(pb)

# report[[code_name]]$warn <- try(warning_summary(report[[code_name]]$raw))
#
# report[[code_name]]$na <- try(add_na(report[[code_name]]$raw, reference_table = reference) %>%
#                                 group_by(site) %>%
#                                 summarise(count = n()))
#
# report[[code_name]]$cov <- try(coverage(report[[code_name]]$raw, occupancy_tbl = occupancy,
#                                         cases_all_tbl = cases_all))
#
# report[[code_name]]$cov_plot <- try(plot(report[[code_name]]$cov))
#
# report[[code_name]]$dist_plot <- try(plot(report[[code_name]]$raw))
#
# report[[code_name]]$raw <- NULL


save(dbls, file = "N:/My Documents/currentSave/doubles.RData")

for (i in 1:length(hic_num)) {

  # save_name_cov <- paste0(all_dbls[i], "_cov.png")
  # save_name_dist <- paste0(all_dbls[i], "_dist.png")
  save_name_plot <- paste0(hic_num[i], ".png")


  try(ggsave(plot = report[[hic_num[i]]]$plot,
         filename = paste0("N:/My Documents/Projects/dataQuality/plots/B", save_name_plot),
         dpi = 300, units = "cm",
         width = 40, height = 22.5))

  # try(ggsave(plot = dbls[[all_dbls[i]]]$distribution_plot,
  #        filename = paste0("N:/My Documents/Projects/dataQuality/plots/", save_name_dist),
  #        dpi = 300, units = "cm",
  #        width = 40, height = 22.5))

}


## Ints

## Strings

## Static Strings

alive <- extract(core_table = core, qref = qref, input = "NIHR_HIC_ICU_0097")

alive %>%
  group_by(site, value) %>%
  summarise(n())

alive %>% flag_range(qref = qref) %>%
  group_by(range_error) %>%
  summarise(n())


alive %>% flag_bounds(los_table = episode_length) %>%
  group_by(out_of_bounds) %>%
  summarise(n())

alive %>% flag_duplicate() %>%
  group_by(duplicate) %>%
  summarise(n())


alive %>% flag_all(qref = qref, los_table = episode_length) %>%
  filter(range_error != 0)


data_item <- alive[1, "code_name"] %>% pull

permitted <- qref %>%
  filter(code_name == data_item) %>%
  select(data) %>%
  unnest() %>%
  select(metadata_labels)

%>%
  pull

  # joins to the quality refernce table to identify range errors
  x %<>%
    dplyr::mutate(range_error = ifelse(value %in% permitted, 0L, 1L)) %>%
    dplyr::select(internal_id, range_error)



# Post Codes

tbls[["events"]] %>%
  filter(code_name == "NIHR_HIC_ICU_0428")



%>%
  select(string) %>% collect %>% distinct

warnings <- lapply(report, '[[', 1)
Nas <- lapply(report, '[[', 2)




report$NIHR_HIC_ICU_0108$warnings



