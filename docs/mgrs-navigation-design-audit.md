# Audit Navigasi & Kelengkapan Kanvas — MGRS Maintenance

Tanggal audit: 2026-09-14

## Ringkasan eksekutif

- **Parser flutter-map:** tidak dapat menjalankan parser otomatis karena aplikasi tidak memakai GoRouter, go_router_builder, AutoRoute, atau pola Navigator yang dikenali parser. Proyek memakai `MaterialApp` + `Navigator.push(MaterialPageRoute(...))` secara manual.
- **Fallback yang tersedia:** `.flutter-map/graph.json` berisi 20 route dan 19 edge, tetapi metadata itu stale terhadap source saat ini: masih merujuk `features/pic`, `features/assets`, `features/scanner`, dan widget `PicDashboardScreen`/`ServiceHomeScreen` yang tidak ada pada `lib/` saat audit.
- **Kanvas:** mencakup alur operasional service dan sebagian besar alur PIC/invoice, termasuk 16 screen service, state invoice PIC, serta beberapa overlay.
- **Gap utama:** autentikasi, pembuatan order aktual, dialog pembatalan, konfirmasi hapus invoice, variant error/loading/empty, serta state scanner dan konflik penyimpanan belum lengkap.
- `flutter analyze` selesai dengan 2 warning di `test/unit_allocation_gateway_test.dart` (dead code dan dead null-aware expression); tidak ditemukan error analisis di `lib/`.

## Arsitektur navigasi aktual dari source

### Shell dan role

1. `SplashScreen` → `LoginScreen` atau `MaintenanceHome` berdasarkan sesi.
2. `MaintenanceHome` adalah shell berbasis `PageView` + `AppBottomNavBar`, bukan named routes.
3. Role service: `HomeScreen` / `AssetCatalogScreen` / `ActionCenterScreen`.
4. Role PIC: `PicHomeScreen` / `UpcomingOrdersScreen` / `InvoiceListScreen`.
5. Admin dapat berganti mode PIC/Servis lewat profile bottom sheet.
6. Scanner dibuka sebagai `MaterialPageRoute` modal-like screen dari shell.

### Screen dan sub-screen yang ditemukan

| Area | Screen / widget | Status desain di kanvas |
|---|---|---|
| Startup/auth | `SplashScreen` | **Missing** |
| Startup/auth | `LoginScreen` | **Missing** |
| Service | `HomeScreen` | Ada sebagai `02 · Beranda operasional` |
| PIC | `PicHomeScreen` | Ada sebagai `PIC 01 · Beranda` |
| Service | `AssetCatalogScreen` | Ada sebagai `07 · Katalog komponen` |
| Service | `ComponentDetailScreen` | Ada sebagai `08 · Detail komponen` |
| Service | `HistoryScreen` | Ada sebagai `15 · Riwayat komponen` |
| Service | `HistoryDetailScreen` | Ada sebagai `16 · Detail riwayat` |
| Service | `ActionCenterScreen` | Ada sebagai `13 · Pusat tindakan` |
| Service | `CheckingScreen(service:false)` | Ada sebagai `09 · Perbarui kondisi` |
| Service | `CheckingScreen(service:true)` | Ada sebagai `11 · Catat servis` |
| Service | success sheet checking | Ada sebagai `10 · Pemeriksaan berhasil` |
| Service | success sheet service | Ada sebagai `12 · Laporan servis berhasil` |
| Service | `ScanScreen` | Ada sebagai `14 · Scanner barcode` |
| PIC/order | `UpcomingOrdersScreen` | Ada sebagai `03 · Daftar order` |
| PIC/order | `OrderDetailScreen` | Ada sebagai `04 · Detail order & alokasi` |
| PIC/order | `CreateOrderScreen` | **Missing** |
| PIC/order | completion confirmation dialog | Ada sebagai `06 · Konfirmasi penyelesaian order` |
| PIC/invoice | `InvoiceListScreen` | Ada sebagai `PIC 02 · Daftar invoice` + variants paid/unpaid |
| PIC/invoice | `CreateInvoiceDialog` | Ada sebagai `PIC 07 · Buat invoice dari order` + reimbursement |
| PIC/invoice | `InvoiceBuilderDialog` | Ada sebagai `PIC 05 · Edit invoice` |
| PIC/invoice | `QuickPaymentDialog` | Ada sebagai `PIC 03 · Atur pembayaran` |
| PIC/invoice | PDF progress/success/receipt dialogs | Ada sebagai `PIC 06/12 · Ekspor PDF` |
| Legacy/unwired | `ScheduleScreen` | **Missing / perlu klasifikasi** |
| Internal loading | `HomeSkeletonScreen` | **Missing state**; bukan screen navigasi mandiri |

