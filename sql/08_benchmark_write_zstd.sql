-- Execute statements one by one. Record Execution before each DROP.
CREATE SCHEMA IF NOT EXISTS iceberg.bench_q18_write;

EXPLAIN ANALYZE
CREATE TABLE iceberg.bench_q18_write.customer
WITH (format = 'PARQUET', compression_codec = 'ZSTD')
AS SELECT custkey, name FROM iceberg.bronze_q18.customer;

DROP TABLE iceberg.bench_q18_write.customer;

EXPLAIN ANALYZE
CREATE TABLE iceberg.bench_q18_write.orders
WITH (format = 'PARQUET', compression_codec = 'ZSTD')
AS SELECT orderkey, custkey, orderdate, totalprice FROM iceberg.bronze_q18.orders;

DROP TABLE iceberg.bench_q18_write.orders;

EXPLAIN ANALYZE
CREATE TABLE iceberg.bench_q18_write.lineitem
WITH (format = 'PARQUET', compression_codec = 'ZSTD')
AS SELECT orderkey, linenumber, quantity FROM iceberg.bronze_q18.lineitem;

DROP TABLE iceberg.bench_q18_write.lineitem;
