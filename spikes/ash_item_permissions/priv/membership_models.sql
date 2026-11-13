-- PROTOTYPE (graasp-web#318): inherited memberships vs materialized vs root-only. Wipe me.
\timing on
-- a heavy account (teacher-like): read on 1000 child folders, write on 1000 others, admin on 50 roots
WITH a AS (SELECT id FROM account WHERE name = 'bulk9')
INSERT INTO item_membership (permission, item_path, account_id)
SELECT (CASE WHEN r % 2 = 0 THEN 'read' ELSE 'write' END)::permission_enum, ('r' || r || '.c3')::ltree, (SELECT id FROM a)
FROM generate_series(100, 2099) r ON CONFLICT DO NOTHING;
WITH a AS (SELECT id FROM account WHERE name = 'bulk9')
INSERT INTO item_membership (permission, item_path, account_id)
SELECT 'admin', ('r' || r)::ltree, (SELECT id FROM a) FROM generate_series(5000, 5049) r ON CONFLICT DO NOTHING;
ANALYZE item_membership;

\echo '== (B) materialize: one row per (item, account) with the highest permission and where it was granted'
DROP TABLE IF EXISTS item_access_prototype;
CREATE TABLE item_access_prototype (
  account_id uuid NOT NULL,
  item_id uuid NOT NULL,
  rank smallint NOT NULL,
  granted_path ltree NOT NULL,
  PRIMARY KEY (account_id, item_id)
);
INSERT INTO item_access_prototype
SELECT DISTINCT ON (m.account_id, i.id) m.account_id, i.id,
  CASE m.permission WHEN 'read' THEN 1 WHEN 'write' THEN 2 ELSE 3 END, m.item_path
FROM item_membership m JOIN item i ON m.item_path @> i.path
ORDER BY m.account_id, i.id, CASE m.permission WHEN 'read' THEN 1 WHEN 'write' THEN 2 ELSE 3 END DESC;
CREATE INDEX ON item_access_prototype (item_id);
ANALYZE item_access_prototype;
SELECT count(*) AS materialized_rows, pg_size_pretty(pg_total_relation_size('item_access_prototype')) AS size,
  (SELECT count(*) FROM item_membership) AS membership_rows,
  pg_size_pretty(pg_total_relation_size('item_membership')) AS membership_size FROM item_access_prototype;

\echo '== (A) root-only: share of memberships not on a root (bulk data)'
SELECT count(*) FILTER (WHERE nlevel(item_path) > 1) AS non_root, count(*) AS total FROM item_membership;
