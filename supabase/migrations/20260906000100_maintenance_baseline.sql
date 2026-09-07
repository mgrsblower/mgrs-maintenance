-- LOCAL BOOTSTRAP ONLY.
-- This file creates an isolated Supabase-local baseline for development and tests.
-- NEVER apply it to an existing, linked, QA, or production MGRS database.

create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  username text,
  phone_number text,
  role text not null check (role in ('Admin', 'PIC Pemasangan', 'Tim Pemasangan', 'Tim Service')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index profiles_username_unique_idx
  on public.profiles (lower(username))
  where username is not null;

create unique index profiles_phone_number_unique_idx
  on public.profiles (phone_number)
  where phone_number is not null;

create table public.master_komponen (
  id uuid primary key default gen_random_uuid(),
  komponen_id text unique not null,
  jenis_komponen text not null check (jenis_komponen in ('Kepala', 'Batang', 'Tabung')),
  nomor_stiker text unique not null,
  kondisi text not null default 'OK' check (kondisi in ('OK', 'Rusak Ringan', 'Rusak Berat', 'Service', 'Hilang')),
  boleh_dipakai text not null default 'Ya' check (boleh_dipakai in ('Ya', 'Tidak')),
  fungsi_terganggu text not null default 'Tidak Ada',
  keterangan text default '-',
  status_penggunaan text not null default 'Tersedia' check (status_penggunaan in ('Tersedia', 'Dipakai', 'Service', 'Hilang')),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

create table public.riwayat_checking_komponen (
  id uuid primary key default gen_random_uuid(),
  timestamp timestamptz not null default now(),
  nomor_stiker text,
  jenis_komponen text,
  kondisi_terbaru text,
  boleh_dipakai text,
  fungsi_terganggu text,
  catatan text,
  petugas uuid references public.profiles(id),
  tanggal_checking date
);

create table public.riwayat_service (
  id uuid primary key default gen_random_uuid(),
  timestamp timestamptz not null default now(),
  nomor_stiker text,
  jenis_komponen text,
  masalah text,
  tindakan_service text,
  biaya_service numeric not null default 0,
  teknisi uuid references public.profiles(id),
  hasil_kondisi text,
  boleh_dipakai text,
  fungsi_terganggu text,
  catatan text
);

create table public.audit_log (
  id uuid primary key default gen_random_uuid(),
  timestamp timestamptz not null default now(),
  action text not null,
  entity_type text not null,
  entity_id text,
  old_value jsonb,
  new_value jsonb,
  user_id uuid references public.profiles(id)
);

create schema private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create function private.current_user_has_role(allowed_roles text[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    (select auth.uid()) is not null
    and exists (
      select 1
      from public.profiles as profile
      where profile.id = (select auth.uid())
        and profile.is_active = true
        and profile.role = any(allowed_roles)
    );
$$;

revoke all on function private.current_user_has_role(text[]) from public, anon;
grant execute on function private.current_user_has_role(text[]) to authenticated;

alter table public.profiles enable row level security;
alter table public.master_komponen enable row level security;
alter table public.riwayat_checking_komponen enable row level security;
alter table public.riwayat_service enable row level security;
alter table public.audit_log enable row level security;

create policy "profiles_select_self_or_admin" on public.profiles
for select to authenticated
using (
  id = (select auth.uid())
  or (select private.current_user_has_role(array['Admin']))
);

create policy "profiles_update_self" on public.profiles
for update to authenticated
using (
  id = (select auth.uid())
  and (select private.current_user_has_role(array['Admin', 'PIC Pemasangan', 'Tim Pemasangan', 'Tim Service']))
)
with check (
  id = (select auth.uid())
  and (select private.current_user_has_role(array['Admin', 'PIC Pemasangan', 'Tim Pemasangan', 'Tim Service']))
);

create policy "master_komponen_select_active" on public.master_komponen
for select to authenticated
using ((select private.current_user_has_role(array['Admin', 'PIC Pemasangan', 'Tim Pemasangan', 'Tim Service'])));
create policy "master_komponen_insert_admin" on public.master_komponen
for insert to authenticated
with check ((select private.current_user_has_role(array['Admin'])));
create policy "master_komponen_update_operational" on public.master_komponen
for update to authenticated
using ((select private.current_user_has_role(array['Admin', 'Tim Pemasangan', 'Tim Service'])))
with check ((select private.current_user_has_role(array['Admin', 'Tim Pemasangan', 'Tim Service'])));
create policy "master_komponen_delete_admin" on public.master_komponen
for delete to authenticated
using ((select private.current_user_has_role(array['Admin'])));

create policy "riwayat_checking_komponen_select_active" on public.riwayat_checking_komponen
for select to authenticated
using ((select private.current_user_has_role(array['Admin', 'PIC Pemasangan', 'Tim Pemasangan', 'Tim Service'])));
create policy "riwayat_checking_komponen_insert_service" on public.riwayat_checking_komponen
for insert to authenticated
with check ((select private.current_user_has_role(array['Admin', 'Tim Service'])));

create policy "riwayat_service_select_active" on public.riwayat_service
for select to authenticated
using ((select private.current_user_has_role(array['Admin', 'PIC Pemasangan', 'Tim Pemasangan', 'Tim Service'])));
create policy "riwayat_service_insert_service" on public.riwayat_service
for insert to authenticated
with check ((select private.current_user_has_role(array['Admin', 'Tim Service'])));

create policy "audit_log_select_admin_pic" on public.audit_log
for select to authenticated
using ((select private.current_user_has_role(array['Admin', 'PIC Pemasangan'])));

grant all privileges on public.master_komponen to anon, authenticated, service_role;
grant all privileges on public.riwayat_checking_komponen to anon, authenticated, service_role;
grant all privileges on public.riwayat_service to anon, authenticated, service_role;
grant all privileges on public.audit_log to anon, authenticated, service_role;

revoke update on public.profiles from authenticated;
grant select on public.profiles to authenticated;
grant update (full_name, username, phone_number, updated_at) on public.profiles to authenticated;
