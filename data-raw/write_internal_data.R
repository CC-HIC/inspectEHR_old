## qref

# you will need to modify this to the right path.
# qref <- read_csv(path = "/_dev/dataQualityReport/quality_reference_090518.csv")

## hic classes

preserved_classes <- makeDict(metadata) %>%
  mutate(class = paste(primary_column, type, sep = "_")) %>%
  distinct(class) %>%
  pull

devtools::use_data(qref, preserved_classes, internal = TRUE, overwrite = TRUE)
