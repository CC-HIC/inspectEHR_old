# Extract example data for working on the data quality
rm(list=ls())
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

# example extracting 2d data
ccd@episodes[[1]]@data$NIHR_HIC_ICU_0017
# example extracting 2d data
ccd@episodes[[1]]@data$NIHR_HIC_ICU_0108

# Now extract all heights
id <-  1:ccd@nepisodes
val <-  as.character(sapply(1:ccd@nepisodes, function(x) ccd@episodes[[x]]@data$NIHR_HIC_ICU_0017))
data1d <- data.table(id,val)
data1d[, site := 'A']
head(data1d)

# Now extract all heart rates
l = lapply(seq(ccd@nepisodes), function(x) data.table(id=x, ccd@episodes[[1]]@data$NIHR_HIC_ICU_0108))
data2d <- rbindlist(l)
head(data2d)
setnames(data2d,'item2d','val')
data2d[, site := 'A']

library(readr)
write_csv(data1d, 'inspectEHR/data/height.csv')
write_csv(data2d, 'inspectEHR/data/hrate.csv')
