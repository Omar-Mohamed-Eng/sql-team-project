USE depiecommerce;
-- ____________________________________________________________________________________________________________________________________________________________
-- ____________________________________________________Note!!!_________________________________________________________________________________________________
-- __________________________________________This SP will create 43 VIEWs _____________________________________________________________________________________
-- ____________________________________________________________________________________________________________________________________________________________

DROP PROCEDURE IF EXISTS sp_refresh_kpi_views;
DELIMITER $$
CREATE PROCEDURE sp_refresh_kpi_views()
BEGIN

-- _________________________Manar________________________________
-- 1. Traffic & Engagement

-- ● Website Traffic (count).
    DROP VIEW IF EXISTS traffic;
    CREATE VIEW traffic AS
      SELECT COUNT(website_session_id) AS total_sessions
      FROM website_sessions;

-- ● Sessions for Unique users
    DROP VIEW IF EXISTS uniqsession;
    CREATE VIEW uniqsession AS
      SELECT COUNT(DISTINCT user_id) AS unique_users
      FROM website_sessions;

-- Sessions count per user 
-- kol unique user 3mal kam session 
    DROP VIEW IF EXISTS user_session;
    CREATE VIEW user_session AS
      SELECT user_id,
             COUNT(website_session_id) AS sessions_per_user
      FROM website_sessions
      GROUP BY user_id
      ORDER BY sessions_per_user;

-- how many users made sessions with signup and how many did not
-- in conclusion, all users are signed up 
    DROP VIEW IF EXISTS usersignedup;
    CREATE VIEW usersignedup AS
      SELECT COUNT(*) AS total_sessions,
             SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS sessions_without_user,
             SUM(CASE WHEN user_id IS NOT NULL THEN 1 ELSE 0 END) AS sessions_with_user
      FROM website_sessions;

-- ● Daily/Hourly Traffic → group website_sessions.created_at by day/hour.
    DROP VIEW IF EXISTS dailytraf;
    CREATE VIEW dailytraf AS
      SELECT DATE(created_at) AS day,
             COUNT(website_session_id) AS sessions
      FROM website_sessions
      GROUP BY DATE(created_at)
      ORDER BY day;

    DROP VIEW IF EXISTS hourlytraf;
    CREATE VIEW hourlytraf AS
      SELECT DATE(created_at) AS day,
             HOUR(created_at) AS hour,
             COUNT(website_session_id) AS sessions
      FROM website_sessions
      GROUP BY DATE(created_at), HOUR(created_at)
      ORDER BY day, hour;

-- ● Top Pages (most viewed)
    DROP VIEW IF EXISTS toppages;
    CREATE VIEW toppages AS
      SELECT pageview_url,
             COUNT(*) AS views
      FROM website_pageviews
      GROUP BY pageview_url
      ORDER BY views DESC;

-- ● Entry Pages (first page of session)
    DROP VIEW IF EXISTS entrypages;
    CREATE VIEW entrypages AS
      WITH first_pages AS (
          SELECT website_session_id,
                 MIN(created_at) AS first_view
          FROM website_pageviews
          GROUP BY website_session_id
      )
      SELECT wp.pageview_url,
             COUNT(*) AS entry_count
      FROM website_pageviews wp
      JOIN first_pages fp
        ON wp.website_session_id = fp.website_session_id
       AND wp.created_at = fp.first_view
      GROUP BY wp.pageview_url
      ORDER BY entry_count DESC
      LIMIT 10;

-- ● Average session duration
    DROP VIEW IF EXISTS userstay;
    CREATE VIEW userstay AS
      WITH session_times AS (
          SELECT ws.user_id,
                 ws.website_session_id,
                 MIN(wp.created_at) AS session_start,
                 MAX(wp.created_at) AS session_end
          FROM website_sessions ws
          JOIN website_pageviews wp ON ws.website_session_id = wp.website_session_id
          GROUP BY ws.user_id, ws.website_session_id
      ),
      session_durations AS (
          SELECT user_id,
                 website_session_id,
                 TIMESTAMPDIFF(SECOND, session_start, session_end) AS session_duration_seconds
          FROM session_times
      )
      SELECT user_id,
             ROUND(AVG(session_duration_seconds), 2) AS avg_session_duration_seconds,
             SUM(session_duration_seconds) AS total_time_seconds,
             COUNT(website_session_id) AS session_count
      FROM session_durations
      GROUP BY user_id
      ORDER BY avg_session_duration_seconds DESC;

