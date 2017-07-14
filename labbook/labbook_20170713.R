# Extract example data for working on the data quality
rm(list=ls())
library(readr)
library(data.table)
library(cleanEHR)
library(purrr)

data_path <- "/Users/steve/projects/ac-CCHIC/data-mx/releases/2017-02-21t1512/anon_internal.RData"

getwd()
load(data_path)
ls()
print(anon_info)
ccd <- anon_ccd
# Access attributes of ccrecord using @
ccd@nepisodes
ccd@infotb

saveRDS(ccd, 'inspectEHR/data-raw/anon_internal.RDS')

# - [ ] @NOTE: (2017-07-13)
# Cannot save as feather since not a dataframe
# install.packages('feather')
# library(feather)
# write_feather(ccd, 'inspectEHR/data-raw/anon_internal.feather')


source("https://bioconductor.org/biocLite.R")
biocLite("rhdf5")
library(rhdf5)
f <- 'inspectEHR/data-raw/anon_internal.h5'
h5createFile(f)
h5createGroup(f, 'ccd')

# H5Adelete(f, ccd)
# ccd@episodes[[1]]@data
h5write(ccd@episodes[[1]]@data, f, 'foo')
h5ls(f)

ccd5 <- lapply(seq(5), function(x) ccd@episodes[[x]]@data)
h5save(ccd5, file=f)
h5ls(f)

devtools::session_info()
devtools::install_github('mannau/h5')
library(h5)
h5_file <- h5file('inspectEHR/data-raw/anon_internal.h5')
h5_file['test/ccd'] <- ccd

# Try extracting by converting ccd to JSON
# install.packages('RJSONIO')
library(RJSONIO)
x <- toJSON(ccd@episodes[[1]])
x <- toJSON(ccd@episodes)
cat(x, file='inspectEHR/data-raw/anon_internal.JSON')
