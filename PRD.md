# PRD — MGRS-Maintenance

Versi: 1.0  
Tanggal: 6 September 2026  
Status: Draft kebutuhan untuk ditinjau, belum merupakan implementasi  
Lokasi proyek: `C:\Users\ogi\MGRS-Maintenance`

Dokumen ini membedakan keputusan pengguna, usulan aturan MVP, dan hal teknis yang perlu diverifikasi. Pemeriksaan integrasi dilakukan pada kode lokal `C:\Users\ogi\mgrs-release`; skema, trigger, constraint, dan kebijakan database produksi belum diperiksa langsung.

## 1. Executive Summary

### 1.1 Masalah

Petugas membutuhkan aplikasi dengan cakupan kecil untuk mengetahui kondisi komponen dan mencatat pemeriksaan serta servis. Pekerjaan tersebut harus dapat dilakukan langsung melalui barcode atau kode komponen, tanpa melalui pemasangan, pesanan, atau alokasi.

### 1.2 Solusi

MGRS-Maintenance adalah aplikasi terpisah yang menggunakan database MGRS yang sama. Aplikasi menangani Kepala, Batang, dan Tabung dengan alur: temukan komponen, lihat kondisi, catat pemeriksaan atau servis, lalu simpan kondisi terbaru beserta riwayatnya.

Pengecekan berkala berlangsung sebulan sekali pada Sabtu keempat setiap bulan dan Minggu setelahnya. Pengecekan manual dan servis tetap dapat dicatat kapan saja.

### 1.3 Keputusan yang sudah disepakati

| Area | Keputusan pengguna |
| --- | --- |
| Proyek | Dikembangkan terpisah dalam folder MGRS-Maintenance |
| Objek | Kepala, Batang, dan Tabung |
| Identitas | Setiap komponen sudah memiliki barcode atau kode unik |
| Data | Tetap menggunakan database MGRS yang sama |
| Hubungan operasional | Tidak memiliki hubungan alur dengan pemasangan, pesanan, atau alokasi |
| Interaksi | Scanner/manual untuk menemukan dan memeriksa komponen |
| Mutasi | Pemeriksaan dan maintenance dapat memperbarui kondisi |
| Jadwal | Sabtu keempat setiap bulan sampai Minggu berikutnya |
| Akses pembaruan | Tim Service, Tim Pemasangan, dan Admin |

### 1.4 Kriteria keberhasilan

Target berikut adalah usulan penerimaan MVP, bukan hasil pengujian yang sudah tercapai.

1. Seluruh barcode sampel Kepala, Batang, dan Tabung yang valid membuka komponen yang tepat; tidak ada pembaruan terhadap komponen lain.
2. Seluruh transaksi berhasil menyimpan kondisi dan riwayat secara konsisten; kegagalan tidak meninggalkan salah satunya tersimpan sendiri.
3. Seluruh percobaan akses tulis oleh akun nonaktif atau role di luar tiga role yang disepakati ditolak oleh server.
4. Seluruh kasus kalender, batas waktu, dan pemeriksaan terlambat dalam matriks QA menghasilkan periode dan status yang benar.
5. Pada perangkat dan jaringan pilot yang disepakati, target p95 pencarian hingga detail tampil maksimal 3 detik dan penyimpanan maksimal 3 detik. Pengukuran minimal 30 percobaan per alur, tidak termasuk waktu petugas mengisi formulir.

## 2. User Experience & Functionality

### 2.1 Pengguna dan hak akses

| Kemampuan | Admin | Tim Service | Tim Pemasangan |
| --- | --- | --- | --- |
| Scan/cari komponen dan lihat kondisi | Ya | Ya | Ya |
| Lihat jadwal dan riwayat komponen | Ya | Ya | Ya |
| Catat pemeriksaan dan ubah kondisi | Ya | Ya | Ya |
| Catat servis dan kondisi hasil servis | Ya | Ya | Ya |
| Hapus/ubah catatan riwayat yang sudah disimpan | Tidak dalam MVP | Tidak dalam MVP | Tidak dalam MVP |
| Mengubah pemasangan, alokasi, atau status penggunaan | Tidak | Tidak | Tidak |

