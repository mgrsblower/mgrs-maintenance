# MGRS-Maintenance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Jika pengguna memilih delegasi, gunakan superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menghasilkan aplikasi terpisah untuk scan/manual, pemeriksaan dan servis Kepala/Batang/Tabung, serta pengecekan pada Sabtu keempat–Minggu setiap bulan, menggunakan database MGRS yang sama.

**Architecture:** Klien baru memiliki navigasi Scan, Berkala, dan Riwayat. Autentikasi menggunakan layanan MGRS; pembacaan dibatasi pada komponen dan maintenance. Penulisan kondisi, riwayat, audit, dan penyelesaian jadwal dilakukan lewat transaksi database yang memverifikasi role, versi data, dan ID permintaan.

**Tech Stack:** Baseline perencanaan adalah Flutter/Dart, Supabase Auth/PostgreSQL/RPC, `mobile_scanner`, dan pengujian Flutter serta pgTAP. Flutter adalah asumsi untuk membuat file dan perintah konkret, bukan keputusan pengguna yang sudah final. Task 1 mengunci platform/framework sebelum scaffold; jika pengguna memilih teknologi lain, revisi task klien dan perintahnya terlebih dahulu. Backend dan aturan produk tetap berlaku.

**Tanggal:** 6 September 2026.  
**Sumber:** [PRD.md](../../../PRD.md), versi 1.0.  
**Status:** Rencana tersimpan untuk ditinjau; belum ada task implementasi yang dikerjakan.  
**Workspace target:** `C:\Users\ogi\MGRS-Maintenance`.  
**Referensi read-only:** `C:\Users\ogi\mgrs-release`.

## Global Constraints

- Objek hanya `Kepala`, `Batang`, dan `Tabung`; identitas dan barcode memakai master yang sudah ada.
- Role yang boleh mengakses dan memperbarui maintenance: `Admin`, `Tim Service`, `Tim Pemasangan`, dengan profil aktif.
- Role `PIC Pemasangan` tidak otomatis ditambahkan. Hak akses baru tidak berarti mengubah hak akses aplikasi lama.
- Tidak ada alur pemasangan, order, alokasi, reservasi, invoice, pengelolaan pengguna, atau pembuatan master.
- `status_penggunaan` dan relasi operasional tidak boleh berubah akibat transaksi aplikasi baru, termasuk efek trigger.
- Jadwal: Sabtu keempat dan Minggu setelahnya, bukan setiap 30 hari atau Sabtu terakhir.
- Rincian usulan PRD 2.5 menjadi baseline yang ditinjau di Task 1: WIB, target per periode, pemeriksaan manual, terlambat, dan aktivasi tanpa tunggakan retroaktif.
- Servis tidak otomatis menyelesaikan pemeriksaan berkala. Pemeriksaan fisik selesai tidak harus menghasilkan kondisi OK.
- Tidak ada penulisan offline pada MVP. Foto, push notification, checklist teknis khusus, ekspor, dan inventaris suku cadang di luar scope.
- Kode, konfigurasi rahasia, APK, dan `.git` proyek lama tidak disalin ke proyek baru.
- Database produksi sama dengan MGRS; local/QA adalah lingkungan uji terisolasi, bukan database operasional baru.
- Semua perintah implementasi di bawah dijalankan hanya setelah pengguna meminta pelaksanaan. Penyusunan plan ini tidak menjalankan scaffold, migrasi, commit, atau deploy.

## 1. Kondisi awal dan temuan yang membentuk urutan kerja

Workspace baru saat perencanaan hanya berisi PRD. Framework, repo Git baru, schema live, device target, deadline, dan distribusi belum dikunci.

Source lama yang dibaca ulang pada 6 September 2026:

| Referensi relatif terhadap `C:\Users\ogi\mgrs-release` | Bukti dan implikasi |
| --- | --- |
| `lib/data/services/supabase_auth_service.dart` | Login memakai Edge Function `flutter-auth-login` dengan `identifier` dan `password`; jangan menggantinya dengan asumsi email/password standar |
| `lib/data/services/supabase_inventory_service.dart` | Lookup stiker memakai `master_komponen.nomor_stiker`; cek barcode nyata dan keunikannya sebelum parser dikunci |
| `lib/domain/models/domain_enums.dart` | Memuat tiga jenis komponen, empat role, lima kondisi, serta kelayakan `Ya`/`Tidak` |
| `lib/data/services/supabase_maintenance_service.dart` | Insert riwayat dan update master terpisah; ikut menulis `status_penggunaan`; fungsi ini tidak boleh dipakai ulang langsung |
| `lib/domain/auth/route_permissions.dart` | Route pemeriksaan/servis lama hanya Admin dan Tim Service; izin database untuk Tim Pemasangan belum terbukti |
| `lib/domain/models/checking_and_audit.dart` | Riwayat memakai stiker dan memiliki metadata pemeriksaan; periodisasi dan idempotensi belum terbukti tersedia |

**Dua batas penting yang wajib diuji, bukan diasumsikan:**

1. Trigger penambah nomor versi hanya membantu mendeteksi perubahan sebelum transaksi baru. Trigger itu tidak membuat klien lama yang mengirim update tanpa versi otomatis mendeteksi data basi. Jaminan konflik untuk seluruh penulis membutuhkan kontrak semua penulis atau keputusan scope yang eksplisit.
2. Dua aplikasi dengan user/JWT dan role database yang sama tidak dapat dibedakan secara aman hanya dengan nama aplikasi, user-agent, atau publishable key. RPC dapat membatasi mutasinya sendiri, tetapi tidak otomatis mencabut hak direct-update yang sudah dimiliki sesi legacy. Jika PRD menuntut pembatasan hak sesi secara penuh, desain akses bersama harus diselesaikan di Gate G0; jangan mengklaim pembatasan UI sebagai keamanan server.

## 2. Urutan fase dan gerbang penerimaan

| Fase | Task | Hasil | Syarat melanjutkan |
| --- | --- | --- | --- |
| 0 — Kontrak | 1–2 | Keputusan platform, audit DB, kontrak integrasi | G0: keputusan produk dan teknis yang memengaruhi write path selesai |
| 1 — Backend aman | 3–5 | Lingkungan uji, akses baca, transaksi pemeriksaan/servis | G1: role, atomisitas, konflik, idempotensi, invariant penggunaan lulus |
| 2 — Kalender server | 6 | Periode, snapshot target, scheduler, penyelesaian tugas | G2: kalender dan recovery job lulus tanpa ketergantungan aplikasi dibuka |
| 3 — Aplikasi baca | 7–8 | Login, navigasi, scan/manual, detail | G3: tiga role dan scanner nyata bekerja pada device target |
| 4 — Pencatatan | 9–10 | Pemeriksaan dan servis terhubung backend | G4: alur simpan dan kegagalannya teramati end-to-end |
| 5 — Monitoring pekerjaan | 11–12 | Berkala, filter, riwayat | G5: status tugas dan riwayat konsisten lintas pengguna |
| 6 — Pilot dan rilis | 13–14 | QA lintas aplikasi, performa, paket rilis | G6: seluruh AC wajib lulus; deployment mengikuti persetujuan rilis |

Urutan default dikerjakan satu task sampai gate-nya selesai. Task klien tidak boleh menulis ke produksi sambil menunggu gate backend. Semua checklist di bawah adalah pekerjaan yang akan dilakukan, bukan laporan progress.

## 3. Peta file dan tanggung jawab

