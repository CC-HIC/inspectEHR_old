df <- tibble(
 ucl = rnorm(n = 1000, mean = 90, sd = 8),
 imperial = rnorm(n = 1000, mean = 89, sd = 7.5),
 gstt = rnorm(n = 1000, mean = 100, sd = 9),
 cambridge = rnorm(n = 1000, mean = 91, sd = 8.1),
 oxford = rnorm(n = 1000, mean = 90.5, sd = 8.2)
)

ks_test <- function(x) {

  x %<>%
    gather()

  mm <- df %>%
    distinct(key) %>%
    pull %>%
    combn(2)

  ks_list <- vector(mode = "list", length = ncol(mm))

  for (i in 1:ncol(mm)) {
    ks_list[[i]] <- ks.test(x = df %>%
                              filter(key == mm[,i][1]) %>%
                              select(value) %>%
                              pull,
                            y = df %>%
                              filter(key == mm[,i][2]) %>%
                              select(value) %>%
                              pull)
  }

  zz <- t(mm) %>%
    as.tibble()

  names(zz) <- c("site_a", "site_b")

  zz %<>%
    mutate(new_name = paste(site_a, site_b, sep = "-")) %>%
    select(new_name) %>%
    pull

  names(ks_list) <- zz

  ks_list

  df2 <- map(ks_list, .f = tidy) %>%
    bind_rows(.id = "source")

  df3 <- str_split_fixed(df2$source, pattern = "-", 2)

  df4 <- cbind(df2, df3)

  df4 %<>%
    rename("Site_A" = "1",
           "Site_B" = "2") %>%
    arrange(Site_A, Site_B)




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




