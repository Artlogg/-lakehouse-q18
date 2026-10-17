-- Execute each CREATE once. Record Execution for each table.
CREATE SCHEMA IF NOT EXISTS iceberg.bench_q18_gzip;

EXPLAIN ANALYZE
CREATE TABLE iceberg.bench_q18_gzip.customer
WITH (format = 'PARQUET', compression_codec = 'GZIP')
AS SELECT custkey, name FROM iceberg.bronze_q18.customer;

EXPLAIN ANALYZE
CREATE TABLE iceberg.bench_q18_gzip.orders
WITH (format = 'PARQUET', compression_codec = 'GZIP')
AS SELECT orderkey, custkey, orderdate, totalprice FROM iceberg.bronze_q18.orders;

EXPLAIN ANALYZE
CREATE TABLE iceberg.bench_q18_gzip.lineitem
WITH (format = 'PARQUET', compression_codec = 'GZIP')
AS SELECT orderkey, linenumber, quantity FROM iceberg.bronze_q18.lineitem;
