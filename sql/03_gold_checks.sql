CREATE SCHEMA IF NOT EXISTS iceberg.gold_q18;

CREATE TABLE iceberg.gold_q18.large_volume_customer
WITH (format = 'PARQUET', compression_codec = 'ZSTD')
AS SELECT name, custkey, orderkey, orderdate, totalprice, total_quantity
FROM iceberg.silver_q18.large_orders
ORDER BY totalprice DESC, orderdate
LIMIT 100;

SELECT * FROM iceberg.gold_q18.large_volume_customer
ORDER BY totalprice DESC, orderdate;

WITH expected AS (
SELECT c.name, c.custkey, o.orderkey, o.orderdate, o.totalprice,
       sum(l.quantity) AS total_quantity
FROM tpch.sf1.customer AS c
JOIN tpch.sf1.orders AS o ON c.custkey = o.custkey
JOIN tpch.sf1.lineitem AS l ON o.orderkey = l.orderkey
WHERE o.orderkey IN (
    SELECT orderkey FROM tpch.sf1.lineitem
    GROUP BY orderkey HAVING sum(quantity) > 300
)
GROUP BY c.name, c.custkey, o.orderkey, o.orderdate, o.totalprice
ORDER BY o.totalprice DESC, o.orderdate
LIMIT 100
),
missing AS (
    SELECT * FROM expected
    EXCEPT ALL
    SELECT name, custkey, orderkey, orderdate, totalprice, total_quantity
    FROM iceberg.gold_q18.large_volume_customer
),
unexpected AS (
    SELECT name, custkey, orderkey, orderdate, totalprice, total_quantity
    FROM iceberg.gold_q18.large_volume_customer
    EXCEPT ALL
    SELECT * FROM expected
)
SELECT 'missing_in_gold' AS check_name, count(*) AS differences FROM missing
UNION ALL
SELECT 'unexpected_in_gold', count(*) FROM unexpected;
