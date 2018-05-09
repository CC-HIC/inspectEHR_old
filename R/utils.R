#' Establishes a connection to the postgres database
#'
#' @param host host of the database: typically localhose
#' @param username
#' @param password
#' @param database
#'
#' @return
#' @export
#'
#' @examples
connect <- function(host = 'localhost', username = 'ucasper', password = "superdb", database = 'cchic') {

  DBI::dbConnect(RPostgres::Postgres(),
                 host=host,
                 port=5432,
                 user=username,
                 password=password,
                 dbname=database)

}


#' Prepares workspace by retrieving all the POSTgres tables without collection
#'
#' These tables come as a list and must be unlisted or accessed directly
#'
#' @param connection a formal PostgreSQL connection
#'
#' @return
#' @export
#'
#' @examples
retrieve <- function(connection) {

  if(missing(connection)) {
    stop("a connection must be provided")
  }

  all_tables <- dplyr::db_list_tables(connection)

  tbl_list <- list()

  for (i in 1:length(all_tables)) {

    tbl_list[[i]] <- dplyr::tbl(connection, all_tables[i])

  }

  names(tbl_list) <- all_tables

  return(tbl_list)

  #for (i in 1:length(all_tables)) assign(all_tables[i], table_list[[i]])

}


#' Make reference Table
#'
#' makes the reference table used as the basis for many local (non-database) functions
#' This is to facilitate grouping by site, as this is not present in the
#' episode table
#'
#'
#' @param episodes collected episode table
#' @param provenance collected provenance table
#'
#' @return a tibble with episode level data with site
#' @export
#'
#' @examples
#' make_reference(episodes, provenance)
make_reference <- function(episodes, provenance) {

  left_join(episodes, provenance, by = c("provenance" = "file_id")) %>%
  select(episode_id, nhs_number, start_date, site)

}



#' Produces the core table structure necessary for the data quality report
#'
#' @param events events table
#' @param episodes episodes table
#' @param provenance provenance table
#'
#' @return
#' @export
#'
#' @examples
make_core <- function(events, episodes, provenance) {

  core <- episodes %>%
  left_join(provenance, by = c("provenance" = "file_id")) %>%
  inner_join(events, by = "episode_id")

  return(core)

}


#' make_key <- function(events, episodes, provenance) {
#'
#'   key <- episodes %>%
#'   left_join(provenance, by = c("provenance" = "file_id")) %>%
#'   inner_join(events, by = "episode_id") %>%
#'   select(episode_id, provenance) %>%
#'   collect() %>%
#'   distinct()
#'
#'   return(key)
#'
#' }


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
