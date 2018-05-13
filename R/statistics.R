# df <- tibble(
#  ucl = rnorm(n = 1000, mean = 90, sd = 8),
#  imperial = rnorm(n = 1000, mean = 89, sd = 7.5),
#  gstt = rnorm(n = 1000, mean = 100, sd = 9),
#  cambridge = rnorm(n = 1000, mean = 91, sd = 8.1),
#  oxford = rnorm(n = 1000, mean = 90.5, sd = 8.2)
# )
#
# df %<>%
#   gather()

ks_test <- function(x, key, value) {

  user_key <- enquo(key)
  user_value <- enquo(value)

  sites <- x %>%
    distinct(!!user_key) %>%
    pull

  site_pairs <- sites %>%
    combn(2)

  ks_list <- vector(mode = "list", length = ncol(site_pairs))

  for (i in 1:ncol(site_pairs)) {
    ks_list[[i]] <- ks.test(x = x %>%
                              filter(!!user_key == site_pairs[,i][1]) %>%
                              select(!!user_value) %>%
                              pull,
                            y = x %>%
                              filter(!!user_key == site_pairs[,i][2]) %>%
                              select(!!user_value) %>%
                              pull)
  }

  site_pairs_t <- t(site_pairs) %>%
    as.tibble()

  names(site_pairs_t) <- c("site_a", "site_b")

  site_pairs_t %<>%
    mutate(paired_name = paste(site_a, site_b, sep = "-")) %>%
    select(new_name) %>%
    pull

  names(ks_list) <- site_pairs_t

  df <- map(ks_list, .f = tidy) %>%
    bind_rows(.id = "source") %>%
    separate(c("A", "B"), sep = "-")

  # df4 <- cbind(df2, df3)
  #
  # df4 %<>%
  #   rename("Site_A" = "1",
  #          "Site_B" = "2") %>%
  #   arrange(Site_A, Site_B)


}


ks_plot <- function(x) {

  x %>%
    rename("Site_B" = "Site_A",
           "Site_A" = "Site_B") %>%
    select(source:alternative, Site_A, Site_B) %>%
    rbind(df4) %>%
    ggplot(aes(x = Site_A, y = Site_B, fill = p.value)) +
    geom_tile() +
    scale_x_discrete(limits=c("cambridge", "gstt", "imperial", "ucl", "oxford")) +
    scale_y_discrete(limits=c("cambridge", "gstt", "imperial", "ucl", "oxford"))

}




