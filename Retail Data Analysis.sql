-- DATA PREPARATION AND UNDERSTANDING
-- 1. What is the total number of rows in each of the 3 tables in the database?
SELECT COUNT(*) No_of_rows
FROM customer
UNION
SELECT COUNT(*) No_of_rows
FROM prod_cat_info
UNION
SELECT COUNT(*) No_of_rows
FROM Transactions;

-- 2. What is the total number of transactions that have a return?
SELECT COUNT(DISTINCT transaction_id)
FROM Transactions
WHERE Qty < 0;

-- 3. As you would have noticed, the dates provided across the datasets are not in a correct format. As first steps, please convert the date variables into valid date formats before proceeding ahead.
SELECT CONVERT(DATE, DOB, 105)
FROM customer;

SELECT CONVERT(DATE, tran_date, 105)
FROM Transactions;

-- 4. What is the time range of the transaction data available for analysis? Show the output in number of days, months and years simultaneously in different columns.
SELECT DATEDIFF(DAY, MIN(CONVERT(DATE, tran_date, 105)),MAX(CONVERT(DATE, tran_date, 105))) AS Diff_Days,
DATEDIFF(MONTH, MIN(CONVERT(DATE, tran_date, 105)),MAX(CONVERT(DATE, tran_date, 105))) AS Diff_Months,
DATEDIFF(YEAR, MIN(CONVERT(DATE, tran_date, 105)),MAX(CONVERT(DATE, tran_date, 105))) AS Diff_Years
FROM Transactions;

-- 5. Which product category does the sub-category "DIY" belong to?
select top 1* from prod_cat_info

SELECT prod_cat, prod_subcat
FROM prod_cat_info
WHERE prod_subcat = 'DIY';


-- DATA ANALYSIS

-- 1. Which channel is most frequesntly used for transactions?
SELECT TOP 1 Store_type, COUNT(*) AS Channel_Frequency
FROM Transactions
GROUP BY Store_type
ORDER BY COUNT(*) DESC;

-- 2. What is the count of male and Female customers in the database?
SELECT Gender, COUNT(*) as Gender_Count
FROM Customer
WHERE Gender is NOT NULL
GROUP BY Gender;

-- 3. Form which city do we have the maximum number of customers and how many?
SELECT TOP 1 city_code, COUNT(*) AS No_of_customers
FROM Customer
GROUP BY city_code
ORDER BY COUNT(*) DESC;

-- 4. How many sub-categories are there under the Book category?
SELECT prod_cat, prod_subcat
FROM prod_cat_info
WHERE prod_cat = 'Books';

-- OR

SELECT prod_cat, COUNT(prod_subcat) as No_of_SubCategories
FROM prod_cat_info
WHERE prod_cat = 'Books'
GROUP BY prod_cat;

-- 5. What is the maximum quantity of products ever ordered?
SELECT p.prod_cat, MAX(t.Qty) Max_quantity
FROM Transactions t
JOIN prod_cat_info p
ON t.prod_cat_code = p.prod_cat_code
GROUP BY p.prod_cat;

-- 6. What is the net total revenue generated in categories Electronics and Books?
SELECT p.prod_cat, SUM(CAST(t.total_amt as FLOAT)) as Total_revenue
FROM Transactions t
JOIN prod_cat_info p
ON t.prod_cat_code = p.prod_cat_code AND t.prod_subcat_code = p.prod_sub_cat_code
WHERE p.prod_cat IN ('Electronics', 'Books')
GROUP BY p.prod_cat;

-- 7. How many costumers have >10 transaction with us,excluding returns?
SELECT COUNT(*) as Total_customers
FROM (
SELECT cust_id, COUNT ( DISTINCT transaction_id) as No_of_transactions
FROM Transactions
WHERE Qty > 0
GROUP BY cust_id
HAVING COUNT ( DISTINCT transaction_id) > 10) as Customer_count;

-- 8. What is the combined revenue earned from the "Electronics" & "Clothing" categories,from "Flagship stories"?
SELECT SUM(CAST(t.total_amt as FLOAT)) as Combined_revenue
FROM Transactions t
JOIN prod_cat_info p
ON t.prod_cat_code = p.prod_cat_code AND t.prod_subcat_code = p.prod_sub_cat_code
WHERE p.prod_cat IN ('Electronics', 'Clothing') AND t.Store_type = 'Flagship store' AND t.Qty>0;

-- 9. What is the total revenue generated from "Male" customers in "Electronics"category?Output should diaplay total revenue by prod sub-cat.
SELECT p.prod_subcat ,SUM(CAST(t.total_amt as FLOAT)) as Total_revenue
FROM Customer c
JOIN Transactions t
ON c.customer_Id = t.cust_id
JOIN prod_cat_info p
ON t.prod_cat_code = p.prod_cat_code AND t.prod_subcat_code = p.prod_sub_cat_code
WHERE c.Gender = 'M' AND p.prod_cat = 'Electronics'
GROUP BY p.prod_subcat;

