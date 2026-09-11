# Design Spec: Fitur Pilih Unit Pemasangan Opsional & Penyeimbang Pemakaian (Wear-and-Tear Balancing)

## 1. Latar Belakang & Tujuan
Pada operasional MGRS, setiap pesanan rental memiliki jumlah unit blower yang harus dipasang (`jumlah_unit`). Di aplikasi web lama, tim lapangan diwajibkan mengalokasikan unit dan membuat laporan setelah pakai yang membebani. 

Fitur ini dirancang khusus untuk mobile:
1. **100% Opsional:** Tim Pemasangan tidak diwajibkan mengisi unit dan tidak dibebani form laporan kaku. Jika terburu-buru, order tetap bisa berjalan normal.
2. **Kombinasi 3 Komponen per Unit:** 1 unit blower terdiri dari kombinasi 3 komponen: **Kepala (`K-xx`)**, **Batang (`B-xx`)**, dan **Tabung (`T-xx`)**.
3. **Penyeimbang Umur Unit (Load Balancing):** Menampilkan riwayat/counter pemakaian masing-masing komponen (`Terpakai X kali`) dan mengurutkan komponen yang paling jarang dipakai di posisi teratas, sehingga rotasi pemakaian mesin merata dan memperpanjang umur aset.
4. **Alur Cepat (Scanner & Rekomendasi 1-Tap):** Menyediakan pemindaian barcode/QR kamera langsung dan tombol *Rekomendasi Tersegar* yang otomatis memilihkan kombinasi komponen tersegar.

---

## 2. Peran & Akses Pengguna
* **Tim Pemasangan & Admin:** Memiliki akses untuk memilih, mengubah, atau menghapus alokasi komponen unit pada layar `OrderDetailScreen`.
* **PIC Pemasangan:** Dapat melihat unit mana saja yang terpasang pada order tersebut (read-only/monitoring).

---

## 3. Struktur Data & Model

### 3.1 Model Unit & Komponen
1 Unit Blower Sewa terdiri dari 3 slot komponen:
* `kepala`: Nomor stiker komponen Kepala (misal `K-05`)
* `batang`: Nomor stiker komponen Batang (misal `B-12`)
* `tabung`: Nomor stiker komponen Tabung (misal `T-08`)

Model Dart:
```dart
class AllocatedUnit {
  final int unitIndex; // 1, 2, ...
  final String? kepalaSticker;
  final String? batangSticker;
  final String? tabungSticker;

  const AllocatedUnit({
    required this.unitIndex,
    this.kepalaSticker,
    this.batangSticker,
    this.tabungSticker,
  });

  bool get isEmpty => kepalaSticker == null && batangSticker == null && tabungSticker == null;
  bool get isComplete => kepalaSticker != null && batangSticker != null && tabungSticker != null;

  AllocatedUnit copyWith({
    String? kepalaSticker,
    String? batangSticker,
    String? tabungSticker,
    bool clearKepala = false,
    bool clearBatang = false,
    bool clearTabung = false,
  });
}
```

### 3.2 Format Penyimpanan (Metadata Aman)
Alokasi unit disimpan pada `catatan_orderan` di tabel `orderan_sewa` menggunakan tag metadata terstruktur:
```
[UNIT_ALOKASI: K-05+B-12+T-08 | K-03+B-01+T-02]
```
* Kompatibel penuh dengan skema database Supabase yang ada (tanpa migrasi tabel baru yang berisiko).
* Tag ini otomatis diabaikan oleh `cleanNote` sehingga catatan publik/deskripsi event tetap bersih.

### 3.3 Penghitungan Counter Pemakaian (Usage Count)
* Gateway menghitung pemakaian setiap stiker komponen secara dinamis dari riwayat seluruh orderan yang mencatat stiker tersebut.
* Hasil berupa `Map<String, int>` (misal: `{'K-01': 14, 'K-05': 3, 'B-01': 8, ...}`).
* Komponen yang belum pernah dipakai memiliki count = `0`.
* Saat order selesai, komponen yang teralokasi otomatis tercatat count +1 secara natural.

