-- show database;
--use warehouse COMPUTE_WH;
 
create database GCSProject;
 
--use database GCSProject;
 
create schema raw;
create schema mart;
 
-- show tables;
 
-- cretae storage integration
 
create or replace storage integration GCS_INT2
type=external_stage
enabled=true
storage_provider='GCS'
storage_allowed_locations=('gcs://retail-analytics-bucket1/');
 
 
-- desc integration
 
desc integration GCS_INT2;
 
-- create
 
CREATE OR REPLACE FILE FORMAT csv_format
TYPE = CSV
FIELD_DELIMITER = ','
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
NULL_IF = ('NULL', 'null');
 
-- create or replace stage
 
 
CREATE or replace  STAGE RETAIL_STAGE
FILE_FORMAT=CSV_FORMAT
STORAGE_INTEGRATION=GCS_INT2
URL='gcs://retail-analytics-bucket1/';
 
list @RETAIL_STAGE;
 
 
-- create tables
 
-- customers
create  or replace table raw_customers
(
customer_id varchar(255),
customer_name varchar(255),
email varchar(255),
city varchar(255)
 
);
 
--
create table raw_inventory
(
inventory_id varchar(255),
product_id varchar(255),
store_id varchar(255),
stock_qty int
 
);
 
--
 
create table raw_product
(
product_id varchar(255),
product_name varchar(255),
category varchar(255),
unit_price int
);
 
 
-- stores
 
create table raw_stores
(
store_id varchar(255),
store_name varchar(255),
location varchar(255)
 
);
 
 
--  order
 
create table raw_orders
(
order_id int,
customer_id varchar(255),
product_id varchar(255),
store_id varchar(255),
qty int,
price int,
order_date date
 
);
 
 
--show tables ;
 
--load data into tables from external staging area
 
copy into raw_customers
from @RETAIL_STAGE/customers;
 
 
copy into raw_inventory
from @RETAIL_STAGE/inventory;
 
 
copy into raw_orders
from @RETAIL_STAGE/orders;
 
 
copy into raw_product
from @RETAIL_STAGE/products;
 
 
copy into raw_stores
from @RETAIL_STAGE/stores;
 
 
-- check data loaded into tables or not
 
select * from raw_customers;
 
select * from raw_inventory;
select * from raw_orders;
select * from raw_product;
select * from raw_stores;
 
 
-- create star schema  
 
-- ALL ARE THE DIMENSION TABLES
 
 
create table MART.DIM_CUSTOMERS
AS
SELECT * FROM RAW_CUSTOMERS;
 
create table MART.DIM_PRODUCTS AS
SELECT * FROM RAW_PRODUCT;
 
 
CREATE TABLE MART.DIM_STORES
AS
SELECT * FROM RAW_STORES;
 
-- CREATE FACT TABLES
 
 
CREATE TABLE MART.FACT_SALES AS
SELECT
ORDER_ID,
CUSTOMER_ID,
PRODUCT_ID,
STORE_ID,
QTY,
PRICE AS SALES_AMOUNT,
ORDER_DATE
FROM RAW_ORDERS;
 
 
SELECT * FROM MART.FACT_SALES;
 
 
 
-- CREATE VIEW FOR PRECOMPUTED RESULT AS WELL AS APPLYING BUSINESS LOGICS
 
CREATE VIEW MART.SALES_VIEW
AS
SELECT 
C.CUSTOMER_NAME,
P.PRODUCT_NAME,
S.STORE_NAME,
F.SALES_AMOUNT,
F.ORDER_DATE
 
FROM MART.FACT_SALES F
JOIN MART.DIM_CUSTOMERS C
ON F.CUSTOMER_ID=C.CUSTOMER_ID
JOIN MART.DIM_PRODUCTS P
ON F.PRODUCT_ID=P.PRODUCT_ID
JOIN MART.DIM_STORES S
ON F.STORE_ID=S.STORE_ID;
 
 
SELECT * FROM MART.SALES_VIEW;
 
 
-- CREATE STREAM FOR TRACKING CHANGES INSERT UPDATE DELETE
 
CREATE STREAM ORDER_STREAM
ON TABLE RAW_ORDERS;
 
 
SELECT * FROM ORDER_STREAM;
 
 
-- CREATE TASK FOR AUTOMATIC ADATA LOADING
 
CREATE TASK LOAD_FACT_TASK
WAREHOUSE=COMPUTE_WH
SCHEDULE='1 minute'
AS
INSERT INTO MART.FACT_SALES
SELECT
ORDER_ID,
CUSTOMER_ID,
PRODUCT_ID,
STORE_ID,
QTY,
PRICE,
ORDER_DATE
FROM ORDER_STREAM;
 
 
ALTER TASK LOAD_FACT_TASK RESUME;
 
-- CREATE DYNAMIC TAVLES FOR FRESH DATA LOADING
 
CREATE DYNAMIC TABLE DT_SALES_SUMMARY
TARGET_LAG='5 minutes'
WAREHOUSE=COMPUTE_WH
AS
SELECT
PRODUCT_ID,
SUM(SALES_AMOUNT) TOTAL_SALES
FROM MART.FACT_SALES
GROUP BY PRODUCT_ID;
 
SELECT * FROM DT_SALES_SUMMARY;
 
 

 
CREATE MATERIALIZED VIEW MV_PRODUCT_SALES
AS
SELECT
PRODUCT_ID,
SUM(SALES_AMOUNT) TOTAL
FROM MART.FACT_SALES
GROUP BY PRODUCT_ID;
 
 
-- TIME TRAVEL
 
-- DELETE FROM MART.FACT_SALES;
 
--
 
SELECT *
FROM MART.FACT_SALES
AT(OFFSET=>-60*5);
 
 
-- ZERO CPOY CLONE
 
CREATE DATABASE RETAIL_DEV_cLONE
CLONE GCSProject;
 
 
-- CREATE MASKING POLICY
 
CREATE MASKING POLICY EMAIL_MASK
AS (VAL STRING)
RETURNS STRING ->
CASE
WHEN CURRENT_ROLE()='ACCOUNTADMIN'
THEN VAL
ELSE '*****'
END;
 
-- APPLY MASKING POLICY ON PARTICULAR FIELD
 
ALTER TABLE MART.DIM_CUSTOMERS
MODIFY COLUMN EMAIL
SET MASKING POLICY EMAIL_MASK;
 
--
 
-- APPLY QUERY OPTIMIZNTION BY ING CLUSERINH
 
ALTER TABLE MART.FACT_SALES
CLUSTER BY (ORDER_DATE);
 
SELECT * FROM MART.FACT_SALES;
 
SELECT *
FROM MART.FACT_SALES
WHERE ORDER_DATE='2026-01-01';
 
 
-- APPLY ROLE BASED ANALYSIS
 
CREATE ROLE ANALYST_ROLE;
 
GRANT USAGE ON DATABASE GCSProject TO ROLE ANALYST_ROLE;
 
GRANT SELECT ON ALL TABLES IN SCHEMA MART TO ROLE ANALYST_ROLE;
 
 
--------------------------------------------------
 
SELECT CURRENT_USER(); -- SHANKARB9663
 
SELECT CURRENT_ACCOUNT(); -- ID21747
 
-- Current user
SELECT CURRENT_USER();
 
-- Current role
SELECT CURRENT_ROLE();
 
-- List users
SHOW USERS;
 
-- List ACCOUNTADMIN members
SHOW GRANTS OF ROLE ACCOUNTADMIN;