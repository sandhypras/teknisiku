# Product Requirements Document

## Aplikasi Si Teknisi

| Informasi | Nilai |
| --- | --- |
| Versi | 1.2 |
| Tanggal update | 28 Juni 2026 |
| Jenis proyek | Project kuliah |
| Platform | Flutter Android, Flutter Web, dan Chrome untuk debug mobile |
| Backend | Supabase |
| Wilayah layanan awal | Solo |
| Jumlah anggota tim | 3 orang |

---

## 1. Ringkasan Produk

Si Teknisi adalah aplikasi marketplace jasa teknisi yang menghubungkan customer dengan penyedia jasa teknisi di wilayah Solo.

Customer dapat mencari teknisi, melihat layanan, memilih teknisi, membuat pesanan, menentukan alamat dan jadwal servis, menyetujui hasil diagnosis, serta memberikan ulasan setelah pekerjaan selesai.

Teknisi dapat mendaftar, melengkapi data diri, mengajukan verifikasi, menyediakan layanan, menerima atau menolak pesanan, melakukan pemeriksaan, menentukan biaya, dan memperbarui status pekerjaan.

Admin mengakses sistem melalui Flutter Web untuk memverifikasi teknisi, menyetujui layanan, mengelola customer, teknisi, pesanan, pembayaran, ulasan, komisi, dan laporan.

Seluruh aplikasi dikembangkan menggunakan Flutter. Supabase digunakan untuk autentikasi, database, penyimpanan file, dan pengelolaan data backend.

### Update Versi 1.2

PRD versi ini menyesuaikan perubahan implementasi terbaru pada aplikasi:

- Dashboard admin terhubung ke Supabase untuk pengelolaan customer, teknisi, kategori, layanan, pesanan, pembayaran, ulasan, komisi, laporan, dan pengaturan.
- Admin dapat melakukan CRUD dan melihat detail data utama.
- Kategori layanan dapat dibuat dari dashboard admin dan memiliki icon gambar yang diunggah ke Supabase Storage.
- Icon kategori yang diunggah admin ditampilkan pada dashboard admin, home guest, dan home customer.
- Teknisi dapat mengunggah foto wajah/selfie dan foto KTP untuk verifikasi akun.
- Dashboard admin dapat melihat dokumen/foto verifikasi teknisi yang diunggah.
- Teknisi memiliki halaman Order Saya untuk melihat dan mengelola pesanan yang masuk.
- Form pemesanan customer diperluas sesuai struktur database alamat dan pesanan.
- Customer dapat memakai lokasi aktif saat ini untuk mengisi koordinat dan alamat layanan.
- Form pemesanan dapat membuat alamat baru langsung dari halaman order apabila customer tidak memakai alamat tersimpan.
- Aplikasi menggunakan package `geolocator` untuk mengambil koordinat dan `geocoding` untuk reverse geocoding alamat.
- Android membutuhkan permission `ACCESS_COARSE_LOCATION` dan `ACCESS_FINE_LOCATION` untuk fitur lokasi aktif.
- Data alamat baru dari form pemesanan disimpan ke tabel `customer_addresses` dan dipakai sebagai `address_id` pada tabel `orders`.
- Teknisi dapat menyimpan koordinat lokasi layanan dari lokasi aktif perangkat.
- Home customer dapat mengurutkan teknisi berdasarkan jarak terdekat dari alamat/lokasi customer.
- Pembayaran customer diintegrasikan dengan Midtrans Sandbox melalui Supabase Edge Function.
- Customer dapat membuka halaman Snap Midtrans dari pesanan yang berstatus menunggu pembayaran.
- Webhook Midtrans memperbarui status pembayaran di Supabase setelah notifikasi diterima.

---

## 2. Latar Belakang

Masyarakat sering mengalami kesulitan menemukan teknisi yang sesuai untuk memperbaiki perangkat seperti komputer, laptop, handphone, printer, CCTV, dan jaringan.

Informasi mengenai keahlian teknisi, harga layanan, area pelayanan, dan ketersediaan teknisi sering tidak tersedia secara jelas.

Si Teknisi dibuat untuk menyediakan platform yang mempertemukan customer dengan teknisi secara lebih terstruktur, aman, dan mudah digunakan.

---

## 3. Tujuan Produk

Tujuan utama aplikasi Si Teknisi adalah:

1. Memudahkan customer menemukan teknisi di wilayah Solo.
2. Memudahkan teknisi menawarkan layanan kepada customer.
3. Menyediakan proses pemesanan jasa yang terstruktur.
4. Menampilkan perkiraan harga sebelum customer melakukan pemesanan.
5. Memberikan mekanisme verifikasi teknisi oleh admin.
6. Menyimpan riwayat pesanan dan pekerjaan teknisi.
7. Menyediakan sistem komisi bagi pengelola aplikasi.
8. Menjadi project kuliah yang menunjukkan penerapan Flutter, Supabase, autentikasi, role, CRUD, dan transaksi.

---

## 4. Ruang Lingkup Produk

### 4.1 Platform

Aplikasi terdiri dari:

- Flutter Android untuk guest
- Flutter Android untuk customer
- Flutter Android untuk teknisi
- Flutter Web untuk admin
- Supabase sebagai backend

### 4.2 Jenis Layanan

Kategori layanan awal meliputi:

- Servis komputer
- Servis laptop
- Servis handphone
- Servis printer
- Servis CCTV
- Instalasi dan perbaikan jaringan

### 4.3 Model Pelayanan

Teknisi datang langsung ke alamat customer.

---

## 5. Target Pengguna

### 5.1 Guest

Guest adalah pengguna yang belum login.

