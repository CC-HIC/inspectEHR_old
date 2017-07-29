import logging
import os
import pandas as pd
import numpy as np

logging.basicConfig(filename='json2hdf.log', level=logging.DEBUG)

from inspectEHR.utils import load_spec
from inspectEHR.CCD import CCD
from inspectEHR.data_classes import DataRaw

spec = load_spec('N_DataItems.yml')
spec_df = pd.DataFrame(spec).T

ccd = CCD('data-raw/anon_internal.JSON', spec, idhs=False)
ccd.json2hdf('data/ccd-anon.h5')

store = pd.HDFStore('data/ccd-anon.h5')
print(store)
store.close()
