-- lesson after finding all the results (recheck the result for every query , make it accurate )

/* 1. Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
business in the  APAC  region. */
-- 1 correct 
Select market from dim_customer where customer = 'Atliq Exclusive' and region = 'APAC';

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? The 
final output contains these fields, 
unique_products_2020 
unique_products_2021 
percentage_chg*/
-- 2nd wrong do it once more - it is corrected by replacin the product with the product_code
with cte as ( 
select row_number() over() as rw,s.fiscal_year as fiscal_year, count(distinct(p.product_code)) as distinct_product
from fact_sales_monthly s 
join dim_product p 
on s.product_code = p.product_code 
where s.fiscal_year in (2020 , 2021)
group by fiscal_year ) ,

year_comp as (
SELECT c2020.distinct_product as Unique_product_2020,
		c2021.distinct_product as Unique_product_2021, 
    round(((c2021.distinct_product - c2020.distinct_product)*100/c2020.distinct_product),2) AS percentage_change 
FROM 
    cte c2020
JOIN 
    cte c2021
ON 
    c2020.fiscal_year = 2020 AND c2021.fiscal_year = 2021 ) 
    select * from year_comp;
 -- Returns exact result and it is similar to 4th question
 -- understand the process behind it (must do )
 
 
/*  Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
2 fields,*/
-- 3rd wrong do it once more -- Corrected , replaced the product to product_code
select p.segment, count(distinct (p.product_code)) as product_count
from dim_product p
group by segment 
order by product_count desc;

/* 4. Which segment had the most increase in unique products in 
2021 vs 2020? 
*/
-- 4th wrong look it once more -- corrected replaced product with the product_code
with product_count as (
select s.fiscal_year as fiscal_year, p.segment as segment , count(distinct(p.product_code)) as product_count
from fact_sales_monthly s 
join dim_product p 
on s.product_code = p.product_code 
where s.fiscal_year in (2020, 2021)
group by p.segment , s.fiscal_year
), 
year_comparison as (
select 
	pc2020.segment, 
    pc2020.product_count as product_count_2020,
    pc2021.product_count as product_count_2021,
    (pc2021.product_count - pc2020.product_count) AS difference
from 
	product_count pc2020
join 
	product_count pc2021
ON 
	pc2020.segment = pc2021.segment
WHERE 
	pc2020.fiscal_year = 2020 AND pc2021.fiscal_year = 2021
) 
select * from year_comparison;
 
-- taking the necessary data from the join table and then use cte for self join with it self , with condition of respective years

/*  Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code 
product 
manufacturing_cost */ 
-- 5th correct 
SELECT m.product_code , p.product , m.manufacturing_cost
FROM fact_manufacturing_cost m 
join dim_product p 
on m.product_code = p.product_code
where manufacturing_cost in ((select min(manufacturing_cost)  from fact_manufacturing_cost),
(select max(manufacturing_cost)  from fact_manufacturing_cost));


/*  Generate a report which contains the top 5 customers who received an 
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
Indian  market. The final output contains these fields, 
customer_code 
customer 
average_discount_percentage */
-- 6th correct 
SELECT pct.customer_code,c.customer , avg(pct.pre_invoice_discount_pct) as average_discount_percentage 
FROM gdb023.fact_pre_invoice_deductions pct 
join dim_customer c
on pct.customer_code = c.customer_code 
where pct.fiscal_year = 2021 and c.market = 'india' 
group by customer_code
order by average_discount_percentage desc
limit 5;

/* Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions. 
The final report contains these columns: 
Month 
Year 
Gross sales Amount */
-- 7 wrong go though once more --- done
WITH temp_table AS (
    SELECT customer,
    monthname(date) AS months ,
    month(date) AS month_number, 
    year(date) AS year, s.fiscal_year as FY,
    (sold_quantity * gross_price)  AS gross_sales
 FROM fact_sales_monthly s JOIN
 fact_gross_price g ON s.product_code = g.product_code
 JOIN dim_customer c ON s.customer_code=c.customer_code
 WHERE customer="Atliq exclusive"
)
SELECT months,year,FY, concat(round(sum(gross_sales)/1000000,2),"M") AS gross_sales FROM temp_table
GROUP BY year,months
ORDER BY year,month_number;

 /* In which quarter of 2020, got the maximum total_sold_quantity? 
The final output contains these fields sorted by the total_sold_quantity, 
Quarter 
total_sold_quantity */
-- 8 done correct 
with cte as ( SELECT 
case 
	when month(date) in (9,10,11) then 'Q1'
    when month(date) in (12,1,2) then 'Q2'
    when month(date) in (3,4,5) then  'Q3'
    when month(date) in (6,7,8) then  'Q4'
    end as Quarter , round((sum(sold_quantity)/1000000),2) as total_sold_quantity
FROM gdb023.fact_sales_monthly
where fiscal_year = 2020
group by Quarter) 
select Quarter, max(total_sold_quantity) as max_sold_quantity from cte;

/*  Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?  The final output  contains these fields, 
channel 
gross_sales_mln 
percentage*/
-- 9 incomplete do once again -- done 
WITH temp_table AS (
      SELECT c.channel,sum(s.sold_quantity * g.gross_price) AS total_sales
  FROM
  fact_sales_monthly s 
  JOIN fact_gross_price g ON s.product_code = g.product_code
  JOIN dim_customer c ON s.customer_code = c.customer_code
  WHERE s.fiscal_year= 2021
  GROUP BY c.channel
  ORDER BY total_sales DESC
)
SELECT 
  channel,
  round(total_sales/1000000,2) AS gross_sales_in_millions,
  round(total_sales/(sum(total_sales) OVER())*100,2) AS percentage 
FROM temp_table ;







/*  Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these 
fields, 
division 
product_code
product 
total_sold_quantity 
rank_order */ 

with cte as (
select p.division as division,
        p.product as product,
        s.product_code as product_code,
        SUM(s.sold_quantity) AS total_sold_quantity,
        ROW_NUMBER() OVER (PARTITION BY p.division ORDER BY SUM(s.sold_quantity) DESC) AS rnk
from fact_sales_monthly s 
join dim_product p 
on s.product_code = p.product_code
where s.fiscal_year = 2021
group by p.division , p.product , s.product_code
) 

SELECT
    division,
    product,
    product_code,
    total_sold_quantity,
    rnk
FROM
    cte
WHERE
    rnk <= 3
ORDER BY
    division, total_sold_quantity DESC;
    
-- 10 done