Usulan akses MVP: menggunakan akun MGRS aktif yang sudah ada. Role lain, termasuk `PIC Pemasangan`, tidak otomatis mendapat akses aplikasi ini. Pengelolaan akun tetap dilakukan melalui mekanisme MGRS yang ada. Ketiga role memiliki kemampuan pencatatan yang sama tanpa tahap approval tambahan.

Nama Tim Pemasangan adalah identitas role pengguna; tidak menambahkan fitur atau ketergantungan pemasangan pada aplikasi.

### 2.2 Navigasi dan layar

Navigasi utama yang diusulkan: **Scan**, **Berkala**, dan **Riwayat**. Akun dan keluar tersedia dari menu profil sederhana.

| Layar | Konten/tindakan utama |
| --- | --- |
| Login | Masuk menggunakan akun MGRS, pesan kegagalan, penolakan akses |
| Scan | Aktifkan kamera, masukkan kode manual, hasil pencarian |
| Detail komponen | Jenis, kode/stiker, kondisi, kelayakan, gangguan fungsi, catatan, pemeriksaan terakhir; tombol Catat Pemeriksaan dan Catat Servis |
| Form pemeriksaan | Kondisi hasil pemeriksaan, kelayakan, gangguan fungsi, catatan, konteks rutin atau berkala |
| Form servis | Masalah, tindakan servis, kondisi setelah servis, kelayakan, gangguan fungsi, catatan |
| Berkala | Periode, rentang Sabtu–Minggu, jumlah selesai/belum selesai/terlambat, filter jenis dan pencarian kode |
| Riwayat | Pemeriksaan dan servis, filter jenis kegiatan, kode, dan tanggal; detail petugas dan hasil |

Kondisi selalu ditampilkan dengan teks, bukan warna saja. Jika tidak ada riwayat, tampilkan “Belum ada pemeriksaan tercatat”; jangan menggunakan tanggal perubahan master sebagai tanggal pemeriksaan.

### 2.3 Alur utama

**Pemeriksaan manual:** Login → Scan/masukkan kode → Detail → Catat Pemeriksaan → Tinjau hasil → Simpan → Kondisi dan riwayat diperbarui.

**Pemeriksaan berkala:** Berkala → Pilih periode dan komponen → Scan atau konfirmasi kode komponen → Catat Pemeriksaan → Simpan untuk periode tersebut → Status tugas diperbarui.

**Servis:** Scan/masukkan kode → Detail → Catat Servis → Isi masalah, tindakan, dan hasil pemeriksaan setelah servis → Simpan → Kondisi dan riwayat diperbarui.

Membuka detail atau memindai barcode tidak mencatat pemeriksaan dan tidak mengubah kondisi.

### 2.4 User stories dan acceptance criteria

#### US-01 — Akses akun

Sebagai anggota Tim Service, Tim Pemasangan, atau Admin, saya ingin masuk dengan akun MGRS agar pencatatan terhubung dengan identitas saya.

- Hanya akun aktif dengan salah satu dari tiga role tersebut dapat mengakses fungsi aplikasi.
- Pemeriksaan role dan status aktif diterapkan pada server untuk setiap operasi yang dilindungi; menyembunyikan tombol saja tidak cukup.
- Petugas pencatat berasal dari sesi autentikasi, tidak dapat diganti melalui isian formulir.
- Sesi kedaluwarsa meminta login kembali dan tidak menampilkan klaim penyimpanan berhasil.

#### US-02 — Menemukan komponen

Sebagai petugas, saya ingin memindai barcode atau memasukkan kode agar membuka komponen yang benar.

- Mendukung Kepala, Batang, dan Tabung yang terdaftar pada master yang sama dengan MGRS.
- Kamera baru dipakai setelah tindakan pengguna. Izin ditolak atau kamera tidak tersedia tetap menyediakan pencarian kode manual.
- Satu hasil scan membuka satu detail; pembacaan frame berulang tidak membuka detail atau transaksi berkali-kali.
- Kode tidak ditemukan menampilkan pesan dan pilihan scan/cari ulang, tanpa membuat komponen baru.
- Jika data menghasilkan lebih dari satu kecocokan, aplikasi meminta pemilihan identitas yang jelas atau menolak pencatatan sampai data diperbaiki; tidak memilih diam-diam.
- Kode yang termasuk objek lain, seperti kabel rol, ditampilkan sebagai di luar cakupan aplikasi.

#### US-03 — Melihat kondisi

Sebagai petugas, saya ingin melihat kondisi dan riwayat terakhir agar mengetahui hasil pemeriksaan sebelumnya.

