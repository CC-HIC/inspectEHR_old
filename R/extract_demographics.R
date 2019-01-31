#' Extract 1d data from CC-HIC
#'
#' @param metadata a database metadata table
#' @param events a database events table
#' @param codes a character vector of HIC codes you want to retrieve
#'
#' @export
#'
#' @return A tibble of 1d data
#' @examples
#' extract_demographics(tbls[["variables"]], tbls[["events"]])
extract_demographics <- function(metadata = NULL, events = NULL, codes = "NIHR_HIC_ICU_0093") {

  demographics <- metadata %>%
    collect() %>%
    dplyr::mutate(nas = metadata %>%
                    dplyr::select(-code_name, -long_name, -primary_column) %>%
                    collect() %>%
                    tibble::as.tibble() %>%
                    apply(1, function(x) sum(!is.na(x)))) %>%
    dplyr::filter(nas == 1) %>%
    dplyr::select(code_name, primary_column)

  code_names <- demographics$code_name

  tb_base <- events %>%
    select(episode_id, code_name, integer, string, real, date, time, datetime) %>%
    filter(code_name %in% code_names) %>%
    collect()

  tb_1_strings <- tb_base %>%
    select(code_name, string, episode_id) %>%
    inner_join(demographics %>%
                 filter(primary_column == "string"), by = "code_name") %>%
    select(-primary_column) %>%
    spread(key = code_name, value = string)

  tb_1_ints <- tb_base %>%
    select(code_name, integer, episode_id) %>%
    inner_join(demographics %>%
                 filter(primary_column == "integer"), by = "code_name") %>%
    select(-primary_column) %>%
    spread(key = code_name, value = integer)

  tb_1_real <- tb_base %>%
    select(code_name, real, episode_id) %>%
    inner_join(demographics %>%
                 filter(primary_column == "real"), by = "code_name") %>%
    select(-primary_column) %>%
    spread(key = code_name, value = real)

  tb_1_dates <- tb_base %>%
    select(code_name, date, episode_id) %>%
    inner_join(demographics %>%
                 filter(primary_column == "date"), by = "code_name") %>%
    select(-primary_column) %>%
    spread(key = code_name, value = date)

  tb_1_time <- tb_base %>%
    select(code_name, time, episode_id) %>%
    inner_join(demographics %>%
                 filter(primary_column == "time"), by = "code_name") %>%
    select(-primary_column) %>%
    spread(key = code_name, value = time)

  tb_1_datetime <- tb_base %>%
    select(code_name, datetime, episode_id) %>%
    inner_join(demographics %>%
                 filter(primary_column == "datetime"), by = "code_name") %>%
    select(-primary_column) %>%
    spread(key = code_name, value = datetime)

  db_1 <- reduce(
    list(tb_1_strings,
         tb_1_ints,
         tb_1_real,
         tb_1_dates,
         tb_1_datetime,
         tb_1_time),
    full_join, by = "episode_id")

  db_1 <- select(db_1, episode_id, !!! codes)

  return(db_1)

}
