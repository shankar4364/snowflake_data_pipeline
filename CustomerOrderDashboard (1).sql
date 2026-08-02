-- customer orders data pipeline with dashboard

use warehouse Demo_Wh;

use database Demo_Db;

use schema CustOrders;

-- create customer table 

CREATE TABLE customers (
  customer_id INT,
  name STRING,
  city STRING
);

-- create Order table


CREATE TABLE orders (
  order_id INT,
  customer_id INT,
  amount INT,
  order_date DATE
);

-- Create stage for temperory loading data from csv files

CREATE STAGE cust_stage;
CREATE STAGE order_stage;

-- toload data into stages using User interface

-- after that stages data copy into tables using copy command

COPY INTO customers
FROM @cust_stage/customers.csv
FILE_FORMAT = (TYPE = CSV);

COPY INTO orders
FROM @order_stage/orders.csv

FILE_FORMAT = (TYPE = CSV);


-- check the data successfully loaded or not 
select * from customers;
select * from orders;

-- create dummy table customer_summary

-- applying some transformation as per requirment 

create table customer_summary as 
select c.customer_id,c.name,c.city,count(o.order_id) as total_orders
,sum(o.amount) as total_spent
from customers c
join orders o 
on c.customer_id=o.customer_id
group by c.customer_id,c.name,c.city;

CREATE TABLE customer_summary AS
SELECT 
  c.customer_id,
  c.name,
  c.city,
  COUNT(o.order_id) AS total_orders,
  SUM(o.amount) AS total_spent
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.city;




-- create stream for tracking the changes while performing operation insert update delete

create stream orders_stream  on table orders;


-- create task 
-- to read the updated DATABASE
-- to store the updated DATABASE
-- snowflake automatically runs the query


create task order_task
warehouse =Demo_Wh
schedule='1 minute'
as 
insert into customer_summary
SELECT 
  c.customer_id,
  c.name,
  c.city,
  COUNT(o.order_id) AS total_orders,
  SUM(o.amount) AS total_spent
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.city;

-- snowflake automatically run the query 
-- read the data
-- saves updated data
-- keep data upated


alter task order_task resume;

-- create materialized view 
-- precomputed query 
-- by using this we cannot write same codde again agian 
-- use materialized view

 create materialized view mv_customer as
 select name, total_spent from customer_summary;



 -- applying masking policy 

 create masking policy  mask_amt as (val int) 
 returns int  ->
 case 
 when current_role() ='ACCOUNTADMIN' then val
 else 0
 end;

 alter table orders modify column amount  set masking policy mask_amt;



 -- create role as per role gives permission 

 create role db_analyst;

 grant select on customer_summary to role db_analyst;
 
-- grant role db_analyst to user SHANKAR9663;

-- create resource monitor rm2 to monitor the how credi used by wh if limit exeed that time suspend wh
with credit_quota=10
triggers
on 100 percent do suspend;


-- final step create streamlit code 