-- ● Bounce Rate = sessions with only 1 pageview ÷ total sessions
    DROP VIEW IF EXISTS bounce;
    CREATE VIEW bounce AS
      WITH session_views AS (
          SELECT website_session_id,
                 COUNT(*) AS pageviews_count
          FROM website_pageviews
          GROUP BY website_session_id
      )
      SELECT ROUND(
                 SUM(CASE WHEN pageviews_count = 1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 
                 2
             ) AS bounce_rate_percentage
      FROM session_views;


-- _______________________________________________Omar_____________________________________________________
-- 2. Marketing Performance KPIs

-- Revenue per Session (RPS)
    DROP VIEW IF EXISTS rps;
    CREATE VIEW rps AS
      SELECT ws.website_session_id,
             SUM(o.price_usd) / COUNT(ws.website_session_id) AS rps
      FROM orders AS o
      INNER JOIN website_sessions AS ws ON o.website_session_id = ws.website_session_id
      GROUP BY ws.website_session_id;

-- Revenue Per Click (RPC)
    DROP VIEW IF EXISTS rpc;
CREATE VIEW rpc AS
    SELECT 
        ROUND((SELECT 
                        SUM(price_usd)
                    FROM
                        orders) - COALESCE((SELECT 
                                SUM(refund_amount_usd)
                            FROM
                                order_item_refunds),
                        0) / COUNT(utm_source),
                2) AS rpc
    FROM
        website_sessions
    WHERE
        utm_source IS NOT NULL;

-- Orders by Device
    DROP VIEW IF EXISTS orders_device;
    CREATE VIEW orders_device AS
      SELECT ws.device_type,
             COUNT(o.order_id) AS orders_count
      FROM orders AS o
      INNER JOIN website_sessions AS ws ON o.website_session_id = ws.website_session_id
      GROUP BY ws.device_type;

-- Orders by Campaign
    DROP VIEW IF EXISTS orders_campaign;
    CREATE VIEW orders_campaign AS
      SELECT ws.utm_campaign,
             COUNT(o.order_id) AS orders_count,
             ROUND(SUM(o.price_usd), 0) AS campaign_revenue
      FROM orders AS o
      INNER JOIN website_sessions AS ws ON o.website_session_id = ws.website_session_id
      GROUP BY ws.utm_campaign;

-- Orders by Source
    DROP VIEW IF EXISTS orders_source;
    CREATE VIEW orders_source AS
      SELECT ws.utm_source,
             COUNT(o.order_id) AS orders_count,
             SUM(o.price_usd) AS total_revenue
      FROM orders AS o
      INNER JOIN website_sessions AS ws ON o.website_session_id = ws.website_session_id
      GROUP BY ws.utm_source;

-- Product Funnel CTR
    DROP VIEW IF EXISTS product_funnel_ctr;
    CREATE VIEW product_funnel_ctr AS
      WITH products_sessions AS (
          SELECT DISTINCT website_session_id
          FROM website_pageviews
          WHERE pageview_url = '/products'
      ),
      funnel_counts AS (
          SELECT 'Products' AS step,
                 COUNT(DISTINCT ps.website_session_id) AS sessions
          FROM products_sessions ps
          UNION ALL
          SELECT 'Cart',
                 COUNT(DISTINCT ps.website_session_id)
          FROM products_sessions ps
          JOIN website_pageviews wp ON ps.website_session_id = wp.website_session_id
          WHERE wp.pageview_url = '/cart'
          UNION ALL
          SELECT 'Shipping',
                 COUNT(DISTINCT ps.website_session_id)
          FROM products_sessions ps
          JOIN website_pageviews wp ON ps.website_session_id = wp.website_session_id
          WHERE wp.pageview_url = '/shipping'
          UNION ALL
          SELECT 'Billing',
                 COUNT(DISTINCT ps.website_session_id)
          FROM products_sessions ps
          JOIN website_pageviews wp ON ps.website_session_id = wp.website_session_id
          WHERE wp.pageview_url LIKE '/billing%'
          UNION ALL
          SELECT 'Thank You',
                 COUNT(DISTINCT ps.website_session_id)
          FROM products_sessions ps
          JOIN website_pageviews wp ON ps.website_session_id = wp.website_session_id
          WHERE wp.pageview_url = '/thank-you-for-your-order'
      )
      SELECT step,
             sessions,
             ROUND(100.0 * sessions / MAX(CASE WHEN step = 'Products' THEN sessions END) OVER (), 2) AS ctr_from_products,
             ROUND(
                 100.0 * sessions / LAG(sessions) OVER (
                     ORDER BY CASE step
                                WHEN 'Products' THEN 1
                                WHEN 'Cart' THEN 2
                                WHEN 'Shipping' THEN 3
                                WHEN 'Billing' THEN 4
                                WHEN 'Thank You' THEN 5
                              END
                 ), 
                 2
             ) AS ctr_from_previous
      FROM funnel_counts;


-- 3. Conversion & Funnel KPIs
-- Conversion Rate (CVR)
    DROP VIEW IF EXISTS cvr;
    CREATE VIEW cvr AS
      SELECT (SELECT COUNT(order_id) FROM orders) /
             (SELECT COUNT(website_session_id) FROM website_sessions) * 100 AS conversion_rate;

-- Entry Pages Count
    DROP VIEW IF EXISTS entry_pages_count;
    CREATE VIEW entry_pages_count AS
      SELECT pageview_url,
             COUNT(*) AS entry_pages_count
      FROM (
          SELECT *,
                 ROW_NUMBER() OVER (PARTITION BY website_session_id ORDER BY created_at) AS funnel_depth
          FROM website_pageviews
      ) f
      WHERE funnel_depth = 1
      GROUP BY pageview_url
      ORDER BY entry_pages_count DESC;

-- Users Number without duplicates
    DROP VIEW IF EXISTS cte_users_number;
    CREATE VIEW cte_users_number AS
      SELECT *
      FROM (
          SELECT *,
                 ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY user_id) AS unique_users
          FROM website_sessions
      ) d
      WHERE unique_users = 1;

