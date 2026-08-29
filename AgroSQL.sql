--Agri sql code

-- show warehouses;

-- use warehouse compute_wh;

-- use database aws_db;


CREATE SCHEMA RAW;
CREATE SCHEMA STAGING;
CREATE SCHEMA CURATED;
CREATE SCHEMA ANALYTICS;


--alter warehouse compute_wh suspend;


--alter warehouse compute_wh resume;

-- create storage integration

create storage integration AWS_INT2
type=external_stage
enabled=true
storage_provider=s3
storage_allowed_locations=('s3://amzn-s3-agrocompany/Agri Data/')
storage_aws_role_arn='arn:aws:iam::291328562383:role/Sw_Agro';


desc storage integration AWS_INT2;


-- copy iam_user-arn
-- arn:aws:iam::802693430741:user/dnfy1000-s

-- aws-external-ID
-- DGB54712_SFCRole=4_w4m1aZ0+e5o36ltII4m1SbD2LNA=


-- create or replace file format csv_format
-- type=csv 
-- skip_header=1
-- field_optionally_enclosed_by= '"';

create or replace stage AWS_Stg_Agro
url='s3://amzn-s3-agrocompany/Agri Data/'
storage_integration=AWS_INT2
file_format=csv_format;


list @AWS_Stg_Agro;



-- Total credits used today (all warehouses)
SELECT
    CURRENT_DATE() AS usage_date,
    SUM(CREDITS_USED) AS total_credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= CURRENT_DATE()
  AND START_TIME < DATEADD(day, 1, CURRENT_DATE());


-- Credits used today by warehouse

SELECT
    WAREHOUSE_NAME,
    SUM(CREDITS_USED) AS credits_used
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE START_TIME >= CURRENT_DATE()
  AND START_TIME < DATEADD(day, 1, CURRENT_DATE())
GROUP BY WAREHOUSE_NAME
ORDER BY credits_used DESC;


-- after loading the data into staging then
-- create table as per csv data fromat field

---------------------------

-- use raw schema
 -- crop dataset

CREATE or replace TABLE RAW.CROP_DATA (
    crop_id INT,
    crop_name STRING,
    state STRING,
    district STRING,
    year INT,
    production_tonnes NUMBER,
    area_hectares NUMBER
);


copy into RAW.CROP_DATA
from @AWS_Stg_Agro/crop_data.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
on_error='continue';


delete from Raw.CROP_DATA;


select * from Raw.CROP_DATA limit 10;


-- farmer dataset
CREATE TABLE RAW.FARMER_DATA (
    farmer_id INT,
    name STRING,
    district STRING,
    land_area_acres NUMBER
);

copy into RAW.FARMER_DATA
from @AWS_Stg_Agro/farmer_data.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
on_error='continue';

select * from  RAW.FARMER_DATA;



-- rainfall

CREATE TABLE RAW.RAINFALL_DATA (
    record_id INT,
    district STRING,
    year INT,
    rainfall_mm NUMBER
);

copy into RAW.RAINFALL_DATA
from @AWS_Stg_Agro/rainfall_data.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
on_error='continue';

select * from RAW.RAINFALL_DATA;


-- soil

CREATE TABLE RAW.SOIL_DATA (
    soil_id INT,
    district STRING,
    soil_type STRING,
    ph_level NUMBER,
    nitrogen NUMBER,
    phosphorus NUMBER,
    potassium NUMBER
);


copy into RAW.SOIL_DATA
from @AWS_Stg_Agro/soil_data.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
on_error='continue';

select * from RAW.SOIL_DATA;


-- fertilizer

CREATE TABLE RAW.FERTILIZER_DATA (
    fertilizer_id INT,
    district STRING,
    fertilizer_type STRING,
    quantity_used_kg NUMBER
);


copy into RAW.FERTILIZER_DATA
from @AWS_Stg_Agro/fertilizer_data.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
on_error='continue';


select * from RAW.FERTILIZER_DATA;


------------------------------------------------------------------------------------------------

-- create snowpipe for each dataset
-- continuos loading


create or replace  pipe crop_pipe as
copy into raw.crop_data
from @AWS_Stg_Agro/crop_data.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
on_error='continue';


create or replace pipe farmer_pipe  as
copy into RAW.FARMER_DATA
from @AWS_Stg_Agro/farmer_data.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
on_error='continue';


-- 

create or replace pipe rainfall_pipe as
copy into RAW.Rainfall_DATA
from @AWS_Stg_Agro/Railfall_data.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
on_error='continue';


create or replace pipe soil_pipe as
copy into RAW.soil_DATA
from @AWS_Stg_Agro/soil_data.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
on_error='continue';


