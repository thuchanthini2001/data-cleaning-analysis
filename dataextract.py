--
import pandas as pd
df = pd.read_csv('netflix_titles.csv')

import sqlalchemy as sal
engine = sal.create_engine(r'mssql://THUCHANTHINI\SQLEXPRESS/master?driver=ODBC+DRIVER+17+FOR+SQL+SERVER', fast_executemany=True)
conn = engine.connect()

df.to_sql('net_raw', con=conn, index=False, if_exists='append')
conn.close()

df.head()
df[df.show_id == 's5023']
max(df.title.str.len())
df.isna().sum()
