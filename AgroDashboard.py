import streamlit as st
import pandas as pd
from snowflake.snowpark import Session

from dotenv import load_dotenv
import os

load_dotenv()

connection_parameters = {
    "account": os.getenv("SNOWFLAKE_ACCOUNT"),
    "user": os.getenv("SNOWFLAKE_USER"),
    "password": os.getenv("SNOWFLAKE_PASSWORD"),
    "warehouse": os.getenv("SNOWFLAKE_WAREHOUSE"),
    "database": os.getenv("SNOWFLAKE_DATABASE"),
    "schema": os.getenv("SNOWFLAKE_SCHEMA"),
    "role": os.getenv("SNOWFLAKE_ROLE")
}

session = Session.builder.configs(connection_parameters).create()

# ---------------------------------------
# Page Settings
# ---------------------------------------

st.set_page_config(
    page_title="AgriInsight Dashboard",
    page_icon="🌾",
    layout="wide"
)

st.title("🌾 AgriInsight Analytics Platform")

# ---------------------------------------
# Sidebar
# ---------------------------------------

page = st.sidebar.selectbox(
    "Select Analytics",
    [
        "Dashboard",
        "Crop Analytics",
        "Rainfall Analytics",
        "Soil Analytics",
        "Fertilizer Analytics",
        "Pipeline Monitoring"
    ]
)

# =======================================
# DASHBOARD
# =======================================

if page == "Dashboard":

    st.header("Agriculture KPI Dashboard")

    df = session.sql("""
        SELECT
        SUM(TOTAL_PRODUCTION) AS TOTAL_PRODUCTION,
        AVG(AVG_RAINFALL) AS AVG_RAINFALL,
        SUM(TOTAL_FARMERS) AS TOTAL_FARMERS,
        COUNT(DISTINCT DISTRICT) AS TOTAL_DISTRICTS
        FROM AWS_DB.CURATED.AGRI_KPI
    """).to_pandas()

    col1, col2, col3, col4 = st.columns(4)

    col1.metric(
        "Total Production",
        round(float(df.iloc[0]["TOTAL_PRODUCTION"]),2)
    )

    col2.metric(
        "Average Rainfall",
        round(float(df.iloc[0]["AVG_RAINFALL"]),2)
    )

    col3.metric(
        "Total Farmers",
        int(df.iloc[0]["TOTAL_FARMERS"])
    )

    col4.metric(
        "Districts",
        int(df.iloc[0]["TOTAL_DISTRICTS"])
    )

# =======================================
# CROP ANALYTICS
# =======================================

elif page == "Crop Analytics":

    st.header("🌾 Crop Production Analytics")

    crop_df = session.sql("""
        SELECT
        CROP_NAME,
        SUM(TOTAL_PRODUCTION) PRODUCTION
        FROM AWS_DB.CURATED.DISTRICT_SUMMARY
        GROUP BY CROP_NAME
        ORDER BY PRODUCTION DESC
    """).to_pandas()

    st.subheader("Crop Production")

    st.bar_chart(
        crop_df,
        x="CROP_NAME",
        y="PRODUCTION"
    )

    st.dataframe(crop_df)

# =======================================
# RAINFALL ANALYTICS
# =======================================

elif page == "Rainfall Analytics":

    st.header("🌧 Rainfall Analytics")

    rain_df = session.sql("""
        SELECT
        DISTRICT,
        AVG(AVG_RAINFALL) RAINFALL
        FROM AWS_DB.CURATED.DISTRICT_SUMMARY
        GROUP BY DISTRICT
        ORDER BY RAINFALL DESC
    """).to_pandas()

    st.bar_chart(
        rain_df,
        x="DISTRICT",
        y="RAINFALL"
    )

    st.dataframe(rain_df)

# =======================================
# SOIL ANALYTICS
# =======================================

elif page == "Soil Analytics":

    st.header("🌱 Soil Analytics")

    soil_df = session.sql("""
        SELECT
        DISTRICT,
        AVG(AVG_PH) PH_LEVEL
        FROM AWS_DB.CURATED.DISTRICT_SUMMARY
        GROUP BY DISTRICT
        ORDER BY PH_LEVEL DESC
    """).to_pandas()

    st.bar_chart(
        soil_df,
        x="DISTRICT",
        y="PH_LEVEL"
    )

    st.dataframe(soil_df)

# =======================================
# FERTILIZER ANALYTICS
# =======================================

elif page == "Fertilizer Analytics":

    st.header("🧪 Fertilizer Analytics")

    fert_df = session.sql("""
        SELECT
        DISTRICT,
        SUM(FERTILIZER_USED) FERTILIZER_USED
        FROM AWS_DB.CURATED.DISTRICT_SUMMARY
        GROUP BY DISTRICT
        ORDER BY FERTILIZER_USED DESC
    """).to_pandas()

    st.bar_chart(
        fert_df,
        x="DISTRICT",
        y="FERTILIZER_USED"
    )

    st.dataframe(fert_df)

# =======================================
# PIPELINE MONITORING
# =======================================

elif page == "Pipeline Monitoring":

    st.header("⚙️ Snowflake Pipeline Monitoring")

    st.subheader("Streams")

    streams = session.sql(
        "SHOW STREAMS"
    ).to_pandas()

    st.dataframe(streams)

    st.subheader("Tasks")

    tasks = session.sql(
        "SHOW TASKS"
    ).to_pandas()

    st.dataframe(tasks)

    st.subheader("Pipes")

    pipes = session.sql(
        "SHOW PIPES"
    ).to_pandas()

    st.dataframe(pipes)

    st.subheader("Task History")

    history = session.sql("""
        SELECT *
        FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
    """).to_pandas()

    st.dataframe(history)

