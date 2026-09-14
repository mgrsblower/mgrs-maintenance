---
name: MGRS Maintenance
description: Antarmuka operasional mobile untuk order, invoice, pemasangan, pemeriksaan, dan servis blower MGRS.
colors:
  canvas: "#F5F5F5"
  surface: "#FFFFFF"
  ink: "#171717"
  muted: "#666666"
  line: "#E7E7E7"
  action: "#D91C48"
  operational: "#147CC1"
  success: "#166534"
  success-soft: "#ECF8F0"
  warning: "#854D0E"
  warning-soft: "#FEFCE8"
  danger: "#B42318"
  danger-soft: "#FEF0EE"
typography:
  page-title:
    fontFamily: "Inter, sans-serif"
    fontSize: "24px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.02em"
  section-title:
    fontFamily: "Inter, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: 1.35
  body:
    fontFamily: "Inter, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.4
  button-label:
    fontFamily: "Inter, sans-serif"
    fontSize: "15px"
    fontWeight: 600
    lineHeight: 1.4
  label:
    fontFamily: "Inter, sans-serif"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.4
  caption:
    fontFamily: "Inter, sans-serif"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.4
rounded:
  control: "12px"
  compact-surface: "16px"
  card: "24px"
  sheet: "28px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  base: "16px"
  lg: "20px"
  xl: "24px"
  section: "32px"
components:
  button-primary:
    backgroundColor: "{colors.action}"
    textColor: "{colors.surface}"
    typography: "{typography.button-label}"
    rounded: "{rounded.pill}"
    padding: "0 20px"
    height: "52px"
  button-neutral:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.surface}"
    typography: "{typography.button-label}"
    rounded: "{rounded.pill}"
    padding: "0 20px"
    height: "52px"
  input-default:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "0 14px"
    height: "48px"
  card-default:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.card}"
    padding: "16px"
  bottom-navigation:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.surface}"
    rounded: "{rounded.pill}"
    padding: "8px"
    height: "68px"
---

# Design System: MGRS Maintenance

## Overview

**Creative North Star: "Peralatan Lapangan yang Tenang"**

MGRS Maintenance adalah aplikasi kerja, bukan dashboard dekoratif. Antarmuka harus cepat dibaca saat operator berada di lokasi pemasangan, memegang perangkat dengan satu tangan, atau bekerja di bawah tekanan waktu. Kode komponen, kondisi terakhir, jadwal, nominal, dan tindakan berikutnya selalu lebih penting daripada ornamen.

Sistem visual mengikuti fondasi pada frame `y8voL5` di `Redesign UI.pen`. Canvas abu muda menjaga layar tetap tenang. Surface putih mengelompokkan informasi. Ink memberi kontras utama. Rose menandai tindakan komitmen. Cobalt dipakai terbatas untuk tindakan operasional seperti scanner, tautan, dan informasi aktif.

Dial: ENERGY 1 / RHYTHM 1 / MOTION 1.

Karakter utama:
- Hierarki ringkas dan mudah dipindai.
- Satu tindakan utama per screen atau dialog.
- Dua shell role yang memakai bahasa visual sama.
- Status selalu memakai warna, ikon, dan teks.
- Empty, loading, error, validation, conflict, dan success termasuk desain inti.

**The Operational Truth Rule.** Angka, kondisi, invoice, dan jadwal harus berasal dari data aplikasi. Contoh pada kanvas tidak boleh dianggap data produksi.

## Colors

Palette utama bersifat netral. Warna muncul ketika membantu operator memahami tindakan atau status.

### Primary
- Ink adalah warna teks utama, navigation dock, dan tombol rutin dengan prioritas tinggi.
- Rose Action menandai tindakan komitmen seperti masuk, membuat invoice, menyimpan order, dan scanner utama.

### Secondary
- Operational Cobalt menandai tautan, aksi scanner sekunder, focus state, serta informasi aktif. Jangan menggunakannya sebagai warna semua CTA.

### Neutral
- Canvas menjadi background screen.
- Surface menjadi card, sheet, dialog, field, dan selected container.
- Muted dipakai untuk metadata dan helper text.
- Line dipakai sebagai divider atau batas input. Card tidak otomatis memakai stroke.

### Semantic status
- Success untuk hasil tersimpan, lunas, dan layak pakai.
- Warning untuk perlu servis, data stale, atau keputusan yang perlu ditinjau.
- Danger untuk error, gangguan fungsi, pembatalan, dan penghapusan.
- Setiap status memakai soft background yang sesuai. Warna tidak pernah menjadi satu-satunya penanda.

**The Sparse Accent Rule.** Satu kelompok tindakan hanya memiliki satu tombol filled yang dominan.