- Detail menampilkan identitas, kondisi terbaru, kelayakan, gangguan fungsi, dan catatan dari sumber data yang sesuai.
- Tanggal pemeriksaan terakhir berasal dari riwayat pemeriksaan; tanggal servis ditampilkan terpisah.
- Refresh membaca perubahan yang disimpan oleh aplikasi lain pada database bersama.
- Tidak ada pencarian order, persyaratan pemasangan, atau perubahan status penggunaan untuk membuka detail.

#### US-04 — Mencatat pemeriksaan

Sebagai petugas berwenang, saya ingin mencatat hasil pemeriksaan agar kondisi master dan riwayat tetap sesuai keadaan komponen.

- Identitas komponen dikunci setelah dipilih; pengguna dapat kembali untuk mengganti komponen sebelum menyimpan.
- Kondisi dan kelayakan wajib diisi. Gangguan fungsi dan catatan temuan wajib saat kondisi tidak OK; untuk OK, gangguan fungsi disimpan konsisten sebagai `Tidak Ada`.
- Pilihan kondisi mengikuti nilai database yang ada, bukan enum baru yang tidak kompatibel.
- Kondisi tidak otomatis dianggap baik karena formulir dibuka. Petugas harus mengonfirmasi hasil sebelum menyimpan.
- Menyimpan kondisi yang sama tetap menghasilkan riwayat pemeriksaan baru yang sah.
- Kondisi, petugas, waktu, dan riwayat tersimpan dalam satu transaksi; tombol simpan dinonaktifkan selama permintaan berjalan.
- Kegagalan menyimpan mempertahankan isian selama layar/sesi masih aktif dan menyediakan coba lagi tanpa catatan ganda.
- Keluar dari formulir yang belum tersimpan meminta konfirmasi pembuangan isian.

#### US-05 — Mencatat servis

Sebagai petugas berwenang, saya ingin mencatat masalah, tindakan, dan kondisi hasil servis agar perawatan dapat ditelusuri.

- Masalah, tindakan servis, kondisi hasil, dan kelayakan wajib diisi.
- Servis boleh dilakukan kapan saja tanpa menunggu jadwal bulanan atau status penggunaan `Service`.
- Pencatatan hasil servis tidak selalu berarti kondisi OK; hasil yang masih bermasalah tetap dapat dicatat dengan kelayakan yang sesuai.
- Riwayat menyimpan petugas, waktu, masalah, tindakan, dan hasil. Pembaruan kondisi bersifat atomik dengan riwayat.
- Servis tidak otomatis menyelesaikan tugas pemeriksaan berkala. Petugas harus mencatat pemeriksaan berkala secara eksplisit jika pemeriksaan bulanan juga dilakukan.
- Biaya bukan kewajiban alur pengguna MVP. Kebutuhan field biaya pada backend harus ditangani secara kompatibel setelah validasi skema, tanpa mengarang biaya aktual.

#### US-06 — Menyelesaikan pemeriksaan bulanan

Sebagai petugas, saya ingin melihat komponen yang perlu diperiksa pada akhir pekan bulanan agar tidak ada pemeriksaan yang terlewat.

- Jadwal dihitung berdasarkan aturan pada bagian 2.5, bukan interval 30 hari.
- Daftar dapat difilter berdasarkan Kepala/Batang/Tabung, kode, dan status tugas.
- Pemeriksaan yang selesai memperbarui satu tugas komponen untuk satu periode; pemeriksaan tambahan tetap masuk riwayat tetapi tidak menambah jumlah tugas selesai.
- Pemeriksaan dengan hasil rusak tetap menyelesaikan kewajiban pemeriksaan. “Selesai diperiksa” tidak berarti “Kondisi baik”.
- Tugas terlambat tetap dapat diselesaikan dengan waktu aktual dan label “Selesai terlambat”.

#### US-07 — Menelusuri riwayat

Sebagai pengguna berwenang, saya ingin melihat riwayat pemeriksaan dan servis agar mengetahui perubahan kondisi dan tindakan sebelumnya.

