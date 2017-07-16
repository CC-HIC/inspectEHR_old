# Labbook for inspectEHR 2017-07-16
"""Remember to place docstrings at the beginnings of your files"""

# - [x] @TODO: (2017-07-16) save as HDF5 instead of feather
# - [ ] @TODO: (2017-07-16) extract_all defaults to saving all objects in hdf5
%pylab
%who
%load_ext autoreload

import pandas as pd

# Load 1d and 2d data
import os
from inspectEHR.utils import load_spec
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin

# - [x] @TODO: (2017-07-15)  make a unique key from ccd (just integer would do)
#   use this to index the item_tb table
# - [ ] @TODO: (2017-07-16) make infotb table with spell and pid information
spec = load_spec(os.path.join('data-raw', 'N_DataItems.yml'))

%autoreload
from inspectEHR.CCD import CCD
filepath = 'data-raw/anon_public_da1000.JSON'
# filepath = 'data/anon_public_da1000.h5'
ccd = CCD(filepath, spec)
ccd.item_2d.info()
ccd = CCD(os.path.join('data-raw', 'anon_public_da1000.JSON'), random_sites=True)
n0108 = ccd.extract_one('NIHR_HIC_ICU_0108', as_type=np.int)
n0108.info()
n0108.head()

# Write extract function for hdf data store items
field = 'NIHR_HIC_ICU_0108'
field = 'NIHR_HIC_ICU_0093'
# given NHICcode  go to spec to get 1d or 2d
%who
item_2d.head()
if spec[field]['dateandtime']:
    df = item_2d[item_2d['NHICcode'] == field]
else:
    df = item_1d[item_1d['NHICcode'] == field]

# Switch off annoying warning message: see https://stackoverflow.com/a/20627316/992999
pd.options.mode.chained_assignment = None  # default='warn'
df['id'] = df['site_id'].astype(str) + df['episode_id'].astype(str)
df.set_index('id', inplace=True)
df.drop(['NHICcode'], axis=1, inplace=True)
# - [ ] @TODO: (2017-07-16) allow other byvars from 1d or infotb items
#   for now leave site_id and episode_id in to permit easy future merge
df['byvar'] = df['site_id']
df.rename(columns={'item2d': 'value'}, inplace=True)
pd.options.mode.chained_assignment = 'warn'  # default='warn'

df.head()

# extract from 1d or 2d
# rename columns
