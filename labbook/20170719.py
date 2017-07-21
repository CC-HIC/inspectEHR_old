# Make up some time series data with a multi-index
def gap_period(df, ke):
        """Define (median) periodicity of measurement in hours"""
        # - [ ] @NOTE: (2017-07-21) working with diff() v slow
        # therefore manually shift and calculate
        res = df.copy()
        res['time_L1'] = res.groupby(ke).time.shift()
        res['gap_period'] = res['time'] - res['time_L1']
        return res.groupby(ke).gap_period.apply(np.median)

# t = pd.timedelta_range(0,periods=1E2,freq='s')
t = pd.timedelta_range(0,periods=1E2,freq='s').to_series().sample(frac=0.5)
ix1 = np.repeat(list('abcde'), 10)
ix2 = np.tile(range(10), 5)

df = pd.DataFrame({'time':t})
df = df.set_index([ix1,ix2])
df.head()



df.groupby(['level_0', 'level_1']).nunique()
df[['level_0', 'level_1']].nunique()
# df.groupby(level=[0,1]).time.diff()
df.reset_index(inplace=True)
gap_period(df, ['level_0', 'level_1']).shape

df.info()
df
df.groupby(['level_0', 'level_1'])[['time']].shift()

np.random.randn(1)
foo = pd.DataFrame({'k': range(5), 'val':np.random.randn(5)})
foo
bar = pd.DataFrame({'k': range(0), 'val':np.random.randn(0)})
bar
pd.merge(foo, bar, how='left')
