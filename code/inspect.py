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
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin


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
# Height
n0017 = ccd.extract('NIHR_HIC_ICU_0017', as_type=np.str)


%load_ext autoreload
%autoreload
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin

# Trying dynamic class initiation to make available the correct methods
# d0108 = DataRaw(n0108, refs['NIHR_HIC_ICU_0108'])
d0108 = DataRaw(n0108, spec=refs['NIHR_HIC_ICU_0108'])
# d0108 = DataRaw(n0108, refs['NIHR_HIC_ICU_0108'])
type(d0108)
d0108.spec
print(d0108)
d0108.inspect()
d0108.plot()
d0108.plot(by=True)


# Method for plotting using byvar
# dt = d0108.dt
# for name, grp in dt.groupby('byvar'):
#     sns.kdeplot(dt['value'])
# plt.show()




d0093 = DataRaw(n0093, spec=refs['NIHR_HIC_ICU_0093'])
print(d0093)
d0093.inspect()
d0093.plot()
d0093.plot(by=True)
dt = d0093.dt
dt.head()
dt['value']
sns.countplot(dt['value'])
dt['value'].plot(kind='bar')
plt.show()


type(d0108)
print(d0108)
