# Example of how to inspect using classes
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os

# Load data as pandas
d1d = pd.read_csv(os.path.join('inspectEHR', 'data', 'height.csv'))
d1d.head()

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

# Base class
class DataRaw(object):
    def __init__(self, dt):
        ''' Initiate and check dataframe with correct rows and dimensions'''
        self.dt = dt

        # Check that this is a pandas data frame
        assert type(self.dt) == pd.core.frame.DataFrame
        # Check core column names
        colnames = ['id', 'site', 'val']
        assert all([i in self.dt.dtypes for i in colnames])
        # Check 1 or more row is present
        self.r, self.c = self.dt.shape
        assert self.r > 0


    def inspect(self):
        '''
        Pass in the values only
        And here is some more stuff
        '''
        print('''Unique episodes ''', len(self.dt['id'].unique()), "available")
        print('''Unique sites ''', len(self.dt['site'].unique()), "available")
        print(self.dt.dtypes)

    def histogram(self):
        # Plot histogram
        self.dt['val'].hist(bins=30)
        plt.show()

    def __str__(self):
        print(self.dt.head())
        print('\n')
        s = ' '.join(["Pandas dataframe with", str(self.r), "rows (first 5 shown)"])
        return s

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

heights = DataRaw(d1d)
print(heights)
heights.dt.head()
heights.inspect()
heights.histogram()

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
