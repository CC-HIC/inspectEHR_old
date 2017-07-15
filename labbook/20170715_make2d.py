# Load the ccd object
# Then in one go make a pandas data frame with all 2d data
# Use this for work

# - [ ] @TODO: (2017-07-15) write method of CCD that makes a feather store for 1D and 2D data
#   then deprecate the extract method to extract single, extract from original
#   then write new extract method that just pulls the data from the feather store


import os
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from statsmodels.graphics.mosaicplot import mosaic


from inspectEHR.utils import load_spec
from inspectEHR.CCD import CCD
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin


ccd = CCD(os.path.join('data-raw', 'anon_public_da1000.JSON'), random_sites=True)
ccd_data = ccd.ccd
# ccd = CCD(os.path.join('data-raw', 'anon_internal.JSON'), random_sites=True)
refs = load_spec(os.path.join('data-raw', 'N_DataItems.yml'))

import warnings

# - [ ] @TODO: (2017-07-15)  make a unique key from ccd (just integer would do)
#   use this to index the item_tb table
def extract_2d(ccd, ccd_key = ['site_id', 'episode_id']):
    '''Extracts all data in ccd object to single data frame and stores feather object
    Args:
        ccd: ccd object (data frame with data column containing dictionary of dictionaries)
        ccd_key: unique key to be stored from ccd object; defaults to site/episode
    '''
    # warnings.warn('\n!!! Debugging - only runs first 5 rows')
    dfin = ccd.ccd.head()
    # Check type and key
    assert type(dfin) == pd.core.frame.DataFrame
    try:
        assert all([k in dfin.columns for k in ccd_key])
    except AssertionError as e:
        print('!!! Key {} not found in dataframe columns'.format(ccd_key))
        return e
    except TypeError as e:
        # ccd_key not list?
        print('!!! ccd_key should be a list of column names')
        return e

    df_from_rows = []
    for row in dfin.itertuples():
        df_from_data = []
        row_key = {k:getattr(row, k) for k in ccd_key}
        # print(row_key)
        for i, (nhic, d) in enumerate(row.data.items()):
            # if i > 5:
            #     warnings.warn('\n!!!: Debugging')
            #     break
            if type(d) == dict:  # If 2d then data stored as dict of lists
                df = pd.DataFrame(d)
                df['NHICcode'] = nhic
                df_from_data.append(df)
            # Now add your row key
            df = pd.concat(df_from_data)
            for k,v in row_key.items():
                df[k] = v
            # Now append to list of data constructed from rows
            df_from_rows.append(df)

    df = pd.concat(df_from_rows)
    # print(df.head())
    return df

df2d = extract_2d(ccd)
df2d.head()
df2d.shape

df = df2d.loc[df2d['NHICcode'] == 'NIHR_HIC_ICU_0108']


df2d.reset_index(inplace=True)
df2d.to_feather('data/item_2d.feather')
df_in = pd.read_feather('data/item_tb.feather')
df.dtypes
df.info
