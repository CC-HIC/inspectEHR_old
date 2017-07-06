# Example of how to inspect using classes
import numpy as np
import pandas as pd
import seaborn as sns
import pandas.api.types as ptypes
import statsmodels.api as sm
from statsmodels.graphics.mosaicplot import mosaic
import matplotlib.pyplot as plt
from pprint import pprint as pp
import os
import yaml

# - [ ] @NOTE: (2017-07-06) check path when working interactively
# %pwd
# Import your own packages
from inspectEHR.libs.inspectEHR import inspectEHR as ihr

# Global variables
ccd_file = "inspectEHR/data/anon_public_da1000.JSON"
ref_file = "inspectEHR/data-raw/N_DataItems.yml"
# Import spec
with open(ref_file, 'r') as f:
    refs = yaml.load(f)

# Import data
with open(ccd_file, 'r') as f:
    ccd = pd.read_json(f)

# Generate a range of sites and set up unique identifier
ccd = ihr.gen_rand_sites(ccd)
ccd = ihr.gen_id(ccd)

# Generate data for testing
# Heart rate
n0108 = ihr.extract(ccd, 'NIHR_HIC_ICU_0108', as_type=np.int)
# Lactate
n0122 = ihr.extract(ccd, 'NIHR_HIC_ICU_0122', as_type=np.float)
# Sex
n0093 = ihr.extract(ccd, 'NIHR_HIC_ICU_0093', as_type=np.str)

n0108.head(1)

# Base class
class DataRaw(object):
    def __init__(self, dt, spec):
        '''
        Initiate and check dataframe with correct rows and dimensions
        Extracts key variable definitions from data spec
        This is the base class
        '''
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
        ''' Print helpful summary of object '''
        print(self.label, '\n')
        print(self.dt.head(), '\n')
        s = ' '.join(["Pandas dataframe with", str(self.nrow), "rows (first 5 shown)"])
        return s



d0108 = DataRaw(n0108, refs['NIHR_HIC_ICU_0108'])
print(d0108)
d0108.d1d
print(d0108.nrow,d0108.ncol)
d0108.dt.head(2)
d0108.id_nunique
print(d0108)

d0093 = DataRaw(n0093)
d0093.value_nmiss
d0093.dt['value'].isnull().sum()




# Load example data as pandas
# d1d = pd.read_csv(os.path.join('inspectEHR', 'data', 'height.csv'))
# d1d.head()
# d1d_cat = pd.read_csv(os.path.join('inspectEHR', 'data', 'sex.csv'))
# d1d_cat.head()
# d2d = pd.read_csv(os.path.join('inspectEHR', 'data', 'hrate.csv'))
# d2d.head()

# demo data
# d = pd.DataFrame({'x': range(5), 'y': [0.0,0.1,0.2,0.3,0.5]})
# assert ptypes.is_any_int_dtype(d['x']) | ptypes.is_float_dtype(d['y'])

# Numerical summary
type(d1d['val'].describe())
d1d['val'].plot(kind='hist', bins=30)
d1d['val'].describe()

# Seaborn
d1d['val'].hist()
plt.show()
sns.kdeplot(d1d['val'])
plt.show()
d1d['val'].hist()



# Contingency table
pd.crosstab(d1d_cat['site'], d1d_cat['val'])
pd.crosstab(d1d_cat['site'], d1d_cat['val']).apply(lambda r: 100*r/r.sum(), axis=1)
p = mosaic(d1d_cat, ['site','val'])
plt.show()




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


sex = DataCat(d1d_cat)
sex.tab()
sex.tab_sites()

heights = DataCont(d1d)
heights.summ()
heights.density()
heights.inspect()
print(heights)


# type(heights.val)
# heights.val.mean()
#
# print("here's looking at you")
# print(heights)

heights = Data1D(d1d)
heights.inspect()

hrates = Data2D_Cont(d2d)
hrates.inspect()
hrates.density()
hrates.summ()
print(hrates)
