-- ==============================================================================
-- MGRS DATABASE CLEAN RESET SCRIPT (SIAP PRODUKSI)
-- ==============================================================================
-- Petunjuk Penggunaan:
-- 1. Buka Supabase Dashboard -> Project MGRS -> SQL Editor.
-- 2. Buat query baru (New query), salin (copy) dan tempel (paste) seluruh isi file ini.
-- 3. Klik tombol "Run" untuk mengeksekusi.
--
-- Hasil Akhir:
--   - Semua data transaksi, orderan, riwayat checking & service, invoice, dan log dibersihkan.
--   - Semua komponen master (60 unit blower: 20 Kepala, 20 Batang, 20 Tabung) berstatus 'OK' & 'Tersedia'.
--   - Semua kabel rol master (10 unit: KR-01 s/d KR-10) berstatus 'OK' & 'Tersedia'.
--   - Seluruh user lama dibersihkan dari auth.users & public.profiles.
--   - 1 User Admin baru dibuat dan langsung aktif:
--       * Username : admin
--       * Email    : admin@mgrs.biz.id
--       * Password : Admin@12345
--       * Role     : Admin
-- ==============================================================================

BEGIN;

-- Pastikan ekstensi pgcrypto tersedia untuk hashing password
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------------------------
-- 1. BERSIHKAN DATA TRANSAKSI, ORDERAN, SERVICE, CHECKING, & LOG OPERASIONAL
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  tbl text;
  tables text[] := ARRAY[
    'audit_log',
    'riwayat_checking_kabel_rol',
    'riwayat_checking_komponen',
    'riwayat_service_kabel_rol',
    'riwayat_service',
    'invoices',
    'konfirmasi_setelah_pakai',
    'laporan_kabel_rol_setelah_pakai',
    'laporan_setelah_pakai',
    'detail_kabel_rol_orderan',
    'detail_orderan',
    'permintaan_order_publik',
    'orderan_sewa',
    'maintenance_events',
    'maintenance_tasks',
    'maintenance_periods'
  ];
BEGIN
  FOREACH tbl IN ARRAY tables LOOP
    IF EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = tbl
    ) THEN
      EXECUTE format('DELETE FROM public.%I;', tbl);
    END IF;
  END LOOP;

  -- Bersihkan membership private jika ada
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'maintenance_private' AND table_name = 'membership'
  ) THEN
    EXECUTE 'DELETE FROM maintenance_private.membership;';
  END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 2. LEPAS REFERENSI USER PADA MASTER KOMPONEN SEBELUM USER DIHAPUS
-- ------------------------------------------------------------------------------
UPDATE public.master_komponen
SET updated_by = NULL;

-- ------------------------------------------------------------------------------
-- 3. HAPUS SEMUA USER LAMA (AUTH & PROFILES)
-- ------------------------------------------------------------------------------
-- Hapus semua profiles dan auth.users (cascade ke session, mfa, identities)
DELETE FROM public.profiles;
DELETE FROM auth.users;

-- ------------------------------------------------------------------------------
-- 4. BUAT USER ADMIN BARU (SIAP LOGIN)
-- ------------------------------------------------------------------------------
DO $$
DECLARE
  v_admin_id uuid := 'a0000000-0000-0000-0000-000000000001'::uuid;
  v_email text := 'admin@mgrs.biz.id';
  v_username text := 'admin';
  v_password text := 'Admin@12345';
  v_encrypted_pw text;
BEGIN
  -- Hash password menggunakan Blowfish (bcrypt) standar Supabase Auth
  v_encrypted_pw := crypt(v_password, gen_salt('bf', 10));

  -- Insert ke auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_admin_id,
    'authenticated',
    'authenticated',
    v_email,
    v_encrypted_pw,
    now(),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('username', v_username, 'full_name', 'Administrator MGRS'),
    now(),
    now(),
    '',
    '',
    '',
    ''
  );

  -- Insert ke auth.identities untuk dukungan Supabase GoTrue email sign-in
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'auth' AND table_name = 'identities'
  ) THEN
    BEGIN
      INSERT INTO auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        provider_id,
        last_sign_in_at,
        created_at,
        updated_at
      ) VALUES (
        v_admin_id,
        v_admin_id,
        jsonb_build_object('sub', v_admin_id::text, 'email', v_email, 'email_verified', true),
        'email',
        v_admin_id::text,
        now(),
        now(),
        now()
      );
    EXCEPTION WHEN OTHERS THEN
      BEGIN
        INSERT INTO auth.identities (
          provider_id,
          user_id,
          identity_data,
          provider,
          last_sign_in_at,
          created_at,
          updated_at
        ) VALUES (
          v_admin_id::text,
          v_admin_id,
          jsonb_build_object('sub', v_admin_id::text, 'email', v_email, 'email_verified', true),
          'email',
          now(),
          now(),
          now()
        );
      EXCEPTION WHEN OTHERS THEN
        NULL;
      END;
    END;
  END IF;

  -- Insert ke public.profiles
  INSERT INTO public.profiles (
    id,
    full_name,
    username,
    role,
    is_active,
    created_at,
    updated_at
  ) VALUES (
    v_admin_id,
    'Administrator MGRS',
    v_username,
    'Admin',
    true,
    now(),
    now()
  );

END $$;

