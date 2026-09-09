-- ==============================================================================
-- MGRS DATABASE CLEAN RESET SCRIPT (VERSI TERBARU)
-- Tujuan: Membersihkan seluruh data operasional, riwayat servis, transaksi,
--         dan user non-admin.
-- Hasil Akhir:
--   - 20 Unit Blower (60 Komponen):
--       * 20 Kepala (K-01 s/d K-20)
--       * 20 Batang (B-01 s/d B-20)
--       * 20 Tabung (T-01 s/d T-20)
--   - 10 Kabel Rol (KR-01 s/d KR-10)
--   - Seluruh status kembali 'OK' / 'Tersedia'
--   - Hanya menyisakan Akun Admin
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. BERSIHKAN DATA TRANSAKSI, ORDERAN, & RIWAYAT (WEB & MOBILE)
-- ------------------------------------------------------------------------------
DELETE FROM public.audit_log;
DELETE FROM public.riwayat_checking_kabel_rol;
DELETE FROM public.riwayat_checking_komponen;
DELETE FROM public.riwayat_service_kabel_rol;
DELETE FROM public.riwayat_service;
DELETE FROM public.invoices;
DELETE FROM public.konfirmasi_setelah_pakai;
DELETE FROM public.laporan_kabel_rol_setelah_pakai;
DELETE FROM public.laporan_setelah_pakai;
DELETE FROM public.detail_kabel_rol_orderan;
DELETE FROM public.detail_orderan;
DELETE FROM public.permintaan_order_publik;
DELETE FROM public.orderan_sewa;

-- Bersihkan event, task checklist, dan sinkronisasi maintenance mobile
DELETE FROM public.maintenance_events;
DELETE FROM public.maintenance_tasks;
DELETE FROM public.maintenance_periods;

-- Bersihkan membership private jika ada
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'maintenance_private' AND table_name = 'membership') THEN
    EXECUTE 'DELETE FROM maintenance_private.membership;';
  END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 2. RESET MASTER KOMPONEN (Tepat 20 Kepala, 20 Batang, 20 Tabung = 60 Komponen)
-- ------------------------------------------------------------------------------
DELETE FROM public.master_komponen;

-- 20 Kepala: K-01 s/d K-20
INSERT INTO public.master_komponen (
  komponen_id,
  jenis_komponen,
  nomor_stiker,
  kondisi,
  boleh_dipakai,
  fungsi_terganggu,
  keterangan,
  status_penggunaan
)
SELECT
  'K' || lpad(series::text, 2, '0'),
  'Kepala',
  'K-' || lpad(series::text, 2, '0'),
  'OK',
  'Ya',
  'Tidak Ada',
  '-',
  'Tersedia'
FROM generate_series(1, 20) AS series;

-- 20 Batang: B-01 s/d B-20
INSERT INTO public.master_komponen (
  komponen_id,
  jenis_komponen,
  nomor_stiker,
  kondisi,
  boleh_dipakai,
  fungsi_terganggu,
  keterangan,
  status_penggunaan
)
SELECT
  'B' || lpad(series::text, 2, '0'),
  'Batang',
  'B-' || lpad(series::text, 2, '0'),
  'OK',
  'Ya',
  'Tidak Ada',
  '-',
  'Tersedia'
FROM generate_series(1, 20) AS series;

-- 20 Tabung: T-01 s/d T-20
INSERT INTO public.master_komponen (
  komponen_id,
  jenis_komponen,
  nomor_stiker,
  kondisi,
  boleh_dipakai,
  fungsi_terganggu,
  keterangan,
  status_penggunaan
)
SELECT
  'T' || lpad(series::text, 2, '0'),
  'Tabung',
  'T-' || lpad(series::text, 2, '0'),
  'OK',
  'Ya',
  'Tidak Ada',
  '-',
  'Tersedia'
FROM generate_series(1, 20) AS series;

-- ------------------------------------------------------------------------------
-- 3. RESET MASTER KABEL ROL (10 Kabel Rol: KR-01 s/d KR-10)
-- ------------------------------------------------------------------------------
DELETE FROM public.master_kabel_rol;

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
FROM generate_series(1, 10) AS series;

-- ------------------------------------------------------------------------------
-- 4. BERSIHKAN USER NON-ADMIN (Hanya menyisakan akun dengan username 'admin' / role 'Admin')
-- ------------------------------------------------------------------------------
-- Hapus dari auth.users (akan otomatis cascade menghapus data profile non-admin)
DELETE FROM auth.users
WHERE id IN (
  SELECT id FROM public.profiles
  WHERE lower(coalesce(username, '')) != 'admin'
    AND role != 'Admin'
);

-- Hapus profile yatim piatu (jika ada profile non-admin tanpa user auth)
DELETE FROM public.profiles
WHERE lower(coalesce(username, '')) != 'admin'
  AND role != 'Admin';

COMMIT;

-- ==============================================================================
-- Verifikasi Cepat (Jalankan setelah query di atas jika ingin mengecek hasil):
-- SELECT count(*) AS total_komponen FROM public.master_komponen; -- Harusnya 60
-- SELECT count(*) AS total_kabel_rol FROM public.master_kabel_rol; -- Harusnya 10
-- SELECT username, role FROM public.profiles;                     -- Harusnya hanya Admin
-- ==============================================================================
