USE olist_assignment;

SHOW TABLES;

SELECT *
FROM olist_orders_dataset
LIMIT 10;

-- Display all the column name and their data types
-- in a order table to understand structure

DESCRIBE olist_orders_dataset;

-- Purpose: Count the total number of records in the orders table.
-- COUNT(*) counts all rows in the table.
-- This helps us understand the size of our order dataset.

SELECT COUNT(*)
FROM olist_orders_dataset;

-- Purpose: Count how many orders belong to each order status.
-- GROUP BY combines rows with the same status.
-- COUNT(*) counts the orders in each status group.

SELECT order_status, COUNT(*)
FROM olist_orders_dataset
GROUP BY order_status;

-- Purpose: Count orders for each status and sort the results.
-- COUNT(*) counts the orders in each group.
-- GROUP BY creates one group for each order status.
-- ORDER BY sorts the counts from highest to lowest.
-- DESC means descending order.

SELECT order_status, COUNT(*)
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY COUNT(*) DESC;

-- Purpose: Calculate the percentage of orders that were delivered.
-- The first COUNT(*) counts delivered orders.
-- The second COUNT(*) counts all orders.
-- Divide delivered orders by total orders and multiply by 100.

SELECT
	(SELECT COUNT(*)
    FROM olist_orders_dataset
    WHERE order_status = 'delivered')
    /
    (SELECT COUNT(*)
    FROM olist_orders_dataset) * 100
    AS delivered_percentage;
    
-- Purpose: Display the column names and data types
-- in the orders table so we can identify the order date column.

DESCRIBE olist_orders_dataset;

-- Purpose: Count orders placed in each year and month.
-- YEAR() extracts the year; MONTH() extracts the month.
-- GROUP BY combines orders from the same year and month.
-- ORDER BY displays the results in chronological order.

SELECT
	YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(*) AS total_orders
FROM olist_orders_dataset
GROUP BY 
		YEAR(order_purchase_timestamp),
        MONTH(order_purchase_timestamp)
ORDER BY
	order_year,
    order_month;

-- Find the most common payment 

SELECT payment_type, COUNT(*)
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY COUNT(*) DESC;

-- query to count orders where order_status is 'delivered'.

SELECT COUNT(*)
AS delivered
FROM olist_orders_dataset
WHERE order_status = 'delivered';

-- Purpose: Calculate how many days each delivered order took.

SELECT
	order_id,
    DATEDIFF(
		order_delivered_customer_date,
        order_purchase_timestamp
    ) AS delivery_days
FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NOT NULL;    

-- Purpose: Calculate the average delivery time in days.
-- AVG() calculates the average of the DATEDIFF() results.
-- IS NOT NULL excludes orders without an actual delivery date.
SELECT 
	AVG(DATEDIFF(
    order_delivered_customer_date,
    order_purchase_timestamp
    )) AS average_delivery_days
FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NOT NULL;

-- Check whether orders arrived on time

SELECT 
	order_id,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    CASE
		WHEN order_delivered_customer_date
        <= order_estimated_delivery_date
        THEN 'On Time'
        ELSE 'Late'
	END AS delivery_status
    FROM olist_orders_dataset
    WHERE order_status = 'delivered';
    
    -- Count On Time vs Late orders
SELECT
	delivery_status,
    COUNT(*) AS total_orders
FROM (
	SELECT
		CASE
			WHEN order_delivered_customer_date
				<= order_estimated_delivery_date
            THEN 'On Time'
            ELSE 'Late'
		END AS delivery_status
	FROM olist_orders_dataset
    WHERE order_status = 'delivered'
) AS delivery_results
GROUP BY delivery_status;


-- Purpose: Count delivered orders by on-time or late status.
-- DATE() compares calendar dates without considering the time.
-- CASE WHEN classifies each order.
-- GROUP BY counts orders in each delivery-status category.

SELECT
    delivery_status,
    COUNT(*) AS total_orders
FROM (
    SELECT
        CASE
            WHEN DATE(order_delivered_customer_date)
                 <= DATE(order_estimated_delivery_date)
            THEN 'On Time'
            ELSE 'Late'
        END AS delivery_status
    FROM olist_orders_dataset
    WHERE order_status = 'delivered'
) AS delivery_results
GROUP BY delivery_status;

-- Purpose: Check the columns available in the order-items table.
-- DESCRIBE displays column names and their data types.

DESCRIBE olist_order_items_dataset;

-- Purpose: Check the columns available in the products table.
-- We need product_id to connect the tables and
-- product_category_name to group sales by category.

DESCRIBE olist_products_dataset;


-- Purpose: Match sold products with their product categories.
-- INNER JOIN keeps rows where product_id matches in both tables.
-- LIMIT 10 displays only 10 matching rows for checking.

SELECT
    oi.product_id,
    oi.price,
    p.product_category_name
FROM olist_order_items_dataset AS oi
INNER JOIN olist_products_dataset AS p
    ON oi.product_id = p.product_id
LIMIT 10;


-- Purpose: Calculate product sales by category.
-- SUM() adds the item prices.
-- GROUP BY calculates the total separately for each category.
-- ORDER BY DESC displays the highest sales first.

SELECT
    p.product_category_name,
    SUM(oi.price) AS total_sales
FROM olist_order_items_dataset AS oi
INNER JOIN olist_products_dataset AS p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_sales DESC;

-- Purpose: Check the columns available in the reviews table.
-- DESCRIBE shows column names and their data types.

DESCRIBE olist_order_reviews_dataset;

-- Purpose: Count customer reviews for each review score.
-- GROUP BY groups reviews with the same score.
-- COUNT(*) counts the reviews in each group.
-- ORDER BY sorts the scores from lowest to highest.

SELECT
    review_score,
    COUNT(*) AS total_reviews
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score;

-- Purpose: Calculate the average customer review score.
-- AVG() calculates the average of all review scores.
-- ROUND() limits the result to 2 decimal places.

SELECT
    ROUND(AVG(review_score), 2) AS average_review_score
FROM olist_order_reviews_dataset;

-- Purpose: Find the top 10 customer states by number of orders.
-- JOIN connects orders with customer location details.
-- GROUP BY groups orders by customer state.
-- COUNT(*) counts orders for each state.
-- ORDER BY sorts states from highest to lowest order count.
-- LIMIT 10 displays only the top 10 states.

SELECT
    c.customer_state,
    COUNT(o.order_id) AS total_orders
FROM olist_orders_dataset AS o
INNER JOIN olist_customers_dataset AS c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC
LIMIT 10;

-- Purpose: Calculate total payment value by payment method.
-- SUM() adds the payment values for each method.
-- GROUP BY separates the totals by payment type.
-- ORDER BY displays the highest total first.

SELECT
    payment_type,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- Purpose: Calculate the percentage of cancelled and unavailable orders.
-- SUM(CASE WHEN ...) counts orders in the two selected statuses.
-- COUNT(*) counts all orders.
-- 100.0 converts the calculation to a percentage.
-- ROUND() displays two decimal places.

SELECT
    SUM(
        CASE
            WHEN order_status IN ('canceled', 'unavailable') THEN 1
            ELSE 0
        END
    ) AS canceled_unavailable_orders,
    COUNT(*) AS total_orders,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_status IN ('canceled', 'unavailable') THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS percentage
FROM olist_orders_dataset;












            
    
 

    
    
    
    
    


