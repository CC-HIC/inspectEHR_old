# Walk through analysis of 2D cont

# - [ ] @TODO: (2017-07-04) Import JSON version of ccd
# - [ ] @TODO: (2017-07-04) Extract 2D data item into dataframe
# - [ ] @TODO: (2017-07-04) Summarise numerical values
# - [ ] @TODO: (2017-07-04) Plot numerical values (density)
# - [ ] @TODO: (2017-07-04) Summarise numerical values by site
# - [ ] @TODO: (2017-07-04) Plot numerical values by site (density)
# - [ ] @TODO: (2017-07-04) Summarise periods
# - [ ] @TODO: (2017-07-04) Summarise periods by site

# Import
import numpy as np
import pandas as pd
import pandas.api.types as ptypes
from statsmodels.graphics.mosaicplot import mosaic
import statsmodels.api as sm
import matplotlib.pyplot as plt
import os
import seaborn as sns

np.__version__
sns.__version__
pd.__version__

sns.set()
