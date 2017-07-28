# parse CCD.ccd one row at a time and write to hdf
%who
def to_timeish(s, delta=True, unit='h'):
    """Convert to either datetime or deltatime"""
    if delta:
        return pd.to_timedelta(s, unit=unit)
    else:
        return pd.to_datetime(s)

def get_1d(data):
    """Get 1d items"""
    data1d = {k:v for k,v in data.items() if type(v) is not dict}

    # data1d dictionary to dataframe df1d
    df1d = pd.DataFrame([data1d], index=['value'], dtype=np.str).T
    for k in ccd_key:
        df1d[k] = getattr(row, k)
    df1d.reset_index(inplace=True)
    df1d.rename(columns={'index':'NHICcode'}, inplace=True)

    return df1d

def get_2d(data):
    """Get 2d items"""
    data2d = {k:v for k,v in data.items() if type(v) is dict}

    # data2d dictionary to dataframe df2d
    df2d = {k:v.keys() for k,v in data2d.items()}
    df2d = {k:pd.DataFrame(v) for k,v in data2d.items()}
    df2d = pd.concat(df2d)
    df2d.reset_index(level=0, inplace=True)
    df2d.rename(columns={'item2d':'value', 'level_0':'NHICcode'}, inplace=True)
    df2d['time'] = to_timeish(df2d['time'])
    if 'meta' not in df2d.columns:
        df2d['meta'] = None

    return df2d

class ProgressMarker():
    """Print a dot with suitable line breaks etc"""

    def __init__(self, steps=10, linebreak=50):

        self.i = 0
        self.steps = steps
        self.linebreak = linebreak * steps

    def status(self):
        if self.i % self.linebreak == 0:
            print("\n{:>6} ".format(i), end='')
        if self.i % self.steps == 0:
            print(".", end='')

        self.i += 1
        return None

    def reset(self):
        self.i = 0

# Config
ccd_key = ['site_id', 'episode_id']
expected_cols = ('Index', 'data', 'episode_id', 'nhs_number', 'parse_file', 'parse_time', 'pas_number', 'site_id', 't_admission', 't_discharge')
cols_to_index = ['site_id', 'NHICcode']

# Start here
# Set variables
os.remove('data/ccd.h5')
store = pd.HDFStore('data/ccd.h5')
store

# Start loop
for i, row in enumerate(ccd.ccd.itertuples()):
    if i == 0:
        os.remove('data/ccd.h5')
        store = pd.HDFStore('data/ccd.h5')
        rows_infotb = [] # check here else will forget to reset
        progress = ProgressMarker()
    if i > 100:
        break
    progress.status()
    assert row._fields  == expected_cols
    # Construct infotb
    row_infotb = {f:getattr(row, f) for f in row._fields if f != 'data'}
    rows_infotb.append(pd.Series(row_infotb))

    # Handle data
    # - [ ] @NOTE: (2017-07-28) specify future columns to index now
    data = getattr(row, 'data')
    store.append('item2d', get_2d(data), index=False, data_columns=cols_to_index, min_itemsize = {'values': 50})
    store.append('item1d', get_1d(data), index=False, data_columns=cols_to_index, min_itemsize = {'values': 50})

infotb = pd.DataFrame(rows_infotb)
store.append('infotb', infotb, data_columns=cols_to_index)

# - [ ] @TODO: (2017-07-28) turn back on the index
store.create_table_index('item1d', columns=['site_id'], optlevel=9, kind='full')
store.create_table_index('item2d', columns=['NHICcode'], optlevel=9, kind='full')

store
store.close()
# row is now a named tuple


# Now append store in correct types
store = pd.HDFStore('data/ccd.h5')
foo = store.select('item2d', start=0, stop=10)
foo
foo = store.select('item2d', 'NHICcode == NIHR_HIC_ICU_0122')
foo.shape
foo.value.astype(np.float).describe()


# append method automatically forces table not fixed format
# store.select('item2d')


store.close()

# Compress file
store_compressed = pd.HDFStore('data/ccd.h5', complevel=9, complib='blosc:blosclz')
