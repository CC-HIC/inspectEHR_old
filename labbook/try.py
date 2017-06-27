import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

import os

d1d = pd.read_csv(os.path.join('inspectEHR', 'data', 'height.csv'))
d1d.head()
d2d = pd.read_csv(os.path.join('inspectEHR', 'data', 'hrate.csv'))
d2d.head()


d1d['val'].describe()
d1d['val'].min()
d1d['val'].max()
d1d['val'].quantile([0.25,0.5,0.75])
d1d.val.describe()


d1d.loc[500:, 'site'] = 'B'
d1d['site'].value_counts()
d1d.groupby('site')['val'].count()

# Missing
d1d.loc[d1d['id'] > 4, ['val','site']]
d1d.loc[d1d['val'].notnull() , ['val','site']]

# Plot histogram
d1d['val'].hist(bins=30)
d1d['val'].plot()
d1d.plot.scatter('id','val')
plt.show()

# dtypes
d1d.dtypes


# 2d inspection
d2d.head()
d2d['time_new'] = pd.to_timedelta(d2d['time'] * 3600, unit='s')
d2d.head()
d2d.dtypes


len(d2d['val'].values)
d2d.values.shape
d2d['val'].values.shape

# doing times series stuff
# nice library called arrow
# import arrow
# base_time = arrow.utcnow()
# type(base_time)

import datetime
base_time = datetime.datetime.utcnow()
base_time
d2d['datetime'] = base_time + d2d['time_new']
d2d.head()

# plot
dt = d2d.loc[d2d['id'] < 3]
plt.plot(dt['datetime'], dt['val'])
plt.show()

# plot
for i in range(5):
    plt.plot(np.random.rand(100))
    # dt = d2d.loc[d2d['id'] == i]
    # plt.plot(dt['datetime'], dt['val'])

plt.show()