---

## 4. Rancangan Antarmuka Pengguna (UI/UX)

### 4.1 Kartu Alokasi di `OrderDetailScreen`
Ditempatkan di bawah Ringkasan Event:
1. **Header:**
   * Judul: *"Alokasi Unit Blower (X Unit)"*
   * Badge: *"Opsional"*
   * Aksi Cepat:
     * Tombol *"✨ Rekomendasi Tersegar"*
     * Tombol *"📷 Scan Cepat"*
2. **Daftar Unit:**
   * Dibuatkan kartu untuk setiap unit (Unit #1 s/d Unit #N sesuai `jumlah_unit` order).
   * Tiap unit memiliki 3 baris slot:
     * **Kepala:** Jika terisi menampilkan badge kode stiker, count pemakaian (warna hijau/kuning/merah), dan tombol hapus (x). Jika kosong, menampilkan tombol `+ Pilih Kepala`.
     * **Batang:** Sama seperti Kepala.
     * **Tabung:** Sama seperti Kepala.

### 4.2 Dialog Pemilih Komponen (`ComponentPickerSheet`)
Saat slot (misal: *Pilih Kepala*) diklik:
* Menampilkan daftar komponen yang sesuai jenisnya (`Kepala`, `Batang`, atau `Tabung`) dari `master_komponen`.
* Hanya menampilkan komponen yang `boleh_dipakai == 'Ya'` dan bukan `Rusak Berat` / `Hilang`.
* **Urutan Cerdas:** Komponen diurutkan dari **count pemakaian terendah ke tertinggi**.
* **Indikator Visual:**
  * 🟢 `0 - 5x pakai` (Sangat Disarankan / Istirahat Cukup)
  * 🟡 `6 - 15x pakai` (Sedang)
  * ⚪ `> 15x pakai` (Cukup Sering Dipakai)
* Dilengkapi kolom pencarian stiker untuk kemudahan jika teknisi mencari kode tertentu.

### 4.3 Rekomendasi Otomatis (1-Tap Auto Allocation)
* Saat tombol *"✨ Rekomendasi Tersegar"* ditekan:
  * Sistem mengambil komponen dengan kondisi `OK` yang pemakaiannya paling sedikit untuk setiap slot yang masih kosong.
  * Menghindari penggunaan stiker yang sama pada lebih dari satu unit dalam order yang sama.
  * Menampilkan snackbar konfirmasi alokasi berhasil.

### 4.4 Integrasi Barcode Scanner Kamera
* Saat tombol *"📷 Scan Cepat"* ditekan:
  * Membuka pemindai barcode / QR.
  * Ketika barcode stiker terdeteksi (misal `K-05`), sistem memeriksa prefix jenisnya (`K-` = Kepala, `B-` = Batang, `T-` = Tabung).
  * Menempatkan stiker tersebut pada slot kosong pertama unit yang relevan.
  * Terdengar haptic / suara sukses pemindaian.

---

## 5. Rencana Pengujian
1. **Model & Parser Tests:**
   * Serialisasi dan deserialisasi format tag `[UNIT_ALOKASI: ...]`.
   * Penghitungan jumlah slot unit sesuai `jumlah_unit`.
   * Pemisahan `cleanNote` tanpa mengikutsertakan tag alokasi.
2. **Gateway & Logic Tests:**
   * Menghitung count pemakaian komponen dari riwayat order.
   * Algoritma rekomendasi memilihkan komponen dengan pemakaian paling rendah.
3. **Widget Tests:**
   * Kartu alokasi unit dirender dengan jumlah slot unit yang tepat.
   * Pemilihan komponen memperbarui slot unit dan menyimpan metadata.
   * Tombol rekomendasi mengisi seluruh slot yang kosong dengan komponen tersegar.
   * Alokasi unit tetap opsional: order tetap bisa diselesaikan tanpa mengisi unit.
