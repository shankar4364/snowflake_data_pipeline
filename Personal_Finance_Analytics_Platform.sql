-- Personal Finance Analytics Platform

-- show warehouses;

-- alter warehouse compute_wh suspend;

----------------------------------------------------------------------------------

-- step 1:

-- create warehouse 

create or replace warehouse finsight_wh
warehouse_size='xsmall'
auto_suspend=30
auto_resume=true;

-- create database

create database finsight_db;


-- create schema

create schema raw;
create schema curated; 
create schema analytics;

-- create role 
use role securityadmin;

create role finsight_admin;

create role Data_Engineer;

create role finance_analyst;

create role report_user;



-- warehouse access

grant usage,operate on warehouse finsight_wh
to role data_engineer;

grant usage,operate on warehouse finsight_wh
to role finance_analyst;

grant usage ,operate on warehouse finsight_wh
to role report_user;

-- database access 

grant usage on database finsight_db
to role data_engineer;

grant usage on database finsight_db
to role finance_analyst;

grant usage on database finsight_db
to role report_user;


-- schema access

grant usage on schema raw 
to role data_engineer;

grant usage on schema curated 
to role data_engineer;

grant usage on schema curated 
to role finance_analyst;

grant usage on schema analytics 
to role report_user;


-- create bucket 
-- create folder - uploda files 
-- copy s3 url
-- create IAM ->role -> create account -> Aws Account -> External ID 00-> ->  gives permission 
--   ->amazons3fullaccess ->roleame ->create role -> click on role -> copy arn 


-- create storage integration 
use role accountadmin;

create or replace storage integration finsight_s3_int
type=external_stage
storage_provider=s3
enabled=true
storage_aws_role_arn='arn:aws:iam::291328562383:role/Sw_Role'
storage_allowed_locations=('s3://amzn-s3-finsight/finsight/');




-- desc storage integration 
-- copy aws_iam_user_arn- and external Id 
-- go to role -> edit  -> trsut relationship ->and paste here 

desc storage integration finsight_s3_int;

-- arn:aws:iam::836095228449:user/qog02000-s

-- YHB15893_SFCRole=5_zzge2aMEmDvnlchM3n6aJI+YowA=




-- create notification integration
-- go to sns ->create topics -> copy arn and paste here

create or replace notification integration finsight_notification_int
type=queue 
enabled=true
direction=inbound
notification_provider=aws_sns
aws_sns_topic_arn='arn:aws:sns:us-east-1:291328562383:finsight';



-- desc notification integration
-- copy aws_iam_user_arn
-- copy aws_external_id


desc notification integration finsight_notification_int;






-- create file format 

create or replace  file format csv_format
type='csv'
field_delimiter=','
skip_header=1
trim_space=true;




-- create externla stage

use schema raw;

create or replace stage aws_stg_Int
url='s3://amzn-s3-finsight/finsight/'
storage_integration=finsight_s3_int
file_format=csv_format;


list @aws_stg_Int;

-- create raw table 
create or replace table raw.transactions_raw
(
transaction_id number,
txn_date date,
description string,
amount number(10,2),
type string,
category string
);


-- create snowpipe 

create or replace pipe transaction_pipe
auto_ingest=true

as 
copy into raw.transactions_raw
from @aws_stg_Int;


--verify pipes

show pipes;
alter pipe transaction_pipe refresh;

-- check data is loaded or not

select count(*) from raw.transactions_raw;


-- create stream 

create or replace stream transaction_stream
on table raw.transactions_raw;

show streams;

select * from transaction_stream;


-- create table in curated layer

create table curated.transactions
(
transaction_id number,
txn_date date,
description string,
amount number(10,2),
type string,
category string,
month_name string,
year number

);


-- create task 

create or replace task process_transaction_task
warehouse=finsight_wh
schedule='1 minute'
-- WHEN SYSTEM$STREAM_HAS_DATA('TRANSACTION_STREAM')
as
insert into curated.transactions
select 
transaction_id,
txn_date,
description,
amount,
type,
case
when lower(description) like '%swiggy%' THEN 'Food'
when lower(description) like '%amazon%' THEN 'Shopping'
when lower(description) like '%uber%' THEN 'Travel'
when lower(description) like '%netflix%' THEN 'Entertainment'
when lower(description) like '%sip%' THEN 'Investment'
else category
end,
monthname(txn_date),
year(txn_date)
from transaction_stream;


select * from curated.transactions;


-- alter task process_transaction_task resume; 



-- create views

-- monthly expences 


CREATE VIEW VW_MONTHLY_EXPENSE
AS

SELECT

DATE_TRUNC('MONTH',TXN_DATE) MONTH,

SUM(ABS(AMOUNT)) EXPENSE

FROM CURATED.TRANSACTIONS

WHERE TYPE='DEBIT'

GROUP BY 1;

-- category expences 


CREATE VIEW VW_CATEGORY_EXPENSE
AS

SELECT

CATEGORY,

SUM(ABS(AMOUNT)) EXPENSE

FROM CURATED.TRANSACTIONS

WHERE TYPE='DEBIT'

GROUP BY CATEGORY;

-- income and expences 

CREATE VIEW VW_INCOME_EXPENSE
AS

SELECT

MONTHNAME(TXN_DATE) MONTH,

SUM(
CASE WHEN TYPE='CREDIT'
THEN AMOUNT
ELSE 0 END
) INCOME,

SUM(
CASE WHEN TYPE='DEBIT'
THEN ABS(AMOUNT)
ELSE 0 END
) EXPENSE

FROM CURATED.TRANSACTIONS

GROUP BY MONTH;




select * from VW_MONTHLY_EXPENSE;
select * from VW_CATEGORY_EXPENSE;
select * from VW_INCOME_EXPENSE;


-- top merchant

CREATE OR REPLACE VIEW ANALYTICS.VW_TOP_MERCHANTS

AS

SELECT

DESCRIPTION,

COUNT(*) TRANSACTION_COUNT,

SUM(ABS(AMOUNT)) TOTAL_SPEND

FROM CURATED.TRANSACTIONS

WHERE TYPE='DEBIT'

GROUP BY DESCRIPTION

ORDER BY TOTAL_SPEND DESC;


-- saving rate

CREATE OR REPLACE VIEW ANALYTICS.VW_SAVINGS

AS

SELECT

SUM(
CASE WHEN TYPE='CREDIT'
THEN AMOUNT
ELSE 0
END
) INCOME,

SUM(
CASE WHEN TYPE='DEBIT'
THEN ABS(AMOUNT)
ELSE 0
END
) EXPENSE,

SUM(
CASE WHEN TYPE='CREDIT'
THEN AMOUNT
ELSE 0
END
) -

SUM(
CASE WHEN TYPE='DEBIT'
THEN ABS(AMOUNT)
ELSE 0
END
)

AS SAVINGS

FROM CURATED.TRANSACTIONS;


-- check view data

select * from ANALYTICS.VW_SAVINGS;

select * from ANALYTICS.VW_TOP_MERCHANTS;

show views;


-- time travel

SELECT *
FROM CURATED.TRANSACTIONS
AT(OFFSET => -3600);

-- Zero Copy Clone

CREATE DATABASE FINSIGHT_DEV
CLONE FINSIGHT_DB;









select current_account();

SELECT * FROM finsight_db.public.VW_MONTHLY_EXPENSE ORDER BY MONTH

SELECT *
FROM FINSIGHT_DB.PUBLIC.VW_MONTHLY_EXPENSE
ORDER BY MONTH

SELECT *
FROM FINSIGHT_DB.PUBLIC.VW_TOP_MERCHANTS
LIMIT 10