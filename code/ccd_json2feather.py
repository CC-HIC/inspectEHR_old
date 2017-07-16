# Load the ccd object
# Then in one go make a pandas data frame with all 2d data
# Use this for work

# - [ ] @TODO: (2017-07-15) write method of CCD that makes a feather store for 1D and 2D data
#   then deprecate the extract method to extract single, extract from original
#   then write new extract method that just pulls the data from the feather store


import os
import warnings
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from statsmodels.graphics.mosaicplot import mosaic


from inspectEHR.utils import load_spec
from inspectEHR.CCD import CCD
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin

# - [ ] @TODO: (2017-07-15)  make a unique key from ccd (just integer would do)
#   use this to index the item_tb table
def extract_all(ccd, d1or2=1, ccd_key = ['site_id', 'episode_id'], progress_marker=False):
    '''Extracts all data in ccd object to single data frame and stores feather object
    Args:
        ccd: ccd object (data frame with data column containing dictionary of dictionaries)
        d1or2: [1,2] 1d or 2d data
        ccd_key: unique key to be stored from ccd object; defaults to site/episode
    '''

    # warnings.warn('\n!!! Debugging - only runs first 5 rows')
    # dfin = ccd.ccd.head()
    dfin = ccd.ccd

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

    msg = '\n*** Extracting all {}d data from {} rows'.format(d1or2, dfin.shape[0])
    if d1or2 == 1:
        print(msg)
        return extract_1d(dfin, ccd_key, progress_marker)
    else:
        print(msg)
        return extract_2d(dfin, ccd_key, progress_marker)


def extract_1d(dfin, ccd_key, progress_marker):
    df_from_rows = []
    i = 0

    for row in dfin.itertuples():
        if progress_marker:
            if i%10 == 0:
                print(".", end='')
            i += 1
        df_from_data = []
        row_key = {k:getattr(row, k) for k in ccd_key}

        for i, (nhic, d) in enumerate(row.data.items()):
            # Assumes 2d data stored as dictionary
            if type(d) == dict:
                continue
            else:
                df_from_data.append({'NHICcode': nhic, 'item1d': d})

        df = pd.DataFrame(df_from_data)
        for k,v in row_key.items():
            df[k] = v
        df_from_rows.append(df)

    df = pd.concat(df_from_rows)
    return df

def extract_2d(dfin, ccd_key, progress_marker):
    df_from_rows = []
    i = 0

    for row in dfin.itertuples():

        if progress_marker:
            if i%10 == 0:
                print(".", end='')
            i += 1

        row_key = {k:getattr(row, k) for k in ccd_key}

        try:
            df = row.data
            df = {k:pd.DataFrame.from_dict(v) for k,v in df.items() if type(v) is dict}
            df = pd.concat(df)
            df.reset_index(level=0, inplace=True)
            df.rename(columns={'level_0':'NHICcode'}, inplace=True)

            for k,v in row_key.items():
                df[k] = v
            df_from_rows.append(df)
        except ValueError as e:
            # unable to concatenate, no data?
            print('!!! Value error for {}'.format(row_key))
            print(e)
            continue
        except Exception as e:
            print('!!! Error for {}'.format(row_key))
            print(e)
            continue

    df = pd.concat(df_from_rows)
    return df


if __name__ == "__main__":
    # ccd = CCD(os.path.join('data-raw', 'anon_public_da1000.JSON'), random_sites=True)
    ccd = CCD(os.path.join('data-raw', 'anon_internal.JSON'), random_sites=True)
    ccd_data = ccd.ccd
    refs = load_spec(os.path.join('data-raw', 'N_DataItems.yml'))

    df2d = extract_all(ccd, 2, progress_marker=True)
    # df2d.shape
    # df2d.head()
    df2d.reset_index(inplace=True)
    df2d.to_feather('data/item_2d.feather')

    df1d = extract_all(ccd, 1, progress_marker=True)
    # df1d.shape
    # df1d.head()
    df1d.reset_index(inplace=True)
    df1d.to_feather('data/item_1d.feather')