Guest dapat melihat:

- Halaman utama
- Daftar kategori
- Daftar layanan
- Daftar teknisi
- Profil teknisi
- Perkiraan harga layanan

Guest harus login apabila ingin membuat pesanan.

### 5.2 Customer

Customer adalah pengguna yang membutuhkan jasa teknisi.

Customer dapat:

- Mendaftar dan login
- Melengkapi profil
- Menyimpan alamat
- Menggunakan lokasi aktif saat ini sebagai alamat layanan
- Melihat layanan
- Memilih teknisi sendiri
- Membuat pesanan
- Memilih beberapa layanan
- Mengunggah foto kerusakan
- Mengisi alamat dan jadwal
- Melihat status pesanan
- Menyetujui biaya
- Melakukan pembayaran
- Melihat invoice
- Mendapatkan garansi
- Memberikan rating dan ulasan

### 5.3 Teknisi

Teknisi adalah pengguna yang menyediakan jasa.

Teknisi dapat:

- Mendaftar sendiri
- Melengkapi profil
- Mengunggah dokumen
- Mengajukan verifikasi
- Menambahkan layanan
- Menentukan perkiraan harga
- Mengatur jadwal kerja
- Menerima atau menolak pesanan
- Mengisi diagnosis
- Menambahkan harga jasa
- Menambahkan sparepart
- Memperbarui status pesanan
- Mengunggah foto pekerjaan
- Melihat pendapatan

### 5.4 Admin

Admin mengakses aplikasi melalui Flutter Web.

Admin dapat:

- Login ke dashboard admin
- Mengelola customer
- Mengelola teknisi
- Memverifikasi teknisi
- Menonaktifkan teknisi
- Mengelola kategori
- Menyetujui layanan
- Mengelola pesanan
- Mengelola pembayaran
- Mengelola ulasan
- Mengatur komisi
- Melihat laporan

---

## 6. Role dan Hak Akses

| Fitur | Guest | Customer | Teknisi | Admin |
| --- | --- | --- | --- | --- |
| Melihat halaman utama | Ya | Ya | Ya | Tidak |
| Melihat kategori | Ya | Ya | Ya | Ya |
| Melihat teknisi | Ya | Ya | Tidak | Ya |
| Membuat pesanan | Tidak | Ya | Tidak | Tidak |
| Menambahkan layanan | Tidak | Tidak | Ya | Ya |
| Menerima pesanan | Tidak | Tidak | Ya | Tidak |
| Memverifikasi teknisi | Tidak | Tidak | Tidak | Ya |
| Menyetujui layanan | Tidak | Tidak | Tidak | Ya |
| Mengelola pembayaran | Tidak | Tidak | Tidak | Ya |
| Memberikan ulasan | Tidak | Ya | Tidak | Tidak |
| Melihat laporan | Tidak | Tidak | Terbatas | Ya |

Guest tidak disimpan sebagai role dalam database. Guest adalah pengguna yang belum melakukan autentikasi.

Role yang disimpan dalam database:

- customer
- technician
- admin

---

## 7. Fitur Utama

### 7.1 Autentikasi

Metode autentikasi menggunakan email dan password melalui Supabase Auth.

Fitur autentikasi:

- Registrasi customer
- Registrasi teknisi
- Login
- Logout
- Lupa password
- Pengecekan role
- Pengalihan halaman berdasarkan role
- Validasi status akun

Admin tidak dapat didaftarkan melalui halaman registrasi umum. Akun admin dibuat langsung melalui database atau dashboard Supabase.

### 7.2 Registrasi Customer

Data customer:

- Nama lengkap
- Email
- Password
- Nomor telepon
- Foto profil opsional
- Alamat

Setelah registrasi berhasil, akun customer langsung aktif.

### 7.3 Registrasi Teknisi

Data teknisi:

- Nama lengkap
- Email
- Password
- Nomor telepon
- Alamat
- Foto profil
- Foto KTP
- Foto wajah/selfie
- Sertifikat
- Pengalaman kerja
- Keahlian
- Area layanan
- Deskripsi profil

Status awal teknisi:

```text
pending
```

Teknisi tidak dapat menampilkan jasa sebelum diverifikasi oleh admin.

Status verifikasi teknisi:

```text
pending
verified
rejected
inactive
```

### 7.4 Verifikasi Teknisi

Admin melihat data dan dokumen teknisi.

Admin dapat:

- Menyetujui teknisi
- Menolak teknisi
- Menonaktifkan teknisi
- Melihat dokumen teknisi
- Melihat foto wajah/selfie teknisi
- Melihat foto KTP teknisi
- Melihat detail profil teknisi
- Mengelola data teknisi apabila diperlukan

Setelah disetujui, status teknisi berubah menjadi:

```text
verified
```

Teknisi yang sudah diverifikasi dapat membuat dan menampilkan layanan setelah layanan tersebut disetujui admin.

### 7.5 Pengelolaan Kategori

Kategori dibuat dan dikelola oleh admin.

Data kategori:

- Nama kategori
- Icon gambar
- Deskripsi
- Status aktif
- Tanggal dibuat

Icon gambar kategori diunggah oleh admin ke Supabase Storage dan URL/path file disimpan pada kolom `icon_url`.

Icon kategori ditampilkan pada:

- Dashboard admin
- Home guest
- Home customer
- Daftar kategori layanan

Kategori awal:

- Komputer
- Laptop
- Handphone
- Printer
- CCTV
- Jaringan

### 7.6 Pengelolaan Layanan Teknisi

Teknisi dapat menambahkan layanan sendiri.

Data layanan:

