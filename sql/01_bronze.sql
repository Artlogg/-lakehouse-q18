CREATE SCHEMA IF NOT EXISTS iceberg.bronze_q18;

CREATE TABLE iceberg.bronze_q18.customer
WITH (format = 'PARQUET', compression_codec = 'ZSTD')
AS SELECT custkey, name FROM tpch.sf1.customer;

CREATE TABLE iceberg.bronze_q18.orders
WITH (format = 'PARQUET', compression_codec = 'ZSTD')
AS SELECT orderkey, custkey, orderdate, totalprice FROM tpch.sf1.orders;

CREATE TABLE iceberg.bronze_q18.lineitem
WITH (format = 'PARQUET', compression_codec = 'ZSTD')
AS SELECT orderkey, linenumber, quantity FROM tpch.sf1.lineitem;

SELECT 'customer' AS table_name, count(*) AS row_count FROM iceberg.bronze_q18.customer
UNION ALL SELECT 'orders', count(*) FROM iceberg.bronze_q18.orders
UNION ALL SELECT 'lineitem', count(*) FROM iceberg.bronze_q18.lineitem;
