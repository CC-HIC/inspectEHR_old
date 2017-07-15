# Try working with the full data (borrowed from paper-brc)
%load_ext autoreload
%autoreload

import os
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from statsmodels.graphics.mosaicplot import mosaic


from inspectEHR.utils import load_spec
from inspectEHR.CCD import CCD
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin

ccd = CCD(os.path.join('data-raw', 'anon_internal.JSON'), random_sites=True)
ccd.ccd.dtypes
ccd.ccd.head()
ccd.ccd.shape
refs = load_spec(os.path.join('data-raw', 'N_DataItems.yml'))

# Test extraction
n0108 = ccd.extract('NIHR_HIC_ICU_0108', as_type=np.int, drop_miss=False)
d0108 = DataRaw(n0108, spec=refs['NIHR_HIC_ICU_0108'])
d0108.inspect()
d0108.plot()

%autoreload
d0108.gap_plot()
df = d0108.gap_startstop(ccd)


# Example saving data as HDF5
# - [ ] @NOTE: (2017-07-13) saves almost no diskspace cf JSON
# os.getcwd()
# store = pd.HDFStore(os.path.join('data-raw', 'anon_internal.h5'))
# store['ccd'] = ccd.ccd
# store

# MongoDB store
from pymongo import MongoClient
client = MongoClient('localhost', port=27017)
db = client['ccd']
anon = db['anon_internal']


import json
with open(os.path.join('data-raw', 'anon_internal.JSON')) as fin:
    episodes = json.load(fin)
    for episode in episodes:
        db.anon.insert_one(episode)

# Import to pandas
df = pd.DataFrame(list(db.anon.find()))
df.shape


db.anon.count()
# cursor = db.anon.find()
# for i, doc in enumerate(cursor):
#     print(i)
#     print(doc)
#     if i > 2:
#         break

import pprint
pprint.pprint(db.anon.find_one())

# return episode 1
d = db.anon.find_one({'episode_id': '1'})
# return parts of episode 1 (1 = include)
d = db.anon.find_one({'episode_id': '1'}, {'site_id': 1, 'episode_id': 1})
# exclude everything but data
d = db.anon.find_one({'episode_id': '1'}, {'data': 0 })
pprint.pprint(d)
# find all non data
d = db.anon.find({}, {'data': 0 })
# Import to pandas using list to iterate the generator
df = pd.DataFrame(list(d))
df.shape
df.head()

# Now just look at the data item
d = db.anon.find_one({}, {'data': 1 })
pprint.pprint(d)
# Just returns heart rate (and excludes _id)
d = db.anon.find_one({}, {'_id': 1, 'site_id':1, 'data.NIHR_HIC_ICU_0108': 1 })
print(d)
# pprint.pprint(d)
# d['data']['NIHR_HIC_ICU_0108']
df = pd.DataFrame(d['data']['NIHR_HIC_ICU_0108'])
df['id'] = d['_id']
df['byvar'] = d['site_id']
df.head()
df.set_index('id', inplace=True)
df.head()

# Now extract all heart rates
docs = db.anon.find({}, {'episode_id': 1, 'site_id':1, 'data.NIHR_HIC_ICU_0108': 1 })

dfs = []
for doc in docs:
    try:
        df = pd.DataFrame(doc['data']['NIHR_HIC_ICU_0108'])
        df['id'] = doc['episode_id']
        df['byvar'] = doc['site_id']
        dfs.append(df)
    except KeyError:
        dfs.append(None)
df = pd.concat(dfs)
df.shape
df.head()

# Now try the same using aggregation
# docs = db.anon.aggregate([
#             {'$project': {
#                 'data.NIHR_HIC_ICU_0108.item2d': 1,
#                 'data.NIHR_HIC_ICU_0108.time': 1}},
#             {'$limit': 10}])

docs = db.anon.find({}, {'episode_id': 1, 'site_id':1, 'data.NIHR_HIC_ICU_0108': 1 })
d = list(docs)
d[1]['data']['NIHR_HIC_ICU_0108']
d[1]['NIHR_HIC_ICU_0108']
d = {doc['_id']: doc['data'] for doc in d}
type(d)
d.keys()
import pandas as pd
x = pd.Panel(d)
x.dtypes
x.to_frame().reset_index()

# JSON normalize from list of dictionaries
docs = db.anon.find({}, {'episode_id': 1, 'site_id':1, 'data.NIHR_HIC_ICU_0108': 1 })
d = list(docs)
from pandas.io.json import json_normalize
d = d[:10]
d[:1]
# res = json_normalize(d, ['NIHR_HIC_ICU_0108'], ['site_id', 'episode_id'])
res = json_normalize(d)
res.dtypes
res.head()
