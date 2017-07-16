import warnings
import numpy as np
import pandas as pd


class CCD:
    def __init__(self, json_filepath, random_sites=False, random_sites_list=list('ABCDE'),
                 id_columns=('site_id', 'episode_id')):
        """ Reads and processes CCD object, provides methods to extract NHIC data items.

        Args:
            json_filepath (str): Path to CCD JSON object
            random_sites (bool): If True,  adds fake site IDs for testing purposes.
            random_sites_list (list): Fake site IDs used if add_random_sites is True
            id_columns (tuple): Columns to concatenate to form unique IDs. Defaults to
                concatenating site and episode IDs.
        """
        self.json_filepath = json_filepath
        self.random_sites = random_sites
        self.random_sites_list = random_sites_list
        self.id_columns = id_columns
        self.ccd = None
        self._load_from_json()
        self._add_random_sites()
        self._add_unique_ids()


    def __str__(self):
        '''Print helpful summary of object'''
        print(self.ccd.head())
        txt = ['\n']
        txt.extend(['CCD object containing data from', self.json_filepath])
        return ' '.join(txt)

    def _load_from_json(self):
        """ Reads in CCD object into pandas DataFrame, checks that format is as expected."""
        with open(self.json_filepath, 'r') as f:
            self.ccd = pd.read_json(f)
        self._check_ccd_quality()

    def _check_ccd_quality(self):
        # TODO: Implement quality checking
        warnings.warn('Quality checking of source JSON not yet implemented.')

    def _add_random_sites(self):
        """ Optionally adds random site IDs for testing purposes."""
        if self.random_sites:
            sites_series = pd.Series(self.random_sites_list)
            self.ccd['site_id'] = sites_series.sample(len(self.ccd), replace=True).values

    def _add_unique_ids(self):
        """ Define a unique ID for CCD data."""
        for i, col in enumerate(self.id_columns):
            if i == 0:
                self.ccd['id'] = self.ccd[col].astype(str)
            else:
                self.ccd['id'] = (self.ccd['id'].astype(str) +
                                  self.ccd[col].astype(str))
        assert not any(self.ccd.duplicated(subset='id'))  # Check unique
        self.ccd.set_index('id', inplace=True)  # Set index

    def _build_df(self, nhic_code, by):
        """ Build DataFrame for specific item."""
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
    def _convert_to_timedelta(df):
        """Convert time in DataFrame to timedelta (if 2d)."""
        if 'time' in df.columns:
            df['time'] = pd.to_timedelta(df['time'], unit='h')
            df = df[['value', 'byvar', 'time']]
        else:
            df = df[['value', 'byvar']]
        return df

    @staticmethod
    def _convert_type(df, as_type):
        """Optionally convert data to specified type."""
        if as_type:
            df['value'] = df['value'].astype(as_type)
        return df

    def _preserve_missingness(self, df, by=None):
        '''Introduce placeholder rows for missing data'''
        if by is None:
            return df.reindex(self.ccd.index)
        else:
            # select by list [[]] to return dataframe not series
            left = self.ccd[[by]]
            result = pd.merge(left, df,
                left_index=True, right_index=True,
                how='left')
            # Drop old byvar (which will have missingness)
            result.drop('byvar', axis=1, inplace=True)
            result.rename(columns={by: 'byvar'}, inplace=True)
            return result


    def extract_one(self, nhic_code, by="site_id", as_type=None, drop_miss=True):
        """ Extract a single NHIC data item directly from ccd object

        Args:
            nhic_code (str): Reference for item to extract, e.g. 'NIHR_HIC_ICU_0108'
            by (str): Allows reporting / analysis by category. Defaults to site
            as_type (type): If not None, attempts to convert data to this type

        Returns:
            DataFrame: IDs are stored as id and i (index the row) with columns
                for the data (value) and time (time)
        """
        # TODO: Standardise column order
        df = self._build_df(nhic_code, by)
        df = self._rename_data_columns(df)
        df = self._convert_to_timedelta(df)
        df = self._convert_type(df, as_type)
        if drop_miss:
            return df
        else:
            return self._preserve_missingness(df, by)

    def extract_all(self, d1or2=1,
            ccd_key = ['site_id', 'episode_id'],
            save2feather=False,
            path=None,
            progress_marker=True):
        '''Extracts all data in ccd object to single data frame and stores feather object
        Args:
            ccd: ccd object (data frame with data column containing dictionary of dictionaries)
            d1or2: [1,2] 1d or 2d data
            ccd_key: unique key to be stored from ccd object; defaults to site/episode
            save2feather: saves a copy to feather format
            path: path to save feather file
            progress_marker: displays a dot every 10 records
        '''

        # warnings.warn('\n!!! Debugging - only runs first 5 rows')
        # dfin = ccd.ccd.head()
        # dfin = self.ccd

        # Check type and key
        # assert type(dfin) == pd.core.frame.DataFrame
        try:
            assert all([k in self.ccd.columns for k in ccd_key])
        except TypeError as e:
            # ccd_key not list?
            print('!!! ccd_key should be a list of column names')
            return e

        msg = '\n*** Extracting all {}d data from {} rows'.format(d1or2, self.ccd.shape[0])
        if d1or2 == 1:
            print(msg)
            df = self._extract_1d(ccd_key, progress_marker)
            if save2feather:
                self.df2feather(df, path)
            else:
                print('\n!!! Not saved to feather')
            return df
        else:
            print(msg)
            df = self._extract_2d(ccd_key, progress_marker)
            if save2feather:
                self.df2feather(df, path)
            else:
                print('\n!!! Not saved to feather')
            return df

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


    def _extract_1d(self, ccd_key, progress_marker):
        df_from_rows = []
        i = 0

        for row in self.ccd.itertuples():
            if progress_marker:
                if i%10 == 0:
                    print(".", end='')
                i += 1
            df_from_data = []
            row_key = {k:getattr(row, k) for k in ccd_key}

            for i, (nhic, d) in enumerate(row.data.items()):
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
        df_from_rows = []
        i = 0

        for row in self.ccd.itertuples():

            if progress_marker:
                if i%10 == 0:
                    print(".", end='')
                i += 1

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
        df['time'] = pd.to_timedelta(df['time'], unit='h')
        return df
