```python
import pandas as pd
import numpy as np
```


```python
customers = pd.read_csv(r"C:\Users\DELL\Downloads\QuickKart_TakeHome_Brief\quickkart_dataset\customers.csv")
orders = pd.read_csv(r"C:\Users\DELL\Downloads\QuickKart_TakeHome_Brief\quickkart_dataset\orders.csv")
order_items = pd.read_csv(r"C:\Users\DELL\Downloads\QuickKart_TakeHome_Brief\quickkart_dataset\order_items.csv")
products = pd.read_csv(r"C:\Users\DELL\Downloads\QuickKart_TakeHome_Brief\quickkart_dataset\products.csv")
sellers = pd.read_csv(r"C:\Users\DELL\Downloads\QuickKart_TakeHome_Brief\quickkart_dataset\sellers.csv")
shipments = pd.read_csv(r"C:\Users\DELL\Downloads\QuickKart_TakeHome_Brief\quickkart_dataset\shipments.csv")
```


```python
orders["created_at"] = pd.to_datetime(orders["created_at"])
orders["promised_delivery_date"] = pd.to_datetime(orders["promised_delivery_date"])
shipments["delivered_at"] = pd.to_datetime(shipments["delivered_at"])
shipments["shipped_at"] = pd.to_datetime(shipments["shipped_at"])
```


```python
df = orders.merge(customers, on="customer_id", how="left") \
           .merge(order_items, on="order_id", how="left") \
           .merge(products, on="product_id", how="left") \
           .merge(sellers, on="seller_id", how="left") \
           .merge(shipments, on="order_id", how="left")
```


```python
df.columns = df.columns.str.lower()

if "seller_id_x" in df.columns:
    df.rename(columns={"seller_id_x": "seller_id"}, inplace=True)
```


```python
df["gmv"] = df["quantity"] * df["unit_price"]
df["month"] = df["created_at"].dt.to_period("M").astype(str)
df["is_delayed"] = df["delivery_status"] != "OnTime"
```


```python
df_clean = df[df["status"] == "Delivered"].copy()
```


```python
gmv_trend = df.groupby(["month", "city", "category"])["gmv"].sum().reset_index()
```


```python
orders_trend = df.groupby(["month", "city"])["order_id"].nunique().reset_index(name="orders")

customers_trend = df.groupby(["month", "city"])["customer_id"].nunique().reset_index(name="customers")
```


```python
delivered = df_clean.sort_values(["customer_id", "created_at"])

delivered["order_count"] = delivered.groupby("customer_id").cumcount() + 1

delivered["is_repeat"] = delivered["order_count"] >= 2

repeat_rate = delivered.groupby("month").agg(
    repeat_customers=("is_repeat", "sum"),
    total_customers=("customer_id", "nunique")
).reset_index()

repeat_rate["repeat_rate"] = repeat_rate["repeat_customers"] / repeat_rate["total_customers"]

```


```python
delay_city_carrier = df_clean.groupby(["city", "carrier"])["is_delayed"].mean().reset_index()

delay_category = df_clean.groupby("category")["is_delayed"].mean().reset_index()

```


```python
first_orders = delivered.groupby("customer_id").first().reset_index()

customer_orders = delivered.groupby("customer_id")["order_id"].nunique().reset_index(name="total_orders")

impact = first_orders.merge(customer_orders, on="customer_id")
impact["is_repeat"] = impact["total_orders"] >= 2

impact_result = impact.groupby("is_delayed")["is_repeat"].mean().reset_index()
```


```python
seller_perf = df_clean.groupby("seller_id").agg(
    total_orders=("order_id", "count"),
    delay_rate=("is_delayed", "mean"),
    total_gmv=("gmv", "sum")
).reset_index()

```


```python
gmv_trend.to_csv("gmv_trend.csv", index=False)
orders_trend.to_csv("orders_trend.csv", index=False)
customers_trend.to_csv("customers_trend.csv", index=False)
repeat_rate.to_csv("repeat_rate.csv", index=False)
delay_city_carrier.to_csv("delay_city_carrier.csv", index=False)
delay_category.to_csv("delay_category.csv", index=False)
seller_perf.to_csv("seller_perf.csv", index=False)
impact_result.to_csv("impact_result.csv", index=False)

```


```python
print("=== GMV TREND ===")
print(gmv_trend.head())

print("\n=== ORDERS TREND ===")
print(orders_trend.head())

print("\n=== CUSTOMERS TREND ===")
print(customers_trend.head())

print("\n=== REPEAT RATE ===")
print(repeat_rate.head())

print("\n=== DELAY CITY + CARRIER ===")
print(delay_city_carrier.head())

print("\n✅ ALL FILES GENERATED SUCCESSFULLY")
```

    === GMV TREND ===
         month       city        category        gmv
    0  2024-07  Ahmedabad           Books   110449.0
    1  2024-07  Ahmedabad     Electronics  6231837.0
    2  2024-07  Ahmedabad         Fashion   672491.0
    3  2024-07  Ahmedabad         Grocery   117559.0
    4  2024-07  Ahmedabad  Home & Kitchen  1341740.0
    
    === ORDERS TREND ===
         month        city  orders
    0  2024-07   Ahmedabad     257
    1  2024-07   Bangalore     805
    2  2024-07  Chandigarh     168
    3  2024-07     Chennai     502
    4  2024-07       Delhi     909
    
    === CUSTOMERS TREND ===
         month        city  customers
    0  2024-07   Ahmedabad        227
    1  2024-07   Bangalore        706
    2  2024-07  Chandigarh        139
    3  2024-07     Chennai        438
    4  2024-07       Delhi        789
    
    === REPEAT RATE ===
         month  repeat_customers  total_customers  repeat_rate
    0  2024-07              3732             4111     0.907808
    1  2024-08              4500             4126     1.090645
    2  2024-09              5047             4130     1.222034
    3  2024-10              5632             4279     1.316195
    4  2024-11              5816             4061     1.432160
    
    === DELAY CITY + CARRIER ===
            city    carrier  is_delayed
    0  Ahmedabad   BlueDart    0.262795
    1  Ahmedabad  Delhivery    0.269934
    2  Ahmedabad      Ekart    0.258941
    3  Bangalore   BlueDart    0.266837
    4  Bangalore  Delhivery    0.267992
    
    ✅ ALL FILES GENERATED SUCCESSFULLY
    


```python

```