create or replace pipe fertilizer_pipe as
copy into RAW.FERTILIZER_DATA
from @AWS_Stg_Agro/fertilizer_data.csv
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)
on_error='continue';




---------------------------------------------------------------------------------------------

-- alter warehouse compute_wh suspend;

-- show warehouses;


-- create stream for trcaking the canhes which is insert update delete(cdc changes data capture)
-- it track the changes 
-- create stream of each TABLES

create or replace  stream Crop_Stream
on table raw.crop_data;


select * from CROP_STREAM;

create stream Farmer_stream
on table raw.farmer_data;

create stream rainfall_stream
on table raw.rainfall_data;

create stream soil_stream 
on table raw.soil_data;

create stream fertilizer_stream
on table raw.rainfall_data

-----------------------------------------------------------------
-- create task for 

CREATE TASK CROP_TASK
AS
INSERT INTO STAGING.CROP_DATA
SELECT * FROM CROP_STREAM;



CREATE TASK RAINFALL_TASK
AS
INSERT INTO STAGING.RAINFALL_DATA
SELECT * FROM RAINFALL_STREAM;

CREATE TASK RAINFALL_TASK
AS
INSERT INTO STAGING.RAINFALL_DATA
SELECT * FROM RAINFALL_STREAM;

CREATE TASK FERTILIZER_TASK
AS
INSERT INTO STAGING.FERTILIZER_DATA
SELECT * FROM FERTILIZER_STREAM;


CREATE or replace  TASK FARMER_TASK
AS
INSERT INTO STAGING.FARMER_DATA
SELECT * FROM raw.farmer_data;


------------------------------------------------------------------------


-- createsing curated table for summary 


CREATE TABLE STAGING.CROP_DATA (
    crop_id INT,
    crop_name STRING,
    state STRING,
    district STRING,
    year INT,
    production_tonnes NUMBER,
    area_hectares NUMBER
);


CREATE TABLE STAGING.FARMER_DATA (
    farmer_id INT,
    name STRING,
    district STRING,
    land_area_acres NUMBER
);

CREATE TABLE STAGING.SOIL_DATA (
    soil_id INT,
    district STRING,
    soil_type STRING,
    ph_level NUMBER,
    nitrogen NUMBER,
    phosphorus NUMBER,
    potassium NUMBER
);

CREATE TABLE STAGING.FERTILIZER_DATA (
    fertilizer_id INT,
    district STRING,
    fertilizer_type STRING,
    quantity_used_kg NUMBER
);


CREATE TABLE STAGING.RAINFALL_DATA (
    record_id INT,
    district STRING,
    year INT,
    rainfall_mm NUMBER
);


-- district wise agricultue summary

select * from staging.farmer_data;
select * from staging.fertilizer_data;

CREATE TABLE CURATED.DISTRICT_SUMMARY AS

SELECT
    c.district,
    c.crop_name,
    SUM(c.production_tonnes) total_production,
    AVG(r.rainfall_mm) avg_rainfall,
    AVG(s.ph_level) avg_ph,
    SUM(f.quantity_used_kg) fertilizer_used,
    COUNT(DISTINCT fm.farmer_id) total_farmers
FROM STAGING.CROP_DATA c
LEFT JOIN STAGING.RAINFALL_DATA r
    ON c.district=r.district
AND c.year=r.year
LEFT JOIN STAGING.SOIL_DATA s
    ON c.district=s.district
LEFT JOIN STAGING.FERTILIZER_DATA f
    ON c.district=f.district
LEFT JOIN STAGING.FARMER_DATA fm
    ON c.district=fm.district
GROUP BY
c.district,
c.crop_name;


select * from CURATED.DISTRICT_SUMMARY;

---------------------------------------------------------

SELECT COUNT(*) FROM RAW.CROP_DATA;
SELECT COUNT(*) FROM RAW.RAINFALL_DATA;
SELECT COUNT(*) FROM RAW.SOIL_DATA;
SELECT COUNT(*) FROM RAW.FERTILIZER_DATA;


SELECT COUNT(*) FROM STAGING.CROP_DATA;
SELECT COUNT(*) FROM STAGING.RAINFALL_DATA;
SELECT COUNT(*) FROM STAGING.SOIL_DATA;
SELECT COUNT(*) FROM STAGING.FERTILIZER_DATA;

SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY());



SELECT COUNT(*) FROM RAW.CROP_DATA;
SELECT COUNT(*) FROM RAW.RAINFALL_DATA;
SELECT COUNT(*) FROM RAW.SOIL_DATA;
SELECT COUNT(*) FROM RAW.FERTILIZER_DATA;
SELECT COUNT(*) FROM RAW.FARMER_DATA;




