import pandas as pd
import seaborn as sns
import numpy as np
import pandas.api.types as ptypes
from statsmodels.graphics.mosaicplot import mosaic
import matplotlib.pyplot as plt



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
            ccd_key=['site_id', 'episode_id']):
        """Initiate and create a data frame for the specific items"""

        # if initial call
        if DataRaw._first_run:
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

        # - [ ] @TODO: (2017-07-16) work out how to add integer types
        if self.fspec['Datatype'] in  ['numeric']:
            fdtype = np.float
        elif self.fspec['Datatype'] in ['text', 'list', 'list / logical', 'Logical']:
            fdtype = np.str
        elif self.fspec['Datatype'] in ['Date', 'Time', 'Date/time']:
            fdtype = np.datetime64
        else:
            raise ValueError('!!! field specification datatype not recognised')

        # Grab the variable from ccd
        self.df = DataRaw.ccd.extract_one(NHICcode, as_type=fdtype)
        self.misstb = None # Don't define on initiation b/c slow

        # Define instance characteristics
        self.label = self.fspec['dataItem']
        self.nrow, self.ncol = self.df.shape
        # Define data as 1d or 2d
        if self.fspec['dateandtime']:
            self.d1d, self.d2d = False, True
        else:
            self.d1d, self.d2d = True, False

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

    def make_misstb(self, verbose=False):
        """Define missingness per episode including time dependent measures"""

        misstb = self._miss_by_episode(DataRaw.infotb, self.df, self.ccd_key)

        if self.d2d:
            gap_start = self._gap_start(DataRaw.infotb, self.df, self.ccd_key)
            misstb = pd.merge(misstb, gap_start.reset_index(), on=self.ccd_key)
            gap_stop = self._gap_stop(DataRaw.infotb, self.df, self.ccd_key)
            misstb = pd.merge(misstb, gap_stop.reset_index(), on=self.ccd_key)
            gap_period = self._gap_period(self.df, self.ccd_key)
            misstb = pd.merge(misstb, gap_period.reset_index(), on=self.ccd_key)

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
        # Contingency table
        assert ptypes.is_string_dtype(self.df['value'])
        return pd.value_counts(self.df['value'])

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
        res = pd.concat(
            [self.df['value'].describe(),
            self.misstb.loc[:,'miss_by_episode':].mean()
        ])
        return res

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