-- Cart Abandonment Rate
	 DROP VIEW IF EXISTS cart_abandonment_rate;
	 CREATE VIEW cart_abandonment_rate as (
	WITH sessions_with_cart AS (
	  SELECT DISTINCT website_session_id
	  FROM website_pageviews
	  WHERE pageview_url LIKE '%/cart%'
	)
	SELECT
	  COUNT(s.website_session_id) AS sessions_with_cart,
	  COUNT(DISTINCT o.order_id) AS orders_completed,
	  ROUND(((COUNT(s.website_session_id) - COUNT(DISTINCT o.order_id)) * 1.0 / 
	   NULLIF(COUNT(s.website_session_id),0)) * 100, 1)AS cart_abandonment_rate
	FROM sessions_with_cart s
	LEFT JOIN orders AS o
	  ON o.website_session_id = s.website_session_id);

-- Funnel Depth Counts (excluding home & lander pages)
    DROP VIEW IF EXISTS funnel_depth_count;
    CREATE VIEW funnel_depth_count AS
      SELECT pageview_url,
             COUNT(*) AS depth_count
      FROM (
          SELECT wp.*,
                 ROW_NUMBER() OVER (PARTITION BY website_session_id ORDER BY created_at) AS funnel_depth
          FROM website_pageviews wp
      ) f
      WHERE funnel_depth > 1
      GROUP BY pageview_url
      ORDER BY depth_count DESC;

-- Funnel Conversion: Thank-you / Billing
    DROP VIEW IF EXISTS funnel_conversion;
    CREATE VIEW funnel_conversion AS
      SELECT
        (SELECT depth_count
         FROM funnel_depth_count
         WHERE pageview_url = '/thank-you-for-your-order') * 1.0 /
        (SELECT SUM(depth_count)
         FROM funnel_depth_count
         WHERE pageview_url LIKE '/billing%') * 100 AS conversion_rate;

