SELECT 'bronze_q18.customer' AS table_name, count(*) AS row_count
FROM iceberg.bronze_q18.customer
UNION ALL SELECT 'bronze_q18.orders', count(*) FROM iceberg.bronze_q18.orders
UNION ALL SELECT 'bronze_q18.lineitem', count(*) FROM iceberg.bronze_q18.lineitem
UNION ALL SELECT 'silver_q18.large_orders', count(*) FROM iceberg.silver_q18.large_orders
UNION ALL SELECT 'gold_q18.large_volume_customer', count(*) FROM iceberg.gold_q18.large_volume_customer;
