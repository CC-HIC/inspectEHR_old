#! /Users/steve/usr/anaconda3/envs/cchic/bin/python
import os
import warnings
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
from statsmodels.graphics.mosaicplot import mosaic
import pandas as pd

from inspectEHR.utils import load_spec
from inspectEHR.CCD import CCD
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin

def to_decimal_hours(s):
    """Return series s as decimal hours"""
    return pd.to_timedelta(s).astype('timedelta64[s]')/3600


def main():
    debug_field_limit = 10
    # data_path = 'data/anon_internal.h5'
    data_path = os.path.join('data', 'anon_public_da1000.h5')
    spec_path = os.path.join('data-raw', 'N_DataItems.yml')

    spec = load_spec(spec_path)
    spec_df = pd.DataFrame(spec).T

    ccd = CCD(data_path, spec)

    non_text_fields = ['numeric', 'list', 'list / logical', 'Logical']
    fields2check = {k:v for k,v in spec.items() if v['Datatype'] in non_text_fields}
    fields = [k for k in fields2check.keys()][:debug_field_limit]


    data_raw_items = {}
    for field in fields:
        print(field)
        data_raw_items[field] = DataRaw(field, ccd=ccd, spec=spec)

    results = {}
    for k,v in data_raw_items.items():
        print(k, v.nrow)
        results[k] = v.inspect_row(by=True)

    # Convert list of dataframes to single data frame
    results = pd.concat(results)
    # Merge in the rest of the data spec
    results = pd.merge(results, spec_df, on='NHICcode' )

    gaps = ['gap_period', 'gap_start', 'gap_stop']
    for i in gaps:
        results[i] = to_decimal_hours(results[i])

    col_order = "NHICcode site_id dataItem level count nunique n pct min 25% 50% 75% max mean std coerced_values miss_by_episode gap_period gap_start gap_stop".split()
    # results[col_order].to_clipboard()
    results[col_order].to_csv('data/results.csv')

if __name__ == '__main__':
    # Turn off modification of slice warnings
    pd.options.mode.chained_assignment = None  # default='warn'
    main()
    # Restore annoying warnings
    pd.options.mode.chained_assignment = 'warn'  # default='warn'
