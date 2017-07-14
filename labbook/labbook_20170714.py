# Import JSON and load into SQLlite
import sqlite3
import json
import os

# Load JSON data
json_data_path = os.path.join('data-raw', 'anon_public_da1000.JSON')
with open(json_data_path) as fin:
    episodes = json.load(fin)
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


# Now do the same for the 1d data
query = "DROP TABLE IF EXISTS item_tb"
c.execute(query)
query = "CREATE TABLE IF NOT EXISTS item_tb(site_id TEXT, episode_id INT, time INT, NHICcode TEXT, value)"
c.execute(query)
# for episode in episodes[:1]:
for episode in episodes:
    for k,v in episode['data'].items():
        if k in ['pid', 'spell']:
            continue
        else:
            val_dict = {rk:rv for rk,rv in episode.items() if rk in ['site_id', 'episode_id']}
            # 2d items
            if type(v) is dict:
                pass
            # 1d items
            else:
                # print(k, v)
                val_dict['NHICcode'] = k
                val_dict['value'] = v
                q1 = "insert into item_tb (site_id, episode_id, NHICcode, value)"
                q2 = "VALUES(:site_id, :episode_id, :NHICcode, :value)"
                query = q1 + q2
                c.execute(query, val_dict)


    # infotb_values = [v for k,v in episode.items() if k != 'data' ]
    # print(infotb_values)

conn.commit()
conn.close()
