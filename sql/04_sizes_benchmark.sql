WITH files AS (
    SELECT 'bronze.customer' AS table_name, record_count, file_size_in_bytes FROM iceberg.bronze_q18."customer$files" WHERE content = 0
    UNION ALL
    SELECT 'bronze.orders', record_count, file_size_in_bytes FROM iceberg.bronze_q18."orders$files" WHERE content = 0
    UNION ALL
    SELECT 'bronze.lineitem', record_count, file_size_in_bytes FROM iceberg.bronze_q18."lineitem$files" WHERE content = 0
    UNION ALL
    SELECT 'silver.large_orders', record_count, file_size_in_bytes FROM iceberg.silver_q18."large_orders$files" WHERE content = 0
    UNION ALL
    SELECT 'gold.large_volume_customer', record_count, file_size_in_bytes FROM iceberg.gold_q18."large_volume_customer$files" WHERE content = 0
)
SELECT table_name, sum(record_count) AS row_count,
       sum(file_size_in_bytes) AS size_bytes,
       round(sum(file_size_in_bytes)/1000000.0,3) AS size_mb
FROM files GROUP BY table_name ORDER BY table_name;

-- Run once for warm-up, then five measured executions.
EXPLAIN ANALYZE
SELECT c.name, c.custkey, o.orderkey, o.orderdate, o.totalprice,
       sum(l.quantity) AS total_quantity
FROM iceberg.bronze_q18.customer AS c
JOIN iceberg.bronze_q18.orders AS o ON c.custkey = o.custkey
JOIN iceberg.bronze_q18.lineitem AS l ON o.orderkey = l.orderkey
WHERE o.orderkey IN (
    SELECT orderkey FROM iceberg.bronze_q18.lineitem
    GROUP BY orderkey HAVING sum(quantity) > 300
)
GROUP BY c.name, c.custkey, o.orderkey, o.orderdate, o.totalprice
ORDER BY o.totalprice DESC, o.orderdate
LIMIT 100;
