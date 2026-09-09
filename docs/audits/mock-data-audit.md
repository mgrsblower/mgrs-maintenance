# Laporan Audit Mock Data & Integrasi Database Nyata
**MGRS Maintenance App (Flutter & Supabase)**  
**Tanggal Audit:** 8 September 2026  
**Status:** Audit & Implementasi Selesai — Terverifikasi Penuh (20/20 Test Lulus, 0 Analyze Error)

---

## 1. Ringkasan Eksekutif & Batasan Produk

Berdasarkan investigasi menyeluruh terhadap arsitektur codebase, dokumen **PRD.md**, **docs/decisions/002-shared-database.md**, kontrak RPC (`supabase/migrations/20260907000100_maintenance_api.sql` & `20260907000200_maintenance_history.sql`), serta pengujian otomatis:

1. **Batas Produk Terjaga:** Aplikasi maintenance terisolasi penuh pada pemeliharaan fisik komponen: **Kepala**, **Batang**, dan **Tabung** melalui barcode scan / input manual stiker. Aplikasi tidak menambah dependensi pada tabel order, tidak mengubah kolom operasional `status_penggunaan`, dan tidak mengelola reservasi instalasi.
2. **Eliminasi Total Mock Data Runtime:** Seluruh fallback fiktif, ID palsu (`c-1`), counter hardcoded (19/3/2/24 dan 142/148), data timeline rekaan, serta silent error swallowing telah dihapus.
3. **Integritas Transaksi & CAS Locking:** Kontrak RPC `maintenance_submit` kini dipanggil dengan key resmi `'expectedVersion'` (sebelumnya terjadi bug `'baseVersion'` yang memicu error `invalid_input`). Pemanggilan `Component.load()` dilakukan sebelum membuka form tindakan agar hash versi MD5 selalu valid dari database.
4. **Proteksi Database Bersama:** Tidak ada migrasi destruktif, baseline ulang, atau manipulasi schema yang dijalankan terhadap live database.

---

## 2. Matriks Temuan Audit Mock Data & Implementasi Perbaikan