**The No Ghost Card Rule.** Pilih salah satu pemisah: perubahan surface, divider, atau shadow. Jangan menumpuk border dan shadow pada card biasa.

## Typography

Inter adalah typeface normatif untuk desain baru dan handoff canvas. Plus Jakarta Sans yang masih ada di implementasi Flutter adalah debt normalisasi, bukan typeface kedua yang perlu diperluas.

### Hierarchy
- Page title: 24px, weight 600, maksimal dua baris.
- Screen app bar: 17px, weight 600.
- Section title: 18px, weight 600.
- Card title: 16px, weight 600.
- Body: 14px, weight 400.
- Label: 12px, weight 600.
- Caption: 11px, weight 400.
- Nominal atau kode penting boleh memakai 20 sampai 24px, weight 600.

Teks tugas menggunakan alignment kiri. Center alignment hanya dipakai untuk empty state, success state, access state, dan dialog confirmation. Nilai uang memakai digit tabular jika implementasi mendukungnya.

**The Code First Rule.** Pada detail komponen, kode stiker menjadi teks paling kuat. Jenis dan metadata menjadi informasi sekunder.

## Layout

Artboard utama berukuran 390 x 844. Screen dengan konten panjang boleh memiliki artboard lebih tinggi untuk handoff, tetapi implementasi tetap memakai viewport perangkat dan scrolling.

- Status bar desain: tinggi 36.
- Gutter horizontal: 20.
- Gap antarbagian utama: 20 sampai 24.
- Gap elemen terkait: 8 sampai 12.
- Safe area wajib pada sisi atas dan bawah.
- Form menggunakan satu kolom. Pasangan field hanya boleh dua kolom jika label dan nilai tetap terbaca pada lebar 320.
- Primary action berada di area bawah atau setelah konten utama. Keyboard tidak boleh menutup field aktif atau tombol submit.
- Detail dan form memakai tombol kembali.
- Sheet memakai tinggi sesuai isi atau maksimal sekitar 75 sampai 85 persen viewport.

### Shell role

PIC MGRS memakai Beranda, Orderan, dan Invoice. Tim pemasangan dan servis memakai Beranda, Aset, Servis, serta Scan sebagai tindakan utama. Admin dapat berganti mode melalui profile sheet. Pergantian role tidak mengubah token, typography, atau perilaku komponen.

### State parity

Loading, empty, error, dan search-no-results adalah variant dari shell yang sama. Header, filter, search, dan navigation harus tetap berada pada posisi yang sama. Hanya area data yang berubah.

Contoh: `22 · Invoice kosong` harus mempertahankan struktur `PIC 02 · Daftar invoice`, termasuk header, source switcher, search, filter status, dan bottom navigation. Card invoice diganti dengan empty state. Empty state tidak boleh terlihat seperti halaman baru.

**The Stable Shell Rule.** Perubahan data tidak boleh memindahkan navigasi atau mengubah identitas halaman.

## Elevation & Depth

Sistem ini flat secara default. Kedalaman berasal dari kontras canvas dan surface.

- Card biasa tidak memakai shadow.
- Sheet dan dialog boleh memakai shadow lembut karena berada di atas scrim.
- Floating navigation boleh memiliki shadow ringan untuk memisahkannya dari konten.
- Focus state memakai outline yang jelas, bukan glow dekoratif.
- Scanner memakai background gelap hanya selama kamera aktif atau menampilkan camera error.

**The Earned Elevation Rule.** Shadow hanya muncul saat elemen benar-benar berada di atas lapisan lain.

## Shapes

Radius menunjukkan fungsi dan tingkat containment.

- Input, compact control, dan kecil state banner memakai radius 12.
- Compact surface memakai radius 16.
- Card utama memakai radius 24.
- Bottom sheet memakai radius atas 28.
- Button, chip, badge, avatar, dan navigation dock boleh memakai pill atau circle.
- Dialog confirmation memakai radius 24 dan icon berada tepat di tengah bagian atas.

Card tidak otomatis memiliki stroke. Input tetap memakai stroke agar batas field terbaca. Status chip boleh memakai soft fill tanpa border jika kontrasnya sudah cukup.

## Components

### Buttons

- Minimum target sentuh 48 x 48.
- Primary memakai Rose Action dengan teks putih.
- Neutral memakai Ink dengan teks putih.
- Secondary memakai Surface atau Canvas dengan teks Ink.
- Destructive memakai Danger dan hanya untuk tindakan merusak.
- Loading mempertahankan ukuran tombol dan mencegah submit ganda.
- Label menyebut tindakan, seperti `Simpan laporan servis`, `Batalkan order`, atau `Muat data terbaru`.

### App bar

