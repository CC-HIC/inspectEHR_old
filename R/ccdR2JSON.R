# 2017-07-27
# Written and tested in IDHS then exported out
library(methods)
library(cleanEHR)
library(jsonlite)

# path to current database in IDHS
load('/data/current_db')
ccd <- alldata@episodes

# ccdl list of episodes in ccd
ccdl <- list()

for (i in 1:length(ccd)) {
	# ccdi: ccd episode in (as R)
	ccdi <- ccd[[i]]
	# ccdi: ccd episode out (as JSON)
	ccdo <- sapply(slotNames(ccdi), function(x) slot(ccdi, x))
	# Copy names hence becomes python dictionary via JSON
	names(ccdo) <- slotNames(ccdi)
	# progress marker
	print(paste(sprintf('%06.0f', i), ccdo$site_id,ccdo$episode_id))
	# append ot list out
	# need to append starting at zero after resets else JSON pads out ids
	j <- i %% 1000
	ccdl[[j]] <- ccdo
	if (i %% 1000 == 0) {
		# Saves every 1000 episodes
		ccdj <- jsonlite::toJSON(ccdl, dataframe='columns', auto_unbox=TRUE)
		cat(ccdj, file=paste0('alldata', sprintf('%06.0f', i), '.JSON'))
		# Reset list to protect memory
		ccdl <- list()
	}

}

# Save final piece
ccdj <- jsonlite::toJSON(ccdl, dataframe='columns', auto_unbox=TRUE)
cat(ccdj, file=paste0('alldata', sprintf('%06.0f', i), '.JSON'))
