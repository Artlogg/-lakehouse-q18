-- Execute manually, statement by statement.
-- The ID below belongs to the recorded experiment.
-- On a fresh deployment, replace BOTH occurrences with the ID obtained
-- from schema_demo$snapshots BEFORE the UPDATE. Do not reuse it blindly.

UPDATE iceberg.silver_q18.schema_demo SET processing_note = 'test_change';

SELECT * FROM iceberg.silver_q18.schema_demo
FOR VERSION AS OF 2737917979539804092
ORDER BY orderkey;

ALTER TABLE iceberg.silver_q18.schema_demo
EXECUTE rollback_to_snapshot(2737917979539804092);

SELECT count(*) AS row_count, count(processing_note) AS filled_notes
FROM iceberg.silver_q18.schema_demo;