- Riwayat dibedakan antara pemeriksaan manual, pemeriksaan berkala, dan servis.
- Setiap catatan baru dapat ditelusuri ke komponen, petugas, waktu server, serta kondisi sebelum dan sesudah tindakan.
- Data historis yang tidak memiliki kondisi sebelumnya ditampilkan apa adanya, tidak direkonstruksi sebagai fakta.
- Koreksi hasil dibuat melalui pencatatan baru dengan alasan koreksi; catatan asli tidak dihapus atau diubah dalam MVP.
- Daftar dimuat bertahap, tidak mengunduh seluruh riwayat ketika aplikasi dibuka.

### 2.5 Aturan jadwal bulanan

**Disepakati:** satu jadwal bulanan pada Sabtu keempat dan Minggu sesudahnya.

**Usulan aturan detail MVP:**

1. Zona waktu operasional adalah `Asia/Jakarta` (WIB); jam perangkat tidak menjadi sumber kebenaran penentuan terlambat.
2. Temukan Sabtu pertama dalam bulan, lalu tambahkan 21 hari. Hari Minggu adalah tanggal setelah Sabtu tersebut. Ini bukan “Sabtu terakhir” dan bukan nomor minggu ISO.
3. Jendela pemeriksaan dimulai Sabtu pukul 00.00 WIB dan berakhir tepat sebelum Senin pukul 00.00 WIB.
4. Sebelum jendela: **Terjadwal**. Di dalam jendela dan belum selesai: **Perlu diperiksa**. Sesudah jendela dan belum selesai: **Terlambat**. Setelah selesai: **Selesai** atau **Selesai terlambat**.
5. Target periode adalah seluruh Kepala/Batang/Tabung yang masih tercatat dalam master saat jendela dibuka. Target tidak difilter menurut pemasangan, alokasi, atau `status_penggunaan`.
6. Daftar target dibekukan per periode supaya angka kepatuhan tidak berubah akibat penambahan master sesudah jadwal dimulai. Komponen yang ditambahkan kemudian mendapat jadwal bulan berikutnya dan tetap bisa diperiksa manual.
7. Periode pertama adalah periode dengan pembukaan jendela pertama pada atau setelah aktivasi fitur. Tidak menghasilkan tunggakan retroaktif sebelum aplikasi digunakan. Riwayat lama tetap dapat dilihat.
8. Sebelum jendela dibuka, pengecekan dianggap manual dan tidak menyelesaikan kewajiban bulanan. Selama jendela, form menawarkan konteks periode aktif secara eksplisit. Scan saja tidak menyelesaikan tugas.
9. Tugas terlambat diselesaikan dengan memilih periodenya dan melakukan pemeriksaan sekarang. Jangan memundurkan waktu pencatatan. Satu pemeriksaan hanya boleh menyelesaikan satu periode; bulan berikutnya tetap memiliki kewajiban tersendiri.
10. Komponen tidak ditemukan atau berstatus Hilang tidak dianggap telah diperiksa fisik. Catatan temuan dapat disimpan; tugas tetap terbuka/terlambat. Mekanisme pengecualian formal belum termasuk MVP.
11. Periode dan tugas unik untuk pasangan komponen–bulan, tetap tersedia lintas pengguna dan perangkat. Pembuatan jadwal harus berjalan tanpa mengharuskan pengguna membuka aplikasi saat Sabtu dimulai.

Contoh kalender yang dihitung saat penyusunan dokumen:

| Periode | Sabtu keempat | Minggu | Mulai terlambat |
| --- | --- | --- | --- |
| September 2026 | 26 September | 27 September | 28 September 00.00 WIB |
| Oktober 2026 | 24 Oktober | 25 Oktober | 26 Oktober 00.00 WIB |
| Februari 2027 | 27 Februari | 28 Februari | 1 Maret 00.00 WIB |

Oktober 2026 memiliki Sabtu kelima pada 31 Oktober; jadwal tetap 24–25 Oktober.

### 2.6 Batas MVP

- Tidak ada pemasangan, order, alokasi, reservasi, approval order, invoice, atau pengubahan status penggunaan.
- Tidak membuat master komponen, barcode baru, atau database operasional duplikat.
- Tidak mencakup kabel rol dan aksesori di luar Kepala/Batang/Tabung.
- Tidak mencakup pengelolaan akun, stok suku cadang, penugasan teknisi, anggaran, dan approval servis.
- Tidak menyediakan penulisan offline atau sinkronisasi antrean pada MVP. Gangguan jaringan harus terlihat dan tidak boleh menghasilkan sukses semu.
- Foto, push notification, checklist teknis per jenis, ekspor, dan analitik lanjutan adalah pengembangan berikutnya, bukan syarat MVP.
- Form awal memakai kondisi, kelayakan, gangguan fungsi, dan catatan. Butir checklist teknis tidak dikarang sebelum divalidasi dengan tim lapangan.