Semua path task relatif terhadap `C:\Users\ogi\MGRS-Maintenance`, kecuali diberi label referensi. Nama file baru adalah rancangan, bukan klaim sudah ada.

| Area | File yang akan dibuat | Tanggung jawab |
| --- | --- | --- |
| Keputusan | `docs/decisions/001-platform-and-product.md`, `002-shared-database.md` | Platform, aturan detail, batas hak akses dan write path |
| Kontrak | `docs/contracts/database-audit.md`, `maintenance-api.md`, `schema-manifest.json` | Metadata DB, RPC dan hasil, kepemilikan migrasi |
| Bukti | `docs/evidence/implementation-ledger.md`, `phase-0.md` sampai `phase-6.md` | Perintah, exit code, artifact, scope, keterbatasan |
| DB | `supabase/config.toml`, `supabase/migrations/`, `supabase/tests/database/` | Baseline uji, tambahan skema kompatibel, pengujian server |
| Konfigurasi | `config/qa.example.json`, `.gitignore`, `pubspec.yaml`, `pubspec.lock` | Konfigurasi publik contoh dan dependensi terpilih |
| App | `lib/main.dart`, `lib/app/app.dart`, `router.dart`, `app_config.dart`, `app_theme.dart` | Bootstrap, route guard, konfigurasi dan tampilan dasar |
| Auth | `lib/features/auth/auth_repository.dart`, `auth_controller.dart`, `login_screen.dart` | Login existing, sesi, role aktif, logout |
| Komponen | `lib/features/components/component.dart`, `component_repository.dart`, `component_detail_screen.dart` | Identitas, lookup terbatas, kondisi dan detail |
| Scanner | `lib/features/scan/scan_controller.dart`, `scan_screen.dart` | Kamera, hasil satu kali, manual fallback, lifecycle |
| Pencatatan | `lib/features/maintenance/maintenance_command.dart`, `maintenance_repository.dart`, `submission_controller.dart`, `checking_screen.dart`, `service_screen.dart` | Form, validasi, request stabil, mutasi melalui RPC |
| Jadwal | `lib/features/schedule/monthly_period.dart`, `schedule_repository.dart`, `schedule_screen.dart` | DTO waktu server, tugas, filter, pembukaan form periode |
| Riwayat | `lib/features/history/history_entry.dart`, `history_repository.dart`, `history_screen.dart`, `history_detail_screen.dart` | Timeline, filter, pagination, koreksi baru |
| UI bersama | `lib/shared/async_state_view.dart`, `condition_badge.dart`, `condition_fields.dart` | Loading/error/kosong, label status dan field kondisi |
| Verifikasi | `test/`, `integration_test/maintenance_flow_test.dart`, `integration_test/shared_database_test.dart` | Uji perilaku, alur aplikasi dan interop |

Gunakan model dan repository langsung per fitur; tidak membuat lapisan generik service/use-case terpisah untuk setiap operasi satu baris. Nama route produk yang direncanakan: `/login`, `/scan`, `/components/:id`, `/components/:id/check`, `/components/:id/service`, `/schedule`, `/history`, `/history/:eventId`. Aplikasi baru tidak meniru route `/dashboard/orderan` milik legacy.

## 4. Kontrak antartask

### 4.1 Bentuk data yang harus dikunci di Task 2

ID pada wire adalah string opaque. Tipe kolom database sebenarnya dibaca dari metadata; jangan menganggap String Dart berarti UUID PostgreSQL.

| DTO | Field wajib dan maknanya |
| --- | --- |
| `Component` | `id`, `code`, `kind`, `condition`, `usable`, `impairedFunction`, `note` nullable, `version` string, `lastCheckingAt` nullable, `lastServiceAt` nullable |
| `MonthlyPeriod` | `id` berformat YYYY-MM, `opensAt`, `closesAt` eksklusif, `serverNow`, `snapshotState` |
| `ScheduleTask` | `id`, `periodId`, identitas snapshot komponen, `status`, `completedEventId` nullable, `completedAt` nullable |
| `MaintenanceCommand` | `requestId`, `componentId`, `expectedVersion`, `activity`, `condition`, `usable`, `impairedFunction`, `eventNote`, `summaryAction`, `summaryText`, `taskId`, `problem`, `action`, `correctsEventId`, `correctionReason` |
| `SubmissionReceipt` | `eventId`, `requestId`, `componentId`, `version`, `recordedAt`, `completedTaskId` nullable |
| `HistoryEntry` | `eventId`, identitas komponen, `activity`, `before` nullable, `after`, petugas, `recordedAt`, `periodId` nullable, detail pemeriksaan/servis, relasi koreksi nullable |
| `Page<T>` | `items`, `nextCursor` nullable; cursor opaque dan terkait filter |

`activity` adalah `manual_check`, `periodic_check`, atau `service`. `taskId` wajib hanya untuk periodic_check. `problem`/`action` wajib untuk service. `correctsEventId` dan `correctionReason` harus berpasangan jika pengguna sedang membuat koreksi. Foto, biaya, identitas petugas, dan tanggal mundur tidak menjadi payload klien MVP.

`summaryAction` adalah `keep`, `replace`, atau `clear`: catatan kejadian tidak otomatis menghapus ringkasan master. `replace` memerlukan `summaryText`; `clear` adalah tindakan eksplisit. Jika produk memilih form tanpa pengelolaan ringkasan di Task 1, selalu kirim `keep` dan revisi layar sebelum implementasi.

Contoh payload QA yang lengkap, tanpa data produksi:

```json
{
  "requestId": "a109b89d-293c-45f1-8599-a617ec017100",
  "componentId": "fixture-kepala-001",
  "expectedVersion": "7",
  "activity": "manual_check",
  "condition": "Rusak Ringan",
  "usable": "Tidak",
  "impairedFunction": "Putaran tidak stabil",
  "eventNote": "Hasil pemeriksaan petugas QA",
  "summaryAction": "replace",
  "summaryText": "Perlu pemeriksaan lanjutan",
  "taskId": null,
  "problem": null,
  "action": null,
  "correctsEventId": null,
  "correctionReason": null
}
```

### 4.2 Endpoint rancangan

Semua endpoint berikut belum ada dan dibuat hanya sesudah audit menyatakan tidak bertabrakan dengan fungsi existing. Kontrak disimpan di `docs/contracts/maintenance-api.md`.

| Endpoint | Input | Output |
| --- | --- | --- |
| Auth existing `flutter-auth-login` | `identifier`, `password` | Respons sesi sesuai kontrak existing yang diverifikasi |
| RPC `maintenance_lookup_component` | `p_code text` | Maksimal dua kandidat `Component`; nol berarti tidak ditemukan |
| RPC `maintenance_get_component` | `p_component_id text` | Satu `Component` atau not_found |
| RPC `maintenance_submit` | `p_command jsonb` | Satu `SubmissionReceipt` |
| RPC `maintenance_request_result` | `p_request_id uuid` | Receipt milik user aktif yang sama, atau null |
| RPC `maintenance_list_tasks` | `p_period_id text`, `p_kind text` nullable, `p_status text` nullable, `p_code text` nullable, `p_cursor text` nullable, `p_limit integer` | Periode dengan waktu server, ringkasan dan `Page<ScheduleTask>` |
| RPC `maintenance_list_history` | `p_component_id text` nullable, `p_activity text` nullable, `p_from timestamptz` nullable, `p_until timestamptz` nullable, `p_cursor text` nullable, `p_limit integer` | `Page<HistoryEntry>` |
| RPC `maintenance_get_history` | `p_event_id text` | Satu `HistoryEntry` |
| Fungsi internal `maintenance_generate_periods` | `p_now timestamptz` untuk test internal | Jumlah periode/target yang dibuat; tidak dapat dipanggil oleh sesi aplikasi |

