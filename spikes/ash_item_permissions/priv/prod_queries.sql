-- PROTOTYPE (graasp-web#318): timings on the production snapshot, heaviest account. Prints counts and times only.
SELECT account_id AS a FROM item_membership GROUP BY 1 ORDER BY count(*) DESC LIMIT 1 \gset
SELECT i.path AS deep_path FROM item_membership m JOIN item i ON i.path <@ m.item_path WHERE m.account_id = :'a' AND i.deleted_at IS NULL ORDER BY nlevel(i.path) DESC LIMIT 1 \gset
\pset footer off
\pset tuples_only on
\timing on
\echo '-- point: highest permission on the deepest accessible item'
SELECT max(permission) IS NOT NULL FROM item_membership WHERE account_id = :'a' AND item_path @> :'deep_path';
\echo '-- home, core query'
WITH iom AS (SELECT i.*, row_number() OVER (ORDER BY i.path) rnb FROM item i JOIN item_membership m ON m.item_path = i.path AND m.account_id = :'a' WHERE i.deleted_at IS NULL)
SELECT count(*) FROM iom WHERE rnb <= (SELECT j.rnb FROM iom j WHERE j.path @> iom.path ORDER BY j.rnb LIMIT 1);
\echo '-- home, NOT EXISTS rewrite'
SELECT count(*) FROM item_membership m JOIN item i ON i.path = m.item_path AND i.deleted_at IS NULL WHERE m.account_id = :'a'
  AND NOT EXISTS (SELECT 1 FROM item_membership p WHERE p.account_id = m.account_id AND p.item_path @> m.item_path AND p.item_path <> m.item_path);
\echo '-- home + permission per row (what the Ash read policy adds)'
SELECT count(*) FROM (SELECT (SELECT max(p.permission) FROM item_membership p WHERE p.account_id = :'a' AND p.item_path @> i.path) perm
  FROM item_membership m JOIN item i ON i.path = m.item_path AND i.deleted_at IS NULL WHERE m.account_id = :'a'
  AND NOT EXISTS (SELECT 1 FROM item_membership p WHERE p.account_id = m.account_id AND p.item_path @> m.item_path AND p.item_path <> m.item_path)) s;