Tinggi 56 dengan target kembali 44 x 44. Judul berada di tengah. Slot kanan tetap seimbang; sembunyikan action yang tidak tersedia tanpa menggeser judul.

### Cards

Card utama memakai Surface, radius 24, dan padding 16 sampai 20. Gunakan card hanya untuk satu kelompok informasi atau tindakan. Empty state tidak perlu stroke. Hindari card di dalam card jika divider atau gap cukup.

### Inputs

Field memiliki label di luar input. Placeholder bukan label. Default memakai Surface, radius 12, dan stroke Line. Error memakai Danger Soft, stroke Danger, serta pesan spesifik di bawah field. Nilai pengguna tetap tersimpan setelah error.

### Search

Search berbentuk pill dengan tinggi 48. Search berisi tombol clear dengan target sentuh yang cukup. Empty database dan search-no-results adalah state berbeda. Search-no-results menampilkan query atau filter aktif serta tindakan reset.

### Status badge

Badge menampilkan label kondisi. Badge pada selected component berada di kanan atas, sejajar dengan identitas komponen. Jangan memakai warna saja untuk menyampaikan status.

### Dialog

Dialog confirmation memakai icon terpusat, judul ringkas, dampak tindakan, dan dua action. Destructive dialog menempatkan tombol aman di kiri dan destructive action di kanan. Pembatalan order menyertakan alasan serta dampak pada invoice. Penghapusan invoice menyebut nomor invoice dan sifat permanen tindakan.

### Bottom sheet

Sheet memakai handle, title, close target, content scrollable, dan action yang tetap dapat dijangkau. Component picker memiliki loading, empty, error, dan search-no-results. Success sheet hanya tampil setelah backend mengonfirmasi penyimpanan.

### Scanner

Scanner memiliki camera viewport, target scan, flash, close, dan fallback input kode. State wajib: permission denied, camera unavailable, lookup loading, not found, ambiguous, network error, result, dan retry. Kamera berhenti setelah hasil ditemukan, saat screen ditutup, ketika aplikasi pause, dan setelah logout.

### Bottom navigation

Navigation dock bersifat floating dan tetap mudah dijangkau satu tangan. Active state memakai kombinasi ikon, label, dan highlight. Setiap destination harus memiliki screen nyata. Scanner adalah action, bukan destination biasa.

### Required screen and state coverage

Screen yang harus dipertahankan dalam desain dan implementasi:
- Splash dan Login.
- Beranda service dan Beranda PIC.
- Daftar order, buat order, detail order, alokasi unit, dan penyelesaian order.
- Daftar invoice, detail invoice, create invoice, reimbursement, edit, pembayaran, export PDF, serta delete confirmation.
- Katalog komponen, detail komponen, action center, pemeriksaan, servis, scanner, riwayat, dan detail riwayat.
- Profile sheet, logout confirmation, cancel order, inline allocation scanner, component picker, dan success sheets.

State yang wajib tersedia:
- Empty, loading, error, dan search-no-results untuk setiap daftar data.
- Validation, saving, conflict, success, dan discard confirmation untuk form.
- Session expired dan forbidden untuk autentikasi.
- Permission, unavailable, not found, ambiguous, dan network failure untuk scanner.

## Do's and Don'ts

### Do

- Do pertahankan struktur shell ketika data berubah menjadi loading, empty, atau error.
- Do gunakan satu CTA dominan per kelompok tindakan.
- Do tampilkan kode komponen, status, jadwal, dan nominal dengan hierarki yang jelas.
- Do pertahankan draft ketika request gagal atau terjadi conflict.
- Do gunakan copy Bahasa Indonesia yang spesifik dan memberi langkah pemulihan.
- Do pastikan target sentuh minimal 48 pada tindakan utama dan minimal 44 pada icon button.
- Do uji lebar 320, 360, 390, dan 430 serta text scaling 200 persen.
- Do gunakan avatar berbasis inisial jika tidak ada foto resmi.

### Don't

- Don't membuat empty state sebagai halaman dengan header dan navigasi berbeda.
- Don't memakai border pada setiap card. Surface dan spacing biasanya sudah cukup.
- Don't memakai rose untuk error atau status jika perannya adalah tindakan utama.
- Don't menampilkan exception, SQL, atau pesan backend mentah kepada operator.
- Don't menghapus input pengguna setelah validation, network error, atau conflict.
- Don't memakai chart, ilustrasi, metric, atau angka yang tidak berasal dari data nyata.
- Don't menaruh navigation dock dan sticky CTA pada area bawah yang sama.
- Don't menganggap kanvas statis sebagai bukti kamera, keyboard, navigation, atau accessibility sudah berfungsi.
