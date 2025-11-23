USE depiecommerce;

-- The year start from 2012-03-19 
-- We Need to calc just 2 period from 2012-03-19 to 2013-03-19 AND 2014-03-19 to 2015-03-19
CREATE VIEW CAGR_CALC AS 
WITH RECURSIVE first_last_period AS (
SELECT 
    DATE('2012-03-19') AS start_date,
    DATE('2013-03-19') AS end_date,
    1 AS rn
    -- rn stand for calc the row so by this way i give each row a number 1,2 or 3
UNION ALL SELECT 
    DATE_ADD(start_date, INTERVAL 1 YEAR),
    DATE_ADD(end_date, INTERVAL 1 YEAR),
    rn + 1
    -- now for each period have its own number first have 1 and second is 2 and third is 3
    FROM first_last_period
    WHERE end_date < '2015-03-19'
    ),
rev_period AS (
SELECT CONCAT(start_date,' --> ',end_date) AS period , ROUND(SUM(o.price_usd)) - ROUND(SUM(oif.refund_amount_usd)) AS net_rev
FROM first_last_period AS flp
-- WE need to calc the rev to this period
LEFT JOIN orders AS o ON o.created_at >= flp.start_date AND o.created_at <= flp.end_date
INNER JOIN order_item_refunds AS oif ON oif.created_at >= flp.start_date AND oif.created_at <= flp.end_date 
-- here we call the period by rn(its unique number we created) instead of writing big quires
WHERE rn =1 OR rn = (SELECT MAX(rn) FROM first_last_period)
GROUP BY period
)
-- We need to get the info to calc GAGR 
SELECT 
POWER(CAST(MAX(net_rev) AS FLOAT) / MIN(net_rev) , 1.0 / 3) -1 AS CAGR
-- cast is makeing the number float to make the result as float like 0.26 not 0 
FROM rev_period;