## 3. AI System Requirements (If Applicable)

Tidak berlaku. MVP tidak memakai AI, diagnosis otomatis, pengenalan kerusakan dari foto, atau rekomendasi kondisi. Hasil kondisi berasal dari pemeriksaan petugas.

## 4. Technical Specifications

### 4.1 Arsitektur dan batas kepemilikan

Alur data: aplikasi baru → autentikasi MGRS → layanan baca/tulis dengan validasi server → database Supabase MGRS yang sama.

Kode MGRS lama adalah referensi kontrak data. Aplikasi baru memiliki source, konfigurasi, build, dan rilis sendiri. Perubahan pada kode lama bukan bagian pekerjaan PRD ini.

Platform, framework, target perangkat, anggaran, dan tenggat belum ditetapkan pengguna. PRD ini tidak mengunci Flutter, Expo, maupun web. Pemilihan teknologi menjadi keluaran tahap fondasi berdasarkan perangkat kerja dan kebutuhan scanner yang sebenarnya.

### 4.2 Kontrak yang ditemukan pada source lokal

Temuan berikut membuktikan kontrak klien saat ini, bukan verifikasi kondisi database live.

| Sumber/data | Temuan |
| --- | --- |
| `profiles` | Auth membaca `id`, `is_active`, `role` |
| Role | `Admin`, `PIC Pemasangan`, `Tim Pemasangan`, `Tim Service` |
| `master_komponen` | `id`, `komponen_id`, `jenis_komponen`, `nomor_stiker`, `kondisi`, `boleh_dipakai`, `fungsi_terganggu`, `keterangan`, `status_penggunaan`, `updated_at`, `updated_by` |
| Jenis | `Kepala`, `Batang`, `Tabung` |
| Kondisi | `OK`, `Rusak Ringan`, `Rusak Berat`, `Service`, `Hilang` |
| Kelayakan | `Ya`, `Tidak` pada `boleh_dipakai` |
| `riwayat_checking_komponen` | Stiker, jenis, kondisi terbaru, kelayakan, gangguan fungsi, catatan, petugas, tanggal pemeriksaan, timestamp |
| `riwayat_service` | Stiker, jenis, masalah, tindakan, biaya, teknisi, kondisi hasil, kelayakan, gangguan fungsi, catatan, timestamp |
| `audit_log` | Model mengenal old/new value, entity, user, dan timestamp; keberadaan trigger dan cakupannya belum terverifikasi |

Referensi yang diperiksa:

- [Enum domain](../mgrs-release/lib/domain/models/domain_enums.dart)
- [Model profil dan komponen](../mgrs-release/lib/domain/models/profile_and_inventory.dart)
- [Model pemeriksaan dan audit](../mgrs-release/lib/domain/models/checking_and_audit.dart)
- [Model servis](../mgrs-release/lib/domain/models/invoice_and_service.dart)
- [Service maintenance Supabase](../mgrs-release/lib/data/services/supabase_maintenance_service.dart)
- [Service autentikasi](../mgrs-release/lib/data/services/supabase_auth_service.dart)
- [Service inventaris dan lookup stiker](../mgrs-release/lib/data/services/supabase_inventory_service.dart)
- [Hak akses route lama](../mgrs-release/lib/domain/auth/route_permissions.dart)

### 4.3 Kebutuhan integrasi yang wajib dipenuhi

**INT-01 — Identitas:** lookup mengikuti format barcode sebenarnya dan identitas master. Relasi baru memakai ID master yang stabil; stiker/jenis tetap tersedia untuk kompatibilitas riwayat lama. Keunikan stiker dan format barcode harus diuji dengan sampel ketiga jenis.

**INT-02 — Batas mutasi:** hanya kondisi, kelayakan, gangguan fungsi, keterangan yang relevan, metadata perubahan, dan riwayat maintenance yang boleh ditulis. `status_penggunaan`, pemasangan, order, alokasi, dan reservasi tidak boleh diubah sebagai efek samping, termasuk melalui trigger database.

