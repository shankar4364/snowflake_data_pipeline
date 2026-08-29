import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session
 
# ------------------------------------------------
# Snowflake Session (for Streamlit in Snowflake)
# ------------------------------------------------
 
from snowflake.snowpark import Session

connection_parameters = {
    "account": "iopukos-mpb86775",
    "user": "sb4364",
    "password": "Tejas@08082002",
    "warehouse": "COMPUTE_WH",
    "database": "GCSProject",
    # "schema": "MART",
    # "role": "ACCOUNTADMIN"
}

session = Session.builder.configs(connection_parameters).create()
 
# ------------------------------------------------
# Query Function
# ------------------------------------------------
 
@st.cache_data(ttl=60)
def run_query(query):
    return session.sql(query).to_pandas()
 
# ------------------------------------------------
# Sidebar
# ------------------------------------------------
 
st.sidebar.title("Retail Analytics Dashboard")
 
page = st.sidebar.radio(
    "Select Report",
    [
        "Sales Overview",
        "Product Sales",
        "Store Sales",
        "Customer Analysis",
        "Dynamic Table",
        "Materialized View",
        "Stream Monitoring"
    ]
)
 
# ------------------------------------------------
# SALES OVERVIEW
# ------------------------------------------------
 
if page == "Sales Overview":
 
    st.title("📊 Retail Sales Overview")
 
    total_sales = run_query("""
        SELECT COALESCE(SUM(SALES_AMOUNT),0) AS TOTAL_SALES
        FROM MART.FACT_SALES
    """)
 
    total_orders = run_query("""
        SELECT COUNT(*) AS TOTAL_ORDERS
        FROM MART.FACT_SALES
    """)
 
    col1, col2 = st.columns(2)
 
    with col1:
        st.metric(
            "Total Sales",
            f"{total_sales.iloc[0]['TOTAL_SALES']:,}"
        )
 
    with col2:
        st.metric(
            "Total Orders",
            total_orders.iloc[0]["TOTAL_ORDERS"]
        )
 
    st.subheader("Recent Sales")
 
    sales = run_query("""
        SELECT *
        FROM MART.SALES_VIEW
        ORDER BY ORDER_DATE DESC
    """)
 
    st.dataframe(sales, use_container_width=True)
 
# ------------------------------------------------
# PRODUCT SALES
# ------------------------------------------------
 
elif page == "Product Sales":
 
    st.title("📦 Product Sales Analysis")
 
    product_sales = run_query("""
        SELECT
            P.PRODUCT_NAME,
            SUM(F.SALES_AMOUNT) AS TOTAL_SALES
        FROM MART.FACT_SALES F
        JOIN MART.DIM_PRODUCTS P
        ON F.PRODUCT_ID = P.PRODUCT_ID
        GROUP BY P.PRODUCT_NAME
        ORDER BY TOTAL_SALES DESC
    """)
 
    st.dataframe(product_sales, use_container_width=True)
 
    if not product_sales.empty:
        st.bar_chart(
            product_sales.set_index("PRODUCT_NAME")["TOTAL_SALES"]
        )
 
# ------------------------------------------------
# STORE SALES
# ------------------------------------------------
 
elif page == "Store Sales":
 
    st.title("🏪 Store Performance")
 
    store_sales = run_query("""
        SELECT
            S.STORE_NAME,
            SUM(F.SALES_AMOUNT) AS TOTAL_SALES
        FROM MART.FACT_SALES F
        JOIN MART.DIM_STORES S
        ON F.STORE_ID = S.STORE_ID
        GROUP BY S.STORE_NAME
        ORDER BY TOTAL_SALES DESC
    """)
 
    st.dataframe(store_sales, use_container_width=True)
 
    if not store_sales.empty:
        st.bar_chart(
            store_sales.set_index("STORE_NAME")["TOTAL_SALES"]
        )
 
# ------------------------------------------------
# CUSTOMER ANALYSIS
# ------------------------------------------------
 
elif page == "Customer Analysis":
 
    st.title("👥 Customer Analysis")
 
    customer_data = run_query("""
        SELECT
            CUSTOMER_NAME,
            COUNT(*) AS TOTAL_ORDERS
        FROM MART.SALES_VIEW
        GROUP BY CUSTOMER_NAME
        ORDER BY TOTAL_ORDERS DESC
    """)
 
    st.dataframe(customer_data, use_container_width=True)
 
    if not customer_data.empty:
        st.bar_chart(
            customer_data.set_index("CUSTOMER_NAME")["TOTAL_ORDERS"]
        )
 
# ------------------------------------------------
# DYNAMIC TABLE
# ------------------------------------------------
 
elif page == "Dynamic Table":
 
    st.title("⚡ Dynamic Table Summary")
 
    dynamic_data = run_query("""
        SELECT *
        FROM MART.DT_SALES_SUMMARY
        ORDER BY TOTAL_SALES DESC
    """)
 
    st.dataframe(dynamic_data, use_container_width=True)
 
    if not dynamic_data.empty:
        st.bar_chart(
            dynamic_data.set_index("PRODUCT_ID")["TOTAL_SALES"]
        )
 
# ------------------------------------------------
# MATERIALIZED VIEW
# ------------------------------------------------
 
elif page == "Materialized View":
 
    st.title("🚀 Materialized View")
 
    mv_data = run_query("""
        SELECT *
        FROM MART.MV_PRODUCT_SALES
        ORDER BY TOTAL DESC
    """)
 
    st.dataframe(mv_data, use_container_width=True)
 
    if not mv_data.empty:
        st.bar_chart(
            mv_data.set_index("PRODUCT_ID")["TOTAL"]
        )
 
# ------------------------------------------------
# STREAM MONITORING
# ------------------------------------------------
 
elif page == "Stream Monitoring":
 
    st.title("🔄 Stream Monitoring")
 
    try:
 
        stream_data = run_query("""
            SELECT *
            FROM MART.ORDER_STREAM
        """)
 
        st.dataframe(stream_data, use_container_width=True)
 
        st.metric(
            "Pending Changes",
            len(stream_data)
        )
 
    except Exception as e:
        st.error(f"Stream Error: {e}")
 
# ------------------------------------------------
# Footer
# ------------------------------------------------
 
st.markdown("---")
st.caption("Snowflake Retail Analytics Dashboard")