Batas halaman default 30, maksimum 100; interval tanggal menggunakan awal inklusif dan akhir eksklusif. Filter kode memakai pencocokan literal, bukan interpolasi query. Klasifikasi kode kabel hanya boleh memakai metadata minimum apabila izin baca memperbolehkan; jangan membuka seluruh data kabel untuk memberi pesan di luar cakupan.

Error domain: `unauthenticated`, `forbidden`, `not_found`, `ambiguous_code`, `invalid_input`, `conflict`, `request_mismatch`, `task_not_open`, `task_already_completed`, `component_unavailable`. Transport timeout/network dipetakan klien secara terpisah. Error tak dikenal menampilkan pesan umum, bukan pesan SQL. Validasi gagal tidak meninggalkan perubahan database.

## 5. Task implementasi

### Task 1 — Kunci platform dan aturan produk (Fase 0)

**Files:** Create `docs/decisions/001-platform-and-product.md`, `docs/evidence/implementation-ledger.md`. Read `PRD.md`; perubahan PRD hanya untuk keputusan pengguna yang benar-benar diberikan.

**Consumes:** keputusan percakapan dan usulan PRD. **Produces:** baseline platform, aturan detail, dan daftar gerbang produk.

- [ ] Catat keputusan perangkat kerja: Android/iOS/web, ketersediaan device pilot, dan metode distribusi. Pertanyaan platform yang masih belum terjawab tidak dianggap sebagai persetujuan Flutter.
- [ ] Jika Flutter dipilih, tentukan platform build yang benar-benar dibutuhkan; jangan menghasilkan lima platform desktop/web tambahan secara default. Jika teknologi lain dipilih, ganti peta file dan perintah klien pada plan ini sebelum Task 7.
- [ ] Tinjau aturan PRD: WIB; manual sebelum jendela tidak menyelesaikan bulanan; servis tidak otomatis menyelesaikan; komponen Hilang tetap terbuka; koreksi adalah catatan baru; akses hanya tiga role.
- [ ] Tetapkan perlakuan ringkasan master dan biaya servis. Jika legacy membutuhkan angka biaya, jangan memasukkan nol untuk “belum dicatat”. Audit harus menemukan representasi unknown yang kompatibel, atau keputusan produk harus menyelesaikannya sebelum servis diimplementasi.
- [ ] Catat kriteria performa pilot, identitas build berbeda dari MGRS, dan kebutuhan tampilan minimum. Jangan menganggap desain Paper lama otomatis menjadi kontrak visual aplikasi baru.
- [ ] Isi ledger awal: semua fase `not_started`, keputusan yang sudah dikunci, keputusan yang masih menunggu, dan artefak acuan. Tidak memerlukan unit test untuk dokumen ini.

**Gate:** keputusan platform dan aturan yang mengubah perilaku selesai dicatat. Kalau hanya pilihan framework yang belum selesai, Task 2 dapat berjalan; Task 7 tidak boleh dimulai.

### Task 2 — Audit database dan tutup kontrak lintas aplikasi (Fase 0)

**Files:** Create `docs/contracts/database-audit.md`, `docs/contracts/schema-manifest.json`, `docs/contracts/maintenance-api.md`, `docs/decisions/002-shared-database.md`, `supabase/inspection/metadata.sql`, `docs/evidence/phase-0.md`.

**Consumes:** Task 1, source legacy yang disebut pada bagian 1, akses database read-only. **Produces:** nama/tipe schema nyata, baseline reproduksibel, kontrak API final, pemilik migrasi, keputusan akses dan konflik seluruh penulis.

- [ ] Pastikan project Supabase target dan pemilik deployment schema tanpa mencetak credential. Periksa tabel komponen/riwayat/profil, enum, FK, constraint, indeks, RLS, grants, trigger, login function, serta semua penulis kondisi yang diketahui.
- [ ] Simpan query metadata berikut dalam `supabase/inspection/metadata.sql`; jalankan melalui koneksi read-only yang sudah dikonfigurasi sebagai service `mgrs_maintenance_audit`.

```sql
begin read only;
select table_name, column_name, data_type, udt_name, is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in ('profiles', 'master_komponen', 'riwayat_checking_komponen', 'riwayat_service', 'audit_log')
order by table_name, ordinal_position;

select tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename in ('profiles', 'master_komponen', 'riwayat_checking_komponen', 'riwayat_service', 'audit_log');

select c.relname as table_name, t.tgname, pg_get_triggerdef(t.oid) as definition
from pg_trigger t join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and not t.tgisinternal
  and c.relname in ('master_komponen', 'riwayat_checking_komponen', 'riwayat_service');

select count(*) as duplicated_sticker_groups
from (select nomor_stiker from public.master_komponen
      group by nomor_stiker having count(*) > 1) d;
rollback;
```

```bash
psql 'service=mgrs_maintenance_audit' -X -v ON_ERROR_STOP=1 -f supabase/inspection/metadata.sql
```

Expected: exit 0; metadata empat kontrak inti terbaca dan hitungan duplikasi tersedia. Jika akses tidak ada, catat fakta itu; jangan mengubah query menjadi koneksi berhak tinggi tanpa kebutuhan. Query di atas adalah probe awal, bukan audit lengkap constraint/grants/function body. Simpan hasil audit yang sudah disanitasi; definisi function dapat mengandung konfigurasi sensitif.

- [ ] Verifikasi payload login, format barcode ketiga jenis, dan relasi riwayat. Gunakan data QA/sampel tersanitasi; jangan mengekspor semua data produksi.
- [ ] Putuskan jalur migrasi: repo ini menyimpan proposal/fixture; jika schema produksi dimiliki repo lain, catat path repo pemilik, nomor migrasi sebenarnya, dan prosedur apply. Jangan membuat dua histori migrasi yang bersaing.
- [ ] Uji dan putuskan INT-04: setiap write path harus membawa versi atau memiliki mekanisme konflik yang terbukti. Jika klien lama tetap melakukan update tanpa versi, catat blocker interop. Perubahan klien lama memerlukan scope tersendiri; tidak diam-diam dikerjakan dalam proyek ini.
- [ ] Putuskan kebutuhan keamanan sesi: uji bahwa direct update tidak dapat melewati hak aplikasi yang diinginkan. Jika hak lama tidak dapat dibatasi tanpa mengganggu MGRS, dokumentasikan desain akses lintas aplikasi untuk ditinjau; jangan menambah policy permisif yang meluaskan role secara global.
- [ ] Pastikan trigger tidak menulis `status_penggunaan` dari perubahan kondisi baru. Jika berbenturan, siapkan perubahan terbatas dan uji regresi backend; jangan menonaktifkan semua trigger.
- [ ] Periksa apakah ada histori membership master yang bisa merekonstruksi target tepat pada pembukaan periode. Jika tidak ada, tetapkan registry temporal tambahan pada Task 6. Cek biaya nullable/default dan pembaca legacy sebelum kontrak servis ditutup.
- [ ] Bekukan nama RPC pada bagian 4, tipe data nyata, migration ownership, dan keputusan gate di `phase-0.md`.

