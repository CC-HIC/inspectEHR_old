# Let's play with function decorators
import pandas as pd
import numpy as np
import itertools

def expand_grid(data_dict):
    rows = itertools.product(*data_dict.values())
    return pd.DataFrame.from_records(rows, columns=data_dict.keys())

df = expand_grid(
    {'height': [150,160,170,180,190],
     'weight': [50,60,70,80,90],
     'sex': ['male', 'female']} )
df.head()

def average_height(df):
    return df.height.mean()

average_height(df)
