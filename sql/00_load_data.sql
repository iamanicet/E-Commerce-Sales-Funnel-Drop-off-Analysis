/* =====================================================================
   00_load_data.sql
   Project : E-Commerce Sales Funnel Drop-off Analysis
   Engine  : MySQL Server 8.0 / MySQL Workbench
   Purpose : Rebuild the sales_analysis database from the 5 source CSVs.
   Safe to re-run: tables are dropped and recreated, so repeated loads
   can never create duplicate rows.

   Prerequisites:
     1. Copy all 5 CSV files into:
        C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/
        (the folder MySQL allows for LOAD DATA INFILE)
     2. File format (verified): comma-separated, all values wrapped in
        double quotes, one header row, '\n' line endings.
   ===================================================================== */

CREATE DATABASE IF NOT EXISTS sales_analysis;
USE sales_analysis;

/* ---------------------------------------------------------------------
   1. TABLE DEFINITIONS
   Each table holds one row per user, so user_id is the PRIMARY KEY.
   The key makes MySQL reject duplicate user_ids at load time, which
   prevents the join fan-out we hit earlier (home_page_table had
   130,606 rows for 90,400 distinct users).
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS payment_confirmation_table;
DROP TABLE IF EXISTS payment_page_table;
DROP TABLE IF EXISTS search_page_table;
DROP TABLE IF EXISTS home_page_table;
DROP TABLE IF EXISTS user_table;

CREATE TABLE user_table (
    user_id INT          NOT NULL,
    date    DATE         NOT NULL,   -- first visit date
    device  VARCHAR(50)  NOT NULL,   -- 'Desktop' | 'Mobile'
    sex     VARCHAR(50)  NOT NULL,   -- 'Male' | 'Female'
    PRIMARY KEY (user_id)
);

CREATE TABLE home_page_table (
    user_id INT          NOT NULL,
    page    VARCHAR(100) NOT NULL,   -- 'home_page'
    PRIMARY KEY (user_id)
);

CREATE TABLE search_page_table (
    user_id INT          NOT NULL,
    page    VARCHAR(100) NOT NULL,   -- 'search_page'
    PRIMARY KEY (user_id)
);

CREATE TABLE payment_page_table (
    user_id INT          NOT NULL,
    page    VARCHAR(100) NOT NULL,   -- 'payment_page'
    PRIMARY KEY (user_id)
);

CREATE TABLE payment_confirmation_table (
    user_id INT          NOT NULL,
    page    VARCHAR(100) NOT NULL,   -- 'payment_confirmation_page'
    PRIMARY KEY (user_id)
);

/* ---------------------------------------------------------------------
   2. BULK LOAD
   OPTIONALLY ENCLOSED BY '"'  -> strips the quotes around every value
   IGNORE 1 LINES              -> skips the header row
   LINES TERMINATED BY '\n'    -> matches the files' line endings
   --------------------------------------------------------------------- */

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/user_table.csv'
INTO TABLE user_table
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(user_id, date, device, sex);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/home_page_table.csv'
INTO TABLE home_page_table
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(user_id, page);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/search_page_table.csv'
INTO TABLE search_page_table
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(user_id, page);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/payment_page_table.csv'
INTO TABLE payment_page_table
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(user_id, page);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/payment_confirmation_table.csv'
INTO TABLE payment_confirmation_table
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(user_id, page);

/* ---------------------------------------------------------------------
   3. POST-LOAD VERIFICATION
   Every row_n must equal distinct_n, and match the expected counts.
   --------------------------------------------------------------------- */

SELECT 'user_table'           AS tbl, COUNT(*) AS row_n, COUNT(DISTINCT user_id) AS distinct_n, 90400 AS expected FROM user_table
UNION ALL
SELECT 'home_page_table',             COUNT(*), COUNT(DISTINCT user_id), 90400 FROM home_page_table
UNION ALL
SELECT 'search_page_table',           COUNT(*), COUNT(DISTINCT user_id), 45200 FROM search_page_table
UNION ALL
SELECT 'payment_page_table',          COUNT(*), COUNT(DISTINCT user_id), 6030  FROM payment_page_table
UNION ALL
SELECT 'payment_confirmation_table',  COUNT(*), COUNT(DISTINCT user_id), 452   FROM payment_confirmation_table;