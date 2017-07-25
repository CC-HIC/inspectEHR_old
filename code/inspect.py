# Example of how to inspect using classes
# Expects to be run from project directory
%who

import os
import numpy as np
import pandas as pd
import pandas.api.types as ptypes
import seaborn as sns
import matplotlib.pyplot as plt
from statsmodels.graphics.mosaicplot import mosaic
import warnings

# ipython magic commands for re-loading modules during development
# - [ ] @NOTE: (2017-07-13) for interactive use
# %load_ext autoreload
# %autoreload
from inspectEHR.utils import load_spec
from inspectEHR.CCD import CCD
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin

# Load data spec
spec = load_spec(os.path.join('data-raw', 'N_DataItems.yml'))
spec_df = pd.DataFrame(spec).T

# Load data
filepath = 'data/anon_public_da1000.h5'
# filepath = 'data/anon_internal.h5'
ccd = CCD(filepath, spec, random_sites=True)
ccd.infotb.shape
ccd.item_1d.shape
ccd.item_2d.shape


# d0093 = DataRaw('NIHR_HIC_ICU_0093', ccd=ccd, spec=spec, first_run=True)
# d0093.nrow

# Loop through items
# Let's try and select all 2d numeric items from spec
fields2check = {k:v for k,v in spec.items() if v['Datatype'] in
                ['numeric', 'list', 'list / logical', 'Logical']}
fields = [k for k in fields2check.keys()][50:60]
# fields = [k for k in fields2check.keys()][:100]
# [fields2check[k]['dataItem'] for k in fields]

data_raw_items = {field:DataRaw(field, ccd=ccd, spec=spec) for field in fields}
# data_raw_items['NIHR_HIC_ICU_0005']
results = {k:v.inspect() for k,v in data_raw_items.items()}
results = pd.concat(results)
results = pd.merge(results, spec_df, on='NHICcode' )
results.shape

col_order = "NHICcode dataItem level count nunique n pct min 25% 50% 75% max mean std miss_by_episode gap_period gap_start gap_stop".split()
def to_decimal_hours(d, f):
    return pd.to_timedelta(d[f]).astype('timedelta64[s]')/3600
results.gap_period = to_decimal_hours(results, 'gap_period')
results.gap_start = to_decimal_hours(results, 'gap_start')
results.gap_stop = to_decimal_hours(results, 'gap_stop')
results[col_order].to_clipboard()
