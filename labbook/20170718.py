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
from inspectEHR.CCD import CCD
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin

d0093 = DataRaw('NIHR_HIC_ICU_0093', ccd=ccd, spec=spec)

bar = d0093.inspect()
d0108 = DataRaw('NIHR_HIC_ICU_0108', ccd=ccd, spec=spec)
foo = d0108.inspect()
foo.shape


pd.concat([foo,bar], ignore_index=True)

fields = ['NIHR_HIC_ICU_0093', 'NIHR_HIC_ICU_0108', 'NIHR_HIC_ICU_0122']
data_raw_items = {field:DataRaw(field, ccd=ccd, spec=spec) for field in fields}

results = {k:v.inspect() for k,v in data_raw_items.items()}

pd.concat(results)
report_cont = pd.DataFrame(results).T
report_cont

pd.concat([report_cat, report_cont])
