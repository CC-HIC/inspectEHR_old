# Example of how to inspect using classes
import numpy as np
import pandas as pd
import pandas.api.types as ptypes
from statsmodels.graphics.mosaicplot import mosaic
import statsmodels.api as sm
import matplotlib.pyplot as plt
import os

# Load data as pandas
d1d = pd.read_csv(os.path.join('inspectEHR', 'data', 'height.csv'))
d1d.head()
d1d_cat = pd.read_csv(os.path.join('inspectEHR', 'data', 'sex.csv'))
d1d_cat.head()

d2d = pd.read_csv(os.path.join('inspectEHR', 'data', 'hrate.csv'))
d2d.head()

# - [ ] @TODO: (2017-06-27) add metadata passing where metadata contains info
# about how to manage that item
# - [ ] @TODO: (2017-06-27) add error checking to make sure data contains expected columns

type(d1d)
r, c = d1d.shape
r > 0
s = ' '.join(["Pandas dataframe with", str(r), "rows"])
print(s)

d = pd.DataFrame({'x': range(5), 'y': [0.0,0.1,0.2,0.3,0.5]})
d.dtypes
assert ptypes.is_any_int_dtype(d['x']) | ptypes.is_float_dtype(d['y'])

# Numerical summary
d1d['val'].describe()
d1d['val'].plot(kind='hist', bins=30)
plt.show()

# Seaborn
import seaborn as sns
sns.set()
d1d['val'].hist()
plt.show()
sns.kdeplot(d1d['val'])
plt.show()
d1d['val'].hist()



# Contingency table
pd.crosstab(d1d_cat['site'], d1d_cat['val'])
pd.crosstab(d1d_cat['site'], d1d_cat['val']).apply(lambda r: 100*r/r.sum(), axis=1)
p = mosaic(d1d_cat, ['site','val'])
plt.show()



# Base class
class DataRaw(object):
    def __init__(self, dt):
        ''' Initiate and check dataframe with correct rows and dimensions'''
        self.dt = dt

        # Basic sanity checks
        # Check that this is a pandas data frame
        assert type(self.dt) == pd.core.frame.DataFrame
        # Check core column names
        colnames = ['id', 'site', 'val']
        assert all([i in self.dt.dtypes for i in colnames])
        # Check 1 or more row is present
        self.r, self.c = self.dt.shape
        assert self.r > 0

    def __str__(self):
        ''' Print helpful summary of object '''
        print(self.dt.head())
        print('\n')
        s = ' '.join(["Pandas dataframe with", str(self.r), "rows (first 5 shown)"])
        return s

    # tabulate values
    def tab(self):
        ''' Tabulate data (if categorical)'''
        # Contingency table
        assert ptypes.is_string_dtype(self.dt['val'])
        return pd.value_counts(self.dt['val'])

    # tabulate by site
    def tab_sites(self):
        ''' Tabulate data (if categorical) by site'''
        # use statsmodels mosaic
        assert ptypes.is_string_dtype(self.dt['val'])
        mosaic(d1d_cat, ['val','site'])
        plt.show()
        return pd.crosstab(self.dt['site'], self.dt['val'])

    def summ(self):
        ''' Summarise data (if numerical)'''
        assert ptypes.is_any_int_dtype(self.dt['val']) \
            | ptypes.is_float_dtype(self.dt['val'])
        return self.dt['val'].describe()

    def inspect(self):
        '''
        Pass in the values only
        And here is some more stuff
        '''
        print('''Unique episodes ''', len(self.dt['id'].unique()), "available")
        print('''Unique sites ''', len(self.dt['site'].unique()), "available")
        print(self.dt.dtypes)

    def density(self):
        # Plot histogram
        assert ptypes.is_any_int_dtype(self.dt['val']) \
            | ptypes.is_float_dtype(self.dt['val'])
        sns.kdeplot(self.dt['val'])
        plt.show()



class Data1D(DataRaw):
    ''' A 1d version of data raw '''
    def __init__(self, dt):
        DataRaw.__init__(self, dt)
        print('made some 1d')


class Data2D(DataRaw):
    ''' A 2d version of data raw '''
    def __init__(self, dt):
        DataRaw.__init__(self, dt)
        # Check time provided
        assert 'time' in self.dt.dtypes
        print(self.dt.head())

sex = Data1D(d1d_cat)
sex.tab()
sex.tab_sites()

heights = Data1D(d1d)
heights.summ()

heights.dt.head()
heights.inspect()
heights.summ()
heights.density()

# type(heights.val)
# heights.val.mean()
#
# print("here's looking at you")
# print(heights)

heights = Data1D(d1d)
heights.inspect()

hrates = Data2D(d2d)
hrates.inspect()
hrates.histogram()
