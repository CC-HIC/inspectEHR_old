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
    '''
    Extract an NHIC data item from the ccd JSON
    Data is stored in a list
    IDs are stored as id and i (index the row)
    byvar allows reporting / analysis by category, defaults to site
    '''
    x = []
    for i, r in ccd.iterrows():
        try:
            d = pd.DataFrame(r['data'][nhic_code])
            d['byvar'] = r[byvar]
            x.append(d)
        except KeyError:
            x.append(None)
    # Now concatenate all the individual data frames
    # Using the site and episode_id as a multikey
    x = pd.concat(x, keys=ccd.index)
    # Label index
    x.index.set_names(['id','i'], inplace=True)
    # Convert time to timedelta
    x['time'] = pd.to_timedelta(x['time'], unit='h')
    # Convert to appropriate np datatype
    if as_type:
        x['item2d'] = x['item2d'].astype(as_type)
    return x


# Import data
with open(ccd_file, 'r') as f:
    ccd = pd.read_json(f)

# Generate a range of sites and set up unique identifier
ccd = gen_rand_sites(ccd)
ccd = gen_id(ccd)

ccd.head()

n0108 = extract(ccd, 'NIHR_HIC_ICU_0108', as_type=np.int)
n0122 = extract(ccd, 'NIHR_HIC_ICU_0122', as_type=np.float)

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