## Missing Screens — prioritas

### P0/P1 — harus digenerate berikutnya

1. **LoginScreen**
   - Form akun/password, show/hide password, validation inline, loading submit, invalid credential, forbidden/inactive account, network timeout.
   - Penting karena ini gerbang kedua role dan belum ada artefak desain sama sekali.
2. **CreateOrderScreen**
   - Form event/client/WhatsApp/alamat, date picker, jumlah unit, durasi, link Maps, catatan, estimasi invoice, sticky submit.
   - Variants wajib: validation, saving, gagal create order/invoice, success confirmation.
3. **Order cancellation dialog** dari `OrderDetailScreen._showCancelOrderDialog`
   - Alasan pembatalan, status invoice unpaid/paid, pilihan pembatalan invoice, confirm/cancel, failure saat menyimpan.
   - Ini alur destruktif yang belum terlihat pada kanvas.
4. **Invoice delete confirmation dialog** dari `InvoiceListScreen._confirmDeleteInvoice`
   - Invoice reference + customer, konsekuensi permanen, Batal / Ya, Hapus, saving/failure.
5. **Scanner inline dialog pada alokasi unit** dari `UnitAllocationCard._showScanDialog`
   - Preview kamera mini, fallback input kode stiker, Batal/Gunakan, invalid format, permission/camera failure.
   - Berbeda dari full-screen `ScanScreen`.

### P2 — perlu sebelum handoff produksi

6. **`ScheduleScreen` / Pemeriksaan berkala**
   - Pertahankan hanya jika akan dihubungkan ke navigasi; jika legacy, tandai deprecated/remove dari audit scope. Jika dipakai: filter jenis/status, month navigation, pagination, preview/not-generated, empty/error/loading.
7. **State auth/session global**
   - Sesi berakhir/unauthenticated, forbidden, retry, keluar akun; saat ini hanya ditampilkan sebagai overlay generik di `app.dart`.
8. **State detail komponen dan riwayat**
   - Detail gagal dimuat, loading, riwayat penggunaan kosong, retry.

## Missing States — matrix desain

| State | Ada di code | Ada desain | Gap |
|---|---:|---:|---|
| Login validation/loading/error | Ya | Tidak | **Missing** |
| Home service loading skeleton | Ya | Tidak | **Missing** |
| Home service empty data | Sebagian (angka 0) | Tidak eksplisit | **Missing** |
| Home/PIC network error | Ya | Tidak eksplisit | **Missing** |
| Order list empty | Ya | Ya (`PIC 09`) | Covered, tetapi search-no-results perlu variant terpisah |
| Order list search-no-results | Tergabung dengan empty | Tidak | **Missing** |
| Invoice empty list | Ya | Tidak | **Missing** |
| Invoice search/filter-no-results | Ya | Tidak | **Missing** |
| Invoice network error | Ya | Tidak | **Missing** |
| Invoice create: no scheduled order | Ya | Tidak | **Missing** |
| Catalog loading/error/empty | Ya | Tidak eksplisit | **Missing** |
| Action center loading/error/empty | Ya | Tidak eksplisit | **Missing** |
| Schedule loading/error/empty/not-generated | Ya | Tidak | **Missing** |
| Component picker loading/error/empty | Ya | Hanya happy picker | **Missing** |
| Full scanner camera permission/unavailable | Ya | Tidak | **Missing — P1** |
| Scanner lookup not found/ambiguous/network | Ya | Tidak | **Missing — P1** |
| Checking validation | Ya | Hanya library `Field / Error` | **Missing screen state** |
| Checking task-not-open | Ya | Tidak | **Missing** |
| Checking save conflict / stale version | Ya | Tidak | **Missing — P1** |
| Service form validation/save error | Ya | Tidak | **Missing — P1** |
| Dirty form discard dialog | Ya (`leave`) | Tidak | **Missing** |
| Allocation unavailable/conflict | Ya via picker/assignment paths | Tidak | **Missing — P1** |
| PDF export failure | Ya via snackbar | Tidak | **Missing** |
| Invoice delete confirmation | Ya | Tidak | **Missing — P1** |
| Order completion confirmation | Ya | Ya | Covered |
| Logout/profile sheet | Ya | Ya (`Profil pengguna · Admin`) | Covered |