**G0:** tidak ada kontradiksi terbuka antara batas tanpa pemasangan, hak server, jaminan konflik seluruh penulis, dan kompatibilitas data lama. Tanpa G0, boleh menyelesaikan dokumen/fixture; tidak boleh mengaktifkan penulisan pada database bersama.

### Task 3 — Buat lingkungan uji dan baseline schema yang bisa direproduksi (Fase 1)

**Files:** Create `supabase/config.toml`, `supabase/migrations/20260906000100_maintenance_baseline.sql`, `supabase/seed.sql`, `supabase/tests/database/001_baseline.test.sql`, `.gitignore`, `docs/evidence/phase-1.md`.

**Consumes:** schema-manifest Task 2. **Produces:** database local/QA berkontrak sama, data sintetis, serta runner pgTAP.

- [ ] Setelah pelaksanaan disetujui, buat repository Git terpisah jika folder ini belum berada dalam repo. Verifikasi root sebelum `git init`; jangan menginisialisasi di `mgrs-release`. Hindari `git add .`; stage file milik task secara eksplisit.
- [ ] Catat versi Flutter/Dart, Supabase CLI, PostgreSQL, dan runtime local yang tersedia. Instal dependency hanya pada tahap implementasi dan kunci versi kompatibel yang dipakai; versi lama di `pubspec` reference bukan perintah upgrade otomatis.
- [ ] Buat baseline minimal dari schema yang diaudit beserta constraint, trigger, dan kebijakan yang relevan. Tandai file baseline sebagai bootstrap lokal, bukan migrasi yang di-apply ulang ke produksi existing.
- [ ] Buat fixture sintetis untuk empat role, akun nonaktif, tiga jenis, setiap kondisi/status penggunaan, kode tidak dikenal, catatan lama tanpa before-value, serta riwayat service/checking. Jangan memakai password pengguna nyata.
- [ ] Tambahkan test baseline yang gagal jika tabel/enum/policy berbeda dari manifest; buktikan gagal terhadap fixture yang sengaja salah, lalu perbaiki fixture, bukan melemahkan test.

```bash
supabase start
supabase db reset --local
supabase test db
```

Expected: database lokal berhasil direkonstruksi dan test baseline lulus. `db reset --local` hanya untuk database local yang dibuat task ini; tidak pernah menggunakan `--linked` atau URL produksi. Docker/runtime yang belum tersedia dicatat sebagai prasyarat, bukan disamarkan sebagai test lulus.

**Gate:** pengembang lain dapat mengulang baseline dari file tanpa mengambil data produksi. Commit hanya file task setelah hasil diverifikasi, tanpa credential atau output raw.

### Task 4 — Akses server dan pembacaan komponen terbatas (Fase 1)

**Files:** Create `supabase/migrations/20260906000200_maintenance_access_and_reads.sql`, `supabase/tests/database/002_access.test.sql`, `supabase/tests/database/003_component_reads.test.sql`.

**Consumes:** schema Task 3, role dan endpoint Task 2. **Produces:** RPC lookup/detail, pengecekan profil aktif dan role, DTO Component berversi.

- [ ] Tulis kasus gagal: anonymous, PIC, akun nonaktif, profil hilang, perubahan role setelah login, kode tidak dikenal, kode ambigu, serta respons yang tidak berisi data order/pengguna lain.
- [ ] Implementasikan satu helper server privat untuk mengambil identitas dari `auth.uid()` dan memeriksa profil aktif dengan tiga role yang tepat. Pengecekan selalu dilakukan sebelum baca/tulis dan sebelum pengembalian hasil replay.
- [ ] Implementasikan lookup literal yang mengembalikan paling banyak dua kandidat dan detail by ID. Sertakan versi server yang dapat dipakai Task 5; ambil tanggal pemeriksaan dan servis secara terpisah.
- [ ] Batasi SELECT dan EXECUTE secara eksplisit. Jika menggunakan SECURITY DEFINER, gunakan schema-qualified objects, search_path aman, owner terbatas, dan pemeriksaan identitas di dalam fungsi. Jangan mengandalkan RLS saja untuk fungsi yang memiliki privilege berbeda.
- [ ] Terapkan keputusan akses direct-write dari G0; uji bypass lewat REST/table API selain lewat RPC. Jangan mencabut privilege legacy secara luas hanya agar test aplikasi baru hijau.
- [ ] Jalankan test berikut dan buktikan lookup tidak membaca seluruh master atau seluruh riwayat.

```bash
supabase test db supabase/tests/database/002_access.test.sql
supabase test db supabase/tests/database/003_component_reads.test.sql
```

Expected: seluruh role/case di atas sesuai kontrak; ketiga role yang diizinkan dapat membaca, sisanya ditolak. Commit migration/read tests secara kohesif.

### Task 5 — Transaksi pemeriksaan dan servis tanpa efek pemasangan (Fase 1)

**Files:** Create `supabase/migrations/20260906000300_maintenance_transactions.sql`, `supabase/tests/database/004_transactions.test.sql`, `supabase/tests/database/005_replay_and_conflicts.test.sql`, `supabase/tests/database/006_legacy_compatibility.test.sql`.

**Consumes:** akses/versi Task 4 dan command Task 2. **Produces:** `maintenance_submit`, `maintenance_request_result`, event ledger append-only, riwayat legacy yang kompatibel.

- [ ] Buat test rollback untuk kegagalan insert riwayat, update master, audit dan validasi. Buat fixture dua koneksi database untuk konflik; satu transaksi test serial tidak membuktikan concurrency.
- [ ] Buat ledger event/request tambahan dengan actor, request ID, fingerprint payload, ID master stabil, before/after, timestamp server, jenis kegiatan, relasi correction dan receipt. Unique key minimal `(actor_id, request_id)`; payload berbeda dengan ID yang sama menghasilkan `request_mismatch`.
- [ ] Urutan transaksi: verifikasi role → klaim/cek request idempotent → lock master → bandingkan expectedVersion → validasi payload → ambil before → tulis riwayat yang sesuai dan event → update hanya field diizinkan → simpan receipt → commit. Kegagalan membatalkan seluruh unit kerja. Periodic_check ditolak sampai Task 6 mengaktifkan validasi task dalam transaksi yang sama.
- [ ] Replay permintaan identik yang sudah berhasil mengembalikan receipt awal setelah otorisasi user aktif, sebelum pengecekan expectedVersion lama. Cegah race dua request identik dengan unique key/locking dan satu hasil committed.
- [ ] Versi master harus dinaikkan pada setiap perubahan relevan dari semua write path sesuai keputusan G0; test legacy-update dahulu lalu submit baru, dan submit baru dahulu lalu stale legacy-update. Jangan mengklaim keduanya aman jika kasus kedua tidak dapat dideteksi.
- [ ] Terapkan enum/kelayakan, gangguan wajib untuk non-OK, catatan temuan, summary keep/replace/clear, dan waktu server. Petugas tidak diambil dari payload. Riwayat koreksi menunjuk catatan asli dari komponen sama dan tidak mengeditnya.
- [ ] Adapter riwayat menulis `riwayat_checking_komponen` atau `riwayat_service` supaya hasil terlihat oleh pembaca MGRS. Field biaya mengikuti keputusan Task 2; unknown tidak dipalsukan sebagai biaya nol.
- [ ] Uji master dengan semua nilai `status_penggunaan`, snapshot data relasi operasional sebelum/sesudah, serta trigger nyata dari baseline. Hasil harus identik untuk field dan relasi yang tidak boleh berubah.

