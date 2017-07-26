#! python
# Import JSON and load into SQLlite
# Makes an infotb table with the basic data information for each episode

# TODO
# - [ ] @TODO: (2017-07-15) optimise storage: (integer for NHIC code not string)
# - [ ] @TODO: (2017-07-15) optimise storage: single integer id to link to site/episode key
# - [ ] @TODO: (2017-07-15) store 2d as json (then split out 1d) into separate tables


import sqlite3
import json
import os
import pandas as pd

# Load JSON data
# json_data_path = os.path.join('data-raw', 'anon_public_da1000.JSON')
json_data_path = os.path.join('data-raw', 'anon_internal.JSON')
with open(json_data_path) as fin:
    episodes = json.load(fin)
print('loaded json')
print(episodes[:1])

infotb_fields = {
    'site_id': 'TEXT',
    'episode_id': 'INT',
    'nhs_number': 'INT',
    'pas_number': 'TEXT',
    't_admission': 'INT', # seconds
    't_discharge': 'INT', # seconds
    'parse_file': 'TEXT',
    'parse_time': 'INT', # seconds
    'pid': 'INT',
    'spell': 'INT'}

# Makes and saves db to disk
conn = sqlite3.connect('ccd.db')
c = conn.cursor()

# Prepare infotb table

query = "DROP TABLE IF EXISTS infotb"
c.execute(query)
fields = ', '.join([k + ' ' + v for k,v in infotb_fields.items() if k != 'data'])
query = "CREATE TABLE IF NOT EXISTS infotb(" + fields + ")"
c.execute(query)

# Load into infotb
# for episode in episodes[:3]:
for episode in episodes:
    infotb_values = [v for k,v in episode.items() if k != 'data' ]
    # Specifically retrieve spell and pid (within data object)
    # - [ ] @TODO: (2017-07-14) add try keyerror logic
    infotb_values.append(episode['data']['pid'])
    infotb_values.append(episode['data']['spell'])
    # print(infotb_values)
    # - [ ] @TODO: (2017-07-14) switch to named pairs rather than relying on order
    query = "insert into infotb VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    c.execute(query, infotb_values)


c.execute("select * from infotb")
print(c.fetchone())
print('loaded infotb')

# - [ ] @NOTE: (2017-07-14) messy way of handling index that is generated via itertuples
# which means that we have to drop the column by recreating the whole table at the end

# Now do the same for the 1d data
query = "DROP TABLE IF EXISTS item_tb"
c.execute(query)
# use tmp field as throw away
query = "CREATE TABLE IF NOT EXISTS item_tb(site_id TEXT, episode_id INT, time REAL, NHICcode TEXT, value, tmp)"
c.execute(query)

for episode in episodes:
    val_dict = {rk:rv for rk,rv in episode.items() if rk in ['site_id', 'episode_id']}
    for k,v in episode['data'].items():
        # Ignore the pid and spell data items (extracted already)
        if k in ['pid', 'spell']:
            continue
        else:
            if type(v) is dict:
                # assumes dict indicates a 2d items
                df = pd.DataFrame.from_records(
                    list(zip(v['item2d'], v['time'])),
                    columns=['value', 'time'])
                df['NHICcode'] = k
                df['site_id'] = episode['site_id']
                df['episode_id'] = episode['episode_id']
                df.rename_axis('tmp')
                cols = list(df.columns)
                cols.insert(0, 'tmp')
                query = "insert into item_tb (" + ", ".join(cols) + ")" + " VALUES(:" + ", :".join(cols) + ")"
                c.executemany(query, df.itertuples())
            else:
                # 1d items
                val_dict['NHICcode'] = k
                val_dict['value'] = v
                q1 = "insert into item_tb (site_id, episode_id, NHICcode, value)"
                q2 = "VALUES(:site_id, :episode_id, :NHICcode, :value)"
                query = q1 + q2
                c.execute(query, val_dict)

conn.commit()
# list(df.columns)
# df.head()


# Cannot drop column so let's recreate table
query = "DROP TABLE IF EXISTS tmp"
c.execute(query)
query = "CREATE TABLE IF NOT EXISTS tmp(site_id TEXT, episode_id INT, time REAL, NHICcode TEXT, value)"
c.execute(query)
conn.commit()
query = "INSERT INTO tmp (site_id, episode_id, time, NHICcode, value) SELECT site_id, episode_id, time, NHICcode, value FROM item_tb"
c.execute(query)
conn.commit()
c.execute("DROP TABLE IF EXISTS item_tb")
c.execute("ALTER TABLE tmp RENAME TO item_tb")
conn.commit()


c.execute("select * from item_tb")
c.fetchone()

# Make covering index (not particularly fast for retrieving NHICcode)
c.execute("CREATE INDEX  IF NOT EXISTS cover ON item_tb \
        (site_id, NHICcode, episode_id, time, value) ")

c.execute("CREATE INDEX  IF NOT EXISTS nhic ON item_tb \
        ( NHICcode) ")

conn.close()
