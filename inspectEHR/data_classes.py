import pandas as pd
import seaborn as sns
import pandas.api.types as ptypes
from statsmodels.graphics.mosaicplot import mosaic
import matplotlib.pyplot as plt


class DataRaw:
    def __init__(self, dt, spec):
        """ Initiate and check dataframe with correct rows and dimensions.
            Extracts key variable definitions from data spec.
            This is the base class.

        Args:
            dt:
            spec:
        """
        # TODO: what are these arguments?

        self.dt = dt
        self.spec = spec
        if spec['dateandtime']:
            self.d1d, self.d2d = False, True
        else:
            self.d1d, self.d2d = True, False
        self.label = spec['dataItem']

        # Basic sanity checks
        # Check that this is a pandas data frame
        assert type(self.dt) == pd.core.frame.DataFrame
        self.nrow, self.ncol = self.dt.shape
        # Check 1 or more row is present
        assert self.nrow > 0
        # Check core column names
        colnames = ['value', 'byvar']
        assert all([i in self.dt.dtypes for i in colnames])
        # Count unique levels of index id
        self.id_nunique = self.dt.index.nunique()
        # Count missing values (NB should always be zero for 2d since constructed from list)
        self.value_nmiss = self.dt['value'].isnull().sum()
        # Define data as 1d or 2d

    def __str__(self):
        """Print helpful summary of object."""
        print(self.label, '\n')
        print(self.dt.head(), '\n')
        s = ' '.join(["Pandas dataframe with", str(self.nrow), "rows (first 5 shown)"])
        return s

    def check_dimensionality(self):
        """Checks dimensionality according to spec."""


class DataCatMixin:
    ''' Categorical data methods'''
    # def __init__(self, dt):
    #     super().__init__(dt)
    #     # Expects categories to be strings
    #     # - [ ] @TODO: (2017-06-28) allow integer categories
    #     assert ptypes.is_string_dtype(self.dt['val'])

    # tabulate values
    def tab(self):
        ''' Tabulate data (if categorical)'''
        # Contingency table
        assert ptypes.is_string_dtype(self.dt['val'])
        return pd.value_counts(self.dt['val'])

    # tabulate by site
    def tab_sites(self):
        ''' Tabulate data (if categorical) by site'''
        # use statsmodels mosaic
        assert ptypes.is_string_dtype(self.dt['val'])
        mosaic(d1d_cat, ['val','site'])
        plt.show()
        return pd.crosstab(self.dt['site'], self.dt['val'])


class DataContMixin:
    ''' Continuous data methods '''
    # def __init__(self, dt):
    #     DataRaw.__init__(self, dt)
    #     # Expects categories to be float or int
    #     assert ptypes.is_any_int_dtype(self.dt['val']) \
    #         | ptypes.is_float_dtype(self.dt['val'])

    def summ(self):
        ''' Summarise data (if numerical)'''
        return self.dt['val'].describe()

    def density(self):
        # Plot histogram
        sns.kdeplot(self.dt['val'])
        plt.show()


class Data1D(DataCatMixin, DataRaw):
    ''' A 1d version of data raw '''
    def __init__(self, dt):
        super().__init__(dt)
        print('made some 1d')


class Data2D_Cont(DataRaw, DataContMixin):
    '''
    A 2d version of DataCont
    '''
    def __init__(self, dt):
        super().__init__(dt)
        # Expects categories to be float or int
        assert ptypes.is_any_int_dtype(self.dt['val']) \
            | ptypes.is_float_dtype(self.dt['val'])
        # Check time provided
        assert 'time' in self.dt.dtypes
        print(self.dt.head())
