import sys
print(sys.version)
import numpy as np
import pandas as pd
from rpy2.rinterface import R_VERSION_BUILD
print(R_VERSION_BUILD)
import rpy2 as rp
rp.__version__
rp.__path__

# initialises and starts embedded R
print(1)
import rpy2.robjects as robjects
pd.__version__
import matplotlib.pyplot as plt

N = int(1E3)
# Now make a timeseries for heart rate
df = pd.DataFrame({
    'time': pd.date_range('20170520',periods=N,freq='10min'),
    'id': np.repeat([1,2,3,4,5],N/5),
    'hrate': np.floor((np.random.randn(N) * 20) + 100 ) })

# Now replace random sample with missing
df.loc[df.sample(frac=0.3).index, 'hrate'] = None
df.head(10)
# df['hrate'].describe()

# Next steps
# Report cadence
def mean_diff(df, t='time', dropna=True):
    '''
    Return mean difference of a timeseries
    Expects a DataFrame with a time index
    '''
    if dropna:
        this_df = df.dropna()
    else:
        this_df = df
    result = np.mean( this_df[t] - this_df.shift(1)[t] )
    return result


df.head()
len(df)

mean_diff(df)
mean_diff(df, dropna=False)


# extract times where hrate is not missing
t = df[df['hrate'].isnull() == False]

# Difference the time series
t.diff()

# Categorise by site
