# Extract example data for working on the data quality
rm(list=ls())
library(readr)
library(data.table)
library(cleanEHR)
library(purrr)
getwd()
load("inspectEHR/data-raw/anon_public_da1000.RData")
ls()
print(anon_info)
ccd <- anon_ccd
# Access attributes of ccrecord using @
ccd@nepisodes
ccd@infotb

# Extract data as list from first 10 patients
ccd5 <- lapply(seq(5), function(x) ccd@episodes[[x]]@data)
# ccd5[[1]]
saveRDS(ccd5, 'inspectEHR/data/ccd5.RDS')

# Alternative
# Try extracting by converting ccd to JSON
# install.packages('RJSONIO')
library(RJSONIO)
x <- toJSON(ccd@episodes[[1]])
x <- toJSON(ccd@episodes)
cat(x, file='inspectEHR/data/anon_public_da1000.JSON')

# example extracting 1d data
ccd@episodes[[1]]@data$NIHR_HIC_ICU_0093 # sex
ccd@episodes[[1]]@data$NIHR_HIC_ICU_0017
# example extracting 2d data
ccd@episodes[[1]]@data$NIHR_HIC_ICU_0108

# Now extract all heights
id <-  1:ccd@nepisodes
val <-  as.character(sapply(1:ccd@nepisodes, function(x) ccd@episodes[[x]]@data$NIHR_HIC_ICU_0017))
data1d <- data.table(id,val)
data1d[, site := 'A']
head(data1d)

# Now extract all sex
id <-  1:ccd@nepisodes
val <-  as.character(sapply(1:ccd@nepisodes, function(x) ccd@episodes[[x]]@data$NIHR_HIC_ICU_0093))
data1d_cat <- data.table(id,val)
data1d_cat[, site := 'A']
head(data1d_cat)

# Now extract all heart rates
l = lapply(seq(ccd@nepisodes), function(x) data.table(id=x, ccd@episodes[[1]]@data$NIHR_HIC_ICU_0108))
data2d <- rbindlist(l)
head(data2d)
setnames(data2d,'item2d','val')
data2d[, site := 'A']

library(readr)

# Simulate different sites
str(data1d)
data1d[250:499, site := 'B']
data1d[500:749, site := 'C']
data1d[750:1000, site := 'D']
table(data1d$site)
write_csv(data1d, 'inspectEHR/data/height.csv')

# Simulate different sites
str(data1d_cat)
data1d_cat[250:499, site := 'B']
data1d_cat[500:749, site := 'C']
data1d_cat[750:1000, site := 'D']
table(data1d_cat$site)
write_csv(data1d_cat, 'inspectEHR/data/sex.csv')


data2d[id %in% c(250:499), site := 'B']
data2d[id %in% c(500:749), site := 'C']
data2d[id %in% c(750:1000), site := 'D']
table(data2d$site)
write_csv(data2d, 'inspectEHR/data/hrate.csv')