## Temuan desain terhadap kanvas

### Yang sudah kuat

- Kanvas sudah sangat baik untuk happy path service: katalog → detail komponen → kondisi/servis → success → riwayat.
- Reusable library mencakup tombol, app bar, search, navigation, badge kondisi, selection row, asset row, dan field error.
- Role PIC dan invoice sudah memiliki cakupan lebih kaya daripada service: create invoice, reimbursement, edit, payment, unpaid/paid, detail, export.
- Hierarki visual dan token operasional cukup konsisten: permukaan netral, aksen biru/rose/semantic status, target kontrol minimum 48, serta catatan safe-area.

### Risiko dan temuan prioritas

- **[P1] Coverage bias ke happy path:** banyak screen dasar sudah ada, tetapi error/loading/empty yang menentukan keberhasilan operasional belum dibuat sebagai artboard nyata.
- **[P1] Auth blind spot:** tidak ada desain startup/login, padahal role menentukan dua shell yang berbeda.
- **[P1] Destructive flow blind spot:** cancel order dan delete invoice ada di code tetapi tidak ada pada kanvas.
- **[P1] Scanner blind spot:** full scanner hanya menampilkan preview sukses; permission denied, kamera unavailable, not found, ambiguous, dan network failure belum ada.
- **[P1] Conflict blind spot:** `SubmissionState.conflict` sudah diimplementasikan, tetapi tidak ada desain yang menjelaskan data stale, tindakan refresh, atau perlindungan input.
- **[P2] Stale navigation map:** `.flutter-map/graph.json` tidak boleh dipakai sebagai source of truth sebelum diperbarui dari source aktual.
- **[P2] Native affordance:** beberapa kontrol code memiliki ukuran visual 36–40 (`IconButton`/tombol kecil), walau sebagian target sentuh Flutter masih lebih besar; validasi emulator perlu memastikan minimal 44–48 logical pixels.
- **[P2] Error copy:** `failureMessage` masih mengembalikan `PostgrestException.message` mentah untuk kasus tertentu; desain dan implementasi harus memastikan detail backend/SQL tidak bocor ke operator.

## Checklist generate selanjutnya

### Batch 1 — release blocking

- [ ] `01 · Login` — default, validation, loading, invalid credential, forbidden, network.
- [ ] `02 · Buat order` — default, validation, saving, failure, success.
- [ ] `03 · Batalkan order` — no invoice, unpaid invoice, paid invoice, failure.
- [ ] `04 · Hapus invoice` — confirmation, deleting, failure.
- [ ] `05 · Scanner failure states` — permission denied, camera unavailable, not found, ambiguous, retry.
- [ ] `06 · Conflict save` — stale data warning, refresh/review, preserve draft.

### Batch 2 — completeness operasional

- [ ] Empty/error/loading invoice list.
- [ ] Empty/error/loading catalog dan action center.
- [ ] Component picker loading/error/empty + search-no-results.
- [ ] Schedule screen bila masih reachable; jika tidak, dokumentasikan sebagai legacy.
- [ ] Detail component/history loading/error/empty history.
- [ ] Session expired / forbidden overlay.

### Batch 3 — quality states

- [ ] Text zoom/long content untuk form order dan service.
- [ ] Disabled/busy controls dengan ukuran tetap.
- [ ] Offline/stale indicator.
- [ ] Accessibility focus/semantic states untuk modal, scanner, radio/selection, dan error inline.

## Rekomendasi tindakan

1. Regenerasi `.flutter-map/graph.json` dengan mode manual yang mencerminkan source aktual; jangan menyalin graph lama.
2. Tambahkan screen/state artboards Batch 1 ke `Redesign UI.pen`.
3. Hubungkan setiap state ke source file dan aksi pemicu agar dapat direplay.
4. Setelah desain selesai, capture emulator Android untuk route dan state; static canvas tidak memverifikasi kamera, keyboard, back gesture, atau screen reader.
5. Jalankan audit ulang setelah Batch 1 dan tandai setiap state sebagai `covered`, `partial`, atau `missing`.
