begin read only;
select jsonb_build_object(
 'columns', (select jsonb_agg(to_jsonb(c)) from (select table_name,column_name,data_type,udt_name,is_nullable,column_default from information_schema.columns where table_schema='public' and table_name in ('profiles','master_komponen','riwayat_checking_komponen','riwayat_service','audit_log') order by table_name,ordinal_position)c),
 'policies', (select jsonb_agg(to_jsonb(p)) from (select tablename,policyname,roles,cmd,qual,with_check from pg_policies where schemaname='public' and tablename in ('profiles','master_komponen','riwayat_checking_komponen','riwayat_service','audit_log'))p),
 'triggers', (select jsonb_agg(jsonb_build_object('table',c.relname,'name',t.tgname,'definition',pg_get_triggerdef(t.oid))) from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and not t.tgisinternal and c.relname in ('master_komponen','riwayat_checking_komponen','riwayat_service')),
 'grants', (select jsonb_agg(to_jsonb(g)) from (select grantee,table_name,privilege_type from information_schema.role_table_grants where table_schema='public' and table_name in ('master_komponen','riwayat_checking_komponen','riwayat_service','audit_log') and grantee in ('anon','authenticated','service_role'))g),
 'duplicate_sticker_groups', (select count(*) from (select nomor_stiker from public.master_komponen group by nomor_stiker having count(*)>1)d),
 'component_counts', (select jsonb_agg(to_jsonb(k)) from (select jenis_komponen,count(*) from public.master_komponen group by jenis_komponen)k),
 'extensions', (select jsonb_agg(extname) from pg_extension where extname in ('pg_cron','pgtap','pgcrypto'))
) as metadata;
rollback;
