# Check Python and R versions available to rpy2
import sys
print(sys.version)
import rpy2
from rpy2.rinterface import R_VERSION_BUILD
print(R_VERSION_BUILD)

import pandas as pd
from pandas.io.json import json_normalize

import rpy2.robjects as robjects
pi = robjects.r['pi']
print(pi[0])


# Short cut using JSON
# The 1000 patient data set is just 29M so not massive
# - [ ] @TODO: (2017-07-01) @later switch to ijson or similar so that not holding big objects in memory
file = "inspectEHR/data/anon_public_da1000.JSON"
import json
with open(file, 'r') as f:
    # ccd = json.load(f)
    ccd = pd.read_json(f)

# Now having imported as dataframe, use iterrows then the index should be preserved
x = []
for i, r in ccd.iterrows():
    try:
        d = pd.DataFrame(r['data']['NIHR_HIC_ICU_0108'])
        x.append(d)
    except KeyError:
        x.append(None)
    # if i > 1: # while debugging
    #     break

# now make a list of pandas dataframes instead of a list of dictionaries
# then concatenate
# then use the keys from the original data frame to label the concatenated dataframes
len(x)
x[:1]

ccd['episode_id']
y = pd.concat(x, keys=ccd['episode_id'])
y.head()
y.shape
y.index
# index properties
y.index.size
y.index.ndim
y.index.shape
y.index.dtype
y.columns
y.loc[:(3,10)]
z = y.copy()
z.head()
# Rename index
zi.set_names(['id','i'], inplace=True)
# use loc to index based on name (or iloc on integer position)
z.loc[:1]
z.loc[:3,:]
z.loc[[2,3],:] # fancy indexing
z.loc[(1,1),:] # pass a tuple to identify a component of a multi-index
# use index slice to extract slices within tuples
z.loc[pd.IndexSlice[:2,:5], :]
# rename for convenience
idx = pd.IndexSlice
z.loc[idx[:5,:10],]
# Now create new index using times
z = z.loc[idx[:5,:10],].copy()
z.shape
# Unstack an index
z.unstack(level=0)
z.unstack(level=1)
# Convert index into column
z = z.reset_index(level=1)
# Add index
z.set_index('time',append=True)
z.dtypes

# Convert times to timedeltas
z['time'] = pd.to_timedelta(z['time'], unit='h')
z.head()
z = z.set_index('time',append=True)
z = z.drop('i', axis='columns')

# index by time
z.loc[idx[:1,:'30 minutes'],]
z.loc[idx[:1,:'24 hours'],]
z.loc[idx[:1,:'1 day'],]
z.index

# Shifting the data
z
z.shift(1) # shifts the data forward 1
z.shift(-1) # shifts the data backward 1
pd.to_timedelta('1 hour')
z.index
z['t'] =
z.tshift(1, freq= pd.to_timedelta('1 hour')) # shifts the data backward 1

#
z = z.reset_index(level=1)
z['time'] = pd.to_timedelta(z['time'], unit='h')
z.loc[:,'time']

# get average period by patient
# (z['time'] - z.groupby('episode_id')['time'].shift(1)).mean()

z
z.dtypes
z.loc['time']
z.loc[:,'time'].tshift(1, freq= pd.to_timedelta('1 hour')) # shifts the data backward 1
z





z.loc[slice(1,2)]
zi = z.index
zi
zi[:1,1]

ccd.tail()
# Now you can iterate through each item
ccd[0].keys()
ccd[0]['data'].keys()
ccd[0]['data']['NIHR_HIC_ICU_0108']
ccd[0]['data']['NIHR_HIC_ICU_0108']['item2d']
ccd[0]['data']['NIHR_HIC_ICU_0108']['time']

# Function to extract 1d and 2d fields from ccd and convert into pandas

def extract_lvl1(d, k):
    '''
    Extract all first level keys from a list of dictionaries
    d is a list of dictionaries (e is an element or single dictionary)
    k is the key to be extracted
    '''
    return [e[k] for e in d]



episode_ids = extract_lvl1(ccd, 'episode_id')
site_ids = extract_lvl1(ccd, 'site_id')
episode_ids[-5:]
site_ids[-5:]


x = []
for i, e in enumerate(ccd):
    try:
        x.append(e['data']['NIHR_HIC_ICU_0108'])
    except KeyError:
        x.append(None)
x[1]
assert len(site_ids) == len(episode_ids) == len(x)
y = list(zip(site_ids, episode_ids, x))
y[0]

ccd05 = json.dumps(ccd[:5])
json_normalize(ccd05, 'NIHR_HIC_ICU_0108', 'site_id', 'episode_id')
pd.read_json(ccd05)
