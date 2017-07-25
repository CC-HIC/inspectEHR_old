import pandas as pd
import seaborn as sns
import numpy as np
import pandas.api.types as ptypes
from statsmodels.graphics.mosaicplot import mosaic
import matplotlib.pyplot as plt
from collections import OrderedDict



class AutoMixinMeta(type):
    # https://stackoverflow.com/a/28205308/992999

    def __call__(cls, *args, **kwargs):
        # - [ ] @TODO: (2017-07-16) allow just 4 digit version of code

        NHICcode = args[0]

        # get field dictionary
        try:
            _spec = getattr(DataRaw, 'spec')
            # fspec = DataRaw.spec[NHICcode]
        except AttributeError as e:
            try:
                _spec = kwargs['spec']
            except KeyError as e:
                raise KeyError('!!! Data dictionary (fspec) not provided as keyword argument')

        # get field spec
        try:
            fspec = _spec[NHICcode]
        except KeyError as e:
            raise KeyError('!!! {} not found in {}.format(NHICcode, spec)')

        # Now check the dictionary defines the datatype
        try:
            if fspec['Datatype'] == 'numeric':
                mixin = ContMixin
            elif fspec['Datatype'] in ['text', 'list', 'list / logical', 'Logical']:
                mixin = CatMixin
            elif fspec['Datatype'] in ['Date', 'Time', 'Date/time']:
                mixin = DateTimeMixin
            else:
                raise ValueError
        except KeyError:
            raise KeyError("!!! Missing 'Datatype' in specification")
        except ValueError:
            raise ValueError('!!! Datatype field not recognised')

        name = "{}With{}".format(cls.__name__, mixin.__name__)
        cls = type(name, (cls, mixin), dict(cls.__dict__))

        return type.__call__(cls, *args, **kwargs)

