#' Plot NHIC Events
#'
#' Plots NHIC events by a pre-determined plot
#'
#' @param core_table core table
#' @param valid_episodes an integer vector of episode IDs that have passed the validation process
#' @param input the input variable of choice
#' @param qref the quality reference table
#'
#' @return A tibble 1 row per event
plot_hic <- function(x) {



  # Identify the correct column type to pull out
  main_plot <- qref %>%
    filter(code_name == input) %>%
    select(main_plot) %>%
    pull

  # extract chosen input variable from the core table

  perfect_plot <- main_plot %>%
    switch(Density = plot_density(x),
         Histogram = plot_histogram(x))

}

plot_coverage <- function(x) {

  cov_plot <- x %>%
    ggplot(aes(x = week_of_month, y = site, fill = log(disparity))) +
      geom_tile(colour = "white") +
      scale_fill_gradient2(low = "#2b83ba", mid = "#ffffbf", high = "#d7191c",
                           midpoint = 0, na.value = "grey70") +
      facet_grid(year ~ month) +
      theme_minimal(base_size = 20) +
      theme(panel.grid = element_blank()) +
      labs(fill = "", x = "Week of Month", y = "Biomedical Research Center")

  return(cov_plot)

}


plot_density <- function(x) {

  l <- x[1, "code_name", drop = TRUE]

  density_plot <- x %>%
    filter(out_of_bounds == 0,
           duplicate == 0,
           range_error == 0) %>%
    ggplot(aes(x = value, fill = site, y = site, height = ..density..)) +
    geom_density_ridges(alpha = 0.8, stat = "density") +
    theme_ridges(grid = FALSE) +
    scale_x_continuous(expand = c(0.01, 0)) +
    scale_y_discrete(expand = c(0.01, 0)) +
    xlab(l) +
    ylab("Population Density")

}


plot_histogram <- function(x) {

  l <- x[1, "code_name", drop = TRUE]

  histogram_plot <- x %>%
    filter(out_of_bounds == 0,
           duplicate == 0,
           range_error == 0) %>%
    ggplot(aes(x = value, fill = site, y = site, height = ..density..)) +
    geom_density_ridges(stat = "binline", bins = 20, scale = 0.95, draw_baseline = TRUE) +
    theme_ridges(grid = FALSE) +
    xlab(l) +
    ylab("Population Density")

}



plot_occupancy <- function(x) {

  occ_plot <- x %>%
    ggplot(aes(x = week_of_month, y = site, fill = est_occupancy)) +
    geom_tile(colour = "white") +
    scale_fill_gradient(low = "#ffffbf", high = "#d7191c", na.value = "grey70") +
    facet_grid(year ~ month) +
    theme_minimal(base_size = 20) +
    theme(panel.grid = element_blank()) +
    labs(fill = "", x = "Week of Month", y = "Biomedical Research Center")

  return(occ_plot)

}

