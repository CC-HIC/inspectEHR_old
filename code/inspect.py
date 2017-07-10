# Example of how to inspect using classes
import os
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from statsmodels.graphics.mosaicplot import mosaic

os.chdir('./inspectEHR')

from inspectEHR.utils import load_spec
from inspectEHR.CCD import CCD
from inspectEHR.data_classes import DataRaw, Data1D, Data2D, DataContMixin, DataCatMixin


ccd = CCD(os.path.join('data-raw', 'anon_public_da1000.JSON'),
          random_sites=True)
refs = load_spec(os.path.join('data-raw', 'N_DataItems.yml'))


# Generate data for testing
# Heart rate
n0108 = ccd.extract('NIHR_HIC_ICU_0108', as_type=np.int)
# Lactate
n0122 = ccd.extract('NIHR_HIC_ICU_0122', as_type=np.float)
# Sex
n0093 = ccd.extract('NIHR_HIC_ICU_0093', as_type=np.str)


%load_ext autoreload
%autoreload
from inspectEHR.data_classes import DataRaw, Data1D, Data2D, DataContMixin, DataCatMixin

# Trying dynamic class initiation to make available the correct methods
# d0108 = DataRaw(n0108, refs['NIHR_HIC_ICU_0108'])
d0108 = DataRaw(dt=n0108, spec=refs['NIHR_HIC_ICU_0108'], mixin=DataContMixin)
print(d0108)
d0108.inspect()
d0108.plot()
d0093 = DataRaw(n0093, refs['NIHR_HIC_ICU_0093'], mixin=DataCatMixin)
print(d0093)
d0093.inspect()
d0093.plot()

type(d0108)
print(d0108)

# d0108 = Data1D(n0108, refs['NIHR_HIC_ICU_0108'])
# d0108 = Data2D(n0108, refs['NIHR_HIC_ICU_0108'])
d0108.dt.head()
d0108.dt.describe()
d0108.dt['value'].isnull().sum()
d0108.dt['byvar'].value_counts()


d0108.dt['value'].value_counts(sort=True)
d0108.dt['value'].value_counts().sort_index().iloc[:5]
d0108.dt['value'].value_counts().sort_index().iloc[-5:]

d0108.dt['value'].value_counts(normalize=True)





d0108.d1d
print(d0108.nrow,d0108.ncol)
d0108.dt.head(2)
d0108.id_nunique
print(d0108)

d0093 = DataRaw(n0093)
d0093.value_nmiss
d0093.dt['value'].isnull().sum()


# Load example data as pandas
# d1d = pd.read_csv(os.path.join('inspectEHR', 'data', 'height.csv'))
# d1d.head()
# d1d_cat = pd.read_csv(os.path.join('inspectEHR', 'data', 'sex.csv'))
# d1d_cat.head()
# d2d = pd.read_csv(os.path.join('inspectEHR', 'data', 'hrate.csv'))
# d2d.head()

# demo data
# d = pd.DataFrame({'x': range(5), 'y': [0.0,0.1,0.2,0.3,0.5]})
# assert ptypes.is_any_int_dtype(d['x']) | ptypes.is_float_dtype(d['y'])


# Numerical summary
type(d1d['val'].describe())
d1d['val'].plot(kind='hist', bins=30)
d1d['val'].describe()

# Seaborn
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


sex = DataCat(d1d_cat)
sex.tab()
sex.tab_sites()

heights = DataCont(d1d)
heights.summ()
heights.density()
heights.inspect()
print(heights)


# type(heights.val)
# heights.val.mean()
#
# print("here's looking at you")
# print(heights)

heights = Data1D(d1d)
heights.inspect()

hrates = Data2D_Cont(d2d)
hrates.inspect()
hrates.density()
hrates.summ()
print(hrates)
