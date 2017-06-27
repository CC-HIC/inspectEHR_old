# Example of how to inspect using classes
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import os

d1d = pd.read_csv(os.path.join('inspectEHR', 'data', 'height.csv'))
d1d.head()
print('''Unique episodes ''', len(d1d['id'].unique()), "available")
len(d1d['id'].unique())
d2d = pd.read_csv(os.path.join('inspectEHR', 'data', 'hrate.csv'))
d2d.head()
d1d['val']
d1d['val'].head()
d1d.dtypes

class DataRaw(object):
    def __init__(self, dt):
        self.dt = dt
        self.val = self.dt['val']
        # print(self.val)
        print('It worked')

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





    # def __str__(self):
    #     return "here's looking at you"

class Data1D(DataRaw):
    ''' A 1d version of data raw '''
    def __init__(self, dt):
        DataRaw.__init__(self, dt)
        print('made some 1d')

class Data2D(DataRaw):
    ''' A 2d version of data raw '''
    def __init__(self, dt):
        DataRaw.__init__(self, dt)
        print('made some 2d')

heights = DataRaw(d1d)
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
