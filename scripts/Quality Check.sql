-- -----------------------------------1. Check for NULLs in Identity Columns -----------------------------------

SELECT 
    *
FROM
    depiecommerce.website_sessions
WHERE
    website_session_id IS NULL;

-- website_pageviews
SELECT 
    *
FROM
    depiecommerce.website_pageviews
WHERE
    website_pageview_id IS NULL;

-- orders
SELECT 
    *
FROM
    depiecommerce.orders
WHERE
    order_id IS NULL;

-- order_items
SELECT 
    *
FROM
    depiecommerce.order_items
WHERE
    order_item_id IS NULL;

-- order_item_refunds
SELECT 
    *
FROM
    depiecommerce.order_item_refunds
WHERE
    order_item_refund_id IS NULL;

-- products
SELECT 
    *
FROM
    depiecommerce.products
WHERE
    product_id IS NULL;


-- -----------------------------------  2. Check for Duplicates in Identity Columns Using RANK -----------------------------------
-- Example for website_sessions, replicate for other tables as needed:
SELECT 
    website_session_id, COUNT(*) AS cnt
FROM
    depiecommerce.website_sessions
GROUP BY website_session_id
HAVING COUNT(*) > 1;

-- Using RANK for full duplicate rows:
SELECT *
FROM (
    SELECT *, RANK() OVER (PARTITION BY website_session_id ORDER BY website_session_id) AS rnk
    FROM depiecommerce.website_sessions
) t
WHERE rnk > 1;

-- -----------------------------------3. Check Leading/Trailing Spaces in String or Category Columns -----------------------------------

SELECT 
    *
FROM
    depiecommerce.website_sessions
WHERE
    utm_source != TRIM(utm_source)
        OR utm_campaign != TRIM(utm_campaign)
        OR utm_content != TRIM(utm_content)
        OR device_type != TRIM(device_type)
        OR http_referer != TRIM(http_referer);

-- products: product_name
SELECT 
    *
FROM
    depiecommerce.products
WHERE
    product_name != TRIM(product_name);
-- -----------------------------------4. Other Important Quality Checks -----------------------------------
-- Check Referential Integrity

SELECT 
    *
FROM
    depiecommerce.orders o
        LEFT JOIN
    depiecommerce.website_sessions ws ON o.website_session_id = ws.website_session_id
WHERE
    ws.website_session_id IS NULL;

-- order_items referencing non-existent order or product
SELECT 
    *
FROM
    depiecommerce.order_items oi
        LEFT JOIN
    depiecommerce.orders o ON oi.order_id = o.order_id
WHERE
    o.order_id IS NULL;

SELECT 
    *
FROM
    depiecommerce.order_items oi
        LEFT JOIN
    depiecommerce.products p ON oi.product_id = p.product_id
WHERE
    p.product_id IS NULL;
-- Check for Negative or Zero Values in Monetary Columns

SELECT 
    *
FROM
    depiecommerce.orders
WHERE
    price_usd <= 0 OR cogs_usd < 0;
-- order_items
SELECT 
    *
FROM
    depiecommerce.order_items
WHERE
    price_usd <= 0 OR cogs_usd < 0;
-- order_item_refunds
SELECT 
    *
FROM
    depiecommerce.order_item_refunds
WHERE
    refund_amount_usd <= 0;

-- _____________________________________Result Target:
-- _____________________________________If the dataset is clean, all queries above should return zero rows.