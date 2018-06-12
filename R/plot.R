#' Plot NHIC Events
#'
#' Plots NHIC events in a predetermined way and output to the plot folder specified
#'
#' @param x flagged table
#'
#' @importFrom rlang .data
#' @export
#'
#' @return A tibble 1 row per event
plot_hic <- function(x, path_name = NULL, all_sites.col) {

  if (nrow(x) != 0) {

    # Identify the correct column type to pull out
    code_name <- attr(x, "code_name")
    data_class <- class(x)[1]

    # These switching statements have been put in for when plots start
    # to diverge

    perfect_plot <- data_class %>%
      base::switch(
        integer_1d = plot_default(x, code_name = code_name, all_sites.col = all_sites.col),
        integer_2d = plot_default(x, code_name = code_name, all_sites.col = all_sites.col),
           real_1d = plot_default(x, code_name = code_name, all_sites.col = all_sites.col),
           real_2d = plot_default(x, code_name = code_name, all_sites.col = all_sites.col),
         string_1d = plot_default(x, code_name = code_name, all_sites.col = all_sites.col),
         string_2d = plot_default(x, code_name = code_name, all_sites.col = all_sites.col),
       datetime_1d = plot_default(x, code_name = code_name, all_sites.col = all_sites.col),
           date_1d = plot_default(x, code_name = code_name, all_sites.col = all_sites.col),
           time_1d = plot_default(x, code_name = code_name, all_sites.col = all_sites.col))

  if (!is.null(path_name)) {

    ggsave(
      plot = perfect_plot,
      filename = paste0(
        path_name, "plots/", code_name, "_main.png"),
      dpi = 300, width = 10, units = "in")

  }

  # Check to see if there is a 2d component, and if so plot periodicity
  if (any(grepl("2d", class(x)))) {

    periodicity_plot <- plot_periodicity(x, code_name, all_sites.col = all_sites.col)

  if (!is.null(path_name)) {

    ggsave(
      plot = periodicity_plot,
  filename = paste0(
      path_name, "plots/", code_name, "_periodicity.png"),
  dpi = 300, width = 10, units = "in")

  }

  }

  } else {

    cat("/n", "/n",
        attr(x, "code_name"),
        " contains no data and will be skipped",
        "/n")

  }

  # debugging only
  return(perfect_plot)

}

# retired function
# plot_coverage <- function(x) {
#
#   cov_plot <- x %>%
#     ggplot(aes(x = week_of_month, y = site, fill = log(disparity))) +
#       geom_tile(colour = "white") +
#       scale_fill_gradient2(low = "#2b83ba", mid = "#ffffbf", high = "#d7191c",
#                            midpoint = 0, na.value = "grey70") +
#       facet_grid(year ~ month) +
#       theme_minimal(base_size = 20) +
#       theme(panel.grid = element_blank()) +
#       labs(fill = "", x = "Week of Month", y = "Biomedical Research Center")
#
#   return(cov_plot)
#
# }


#' Default Plot
#'
#' @param x
#' @param code_name
#'
#' @return
#' @export
#'
#' @importFrom rlang .data
#' @importFrom magrittr %>%
#'
#' @examples
plot_default <- function(x, code_name, all_sites.col) {

  if (code_name %in% categorical_hic) {

    perfect_plot <- plot_histogram(x, code_name, all_sites.col)

  } else {

    perfect_plot <- x %>%
      filter(.data$out_of_bounds == 0 | is.na(.data$out_of_bounds),
             .data$duplicate == 0 | is.na(.data$duplicate),
             .data$range_error == 0 | is.na(.data$range_error)) %>%
      ggplot(
        aes_string(x = "value",
                   colour = "site")) +
      scale_colour_manual(values = all_sites.col) +
      geom_density() +
      xlab(code_name) +
      ylab("Population Density") +
      theme_minimal()

  }

  return(perfect_plot)

}


#' Plot Histogram
#'
#' @param x
#' @param code_name
#'
#' @return
#' @export
#'
#' @importFrom rlang .data
#' @importFrom magrittr %>%
#' @importFrom tidyr complete
#' @importFrom scales percent_format
#'
#' @examples
plot_histogram <- function(x, code_name, all_sites.col) {

  perfect_plot <- x %>%
    dplyr::filter(.data$out_of_bounds == 0 | is.na(.data$out_of_bounds),
           .data$duplicate == 0 | is.na(.data$duplicate),
           .data$range_error == 0 | is.na(.data$range_error)) %>%
    dplyr::select(site, value) %>%
    dplyr::group_by(site, value) %>%
    dplyr::count() %>%
    dplyr::ungroup() %>%
    dplyr::group_by(site) %>%
    dplyr::mutate(total = sum(n)) %>%
    dplyr::ungroup() %>%
    tidyr::complete(site, value) %>%
    ggplot(
      aes(x = value,
       fill = site)
    ) +
    geom_bar(
      aes(y = n/total),
      position = "dodge",
      stat = "identity",
      width = 0.8) +
    scale_fill_manual(values = all_sites.col) +
    scale_y_continuous(labels = scales::percent_format()) +
    xlab(code_name) +
    ylab("Percentage by BRC") +
    theme_minimal()

  return(perfect_plot)

}


