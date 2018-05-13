context("basic validation flags")
library(inspectEHR)

test_that("duplicates are correctly identified", {
  expect_true(flag_duplicate_2d(hr) %>% filter(duplicate != 0) %>% length != 0)
})
