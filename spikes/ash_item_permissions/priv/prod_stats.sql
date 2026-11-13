-- PROTOTYPE (graasp-web#318): aggregate shape of production memberships. Aggregates only, no personal data.
\pset footer off
\echo '== items'
SELECT count(*) AS items, count(*) FILTER (WHERE deleted_at IS NULL) AS live,
       max(nlevel(path)) AS max_depth, round(avg(nlevel(path)), 2) AS avg_depth,
       count(*) FILTER (WHERE nlevel(path) = 1 AND deleted_at IS NULL) AS live_roots
FROM item;
\echo '== live subtree size per root (items)'
SELECT percentile_disc(ARRAY[0.5, 0.9, 0.99]) WITHIN GROUP (ORDER BY n) AS p50_p90_p99, max(n)
FROM (SELECT subpath(path, 0, 1) r, count(*) n FROM item WHERE deleted_at IS NULL GROUP BY 1) s;
\echo '== memberships by depth and permission'
SELECT CASE WHEN nlevel(item_path) = 1 THEN 'root' ELSE 'below root' END AS level, permission, count(*)
FROM item_membership GROUP BY 1, 2 ORDER BY 1, 2;
\echo '== memberships per account'
SELECT count(*) AS accounts, percentile_disc(ARRAY[0.5, 0.9, 0.99, 0.999]) WITHIN GROUP (ORDER BY n) AS p50_p90_p99_p999, max(n)
FROM (SELECT account_id, count(*) n FROM item_membership GROUP BY 1) s;
\echo '== below-root memberships: is there also one on an ancestor for the same account?'
SELECT count(*) AS below_root,
  count(*) FILTER (WHERE anc IS NULL) AS no_ancestor_membership,
  count(*) FILTER (WHERE anc IS NOT NULL AND m_rank > anc) AS upgrade_of_ancestor,
  count(*) FILTER (WHERE anc IS NOT NULL AND m_rank <= anc) AS redundant_or_downgrade
FROM (
  SELECT m.permission AS m_rank,
    (SELECT max(p.permission) FROM item_membership p WHERE p.account_id = m.account_id AND p.item_path @> m.item_path AND p.item_path <> m.item_path) AS anc
  FROM item_membership m WHERE nlevel(m.item_path) > 1) s;
\echo '== visibilities'
SELECT type, CASE WHEN nlevel(item_path) = 1 THEN 'root' ELSE 'below root' END AS level, count(*) FROM item_visibility GROUP BY 1, 2 ORDER BY 1, 2;
\echo '== rows a materialized (item, account) table would hold (live items)'
SELECT count(*) FROM (SELECT DISTINCT m.account_id, i.id FROM item_membership m JOIN item i ON m.item_path @> i.path WHERE i.deleted_at IS NULL) s;
