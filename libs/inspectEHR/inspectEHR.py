# Functions for inspecting and working with ccd data
import numpy as np
import pandas as pd

# Impute random sites for testing
def gen_rand_sites(d, sites=pd.Series(data=list('ABCDE'))):
    '''
    Generate random sites for index for testing
    '''
    sites = sites.sample(len(d), replace=True).values
    d['site_id'] = sites
    return d

def gen_id(ccd, *args):
    '''Define a unique ID for ccd data
    Defaults to concatenating site and episode IDs

    Args:
        ccd: ccd object imported as pandas dataframe
        cols: columns to concatenate

    Yields:
        pandas dataframe with appropriate index
    '''
    if not args:
        cols = ['site_id', 'episode_id']
    else:
        cols = args
    try:
        assert(all([col in ccd.columns for col in cols]))
    except AssertionError as e:
        print('!!!ERROR: Some of', cols, 'not found in ', ccd.columns)
        return ccd

    # Loop through cols and concatenate
    for i, col in enumerate(cols):
        if i == 0:
            ccd['id'] = ccd[col].astype(str)
        else:
            ccd['id'] = ccd['id'].astype(str) + ccd[col].astype(str)

    # Check unique
    assert not any(ccd.duplicated(subset='id'))
    # Set index
    ccd.set_index('id', inplace=True)
    return ccd


def extract(ccd, nhic_code, byvar="site_id", as_type=None):
    ''' Extract an NHIC data item from the ccd JSON object
    Args:
        ccd: ccd object imported as pandas dataframe
        nhic_code: data item to extract
        byvar: allows reporting / analysis by category, defaults to site

    Yields:
        pandas dataframe
        IDs are stored as id and i (index the row)
        with columns for the data (value) and time (time)
    '''
    x = []
    for r in ccd.itertuples():
        try:
            d = r.data[nhic_code]
            bv = getattr(r,byvar)
            # If 2d then data stored as dict of lists
            if type(d) == dict:
                d = pd.DataFrame(d, index=np.repeat(r.Index, len(d['item2d'])))
                d['byvar'] = bv
            # else data stored as single item
            else:
                d = pd.DataFrame({'item1d': d, 'byvar': bv}, index=[r.Index])
            x.append(d)
        except KeyError:
            x.append(None)
    # Now concatenate all the individual data frames
    x = pd.concat(x)
    # Rename data columns (assumes only 1 of item2d or item1d)
    x.rename(columns={'item2d': 'value', 'item1d': 'value'}, inplace=True)
    # Standardise column order
    # Convert time to timedelta (if 2d)
    if 'time' in x.columns:
        x['time'] = pd.to_timedelta(x['time'], unit='h')
        x = x[['value', 'byvar', 'time']]
    else:
        x = x[['value', 'byvar']]

    # Convert to appropriate np datatype
    if as_type:
        x['value'] = x['value'].astype(as_type)
    return x
