-- PROTOTYPE seed for graasp_ash_spike_prototype (graasp-web#318). Wipe me.
-- Readable ltree labels stand in for core's uuid-based labels.
TRUNCATE item_visibility, item_membership, item, account CASCADE;

INSERT INTO account (id, name, type, is_validated, email)
SELECT id, name, type::account_type_enum, is_validated, name || '@spike.test' FROM (VALUES
  (uuid_generate_v4(), 'alice',  'individual', true),   -- admin on A
  (uuid_generate_v4(), 'bob',    'individual', true),   -- read on A.a1, write on A.a3
  (uuid_generate_v4(), 'carol',  'individual', true),   -- read on A, write on A.a2.a2y
  (uuid_generate_v4(), 'dave',   'individual', true),   -- read on A.a3.a3x; admin on B + read on B.b1 (downgrade, breaks the invariant)
  (uuid_generate_v4(), 'erin',   'individual', true),   -- no membership at all
  (uuid_generate_v4(), 'frank',  'individual', false),  -- NOT validated, read on A.a1
  (uuid_generate_v4(), 'gwen',   'guest',      true)    -- guest, read on A.a2
) AS a(id, name, type, is_validated);

INSERT INTO item (id, name, type, path, "order", deleted_at) VALUES
  (uuid_generate_v4(), 'A',     'folder',   'A',          null, null),
  (uuid_generate_v4(), 'a1',    'folder',   'A.a1',       1,    null),
  (uuid_generate_v4(), 'a1x',   'document', 'A.a1.a1x',   1,    null),
  (uuid_generate_v4(), 'a1y',   'document', 'A.a1.a1y',   2,    null),
  (uuid_generate_v4(), 'a2',    'folder',   'A.a2',       2,    null),
  (uuid_generate_v4(), 'a2x',   'document', 'A.a2.a2x',   1,    null),
  (uuid_generate_v4(), 'a2y',   'folder',   'A.a2.a2y',   2,    null),
  (uuid_generate_v4(), 'a2y1',  'document', 'A.a2.a2y.a2y1', 1, null),
  (uuid_generate_v4(), 'a3',    'folder',   'A.a3',       3,    null),
  (uuid_generate_v4(), 'a3x',   'document', 'A.a3.a3x',   1,    null),
  (uuid_generate_v4(), 'a4',    'document', 'A.a4',       4,    now()),  -- soft-deleted
  (uuid_generate_v4(), 'B',     'folder',   'B',          null, null),
  (uuid_generate_v4(), 'b1',    'folder',   'B.b1',       1,    null),
  (uuid_generate_v4(), 'b1x',   'document', 'B.b1.b1x',   1,    null),
  (uuid_generate_v4(), 'b2',    'document', 'B.b2',       2,    null),
  (uuid_generate_v4(), 'C',     'folder',   'C',          null, null);   -- nobody

INSERT INTO item_membership (permission, item_path, account_id)
SELECT m.permission::permission_enum, m.path::ltree, a.id FROM (VALUES
  ('alice', 'admin', 'A'),
  ('bob',   'read',  'A.a1'),
  ('bob',   'write', 'A.a3'),
  ('carol', 'read',  'A'),
  ('carol', 'write', 'A.a2.a2y'),
  ('dave',  'read',  'A.a3.a3x'),
  ('dave',  'admin', 'B'),
  ('dave',  'read',  'B.b1'),
  ('frank', 'read',  'A.a1'),
  ('gwen',  'read',  'A.a2')
) AS m(name, permission, path) JOIN account a ON a.name = m.name;

INSERT INTO item_visibility (type, item_path) VALUES
  ('hidden', 'A.a1.a1x'),
  ('public', 'A.a2'),
  ('hidden', 'A.a2.a2x'),
  ('hidden', 'A.a3'),
  ('public', 'B'),
  ('hidden', 'B.b1');