CREATE OR REPLACE TABLE STAGING.CROP_DATA
LIKE RAW.CROP_DATA;

CREATE OR REPLACE TABLE STAGING.RAINFALL_DATA
LIKE RAW.RAINFALL_DATA;

CREATE OR REPLACE TABLE STAGING.SOIL_DATA
LIKE RAW.SOIL_DATA;

CREATE OR REPLACE TABLE STAGING.FERTILIZER_DATA
LIKE RAW.FERTILIZER_DATA;

CREATE OR REPLACE TABLE STAGING.FARMER_DATA
LIKE RAW.FARMER_DATA;




-----------------------------------


INSERT INTO STAGING.CROP_DATA
SELECT * FROM RAW.CROP_DATA;

INSERT INTO STAGING.RAINFALL_DATA
SELECT * FROM RAW.RAINFALL_DATA;

INSERT INTO STAGING.SOIL_DATA
SELECT * FROM RAW.SOIL_DATA;

INSERT INTO STAGING.FERTILIZER_DATA
SELECT * FROM RAW.FERTILIZER_DATA;

INSERT INTO STAGING.FARMER_DATA
SELECT * FROM RAW.FARMER_DATA;



SELECT COUNT(*) FROM STAGING.CROP_DATA;
SELECT COUNT(*) FROM STAGING.RAINFALL_DATA;
SELECT COUNT(*) FROM STAGING.SOIL_DATA;
SELECT COUNT(*) FROM STAGING.FERTILIZER_DATA;
SELECT COUNT(*) FROM STAGING.FARMER_DATA;


-- creae stream

CREATE OR REPLACE STREAM CROP_STREAM
ON TABLE RAW.CROP_DATA;

CREATE OR REPLACE STREAM RAINFALL_STREAM
ON TABLE RAW.RAINFALL_DATA;

CREATE OR REPLACE STREAM SOIL_STREAM
ON TABLE RAW.SOIL_DATA;

CREATE OR REPLACE STREAM FERTILIZER_STREAM
ON TABLE RAW.FERTILIZER_DATA;

CREATE OR REPLACE STREAM FARMER_STREAM
ON TABLE RAW.FARMER_DATA;


--------------------------------------------

-- create tasks

CREATE OR REPLACE TASK CROP_TASK
WAREHOUSE=COMPUTE_WH
SCHEDULE='5 MINUTE'
AS
INSERT INTO STAGING.CROP_DATA
SELECT * FROM CROP_STREAM;


CREATE OR REPLACE TASK RAINFALL_TASK
WAREHOUSE=COMPUTE_WH
SCHEDULE='5 MINUTE'
AS
INSERT INTO STAGING.RAINFALL_DATA
SELECT * FROM RAINFALL_STREAM;


CREATE OR REPLACE TASK SOIL_TASK
WAREHOUSE=COMPUTE_WH
SCHEDULE='5 MINUTE'
AS
INSERT INTO STAGING.SOIL_DATA
SELECT * FROM SOIL_STREAM;

CREATE OR REPLACE TASK FERTILIZER_TASK
WAREHOUSE=COMPUTE_WH
SCHEDULE='5 MINUTE'
AS
INSERT INTO STAGING.FERTILIZER_DATA
SELECT * FROM FERTILIZER_STREAM;


CREATE OR REPLACE TASK FARMER_TASK
WAREHOUSE=COMPUTE_WH
SCHEDULE='5 MINUTE'
AS
INSERT INTO STAGING.FARMER_DATA
SELECT * FROM FARMER_STREAM;


-- resume all the tasks

ALTER TASK CROP_TASK RESUME;
ALTER TASK RAINFALL_TASK RESUME;
ALTER TASK SOIL_TASK RESUME;
ALTER TASK FERTILIZER_TASK RESUME;
ALTER TASK FARMER_TASK RESUME;


-----------------------------------------------------

-- create curated TABLES FOR SUMMARY

CREATE OR REPLACE TABLE CURATED.DISTRICT_SUMMARY AS

SELECT

c.district,
c.crop_name,

SUM(c.production_tonnes) AS total_production,

AVG(r.rainfall_mm) AS avg_rainfall,

AVG(s.ph_level) AS avg_ph,

SUM(f.quantity_used_kg) AS fertilizer_used,

COUNT(DISTINCT fm.farmer_id) AS total_farmers

FROM STAGING.CROP_DATA c

LEFT JOIN STAGING.RAINFALL_DATA r
ON UPPER(c.district)=UPPER(r.district)
AND c.year=r.year

