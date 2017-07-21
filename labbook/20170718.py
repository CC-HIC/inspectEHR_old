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
spec = load_spec(os.path.join('data-raw', 'N_DataItems.yml'))
# spec['NIHR_HIC_ICU_0093']

%autoreload
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin


# Load 1d and 2d data
from inspectEHR.CCD import CCD
# filepath = 'data-raw/anon_public_da1000.JSON'
filepath = 'data/anon_public_da1000.h5'
ccd = CCD(filepath, spec, random_sites=True)
# ccd.infotb.head()

# Create DataRaw instances
%autoreload
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin
d0122 = DataRaw('NIHR_HIC_ICU_0122', ccd=ccd, spec=spec)


len(d0122.df)
d0122.d1d
d0122.make_misstb(verbose=True)


d0122.inspect()
d0108 = DataRaw('NIHR_HIC_ICU_0108', ccd=ccd, spec=spec)
d0108.make_misstb()
d0108.misstb.shape
d0108.misstb.miss_by_episode.value_counts()
d0122.misstb.miss_by_episode.value_counts()

fields = ['NIHR_HIC_ICU_0108', 'NIHR_HIC_ICU_0122']
data_raw_items = {field:DataRaw(field, ccd=ccd, spec=spec) for field in fields}

data_raw_items['NIHR_HIC_ICU_0108'].inspect()
data_raw_items['NIHR_HIC_ICU_0122'].inspect()
x = data_raw_items['NIHR_HIC_ICU_0122'].inspect()

results = {k:v.inspect() for k,v in data_raw_items.items()}

x = pd.DataFrame(results)
x.T


# Let's try and select all 2d numeric items from spec
spec_df = pd.DataFrame(spec).T
spec_2dcont = {k:v for k,v in spec.items() if v['NHICdtCode'] is not None
                                            and v['Datatype'] in ['numeric']}

fields = [k for k in spec_2dcont.keys()]
fields = fields[:20]
data_raw_items = {field:DataRaw(field, ccd=ccd, spec=spec) for field in fields}
results = {k:v.inspect() for k,v in data_raw_items.items()}
results = pd.DataFrame(results).T
results.head()
results = pd.merge(results, spec_df, left_index=True, right_index=True )
col_order = "dataItem count min 25% 50% 75% max mean std miss_by_episode gap_period gap_start gap_stop".split()
def to_decimal_hours(d, f):
    return pd.to_timedelta(d[f]).astype('timedelta64[s]')/3600
results.gap_period = to_decimal_hours(results, 'gap_period')
results.gap_start = to_decimal_hours(results, 'gap_start')
results.gap_stop = to_decimal_hours(results, 'gap_stop')
results[col_order].to_clipboard()