-- AB Test Results
    DROP VIEW IF EXISTS ab_test_results;
    CREATE VIEW ab_test_results AS
      SELECT wp.pageview_url AS landing_page,
             COUNT(DISTINCT ws.website_session_id) AS total_sessions,
             COUNT(DISTINCT o.order_id) AS total_orders,
             ROUND(SUM(o.price_usd) - COALESCE(SUM(r.refund_amount_usd), 0), 0) AS net_revenue,
             ROUND(COUNT(DISTINCT o.order_id) * 1.0 / COUNT(DISTINCT ws.website_session_id) * 100, 2) AS conversion_rate,
             ROUND((SUM(o.price_usd) - COALESCE(SUM(r.refund_amount_usd), 0)) * 1.0 / COUNT(DISTINCT ws.website_session_id), 2) AS rpc
      FROM website_sessions ws
      LEFT JOIN orders o ON ws.website_session_id = o.website_session_id
      LEFT JOIN website_pageviews wp ON ws.website_session_id = wp.website_session_id
      LEFT JOIN order_item_refunds r ON o.order_id = r.order_id
      WHERE wp.pageview_url LIKE '/lander%' OR wp.pageview_url = '/home'
      GROUP BY wp.pageview_url
      ORDER BY net_revenue DESC;


-- _______________________________________________Nour_____________________________________________________
-- 3. Orders and Revenue
DROP VIEW IF EXISTS total_orders;
CREATE VIEW total_orders AS
    SELECT 
        COUNT(order_id) AS total_orders
    FROM
        orders;
-- Revenue and Net Revenue
DROP VIEW IF EXISTS revenue_summary;

CREATE VIEW revenue_summary AS
SELECT 
    SUM(oi.price_usd)                        AS total_revenue,
    SUM(oi.price_usd) - SUM(oir.refund_amount_usd) AS net_revenue
FROM order_items AS oi
LEFT JOIN order_item_refunds AS oir 
    ON oi.order_item_id = oir.order_item_id;


-- Gross Merchandise Value (GMV) 
DROP VIEW IF EXISTS GMV;
CREATE VIEW GMV AS
    SELECT 
        SUM(price_usd) AS volume_of_transactions
    FROM
        order_items;

    -- Average Order Value (AOV) 
DROP VIEW IF EXISTS Average_order_value;
CREATE VIEW Average_order_value AS
    SELECT 
        SUM(price_usd) / COUNT(order_id) AS Average_Order_Value
    FROM
        orders;

-- Gross Margin 
DROP VIEW IF EXISTS Gross_margin;
CREATE VIEW Gross_margin AS
    SELECT 
        CONCAT(ROUND(((SUM(price_usd) - SUM(cogs_usd)) / SUM(price_usd)) * 100,
                        2),
                '%') AS gross_margin
    FROM
        orders;

-- Refund/Return Rate by orders
DROP VIEW IF EXISTS return_rate_by_orders;
CREATE VIEW return_rate_by_orders AS
SELECT 
    ROUND(COUNT(DISTINCT (oir.order_id)) / COUNT(DISTINCT (o.order_id)) * 100,
            3) AS Return_rate_by_orders
FROM
    orders AS o
        LEFT JOIN
    order_item_refunds AS oir ON o.order_id = oir.order_id;

-- Refund/Return Rate by Value
DROP VIEW IF EXISTS return_rate_by_value;
CREATE VIEW return_rate_by_value AS
SELECT
CONCAT( 
    ROUND(
        (SUM(oir.refund_amount_usd) * 1.0 / SUM(o.price_usd)) * 100,
    2),'%' )AS return_rate_value
FROM orders o
LEFT JOIN order_item_refunds as oir
    ON o.order_id = oir.order_id;

-- Refund Rates by Product
DROP VIEW IF EXISTS return_rate_by_products;
CREATE VIEW return_rate_by_products AS
SELECT 
    p.product_id,
    p.product_name,
    COUNT(DISTINCT oir.order_item_id) AS returned_items,
    COUNT(DISTINCT oi.order_item_id) AS total_items_sold,
    CONCAT(
    ROUND(
        (COUNT(DISTINCT oir.order_item_id) * 1.0 / COUNT(DISTINCT oi.order_item_id)) * 100,
        2
    ) ,'%') AS return_rate_percent
FROM products AS p
LEFT JOIN order_items AS oi 
    ON p.product_id = oi.product_id
LEFT JOIN order_item_refunds AS oir
    ON oi.order_item_id = oir.order_item_id
GROUP BY p.product_id, p.product_name
ORDER BY return_rate_percent DESC;

-- orders by product 'no of orders that has the product'
DROP VIEW IF EXISTS orders_by_product;
CREATE VIEW orders_by_product AS
SELECT 
    p.product_id,
    p.product_name,
    COUNT(DISTINCT oi.order_id) AS number_of_orders
FROM
    products AS p
        LEFT JOIN
    order_items AS oi ON oi.product_id = p.product_id
