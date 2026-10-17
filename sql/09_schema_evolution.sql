CREATE TABLE iceberg.silver_q18.schema_demo
WITH (format = 'PARQUET', compression_codec = 'ZSTD')
AS SELECT orderkey, total_quantity
FROM iceberg.silver_q18.large_orders
ORDER BY orderkey LIMIT 5;

ALTER TABLE iceberg.silver_q18.schema_demo ADD COLUMN analyst_note VARCHAR;
ALTER TABLE iceberg.silver_q18.schema_demo RENAME COLUMN analyst_note TO processing_note;

SHOW COLUMNS FROM iceberg.silver_q18.schema_demo;
SELECT * FROM iceberg.silver_q18.schema_demo ORDER BY orderkey;
SELECT snapshot_id, committed_at
FROM iceberg.silver_q18."schema_demo$snapshots"
ORDER BY committed_at DESC;
