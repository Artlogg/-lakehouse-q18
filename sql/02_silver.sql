CREATE SCHEMA IF NOT EXISTS iceberg.silver_q18;

CREATE TABLE iceberg.silver_q18.large_orders
WITH (format = 'PARQUET', compression_codec = 'ZSTD')
AS
WITH order_quantities AS (
    SELECT orderkey, sum(quantity) AS total_quantity
    FROM iceberg.bronze_q18.lineitem
    GROUP BY orderkey
    HAVING sum(quantity) > 300
)
SELECT c.name, c.custkey, o.orderkey, o.orderdate,
       o.totalprice, q.total_quantity
FROM order_quantities AS q
JOIN iceberg.bronze_q18.orders AS o ON q.orderkey = o.orderkey
JOIN iceberg.bronze_q18.customer AS c ON o.custkey = c.custkey;

SELECT count(*) AS silver_rows,
       count(DISTINCT orderkey) AS unique_orders,
       count_if(total_quantity IS NULL OR total_quantity <= 300
                OR custkey IS NULL OR name IS NULL
                OR orderdate IS NULL OR totalprice IS NULL) AS invalid_rows
FROM iceberg.silver_q18.large_orders;
