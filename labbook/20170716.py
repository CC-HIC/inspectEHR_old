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

# - [x] @TODO: (2017-07-15)  make a unique key from ccd (just integer would do)
#   use this to index the item_tb table
# - [ ] @TODO: (2017-07-16) make infotb table with spell and pid information

refs = load_spec(os.path.join('data-raw', 'N_DataItems.yml'))
ccd = CCD(os.path.join('data-raw', 'anon_public_da1000.JSON'), random_sites=True)

help(CCD.extract_all)
ccd.ccd.head()
ccd.ccd.iloc[1]['data']['spell']
ccd.ccd.iloc[1]['data']['pid']

infotb = ccd.ccd['']
cols_2drop = ['data']
cols_2keep = [i for i  in ccd.ccd.columns if i not in cols_2drop]; cols_2keep
rows_out = []
for row in ccd.ccd.itertuples():
    row_in = row._asdict()
    row_out = {k:v for k,v in row_in.items() if k != 'data'}
    row_out['spell'] = row_in['data']['spell']
    row_out['pid'] = row_in['data']['pid']
    rows_out.append(row_out)
infotb = pd.DataFrame(rows_out)
infotb.head()
cols_timedelta = ['t_admission', 't_discharge', 'parse_time']
for col in cols_timedelta:
    infotb[col] = pd.to_timedelta(infotb[col], unit='s')
# infotb['t_admission'] = pd.to_timedelta(infotb['t_admission'], unit='s')
# infotb['t_discharge'] = pd.to_timedelta(infotb['t_discharge']/3600, unit='h')
infotb.head()



[lambda col: info_tb[col] = pd.to_timedelta(infotb[col], unit='h') for col in cols_timedelta]


ccd.ccd.iloc[1]['data']['spell']
ccd.ccd.iloc[1]['data']['pid']




}df2d = CCD.extract_all(ccd, 2, save2feather=False)
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
