import warnings
import numpy as np
import pandas as pd
import os



class CCD:
    def __init__(self,
                    filepath,
                    spec,
                    idhs = True,
                    random_sites=False,
                    random_sites_list=list('ABCDE'),
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

        _, self.ext = os.path.splitext(filepath).lower()
        self.spec = spec
        self.filepath = filepath
        self.idhs = idhs

        if self.ext == '.json':
            self.ext = 'json'
            self.random_sites = random_sites
            self.random_sites_list = random_sites_list
            self.id_columns = id_columns
            self.ccd = self._load_from_json(self.filepath)
            self._add_random_sites()
            self.infotb = self._extract_infotb()
            self._add_unique_ids(self.ccd)
            self._add_unique_ids(self.infotb)
        elif self.ext == '.h5':
            self.ext = 'h5'
            store = pd.HDFStore(self.filepath)
            self.infotb = store.get('infotb')
            self.item_1d = store.get('item_1d')
            self.item_2d = store.get('item_2d')
            store.close()
        elif os.path.isdir(filepath):
            # Handle a directory of JSON files
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
            path=None,
            ccd_key = ['site_id', 'episode_id'],
            progress_marker=True):
        '''Extracts all data in ccd object to infotb, 1d, and 2d data frames in HDF5
        Args:
            ccd: ccd object (data frame with data column containing dictionary of dictionaries)
            ccd_key: unique key to be stored from ccd object; defaults to site/episode
            path: path to save file
            progress_marker: displays a dot every 10 records
        '''
        if path is None:
            raise NameError('No path provided to which to save the HDF5 file')
        if not all([k in self.ccd.columns for k in ccd_key]):
            raise KeyError('!!! ccd_key should be a list of column names')

        # Extract and save infotb
        print('\n*** Extracting all infotb data from {} rows'.format(self.ccd.shape[0]))
        infotb = self._extract_infotb()

        # Extract and save 1d
        print('\n*** Extracting all {}d data from {} rows'.format(1, self.ccd.shape[0]))
        item_1d = self._extract_1d(ccd_key, progress_marker)

        # Extract and save 2d
        print('\n*** Extracting all {}d data from {} rows'.format(2, self.ccd.shape[0]))
        item_2d = self._extract_2d(ccd_key, progress_marker)

        dd = {'item_1d': item_1d, 'item_2d': item_2d, 'infotb':infotb}
        self._ccd2hdf(dd, path)

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

    @staticmethod
    def _ccd2hdf(dd, path):
        """Save list of data frames to HDF5 store"""
        if type(dd) is not dict:
            raise ValueError('Expects dictionary of dataframes')
        store = pd.HDFStore(path, mode='w')
        {store.put(k,v) for k,v in dd.items()}
        print(store)
        store.close()

    def _extract_infotb(self):
        """Extract infotb from after JSON import"""
        cols_2drop = ['data']
        cols_timedelta = ['t_admission', 't_discharge', 'parse_time']

        cols_2keep = [i for i  in self.ccd.columns if i not in cols_2drop]; cols_2keep
        rows_out = []

        for row in self.ccd.itertuples():
            row_in = row._asdict()
            row_out = {k:v for k,v in row_in.items() if k != 'data'}
            rows_out.append(row_out)

        infotb = pd.DataFrame(rows_out)

        for col in cols_timedelta:
            if self.idhs:
                # datetimes not timedeltas in IDHS
                infotb[col] = pd.to_datetime(infotb[col])
            else:
                infotb[col] = pd.to_timedelta(infotb[col], unit='s')

        return infotb

    @staticmethod
    def progress_marker(on=False, counter=i, steps=10):
        """Print a dot for every n steps of i"""
        if on & counter%steps == 0:
            print(".", end='')
        return counter += 1

    def _extract_1d(self, ccd_key, progress_marker):
        """Extract 1d data from nested dictionary in dataframe after JSON import"""
        df_from_rows = []
        i = 0

        for row in self.ccd.itertuples():
            i = self.progress_marker(True)

            df_from_data = []
            row_key = {k:getattr(row, k) for k in ccd_key}

            for j, (nhic, d) in enumerate(row.data.items()):
                # Assumes 2d data stored as dictionary
                if type(d) == dict:
                    continue
                else:
                    df_from_data.append({'NHICcode': nhic, 'item1d': d})

            df = pd.DataFrame(df_from_data)
            for k,v in row_key.items():
                df[k] = v
            df_from_rows.append(df)

        df = pd.concat(df_from_rows)
        return df

    def _extract_2d(self, ccd_key, progress_marker):
        """Extract 2d data from nested dictionary in dataframe after JSON import"""
        df_from_rows = []
        i = 0

        for row in self.ccd.itertuples():

            i = self.progress_marker(True)

            row_key = {k:getattr(row, k) for k in ccd_key}

            try:
                df = row.data
                df = {k:pd.DataFrame.from_dict(v) for k,v in df.items() if type(v) is dict}
                df = pd.concat(df)
                df.reset_index(level=0, inplace=True)
                df.rename(columns={'level_0':'NHICcode'}, inplace=True)

                for k,v in row_key.items():
                    df[k] = v
                df_from_rows.append(df)
            except ValueError as e:
                # unable to concatenate, no data?
                print('!!! Value error for {}'.format(row_key))
                print(e)
                continue
            except Exception as e:
                print('!!! Error for {}'.format(row_key))
                print(e)
                continue

        df = pd.concat(df_from_rows)
        df['time'] = pd.to_datetime(df['time'])
        return df
