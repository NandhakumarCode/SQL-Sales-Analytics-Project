**Sales Analytics SQL Project**
**Project Overview**

This project analyzes sales performance using a Star Schema data model consisting of one Fact table and two Dimension tables. The objective is to generate business insights related to sales trends, product performance, and customer behavior using SQL.

**Data Model**

Fact Table

**fact_sales**

order_number,
product_key,
customer_key,
order_date,
shipping_date,
due_date,
sales_amount,
quantity,
price.

**Dimension Tables**

**dim_products**

Product information and attributes

**dim_customers**

Customer demographics and details

**Data Cleaning** : 
Before performing the analysis, the dataset was validated through the following checks:

- Verified data types for all columns
- Checked for NULL values
- Identified and handled duplicate records
- Validated order date ranges
- Verified relationships between Fact and Dimension tables
- Checked for missing Product Keys and Customer Keys
- Ensured data consistency across tables

**Analysis Performed**
1. Sales Trend Analysis :
Monthly sales aggregation,
Identification of sales trends over time

2. Running Metrics :
Running Total Sales,
Running Average Price

3. Product Performance Analysis :
Comparison of product sales against average sales performance,
Previous year vs current year performance analysis

4. Category Contribution Analysis :
Percentage contribution of each product category to total sales

5. Product Segmentation :
Grouped products into cost ranges,
Counted products within each segment

6. Customer Segmentation :
Classified customers into spending segments:
High Value,
Medium Value,
Low Value.

7. Customer Performance Report :

Generated customer-level KPIs including:

Total Sales,
Total Orders,
Recency (Months Since Last Order),
Average Order Value,
Average Monthly Spend.

8. Top-N Analysis :
Top Customers by Sales,
Ranking using SQL Window Functions.

**SQL Concepts Used**
Joins,
Common Table Expressions (CTEs),
Aggregate Functions,
Window Functions,
CASE Statements,
Date Functions,
Group By & Having,
Delete,Alter and Drop.


**Key Business Insights**
Identified sales trends across different time periods.
Measured product performance against historical benchmarks.
Determined category contribution to overall revenue.
Segmented customers based on spending behavior.
Highlighted top-performing customers and products.

**Tools Used**
PostgreSQL,
Excel,
GitHub.
