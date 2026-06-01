
--DATA CLEANING AND VALIDATING
-- Table details
SELECT tablename
FROM pg_tables
WHERE schemaname ='public';


-- Checking Duplicate Values in Product & Customer Table
SELECT  product_id, COUNT(product_id)
FROM dim_products
GROUP BY product_id
HAVING COUNT(product_id)>2;

SELECT customer_id, COUNT(customer_id)
FROM dim_customers
GROUP BY customer_id
HAVING COUNT(customer_id)>2;

--Remove Duplicates
WITH Duplicate AS (
SELECT *, RANK() OVER (PARTITION BY customer_id ORDER BY customer_id) AS Rnk
FROM dim_customers
)
DELETE FROM dim_customers
WHERE customer_id IN(
     SELECT customer_id 
	 FROM Duplicate
	 WHERE Rnk >1
)
--Checking relationship
SELECT *
FROM fact_sales s
JOIN dim_products p
ON s.product_key = p.product_key
WHERE p.product_key IS NULL;

SELECT *
FROM fact_sales s
JOIN dim_customers c
ON s.customer_key = c.customer_key
WHERE c.customer_key IS NULL;

-- Checking for Null Values
SELECT COUNT(*) AS Total_rows,
       COUNT (sales_amount) AS Sales_count,
	   COUNT (order_number) AS Order_count,
	   COUNT (shipping_date) AS Shipping_count,
	   COUNT (order_date) AS OrderDate_count,
	   COUNT (customer_key) AS Customer_count,
	   COUNT (quantity) AS quantity_count,
	   COUNT (price) AS price_count
FROM fact_sales;

-- Order_date has 19 Null Values
-- For time-based analysis, need to exlcude NULL values of order_date

--DATA Type Checking
ALTER TABLE fact_sales
ALTER COLUMN sales_amount TYPE TEXT
USING sales_amount::TEXT

SELECT *
FROM fact_sales
LIMIT 0;

SELECT *
FROM dim_customers
LIMIT 0;

SELECT *
FROM dim_products
LIMIT 0;

ALTER TABLE fact_sales
ALTER COLUMN sales_amount TYPE INT
USING sales_amount::INT

--Checking DATE Ranges
SELECT MIN(order_date) AS Min_orderdate,
MAX(order_date) AS Max_orderdate,
MIN(shipping_date) AS Min_shipping,
MAX(shipping_date) AS Max_shipping,
MIN(due_date) AS Min_due,
MAX(due_date) AS Max_due
FROM fact_sales;

SELECT MIN (start_date) AS Min_start,
MAX (start_date) AS Max_start
FROM dim_products;

SELECT MIN (birthdate) AS Min_birth,
MAX (birthdate) AS Max_birth,
MIN (create_date) AS Min_create,
MAX (create_date) AS Max_create
FROM dim_customers;

---------------------------------------------------------------------------------------------------
--ANALYSIS
--Changes over Time Analysis - monthly Aggregation

SELECT TO_CHAR(order_date,'yyyy-mm') AS Year_Month,
SUM(sales_amount) AS TotalSales,
SUM(customer_key) AS TotalCustomers,
SUM (product_key) AS TotalProducts,
( LAG(SUM(sales_amount)) OVER(Order BY TO_CHAR(order_date,'yyyy-mm')) 
- SUM(sales_amount)) AS Diff
FROM fact_sales
WHERE order_date is NOT NULL
GROUP BY TO_CHAR(order_date,'yyyy-mm')
ORDER BY TO_CHAR(order_date,'yyyy-mm') ; 

-----------------------------------------------------------------------------------

--Cumulative Analysis - Running Total_sales & Running Average_price

SELECT TO_CHAR(order_date,'yyyy-mm') AS Month_Year,
SUM(sales_amount) AS Total_Sales,
SUM(SUM(sales_amount))OVER( 
ORDER BY TO_CHAR(order_date,'yyyy-mm')) AS Running_Totalsales,
ROUND(AVG(SUM(price)) OVER (
ORDER BY TO_CHAR(order_date,'yyyy-mm')),1) AS Running_Avgprice
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY TO_CHAR(order_date,'yyyy-mm')
ORDER BY TO_CHAR(order_date,'yyyy-mm');