class DataRaw(object, metaclass=AutoMixinMeta):
    """ Initiate and check dataframe with correct rows and dimensions.
        Extracts key variable definitions from data spec.
        This is the base class, and then conditionally picks the right mixins.

    Args:
        NHICcode:
        ccd:
        spec: data dictionary
    """

    # - [ ] @NOTE: (2017-07-20) these values will persist for this instance
    _first_run = True
    _foo = 0

    def __init__(self, NHICcode, ccd=None, spec=None,
            ccd_key=['site_id', 'episode_id'], first_run = False):
        """Initiate and create a data frame for the specific items"""

        # if initial call (either by default, or explicitly)
        if DataRaw._first_run or first_run:
            if ccd is None or spec is None:
                raise ValueError("First call requires ccd and spec args")
            else:
                print('*** First initialisation of DataRaw class')
                setattr(DataRaw,  'ccd', ccd )
                setattr(DataRaw,  'infotb', ccd.infotb )
                setattr(DataRaw,  'spec', spec )
                if not all([k in self.infotb.columns for k in ccd_key]):
                    raise KeyError('!!! ccd_key should be a list of column names')
                else:
                    setattr(DataRaw,  'ccd_key', ccd_key)
                DataRaw._first_run = False
                print('*** Class variables ccd and spec initiated')

        self.NHICcode = NHICcode
        self.fspec = DataRaw.spec[NHICcode]
        self.fdtype = self._datatype_to_pandas(self.fspec['Datatype'])

        # - [ ] @TODO: (2017-07-16) work out how to add integer types

        # Grab the variable from ccd
        self.df = DataRaw.ccd.extract_one(NHICcode)

        # Convert to correct type and record data quality
        self.categories = None # will be reset if datatype is categorical
        self.coerced_values = pd.Series([], dtype='str')
        self._convert_type()

        self.misstb = None # Don't define on initiation b/c slow

        # Define instance characteristics
        self.label = self.fspec['dataItem']
        self.nrow, self.ncol = self.df.shape
        # Define data as 1d or 2d
        if self.fspec['NHICdtCode'] is None:
            self.d1d, self.d2d = True, False
        else:
            self.d1d, self.d2d = False, True

        # Count unique levels of index id
        self.id_nunique = self.df.index.nunique()
        # Count missing values (NB should always be zero for 2d since constructed from list)
        self.value_nmiss = self.df['value'].isnull().sum()

        DataRaw._foo += 1


    def __len__(self):
        return len(self.df)

    def __getitem__(self, rownum):
        return self.df.iloc[rownum]

    def __repr__(self):
        return str(self.df)

    def __str__(self):
        """Print helpful summary of object."""
        print(self.label, '\n')
        print(self.df.head(), '\n')
        print ("Pandas dataframe with", str(self.nrow), "rows (first 5 shown)")
        print("Unique episodes", self.id_nunique, '\n')
        return "\n"

    @staticmethod
    def _datatype_to_pandas(s):
        """Given a string, identify the correct pandas or np data type
        Returns the appropriate string so use as
        dtype='int' not np.int"""
        if s in  ['numeric']:
            fdtype = 'float' # no numeric type, therefore this is most general
        elif s in ['text']:
            fdtype = 'str'
        elif s in ['list', 'list / logical', 'Logical']:
            fdtype = 'category' # pd.Categorical
        elif s in ['Date', 'Time', 'Date/time']:
            fdtype = 'datetime64'
        else:
            raise ValueError('!!! field specification datatype not recognised')
        return fdtype

    def _convert_type(self):
        """Convert data to specified type."""
        # Turn off modification of slice warnings
        pd.options.mode.chained_assignment = None  # default='warn'

        if self.fdtype == 'float':
            self.coerced_values = self.not_numeric(self.df.value)
            # must use NaN not None below
            self.df.value = self.df.value.replace(' ', np.NaN)
            self.df.value = pd.to_numeric(self.df.value, errors='coerce', downcast='integer')
        elif self.fdtype == 'str':
            # no change required as should be text by default
            pass
        elif self.fdtype == 'category':
            self.df.value = pd.Categorical(self.df.value)
            self.categories = self.df.value.cat.categories

        elif self.fdtype == 'datatime64':
            pass
        else:
            raise ValueError('!!! field specification datatype not recognised')
        pd.options.mode.chained_assignment = 'warn'  # default='warn'
        # Python convention to return None if changing in place
        return None

    @staticmethod
    def not_numeric(v):
        """Returns an array of those the values in s that are coerced"""
        mask_orig = v.isnull()
        mask_coerce = pd.to_numeric(v, errors='coerce', downcast='integer').isnull()
        return v.loc[np.logical_and(mask_coerce, np.logical_not(mask_orig))]


    def make_misstb(self, verbose=False):
        """Define missingness per episode including time dependent measures"""

        misstb = self._miss_by_episode(DataRaw.infotb, self.df, self.ccd_key)

        if self.d2d and len(self.df) > 0:
            gap_start = self._gap_start(DataRaw.infotb, self.df, self.ccd_key)
            misstb = pd.merge(misstb, gap_start.reset_index(), on=self.ccd_key, how='left')
            gap_stop = self._gap_stop(DataRaw.infotb, self.df, self.ccd_key)
            misstb = pd.merge(misstb, gap_stop.reset_index(), on=self.ccd_key, how='left')
            gap_period = self._gap_period(self.df, self.ccd_key)
            misstb = pd.merge(misstb, gap_period.reset_index(), on=self.ccd_key, how='left')

        self.misstb = misstb

        if verbose:
            print('*** Missing data table saved as self.misstb\ne.g.\n')
            print(misstb.loc[:5,'miss_by_episode':])



    @staticmethod
    def _miss_by_episode(infotb, df, ke):
        """Report if any data available for each episode in infotb
        Args:
            ke: key columns for infotb
            infotb:
            df: dataframe of 1d or 2d data
        Yields:
            dataframe with key cols and boolean if present in data
        """
        res = infotb[ke]
        df_episodes = df[ke].drop_duplicates()
        res = pd.merge(res, df_episodes, on=ke,  how='left', indicator=True)
        # there's shouldn't be an index in the data that is not in infotb
        assert len(res[res['_merge']=='right_only']) == 0
        res.loc[res._merge == 'both', 'miss_by_episode'] = False
        res.loc[res._merge == 'left_only', 'miss_by_episode'] = True
        res.drop('_merge', axis=1, inplace=True)
        return res

    @staticmethod
    def _gap_start(infotb, df, ke, tstart = 't_admission'):
        """Report delay before first 2d observation"""
        tmin = df.groupby(by=ke).time.min().reset_index()
        cols = ke.copy()
        cols.append(tstart)
        res = infotb[cols]
        res = pd.merge(res, tmin , on=ke,  how='left')
        res['gap_start'] = res.time - res[tstart]
        return res.set_index(ke).gap_start

    @staticmethod
    def _gap_stop(infotb, df, ke, tstop = 't_discharge'):
        """Report delay after last 2d observation"""
        tmax = df.groupby(by=ke).time.max().reset_index()
        cols = ke.copy()
        cols.append(tstop)
        res = infotb[cols]
        res = pd.merge(res, tmax , on=ke,  how='left')
        res['gap_stop'] = res.time - res[tstop]
        return res.set_index(ke).gap_stop

    @staticmethod
    def _gap_period(df, ke, method=np.median):
        """Define (median) periodicity of measurement in hours"""
        # - [ ] @NOTE: (2017-07-21) working with diff() v slow
        # therefore manually shift and calculate
        res = df.copy()
        res['time_L1'] = res.groupby(ke).time.shift()
        res['gap_period'] = res['time'] - res['time_L1']
        res = res.groupby(ke).gap_period.apply(method)
        return res