**INT-03 — Atomisitas:** perubahan master, riwayat, audit kondisi sebelumnya/sesudahnya, dan penyelesaian tugas berkala bila relevan harus berada dalam satu transaksi server. Jika satu bagian gagal, semua dibatalkan.

**INT-04 — Konflik data:** ketika komponen berubah sesudah detail dibaca, server menolak pembaruan berdasarkan versi lama. Aplikasi menampilkan kondisi terbaru dan meminta petugas meninjau kembali. Mekanisme versi harus mencakup semua aplikasi penulis pada database bersama.

**INT-05 — Pencegahan duplikasi:** setiap aksi simpan memiliki ID permintaan unik. Ketika respons terputus setelah transaksi berhasil, percobaan ulang mengembalikan hasil yang sama, tanpa riwayat ganda. Pemeriksaan baru yang disengaja tetap diperbolehkan.

**INT-06 — Jadwal:** dibutuhkan penyimpanan periode, target komponen, dan relasi ke pemeriksaan penyelesai. Sumber yang diperiksa belum menunjukkan kontrak jadwal bulanan, sehingga kemampuan ini belum boleh diasumsikan tersedia. Desain skema harus memeriksa struktur live sebelum mengusulkan tambahan secara kompatibel.

**INT-07 — Konsistensi nilai:** usulan validasi MVP menetapkan kondisi `Rusak Berat`, `Service`, dan `Hilang` tidak boleh disimpan dengan kelayakan `Ya`. Untuk `Rusak Ringan`, petugas memilih kelayakan dan menjelaskan gangguan. Validasi akhir harus diperiksa terhadap aturan database yang berlaku; label kondisi tidak diubah diam-diam.

**INT-08 — Catatan:** riwayat menyimpan catatan kejadian, sedangkan master menyimpan ringkasan kondisi terkini. Catatan master lama tidak boleh dihapus karena isian kosong tanpa tindakan pengguna yang jelas. Placeholder historis seperti `-` ditampilkan sebagai informasi kosong, bukan temuan baru.

### 4.4 Perbedaan penting dari kode MGRS lama

1. `submitCheckingKomponen` dan `completeServiceKomponen` menghitung status melalui `_deriveStatus` lalu menulis `status_penggunaan`. Menggunakan fungsi tersebut tanpa penyesuaian akan melanggar batas aplikasi baru. Endpoint/transaksi baru perlu mempertahankan status penggunaan dan diuji terhadap trigger serta semua pembaca terkait.
2. Fungsi tersebut melakukan insert riwayat dan update master sebagai dua permintaan terpisah. Pola ini belum memenuhi transaksi atomik yang dibutuhkan produk baru.
3. Route checking/service lama hanya mengizinkan Admin dan Tim Service. Aplikasi baru juga mengizinkan Tim Pemasangan. Hak akses database live harus diperiksa; mengubah navigasi klien saja tidak cukup.
4. Antrean servis lama difilter berdasarkan `status_penggunaan = Service`. Aplikasi baru tidak boleh bergantung pada filter ini untuk mengizinkan pencatatan servis.
5. Model riwayat lama belum membuktikan adanya periode bulanan, ID permintaan, relasi stabil ke ID master, dan kondisi sebelumnya. Jangan menganggap kemampuan tersebut sudah ada hanya karena layar riwayat tersedia.

Temuan ini adalah batas integrasi yang perlu ditangani pada tahap fondasi, bukan laporan bug yang sudah diperbaiki. Meskipun aplikasi baru tidak memiliki alur pemasangan, perubahan kondisi pada database bersama tetap terlihat oleh aplikasi MGRS dan dapat memengaruhi keputusan kelayakan yang sudah ada di sana.

### 4.5 Keamanan dan privasi

- Gunakan autentikasi MGRS dan verifikasi profil aktif serta role pada server.
- Kebijakan database membatasi operasi pada data dan field yang dibutuhkan; jangan memberi akses luas ke domain order atau pengguna.
- Kunci administratif/service-role tidak boleh berada di aplikasi klien. Konfigurasi publik mengikuti mekanisme klien yang sah.
- Identitas pencatat dan timestamp audit ditentukan oleh server, bukan dipercayai dari payload klien.
- Riwayat disimpan tanpa fungsi hapus/edit pada MVP. Kebijakan retensi mengikuti pengelolaan MGRS dan tidak diubah oleh aplikasi baru.
- Pesan UI menggunakan bahasa Indonesia yang ringkas; jangan menampilkan exception mentah, token, query, atau stack trace.

