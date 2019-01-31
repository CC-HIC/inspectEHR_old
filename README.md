# inspectEHR

This is the adapted version of inspectEHR to run with a PostgreSQL backend for CC-HIC. Please see the `R` vignettes for further details. InspectEHR is the data validation package for CC-HIC. It's purpose is to apply rules for data validation, and allow for feedback to contributing sites to CC-HIC.

## Acknowledgements
Many thanks to Steve Harris and Roma Klapaukh for their support on this.

## Rules

### Episode Level
- Internal consistency check of episode
  - Each episode has a unique identifier
  - Each episode has a start date
  - Each episode has an end date defined by one of:
	- End of episode date time
	- Death date time
	- Or: is flagged as an "open" episode

### Event Level 1
- Events occur within their episode (with a buffer of 48 hours)
- Events fall within range validation checks - see `qref`
- Events are not duplicates

### Event Level 2
- Co-occurance events:
	  - When systolic and diastolic BP are recorded together, diastolic is lower than systolic
	  - Mean arterial BP, when documented with a systolic and diastolic is approximated by the mathematical derivation of this component
		  
### Event Level 3
- Events that are known to follow a particular distribution, conform to a check of CDF form
- K-S testing checks for significant deviation of a distribution applied as a pairwise testing between ICUs.