class CatMixin:
    ''' Categorical data methods'''

    # tabulate values
    def inspect(self):
        ''' Tabulate data (if categorical)'''
        # Build missing data if not already done
        if self.misstb is None:
            self.make_misstb(verbose=False)
        # Mini data frame with levels and missingness
        rows = []
        row_keys = ['NHICcode', 'level', 'count', 'n', 'pct', 'nunique', 'miss_by_episode', 'gap_start', 'gap_stop', 'gap_period']
        row = OrderedDict.fromkeys(row_keys)
        vals = self.df['value']

        # Header row
        # ==========
        row['NHICcode'] = self.NHICcode
        row['level'] = 'header'
        row['nunique'] = vals.nunique()
        row['count'] = len(vals)
        row['coerced'] = len(self.coerced_values)

        row_miss = self.misstb.loc[:,'miss_by_episode':].mean()
        # for some reason, can't write this as a list comprehension
        for k,v in row_miss.iteritems():
            row[k] = v

        rows.append(pd.Series(row))

        # now repeat for levels of variable
        # =================================
        for lvl in vals.cat.categories:
            row = OrderedDict.fromkeys(row_keys)
            # Header row
            row['NHICcode'] = self.NHICcode
            row['level'] = lvl
            row['n'] = vals.loc[vals == lvl].count()
            row['pct'] = row['n'] / len(vals)
            rows.append(pd.Series(row))

        return pd.DataFrame(rows)


    # tabulate by site
    def plot(self, by=False, mosaic=False, **kwargs):
        ''' Tabulate data (if categorical) by site
        options for plotting by strata
        option for mosaic'''
        if by:
            if mosaic==True:
                # use statsmodels mosaic
                mosaic(self.df, ['value','byvar'], **kwargs)
            else:
                sns.factorplot('value',
                    col='byvar',
                    data=self.df,
                    kind='count', **kwargs)
        else:
            sns.countplot(self.df['value'], **kwargs)
        plt.show()


class ContMixin:
    ''' Continuous data methods '''

    def inspect(self):
        ''' Summarise data (if numerical)
        includes mean gap data (but median might be more appropriate)'''

        if self.misstb is None:
            self.make_misstb(verbose=False)
        res = pd.concat([
                pd.Series(
                        [self.NHICcode, len(self.coerced_values)],
                        index=['NHICcode', 'coerced_values']),
                self.df['value'].describe(),
                self.misstb.loc[:,'miss_by_episode':].mean()
        ])
        # although single row, return as dataframe for consistency with cat version
        # and transpose so wide not long
        return pd.DataFrame(res).T

    def plot(self, by=False, **kwargs):
        if by:
            for name, grp in self.df.groupby('byvar'):
                sns.kdeplot(self.df['value'], **kwargs)
        else:
            sns.kdeplot(self.df['value'], **kwargs)
        plt.show()


class DateTimeMixin:
    ''' Date/Time methods'''
    pass

class TextMixin:
    ''' Text methods'''
    pass
