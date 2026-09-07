begin;

select plan(17);

select has_extension('pgcrypto', 'pgcrypto is available for UUID defaults');
select has_table('public', 'profiles', 'profiles baseline table exists');
select has_table('public', 'master_komponen', 'component baseline table exists');
select has_table('public', 'riwayat_checking_komponen', 'checking history baseline table exists');
select has_table('public', 'riwayat_service', 'service history baseline table exists');
select has_table('public', 'audit_log', 'audit log baseline table exists');
select has_function('private', 'current_user_has_role', array['text[]'], 'private active-role helper exists');
select row_security_active('public.profiles'::regclass, 'profiles RLS is enabled');
select row_security_active('public.master_komponen'::regclass, 'master component RLS is enabled');
select is(
  (select count(*) from pg_policies where schemaname = 'public' and tablename = 'master_komponen'),
  4::bigint,
  'master component has the four audited policies'
);
select is(
  (select count(*) from pg_policies where schemaname = 'public' and tablename = 'riwayat_checking_komponen'),
  2::bigint,
  'checking history has the two audited policies'
);
select is(
  (select count(*) from pg_policies where schemaname = 'public' and tablename = 'riwayat_service'),
  2::bigint,
  'service history has the two audited policies'
);
select is(
  (select count(*) from pg_policies where schemaname = 'public' and tablename = 'audit_log'),
  1::bigint,
  'audit log has the audited reader policy'
);
select is(
  (select count(*) from public.profiles),
  5::bigint,
  'seed contains four roles and one inactive fixture'
);
select is(
  (select count(distinct jenis_komponen) from public.master_komponen),
  3::bigint,
  'seed contains every component kind'
);
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000004', true);
select ok(
  private.current_user_has_role(array['Tim Service']),
  'active service fixture is recognized by the helper'
);
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000005', true);
select ok(
  not private.current_user_has_role(array['Tim Service']),
  'inactive fixture is rejected by the helper'
);

select * from finish();
rollback;