### 4.6 Persyaratan nonfungsional dan QA

- Detail dicari sesuai kode, riwayat dan daftar jadwal memakai pagination. Jangan memuat seluruh data saat login atau membuka scanner.
- Kamera dihentikan setelah hasil diterima, ketika layar scanner ditinggalkan, dan saat aplikasi masuk latar belakang.
- Target sentuh minimal 44 × 44 unit logis; status memiliki label teks; formulir tetap dapat digunakan saat ukuran teks sistem diperbesar.
- Penyimpanan membutuhkan koneksi. Data gagal dimuat tidak disajikan sebagai kondisi terbaru yang terkonfirmasi.
- Keberhasilan build/test tidak menggantikan pengujian kamera pada perangkat nyata dan integrasi pada lingkungan uji dengan kebijakan server yang setara.

| Skenario wajib | Hasil yang diharapkan |
| --- | --- |
| Login tiga role yang disepakati | Baca dan tulis maintenance diperbolehkan |
| PIC Pemasangan, akun nonaktif, atau tanpa sesi | Akses yang dilindungi ditolak server |
| Scan masing-masing jenis, kode manual, barcode tidak dikenal | Detail tepat atau pesan kesalahan yang sesuai |
| Kamera ditolak, frame berulang, keluar dari scanner | Input manual tersedia; tidak ada aksi ganda; kamera berhenti |
| Pemeriksaan OK dan rusak, servis berhasil atau belum berhasil | Nilai dan riwayat sesuai input serta validasi |
| Gagal pada salah satu bagian transaksi | Tidak ada perubahan parsial |
| Respons putus setelah transaksi berhasil, lalu coba lagi | Satu transaksi dan satu riwayat |
| Dua petugas/aplikasi mengubah komponen bersamaan | Konflik terdeteksi, tidak menimpa tanpa peninjauan |
| Master berstatus penggunaan Dipakai/Tersedia/Service/Hilang | Pemeriksaan tidak mengubah status penggunaan maupun relasi operasional |
| Sebelum Sabtu, Sabtu 00.00, Minggu akhir hari, Senin 00.00 | Status dan kelayakan penyelesaian periode benar |
| Bulan dengan lima Sabtu, Februari kabisat/nonkabisat, ganti tahun | Sabtu keempat dan pasangan Minggu benar |
| Pemeriksaan manual sebelum jadwal, servis, buka detail saja | Tidak otomatis menyelesaikan tugas bulanan |
| Hasil pemeriksaan rusak, tetapi pemeriksaan fisik selesai | Tugas selesai, kondisi tetap sesuai hasil |
| Dua kali cek pada periode sama, dua periode terlambat | Hitungan per periode tidak ganda; satu pemeriksaan tidak menutup dua periode |
| Komponen baru sesudah pembukaan periode, aktivasi di tengah bulan | Tidak mengubah target beku atau menciptakan tunggakan retroaktif |
| Baca hasil dari MGRS lama setelah update baru | Kondisi dan riwayat tetap kompatibel; tidak ada perubahan pemasangan/alokasi |

## 5. Risks & Roadmap

### 5.1 Risiko dan penanganan

| Risiko | Dampak | Penanganan |
| --- | --- | --- |
| Trigger/service lama mengubah status penggunaan | Efek samping pada operasional MGRS | Audit write path dan trigger; uji invariant sebelum aktivasi |
| RLS menolak Tim Pemasangan atau terlalu longgar | Fitur gagal atau akses melampaui kebutuhan | Verifikasi tiga role di server dengan kasus positif dan negatif |
| Pembaruan dari beberapa aplikasi | Kondisi terbaru tertimpa | Transaksi dan pemeriksaan versi lintas penulis |
| Riwayat tersimpan tetapi master gagal | Data tidak konsisten | Satu transaksi server dan idempotensi |
| Riwayat lama hanya terhubung melalui stiker | Salah relasi bila stiker berubah/tidak unik | Audit identitas; gunakan ID stabil pada relasi baru |
| Jadwal dianggap setiap 30 hari atau Sabtu terakhir | Tugas muncul pada tanggal yang salah | Aturan kalender eksplisit dan pengujian batas waktu |
| Skema jadwal belum tersedia | Tugas lintas perangkat tidak konsisten | Desain penyimpanan periode pada database bersama setelah audit |
| Komponen tidak dapat diperiksa fisik | Tunggakan tidak bisa dianggap selesai | Tampilkan keadaan terbuka secara jujur; evaluasi aturan pengecualian setelah pilot |

