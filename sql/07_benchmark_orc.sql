-- Execute each CREATE once. Record Execution for each table.
CREATE SCHEMA IF NOT EXISTS iceberg.bench_q18_orc;

EXPLAIN ANALYZE
CREATE TABLE iceberg.bench_q18_orc.customer
WITH (format = 'ORC', compression_codec = 'ZSTD')
AS SELECT custkey, name FROM iceberg.bronze_q18.customer;

EXPLAIN ANALYZE
CREATE TABLE iceberg.bench_q18_orc.orders
WITH (format = 'ORC', compression_codec = 'ZSTD')
AS SELECT orderkey, custkey, orderdate, totalprice FROM iceberg.bronze_q18.orders;

EXPLAIN ANALYZE
CREATE TABLE iceberg.bench_q18_orc.lineitem
WITH (format = 'ORC', compression_codec = 'ZSTD')
AS SELECT orderkey, linenumber, quantity FROM iceberg.bronze_q18.lineitem;

SELECT sum(file_size_in_bytes) AS size_bytes,
       round(sum(file_size_in_bytes) / 1000000.0, 3) AS size_mb
FROM (
    SELECT file_size_in_bytes FROM iceberg.bench_q18_orc."customer$files" WHERE content = 0
    UNION ALL
    SELECT file_size_in_bytes FROM iceberg.bench_q18_orc."orders$files" WHERE content = 0
    UNION ALL
    SELECT file_size_in_bytes FROM iceberg.bench_q18_orc."lineitem$files" WHERE content = 0
) AS files;

-- Run the following SELECT once for warm-up, then five times for timing.
EXPLAIN ANALYZE
SELECT c.name, c.custkey, o.orderkey, o.orderdate, o.totalprice,
       sum(l.quantity) AS total_quantity
FROM iceberg.bench_q18_orc.customer AS c
JOIN iceberg.bench_q18_orc.orders AS o ON c.custkey = o.custkey
JOIN iceberg.bench_q18_orc.lineitem AS l ON o.orderkey = l.orderkey
WHERE o.orderkey IN (
    SELECT orderkey FROM iceberg.bench_q18_orc.lineitem
    GROUP BY orderkey HAVING sum(quantity) > 300
)
GROUP BY c.name, c.custkey, o.orderkey, o.orderdate, o.totalprice
ORDER BY o.totalprice DESC, o.orderdate
LIMIT 100;