---------------------------------------------------------------------------------------------
/*Performance Analysis
Analyze the yearly performance of products by comparing each product's sales to 
both its average sales performance and the previous year's sales
*/
SELECT p.product_name,
TO_CHAR(order_date,'yyyy') AS orderyear, 
SUM(sales_amount) AS TOTAL_SALES,
ROUND(AVG(SUM(sales_amount)) 
OVER(PARTITION BY p.product_name),1) AS Avg_productsales,
SUM(sales_amount) - ROUND(AVG(SUM(sales_amount))
OVER(PARTITION BY p.product_name),1) AS Diff_avg,
CASE WHEN SUM(sales_amount) - ROUND(AVG(SUM(sales_amount)) 
     OVER(PARTITION BY p.product_name),1) >0 
     THEN 'Above average'
     WHEN SUM(sales_amount) - ROUND(AVG(SUM(sales_amount))
	 OVER(PARTITION BY p.product_name),1) <0 
	 THEN 'Below average'
	 ELSE 'Average'
END Diff_avg_status,
LAG(SUM(s.sales_amount))
OVER (PARTITION BY p.product_name) AS PY_sales,
SUM(sales_amount) - LAG(SUM(s.sales_amount)) 
OVER (PARTITION BY p.product_name) AS Diff_PYsales,
CASE WHEN SUM(sales_amount) - LAG(SUM(s.sales_amount)) 
     OVER (PARTITION BY p.product_name) >0 
     THEN 'Increase'
     WHEN SUM(sales_amount) - LAG(SUM(s.sales_amount))
	 OVER (PARTITION BY p.product_name) <0
	 THEN 'Decrease'
	 ELSE 'No change'
END Diff_PYsales_status,
COUNT(s.product_key) AS Count_products
FROM fact_sales s
LEFT JOIN dim_products p
ON s.product_key = p.product_key
WHERE order_date IS NOT NULL
GROUP BY TO_CHAR(order_date,'yyyy'), p.product_name
ORDER BY p.product_name, orderyear;

--------------------------------------------------------------------------------------------------------

SELECT *
FROM dim_products
LIMIT 10;

--Percentage Analysis - Totol Sales by product Category
WITH Cate AS ( 
SELECT category,SUM(sales_amount) AS Cate_sales
FROM fact_sales s
LEFT JOIN dim_products p 
ON p.product_key = s.product_key
GROUP BY p.category
ORDER BY Cate_sales DESC
)

SELECT *,
SUM(Cate_Sales)OVER () AS Total_sales, 
CONCAT(ROUND((Cate_sales/SUM(Cate_sales)OVER ())*100,1),'%') AS Percentage
FROM Cate

-------------------------------------------------------------------------------

/*TOP N Analysis
Give me Top 10 Customers with high Total Sales
*/
WITH Top_sales AS (
SELECT customer_key,
SUM(sales_amount) AS Total_sales,
RANK() OVER( 
ORDER BY SUM(sales_amount) DESC ) AS rnk
FROM fact_sales
GROUP BY customer_key
)
SELECT customer_key,Total_sales
FROM Top_sales
WHERE rnk <=10;

/*Data Segmentation
Segment products into cost ranges and 
count how many products fall into each segment
*/

WITH costcate AS (
SELECT product_name,SUM(cost),
CASE 
    WHEN SUM(cost) <100 THEN  'Below 100'
    WHEN SUM(cost) BETWEEN 100 AND 200 THEN  '100 - 200'
    WHEN SUM(cost) BETWEEN 200 AND 500 THEN  '200 - 500'
    WHEN SUM(cost) BETWEEN 500 AND 1000 THEN  '500 - 1000'
ELSE 'Above 1000'
END AS cost_range
FROM dim_products
GROUP BY product_name
ORDER BY SUM(cost) DESC
)

