SELECT sum(file_size_in_bytes) AS size_bytes,
       round(sum(file_size_in_bytes) / 1000000.0, 3) AS size_mb
FROM (
    SELECT file_size_in_bytes FROM iceberg.bench_q18_gzip."customer$files" WHERE content = 0
    UNION ALL
    SELECT file_size_in_bytes FROM iceberg.bench_q18_gzip."orders$files" WHERE content = 0
    UNION ALL
    SELECT file_size_in_bytes FROM iceberg.bench_q18_gzip."lineitem$files" WHERE content = 0
) AS files;

-- One warm-up, then five measured executions.
EXPLAIN ANALYZE
SELECT c.name, c.custkey, o.orderkey, o.orderdate, o.totalprice,
       sum(l.quantity) AS total_quantity
FROM iceberg.bench_q18_gzip.customer AS c
JOIN iceberg.bench_q18_gzip.orders AS o ON c.custkey = o.custkey
JOIN iceberg.bench_q18_gzip.lineitem AS l ON o.orderkey = l.orderkey
WHERE o.orderkey IN (
    SELECT orderkey FROM iceberg.bench_q18_gzip.lineitem
    GROUP BY orderkey HAVING sum(quantity) > 300
)
GROUP BY c.name, c.custkey, o.orderkey, o.orderdate, o.totalprice
ORDER BY o.totalprice DESC, o.orderdate
LIMIT 100;
