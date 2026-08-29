import streamlit as st
import pandas as pd
import plotly.express as px
from snowflake.snowpark.context import get_active_session

# --------------------------------------------------
# PAGE CONFIG
# --------------------------------------------------

st.set_page_config(
    page_title="FinSight",
    page_icon="💰",
    layout="wide"
)

st.title("💰 FinSight Personal Finance Analytics Platform")

# --------------------------------------------------
# SNOWFLAKE SESSION
# --------------------------------------------------

session = get_active_session()

# --------------------------------------------------
# LOAD DATA FUNCTION
# --------------------------------------------------

@st.cache_data
def load_data(query):
    return session.sql(query).to_pandas()

# --------------------------------------------------
# LOAD VIEWS
# --------------------------------------------------

monthly_expense = load_data("""
SELECT *
FROM FINSIGHT_DB.PUBLIC.VW_MONTHLY_EXPENSE
ORDER BY MONTH
""")

category_expense = load_data("""
SELECT *
FROM FINSIGHT_DB.PUBLIC.VW_CATEGORY_EXPENSE
""")

income_expense = load_data("""
SELECT *
FROM FINSIGHT_DB.PUBLIC.VW_INCOME_EXPENSE
ORDER BY MONTH
""")

top_merchants = load_data("""
SELECT *
FROM FINSIGHT_DB.ANALYTICS.VW_TOP_MERCHANTS
LIMIT 10
""")

savings_data = load_data("""
SELECT *
FROM FINSIGHT_DB.ANALYTICS.VW_SAVINGS
""")

# --------------------------------------------------
# KPI SECTION
# --------------------------------------------------

income = savings_data["INCOME"][0]
expense = savings_data["EXPENSE"][0]
savings = savings_data["SAVINGS"][0]

savings_rate = 0

if income > 0:
    savings_rate = round(
        (savings / income) * 100,
        2
    )

col1, col2, col3, col4 = st.columns(4)

col1.metric(
    "💵 Income",
    f"₹{income:,.0f}"
)

col2.metric(
    "💸 Expense",
    f"₹{expense:,.0f}"
)

col3.metric(
    "🏦 Savings",
    f"₹{savings:,.0f}"
)

col4.metric(
    "📊 Savings %",
    f"{savings_rate}%"
)

st.divider()

# --------------------------------------------------
# CATEGORY EXPENSE PIE CHART
# --------------------------------------------------

st.subheader("📊 Category Wise Expenses")

fig1 = px.pie(
    category_expense,
    names="CATEGORY",
    values="EXPENSE",
    hole=0.4
)

st.plotly_chart(
    fig1,
    use_container_width=True
)

# --------------------------------------------------
# MONTHLY EXPENSE TREND
# --------------------------------------------------

st.subheader("📈 Monthly Spending Trend")

fig2 = px.line(
    monthly_expense,
    x="MONTH",
    y="EXPENSE",
    markers=True
)

st.plotly_chart(
    fig2,
    use_container_width=True
)

# --------------------------------------------------
# INCOME VS EXPENSE
# --------------------------------------------------

st.subheader("💰 Income vs Expense")

fig3 = px.bar(
    income_expense,
    x="MONTH",
    y=["INCOME", "EXPENSE"],
    barmode="group"
)

st.plotly_chart(
    fig3,
    use_container_width=True
)

# --------------------------------------------------
# TOP MERCHANTS
# --------------------------------------------------

st.subheader("🏪 Top Merchants")

fig4 = px.bar(
    top_merchants,
    x="DESCRIPTION",
    y="TOTAL_SPEND",
    color="TOTAL_SPEND"
)

st.plotly_chart(
    fig4,
    use_container_width=True
)

# --------------------------------------------------
# FINANCIAL HEALTH
# --------------------------------------------------

st.subheader("❤️ Financial Health")

if savings_rate >= 40:

    st.success(
        f"Excellent Savings Habit ({savings_rate}%)"
    )

elif savings_rate >= 20:

    st.info(
        f"Good Savings Habit ({savings_rate}%)"
    )

elif savings_rate >= 10:

    st.warning(
        f"Average Savings Habit ({savings_rate}%)"
    )

else:

    st.error(
        f"High Spending Pattern ({savings_rate}%)"
    )

# --------------------------------------------------
# DATA TABLES
# --------------------------------------------------

with st.expander("View Category Expense Details"):
    st.dataframe(category_expense)

with st.expander("View Monthly Expense Details"):
    st.dataframe(monthly_expense)

with st.expander("View Top Merchants"):
    st.dataframe(top_merchants)