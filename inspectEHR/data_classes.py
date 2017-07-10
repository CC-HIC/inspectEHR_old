import pandas as pd
import seaborn as sns
import pandas.api.types as ptypes
from statsmodels.graphics.mosaicplot import mosaic
import matplotlib.pyplot as plt



class AutoMixinMeta(type):
    # https://stackoverflow.com/a/28205308/992999
    def __call__(cls, *args, **kwargs):
        try:
            mixin = kwargs.pop('mixin')
            # print(mixin)
            name = "{}With{}".format(cls.__name__, mixin.__name__)
            cls = type(name, (mixin, cls), dict(cls.__dict__))
        except KeyError:
            pass
        return type.__call__(cls, *args, **kwargs)


class DataRaw(object, metaclass=AutoMixinMeta):

    def __init__(self, dt, spec, **kwargs):
        # https://stackoverflow.com/a/12099839/992999
        """ Initiate and check dataframe with correct rows and dimensions.
            Extracts key variable definitions from data spec.
            This is the base class, and then conditionally initiates the correct inherited class


        Args:
            dt:
            spec:
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

        # Initiate the corrct class and make available appropriate methods
        if spec['dateandtime']:
            self.d1d, self.d2d = False, True
            # self.__class__ = Data2D
        else:
            self.d1d, self.d2d = True, False
            # self.__class__ = Data1D
        self.label = spec['dataItem']

        # Count unique levels of index id
        self.id_nunique = self.dt.index.nunique()
        # Count missing values (NB should always be zero for 2d since constructed from list)
        self.value_nmiss = self.dt['value'].isnull().sum()
        # Define data as 1d or 2d

    # # Action when we subclass
    # def __init__subclass(cls, bar):
    #     super().__init__subclass()
    #     print('foo and bar')
    #     cls.foo = bar

    def __str__(self):
        """Print helpful summary of object."""
        print(self.label, '\n')
        print(self.dt.head(), '\n')
        print ("Pandas dataframe with", str(self.nrow), "rows (first 5 shown)")
        print("Unique episodes", self.id_nunique, '\n')
        return "\n"


class DataCatMixin:
    ''' Categorical data methods'''

    # tabulate values
    def inspect(self):
        ''' Tabulate data (if categorical)'''
        # Contingency table
        assert ptypes.is_string_dtype(self.dt['value'])
        return pd.value_counts(self.dt['value'])

    # tabulate by site
    def plot(self):
        ''' Tabulate data (if categorical) by site'''
        # use statsmodels mosaic
        assert ptypes.is_string_dtype(self.dt['value'])
        mosaic(self.dt, ['value','byvar'])
        plt.show()
        return pd.crosstab(self.dt['byvar'], self.dt['value'])


class DataContMixin:
    ''' Continuous data methods '''

    def inspect(self):
        ''' Summarise data (if numerical)'''
        return self.dt['value'].describe()

    def plot(self):
        # Plot histogram
        sns.kdeplot(self.dt['value'])
        plt.show()


# class Data1D(DataCatMixin, DataRaw):
#     ''' A 1d version of data raw '''
#     def __init__(self, dt):
#         super().__init__(dt)
#         print('made some 1d')


# class Data2D_Cont(DataRaw, DataContMixin):
#     '''
#     A 2d version of DataCont
#     '''
#     def __init__(self, dt):
#         super().__init__(dt)
#         # Expects categories to be float or int
#         assert ptypes.is_any_int_dtype(self.dt['val']) \
#             | ptypes.is_float_dtype(self.dt['val'])
#         # Check time provided
#         assert 'time' in self.dt.dtypes
#         print(self.dt.head())

class Data2D(DataRaw, DataContMixin, DataCatMixin):
    '''
    A 2d version of DataRaw
    Borrows methods from DataCont and DataCat Mixins
    '''
    def __init__(self, dt, spec):
        super().__init__(dt, spec)
        # assert 'time' in self.dt.colnames
        print('made some 2d, spam')
        print(self.dt.head())

    def spam(self):
        '''
        testing
        '''
        print('eggs')


class Data1D(DataRaw, DataContMixin, DataCatMixin):
    '''
    A 1d version of DataRaw
    Borrows methods from DataCont and DataCat Mixins
    '''
    def __init__(self, dt, spec):
        super().__init__(dt, spec)
        print('made some 1d')
        print(self.dt.head())
