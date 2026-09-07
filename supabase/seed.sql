insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
)
values
  ('10000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'admin.fixture@invalid.local', null, now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('10000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'pic.fixture@invalid.local', null, now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('10000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'installer.fixture@invalid.local', null, now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('10000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', 'service.fixture@invalid.local', null, now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()),
  ('10000000-0000-0000-0000-000000000005', 'authenticated', 'authenticated', 'inactive.fixture@invalid.local', null, now(), '{"provider":"email","providers":["email"]}', '{}', now(), now())
on conflict (id) do nothing;

insert into public.profiles (id, full_name, username, role, is_active)
values
  ('10000000-0000-0000-0000-000000000001', 'Fixture Admin', 'fixture_admin', 'Admin', true),
  ('10000000-0000-0000-0000-000000000002', 'Fixture PIC', 'fixture_pic', 'PIC Pemasangan', true),
  ('10000000-0000-0000-0000-000000000003', 'Fixture Installer', 'fixture_installer', 'Tim Pemasangan', true),
  ('10000000-0000-0000-0000-000000000004', 'Fixture Service', 'fixture_service', 'Tim Service', true),
  ('10000000-0000-0000-0000-000000000005', 'Fixture Inactive Service', 'fixture_inactive', 'Tim Service', false)
on conflict (id) do update
set full_name = excluded.full_name,
    username = excluded.username,
    role = excluded.role,
    is_active = excluded.is_active,
    updated_at = now();

insert into public.master_komponen (komponen_id, jenis_komponen, nomor_stiker, updated_by)
values
  ('LOCAL-KEPALA-001', 'Kepala', 'LOCAL-STICKER-KEPALA-001', '10000000-0000-0000-0000-000000000001'),
  ('LOCAL-BATANG-001', 'Batang', 'LOCAL-STICKER-BATANG-001', '10000000-0000-0000-0000-000000000001'),
  ('LOCAL-TABUNG-001', 'Tabung', 'LOCAL-STICKER-TABUNG-001', '10000000-0000-0000-0000-000000000001')
on conflict (komponen_id) do update
set jenis_komponen = excluded.jenis_komponen,
    nomor_stiker = excluded.nomor_stiker,
    updated_by = excluded.updated_by,
    updated_at = now();