GROUP BY p.product_id , p.product_name;

-- Revenue by product
DROP VIEW IF EXISTS Rev_by_product;
CREATE VIEW Rev_by_product AS
    SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.price_usd) AS Revenues_usd
    FROM
        products AS p
            LEFT JOIN
        order_items AS oi ON p.product_id = oi.product_id
    GROUP BY p.product_id , p.product_name;

 -- Revenue by margin  
 DROP VIEW IF EXISTS rev_by_margin;
create view rev_by_margin as
    SELECT 
    p.product_id,
    p.product_name,
    SUM(oi.price_usd - oi.cogs_usd) AS margin_usd
FROM products p
JOIN order_items oi 
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name;

-- Product Portfolio Impact 
DROP VIEW IF EXISTS Product_Portfolio_Impact;
create view Product_Portfolio_Impact as
SELECT 
    p.product_id,
    p.product_name,
    SUM(oi.price_usd) AS revenue_usd,
   CONCAT(
		ROUND( (SUM(oi.price_usd) * 100.0) / SUM(SUM(oi.price_usd)) OVER(), 2) ,'%') AS contribution_percent
FROM products p
JOIN order_items oi 
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY revenue_usd DESC;

-- _______________________________________________Faris_____________________________________________________
-- CAGR Calculation
    DROP VIEW IF EXISTS cagr_calc;
    CREATE VIEW cagr_calc AS
      WITH RECURSIVE first_last_period AS (
          SELECT DATE('2012-03-19') AS start_date,
                 DATE('2013-03-19') AS end_date,
                 1 AS rn
          UNION ALL
          SELECT DATE_ADD(start_date, INTERVAL 1 YEAR),
                 DATE_ADD(end_date, INTERVAL 1 YEAR),
                 rn + 1
          FROM first_last_period
          WHERE end_date < '2015-03-19'
      ),
      rev_period AS (
          SELECT CONCAT(start_date, ' --> ', end_date) AS period,
                 ROUND(SUM(o.price_usd)) - ROUND(SUM(oif.refund_amount_usd)) AS net_rev
          FROM first_last_period AS flp
          LEFT JOIN orders AS o ON o.created_at BETWEEN flp.start_date AND flp.end_date
          INNER JOIN order_item_refunds AS oif ON oif.created_at BETWEEN flp.start_date AND flp.end_date
          WHERE rn = 1 OR rn = (SELECT MAX(rn) FROM first_last_period)
          GROUP BY period
      )
      SELECT POWER(CAST(MAX(net_rev) AS DECIMAL(18,2)) / MIN(net_rev), 1.0/3) - 1 AS CAGR
      FROM rev_period;

-- Revenue Per Session (monthly)
    DROP VIEW IF EXISTS rev_per_session;
    CREATE VIEW rev_per_session AS
      SELECT YEAR(o.created_at) AS years,
             MONTH(o.created_at) AS months,
             ROUND(SUM(o.price_usd) / COUNT(DISTINCT ws.website_session_id), 2) AS rev_per_session
      FROM orders o
      LEFT JOIN website_sessions ws ON o.website_session_id = ws.website_session_id
      GROUP BY years, months
      ORDER BY years, months;

-- Gross Margin per Session (monthly)
    DROP VIEW IF EXISTS gm_per_session;
    CREATE VIEW gm_per_session AS
      SELECT YEAR(o.created_at) AS years,
             MONTH(o.created_at) AS months,
             ROUND((SUM(o.price_usd) - SUM(o.cogs_usd)) / COUNT(DISTINCT ws.website_session_id), 2) AS gross_per_session
      FROM orders o
      LEFT JOIN website_sessions ws ON o.website_session_id = ws.website_session_id
      GROUP BY years, months
      ORDER BY years, months;

-- _________________________Hassan________________________________

-- New vs. Repeat Customers 
CREATE VIEW vw_New_vs_Repeat_Performance AS
    SELECT 
        CASE
            WHEN s.is_repeat_session = 0 THEN 'New Customer Session'
            WHEN s.is_repeat_session = 1 THEN 'Repeat Customer Session'
        END AS Customer_Type,
        COUNT(DISTINCT s.website_session_id) AS Total_Sessions,
        COUNT(DISTINCT o.order_id) AS Total_Orders,
        SUM(o.price_usd) AS Total_Revenue
    FROM
        website_sessions s
            LEFT JOIN
        orders o ON s.user_id = o.user_id
    GROUP BY s.is_repeat_session;
    
  --  Repeat Purchase Rate (RPR)
  CREATE VIEW vw_Repeat_Purchase_Rate AS

