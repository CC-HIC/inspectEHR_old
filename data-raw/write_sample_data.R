# Lets make some sample data

# categorical
df_1d <- tibble(
  internal_id = 1:5000,
  episode_id = sample(1:250, 5000, replace = TRUE),
  site = rep(c("UCL", "Imperial", "Oxford", "GSTT", "Cambridge"), each = 1000),
  code_name = "NHIC_demo",
  value = rbinom(5000, prob = 0.8, size = 1),
  out_of_bounds = rep(0L, 5000),
  duplicate = rep(0L, 5000),
  range_error = rep(0L, 5000)
)

attr(df_1d, "code_name") <- "NIHR_HIC_ICU_0026"
class(df_1d) <- append(class(df_1d), "string_1d", after = 0)

#=======

# date
df_date <- tibble(
  internal_id = 1:5000,
  episode_id = sample(1:250, 5000, replace = TRUE),
  site = rep(c("UCL", "Imperial", "Oxford", "GSTT", "Cambridge"), each = 1000),
  code_name = "NIHR_HIC_ICU_0406",
  date = rep(
    seq.Date(from = ymd("2014-01-01"), to = ymd("2016-09-26"), by = "day"), 5),
  value = c(
    rnorm(1000, mean = 145, sd = 0.1),
    rnorm(1000, mean = 147, sd = 0.4),
    rnorm(1000, mean = 142, sd = 0.5),
    rnorm(1000, mean = 144, sd = 2),
    rnorm(1000, mean = 144.5, sd = 1)),
  out_of_bounds = rep(0L, 5000),
  duplicate = rep(0L, 5000),
  range_error = rep(0L, 5000)
)

attr(df02, "code_name") <- "NIHR_HIC_ICU_0406"
class(df02) <- append(class(df02), "date_1d", after = 0)



#=======

# numeric 2d
df_numeric_2d <- tibble(
  internal_id = 1:5000,
  episode_id = sample(1:250, 5000, replace = TRUE),
  site = rep(c("UCL", "Imperial", "Oxford", "GSTT", "Cambridge"), each = 1000),
  code_name = "NIHR_HIC_ICU_0406",
  date = rep(
    seq.Date(from = ymd("2014-01-01"), to = ymd("2016-09-26"), by = "day"), 5),
  value = c(
    rnorm(1000, mean = 145, sd = 0.1),
    rnorm(1000, mean = 147, sd = 0.4),
    rnorm(1000, mean = 142, sd = 0.5),
    rnorm(1000, mean = 144, sd = 2),
    rnorm(1000, mean = 144.5, sd = 1)),
  out_of_bounds = rep(0L, 5000),
  duplicate = rep(0L, 5000),
  range_error = rep(0L, 5000)
)

attr(df02, "code_name") <- "NIHR_HIC_ICU_0406"
class(df02) <- append(class(df02), "date_1d", after = 0)
