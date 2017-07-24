# Example of how to inspect using classes
# Expects to be run from project directory
# ipython magic commands for re-loading modules during development
# - [ ] @NOTE: (2017-07-13) for interactive use
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


ccd = CCD(os.path.join('data-raw', 'anon_public_da1000.JSON'), random_sites=True)
refs = load_spec(os.path.join('data-raw', 'N_DataItems.yml'))


# Generate data for testing
# Heart rate
n0108 = ccd.extract('NIHR_HIC_ICU_0108', as_type=np.int)
n0108 = ccd.extract('NIHR_HIC_ICU_0108', as_type=np.int, drop_miss=False)
d0108 = DataRaw(n0108, spec=refs['NIHR_HIC_ICU_0108'])
df = d0108.gap_startstop(ccd)

# Lactate
n0122 = ccd.extract('NIHR_HIC_ICU_0122', as_type=np.float)
d0122 = DataRaw(n0122, spec=refs['NIHR_HIC_ICU_0122'])
df = d0122.gap_startstop(ccd)
sns.kdeplot(df['stop'].dropna())
# Sex
n0093 = ccd.extract('NIHR_HIC_ICU_0093', as_type=np.str)
# Height
n0017 = ccd.extract('NIHR_HIC_ICU_0017', as_type=np.str)
n0017 = ccd.extract('NIHR_HIC_ICU_0017', as_type=np.str, drop_miss=False)

# Loop through items
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