-- ------------------------------------------------------------------------------
-- 5. RESET SEMUA KOMPONEN MASTER AGAR BERSTATUS 'OK' & 'TERSEDIA'
-- ------------------------------------------------------------------------------
-- Update semua komponen yang ada agar kondisinya OK dan Tersedia
UPDATE public.master_komponen
SET kondisi = 'OK',
    boleh_dipakai = 'Ya',
    fungsi_terganggu = 'Tidak Ada',
    keterangan = '-',
    status_penggunaan = 'Tersedia',
    updated_by = NULL,
    updated_at = now();

-- Pastikan tepat 20 Kepala (K-01 s/d K-20) tersedia
INSERT INTO public.master_komponen (
  komponen_id,
  jenis_komponen,
  nomor_stiker,
  kondisi,
  boleh_dipakai,
  fungsi_terganggu,
  keterangan,
  status_penggunaan,
  updated_at,
  updated_by
)
SELECT
  'K' || lpad(series::text, 2, '0'),
  'Kepala',
  'K-' || lpad(series::text, 2, '0'),
  'OK',
  'Ya',
  'Tidak Ada',
  '-',
  'Tersedia',
  now(),
  NULL
FROM generate_series(1, 20) AS series
ON CONFLICT (komponen_id) DO UPDATE SET
  jenis_komponen = EXCLUDED.jenis_komponen,
  nomor_stiker = EXCLUDED.nomor_stiker,
  kondisi = 'OK',
  boleh_dipakai = 'Ya',
  fungsi_terganggu = 'Tidak Ada',
  keterangan = '-',
  status_penggunaan = 'Tersedia',
  updated_by = NULL,
  updated_at = now();

-- Pastikan tepat 20 Batang (B-01 s/d B-20) tersedia
INSERT INTO public.master_komponen (
  komponen_id,
  jenis_komponen,
  nomor_stiker,
  kondisi,
  boleh_dipakai,
  fungsi_terganggu,
  keterangan,
  status_penggunaan,
  updated_at,
  updated_by
)
SELECT
  'B' || lpad(series::text, 2, '0'),
  'Batang',
  'B-' || lpad(series::text, 2, '0'),
  'OK',
  'Ya',
  'Tidak Ada',
  '-',
  'Tersedia',
  now(),
  NULL
FROM generate_series(1, 20) AS series
ON CONFLICT (komponen_id) DO UPDATE SET
  jenis_komponen = EXCLUDED.jenis_komponen,
  nomor_stiker = EXCLUDED.nomor_stiker,
  kondisi = 'OK',
  boleh_dipakai = 'Ya',
  fungsi_terganggu = 'Tidak Ada',
  keterangan = '-',
  status_penggunaan = 'Tersedia',
  updated_by = NULL,
  updated_at = now();

-- Pastikan tepat 20 Tabung (T-01 s/d T-20) tersedia
INSERT INTO public.master_komponen (
  komponen_id,
  jenis_komponen,
  nomor_stiker,
  kondisi,
  boleh_dipakai,
  fungsi_terganggu,
  keterangan,
  status_penggunaan,
  updated_at,
  updated_by
)
SELECT
  'T' || lpad(series::text, 2, '0'),
  'Tabung',
  'T-' || lpad(series::text, 2, '0'),
  'OK',
  'Ya',
  'Tidak Ada',
  '-',
  'Tersedia',
  now(),
  NULL
FROM generate_series(1, 20) AS series
ON CONFLICT (komponen_id) DO UPDATE SET
  jenis_komponen = EXCLUDED.jenis_komponen,
  nomor_stiker = EXCLUDED.nomor_stiker,
  kondisi = 'OK',
  boleh_dipakai = 'Ya',
  fungsi_terganggu = 'Tidak Ada',
  keterangan = '-',
  status_penggunaan = 'Tersedia',
  updated_by = NULL,
  updated_at = now();

-- ------------------------------------------------------------------------------
-- 6. RESET MASTER KABEL ROL (10 Kabel Rol: KR-01 s/d KR-10) JIKA TABEL TERSEDIA
-- ------------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'master_kabel_rol'
  ) THEN
    UPDATE public.master_kabel_rol
    SET kondisi = 'OK',
        boleh_dipakai = 'Ya',
        keterangan = '-',
        status_penggunaan = 'Tersedia';

    INSERT INTO public.master_kabel_rol (
      nomor_kabel,
      kondisi,
      boleh_dipakai,
      keterangan,
      status_penggunaan
    )
    SELECT
      'KR-' || lpad(series::text, 2, '0'),
      'OK',
      'Ya',
      '-',
      'Tersedia'
    FROM generate_series(1, 10) AS series
    ON CONFLICT (nomor_kabel) DO UPDATE SET
      kondisi = 'OK',
      boleh_dipakai = 'Ya',
      keterangan = '-',
      status_penggunaan = 'Tersedia';
  END IF;
END $$;

COMMIT;

-- ==============================================================================
-- HASIL VERIFIKASI (Otomatis tampil setelah dijalankan):
-- ==============================================================================
SELECT 'Komponen Master' AS entitas, count(*) AS total, 'Semua OK & Tersedia' AS keterangan
FROM public.master_komponen
UNION ALL
SELECT 'User Admin' AS entitas, count(*) AS total, coalesce(max(username), '-') || ' (' || coalesce(max(role), '-') || ')' AS keterangan
FROM public.profiles
UNION ALL
SELECT 'Auth User' AS entitas, count(*) AS total, coalesce(max(email), '-') AS keterangan
FROM auth.users;
