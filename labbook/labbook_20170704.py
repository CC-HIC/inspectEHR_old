# Walk through analysis of 2D cont

# Notes
# - use pandas, seaborn for graphics (then customise with matplotlib)

# - [x] @TODO: (2017-07-04) Import JSON version of ccd
# - [x] @TODO: (2017-07-04) Extract 2D data item into dataframe
# - [x] @TODO: (2017-07-04) Summarise numerical values
# - [x] @TODO: (2017-07-04) Plot numerical values (density)
# - [ ] @TODO: (2017-07-04) generate dummy sites
# - [x] @TODO: (2017-07-05) switch to single index (simpler)
# - [x] @TODO: (2017-07-05) add category for cross classifying (default site)
# - [ ] @TODO: (2017-07-04) Summarise numerical values by site
# - [ ] @TODO: (2017-07-04) Plot numerical values by site (density)
# - [ ] @TODO: (2017-07-04) Summarise periods
# - [ ] @TODO: (2017-07-04) Summarise periods by site

# Import
import numpy as np
import pandas as pd
import seaborn as sns
import statsmodels.api as sm
import matplotlib.pyplot as plt
import os
import json

from statsmodels.graphics.mosaicplot import mosaic

# Global variables
ccd_file = "inspectEHR/data/anon_public_da1000.JSON"

np.__version__
sns.__version__
pd.__version__

# Set up pandas
idx = pd.IndexSlice

# Set up seaborn
sns.reset_defaults()
sns.set()

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
    # Convert time to timedelta (if 2d)
    if 'time' in x.columns:
        x['time'] = pd.to_timedelta(x['time'], unit='h')
    # Convert to appropriate np datatype
    if as_type:
        x['value'] = x['value'].astype(as_type)
    return x


# Import data
with open(ccd_file, 'r') as f:
    ccd = pd.read_json(f)

# Generate a range of sites and set up unique identifier
ccd = gen_rand_sites(ccd)
ccd = gen_id(ccd)

ccd.head()

# Heart rate
n0108 = extract(ccd, 'NIHR_HIC_ICU_0108', as_type=np.int)
# Lactate
n0122 = extract(ccd, 'NIHR_HIC_ICU_0122', as_type=np.float)
# Sex
n0093 = extract(ccd, 'NIHR_HIC_ICU_0093', as_type=np.str)

n0108.iloc[:1]
n0093.iloc[:1]
n0122.iloc[:1]

# Count missing data by episode


# Describe
n0122.head()
n0122['item2d'].describe()

# Plot
# - [ ] @TODO: (2017-07-05) work out if legend corresponds to colours
sns.set_style('white')
sns.set_palette('husl')
for i, grp in n0122.groupby('byvar'):
    sns.kdeplot(grp['item2d'], shade=True)
plt.legend(n0122['byvar'].unique())
plt.show()
