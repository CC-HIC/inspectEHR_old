import warnings
import numpy as np
import pandas as pd
import os
from .utils import ProgressMarker


# Primary class
class CCD:
    def __init__(self, filepath, spec,
                    idhs = True,
                    random_sites=False, random_sites_list=list('ABCDE'),
                     id_columns=('site_id', 'episode_id')):
        """ Reads and processes CCD object, provides methods to extract NHIC data items.
        With JSON will load and
            - provide methods to extract single items
            - provide methods to extract all to h5
        With h5 will load and make available as infotb, item_1d, and item_2d dataframes

        Args:
            filepath (str): Path to CCD JSON object or h5 file
            spec: data specification as dictionary
            idhs: indicate if being run in safe haven as data format differs
            With JSON:
                random_sites (bool): If True,  adds fake site IDs for testing purposes.
                random_sites_list (list): Fake site IDs used if add_random_sites is True
            id_columns (tuple): Columns to concatenate to form unique IDs. Defaults to
                concatenating site and episode IDs.
        """
        if not os.path.exists(filepath):
            raise ValueError("Path to data not valid")

        _, self.ext = os.path.splitext(filepath)
        self.ext = self.ext.lower()
        self.spec = spec
        self.filepath = filepath
        self.idhs = idhs

        if self.ext == '.json':
            self.ext = 'json'
            self.random_sites = random_sites
            self.random_sites_list = random_sites_list
            # - [ ] @FIXME: (2017-07-28) drop id_columns
            self.id_columns = id_columns
            self.ccd_key = id_columns
            self.ccd = self._load_from_json(self.filepath)
            self._add_random_sites()
            # self.infotb = self._extract_infotb()
            # self._add_unique_ids(self.ccd)
            # self._add_unique_ids(self.infotb)
        elif self.ext == '.h5':
            self.ext = 'h5'
            store = pd.HDFStore(self.filepath)
            self.infotb = store.get('infotb')
            self.item_1d = store.get('item1d')
            self.item_2d = store.get('item2d')
            store.close()
        elif os.path.isdir(filepath):
            # Handle a directory of JSON files
            # - [ ] @NOTE: (2017-07-28) manages 25k patients OK: i.e. loading
            files = os.listdir(filepath)
            if not all([os.path.splitext(f)[1].lower() == '.json'
                        for f in files]):
                raise ValueError('!!! Directory must only contain JSON files')
            self.ccd = pd.concat(list((self._load_from_json(f) for f in files)))
            self.infotb = self._extract_infotb()
        else:
            raise ValueError('!!! Expects a JSON or h5 file')



    def __str__(self):
        '''Print helpful summary of object'''
        print(self.ccd.head())
        txt = ['\n']
        txt.extend(['CCD object containing data from', self.json_filepath])
        return ' '.join(txt)

    @staticmethod
    def _load_from_json(fp):
        """ Reads in CCD object into pandas DataFrame, checks that format is as expected."""
        with open(fp, 'r') as f:
            ccd = pd.read_json(f)
        # self._check_ccd_quality()
        return ccd

    def _check_ccd_quality(self):
        # TODO: Implement quality checking
        warnings.warn('Quality checking of source JSON not yet implemented.')

    def _add_random_sites(self):
        """ Optionally adds random site IDs for testing purposes."""
        if self.random_sites:
            sites_series = pd.Series(self.random_sites_list)
            self.ccd['site_id'] = sites_series.sample(len(self.ccd), replace=True).values

    def _add_unique_ids(self, dt):
        """ Define a unique ID for CCD data."""
        for i, col in enumerate(self.id_columns):
            if i == 0:
                dt['id'] = dt[col].astype(str)
            else:
                dt['id'] = (dt['id'].astype(str) +
                                  dt[col].astype(str))
        assert not any(dt.duplicated(subset='id'))  # Check unique
        dt.set_index('id', inplace=True)  # Set index

    def _build_df(self, nhic_code, by):
        """ Build DataFrame for specific item from original JSON."""
        # TODO: Eliminate loop
        individual_dfs = []
        for row in self.ccd.itertuples():
            try:
                d = row.data[nhic_code]
                bv = getattr(row, by)
                if type(d) == dict:  # If 2d then data stored as dict of lists
                    d = pd.DataFrame(d, index=np.repeat(row.Index, len(d['item2d'])))
                    d['byvar'] = bv
                else:  # else data stored as single item
                    d = pd.DataFrame({'item1d': d, 'byvar': bv}, index=[row.Index])
                individual_dfs.append(d)
            except KeyError:
                individual_dfs.append(None)
        return pd.concat(individual_dfs)

    @staticmethod
    def _rename_data_columns(df):
        """Renames data columns in DataFrame (assumes only 1 of item2d or item1d)"""
        return df.rename(columns={'item2d': 'value', 'item1d': 'value'})

    @staticmethod
    def _convert_to_timedelta(df, delta=False):
        """Convert time in DataFrame to timedelta (if 2d)."""
        if 'time' in df.columns:
            if delta:
                df['time'] = pd.to_timedelta(df['time'], unit='h')
            else:
                df['time'] = pd.to_datetime(df['time'])
            df = df[['value', 'byvar', 'time']]
        else:
            df = df[['value', 'byvar']]
        return df

    def extract_one(self, nhic_code, by="site_id"):
        """ Extract a single NHIC data item from JSON or HDF

        Args:
            nhic_code (str): Reference for item to extract, e.g. 'NIHR_HIC_ICU_0108'
            by (str): Allows reporting / analysis by category. Defaults to site
            as_type (type): If not None, attempts to convert data to this type

        Returns:
            DataFrame: IDs are stored as id and i (index the row) with columns
                for the data (value) and time (time)
        """
        # TODO: Standardise column order
        if self.ext == 'json':
            df = self._build_df(nhic_code, by)
            df = self._rename_data_columns(df)
            df = self._convert_to_timedelta(df, delta=False)
            return df
        elif self.ext == 'h5':
            # method for h5
            if self.spec[nhic_code]['dateandtime']:
                df = self.item_2d[self.item_2d['NHICcode'] == nhic_code]
            else:
                df = self.item_1d[self.item_1d['NHICcode'] == nhic_code]

            # Switch off annoying warning message: see https://stackoverflow.com/a/20627316/992999
            pd.options.mode.chained_assignment = None  # default='warn'
            df['id'] = df['site_id'].astype(str) + df['episode_id'].astype(str)
            df.set_index('id', inplace=True)
            df.drop(['NHICcode'], axis=1, inplace=True)
            # - [ ] @TODO: (2017-07-16) allow other byvars from 1d or infotb items
            #   for now leave site_id and episode_id in to permit easy future merge
            df['byvar'] = df[by]
            df.rename(columns={'item2d': 'value', 'item1d': 'value'}, inplace=True)
            pd.options.mode.chained_assignment = 'warn'  # default='warn'

            return df

        else:
            raise ValueError('!!! ccd object derived from file with unrecognised extension {}'.format(DataRawNew.ccd.ext))

    def json2hdf(self,
        path, replace=True, progress_marker=True,
        ccd_key = ['site_id', 'episode_id']):
        '''Extracts all data in ccd object to infotb, 1d, and 2d data frames in HDF5
        Args:
            ccd: ccd object (data frame with data column containing dictionary of dictionaries)
            ccd_key: unique key to be stored from ccd object; defaults to site/episode
            path: path to save file
            progress_marker: displays a dot every 10 records
        '''

        if not os.path.exists(os.path.dirname(path)):
            raise ValueError('!!! Requires valid path for HDF file')

        # Config
        _minsize = 64
        expected_cols = ('Index', 'data', 'episode_id', 'nhs_number', 'parse_file',
            'parse_time', 'pas_number', 'site_id', 't_admission', 't_discharge')
        cols_to_index = ['site_id', 'NHICcode']

        if replace:
            try:
                os.remove(path)
            except FileNotFoundError:
                pass
        else:
            if os.path.exists(path):
                raise NotImplementedError('!!! No function to append to existing data store')

        # Set variables
        # - [ ] @TODO: (2017-07-28) optionally switch off compression if slows performance
        store = pd.HDFStore(path, complib='zlib',complevel=9)
        rows_infotb = [] # check here else will forget to reset
        progress = ProgressMarker()

        # Start loop
        for i, row in enumerate(self.ccd.itertuples()):

            progress.status()
            assert row._fields  == expected_cols

            # Construct infotb
            row_infotb = {f:getattr(row, f) for f in row._fields if f != 'data'}
            rows_infotb.append(pd.Series(row_infotb))

            # Handle data
            # - [ ] @NOTE: (2017-07-28) specify future columns to index now
            data = getattr(row, 'data')
            store.append('item2d', self.get_2d(data, row),
                index=False, data_columns=cols_to_index, min_itemsize = {'values': _minsize})
            store.append('item1d', self.get_1d(data, row),
                index=False, data_columns=cols_to_index, min_itemsize = {'values': _minsize})

        infotb = pd.DataFrame(rows_infotb)
        store.append('infotb', infotb, data_columns=cols_to_index)

        store.create_table_index('item1d', columns=['site_id'], optlevel=9, kind='full')
        store.create_table_index('item2d', columns=['NHICcode'], optlevel=9, kind='full')

        store.close()

    @staticmethod
    def to_timeish(s, delta=True, unit='h'):
        """Convert to either datetime or deltatime"""
        if delta:
            return pd.to_timedelta(s, unit=unit)
        else:
            return pd.to_datetime(s)

    def get_1d(self, data, row):
        """Get 1d items
        Args:
            data: expects a dictionary
        """
        data1d = {k:v for k,v in data.items() if type(v) is not dict}

        # data1d dictionary to dataframe df1d
        df1d = pd.DataFrame([data1d], index=['value'], dtype=np.str).T
        for k in self.ccd_key:
            df1d[k] = getattr(row, k)
        df1d.reset_index(inplace=True)
        df1d.rename(columns={'index':'NHICcode'}, inplace=True)

        return df1d

    def get_2d(self, data, row):
        """Get 2d items
        Args:
            data: expects a dictionary of dictionaries of lists
        """
        data2d = {k:v for k,v in data.items() if type(v) is dict}

        # data2d dictionary to dataframe df2d
        df2d = {k:v.keys() for k,v in data2d.items()}
        df2d = {k:pd.DataFrame(v) for k,v in data2d.items()}
        df2d = pd.concat(df2d)
        df2d.reset_index(level=0, inplace=True)
        df2d.rename(columns={'item2d':'value', 'level_0':'NHICcode'}, inplace=True)
        df2d['time'] = self.to_timeish(df2d['time'])
        if 'meta' not in df2d.columns:
            df2d['meta'] = None

        return df2d

    @staticmethod
    def df2feather(df, path):
        '''Save dataframe to feather'''
        # Resets index to ensure unique for feather format
        df.reset_index(inplace=True, drop=True)
        try:
            df.to_feather(path)
        except NotImplementedError as e:
            warnings.warn('\n!!! converting time timedelta64 to numeric to save to feather')
            df['time'] = pd.to_numeric(df['time'])
            df.to_feather(path)
        except IOError as e:
            warnings.warn('\n!!! Unable to save dataframe - do this now manually')
            print(e)