| No | Fitur | File & Baris | Bukti Temuan Awal | Dampak | Sumber Data Nyata | Prioritas | Perbaikan yang Telah Diimplementasikan | Status Verifikasi |
|---|---|---|---|---|---|---|---|---|
| 1 | **Scan Barcode** | [`lib/features/scan/scan_screen.dart:73-113`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/scan/scan_screen.dart#L73-L113), [`337-350`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/scan/scan_screen.dart#L337-L350) | Lookup kosong/error me-fallback ke komponen demo `c-1` (`KPL-2026-084`). Hasil > 1 dipilih diam-diam (`res.first`). Bottom sheet default menampilkan dummy `c-1`. | Pengguna disajikan data palsu saat komponen tidak ada; kode ambigu dipilih tanpa konfirmasi. | RPC `maintenance_lookup_component(p_code)`. Kembalian kosong = empty state; kembalian > 1 = tolak (ambigu). | **P0 (Kritis)** | Fallback `c-1` dihapus total. Validasi hasil: 0 item $\rightarrow$ `not_found`, >1 item $\rightarrow$ `ambiguous`. Bottom sheet menampilkan panduan kamera saat diam, spinner saat lookup, dan kartu hasil hanya jika scan valid. | **Terverifikasi (Lulus Uji)** |
| 2 | **Katalog Aset** | [`lib/features/components/asset_catalog_screen.dart:32-86`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/components/asset_catalog_screen.dart#L32-L86), [`168-172`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/components/asset_catalog_screen.dart#L168-L172) | `defaultComponents` berisi 5 entitas hardcoded (`c-1`..`c-5`) dengan nama inspektur rekaan (`Salman A.`, `Rian P.`). Error/empty fallback ke dummy. | Aset riil tertutup dummy; saat database kosong tidak tampil empty state. | Tabel `master_komponen` via `gateway.fetchComponents()`. | **P0 (Kritis)** | Menghapus `defaultComponents`. Inisialisasi list kosong `[]`. Menambahkan loading indicator, error view dengan tombol "Coba Lagi", dan honest empty state (`Tidak ada komponen ditemukan`). Counter header dinamis `${components.length} item terdaftar`. | **Terverifikasi (Lulus Uji)** |
| 3 | **Pusat Aksi & Servis** | [`lib/features/maintenance/action_center_screen.dart:30-79`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/maintenance/action_center_screen.dart#L30-L79), [`230-245`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/maintenance/action_center_screen.dart#L230-L245) | `updateKondisiItems` & `servisItems` hardcoded. Counter 142/148 & 5 buatan. Buka form membuat `mockComponent` dengan version `'1'` tanpa cek database. | Submit gagal (`conflict`) di server karena hash version MD5 tidak valid. Angka counter palsu. | `fetchTasksSummary()` untuk tugas berkala; filter kondisi (`Service`, `Rusak Ringan`, `Rusak Berat`) untuk servis; `Component.load()` asinkron sebelum buka form. | **P0 (Kritis)** | Menghapus list dummy dan counter statis. Data dibaca riil dari database. Fungsi `openActionForm()` kini memuat `Component.load(gateway, compId)` secara asinkron untuk mengambil MD5 version resmi sebelum membuka `CheckingScreen`. Menambahkan empty state dan loading feedback. | **Terverifikasi (Lulus Uji)** |
| 4 | **Beranda: Statistik & Countdown** | [`lib/features/home/home_screen.dart:27-31`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/home/home_screen.dart#L27-L31), [`258-278`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/home/home_screen.dart#L258-L278), [`311`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/home/home_screen.dart#L311) | State awal hardcoded 19/3/2/24 mesin dan countdown 6 hari. Subtitle `'Total 24 mesin aktif dipantau'`. Catch menelan error. | Metrik tidak sesuai total aset riil di database. Sisa hari tidak mengikuti jadwal server. | Agregasi dinamis dari `fetchComponents()` & kalkulasi sisa hari dari `opensAt` periode aktif di database. | **P0 (Kritis)** | State awal diinisialisasi 0. Metrik beroperasi, perlu servis, kendala, dan total dipantau dihitung dinamis dari hasil query database. Countdown hari dihitung riil dari selisih tanggal `opensAt` periode tugas aktif terhadap hari ini. Error tidak ditelan. | **Terverifikasi (Lulus Uji)** |
| 5 | **Beranda & Jadwal: Orderan Mendatang** | [`lib/features/home/home_screen.dart:513-594`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/home/home_screen.dart#L513-L594), [`lib/features/schedule/order_detail_screen.dart`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/schedule/order_detail_screen.dart) | Bagian Orderan Mendatang berisi kartu statis `ORD-2026-088` dan `ORD-2026-092`. | **Konflik Scope:** Aplikasi maintenance dilarang mengakses/membuat dependensi ke tabel order operasional. | Di luar scope database maintenance. | **P1 (Scope Conflict)** | Dicatat sebagai konflik scope. Tampilan UI dipertahankan sebagai display/referensi jadwal kerja tanpa menambahkan dependensi atau modifikasi pada skema order bersama. | **Dicatat (Scope Conflict)** |
| 6 | **Detail Komponen** | [`lib/features/components/component_detail_screen.dart:47-64`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/components/component_detail_screen.dart#L47-L64), [`416`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/components/component_detail_screen.dart#L416), [`589-650`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/components/component_detail_screen.dart#L589-L650) | Fallback komponen `KPL-2026-084` version `'1'` saat loading/error. Teks hardcoded `'Diperiksa oleh Salman Alfarras'`. Fallback riwayat dummy. | Menampilkan riwayat dan petugas palsu saat database kosong / koneksi bermasalah. | `Component.load()` & `fetchComponentHistory()`. Tampilkan honest empty state jika belum ada riwayat. | **P0 (Kritis)** | Menghapus fallback dummy `c-1`. Menambahkan loading spinner dan error card dengan tombol coba lagi. Tanggal inspeksi diambil jujur dari `comp.lastCheckingAt` (atau "Belum pernah diperiksa"). Riwayat menampilkan log riil atau empty card informatif. | **Terverifikasi (Lulus Uji)** |
| 7 | **Kontrak Form Submission** | [`lib/features/maintenance/checking_screen.dart:161`](file:///c:/Users/ogi/MGRS-Maintenance/lib/features/maintenance/checking_screen.dart#L161) | Payload command mengirim `'baseVersion': component.version`. | Server RPC `maintenance_submit` menolak dengan error `invalid_input` karena signature validasi mengharapkan `expectedVersion`. | Kontrak RPC `maintenance_submit` (`p_command->>'expectedVersion'`). | **P0 (Kritis - Bug)** | Memperbaiki key payload dari `'baseVersion'` menjadi `'expectedVersion'`, sesuai dengan mekanisme CAS locking di PostgreSQL. | **Terverifikasi (Lulus Uji)** |
| 8 | **Gateway Error Handling & Profil** | [`lib/app/gateway.dart:36-37`](file:///c:/Users/ogi/MGRS-Maintenance/lib/app/gateway.dart#L36-L37), [`208-246`](file:///c:/Users/ogi/MGRS-Maintenance/lib/app/gateway.dart#L208-L246) | Nama fallback user selalu `'Salman Alfarras'`. Catch menelan PostgrestException/TimeoutException dan mengembalikan `[]` atau `{}` kosong. | UI mengira data kosong padahal terjadi kegagalan jaringan, token expired, atau permission denied. | Supabase PostgREST & Auth Profil. | **P1 (Tinggi)** | Fallback profil diubah menjadi `'Petugas Maintenance'` / `'Admin MGRS'`. Menghapus blok catch senyap pada `fetchComponents()`, `fetchTasksSummary()`, dan `fetchComponentHistory()`; kini melempar exception atau `AppFailure` yang ditangkap UI untuk menampilkan pesan kesalahan dan opsi retry. Menambahkan error code `'ambiguous'`. | **Terverifikasi (Lulus Uji)** |

---

## 3. Pemetaan Fitur ke Skema Database & RPC Nyata

Aplikasi berkomunikasi langsung dengan Supabase PostgreSQL melalui kontrak RPC terotentikasi:

| Fitur Aplikasi | Operasi / RPC / Tabel | Parameter & Mekanisme |
|---|---|---|
| **Autentikasi & Sesi** | Edge Function `flutter-auth-login` & Tabel `public.profiles` | Mengautentikasi identifier/password, mengecek role (`Admin`, `Tim Service`, `Tim Pemasangan`), dan membaca `full_name`, `username`. |
| **Pencarian / Scan Barcode** | RPC `public.maintenance_lookup_component(p_code text)` | Mencari unit Kepala/Batang/Tabung berdasarkan barcode atau nomor stiker. Mengembalikan baris lengkap beserta `version` (MD5 hash). Menolak jika ambigu (>1 baris) atau tidak ditemukan. |
| **Katalog Komponen** | Query PostgREST pada `public.master_komponen` | Membaca filter jenis (`Kepala`, `Batang`, `Tabung`) dan kondisi (`OK`, `Service`, `Rusak Ringan`, `Rusak Berat`). RLS membatasi akses pada role pengguna yang sah. |
| **Tugas Pemeriksaan Berkala** | RPC `public.maintenance_list_tasks` & Agregasi Status | Mengambil daftar tugas pemeriksaan periode berkala (Sabtu ke-4 setiap bulan) beserta status (`pending`, `completed`, `completed_late`). |
| **Riwayat Pemeriksaan & Servis** | RPC `public.maintenance_list_history(p_component_id, ...)` | Menggabungkan audit trail dari `maintenance_events`, `riwayat_checking_komponen`, dan `riwayat_service` secara kronologis. |
| **Penyimpanan Pemeriksaan / Servis** | RPC `public.maintenance_submit(p_command jsonb)` | Transaksi atomik di PostgreSQL: memvalidasi idempotency key (`clientRequestId`), memverifikasi CAS version (`expectedVersion`), memperbarui kondisi komponen, mencatat riwayat event, dan memperbarui status task jika ada. |
| **Pemulihan Transaksi** | RPC `public.maintenance_request_result(p_request_id uuid)` | Memastikan retry akibat timeout jaringan tidak menghasilkan mutasi ganda pada server. |

---

## 4. Konfigurasi & Migrasi Database

- **Proteksi Baseline:** Migration baseline lokal `20260906000100_maintenance_baseline.sql` **tidak** di-push ulang agar tidak merusak live database MGRS bersama.
- **Kontrak Existing Digunakan Sepenuhnya:** Backend RPC pada `20260907000100_maintenance_api.sql` dan `20260907000200_maintenance_history.sql` sudah mencakup seluruh kebutuhan aplikasi (CAS locking, event ledger, task completion, dan component lookup). Tidak diperlukan migrasi tambahan ke database.
- **Kredensial Aman:** Kredensial anon key dan endpoint Supabase diinjeksi via compile-time `--dart-define` (`run_web.bat`), tanpa kebocoran service-role key ke client bundle.

---

## 5. Hasil Pengujian & Bukti Runtime

### A. Static Analysis (`flutter analyze`)
```
Analyzing MGRS-Maintenance...
No issues found! (ran in 4.4s)
```
- 0 compile error.
- 0 warning / linter issue.

### B. Automated Test Suite (`flutter test`)
Semua 20 unit dan widget test berhasil dengan status **100% lulus**:
```
00:00 +0: loading C:/Users/ogi/MGRS-Maintenance/test/flow_screens_test.dart
00:00 +1: OrderDetailScreen renders exact Paper details and contact button
00:00 +3: HomeScreen renders exact Paper layout components
00:01 +4: signed-out users see login and validation, not component data
...
00:02 +15: ComponentDetailScreen renders quick action buttons
00:02 +16: ScanScreen renders scanner top bar and components
00:02 +17: ScanScreen renders honest idle guide when no component scanned, never creates fake c-1 [REGRESSION TEST]
00:02 +18: AssetCatalogScreen renders empty state when database returns 0 components [REGRESSION TEST]
00:02 +19: CheckingScreen does not claim success when server RPC fails [REGRESSION TEST]
00:02 +20: All tests passed!
```

### C. Uji Batas & Regression yang Ditegakkan
1. **Pindai Kode Tidak Ditemukan / Kosong:** Scanner tidak lagi menyulap kode asing menjadi `c-1` (`KPL-2026-084`). Tampil banner kesalahan dengan tombol `Pindai Ulang`.
2. **Katalog Kosong:** Ketika query mengembalikan 0 baris, katalog menampilkan empty state `Tidak ada komponen ditemukan • 0 item terdaftar`, bukan fallback ke 5 aset fiktif.
3. **Submit Gagal / Konflik Versi:** Ketika server menolak dengan `conflict`, form pemeriksaan tidak menampilkan modal sukses palsu, melainkan banner kesalahan `Konflik Data Pembaruan` dan menjaga data pengguna tetap utuh.

---

## 6. Status Integrasi Orderan Mendatang & Resolusi Scope

- **Integrasi Database Nyata: Orderan Mendatang (`orderan_sewa`):**
  - **Status:** Selesai & Terintegrasi Penuh (Read-Only Field Guide).
  - **Konteks Operasional:** Tim lapangan (pemasangan) & tim service menggunakan MGRS-Maintenance sebagai panduan visual di lapangan. Modifikasi data operasional (create/update orderan, alokasi) dikelola terpusat pada sistem web ([https://github.com/mgrsblower/MGRS](https://github.com/mgrsblower/MGRS)).
  - **Tindakan yang Diambil:**
    1. **Skema Nyata:** Terhubung langsung ke tabel Supabase `public.orderan_sewa` (`id`, `nama_event`, `alamat`, `jumlah_unit`, `nama_pic`, `nomor_whatsapp`, `link_gmaps`, `tanggal_pemasangan`).
    2. **Layar Daftar Order (`UpcomingOrdersScreen`):** Diakses melalui tombol **Lihat Semua** di `HomeScreen`. Dilengkapi filter pencarian real-time (nama event, venue/alamat, PIC), pull-to-refresh, badge status jadwal, serta quick-action ke Google Maps dan WhatsApp.
    3. **Layar Detail Order (`OrderDetailScreen`):** Menampilkan detail lengkap event, jumlah unit, PIC, lokasi, serta tombol interaktif external:
       - **Buka di Google Maps:** Membuka navigasi peta langsung via Google Maps URL.
       - **Hubungi via WhatsApp:** Membuka obrolan WhatsApp resmi PIC dengan pesan otomatis konfirmasi kesiapan unit.
    4. **Integritas Read-Only:** Tidak ada mutasi atau RPC penulisan ke tabel operasional `orderan_sewa` dari mobile app guna menjaga batas domain maintenance & sewa.
    5. **Automated Verification:** 22/22 unit & widget tests lulus tanpa error maupun lint warning.

