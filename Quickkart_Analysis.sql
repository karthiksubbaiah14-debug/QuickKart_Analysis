CREATE TABLE customers (
    customer_id TEXT,
    signup_date DATE,
    city TEXT,
    state TEXT,
    segment TEXT
);

CREATE TABLE sellers (
    seller_id TEXT,
    seller_name TEXT,
    primary_city TEXT,
    rating FLOAT
);

CREATE TABLE products (
    product_id TEXT,
    category TEXT,
    subcategory TEXT,
    base_price FLOAT
);

CREATE TABLE orders (
    order_id TEXT,
    customer_id TEXT,
    created_at TIMESTAMP,
    status TEXT,
    payment_method TEXT,
    promised_delivery_date TIMESTAMP,
    is_fast_delivery_eligible BOOLEAN
);

CREATE TABLE order_items (
    order_item_id TEXT,
    order_id TEXT,
    product_id TEXT,
    seller_id TEXT,
    quantity INT,
    unit_price FLOAT,
    discount_pct FLOAT,
    platform_fee_pct FLOAT
);

CREATE TABLE shipments (
    shipment_id TEXT,
    order_id TEXT,
    carrier TEXT,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    ship_from_city TEXT,
    ship_to_city TEXT,
    shipping_cost FLOAT,
    delivery_status TEXT
);

=========== ETL VERIFICATION=====================
SELECT COUNT(*) FROM customers;

SELECT COUNT(*) FROM orders;

SELECT COUNT(*) FROM order_items;

SELECT COUNT(*) FROM products;

SELECT COUNT(*) FROM sellers;

SELECT COUNT(*) FROM shipments;

==========Monthly_Marketplace_Metrics==========
WITH order_gmv AS (
    SELECT 
        oi.order_id,
        SUM(oi.quantity * oi.unit_price) AS GMV
    FROM order_items oi
    GROUP BY oi.order_id
),

delivered_orders AS (
    SELECT 
        o.order_id,
        o.customer_id,
        o.created_at,
        c.city,
        DATE_TRUNC('month', o.created_at) AS month
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
    WHERE o.status = 'Delivered'
),

customer_order_rank AS (
    SELECT 
        customer_id,
        order_id,
        created_at,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY created_at) AS order_num
    FROM delivered_orders
)

SELECT 
    d.month,
    d.city,
    SUM(g.GMV) AS GMV,
    COUNT(DISTINCT d.order_id) AS number_of_orders,
    COUNT(DISTINCT d.customer_id) AS unique_customers,
    COUNT(DISTINCT CASE WHEN cor.order_num >= 2 THEN d.customer_id END)::FLOAT
        / COUNT(DISTINCT d.customer_id) AS repeat_purchase_rate
FROM delivered_orders d
JOIN order_gmv g 
    ON d.order_id = g.order_id
LEFT JOIN customer_order_rank cor 
    ON d.order_id = cor.order_id
GROUP BY d.month, d.city
ORDER BY d.month, d.city;

==========IMPACT_ON_1st_Order_delay_repeat=============

WITH first_orders AS (
    SELECT 
        o.customer_id,
        o.order_id,
        o.created_at,
        s.delivery_status,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.created_at) AS rn
    FROM orders o
    JOIN shipments s 
        ON o.order_id = s.order_id
    WHERE o.status = 'Delivered'
),

first_order_flag AS (
    SELECT 
        customer_id,
        order_id,
        created_at,
        CASE 
            WHEN delivery_status = 'OnTime' THEN 'OnTime'
            ELSE 'Delayed'
        END AS first_order_delay_status
    FROM first_orders
    WHERE rn = 1
),

repeat_within_90d AS (
    SELECT 
        f.customer_id,
        f.first_order_delay_status,
        COUNT(o.order_id) AS orders_in_90d
    FROM first_order_flag f
    LEFT JOIN orders o 
        ON f.customer_id = o.customer_id
        AND o.created_at > f.created_at
        AND o.created_at <= f.created_at + INTERVAL '90 days'
        AND o.status = 'Delivered'
    GROUP BY f.customer_id, f.first_order_delay_status
)

SELECT 
    first_order_delay_status,
    COUNT(CASE WHEN orders_in_90d >= 1 THEN 1 END)::FLOAT
        / COUNT(*) AS repeat_rate_90d
FROM repeat_within_90d
GROUP BY first_order_delay_status;

=========SELLER_&_CARRIER_PERFORMANCE======================

WITH order_gmv AS (
    SELECT 
        order_id,
        seller_id,
        SUM(quantity * unit_price) AS GMV
    FROM order_items
    GROUP BY order_id, seller_id
),

shipment_data AS (
    SELECT 
        s.order_id,
        s.carrier,
        s.ship_to_city,
        s.delivery_status,
        s.delivered_at,
        o.promised_delivery_date
    FROM shipments s
    JOIN orders o 
        ON s.order_id = o.order_id
    WHERE o.status = 'Delivered'
)
SELECT 
    og.seller_id,
    sd.carrier,
    sd.ship_to_city,
    COUNT(DISTINCT og.order_id) AS total_orders,
    SUM(og.GMV) AS total_GMV,
    SUM(CASE WHEN sd.delivery_status <> 'OnTime' THEN og.GMV ELSE 0 END) AS delayed_GMV,
    COUNT(DISTINCT CASE WHEN sd.delivery_status <> 'OnTime' THEN og.order_id END)::FLOAT
        / COUNT(DISTINCT og.order_id) AS delayed_order_rate,
    AVG(
        CASE 
            WHEN sd.delivery_status <> 'OnTime' 
            THEN EXTRACT(DAY FROM (sd.delivered_at - sd.promised_delivery_date))
        END
    ) AS avg_delay_days
FROM order_gmv og
JOIN shipment_data sd 
    ON og.order_id = sd.order_id
GROUP BY og.seller_id, sd.carrier, sd.ship_to_city
HAVING COUNT(DISTINCT og.order_id) >= 10
ORDER BY delayed_order_rate DESC;

======== Query_Optimization==========

SELECT 
    o.order_id,
    s.delivered_at,
    o.created_at,
    c.city
FROM orders o
JOIN customers c 
    ON c.customer_id = o.customer_id
JOIN shipments s 
    ON s.order_id = o.order_id
WHERE s.delivery_status <> 'OnTime';


SELECT 
    og.seller_id,
    sd.carrier,
    sd.ship_to_city,
    COUNT(*) AS order_count
FROM (
    SELECT order_id, seller_id
    FROM order_items
    GROUP BY order_id, seller_id
) og
JOIN shipments sd 
    ON og.order_id = sd.order_id
GROUP BY og.seller_id, sd.carrier, sd.ship_to_city
ORDER BY order_count DESC;

=====EFFICIENCY_REASON=======

1. It actually removes Correlated subquery and EXISTS clause.

2. One timeshipment scanning.

3.Better execution plan as it uses joins.

=======INDEXES=======

CREATE INDEX idx_shipments_order_status 
ON shipments(order_id, delivery_status);

CREATE INDEX idx_orders_customer 
ON orders(customer_id);

CREATE INDEX idx_shipments_order 
ON shipments(order_id);