```bash
supabase test db supabase/tests/database/004_transactions.test.sql
supabase test db supabase/tests/database/005_replay_and_conflicts.test.sql
supabase test db supabase/tests/database/006_legacy_compatibility.test.sql
```

**G1:** receipt, before/after, riwayat legacy, role, atomisitas, idempotensi, serta konflik lintas penulis terbukti. Catat failure injection dan hasil dua koneksi dalam `phase-1.md`; jangan menyebut test serial sebagai bukti konkurensi. Commit artefak task setelah gate.

### Task 6 — Kalender dan target pemeriksaan bulanan di server (Fase 2)

**Files:** Create `supabase/migrations/20260906000400_maintenance_schedule.sql`, `supabase/tests/database/007_calendar.test.sql`, `supabase/tests/database/008_schedule_tasks.test.sql`, `supabase/tests/database/009_scheduler_recovery.test.sql`, `docs/evidence/phase-2.md`. Modify transaksi Task 5 untuk periodic_check.

**Consumes:** G1, aturan jadwal Task 1. **Produces:** periode, target frozen, internal generator, list tasks, penyelesaian periodik atomik.

- [ ] Tulis uji kalender berikut sebelum function kalender. Gunakan function publik hanya jika aksesnya benar-benar diperlukan; helper kalender default ditempatkan pada schema privat `maintenance_private` yang dibuat migration.

```sql
begin;
select plan(4);
select is(maintenance_private.fourth_saturday('2026-09-01'::date), '2026-09-26'::date, 'September');
select is(maintenance_private.fourth_saturday('2026-10-01'::date), '2026-10-24'::date, 'Not final Saturday');
select is(maintenance_private.fourth_saturday('2027-02-01'::date), '2027-02-27'::date, 'February');
select is(maintenance_private.fourth_saturday('2028-02-01'::date), '2028-02-26'::date, 'Leap year');
select * from finish();
rollback;
```

- [ ] Jalankan untuk membuktikan function belum ada, lalu implementasikan helper berikut dan ulang test. Fixture pgTAP/search_path disiapkan pada Task 3.

```sql
create function maintenance_private.fourth_saturday(p_month date)
returns date
language sql immutable strict
set search_path = ''
as $$
  select date_trunc('month', p_month)::date
    + ((6 - extract(dow from date_trunc('month', p_month))::integer + 7) % 7)
    + 21;
$$;
```

- [ ] Bentuk `opensAt` dari tanggal Sabtu pada zona `Asia/Jakarta`; `closesAt` dari tanggal Senin pukul 00.00 di zona yang sama. Simpan timestamptz dan gunakan serverNow, bukan jam perangkat. Tanggal bulan yang tidak valid ditolak pada boundary input.
- [ ] Buat periode unik YYYY-MM, target unik `(component_id, period_id)`, serta relasi ke satu event penyelesai. Bekukan identitas snapshot sehingga perubahan stiker atau penghapusan master tidak mengubah riwayat target. Jangan menambah FK yang membuat penghapusan master legacy tiba-tiba gagal tanpa keputusan G0.
- [ ] Tetapkan activation_at dan periode pertama yang opening-nya >= activation_at. Sebelum opening, tampilkan jadwal mendatang sebagai preview, bukan jumlah target final. Jangan membuat backlog sebelum activation.
- [ ] Jalankan generator terjadwal server setiap menit dengan cek opening/idempotensi di dalam transaksi. Sesi aplikasi tidak boleh mengirim p_now atau mengeksekusi generator. Simpan heartbeat/failure job untuk operator; ini bukan push notification petugas.
- [ ] Jika sumber lama tidak memiliki membership as-of yang terpercaya, buat registry temporal minimal sejak activation yang mencatat masuk/keluar master dari semua penulis. Job yang terlambat merekonstruksi target as-of opening dari registry itu, bukan mengambil daftar saat retry. Bootstrap registry, trigger membership dan activation dilakukan konsisten; transaksi master yang sedang berjalan pada batas waktu harus ikut diuji.
- [ ] Jika target as-of tidak bisa dibuktikan akibat gap registry, tandai snapshot gagal dan tampilkan kegagalan sistem; jangan mengarang target lalu menyebut jadwal berhasil.
- [ ] Tambahkan ke `maintenance_submit`: lock task setelah master dengan urutan lock tetap; periksa komponen cocok, opening sudah lewat, belum selesai, period dipilih jelas, dan pemeriksaan fisik sah. Simpan completion bersama kondisi/riwayat dalam transaksi yang sama.
- [ ] Status dihitung dari receipt dan batas waktu: terjadwal, perlu diperiksa, terlambat, selesai, selesai terlambat. Hilang/tidak diperiksa fisik tetap tidak selesai; pemeriksaan rusak yang sah dapat selesai. Servis/manual tidak menyelesaikan task.
- [ ] Uji dua petugas menutup task yang sama: pertama sukses; kedua mendapat task_already_completed tanpa write parsial. Jika ingin pemeriksaan tambahan, petugas membuka pencatatan manual baru. Satu event tidak menutup dua task/periode.

```bash
supabase test db supabase/tests/database/007_calendar.test.sql
supabase test db supabase/tests/database/008_schedule_tasks.test.sql
supabase test db supabase/tests/database/009_scheduler_recovery.test.sql
```

**G2:** uji sebelum opening, tepat opening, akhir Minggu, Senin, ganti tahun, lima Sabtu, kabisat, activation tengah bulan, insertion/deletion saat boundary, job terlambat, retry job, dan task ganda lulus. Tidak memalsukan waktu produksi untuk QA. Commit perubahan schedule dan perluasan transaksi sebagai satu perubahan yang diuji.

### Task 7 — Scaffold minimum, login, dan navigasi terlindungi (Fase 3)

**Files:** Create platform terpilih, `pubspec.yaml`, `pubspec.lock`, `config/qa.example.json`, `lib/main.dart`, file `lib/app/` dan `lib/features/auth/` pada peta file, `lib/shared/async_state_view.dart`, `test/features/auth/auth_controller_test.dart`, `test/app/router_test.dart`, `docs/evidence/phase-3.md`.

**Consumes:** keputusan Flutter/target dari Task 1, auth dan akses Task 4. **Produces:** aplikasi login nyata dengan tiga tab dan route guard.

- [ ] Catat baseline folder dan root Git. Scaffold hanya platform yang disepakati. Contoh berikut berlaku jika Task 1 memilih Android; tambahkan iOS hanya jika iOS memang masuk target.

```bash
flutter create --project-name mgrs_maintenance --platforms=android .
flutter pub add supabase_flutter mobile_scanner go_router uuid
flutter pub add 'dev:integration_test:{sdk: flutter}'
```