### 5.2 Tahap pengembangan

**Tahap 0 — Fondasi dan kontrak integrasi**

- Tinjau usulan detail MVP dalam PRD, khususnya pemeriksaan di luar jendela, target bulanan, dan kelayakan.
- Tetapkan perangkat/platform, framework, metode distribusi, serta target performa pilot.
- Verifikasi database live secara read-only: tabel, field, enum, constraint, indeks, keunikan kode, trigger, RLS, dan seluruh jalur penulisan yang relevan.
- Tentukan perubahan backend terkecil untuk transaksi kondisi/riwayat, akses Tim Pemasangan, konflik, idempotensi, dan jadwal bulanan.
- Siapkan lingkungan uji. Keluaran: kontrak integrasi dan rencana implementasi yang dapat ditinjau; belum mengubah produksi.

**MVP — Scan, kondisi, pemeriksaan, servis, dan jadwal**

- Implementasi login tiga role, scan/manual, detail, form pemeriksaan, form servis, serta riwayat.
- Implementasi periode bulanan, daftar target, dan penyelesaian tugas dengan label terlambat.
- Verifikasi seluruh acceptance criteria dan matriks QA pada perangkat target serta database uji.
- Pilot dengan perwakilan tiga role dan sampel ketiga jenis komponen. Rilis jika seluruh gerbang penerimaan terpenuhi.

**v1.1 — Peningkatan berdasarkan pilot**

Kandidat: foto temuan, checklist per jenis yang divalidasi tim, pengingat, dan aturan pengecualian komponen yang tidak dapat diperiksa. Kandidat ini bukan komitmen scope saat ini.

**v2.0 — Kebutuhan lanjutan jika terbukti diperlukan**

Kandidat: draft offline/sinkronisasi, ekspor rekap, dan analisis kerusakan berulang. Tetap mempertahankan pemisahan dari pemasangan dan alokasi.

### 5.3 Definisi selesai MVP

- Seluruh fungsi MVP dapat dijalankan end-to-end oleh ketiga role pada perangkat target.
- Tidak ada perubahan status penggunaan atau data pemasangan/alokasi akibat pencatatan maintenance.
- Kondisi, riwayat, audit, dan status tugas yang relevan tersimpan atomik serta tahan pengulangan permintaan.
- Aturan Sabtu keempat dan Minggu berikutnya terbukti melalui pengujian kalender dan tampilan jadwal.
- Kegagalan jaringan, sesi kedaluwarsa, kode tidak dikenal, dan konflik data memiliki hasil yang teruji.
- Bukti test, build, QA perangkat, dan verifikasi integrasi dicatat terpisah. Saat ini dokumen ini belum menyatakan salah satunya lulus.

### 5.4 Keputusan yang perlu ditetapkan sebelum implementasi

| Keputusan | Posisi dokumen ini |
| --- | --- |
| Platform dan framework | Belum dipilih; tentukan dari perangkat lapangan |
| Anggaran dan tenggat | Belum diberikan; tidak ada estimasi komitmen dalam PRD |
| Rincian jadwal dan akses | Aturan utama disepakati; rincian pada 2.1 dan 2.5 adalah usulan MVP |
| Checklist, foto, pengingat, offline | Ditunda dari MVP agar cakupan tetap kecil |
| Kebijakan nilai kondisi dan kelayakan | Pertahankan enum lama; validasi usulan harus dicocokkan dengan aturan backend |
| Skema jadwal dan endpoint transaksi | Kebutuhan ditetapkan; desain final menunggu audit database |

### 5.5 Pemeriksaan dokumen

- Keputusan pengguna dibedakan dari usulan dan ketidakpastian teknis.
- Ketiga jenis komponen, tiga role, database bersama, dan batas tanpa pemasangan tercakup.
- Waktu kalender, terlambat, duplikasi, akses server, dan efek samping kode lama memiliki kriteria penerimaan.
- Tidak ada stack, migrasi produksi, atau hasil pengujian aplikasi yang dinyatakan sebagai fakta tanpa bukti.
