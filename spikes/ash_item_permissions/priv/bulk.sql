-- PROTOTYPE bulk data for EXPLAIN (graasp-web#318): ~610k items, ~150k memberships.
-- Run after seed.sql. Wipe me.
INSERT INTO account (id, name, type, is_validated, email, extra, enable_save_actions)
SELECT uuid_generate_v4(), 'bulk' || g, 'individual', true, 'bulk' || g || '@spike.test', '{}', true
FROM generate_series(1, 20000) g;

INSERT INTO item (id, name, type, path)
SELECT uuid_generate_v4(), 'r' || r, 'folder', ('r' || r)::ltree FROM generate_series(1, 10000) r;
INSERT INTO item (id, name, type, path, "order")
SELECT uuid_generate_v4(), 'r' || r || 'c' || c, 'folder', ('r' || r || '.c' || c)::ltree, c
FROM generate_series(1, 10000) r, generate_series(1, 10) c;
INSERT INTO item (id, name, type, path, "order")
SELECT uuid_generate_v4(), 'r' || r || 'c' || c || 'g' || g, 'document', ('r' || r || '.c' || c || '.g' || g)::ltree, g
FROM generate_series(1, 10000) r, generate_series(1, 10) c, generate_series(1, 5) g;

-- every root: one admin; ~half the children: an extra member with random permission
WITH accts AS (SELECT id, row_number() OVER () AS n FROM account WHERE name LIKE 'bulk%')
INSERT INTO item_membership (permission, item_path, account_id)
SELECT 'admin'::permission_enum, ('r' || r)::ltree, (SELECT id FROM accts WHERE n = 1 + (r * 7) % 20000)
FROM generate_series(1, 10000) r;
WITH accts AS (SELECT id, row_number() OVER () AS n FROM account WHERE name LIKE 'bulk%')
INSERT INTO item_membership (permission, item_path, account_id)
SELECT (ARRAY['read','write','admin'])[1 + (r + c) % 3]::permission_enum, ('r' || r || '.c' || c)::ltree,
       (SELECT id FROM accts WHERE n = 1 + (r * 13 + c) % 20000)
FROM generate_series(1, 10000) r, generate_series(1, 10) c WHERE (r + c) % 2 = 0
ON CONFLICT DO NOTHING;

INSERT INTO item_visibility (type, item_path)
SELECT 'hidden', ('r' || r || '.c' || c)::ltree FROM generate_series(1, 10000) r, generate_series(1, 10) c WHERE (r * c) % 20 = 0;
INSERT INTO item_visibility (type, item_path)
SELECT 'public', ('r' || r)::ltree FROM generate_series(1, 10000) r WHERE r % 50 = 0;

ANALYZE;
