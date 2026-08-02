import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd
 
st.title("👤 Customer Dashboard")
 
session = get_active_session()
 
# ✅ Set correct context (IMPORTANT)
session.sql("USE WAREHOUSE DEMO_WH").collect()
session.sql("USE DATABASE DEMO_DB").collect()
session.sql("USE SCHEMA CustOrders").collect()
 
# data = session.sql("""
# SELECT name, total_spent
# FROM customer_summary
# ORDER BY total_spent DESC
# """).collect()
 
 
# ✅ FIXED QUERY (Very Important)
data = session.sql("""
SELECT 
  name,
  SUM(total_spent) AS total_spent
FROM customer_summary
GROUP BY name
ORDER BY total_spent DESC
""").collect()
 
 
df = pd.DataFrame([(r[0], r[1]) for r in data],
                  columns=["NAME", "TOTAL_SPENT"])
 
st.dataframe(df)
 
st.bar_chart(df.set_index("NAME"))