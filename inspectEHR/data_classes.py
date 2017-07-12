import pandas as pd
import seaborn as sns
import pandas.api.types as ptypes
from statsmodels.graphics.mosaicplot import mosaic
import matplotlib.pyplot as plt



class AutoMixinMeta(type):
    # https://stackoverflow.com/a/28205308/992999

    def __call__(cls, *args, **kwargs):
        try:
            spec = kwargs['spec']
            # Now check the dictionary defines the datatype
            try:
                if spec['Datatype'] == 'numeric':
                    mixin = ContMixin
                elif spec['Datatype'] in ['text', 'list', 'list / logical', 'Logical']:
                    mixin = CatMixin
                elif spec['Datatype'] in ['Date', 'Time', 'Date/time']:
                    mixin = DateTimeMixin
                else:
                    raise ValueError

            except KeyError:
                print('!!! Missing Datatype field in specification')
                return type.__call__(cls, *args, **kwargs)

            except ValueError:
                print('!!! Datatype field not recognised')
                return type.__call__(cls, *args, **kwargs)

        except KeyError as e:
                print('!!! Missing specification dictionary for data')
                return type.__call__(cls, 'no spec')

        name = "{}With{}".format(cls.__name__, mixin.__name__)
        cls = type(name, (cls, mixin), dict(cls.__dict__))
        return type.__call__(cls, *args, **kwargs)


class DataRaw(object, metaclass=AutoMixinMeta):

    def __init__(self, dt, spec):
        """ Initiate and check dataframe with correct rows and dimensions.
            Extracts key variable definitions from data spec.
            This is the base class, and then conditionally picks the right mixins.

        Args:
            dt:
            spec: a dictionary containing a 'Datatype' field, and ...
        """
        self.dt = dt
        self.spec = spec

        # Basic sanity checks
        # Check that this is a pandas data frame
        assert type(self.dt) == pd.core.frame.DataFrame
        self.nrow, self.ncol = self.dt.shape
        # Check 1 or more row is present
        assert self.nrow > 0
        # Check core column names
        colnames = ['value', 'byvar']
        assert all([i in self.dt.dtypes for i in colnames])

        # Define instance characteristics
        self.label = spec['dataItem']
        if spec['dateandtime']:
            self.d1d, self.d2d = False, True
        else:
            self.d1d, self.d2d = True, False

        # Count unique levels of index id
        self.id_nunique = self.dt.index.nunique()
        # Count missing values (NB should always be zero for 2d since constructed from list)
        self.value_nmiss = self.dt['value'].isnull().sum()
        # Define data as 1d or 2d

    # Missingness does not depend on variable type so defined in base class
    def _prep_miss(self):
        '''Convert data to boolean missingness summary'''
        pass

    def data_complete(self):
        '''Report missingness by episode'''
        pass

    def data_frequency(self):
        '''Report data frequency'''
        try:
            assert self.d2d
            pass
        except AssertionError as e:
            print('!!! data is not timeseries, not possible to report observation frequency')
            return e
        pass

    def __str__(self):
        """Print helpful summary of object."""
        print(self.label, '\n')
        print(self.dt.head(), '\n')
        print ("Pandas dataframe with", str(self.nrow), "rows (first 5 shown)")
        print("Unique episodes", self.id_nunique, '\n')
        return "\n"


class CatMixin:
    ''' Categorical data methods'''

    # tabulate values
    def inspect(self):
        ''' Tabulate data (if categorical)'''
        # Contingency table
        assert ptypes.is_string_dtype(self.dt['value'])
        return pd.value_counts(self.dt['value'])

    # tabulate by site
    def plot(self, by=False, mosaic=False, **kwargs):
        ''' Tabulate data (if categorical) by site
        options for plotting by strata
        option for mosaic'''
        if by:
            if mosaic==True:
                # use statsmodels mosaic
                mosaic(self.dt, ['value','byvar'], **kwargs)
            else:
                sns.factorplot('value',
                    col='byvar',
                    data=self.dt,
                    kind='count', **kwargs)
        else:
            sns.countplot(self.dt['value'], **kwargs)
        plt.show()


class ContMixin:
    ''' Continuous data methods '''

    def inspect(self):
        ''' Summarise data (if numerical)'''
        return self.dt['value'].describe()

    def plot(self, by=False, **kwargs):
        if by:
            for name, grp in self.dt.groupby('byvar'):
                sns.kdeplot(self.dt['value'], **kwargs)
        else:
            sns.kdeplot(self.dt['value'], **kwargs)
        plt.show()


class DateTimeMixin:
    ''' Date/Time methods'''
    pass