LEFT JOIN STAGING.SOIL_DATA s
ON UPPER(c.district)=UPPER(s.district)

LEFT JOIN STAGING.FERTILIZER_DATA f
ON UPPER(c.district)=UPPER(f.district)

LEFT JOIN STAGING.FARMER_DATA fm
ON UPPER(c.district)=UPPER(fm.district)

GROUP BY
c.district,
c.crop_name;


select * from CURATED.DISTRICT_SUMMARY limit 50;

select count(*) as counts from CURATED.DISTRICT_SUMMARY;


------------------------------------------------------------------

create or replace dynamic table curated.agri_kpi
target_lag='5 minute'
warehouse=compute_wh
as
select 

district,
sum(total_production) as total_production,
avg(avg_rainfall) as avg_rainfall,
sum(total_farmers) as total_farmers,

from CURATED.DISTRICT_SUMMARY
group by district;


-- select * from curated.agri_kpi;

-- show streams;

-- SHOW TASKS;


-- SHOW PIPES;

-- show warehouses;

-- select current_user();

-- select current_account();



-- SELECT COUNT(*) FROM CURATED.DISTRICT_SUMMARY;

-- SELECT COUNT(*) FROM CURATED.AGRI_KPI;


show schemas;

SHOW TABLES IN SCHEMA CURATED;


--------------------------------------------

SELECT
    WAREHOUSE_NAME,
    SUM(CREDITS_USED) AS CREDITS_USED_TODAY
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'COMPUTE_WH'
  AND START_TIME >= CURRENT_DATE()
GROUP BY WAREHOUSE_NAME;

-- DAY BY DAY


SELECT
    DATE(START_TIME) AS USAGE_DATE,
    WAREHOUSE_NAME,
    SUM(CREDITS_USED) AS CREDITS_USED
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'COMPUTE_WH'
GROUP BY DATE(START_TIME), WAREHOUSE_NAME
ORDER BY USAGE_DATE DESC;


SELECT
    WAREHOUSE_NAME,
    SUM(CREDITS_USED) AS TOTAL_CREDITS_USED
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'COMPUTE_WH'
GROUP BY WAREHOUSE_NAME;







----------------------------------------------------------------
-- real time work with stream and task

--cdc changes capture data
-- insert uodate delete

-- data inserted 16.13 pm
INSERT INTO RAW.CROP_DATA
VALUES
(
1001,
'SOYABEAN',
'MAHARASHTRA',
'LATUR',
2025,
5000,
500
);



-- after inserting new records 
-- check stream

select * from crop_stream;

-- show tasks;
-- alter task crop_task resume;

select * from staging.CROP_TASK;


SELECT *
FROM STAGING.CROP_DATA order by crop_id desc;

select count(*) from STAGING.CROP_DATA;

----------------------------------------------------
but after 5 minute checking not data arriving

SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        TASK_NAME => 'CROP_TASK'
    )
)
ORDER BY SCHEDULED_TIME DESC;



SELECT
    NAME,
    STATE,
    SCHEDULED_TIME,
    QUERY_ID,
    ERROR_MESSAGE
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        TASK_NAME=>'CROP_TASK'
    )
)
ORDER BY SCHEDULED_TIME DESC;



------------------------------------------


RAW TABLE
    ↓
STREAM
    ↓
TASK
    ↓
STAGING TABLE

-- After the Stream captures new records from the RAW table, the Task automatically executes based on its schedule. In my project, tasks run every 5 minutes and load only the incremental records from the Stream into the STAGING layer. Once processed, the Stream becomes empty until new changes arrive.


 
-----------------------------------------------------------

step 1

show warehouses;

alter warehouse compute_wh resume;

-- data inserted 16.13 pm
INSERT INTO RAW.CROP_DATA
VALUES
(
1001,
'SOYABEAN',
'MAHARASHTRA',
'LATUR',
2025,
5000,
500
);

delete from raw.crop_data where crop_id=1001;


select * from crop_stream;


SELECT *,
       METADATA$ACTION,
       METADATA$ISUPDATE
FROM crop_stream;

show tasks;


-- select count(*) from staging.crop_data;


-- CREATE OR REPLACE TASK CROP_TASK
-- WAREHOUSE = COMPUTE_WH
-- SCHEDULE = '1 MINUTE'
-- WHEN SYSTEM$STREAM_HAS_DATA('CROP_STREAM')
-- AS
-- INSERT INTO STAGING.CROP_DATA
-- SELECT *
-- FROM CROP_STREAM;


alter warehouse compute_wh suspend;

show warehouses;