- Nama layanan
- Kategori
- Deskripsi
- Harga perkiraan
- Estimasi durasi
- Jadwal tersedia
- Foto layanan
- Status aktif
- Status persetujuan

Status persetujuan layanan:

```text
pending
approved
rejected
```

Layanan hanya tampil kepada customer apabila:

- Teknisi berstatus verified
- Layanan berstatus approved
- Layanan berstatus aktif

Teknisi tidak dapat memberikan diskon atau promo pada versi awal.

### 7.7 Pencarian Teknisi

Customer dapat:

- Melihat daftar teknisi
- Melihat teknisi berdasarkan kategori
- Mencari berdasarkan nama
- Melihat teknisi yang berada di sekitar wilayah customer berdasarkan koordinat lokasi
- Melihat rating teknisi
- Melihat jumlah pekerjaan selesai
- Melihat layanan yang ditawarkan

Customer memilih teknisi sendiri. Admin tidak menentukan teknisi untuk pesanan customer.

### 7.8 Profil Teknisi

Profil teknisi menampilkan:

- Foto profil
- Nama teknisi
- Keahlian
- Pengalaman
- Area layanan
- Rating
- Jumlah pekerjaan selesai
- Daftar layanan
- Perkiraan harga
- Status verifikasi

Informasi sensitif seperti KTP dan dokumen pribadi tidak ditampilkan kepada customer.

### 7.9 Alamat Customer

Customer dapat menyimpan lebih dari satu alamat.

Data alamat:

- Label alamat
- Nama penerima
- Nomor telepon
- Alamat lengkap
- Kota
- Kecamatan
- Kelurahan
- Kode pos
- Latitude
- Longitude
- Status alamat utama

Customer dapat memilih alamat yang sudah tersimpan atau membuat alamat baru pada form pemesanan.

Customer dapat menggunakan lokasi aktif saat ini. Sistem mengambil izin lokasi perangkat, membaca koordinat latitude dan longitude, lalu mencoba mengisi alamat menggunakan reverse geocoding.

Google Maps dapat digunakan untuk memilih titik alamat customer apabila API key tersedia. Pada MVP, pengambilan lokasi aktif menggunakan Geolocator dan Geocoding.

Customer tidak dapat melihat lokasi teknisi secara langsung. Aplikasi tidak menggunakan live tracking.

### 7.10 Pemesanan Layanan

Customer dapat memesan satu atau beberapa layanan dalam satu pesanan.

Data pemesanan:

- Customer
- Teknisi
- Daftar layanan
- Deskripsi kerusakan
- Foto kerusakan
- Alamat layanan
- Label alamat
- Nama penerima
- Nomor telepon penerima
- Kota
- Kecamatan
- Kelurahan
- Kode pos
- Titik lokasi latitude dan longitude
- Tanggal kunjungan
- Jam kunjungan
- Catatan tambahan

Form pemesanan customer harus menampilkan ringkasan teknisi, layanan yang dipilih, estimasi total, pilihan alamat tersimpan/alamat baru, tombol gunakan lokasi saat ini, jadwal kunjungan, jam kunjungan, dan deskripsi masalah.

Alur alamat pada form pemesanan:

1. Customer dapat memilih alamat tersimpan.
2. Customer dapat memilih mode alamat baru.
3. Pada mode alamat baru, customer mengisi label alamat, nama penerima, nomor HP, alamat lengkap, kota, kecamatan, kelurahan, dan kode pos.
4. Customer dapat menekan tombol gunakan lokasi saat ini.
5. Sistem meminta izin lokasi perangkat.
6. Sistem mengambil latitude dan longitude dari perangkat.
7. Sistem mencoba melakukan reverse geocoding untuk mengisi alamat.
8. Alamat baru disimpan ke tabel `customer_addresses`.
9. Pesanan dibuat dengan `address_id` dari alamat yang dipilih atau alamat baru tersebut.

Pesanan langsung dikirim kepada teknisi tanpa persetujuan admin.

Customer tidak dapat membatalkan pesanan setelah pesanan berhasil dibuat.

Teknisi dapat menerima atau menolak pesanan.

### 7.11 Status Pesanan

Status pesanan:

```text
waiting_confirmation
accepted
on_the_way
inspection
waiting_price_approval
in_progress
waiting_payment
completed
rejected
price_rejected
```

Keterangan:

| Status | Keterangan |
| --- | --- |
| waiting_confirmation | Menunggu konfirmasi teknisi |
| accepted | Pesanan diterima teknisi |
| on_the_way | Teknisi menuju lokasi |
| inspection | Teknisi sedang melakukan pemeriksaan |
| waiting_price_approval | Menunggu persetujuan biaya dari customer |
| in_progress | Pekerjaan sedang dilakukan |
| waiting_payment | Menunggu pembayaran |
| completed | Pekerjaan selesai |
| rejected | Pesanan ditolak teknisi |
| price_rejected | Biaya ditolak customer |

### 7.12 Diagnosis dan Persetujuan Biaya

Setelah melakukan pemeriksaan, teknisi wajib memasukkan:

- Hasil diagnosis
- Penjelasan kerusakan
- Biaya jasa
- Daftar sparepart
- Harga sparepart
- Total biaya
- Estimasi waktu pengerjaan

Customer harus menyetujui total biaya sebelum teknisi memulai pekerjaan.

Apabila customer menyetujui biaya, status berubah menjadi:

```text
in_progress
```

Apabila customer menolak biaya, status berubah menjadi:

```text
price_rejected
```

### 7.13 Dokumentasi Pekerjaan

Teknisi wajib mengunggah:

- Foto sebelum pengerjaan
- Foto sesudah pengerjaan
- Catatan hasil pekerjaan