#' Plot periodicity
#'
#' @param x
#' @param code_name
#'
#' @return
#' @export
#'
#' @importFrom rlang .data
#' @importFrom magrittr %>%
#'
#' @examples
plot_periodicity <- function(x, code_name, all_sites.col) {

  periodicity_plot <- x %>%
    filter(.data$out_of_bounds == 0 | is.na(.data$out_of_bounds),
           .data$duplicate == 0 | is.na(.data$duplicate),
           .data$range_error == 0 | is.na(.data$range_error)) %>%
    distinct(.data$site, .data$periodicity) %>%
    filter(.data$periodicity <= 48) %>%
    ggplot(
      aes_string(x = "periodicity",
           colour = "site")) +
    scale_colour_manual(values = all_sites.col) +
    geom_histogram() +
    xlab(code_name) +
    ylab("Population Density") +
    theme_minimal()

  return(periodicity_plot)

}


#' Plot Date
#'
#' @param x
#' @param code_name
#'
#' @return
#' @export
#'
#' @importFrom rlang .data
#' @importFrom magrittr %>%
#'
#' @examples
plot_date <- function(x, code_name, all_sites.col) {

  date_plot <- x %>%
    filter(.data$out_of_bounds == 0 | is.na(.data$out_of_bounds),
           .data$duplicate == 0 | is.na(.data$duplicate),
           .data$range_error == 0 | is.na(.data$range_error)) %>%
    ggplot(
      aes_string(x = "date",
            colour = "site",
                 y = "value")) +
    scale_colour_manual(values = all_sites.col) +
    geom_line() +
    xlab("date") +
    ylab(code_name) +
    theme_minimal()

  return(date_plot)

}


#' Plot Datetime
#'
#' @param x
#' @param code_name
#'
#' @return
#' @export
#'
#' @importFrom rlang .data
#' @importFrom magrittr %>%
#'
#' @examples
plot_datetime <- function(x, code_name, all_sites.col) {

  datetime_plot <- x %>%
    filter(.data$out_of_bounds == 0 | is.na(.data$out_of_bounds),
           .data$duplicate == 0 | is.na(.data$duplicate),
           .data$range_error == 0 | is.na(.data$range_error)) %>%
    ggplot(
      aes_string(x = "datetime",
            colour = "site",
                 y = "value")) +
    scale_colour_manual(values = all_sites.col) +
    geom_line() +
    xlab("datetime") +
    ylab(code_name) +
    theme_minimal()

  return(date_plot)

}


#' Plot Time
#'
#' @param x
#' @param code_name
#'
#' @return
#' @export
#'
#' @importFrom rlang .data
#' @importFrom magrittr %>%
#'
#' @examples
plot_time <- function(x, code_name, all_sites.col) {

  time_plot <- x %>%
    filter(.data$out_of_bounds == 0 | is.na(.data$out_of_bounds),
           .data$duplicate == 0 | is.na(.data$duplicate),
           .data$range_error == 0 | is.na(.data$range_error)) %>%
    ggplot(
      aes_string(x = "time",
            colour = "site",
                 y = "value")) +
    scale_colour_manual(values = all_sites.col) +
    geom_line() +
    xlab("time") +
    ylab(code_name) +
    theme_minimal()

  return(date_plot)

}


# Retired occupancy plot

# plot_occupancy <- function(x) {
#
#   occ_plot <- x %>%
#     ggplot(aes(x = week_of_month, y = site, fill = est_occupancy)) +
#     geom_tile(colour = "white") +
#     scale_fill_gradient(low = "#ffffbf", high = "#d7191c", na.value = "grey70") +
#     facet_grid(year ~ month) +
#     theme_minimal(base_size = 20) +
#     theme(panel.grid = element_blank()) +
#     labs(fill = "", x = "Week of Month", y = "Biomedical Research Center")
#
#   return(occ_plot)
#
# }


# For plotting invalid months
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

