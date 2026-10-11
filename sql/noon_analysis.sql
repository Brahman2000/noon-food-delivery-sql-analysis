-- 1 -- find top 1 outlet by cuisine type without using limit and top function 
with cte1 as (select *,dense_rank()over(partition by cuisine order by no_of_order desc ) as dnrnk 
from (
select  restaurant_id,cuisine,count(*) as no_of_order
from orders
group by restaurant_id,cuisine) as x)

select * from cte1
where dnrnk=1  ;

-- 2 -- find daily new customer count from the launch date(everday how many new customers we are acquiring )
with cte as (select customer_code , cast(min(placed_at) as date) as first_order
from orders 
group by customer_code
)
select first_order, count(*) as daily_new_customer
from cte
group by first_order
order by first_order ;

with cte2  as (
select *,cast(placed_at as date) as first_date from 
(
select *,
row_number()over(partition by customer_code order by placed_at ) as rn 
from orders ) as t 
where rn=1 )

select first_date ,count(*) as new_customer
from cte2 
group by first_date
order by first_date;


-- 3 -- Count all the users who were acquired in January 2025 and placed only one order in January and did not place any other order

select customer_code,count(*) as no_of_orders
from orders
where month(placed_at)=1 and year(placed_at)=2025
and customer_code not in (select distinct customer_code
from orders
where not (month(placed_at)=1 and year(placed_at)=2025))
group by customer_code
having count(*)=1;

-- 4) List All the customers with no order in the last 7 days but were acquired one month ago with their first order
-- on promo.

with cte1 as (select customer_code,min(placed_at) as first_order_date,max(placed_at) as latest_order_date
from orders
group by customer_code)

select cte1.* ,orders.Promo_code_Name as first_order_promo
from cte1
inner join orders 
on cte1.customer_code=orders.customer_code and cte1.first_order_date=orders.placed_at
where latest_order_date < DATE_ADD(CURDATE(), INTERVAL -7 DAY)  and first_order_date < DATE_ADD(CURDATE(), INTERVAL -1 MONTH) and
orders.Promo_code_Name is not null  ;

-- 5-- Growth team is planning to create a trigger that will target customers after their every
-- third order with a personalized communication and they have asked you to create a query for this.

with cte as (select * ,
row_number()over(partition by customer_code order by placed_at asc) as rn
from orders )

select * from cte
where rn%3=0 and cast(placed_at as date)=cast(now() as date);

-- 6-- list customer who placed more than 1 order and all their orders on a promo only 
select customer_code,count(*) as no_of_orders ,count(promo_code_name) as promo_orders
from orders
group by customer_code 
having count(*)>1 and count(*)=count(promo_code_name);

-- 7-- what percent of customers were organically acquired in jan 2025 (placed their first order without promo code)

WITH cte AS (
    SELECT customer_code,
           MIN(placed_at) AS first_order
    FROM orders
    GROUP BY customer_code
    HAVING MIN(placed_at) >= '2025-01-01'
       AND MIN(placed_at) < '2025-02-01'
)

,cte1 as (select count(*) as cust_wiout_promo_code from 
(select cte.*, orders.promo_code_name as first_order_promo_code
from cte 
inner join 
orders 
on cte.customer_code=orders.customer_code and cte.first_order=orders.placed_at
where orders.promo_code_name is null ) as t)

,cte2 AS (
    SELECT COUNT(*) AS acrd_in_jan_2025
    FROM cte
)

SELECT 
    (SELECT cust_wiout_promo_code FROM cte1) * 100.0
    / 
    (SELECT acrd_in_jan_2025 FROM cte2) 
    AS organic_percentage;
    
    -- 8. Which cuisine has the highest number of orders?
    
    with cte as (select *
    ,dense_rank()over(order by no_of_orders_by_cuisine desc ) as dn from 
    (
    select cuisine, count(*) as no_of_orders_by_cuisine
    from orders
    group by cuisine) as x)
    
    select cuisine, no_of_orders_by_cuisine from cte
    where dn=1;
    
    -- Q9. What percentage of total orders used a promo code?
    
    select count(case when promo_code_name is not null then 1  end ) *100.0/ count(*) as percentage_of_promo_code  from orders ;

-- 10. What is the repeat customer rate (Customers with more than 1 order ÷ total customers.)?

select count(*)*100.00/(select count(distinct customer_code) from orders ) from 
(select  customer_code
from orders 
group by customer_code
having count(*)>1) as c;  

-- 11. What is the average number of orders per customer?

select count(*) / count(distinct customer_code) from orders ;

-- Q12. What percentage of orders were delivered vs cancelled?
select 
count(case when order_status = "Delivered" then 1  end )*100.0/count(*) as delivered_percentage,
count(case when order_status="Cancelled" then 1 end )*100.0/ count(*) as cancelled_percentage
from orders 


