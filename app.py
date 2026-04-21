import streamlit as st
import pandas as pd
import plotly.express as px
import os

st.set_page_config(page_title="QuickKart Dashboard", layout="wide")

# 1. DEFINE THE DIRECTORY PATH
# This is the folder where all your CSVs are stored
folder_path = r"C:\Users\DELL\Downloads\QuickKart_TakeHome_Brief\quickkart_dataset"

st.title("📦 QuickKart Marketplace Performance")

@st.cache_data
def load_data():
    try:
        # Construct full paths for each file
        cust = pd.read_csv(os.path.join(folder_path, "customers.csv"))
        ords = pd.read_csv(os.path.join(folder_path, "orders.csv"))
        items = pd.read_csv(os.path.join(folder_path, "order_items.csv"))
        ship = pd.read_csv(os.path.join(folder_path, "shipments.csv"))
        prod = pd.read_csv(os.path.join(folder_path, "products.csv"))

        # Convert dates
        ords['created_at'] = pd.to_datetime(ords['created_at'])
        
        # Calculate GMV
        items['item_gmv'] = items['quantity'] * items['unit_price']
        
        # Merge all data into one master table
        df = ords.merge(items, on='order_id')
        df = df.merge(prod, on='product_id')
        df = df.merge(cust, on='customer_id')
        df = df.merge(ship[['order_id', 'carrier', 'delivery_status']], on='order_id')
        
        # Create Month column for trend chart
        df['month'] = df['created_at'].dt.to_period('M').dt.to_timestamp()
        
        # Create Delay flag (1 if Late, 0 otherwise)
        df['is_delayed'] = df['delivery_status'].str.contains('Late', na=False).astype(int)
        
        return df
    except Exception as e:
        st.error(f"⚠️ Could not load files. Error: {e}")
        st.info(f"Check if your files are actually in: {folder_path}")
        return None

# Load the data
df = load_data()

# Only run the dashboard if data loaded successfully
if df is not None:
    # --- SIDEBAR FILTERS ---
    st.sidebar.header("Dashboard Controls")
    
    cities = st.sidebar.multiselect("Select Cities", options=sorted(df['city'].unique()), default=df['city'].unique()[:5])
    carriers = st.sidebar.multiselect("Select Carriers", options=df['carrier'].unique(), default=df['carrier'].unique())
    metric = st.sidebar.radio("Select Metric", ["GMV", "Orders", "Delayed Order Rate"])

    # Filter the dataframe
    mask = (df['city'].isin(cities)) & (df['carrier'].isin(carriers))
    f_df = df[mask]

    # --- KPI STRIP ---
    kpi1, kpi2, kpi3 = st.columns(3)
    
    total_gmv = f_df['item_gmv'].sum()
    total_orders = f_df['order_id'].nunique()
    delay_rate = f_df['is_delayed'].mean()

    kpi1.metric("Total GMV", f"₹{total_gmv:,.0f}")
    kpi2.metric("Total Orders", f"{total_orders:,}")
    kpi3.metric("Delay Rate", f"{delay_rate:.1%}")

    # --- CHARTS ---
    col_a, col_b = st.columns(2)

    with col_a:
        st.subheader("Monthly Trend")
        trend_data = f_df.groupby('month').agg({'item_gmv':'sum', 'order_id':'nunique', 'is_delayed':'mean'}).reset_index()
        
        y_val = 'item_gmv' if metric == "GMV" else 'order_id' if metric == "Orders" else 'is_delayed'
        fig_line = px.line(trend_data, x='month', y=y_val, markers=True)
        st.plotly_chart(fig_line, use_container_width=True)

    with col_b:
        st.subheader(f"{metric} by City")
        city_data = f_df.groupby('city').agg({'item_gmv':'sum', 'order_id':'nunique', 'is_delayed':'mean'}).reset_index()
        fig_bar = px.bar(city_data, x='city', y=y_val, color='city')
        st.plotly_chart(fig_bar, use_container_width=True)

    # --- INSIGHTS ---
    st.markdown("### 💡 Insights")
    st.write(f"- The carrier **{f_df.groupby('carrier')['is_delayed'].mean().idxmin()}** currently has the lowest delay rate.")
    st.write(f"- **{f_df.groupby('city')['item_gmv'].sum().idxmax()}** is the highest contributing city to GMV.")
    st.write(f"- Total average delay rate across selected filters is **{delay_rate:.1%}**.")