Dokumentasi disimpan melalui Supabase Storage.

### 7.14 Pembayaran

Metode pembayaran:

- Tunai
- Transfer bank
- Midtrans Sandbox

Untuk pembayaran tunai:

- Teknisi menandai bahwa pembayaran sudah diterima
- Admin dapat melihat status pembayaran

Untuk pembayaran transfer:

- Customer mengunggah bukti transfer
- Admin atau teknisi melakukan verifikasi pembayaran

Untuk pembayaran Midtrans Sandbox:

- Customer menekan tombol bayar pada pesanan yang berstatus `waiting_payment`.
- Aplikasi meminta Snap token melalui Supabase Edge Function `midtrans-create-snap`.
- Customer diarahkan ke halaman Snap Midtrans Sandbox.
- Midtrans mengirim notifikasi pembayaran ke Supabase Edge Function `midtrans-webhook`.
- Webhook memvalidasi signature Midtrans sebelum mengubah status pembayaran.

Status pembayaran:

```text
unpaid
waiting_verification
paid
rejected
```

### 7.15 Komisi Aplikasi

Aplikasi mengambil komisi sebesar 10% dari total transaksi.

Perhitungan:

```text
Komisi aplikasi = Total pembayaran x 10%
Pendapatan teknisi = Total pembayaran - Komisi aplikasi
```

Contoh:

```text
Total pembayaran: Rp500.000
Komisi aplikasi: Rp50.000
Pendapatan teknisi: Rp450.000
```

Persentase komisi disimpan dalam pengaturan aplikasi agar dapat diubah oleh admin.

### 7.16 Invoice

Setelah pembayaran berhasil, sistem membuat invoice.

Invoice memuat:

- Nomor invoice
- Nomor pesanan
- Nama customer
- Nama teknisi
- Daftar layanan
- Daftar sparepart
- Biaya jasa
- Total pembayaran
- Metode pembayaran
- Tanggal pembayaran
- Masa garansi

Untuk MVP, invoice dapat ditampilkan sebagai halaman digital tanpa ekspor PDF.

### 7.17 Garansi

Setiap pesanan yang selesai mendapatkan garansi selama tujuh hari.

Masa garansi dihitung sejak status pesanan berubah menjadi completed.

Data garansi:

- Nomor garansi
- Pesanan
- Customer
- Teknisi
- Tanggal mulai
- Tanggal berakhir
- Status garansi

### 7.18 Rating dan Ulasan

Customer hanya dapat memberikan rating setelah pesanan berstatus completed.

Data ulasan:

- Pesanan
- Customer
- Teknisi
- Rating 1-5
- Komentar
- Foto opsional
- Tanggal ulasan

Setiap pesanan hanya dapat memiliki satu ulasan.

Nilai rating teknisi dihitung dari rata-rata seluruh ulasan.

### 7.19 Notifikasi

Notifikasi pada versi awal ditampilkan di dalam aplikasi.

Jenis notifikasi:

- Registrasi teknisi berhasil
- Teknisi berhasil diverifikasi
- Layanan disetujui
- Pesanan baru
- Pesanan diterima
- Pesanan ditolak
- Menunggu persetujuan biaya
- Biaya disetujui
- Pekerjaan selesai
- Pembayaran berhasil

Push notification dapat dikembangkan pada versi berikutnya.

### 7.20 Admin Flutter Web

Menu admin:

- Dashboard
- Customer
- Teknisi
- Verifikasi teknisi
- Kategori
- Persetujuan layanan
- Pesanan
- Pembayaran
- Ulasan
- Komisi
- Laporan
- Pengaturan

Dashboard versi MVP hanya menampilkan ringkasan angka:

- Jumlah customer
- Jumlah teknisi
- Teknisi menunggu verifikasi
- Layanan menunggu persetujuan
- Jumlah pesanan
- Total transaksi

Grafik tidak wajib pada versi MVP.

---

## 8. Alur Utama Aplikasi

### 8.1 Alur Registrasi Teknisi

```text
Teknisi membuka aplikasi
-> Memilih daftar sebagai teknisi
-> Mengisi data akun
-> Melengkapi profil dan dokumen
-> Status verifikasi pending
-> Admin memeriksa data
-> Admin menyetujui teknisi
-> Status berubah menjadi verified
```

### 8.2 Alur Pembuatan Layanan

```text
Teknisi login
-> Teknisi memilih Tambah Layanan
-> Mengisi data layanan
-> Status layanan pending
-> Admin memeriksa layanan
-> Admin menyetujui layanan
-> Layanan tampil kepada customer
```

### 8.3 Alur Pemesanan

```text
Customer login
-> Memilih kategori
-> Memilih teknisi
-> Memilih layanan
-> Mengisi detail kerusakan
-> Memilih alamat dan jadwal
-> Mengirim pesanan
-> Pesanan masuk ke teknisi
```

### 8.4 Alur Pengerjaan

```text
Teknisi menerima pesanan
-> Teknisi menuju lokasi
-> Teknisi melakukan pemeriksaan
-> Teknisi memasukkan diagnosis dan biaya
-> Customer menyetujui biaya
-> Teknisi mulai mengerjakan
-> Teknisi mengunggah foto hasil
-> Pesanan menunggu pembayaran
-> Pembayaran berhasil
-> Pesanan selesai
```

---

## 9. Halaman Aplikasi

### 9.1 Halaman Guest

- Splash screen
- Onboarding
- Home
- Daftar kategori
- Daftar teknisi
- Detail teknisi
- Detail layanan
- Login
- Register

### 9.2 Halaman Customer