SELECT cost_range, COUNT(cost_range) AS Count
FROM costcate
GROUP BY cost_range
ORDER BY cost_range;

/* Group Customers into three segments based on their spending behavior
 - VIP - Customers with at least 12 months of history and spending more than 5000
 - Regular - Customers with at least 12 months of history but spending 5000 or less
 - New - Customers with a lifespan of less than 12 months
 And find the total number of customers by each group
 */

SELECT *
FROM fact_sales
LIMIT 10;

WITH Customer_seg AS(
SELECT customer_id, 
SUM(sales_amount) AS Total_sales,
MIN(order_date) as first_order, 
MAX(order_date) AS last_order,
((MAX(order_date) - MIN(order_date))/30) AS History_months ,
CASE 
    WHEN SUM(sales_amount) > 5000 AND ((MAX(order_date) - MIN(order_date))/30) >= 12 
    THEN 'VIP'
    WHEN SUM(sales_amount)<=5000 AND ((MAX(order_date) - MIN(order_date))/30) >=12 
    THEN 'Regular'
    WHEN ((MAX(order_date) - MIN(order_date))/30) <12 
    THEN 'New'
	ELSE 'Not Applicable'
END AS Customer_Cate
FROM fact_sales s
LEFT JOIN dim_customers c
ON s.customer_key = c.customer_key
GROUP BY customer_id
ORDER BY SUM(sales_amount) DESC
)
SELECT *
FROM Customer_seg
WHERE Customer_Cate IS NULL;

SELECT Customer_Cate, COUNT(customer_id) AS Total_Count 
FROM Customer_seg
--WHERE Customer_Cate = NULL;
GROUP BY Customer_Cate;
/*
==============================================================
Customer Report
==============================================================

Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.

    2. Segments customers into categories (VIP, Regular, New) and age groups.

    3. Aggregates customer-level metrics:
        - total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)

    4. Calculates valuable KPIs:
        - recency (months since last order)
        - average order value
        - average monthly spend
*/

SELECT *
FROM dim_customers
LIMIT 10;

SELECT *
FROM fact_sales
LIMIT 10;


-- General Details & Aggregates customer-level metrics
WITH Customer_seg AS(
SELECT customer_id,
CONCAT(first_name,' ',last_name) AS Customer_name,
birthdate AS Birthdate,
MIN(order_date) as first_order, 
MAX(order_date) AS last_order,
SUM(sales_amount) AS Total_sales,
COUNT (order_number) AS Total_orders,
SUM(quantity) AS Total_quantity,
COUNT(DISTINCT(product_key)) AS Total_uniqueproducts,
(CURRENT_DATE - c.birthdate::date)/356 AS AGE,
((MAX(order_date) - MIN(order_date))/30) AS Lifespan_months

FROM fact_sales s
LEFT JOIN dim_customers c
ON s.customer_key = c.customer_key
GROUP BY customer_id,first_name,last_name,birthdate
ORDER BY SUM(sales_amount) DESC
),

--Segments customers into categories 
 Cus_Cate AS (
SELECT *,
CASE WHEN Total_sales > 5000 AND Lifespan_months >= 12 
     THEN 'VIP'
     WHEN Total_sales <=5000 AND Lifespan_months >=12 
     THEN 'Regular'
     WHEN Lifespan_months <12
     THEN 'New'
END AS Customer_Cate,
CASE WHEN AGE <30 THEN 'Under 30'
     WHEN AGE >=30 AND AGE < 50 THEN 'Between 30 and 50'
     WHEN AGE >=50 THEN 'Above 50'
     ELSE 'Not Applicable'
END AS Age_Cat
FROM Customer_seg
)

--Valuable KPIs:
SELECT *, 
((CURRENT_DATE - last_order)/30) AS Recency,
(total_sales/NULLIF(lifespan_months,0)) AS Monthly_avgspends,
(total_sales/NULLIF(total_orders,0)) AS Avg_ordervalue
FROM Cus_Cate;


-----------------------END---------------------------------------------------



