#' Plot Calendar Heatmap
#'
#' @param episodes collected episodes table
#' @param provenance collected provenance table
#' @param site character string of hospital site to plot
#' @param filename optional string to save output. must include extension
#'
#' @return a plot with admission details in heatmap form
#' @export
#'
#'
#' @examples
#' plot_heatcal(episodes, provenance, "UCL")
#' plot_heatcal(episodes, provenance, "UCL", "~/some/path/plot.png")
plot_heatcal <- function(episodes = NULL,
                         provenance = NULL,
                         site = NULL,
                         filename = NULL) {

  retrieve_unique_cases(episodes, provenance) %>%
  report_cases_byday(bysite = site) %>%
  create_calendar() -> calendar

  calendar %>%
    create_grid() -> Grid

  if (is.null(filename)) {

    ggHeatCal(x = calendar,
              gridLines = Grid,
              Title = paste0("Admission Calendar Heatmap for " , site)) -> Plot

  return(Plot)

  } else {

    ggsave(
      ggHeatCal(x = calendar,
                gridLines = Grid,
                Title = paste0("Admission Calendar Heatmap for " , site)),
      filename = filename)

  }

}







#' Find First Sunday
#'
#' Finds the first sunday of the year supplied to x
#'
#' @param x a vector of class date
#'
#' @return a vector with dates for the first sunday of each year supplied to x
#' @export
#'
#' @importFrom lubridate floor_date wday days
#'
#' @examples
#' find_first_sunday(x)
find_first_sunday <- function(x) {

  first <- floor_date(x, "month")
  dow <- sapply(seq(0,6),function(x) wday(first+days(x)))
  firstSunday <- first + days(which(dow==1)-1)
  return(firstSunday)

}


#' Create A Heat Map Calender
#'
#' creates the basic template for a heatmap calendar in ggplop
#'
#' @param start_date a starting date as character vector of format YYYY/MM/DD
#' @param end_date an end date as character vector of format YYYY/MM/DD
#' @param x count data to be used in the calendar
#'
#' @return a tibble with correct week alignments for a calendar heatmap
#' @export
#'
#' @importFrom lubridate floor_date ceiling_date ymd year month
#'
#' @examples
#' sample_data <- create_calendar(myData, "2014-01-01", "2018-01-01")
create_calendar <- function(x = NULL,
                   start_date = "2014-01-01",
                     end_date = "2018-01-01") {

  first_date <- floor_date(ymd(start_date), unit = "years")
  last_date <- ceiling_date(ymd(end_date), unit = "years") - 1

  # days till first sunday for each year
  remaining <-
    tibble(
      years = seq(from = first_date,
                    to = last_date,
                    by = "year")) %>%
    mutate(
      firstSundays = as.Date(
        sapply(years, find_first_sunday), origin = "1970/01/01"),
    remaining_days = as.integer(firstSundays - years),
              year = year(years))

  calendar <-
    tibble(date = seq(from = first_date, to = last_date, by = "day")) %>%
    mutate(year = as.integer(year(date)))

  years <- unique(calendar$year)
  week_of_year <- vector(mode = "integer")

  for (year in years) {

    if (remaining$remaining_days[remaining$year == year] == 0) {
      this_week_of_year <- rep(1:52, each = 7)

    } else {

      this_week_of_year <- c(rep(1, times = remaining$remaining_days[remaining$year == year]),
                             rep(2:52, each = 7))

    }

    remaining_length <- nrow(calendar[calendar$year == year,]) - length(this_week_of_year)

    if (remaining_length != 0) {

      this_week_of_year <- c(this_week_of_year, rep(53, times = remaining_length))

    }

    week_of_year <- c(week_of_year, this_week_of_year)

  }

  calendar <- calendar %>%
    mutate(week_of_year = as.integer(week_of_year),
            day_of_week = wday(date, label = TRUE),
                  month = month(date, label = TRUE)) %>%
    left_join(x, by = "date")

  return(calendar)

}

create_grid <- function(calendar_template = NULL) {

  template <- calendar_template %>%
    select(date, year, week_of_year, day_of_week, month)

  # Right Vertical
  rv <- template %>%
    mutate(
      x_start = ifelse(
        lead(month, 7) != month |
          is.na(lead(month, 7)),
        week_of_year + 0.5,
        NA),
      y_start = ifelse(
        lead(month, 7) != month |
          is.na(lead(month, 7)),
        as.double(day_of_week) + 0.5,
        NA
      )
    ) %>%
    na.omit %>%
    select(year, x_start, y_start) %>%
    mutate(x_end = x_start,
           y_end = y_start - 1)

  # Left Vertical
  lv <- template %>%
    mutate(
      x_start = ifelse(lag(month, 7) != month |
                         is.na(lag(month, 7)), week_of_year - 0.5, NA),
      y_start = ifelse(
        lag(month, 7) != month |
          is.na(lag(month, 7)),
        as.double(day_of_week) + 0.5,
        NA
      )
    ) %>%
    na.omit %>%
    select(year, x_start, y_start) %>%
    mutate(x_end = x_start,
           y_end = y_start - 1)

  # Top Horizontal
  th <- template %>%
    mutate(
      x_start = ifelse(
        lead(month, 1) != month |
          lead(week_of_year, 1) != week_of_year |
          is.na(lead(week_of_year)),
        week_of_year - 0.5,
        NA
      ),
      y_start = ifelse(
        lead(month, 1) != month |
          lead(week_of_year, 1) != week_of_year |
          is.na(lead(week_of_year)),
        as.double(day_of_week) + 0.5,
        NA
      )
    ) %>%
    na.omit %>%
    select(year, x_start, y_start) %>%
    mutate(x_end = x_start + 1,
           y_end = y_start)

  # Bottom Horizontal
  bh <- template %>%
    mutate(
      x_start = ifelse(
        lag(month, 1) != month |
          lag(week_of_year, 1) != week_of_year |
          is.na(lag(week_of_year, 1)),
        week_of_year - 0.5,
        NA
      ),
      y_start = ifelse(
        lag(month, 1) != month |
          lag(week_of_year, 1) != week_of_year |
          is.na(lag(week_of_year, 1)),
        as.double(day_of_week) - 0.5,
        NA
      )
    ) %>%
    na.omit %>%
    select(year, x_start, y_start) %>%
    mutate(x_end = x_start + 1,
           y_end = y_start)

  gridLines <- rbind(rv, lv, th, bh) %>% distinct()

  return(gridLines)

}


ggHeatCal <- function(x, gridLines, Title) {

  x %>%
    ggplot() +
    geom_tile(aes(x = week_of_year, y = day_of_week, fill = episodes), colour = "#FFFFFF") +
    scale_fill_gradientn(colors = c("#B5E384", "#FFFFBD", "#FFAE63", "#D61818"), na.value = "grey90") +
    facet_grid(year~.) +
    theme_minimal() +
    theme(panel.grid.major=element_blank(),
          plot.title = element_text(hjust = 0.5),
          axis.text.x = element_blank(),
          axis.title.y = element_blank(),
          axis.title.x = element_blank()) +
    geom_segment(aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
                 colour = "black", size = 0.5, data = gridLines) +
    labs(title = Title) +
    ylab(label = "Day of Week") +
    xlab(label = "Month") +
    coord_equal()

}