WITH UserOrderCounts AS (
    SELECT
        user_id,
        COUNT(order_id) AS order_count
    FROM
        orders
    GROUP BY
        user_id
)

SELECT
    (CAST((SELECT COUNT(*) FROM UserOrderCounts WHERE order_count >= 2) AS REAL) * 100.0)
    /
    (SELECT COUNT(DISTINCT user_id) FROM orders) AS RPR_Percentage;
    
    --  Customer Lifetime Value (CLV)
CREATE VIEW vw_New_vs_Repeat_Performance AS

SELECT
    CASE
        WHEN s.is_repeat_session = 0 THEN 'New Customer Session'
        WHEN s.is_repeat_session = 1 THEN 'Repeat Customer Session'
    END AS Customer_Type,
    
    COUNT(DISTINCT s.website_session_id) AS Total_Sessions,
    
    COUNT(DISTINCT o.order_id) AS Total_Orders,
    
    SUM(o.price_usd) AS Total_Revenue
FROM
    website_sessions s
LEFT JOIN
    orders o ON s.user_id = o.user_id 
GROUP BY
    s.is_repeat_session;
    
    --  Loyalty: Days Between Visits
CREATE VIEW vw_Loyalty_Days_Between_Visits AS

WITH SessionDates AS (
    SELECT
        user_id,
        created_at,
        LAG(created_at, 1) OVER (PARTITION BY user_id ORDER BY created_at) AS previous_session_date
    FROM
        website_sessions
),

DateDifferences AS (
    SELECT
        user_id,
        DATEDIFF(created_at,previous_session_date) AS days_between_sessions
    FROM
        SessionDates
    WHERE
        previous_session_date IS NOT NULL
)

SELECT
    user_id,
    AVG(days_between_sessions) AS Avg_Days_Between_Visits
FROM
    DateDifferences
GROUP BY
    user_id;

-- _________________________Hassan________________________________
-- Customer Metrics

-- New vs Repeat Customers
    DROP VIEW IF EXISTS vw_new_vs_repeat_performance;
    CREATE VIEW vw_new_vs_repeat_performance AS
      SELECT CASE
                 WHEN s.is_repeat_session = 0 THEN 'New Customer Session'
                 WHEN s.is_repeat_session = 1 THEN 'Repeat Customer Session'
             END AS customer_type,
             COUNT(DISTINCT s.website_session_id) AS total_sessions,
             COUNT(DISTINCT o.order_id) AS total_orders,
             SUM(o.price_usd) AS total_revenue
      FROM website_sessions s
      LEFT JOIN orders o ON s.user_id = o.user_id
      GROUP BY s.is_repeat_session;

-- Repeat Purchase Rate (RPR)
    DROP VIEW IF EXISTS vw_repeat_purchase_rate;
    CREATE VIEW vw_repeat_purchase_rate AS
      WITH UserOrderCounts AS (
          SELECT user_id, COUNT(order_id) AS order_count
          FROM orders
          GROUP BY user_id
      )
      SELECT (CAST((SELECT COUNT(*) FROM UserOrderCounts WHERE order_count >= 2) AS DECIMAL(18,2)) * 100.0) /
             (SELECT COUNT(DISTINCT user_id) FROM orders) AS rpr_percentage;

-- Customer Loyalty: Avg days between visits
    DROP VIEW IF EXISTS vw_loyalty_days_between_visits;
    CREATE VIEW vw_loyalty_days_between_visits AS
      WITH SessionDates AS (
          SELECT user_id,
                 created_at,
                 LAG(created_at, 1) OVER (PARTITION BY user_id ORDER BY created_at) AS previous_session_date
          FROM website_sessions
      ),
      DateDifferences AS (
          SELECT user_id,
                 DATEDIFF(created_at, previous_session_date) AS days_between_sessions
          FROM SessionDates
          WHERE previous_session_date IS NOT NULL
      )
      SELECT user_id,
             AVG(days_between_sessions) AS avg_days_between_visits
      FROM DateDifferences
      GROUP BY user_id;

END$$

DELIMITER ;


-- __________________________________________ Run this manually alone _______________________________________
CALL sp_refresh_kpi_views();
