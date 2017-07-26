# Load the ccd object
# Then in one go make a pandas data frame with all 2d data
# Use this for work

# - [ ] @TODO: (2017-07-15) write method of CCD that makes a feather store for 1D and 2D data
#   then deprecate the extract method to extract single, extract from original
#   then write new extract method that just pulls the data from the feather store


import os
import warnings
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from statsmodels.graphics.mosaicplot import mosaic


from inspectEHR.utils import load_spec
from inspectEHR.CCD import CCD
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin

# - [ ] @TODO: (2017-07-15)  make a unique key from ccd (just integer would do)
#   use this to index the item_tb table


if __name__ == "__main__":
    ccd = CCD(os.path.join('data-raw', 'anon_public_da1000.JSON'), random_sites=True)
    # ccd = CCD(os.path.join('data-raw', 'anon_internal.JSON'), random_sites=True)
    refs = load_spec(os.path.join('data-raw', 'N_DataItems.yml'))

    df2d = extract_all(ccd, 2, save2feather=True, path='data/item_2d.feather)

    df1d = extract_all(ccd, 1, save2feather=True, path='data/item_1d.feather)
