# Labbook for inspectEHR 2017-07-16
"""Remember to place docstrings at the beginnings of your files"""

# - [x] @TODO: (2017-07-16) save as HDF5 instead of feather
# - [ ] @TODO: (2017-07-16) extract_all defaults to saving all objects in hdf5
%pylab
%who
%load_ext autoreload
%autoreload

import pandas as pd

# Load 1d and 2d data
import os
from inspectEHR.utils import load_spec
from inspectEHR.CCD import CCD
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin

# - [ ] @TODO: (2017-07-15)  make a unique key from ccd (just integer would do)
#   use this to index the item_tb table
refs = load_spec(os.path.join('data-raw', 'N_DataItems.yml'))
ccd = CCD(os.path.join('data-raw', 'anon_public_da1000.JSON'), random_sites=True)

help(CCD.extract_all)

df2d = CCD.extract_all(ccd, 2, save2feather=False)
df1d = CCD.extract_all(ccd, 1, save2feather=False)

# os.remove('data/anon_public_da1000.h5')
store = pd.HDFStore('data/anon_public_da1000.h5', mode='w')
print(store)
df1d.name
store.put(str(df1d), df1d)
# store.put('df2d',  df2d)
print(store)

dft = store.get('df1d')
dft.info()
store.close()
