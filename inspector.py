import sys
import os
import argparse
import warnings
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
from statsmodels.graphics.mosaicplot import mosaic
import pandas as pd
# Turn off modification of slice warnings
pd.options.mode.chained_assignment = None  # default='warn'
# Restore annoying warnings
# pd.options.mode.chained_assignment = 'warn'  # default='warn'

from inspectEHR.utils import load_spec
from inspectEHR.CCD import CCD
from inspectEHR.data_classes import DataRaw, ContMixin, CatMixin

def to_decimal_hours(s):
    """Return series s as decimal hours"""
    return pd.to_timedelta(s).astype('timedelta64[s]')/3600

def row_generator(NHICcode, ccd, spec, by=False, verbose=False):
    """Mini function to use make row inspection more efficient"""
    cc_item = DataRaw(NHICcode, ccd=ccd, spec=spec)
    if verbose:
        print(NHICcode, cc_item.nrow)
        return cc_item.inspect_row(by=by)

def main(args, debug=False):

    if debug:
        field_limit = 10
        print('!!! Debugging - will only check first {} fields'.format(field_limit))
    else:
        field_limit = None

    data_path         = args.data_path
    spec_path         = args.spec
    results_path      = args.to
    bysite            = args.bysite

    spec = load_spec(spec_path)
    spec_df = pd.DataFrame(spec).T

    ccd = CCD(data_path, spec)

    non_text_fields = ['numeric', 'list', 'list / logical', 'Logical']
    fields2check = {k:v for k,v in spec.items() if v['Datatype'] in non_text_fields}
    fields = [k for k in fields2check.keys()][:field_limit]

    # parentheses turn the following into a generator expression
    rows = list((row_generator(f, ccd=ccd, spec=spec, by=bysite, verbose=True) for f in fields))

    # Convert list of dataframes to single data frame
    results = pd.concat(rows)
    # Merge in the rest of the data spec
    results = pd.merge(results, spec_df, on='NHICcode' )

    gaps = ['gap_period', 'gap_start', 'gap_stop']
    for i in gaps:
        results[i] = to_decimal_hours(results[i])

    col_order = "NHICcode site_id dataItem level count nunique n pct min 25% 50% 75% max mean std coerced_values miss_by_episode gap_period gap_start gap_stop".split()
    # results[col_order].to_clipboard()
    results[col_order].to_csv(results_path)

def cli():
    ''' Command line interface for running script '''

    # Parse arguments
    parser = argparse.ArgumentParser(
        description='Report data quality for CCD object'
    )

    parser.add_argument('data_path',
                        help='JSON or hd5 file to be parsed')

    parser.add_argument('-s', '--spec',
                        default = 'N_DataItems.yml',
                        help='Data specification')

    parser.add_argument('-t', '--to',
                        default = 'inspector.csv',
                        help='CSV file with results')

    parser.add_argument('--bysite',
                        action='store_true',
                        help='Inspection stratified by site')

    args = parser.parse_args()
    return args

if __name__ == '__main__':
    args = cli()
    
    # interactive = True
    # if interactive:
    #     args.data_path         = 'data/anon_public_da1000.h5'
    # print(args)
    # main(args, debug=True)

    main(args)