- [ ] Kunci dependency hasil resolusi, catat versi SDK dan package. Buat app ID yang tidak bertabrakan dengan MGRS. Jangan menyalin `dart_defines.json` legacy.
- [ ] `AppConfig` membaca `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `APP_ENV`; validasi gagal menampilkan kesalahan konfigurasi tanpa membocorkan nilai. `config/*.local.json` dan file kredensial pengujian masuk .gitignore.
- [ ] Buat kontrak `AuthRepository.signIn(identifier, password)`, `signOut()`, `loadActiveProfile()` dan stream perubahan sesi; payload respons mengikuti audit Task 2. Gunakan state loading/authenticated/denied/signedOut/error tanpa menganggap sesi tersimpan pasti masih aktif.
- [ ] Tulis uji perilaku login gagal, role ditolak, sesi kedaluwarsa, profil dinonaktifkan, logout, dan deep link terlindungi. Implementasikan guard dan halaman login hingga uji lulus.
- [ ] Buat tema sederhana dan tiga tab; loading/error/empty tidak berisi data dummy yang dianggap live. Kelola auth refresh saat resume dan sebelum mutasi melalui repository; server tetap otoritas izin.

```bash
flutter analyze --no-pub
flutter test test/features/auth/auth_controller_test.dart test/app/router_test.dart
flutter run --dart-define-from-file=config/qa.local.json
```

Expected: analyzer tidak menghasilkan error baru; test lulus; akun QA tiga role berhasil login dan role terlarang ditolak. Manual: cold start, logout, login gagal, deep link tanpa sesi, dan resume. G3 lengkap setelah Task 8. Commit hanya source/config contoh/test task.

### Task 8 — Scan/manual dan detail kondisi (Fase 3)

**Files:** Create file `lib/features/components/` dan `lib/features/scan/` pada peta, `lib/shared/condition_badge.dart`, `test/features/components/component_repository_test.dart`, `test/features/scan/scan_controller_test.dart`. Modify router Task 7.

**Consumes:** lookup/detail Task 4, auth Task 7. **Produces:** komponen teridentifikasi dengan version dan pilihan pemeriksaan/servis.

- [ ] Definisikan `ComponentRepository.lookupByCode(String code)` mengembalikan nol–dua Component; `getById(String id)` mengembalikan detail terbaru. DTO memetakan enum secara ketat dan string kosong/historis `-` menjadi tampilan kosong tanpa menulis ulang database.
- [ ] Tulis uji code trim sesuai format audit, hasil kosong, ambigu, tipe di luar scope, dan error server. Jangan mengubah huruf besar/kecil atau leading zero jika barcode sebenarnya menganggapnya signifikan.
- [ ] Implementasikan state scanner idle/permission/scanning/resolving/result/error. Gunakan guard satu lookup aktif; ignore frame berulang sampai pengguna memilih scan berikutnya. Stop/dispose kamera pada result, route leave, pause, dan sign-out; tangani resume tanpa memulai dua controller.
- [ ] Form manual tersedia saat izin ditolak. Detail menampilkan tanggal pemeriksaan dan servis terpisah, version internal, catatan dan label kondisi. Refresh tidak membaca order/alokasi dan tidak mengubah database.
- [ ] Sesudah permission error, sediakan tindakan buka pengaturan bila platform mendukung dan tombol input kode. Pengguna dapat kembali tanpa loop dialog izin.

```bash
flutter test test/features/components/component_repository_test.dart test/features/scan/scan_controller_test.dart
flutter run --dart-define-from-file=config/qa.local.json
```

**G3:** pada device nyata, scan satu barcode setiap jenis, ulang frame, barcode tak dikenal, izin ditolak lalu pulih, input manual, background/resume dan keluar layar. Bukti kamera nyata terpisah dari fake controller test. Commit setelah alur baca diamati bekerja.

### Task 9 — Form pemeriksaan dan state penyimpanan (Fase 4)

**Files:** Create `lib/features/maintenance/maintenance_command.dart`, `maintenance_repository.dart`, `submission_controller.dart`, `checking_screen.dart`, `lib/shared/condition_fields.dart`, `test/features/maintenance/checking_test.dart`, `test/features/maintenance/submission_controller_test.dart`, `docs/evidence/phase-4.md`.

**Consumes:** Component/version Task 8, RPC Task 5, task berkala Task 6. **Produces:** alur manual/periodik yang menyimpan receipt dan memperbarui detail setelah berhasil.

- [ ] Definisikan `MaintenanceRepository.submit(MaintenanceCommand command)` dan `findReceipt(String requestId)` menggunakan endpoint bagian 4. Controller menerima repository, memegang satu immutable command per percobaan logis, dan menghasilkan idle/submitting/succeeded/conflict/uncertain/failed.
- [ ] Tulis kasus submit berhasil, double tap, kondisi sama, invalid field, non-OK tanpa catatan, summary keep/clear, cancel dirty form, timeout setelah commit, retry identik, replay payload berbeda, role dicabut, dan konflik versi.
- [ ] Form tidak pre-confirm kondisi baik. Review menampilkan kode, jenis, hasil dan konteks periode. Identitas petugas/timestamp tidak dapat diedit. Catatan koreksi wajib jika correctsEventId hadir.
- [ ] Generate requestId saat pengguna mengonfirmasi payload. Retry timeout memakai ID dan payload sama; lookup receipt sebelum memulai mutasi baru. Setelah pengguna mengubah isian untuk tindakan baru, buat ID baru hanya sesudah hasil permintaan lama diketahui.
- [ ] Saat status uncertain, jangan tampilkan berhasil/gagal definitif; tawarkan “Periksa hasil penyimpanan”. Kalau sesi berakhir, hapus isian sensitif dari memori setelah navigasi login dan arahkan pemeriksaan riwayat sesudah masuk. MVP tidak menjanjikan recovery draft setelah proses aplikasi mati.
- [ ] Refresh component setelah sukses/conflict; cek current role di server. Teks konflik: “Kondisi komponen sudah diperbarui. Periksa data terbaru sebelum menyimpan kembali.” Jangan menimpa diam-diam.
- [ ] Jika periodic_check menemukan task sudah selesai, hentikan simpan tanpa record parsial; tawarkan melihat riwayat atau memulai pemeriksaan manual baru secara eksplisit.

```bash
flutter test test/features/maintenance/checking_test.dart test/features/maintenance/submission_controller_test.dart
flutter run --dart-define-from-file=config/qa.local.json
```

Manual: simpan pemeriksaan tiap jenis, verifikasi receipt dan master/riwayat pada QA, putus jaringan setelah pengiriman, coba ulang, serta dua sesi mengubah komponen sama. Kondisi penggunaan sebelum/sesudah harus sama. Commit ketika bukti alur tulis tersedia.

### Task 10 — Form servis dan koreksi hasil (Fase 4)

**Files:** Create `lib/features/maintenance/service_screen.dart`, `test/features/maintenance/service_test.dart`. Modify route dan repository hanya jika kontrak Task 5 memerlukan pemetaan tambahan.

**Consumes:** shared fields/controller Task 9, activity service Task 5. **Produces:** pencatatan servis kapan saja dengan riwayat dan kondisi aktual.

- [ ] Tulis kasus masalah/tindakan kosong, hasil belum OK, kelayakan invalid, unknown biaya, replay, task berkala tetap terbuka, serta koreksi yang menunjuk komponen berbeda.
- [ ] Buat form masalah, tindakan, hasil kondisi, kelayakan, gangguan, catatan, dan ringkasan sesuai Task 1. Jangan menambahkan antrean wajib dengan filter status_penggunaan=Service.
- [ ] Gunakan submission_controller yang sama untuk request lifecycle; service tidak membawa taskId. Server menolak taskId atau field yang tidak berlaku, bukan mengabaikannya diam-diam.
- [ ] Pemeriksaan akhir tercermin dari konfirmasi hasil di form. Servis yang belum berhasil boleh tercatat dengan kondisi yang sesuai; tidak otomatis mengubah ke OK.
- [ ] Koreksi servis membuat event service baru dengan relasi correction/alasan, menjalankan versi master terbaru, dan tidak mengedit riwayat asli atau status tugas masa lalu.

```bash
flutter test test/features/maintenance/service_test.dart
flutter run --dart-define-from-file=config/qa.local.json
```

**G4:** pemeriksaan dan servis diamati oleh ketiga role pada QA; histori legacy dapat membaca hasil; server tidak mengubah status penggunaan/order/alokasi. Commit setelah observasi ini, bukan hanya widget test.

### Task 11 — Daftar berkala dan penyelesaian terlambat (Fase 5)

**Files:** Create file `lib/features/schedule/` pada peta, `test/features/schedule/schedule_test.dart`, `docs/evidence/phase-5.md`. Modify checking route untuk taskId/periodId yang eksplisit.

**Consumes:** DTO/RPC periode Task 6 dan form Task 9. **Produces:** tab Berkala berbasis waktu server dan target frozen.

- [ ] Tulis test status waktu, filter jenis/status/kode, pagination, preview sebelum opening, snapshot gagal, period lama, timezone perangkat berbeda, dan task yang selesai oleh user lain.
- [ ] Ambil serverNow dan bounds dari RPC, bukan kalkulasi jadwal terpisah di klien. Refresh pada resume, pergantian periode, kembali dari form, serta pada batas opening/closing; timer UI hanya memicu refresh.
- [ ] Tampilkan range Sabtu–Minggu, target final hanya saat snapshot siap, jumlah selesai/terbuka/terlambat yang konsisten untuk periode dan filter, serta daftar komponen. Empty dan error berbeda.
- [ ] Buka detail/form dengan task yang dipilih. Untuk backlog, tampilkan bulan yang akan diselesaikan dan waktu pencatatan aktual. Jangan menandai dua periode selesai dari satu pemeriksaan.
- [ ] Jika komponen hilang/dihapus, pertahankan baris snapshot dan penjelasan tidak dapat diselesaikan; jangan membuka form untuk ID komponen lain sebagai pengganti.
- [ ] Hasil rusak tetap ditandai selesai diperiksa jika memenuhi validasi; kondisi dan status tugas memiliki label terpisah.

```bash
flutter test test/features/schedule/schedule_test.dart
flutter run --dart-define-from-file=config/qa.local.json
```

Manual: QA server memakai clock fixture/test environment yang dikontrol operator, bukan input p_now dari aplikasi. Uji Sabtu–Senin dan dua user melihat completion yang sama. Commit setelah waktu/angka ditinjau di layar.

### Task 12 — Riwayat gabungan dan detail yang bisa ditelusuri (Fase 5)

**Files:** Create `supabase/migrations/20260906000500_maintenance_history_reads.sql`, `supabase/tests/database/010_history.test.sql`, file `lib/features/history/` pada peta, `test/features/history/history_test.dart`.

**Consumes:** ledger/new events dan legacy history Task 5, reader permission Task 4. **Produces:** list/detail history dan entry point koreksi baru.

- [ ] Uji gabungan old/new tanpa duplikasi: satu transaksi baru yang juga menulis tabel legacy tetap hanya tampil satu kali. Ledger menyimpan relasi ke ID riwayat legacy sebagai dasar deduplikasi, bukan kesamaan timestamp/stiker saja.
- [ ] Implementasikan read RPC history dengan cursor stabil berdasarkan recorded_at dan ID tiebreaker. Filter interval inklusif/eksklusif dan activity harus konsisten lintas halaman. User hanya melihat informasi petugas yang dibutuhkan.
- [ ] Riwayat lama yang sebelum/sesudah tidak lengkap menampilkan “Tidak tercatat” untuk before, bukan kondisi master saat ini. Bila relasi stiker historis ambigu, tandai riwayat lama tidak terverifikasi alih-alih mengaitkan ke komponen yang keliru.
- [ ] UI menampilkan manual/berkala/servis, tanggal, petugas, temuan, tindakan, hasil dan relasi koreksi. Action koreksi membuka form baru dengan current component/version; tidak menyediakan DELETE/PATCH catatan lama.
- [ ] Riwayat kosong, gagal, halaman berikutnya gagal, refresh, dan perubahan filter ditangani tanpa mencampur hasil filter sebelumnya.

```bash
supabase test db supabase/tests/database/010_history.test.sql
flutter test test/features/history/history_test.dart
```

**G5:** data QA lama dan baru dapat ditelusuri tanpa count ganda atau tanggal palsu. Task 11 dan 12 berfungsi lintas role/perangkat. Commit setelah history/detail dan koreksi diamati.

### Task 13 — QA integrasi, perangkat, regresi MGRS, dan performa (Fase 6)

**Files:** Create `integration_test/maintenance_flow_test.dart`, `integration_test/shared_database_test.dart`, `docs/qa/mvp-scenarios.md`, `docs/evidence/phase-6.md`. Modify hanya file yang menimbulkan kegagalan scope task.

**Consumes:** G0–G5. **Produces:** bukti release readiness per PRD, tanpa menyamakan browser/test dengan device E2E.

- [ ] Buat integration flow login → lookup → pemeriksaan → receipt → detail → riwayat → servis → berkala, menggunakan data dan akun QA. Test tidak memuat kredensial dalam source. Untuk camera permission dan barcode fisik, gunakan checklist manual perangkat terpisah dari injected barcode test.
- [ ] Siapkan build MGRS reference yang diarahkan ke QA melalui konfigurasi yang disetujui; jangan mengubah source legacy hanya untuk test. Uji membaca kondisi/riwayat baru dan kedua urutan konflik antar aplikasi. Jika reader/writer legacy tidak bisa diuji, interop belum lulus.
- [ ] Jalankan audit seluruh matriks PRD 4.6, mencatat setiap US/INT, role, device, data fixture, waktu, hasil, dan artifact. Uji denial langsung di API, rollback, replay, biaya unknown, serta snapshot job yang terlambat.
- [ ] Uji teks besar, target sentuh, keyboard form, fokus, label kondisi non-warna, loading/empty/error, lifecycle kamera, dan text wrapping pada perangkat target. Jika visual berubah selama perbaikan, ulang QA layar terkait.

```bash
supabase test db
flutter analyze --no-pub
flutter test
flutter devices
flutter test integration_test/maintenance_flow_test.dart -d "$MAINTENANCE_DEVICE_ID" --dart-define-from-file=config/qa.local.json
flutter test integration_test/shared_database_test.dart -d "$MAINTENANCE_DEVICE_ID" --dart-define-from-file=config/qa.local.json
```

`MAINTENANCE_DEVICE_ID` diisi dengan ID nyata hasil flutter devices, bukan contoh literal. QA config menunjuk endpoint yang dapat dicapai perangkat; localhost komputer tidak otomatis dapat dicapai ponsel. Perintah hanya berlaku setelah file test dibuat oleh task ini dan target Flutter disepakati.

- [ ] Ukur minimal 30 pencarian dan 30 penyimpanan per alur yang diklaim, catat perangkat, jaringan, dataset, cold/warm state; hitung p95 dan bandingkan target 3 detik. Catat ukuran APK dan cold launch sebagai baseline, tanpa klaim target ukuran yang belum disepakati.
- [ ] Perbaiki hanya penyebab kegagalan scope, ulang subset terkait dan integration yang terpengaruh. Jangan mengubah expected test untuk menerima bug.

**Gate:** setiap AC wajib memiliki hasil nyata; belum tersedia device/akses QA berarti gate terkait belum terpenuhi, bukan PASS bersyarat. Commit perbaikan dan laporan dengan scope bukti yang jelas.

### Task 14 — Paket rilis, migrasi produksi yang bisa ditinjau, dan handoff (Fase 6)

**Files:** Create `docs/release/runbook.md`, `docs/release/acceptance.md`, `docs/release/release-manifest.json`; output build pada folder standar platform terpilih.

**Consumes:** Task 13 lulus, pemilik migrasi Task 2, keputusan distribusi Task 1. **Produces:** paket yang dapat ditinjau dan prosedur aktivasi/deaktivasi tanpa menghapus data.

- [ ] Siapkan migrasi tambahan produksi sesuai repo pemilik. Baseline schema local tidak boleh diterapkan ke database existing. Lakukan rehearsal QA dari snapshot schema tersanitasi yang setara dan simpan checksum/urutan migrasi.
- [ ] Runbook memuat verifikasi backup, endpoint yang berubah, hak role sebelum/sesudah, jadwal activation_at, health check job, uji status_penggunaan, dan rollback berupa penghentian fitur/job baru tanpa menghapus riwayat atau tabel bersama.
- [ ] Buat build release dari commit yang diverifikasi dengan signing/distribusi terpilih. Untuk Android, perintah rencana:

```bash
flutter build apk --release --dart-define-from-file=config/release.local.json
git diff --check
```

Expected: build exit 0, artefak `build/app/outputs/flutter-apk/app-release.apk`, dan tidak ada whitespace error. Signing debug tidak dianggap paket produksi. Release config hanya memuat konfigurasi klien yang sah, bukan service-role atau akun test. iOS memerlukan build/signing/QA di macOS bila iOS dipilih; Android tidak membuktikan iOS.

- [ ] Manifest mencatat full commit SHA, versi build, checksum artifact, environment target tanpa secret, versi toolchain, migration checksums, dan lokasi laporan QA. Jika ada perubahan setelah QA, uji ulang bagian yang terpengaruh terhadap SHA yang akan dirilis.
- [ ] Sajikan artifact dan rencana perubahan database yang konkret untuk keputusan rilis. Jangan deploy/push/mengubah produksi hanya karena plan disetujui untuk implementasi.
- [ ] Setelah rilis benar-benar diotorisasi, apply melalui pemilik schema, lakukan smoke test read dan satu transaksi komponen uji yang disepakati, pantau job jadwal, lalu dokumentasikan hasil aktual. Jangan menggunakan komponen produksi sembarang sebagai fixture.

**G6:** kriteria PRD 5.3 lulus, artifact terpasang pada target pilot, pembaruan terbaca di MGRS, dan batas tanpa pemasangan tetap utuh. Jika hanya paket sudah dibangun tetapi belum diaktifkan, laporkan “siap ditinjau untuk rilis”, bukan “sudah rilis”.

## 6. Coverage PRD → Task

| Kebutuhan | Task pelaksana | Bukti penerimaan |
| --- | --- | --- |
| US-01 tiga role/profil aktif | 2, 4, 7, 13 | API denial dan login nyata |
| US-02 scan/manual | 4, 8, 13 | Ketiga barcode + permission/device lifecycle |
| US-03 kondisi/detail | 4, 8, 12 | Detail live, timestamp history terpisah |
| US-04 pemeriksaan | 5, 9, 13 | Transaksi, form, konflik dan replay |
| US-05 servis | 2, 5, 10, 13 | Hasil servis, biaya kompatibel, tanpa auto-completion |
| US-06 jadwal | 6, 11, 13 | Kalender, job recovery dan period completion |
| US-07 riwayat/koreksi | 5, 9, 10, 12 | Before/after, old-data honesty, append-only correction |
| INT-01 identitas | 2, 4, 8, 12 | Keunikan barcode dan relasi legacy |
| INT-02 batas mutasi | 2, 5, 13 | Diff field/relasi operasional dan trigger |
| INT-03 atomisitas | 5, 6, 13 | Failure injection semua bagian transaksi |
| INT-04 konflik seluruh penulis | 2, 5, 13 | Dua koneksi dan kedua urutan legacy/new |
| INT-05 idempotensi | 5, 9, 10, 13 | Timeout-after-commit, replay identik/mismatch |
| INT-06 periode dan tugas | 6, 11 | Snapshot as-of, uniqueness, activation |
| INT-07 nilai kondisi | 1, 2, 5, 9, 10 | Validasi client/server dan enum existing |
| INT-08 catatan | 5, 9, 12 | keep/replace/clear dan placeholder historis |
| NFR ringan, aksesibilitas, kamera | 7–8, 11–13 | Pagination, lifecycle, device QA, p95 |
| Distribusi/interop | 13–14 | QA lintas aplikasi, build/signing, manifest |

## 7. Prosedur pencatatan kemajuan

Pada awal setiap task, baca ledger dan file yang akan disentuh. Perbarui status task hanya sesudah bukti tersimpan. Format setiap entri: task, commit SHA bila tersedia, environment, perintah, exit code, perilaku yang diamati, artifact, dan hal yang belum dibuktikan.

Commit dilakukan per deliverable yang sudah diverifikasi dan hanya ketika implementasi sedang dijalankan. Tidak mengubah source legacy, tidak memasukkan credential, tidak melakukan push otomatis. Tidak ada reviewer/subagent wajib untuk penyusunan plan ini; self-review dokumen dilakukan langsung.

Eksekusi berikutnya dapat memakai `executing-plans` dalam sesi yang sama. Jika pengguna secara eksplisit memilih kerja dengan subagent, bagi kepemilikan berdasarkan task/file dan tetap penuhi gate server/perangkat sebelum integrasi.

## 8. Referensi teknis dan batas verifikasi

Dokumentasi resmi diperiksa 6 September 2026. Rancangan transaksi dan schema di atas adalah keputusan proyek yang harus diuji terhadap schema nyata, bukan pernyataan bahwa backend MGRS sudah mendukungnya.

- Fungsi database dapat dipanggil melalui API; hak fungsi dan SECURITY DEFINER memerlukan pengaturan eksplisit. [Supabase Database Functions](https://supabase.com/docs/guides/database/functions).
- Akses tabel menggunakan kebijakan server; konsekuensi role dan bypass harus diperiksa terhadap kebijakan existing. [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security).
- Supabase Cron mendukung penjadwalan pekerjaan server. Pemilihan interval satu menit dan recovery target as-of adalah rancangan produk ini. [Supabase Cron](https://supabase.com/docs/guides/cron), [Quickstart](https://supabase.com/docs/guides/cron/quickstart).
- Verifikasi perintah database dilakukan terhadap CLI yang dipasang saat Task 3. [Supabase CLI test db](https://supabase.com/docs/reference/cli/supabase-test-db).
- Integration test Flutter mendukung pengujian pada perangkat/emulator; barcode fisik dan izin kamera tetap mendapat skenario manual. [Flutter integration tests](https://docs.flutter.dev/testing/integration-tests), [mobile_scanner](https://pub.dev/packages/mobile_scanner).

**Self-review rencana:** setiap US dan INT memiliki task serta gate; nama DTO/RPC konsisten; temuan source dibedakan dari schema live; asumsi platform tidak disamarkan sebagai keputusan; tidak ada aplikasi, migrasi, test aplikasi, atau rilis yang dinyatakan selesai oleh dokumen ini.
