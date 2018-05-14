#' Pairwise Kolmogorov-Smirnov Test
#'
#' This takes an extract data item from CC-HIC and returns
#' the pairwise KS test by site.
#'
#' @param x extracted data item
#' @param site
#'
#' @return
#' @export
#'
#' @importFrom rlang .data
#' @importFrom magrittr %>% %<>%
#'
#' @examples
#' ks_test(heart_rates)
ks_test <- function(x) {

  sites <- x %>%
    dplyr::distinct(.data$site) %>%
    dplyr::pull()

  site_pairs <- sites %>%
    utils::combn(2)

  ks_list <- base::vector(
    mode = "list",
    length = base::ncol(site_pairs)
  )

  for (i in 1:ncol(site_pairs)) {
    ks_list[[i]] <- ks.test(x = x %>%
                              filter(.data$site == site_pairs[,i][1]) %>%
                              select(.data$value) %>%
                              pull,
                            y = x %>%
                              filter(.data$site == site_pairs[,i][2]) %>%
                              select(.data$value) %>%
                              pull)
  }

  site_pairs_t <- t(site_pairs) %>%
    as.tibble()

  names(site_pairs_t) <- c("site_a", "site_b")

  site_pairs_t %<>%
    mutate(paired_name = paste(.data$site_a, .data$site_b, sep = "-")) %>%
    select(.data$paired_name) %>%
    pull

  names(ks_list) <- site_pairs_t

  df <- purrr::map(ks_list, .f = broom::tidy) %>%
    dplyr::bind_rows(.id = "source") %>%
    tidyr::separate(source, into = c("Site_A", "Site_B"), sep = "-")

  return(df)

}


ks_plot <- function(x) {

  x %<>%
    ggplot(
      aes(
        x = .data$Site_A, y = .data$Site_B, fill = .data$p.value)) +
    geom_tile() +
    scale_x_discrete(limits=c("cambridge", "gstt", "imperial", "ucl", "oxford")) +
    scale_y_discrete(limits=c("cambridge", "gstt", "imperial", "ucl", "oxford"))

  return(x)

}




