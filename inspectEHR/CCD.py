import warnings
import numpy as np
import pandas as pd


class CCD:
    def __init__(self, json_filepath, random_sites=True, random_sites_list=list('ABCDE'),
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

    def extract(self, nhic_code, by="site_id", as_type=None):
        """ Extract an NHIC data item.

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
        return df