-- 10. What is the percentage of sales and returns by product sub category;display only top 5 sub categories in terms of sales?
-- Percentage of Sales
SELECT Percent_Sales.prod_subcat, Percentage_of_sales, Percentage_of_returns FROM
(
SELECT TOP 5 p.prod_subcat, SUM(CAST(t.total_amt as FLOAT)) / (SELECT SUM(CAST (total_amt as FLOAT)) as Total_sales FROM Transactions WHERE Qty>0) as Percentage_of_sales
FROM prod_cat_info p
JOIN Transactions t
ON p.prod_cat_code = t.prod_cat_code AND p.prod_sub_cat_code = t.prod_subcat_code
WHERE t.Qty > 0
GROUP BY p.prod_subcat
ORDER BY Percentage_of_sales DESC
) as Percent_Sales
JOIN
-- Percentage of Returns
(
SELECT p.prod_subcat, SUM(CAST(t.total_amt as FLOAT)) / (SELECT SUM(CAST (total_amt as FLOAT)) as Total_sales FROM Transactions WHERE Qty<0) as Percentage_of_returns
FROM prod_cat_info p
JOIN Transactions t
ON p.prod_cat_code = t.prod_cat_code AND p.prod_sub_cat_code = t.prod_subcat_code
WHERE t.Qty < 0
GROUP BY p.prod_subcat
) as Percent_Returns
ON Percent_Sales.prod_subcat = Percent_Returns.prod_subcat;

-- 11. For all customers aged between 25 to 35 years find what is the net total revenue generated by thease consumers in last 30 days of transactions from max transaction date available in the data?
-- Age of customer
SELECT * 
FROM
(
SELECT *
FROM 
(
SELECT customer_Id, DATEDIFF(YEAR, DOB, Max_date) as Age, Revenue
FROM 
(
SELECT c.customer_Id, c.DOB, MAX(CONVERT(DATE, t.tran_date, 105)) as Max_date, SUM(CAST(t.total_amt as FLOAT)) as Revenue
FROM Customer c
JOIN Transactions t
ON c.customer_Id = t.cust_id
WHERE t.Qty>0
GROUP BY c.customer_Id, c.DOB
) as A
) as B
WHERE Age BETWEEN 25 AND 35
) as C
JOIN
-- Last 30 days of transactions
(
SELECT cust_id, CONVERT(DATE, tran_date, 105) as Tran_date
FROM Transactions
GROUP BY cust_id, CONVERT(DATE, tran_date, 105)
HAVING CONVERT(DATE, tran_date, 105) > (SELECT DATEADD(DAY, -30, MAX(CONVERT(DATE, tran_date, 105))) as cutoff_date  FROM Transactions)
) as D
ON C.customer_Id = D.cust_id;	

-- 12. Which product category has been the max value of returns in the last 3 months of transactions?
SELECT TOP 1 prod_cat_code, SUM(Returns) as Tot_returns
FROM
(
SELECT prod_cat_code, CONVERT(DATE, tran_date, 105) as Tran_date, SUM(Qty) as Returns
FROM Transactions
WHERE Qty < 0
GROUP BY prod_cat_code, CONVERT(DATE, tran_date, 105)
HAVING CONVERT(DATE, tran_date, 105) > (SELECT DATEADD(MONTH, -3, MAX(CONVERT(DATE, tran_date, 105))) as cutoff_date  FROM Transactions)
) as A
GROUP BY prod_cat_code
ORDER BY Tot_returns;

-- 13. Which store-type sells the maximum products; by value of sales amount and by quantity sold?
SELECT Store_type, SUM(CAST(total_amt as FLOAT)) as Revenue, SUM(Qty) as Quantity
FROM Transactions
WHERE Qty > 0
GROUP BY Store_type
ORDER BY Revenue DESC, Quantity DESC

-- 14. What are the categories for which average revenue is above the overall average.
SELECT prod_cat_code, AVG(CAST(total_amt as FLOAT)) as Avg_revenue
FROM Transactions
WHERE Qty > 0
GROUP BY prod_cat_code
HAVING AVG(CAST(total_amt as FLOAT)) >= (SELECT AVG(CAST(total_amt as FLOAT)) FROM Transactions WHERE Qty > 0)

-- 15. Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.
SELECT prod_subcat_code, AVG(CAST(total_amt as FLOAT)) as Avg_revenue, SUM(CAST(total_amt as FLOAT)) as Revenue
FROM Transactions
WHERE Qty > 0 AND prod_cat_code IN (SELECT TOP 5 prod_cat_code FROM Transactions
									WHERE Qty > 0
									GROUP BY prod_cat_code
									ORDER BY SUM(Qty) DESC) 

GROUP BY prod_subcat_code;
