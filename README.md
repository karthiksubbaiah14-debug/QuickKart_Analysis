QuickKart Marketplace Analytics Dashboard

An interactive analytics solution built using Python to help business leaders understand how delivery performance impacts GMV and customer repeat behavior across cities, categories, and logistics partners.

Problem Statement:

This project analyzes how delivery delays influence revenue (GMV) and customer retention.
It is designed for:
Head of Marketplace
Head of Logistics

The dashboard enables quick decision-making within 10 minutes before critical meetings.

Tech Stack
Python (Pandas, NumPy)
Streamlit (Dashboard)
SQL (Pre-aggregation logic)
CSV-based data pipeline

Dataset Overview

The analysis is based on multiple relational datasets:

customers.csv
orders.csv
order_items.csv
products.csv
sellers.csv
shipments.csv
 Key Features
Filters (User Controls)
Date range (based on order creation date)
City (multi-select)
Category (multi-select)
Carrier (multi-select)
Metric selector:
GMV
Orders
Repeat Rate
Delayed Order Rate
Dashboard Views
1. KPI Strip
Total GMV
Delayed Order Rate
Repeat Rate
2. Time Series Analysis
Monthly trend of selected metric
3. Breakdown Analysis
Metric split by:
City
Carrier (toggle option)
4. Business Insights Section
Automated insights explaining:
Delivery performance impact
High-risk cities/carriers
Customer retention patterns
Key Metrics Logic
GMV = Quantity × Unit Price
Delayed Orders = Delivered after the promised date
Repeat Rate = Customers with 2+ orders / Total customers
Delayed Order Rate = Delayed orders / Total delivered orders
Output Files Generated
gmv_trend.csv
orders_trend.csv
customers_trend.csv
repeat_rate.csv
delay_city_carrier.csv
delay_category.csv
seller_perf.csv
impact_result.csv
How to Run the Project
Step 1: Install Dependencies
pip install pandas numpy streamlit
Step 2: Run Data Processing Script
python analysis.py
Step 3: Launch Dashboard
streamlit run app.py

Key Insights (Example)
Higher delivery delays are strongly linked to lower repeat purchase rates
Certain cities show consistently higher delay rates across carriers
Reliable carriers contribute significantly to higher GMV retention
First-order delays negatively impact long-term customer behavior

Business Impact

This dashboard helps stakeholders:

Identify underperforming logistics partners
Improve delivery SLAs
Boost customer retention
Maximize revenue through operational efficiency

Future Enhancements
Real-time database integration
Predictive delay modeling (ML)
Cohort-based retention analysis
Alert system for high delay spikes
