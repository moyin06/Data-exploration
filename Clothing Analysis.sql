											--Clothing Analysis--
--1. Which 5 customers have spent the most in total? Include their name, total amount spent, and number of purchases?----
select top 5 c.[name], floor(sum(p.price* quantity)) as amt_spent, count(s.sale_id) as num_pur
From sales s
 join customers c
	on s.customer_id = c.customer_id
 join products p
	on s.product_id = p.product_id
Group by c.[name]
Order by c.[name] desc

--2. Category-Wise Best-Selling Products--
--For each product category, which product had the highest total sales quantity?--
With product_sales as (
Select p.category, p.product_name, sum(s.quantity) as total_quantity
From sales s
    join products p on s.product_id = p.product_id
Group by p.category, p.product_name
),
ranked_sales as (
Select *,
	Rank() over (partition by category order by total_quantity desc) as rnk
From product_sales
)
Select category, product_name, total_quantity
From ranked_sales
Where rnk = 1;

--3. Customer Retention Check--
--Which customers made purchases in more than one month? Show their name and the months they shopped.--

Select c.[name], format(s.sale_date, 'yyyy-MM') as date
From Sales s
join customers c
	on s.customer_id = c.customer_id
Group by c.[name], format(s.sale_date, 'yyyy-MM')
Having count( distinct format(s.sale_date, 'yyyy-MM')) > 1;

--4. Product Performance Over Time
--What is the total monthly quantity sold for each product? (Use a CTE to simplify the result.)

With monthly_sales as (
Select  Product_id, format (sale_date, 'yyyy-MMMM') as monthly, Sum(quantity) as total_quantity
From Sales
Group by Product_id, format (sale_date, 'yyyy-MMMM')
)
Select  product_id, monthly, total_quantity 
From monthly_sales
Order by monthly;

--5. Low-Performing Products (Subquery)
--List products whose total sales quantity is below the average quantity sold across all products.

Select p.product_name, sum(s.quantity) totalqty
From Sales s
join products p
	on s.product_id = p.product_id
Group by p.product_name 
Having sum(s.quantity) < (
		Select avg(totalqty) 
		From (
			select sum(quantity) as totalqty
			From sales
			Group by product_id
			) as avgtbl
);

--6.  Most Popular Category per Month
--For each month, which product category sold the most units?

With category_monthly_sales as (
Select format (s.sale_date, 'yyyy-MMMM') as monthly, p.category,  sum(s.quantity) units
From sales s
join products p
	on s.product_id = p.product_id
Group by format (s.sale_date, 'yyyy-MMMM'), p.category
),
ranked as (
    Select *,
        rank() over (partition by monthly order by units desc) as rnk
    from category_monthly_sales
)
select Monthly, category, units
from ranked
where rnk = 1;

--7. Big Spenders with Repeat Purchases
--Identify customers who spent more than the average and made purchases in at least 3 different transactions.
With cus_t as (
Select s.customer_id, count(s.sale_id) numpur, c.[name], sum(s.quantity * p.price) tspent
From Sales s
join customers c
	on c.customer_id = s.customer_id
join products p
on s.product_id = p.product_id
Group by s.customer_id, c.[name]
),
spendings as (
	select avg(tspent) as avgqty
	from cus_t
)

Select ct.[name], ct.tspent, numpur
From cus_t ct
join spendings st  ON 1=1
where ct.tspent > st.avgqty AND ct.numpur >= 3;

--8. Dormant Customers (Subquery)
--Which customers haven’t made a purchase in the last 60 days from the most recent sale date?
Select c.name
From customers c
Where c.customer_id NOT IN (

Select s.customer_id
From Sales s
where s.sale_date > (

Select dateadd(day, -60, max(sale_date))
From Sales)
);

--9. High-Volume Sales Days
--On which days was the total quantity of products sold higher than the daily average?
With productqty as (
Select p.Product_name, s.Sale_date, sum(s.quantity) as tqty
From Sales s
join products p
	on s.product_id = p.product_id
Group by p.Product_name, s.Sale_date
),
dailyavg as (
Select avg(tqty) as agty
From productqty
)

Select pq.sale_date, pq.Product_name, pq.tqty
From productqty pq
JOIN dailyavg da ON pq.tqty > da.agty;

--10. Top Products by Revenue with CTE
--Use a CTE to find the top 3 products by revenue in each category. 
With revenue as (
Select P.category, p.product_name, Sum(P.price * S.quantity) as rev
From Sales s
join products p
 on s.product_id = p.product_id
Group by P.category, p.product_name
),

ranked_products as (
Select *,
  rank() over (partition by category order by rev desc) as rnk
From revenue
)
Select category, product_name, rev
From ranked_products
Where rnk <= 3;