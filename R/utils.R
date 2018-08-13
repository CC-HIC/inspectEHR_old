#' Establishes a connection to the database
#'
#' @param host db host: typically "localhost"
#' @param username db username
#' @param password db password
#' @param database target db
#' @param system choice of either "postgres" or "sqlite" depending upon your backend
#' @param file filename as character vector if using an sqlite db
#'
#' @return a database object connection
#' @export
#'
#' @examples
#' # connect to postgres with default settings
#' ctn <- connect()
#' # connect to sqlite
#' ctn <- connect(system = "sqlite", file = "path/to/file.sqlite3")
connect <- function(host = 'localhost',
                    username = 'ucasper',
                    password = "superdb",
                    database = 'cchic',
                    system = "postgres",
                    file = NULL) {

  if (system == "postgres") {

    connection <- DBI::dbConnect(RPostgres::Postgres(),
                   host=host,
                   port=5432,
                   user=username,
                   password=password,
                   dbname=database)

  }

  if (system == "sqlite") {

    connection <- DBI::dbConnect(RSQLite::SQLite(), file)

  }

  return(connection)

}


#' Retrieves db tables
#'
#' These tables come as a list and must be unlisted or accessed directly
#'
#' @param connection an sql connection
#'
#' @importFrom dplyr db_list_tables
#' @import dbplyr
#'
#' @return a list containing pointers to tables within the sql connection
#' @export
#'
#' @examples
#' retrieve_tables(ctn)
retrieve_tables <- function(connection) {

  if(missing(connection)) {
    stop("a connection must be provided")
  }

  all_tables <- dplyr::db_list_tables(connection)
  tbl_list <- list()

  for (i in seq_along(all_tables)) {
    tbl_list[[all_tables[i]]] <- dplyr::tbl(connection, all_tables[i])
  }

  return(tbl_list)

}


#' Make reference Table
#'
#' Makes the reference table used my many functions in this package.
#' This is part of the basic setup.
#'
#' @param connection a database connection
#'
#' @return a tibble with episode level data with site
#' @export
#'
#' @examples
#' make_reference(ctn)
make_reference <- function(connection) {

    episodes <- dplyr::tbl(connection, "episodes")
    provenance <- dplyr::tbl(connection, "provenance")

    reference <- left_join(episodes, provenance, by = c("provenance" = "file_id")) %>%
      select(episode_id, nhs_number, start_date, site)

    # Accounts for lack of datetime type in SQLite
    if (attributes(attributes(connection)$class)$package == "RSQLite") {
      reference <- reference %>%
        mutate(start_date = datetime(start_date, 'unixepoch')) %>%
        collect() %>%
        mutate(start_date = lubridate::ymd_hms(start_date))

      return(reference)

    } else {

      reference <- collect(reference)
      return(reference)

    }
}


#' Make core table
#'
#' Produces the core table structure necessary for the data quality report
#'
#' @param connection a database connection
#'
#' @return a tibble with all hic events
#' @export
#'
#' @examples
#' make_core(ctn)
make_core <- function(connection) {

  events <- dplyr::tbl(connection, "events")
  episodes <- dplyr::tbl(connection, "episodes")
  provenance <- dplyr::tbl(connection, "provenance")

  core <- episodes %>%
    left_join(provenance, by = c("provenance" = "file_id")) %>%
    inner_join(events, by = "episode_id")

  # if (attributes(attributes(connection)$class)$package == "RSQLite") {
  #
  #   core <- core %>%
  #     mutate(start_date = datetime(start_date, 'unixepoch'),
  #            date_created = datetime(date_created, 'unixepoch'),
  #            datetime = datetime(datetime, 'unixepoch')
  #            #date = datetime(date, 'unixepoch')
  #            )
  #
  # }

  return(core)

}


parse_sqlite_datetime <- function(object) {

  if (attributes(class(object$src$con))$package == "RSQLite") {


  }

}


find_max_time <- function(events, time_col) {

  quo_timecol <- enquo(time_col)

  max_time <- events %>%
    group_by(episode_id) %>%
    summarise(maxtime = max(!! quo_timecol, na.rm = TRUE)) %>%
    collect() %>%
    mutate(maxtime = as.POSIXct(maxtime, origin = "1970-01-01 00:00:00"))

  return(max_time)

}

# admission_dttm <- function(core_table = NULL) {
#
#   if (is.null(core_table)) stop("You must include the tables")
#
#   admission_dttm <- core_table %>%
#     filter(code_name == "NIHR_HIC_ICU_0411") %>%
#     select(episode_id, datetime) %>%
#     collect()
#
#   names(admission_dttm) <- c("episode_id", "addm_dttm")
#
#   return(admission_dttm)
#
# }


#' Custom Error Capturing
#'
#' @param x
#'
#' @return
#' @export
#'
#' @examples
is.error <- function(x) {
  inherits(x, "try-error")
}



fix_oxford_time <- function(x) {
  ## Fix Oxford -> this is a temporary fix for the oxford time issue ====

  oxford <- x %>%
    filter(site == "Oxford")

  ## Couldn't get this to work in DPLYR without throwing errors, reverted to base
  ## Also note, that oxford dttm conventions are inconsistent, making is hard it anticipate
  ## which dttm format they are intending on using

  oxford$epi_start_dttm <- as.POSIXct(paste(
    strftime(oxford$epi_start_dttm, format = "%F"),
    strftime(oxford$epi_start_dttm, format = "%M:%S")
  ), format = "%F %H:%M")

  oxford$epi_end_dttm <- as.POSIXct(paste(
    strftime(oxford$epi_end_dttm, format = "%F"),
    strftime(oxford$epi_end_dttm, format = "%M:%S")
  ), format = "%F %H:%M")

  oxford$los <-
    difftime(oxford$epi_end_dttm, oxford$epi_start_dttm, units = "days")

  x %<>%
    filter(site != "Oxford") %>%
    rbind(oxford)

  return(x)

}


# ===== CLASS CHECKING


is.string_2d <- function(x) inherits(x, "string_2d")
is.string_1d <- function(x) inherits(x, "string_1d")
is.integer_2d <- function(x) inherits(x, "integer_2d")
is.integer_1d <- function(x) inherits(x, "integer_1d")
is.real_2d <- function(x) inherits(x, "real_2d")
is.real_1d <- function(x) inherits(x, "real_1d")
is.datetime_1d <- function(x) inherits(x, "datetime_1d")
is.date_1d <- function(x) inherits(x, "date_1d")
is.time_1d <- function(x) inherits(x, "time_1d")
