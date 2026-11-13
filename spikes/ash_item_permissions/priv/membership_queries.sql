-- PROTOTYPE (graasp-web#318): query cost per membership model, heavy account bulk9 (2050 memberships)
SELECT id AS a FROM account WHERE name = 'bulk9' \gset
SELECT id AS item_id, path AS item_path FROM item WHERE name = 'r100c3g2' \gset
SELECT path AS parent_path FROM item WHERE name = 'r100c3' \gset
\set ECHO none
\timing on
\echo '--- Q1 highest permission on one item'
\echo 'inherited:'
SELECT max(CASE permission WHEN 'read' THEN 1 WHEN 'write' THEN 2 ELSE 3 END) FROM item_membership WHERE account_id = :'a' AND item_path @> :'item_path';
\echo 'materialized:'
SELECT rank FROM item_access_prototype WHERE account_id = :'a' AND item_id = :'item_id';
\echo '--- Q2 children of a folder with the actor permission'
\echo 'inherited:'
SELECT count(*), max(r) FROM (SELECT i.id, (SELECT max(CASE permission WHEN 'read' THEN 1 WHEN 'write' THEN 2 ELSE 3 END) FROM item_membership m WHERE m.account_id = :'a' AND m.item_path @> i.path) r
  FROM item i WHERE i.path <@ :'parent_path' AND nlevel(i.path) = nlevel(:'parent_path'::ltree) + 1) s;
\echo 'materialized:'
SELECT count(*), max(a.rank) FROM item i LEFT JOIN item_access_prototype a ON a.item_id = i.id AND a.account_id = :'a'
  WHERE i.path <@ :'parent_path' AND nlevel(i.path) = nlevel(:'parent_path'::ltree) + 1;
\echo '--- Q3 home list: top-most items the account has a membership on'
\echo 'core (row_number + correlated first-ancestor subquery):'
WITH iom AS (SELECT i.*, row_number() OVER (ORDER BY i.path) rnb FROM item i JOIN item_membership m ON m.item_path = i.path AND m.account_id = :'a')
SELECT count(*) FROM iom WHERE rnb <= (SELECT j.rnb FROM iom j WHERE j.path @> iom.path ORDER BY j.rnb LIMIT 1);
\echo 'inherited, NOT EXISTS rewrite:'
SELECT count(*) FROM item_membership m WHERE m.account_id = :'a'
  AND NOT EXISTS (SELECT 1 FROM item_membership p WHERE p.account_id = m.account_id AND p.item_path @> m.item_path AND p.item_path <> m.item_path);
\echo '--- Q4 every item the account can write'
\echo 'inherited, narrowed to membership subtrees:'
SELECT count(*) FROM item i WHERE i.path <@ ANY(ARRAY(SELECT item_path FROM item_membership WHERE account_id = :'a' AND permission IN ('write', 'admin')));
\echo 'materialized:'
SELECT count(*) FROM item_access_prototype WHERE account_id = :'a' AND rank >= 2;
\echo '--- write cost: share root r42 (61 items) with a new account'
\echo 'inherited (1 row):'
BEGIN; INSERT INTO item_membership (permission, item_path, account_id) VALUES ('read', 'r42', :'a'); ROLLBACK;
\echo 'materialized (1 + 61 rows):'
BEGIN; INSERT INTO item_access_prototype SELECT :'a', i.id, 1, 'r42' FROM item i WHERE i.path <@ 'r42' ON CONFLICT DO NOTHING; ROLLBACK;