- Home customer
- Kategori
- Pencarian teknisi
- Detail teknisi
- Detail layanan
- Form pemesanan lengkap
- Pilih alamat
- Gunakan lokasi saat ini
- Pilih jadwal
- Pesanan saya
- Detail pesanan
- Persetujuan biaya
- Pembayaran
- Invoice
- Garansi
- Rating dan ulasan
- Profil
- Kelola alamat

### 9.3 Halaman Teknisi

- Dashboard teknisi
- Status verifikasi
- Profil teknisi
- Dokumen teknisi
- Upload foto wajah/selfie
- Upload foto KTP
- Daftar layanan
- Tambah layanan
- Edit layanan
- Order Saya
- Pesanan masuk
- Detail pesanan
- Form diagnosis
- Form harga
- Upload dokumentasi
- Pendapatan
- Riwayat pekerjaan

### 9.4 Halaman Admin

- Login admin
- Dashboard
- Daftar customer
- Detail customer
- CRUD customer
- Daftar teknisi
- Detail teknisi
- Verifikasi teknisi
- Preview foto wajah/selfie teknisi
- Preview foto KTP teknisi
- CRUD teknisi
- Daftar kategori
- Tambah kategori
- Edit kategori
- Hapus kategori
- Upload icon kategori
- Daftar layanan
- Detail layanan
- CRUD layanan
- Persetujuan layanan
- Daftar pesanan
- Detail pesanan
- Edit status pesanan
- Hapus pesanan
- Daftar pembayaran
- Detail pembayaran
- CRUD pembayaran
- Daftar ulasan
- Detail ulasan
- CRUD ulasan
- Pengaturan komisi
- Laporan
- Pengaturan aplikasi

---

## 10. Desain Antarmuka

### 10.1 Konsep Desain

Desain aplikasi menggunakan gaya:

- Modern
- Elegan
- Profesional
- Bersih
- Mudah digunakan

### 10.2 Warna

| Kegunaan | Warna | Kode |
| --- | --- | --- |
| Primary | Navy Blue | `#16324F` |
| Secondary | Teal | `#00A6A6` |
| Accent | Amber | `#F4A261` |
| Background | Soft Gray | `#F6F8FA` |
| Card | White | `#FFFFFF` |
| Teks utama | Dark Charcoal | `#1F2937` |
| Teks sekunder | Gray | `#6B7280` |
| Sukses | Green | `#22C55E` |
| Peringatan | Orange | `#F59E0B` |
| Gagal | Red | `#EF4444` |

### 10.3 Font

Font yang disarankan:

- Poppins
- Inter

### 10.4 Komponen UI

Komponen utama:

- AppBar
- Bottom navigation
- Service card
- Technician card
- Status badge
- Order timeline
- Form input
- Primary button
- Secondary button
- Dialog konfirmasi
- Loading indicator
- Empty state
- Error state

---

## 11. Arsitektur Teknologi

### 11.1 Mobile dan Web

- Flutter
- Dart
- Material Design 3

Dependency Flutter utama:

- `supabase_flutter` untuk autentikasi, database, dan storage Supabase
- `flutter_dotenv` untuk konfigurasi environment
- `image_picker` untuk upload gambar/dokumen
- `geolocator` untuk mengambil lokasi aktif perangkat
- `geocoding` untuk membaca alamat dari koordinat

### 11.2 Backend

- Supabase Auth
- Supabase PostgreSQL
- Supabase Storage
- Supabase Realtime
- Supabase Edge Functions untuk integrasi Midtrans
- Midtrans Snap Sandbox untuk checkout pembayaran

### 11.3 Maps

- Geolocator
- Geocoding
- Google Maps Flutter opsional apabila API key tersedia

Pada MVP, fitur lokasi aktif menggunakan Geolocator untuk mengambil koordinat perangkat dan Geocoding untuk membaca alamat dari koordinat.

Permission platform:

- Android: `ACCESS_COARSE_LOCATION`
- Android: `ACCESS_FINE_LOCATION`
- Android: `CAMERA`

Permission camera digunakan untuk kebutuhan upload foto/dokumen. Permission lokasi digunakan pada form pemesanan ketika customer memilih opsi gunakan lokasi saat ini.

### 11.4 Storage

Supabase Storage digunakan untuk menyimpan file upload aplikasi.

Bucket utama:

- `profile-images` untuk foto profil dan foto wajah/selfie
- `technician-documents` untuk dokumen teknisi seperti KTP dan sertifikat
- `category-images` untuk icon kategori layanan
- `service-images` untuk foto layanan
- `order-attachments` untuk lampiran/foto kerusakan dan dokumentasi pekerjaan
- `payment-proofs` untuk bukti pembayaran

### 11.5 Payment Gateway

Payment gateway yang digunakan pada fase pengembangan adalah Midtrans Sandbox.

Komponen integrasi:

- Edge Function `midtrans-create-snap` untuk membuat transaksi Snap.
- Edge Function `midtrans-webhook` untuk menerima notifikasi Midtrans.
- Secret `MIDTRANS_SERVER_KEY` disimpan di Supabase, bukan di Flutter.
- Kolom Snap dan transaction metadata disimpan pada tabel `payments`.

Flutter client hanya menerima `snap_redirect_url` dan membuka halaman pembayaran melalui browser atau external application.

### 11.6 State Management

Pilihan state management:

- Provider
- Riverpod

Untuk project ini disarankan menggunakan Riverpod atau Provider sesuai kemampuan tim.

### 11.7 Routing

- GoRouter

Route utama mengikuti role pengguna:

- Guest: home, layanan, detail teknisi, login, register
- Customer: home, layanan, detail teknisi, form pemesanan, pesanan, profil
- Teknisi: dashboard, layanan saya, order saya, pesan, akun/profil
- Admin: dashboard, customer, teknisi, kategori, layanan, pesanan, pembayaran, ulasan, komisi, laporan, pengaturan

### 11.8 Struktur Repository

```text
teknisiku/
|-- android/
|-- assets/
|-- documentation/
|   `-- PRD.md
|-- lib/
|   |-- core/
|   |-- features/
|   |   |-- admin/
|   |   |-- auth/
|   |   |-- customer/
|   |   |-- guest/
|   |   `-- technician/
|   |-- shared/
|   `-- main.dart
|-- supabase/
|   |-- migrations/
|   |-- policies/
|   `-- README.md
|-- web/
|-- windows/
|-- pubspec.yaml
`-- README.md
```

Mobile, admin web, guest, customer, dan teknisi berada dalam satu project Flutter dengan pemisahan fitur di dalam folder `lib/features`.

---

## 12. Struktur Database

Tabel utama:

```text
profiles
technician_profiles
technician_documents
categories
services
service_images
technician_schedules
customer_addresses
orders
order_items
order_attachments
diagnoses
spareparts
order_spareparts
payments
reviews
warranties
invoices
notifications
app_settings
```

### 12.1 Profiles

Kolom:

```text
id
email
full_name
phone
role
profile_image_url
is_active
created_at
updated_at
```

### 12.2 Technician Profiles

Kolom:

```text
id
user_id
address
experience
skills
service_area
latitude
longitude
description
verification_status
verified_at
created_at
updated_at
```

### 12.3 Categories

Kolom:

```text
id
name
description
icon_url
is_active
created_at
updated_at
```

Kolom `icon_url` menyimpan path atau public URL gambar icon kategori dari Supabase Storage bucket `category-images`.

### 12.4 Services

Kolom:

```text
id
technician_id
category_id
name
description
estimated_price
estimated_duration
approval_status
is_active
created_at
updated_at
```

### 12.5 Technician Documents

Kolom:

```text
id
technician_id
document_type
file_url
uploaded_at
```

Nilai `document_type` yang digunakan:

```text
selfie
ktp
certificate
experience
skill
service_area
```

File dokumen teknisi disimpan pada Supabase Storage bucket `technician-documents`.

### 12.6 Customer Addresses

Kolom:

```text
id
customer_id
label
recipient_name
phone
full_address
city
district
village
postal_code
latitude
longitude
is_primary
created_at
updated_at
```

Kolom `latitude` dan `longitude` diisi ketika customer menggunakan lokasi aktif saat ini atau memilih titik alamat.

Alamat yang dibuat dari form pemesanan disimpan dengan `is_primary = false` secara default agar tidak otomatis mengganti alamat utama customer.

### 12.7 Orders

Kolom:

```text
id
order_number
customer_id
technician_id
address_id
schedule_date
schedule_time
problem_description
status
estimated_total
final_total
commission_percentage
commission_amount
technician_income
created_at
updated_at
```

Kolom `address_id` mengarah ke tabel `customer_addresses`. Jika customer memakai lokasi aktif saat ini dan membuat alamat baru saat checkout, maka `address_id` menggunakan ID alamat baru yang dibuat sebelum order disimpan.

### 12.8 Order Items

Kolom:

```text
id
order_id
service_id
service_name
estimated_price
final_price
created_at
```

### 12.9 Diagnoses

Kolom:

```text
id
order_id
technician_id
diagnosis_result
work_estimation
service_cost
sparepart_cost
total_cost
created_at
updated_at
```

### 12.10 Payments

Kolom:

```text
id
order_id
payment_method
amount
proof_url
payment_status
paid_at
midtrans_order_id
snap_token
snap_redirect_url
transaction_id
fraud_status
raw_response
created_at
updated_at
```

### 12.11 Reviews

Kolom:

```text
id
order_id
customer_id
technician_id
rating
comment
image_url
created_at
```

### 12.12 Warranties

Kolom:

```text
id
order_id
warranty_number
start_date
end_date
status
created_at
```

---

## 13. Aturan Bisnis

1. Customer dan teknisi harus login menggunakan email dan password.
2. Satu akun hanya memiliki satu role.
3. Teknisi harus diverifikasi admin sebelum menyediakan layanan.
4. Layanan teknisi harus disetujui admin sebelum tampil.
5. Customer memilih teknisi sendiri.
6. Pesanan langsung masuk kepada teknisi.
7. Teknisi dapat menerima atau menolak pesanan.
8. Customer tidak dapat membatalkan pesanan.
9. Teknisi harus memasukkan diagnosis dan total biaya.
10. Customer harus menyetujui biaya sebelum pekerjaan dimulai.
11. Teknisi wajib mengunggah foto sebelum dan sesudah pengerjaan.
12. Pembayaran menggunakan tunai atau transfer.
13. Komisi aplikasi adalah 10%.
14. Rating hanya dapat diberikan setelah pesanan selesai.
15. Satu pesanan hanya dapat diberikan satu ulasan.
16. Garansi berlaku selama tujuh hari.
17. Customer tidak dapat melihat lokasi teknisi secara langsung.
18. Aplikasi tidak menyediakan fitur chat.
19. Aplikasi tidak menyediakan live tracking.
20. Admin tidak dapat memilihkan teknisi untuk customer.
21. Admin dapat membuat, melihat, memperbarui, dan menghapus data master seperti kategori, layanan, customer, teknisi, pesanan, pembayaran, dan ulasan sesuai kebutuhan operasional.
22. Icon kategori harus berasal dari data kategori di database agar tampilan home customer dan guest mengikuti perubahan dashboard admin.
23. Teknisi wajib menyediakan foto wajah/selfie dan foto KTP untuk proses verifikasi.
24. Dokumen verifikasi teknisi hanya dapat dilihat oleh teknisi pemilik akun dan admin.
25. Customer dapat menggunakan lokasi aktif saat ini untuk mengisi alamat layanan, tetapi tidak dapat melihat lokasi teknisi secara real-time.

---

## 14. MVP Satu Hari

Karena aplikasi ditargetkan memiliki versi demo dalam satu hari, fitur MVP diprioritaskan sebagai berikut:

### Fitur Wajib

- Login dan register
- Role customer, teknisi, dan admin
- Home guest
- Daftar kategori
- Daftar teknisi
- Profil teknisi
- Registrasi teknisi
- Verifikasi teknisi
- Penambahan layanan
- Persetujuan layanan
- Pembuatan pesanan
- Form pemesanan lengkap dengan alamat dan jadwal
- Penggunaan lokasi aktif saat ini pada form pemesanan
- Daftar pesanan customer
- Daftar pesanan teknisi
- Halaman Order Saya teknisi
- Terima atau tolak pesanan
- Perubahan status pesanan
- CRUD dashboard admin untuk data utama
- Upload icon kategori dari dashboard admin
- Preview dokumen teknisi pada dashboard admin

### Penyederhanaan MVP

Untuk versi demo:

- Alamat dapat menggunakan input teks dan lokasi aktif perangkat
- Google Maps visual dapat ditambahkan setelah alur utama berjalan
- Pembayaran dapat menggunakan status manual
- Invoice cukup berupa halaman digital
- Upload video tidak wajib
- Notifikasi cukup di dalam aplikasi
- Perhitungan komisi dapat dilakukan otomatis tanpa pencairan dana
- Garansi cukup berupa tanggal mulai dan berakhir
- Rating dapat ditambahkan setelah alur pesanan selesai

---

## 15. Pembagian Tugas Tim

### Anggota 1: Supabase dan Autentikasi

Tanggung jawab:

- Membuat project Supabase
- Membuat database
- Membuat tabel
- Membuat relasi
- Membuat autentikasi
- Membuat role
- Membuat Supabase Storage
- Membuat Row Level Security
- Menyiapkan data dummy
- Membantu integrasi database

Branch:

```text
backend-supabase
```

### Anggota 2: Guest dan Customer Mobile

Tanggung jawab:

- Splash screen
- Login dan register
- Home guest
- Home customer
- Daftar kategori
- Daftar teknisi
- Detail teknisi
- Form pemesanan
- Pesanan customer
- Detail pesanan
- Profil customer

Branch:

```text
customer-mobile
```

### Anggota 3: Teknisi dan Admin

Tanggung jawab teknisi:

- Dashboard teknisi
- Profil teknisi
- Upload dokumen
- Daftar layanan
- Tambah layanan
- Pesanan teknisi
- Terima atau tolak pesanan
- Update status pesanan

Tanggung jawab admin:

- Login admin
- Verifikasi teknisi
- Persetujuan layanan
- Daftar customer
- Daftar pesanan

Branch:

```text
technician-admin
```

---

## 16. Acceptance Criteria

### Autentikasi

- Pengguna dapat register menggunakan email dan password.
- Pengguna dapat login.
- Sistem mengarahkan pengguna berdasarkan role.
- Pengguna dapat logout.

### Teknisi

- Teknisi dapat melengkapi profil.
- Teknisi dapat mengunggah dokumen.
- Teknisi dapat mengunggah foto wajah/selfie.
- Teknisi dapat mengunggah foto KTP.
- Admin dapat memverifikasi teknisi.
- Teknisi terverifikasi dapat membuat layanan.
- Teknisi dapat menerima atau menolak pesanan.
- Teknisi dapat melihat daftar Order Saya.

### Customer

- Customer dapat melihat kategori.
- Customer dapat melihat icon kategori yang dibuat admin.
- Customer dapat melihat teknisi.
- Customer dapat memilih layanan.
- Customer dapat membuat pesanan.
- Customer dapat membuat pesanan dengan alamat tersimpan.
- Customer dapat membuat pesanan dengan alamat baru.
- Customer dapat menggunakan lokasi aktif saat ini pada form pemesanan.
- Customer dapat melihat status pesanan.

### Admin

- Admin dapat login melalui Flutter Web.
- Admin dapat melihat teknisi pending.
- Admin dapat menyetujui atau menolak teknisi.
- Admin dapat melihat foto wajah/selfie dan foto KTP teknisi.
- Admin dapat menyetujui atau menolak layanan.
- Admin dapat melihat seluruh pesanan.
- Admin dapat melakukan CRUD kategori.
- Admin dapat mengunggah icon kategori.
- Admin dapat melakukan CRUD customer, teknisi, layanan, pesanan, pembayaran, dan ulasan.
- Admin dapat melihat laporan dan ringkasan data dashboard.

### Order

- Pesanan tersimpan di Supabase.
- Pesanan masuk kepada teknisi yang dipilih.
- Teknisi dapat mengubah status.
- Perubahan status dapat dilihat customer.
- Pesanan selesai dapat diberikan ulasan.

---

## 17. Skenario Pengujian Utama

### Skenario 1: Registrasi Teknisi

1. Teknisi melakukan registrasi.
2. Teknisi melengkapi profil.
3. Teknisi mengunggah dokumen.
4. Status teknisi pending.
5. Admin membuka data teknisi.
6. Admin menyetujui teknisi.
7. Status teknisi menjadi verified.

### Skenario 2: Penambahan Layanan

1. Teknisi login.
2. Teknisi menambahkan layanan.
3. Status layanan pending.
4. Admin menyetujui layanan.
5. Layanan tampil pada aplikasi customer.

### Skenario 3: Pemesanan Customer

1. Customer login.
2. Customer memilih kategori.
3. Customer memilih teknisi.
4. Customer memilih layanan.
5. Customer memilih alamat tersimpan atau membuat alamat baru.
6. Customer dapat menekan gunakan lokasi saat ini untuk mengisi koordinat.
7. Customer mengisi jadwal dan data kerusakan.
8. Customer mengirim pesanan.
9. Pesanan tersimpan di Supabase.
10. Teknisi menerima pesanan.
11. Customer melihat perubahan status.

### Skenario 3A: Pengelolaan Kategori Admin

1. Admin login ke dashboard web.
2. Admin membuka halaman kategori.
3. Admin menambahkan kategori baru.
4. Admin mengunggah icon kategori.
5. Data kategori tersimpan di Supabase.
6. Icon kategori tampil pada dashboard admin.
7. Icon kategori tampil pada home guest dan customer.

### Skenario 3B: Verifikasi Dokumen Teknisi

1. Teknisi login.
2. Teknisi membuka halaman profil/verifikasi.
3. Teknisi mengunggah foto wajah/selfie.
4. Teknisi mengunggah foto KTP.
5. Admin membuka detail teknisi.
6. Admin melihat dokumen yang diunggah.
7. Admin menyetujui atau menolak verifikasi teknisi.

### Skenario 4: Penyelesaian Pekerjaan

1. Teknisi mengubah status menjadi inspection.
2. Teknisi mengisi diagnosis dan biaya.
3. Customer menyetujui biaya.
4. Teknisi mengubah status menjadi in_progress.
5. Teknisi menyelesaikan pekerjaan.
6. Customer melakukan pembayaran.
7. Status berubah menjadi completed.
8. Customer memberikan rating.

---

## 18. Fitur di Luar Ruang Lingkup MVP

Fitur berikut tidak menjadi prioritas versi satu hari:

- Live tracking
- Chat customer dan teknisi
- Pembayaran payment gateway
- QRIS otomatis
- Push notification Firebase
- Video call
- Sistem voucher
- Promo dan diskon
- Sistem saldo teknisi
- Penarikan saldo
- Analisis berbasis AI
- Diagnosa otomatis
- Grafik laporan kompleks
- Multiwilayah
- Aplikasi iOS

---

## 19. Risiko Proyek

| Risiko | Dampak | Penanganan |
| --- | --- | --- |
| Integrasi antaranggota berbeda | Fitur gagal digabungkan | Gunakan model dan nama tabel yang sama |
| Database berubah saat pengerjaan | Error query | Struktur database harus disepakati di awal |
| Konflik Git | Kode tertimpa | Gunakan branch masing-masing |
| Upload file bermasalah | Verifikasi teknisi gagal | Gunakan file gambar kecil untuk demo |
| Google Maps membutuhkan konfigurasi | Build tertunda | Gunakan input alamat pada MVP |
| Role tidak terbaca | Salah halaman | Simpan role pada tabel profiles |
| RLS memblokir data | Data tidak muncul | Uji policy setiap tabel |
| Fitur terlalu banyak | MVP tidak selesai | Fokus pada alur utama |

---

## 20. Definition of Done

Project dinyatakan selesai untuk versi MVP apabila:

1. Aplikasi Flutter dapat dijalankan.
2. Flutter terhubung ke Supabase.
3. Registrasi dan login berjalan.
4. Role customer, teknisi, dan admin berjalan.
5. Teknisi dapat mendaftar dan diverifikasi.
6. Teknisi dapat membuat layanan.
7. Admin dapat menyetujui layanan.
8. Customer dapat melihat layanan.
9. Customer dapat membuat pesanan.
10. Teknisi dapat menerima atau menolak pesanan.
11. Status pesanan dapat dilihat customer.
12. Tidak terdapat error utama pada alur demo.
13. Source code sudah digabungkan ke branch utama.
14. README berisi cara menjalankan aplikasi.
15. Data dummy tersedia untuk presentasi.

---

## 21. Skenario Demo Presentasi

Urutan demo:

1. Buka aplikasi sebagai guest.
2. Tampilkan home dan kategori.
3. Tampilkan daftar teknisi.
4. Login sebagai teknisi.
5. Tampilkan status verifikasi teknisi.
6. Login admin melalui Flutter Web.
7. Verifikasi teknisi.
8. Teknisi menambahkan layanan.
9. Admin menyetujui layanan.
10. Login sebagai customer.
11. Customer memilih teknisi dan layanan.
12. Customer membuat pesanan.
13. Teknisi membuka pesanan masuk.
14. Teknisi menerima pesanan.
15. Customer melihat status pesanan berubah.

---

## 22. Kesimpulan

Si Teknisi merupakan aplikasi marketplace jasa teknisi berbasis Flutter dan Supabase yang menyediakan layanan servis komputer, laptop, handphone, printer, CCTV, dan jaringan.

Aplikasi memiliki tiga role utama, yaitu customer, teknisi, dan admin, serta akses guest untuk pengguna yang belum login.

Versi MVP difokuskan pada autentikasi, verifikasi teknisi, pengelolaan layanan, pemesanan, lokasi aktif customer, dashboard admin CRUD, dan perubahan status pesanan. Fitur tambahan seperti payment gateway, live tracking, chat, dan laporan analitik kompleks dapat dikembangkan setelah alur utama berjalan dengan baik.
