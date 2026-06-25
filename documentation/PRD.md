# Product Requirements Document

## Aplikasi Si Teknisi

**Versi:** 1.0  
**Jenis proyek:** Project kuliah  
**Platform:** Flutter Android dan Flutter Web  
**Backend:** Supabase  
**Wilayah layanan awal:** Solo  
**Jumlah anggota tim:** 3 orang

---

## 1. Ringkasan Produk

Si Teknisi adalah aplikasi marketplace jasa teknisi yang menghubungkan customer dengan penyedia jasa teknisi di wilayah Solo.

Customer dapat mencari teknisi, melihat layanan, memilih teknisi, membuat pesanan, menentukan alamat dan jadwal servis, menyetujui hasil diagnosis, serta memberikan ulasan setelah pekerjaan selesai.

Teknisi dapat mendaftar, melengkapi data diri, mengajukan verifikasi, menyediakan layanan, menerima atau menolak pesanan, melakukan pemeriksaan, menentukan biaya, dan memperbarui status pekerjaan.

Admin mengakses sistem melalui Flutter Web untuk memverifikasi teknisi, menyetujui layanan, mengelola customer, teknisi, pesanan, pembayaran, ulasan, komisi, dan laporan.

Seluruh aplikasi dikembangkan menggunakan Flutter. Supabase digunakan untuk autentikasi, database, penyimpanan file, dan pengelolaan data backend.

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

Setelah disetujui, status teknisi berubah menjadi:

```text
verified
```

Teknisi yang sudah diverifikasi dapat membuat dan menampilkan layanan setelah layanan tersebut disetujui admin.

### 7.5 Pengelolaan Kategori

Kategori dibuat dan dikelola oleh admin.

Data kategori:

- Nama kategori
- Ikon
- Deskripsi
- Status aktif
- Tanggal dibuat

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
- Melihat teknisi yang berada di sekitar wilayah customer
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

Google Maps digunakan untuk memilih titik alamat customer.

Customer tidak dapat melihat lokasi teknisi secara langsung. Aplikasi tidak menggunakan live tracking.

### 7.10 Pemesanan Layanan

Customer dapat memesan satu atau beberapa layanan dalam satu pesanan.

Data pemesanan:

- Customer
- Teknisi
- Daftar layanan
- Deskripsi kerusakan
- Foto kerusakan
- Alamat
- Titik lokasi
- Tanggal kunjungan
- Jam kunjungan
- Catatan tambahan

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

Untuk pembayaran tunai:

- Teknisi menandai bahwa pembayaran sudah diterima
- Admin dapat melihat status pembayaran

Untuk pembayaran transfer:

- Customer mengunggah bukti transfer
- Admin atau teknisi melakukan verifikasi pembayaran

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
- Form pemesanan
- Pilih alamat
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
- Daftar layanan
- Tambah layanan
- Edit layanan
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
- Daftar teknisi
- Detail teknisi
- Verifikasi teknisi
- Daftar kategori
- Daftar layanan
- Persetujuan layanan
- Daftar pesanan
- Detail pesanan
- Daftar pembayaran
- Daftar ulasan
- Pengaturan komisi
- Laporan

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

### 11.2 Backend

- Supabase Auth
- Supabase PostgreSQL
- Supabase Storage
- Supabase Realtime

### 11.3 Maps

- Google Maps Flutter
- Geolocator
- Geocoding

### 11.4 State Management

Pilihan state management:

- Provider
- Riverpod

Untuk project ini disarankan menggunakan Riverpod atau Provider sesuai kemampuan tim.

### 11.5 Routing

- GoRouter

### 11.6 Struktur Repository

```text
si-teknisi/
|-- mobile_app/
|-- admin_web/
|-- supabase/
|   |-- migrations/
|   |-- policies/
|   `-- seed.sql
|-- documentation/
`-- README.md
```

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

### 12.5 Orders

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

### 12.6 Order Items

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

### 12.7 Diagnoses

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

### 12.8 Payments

Kolom:

```text
id
order_id
payment_method
amount
proof_url
payment_status
paid_at
created_at
updated_at
```

### 12.9 Reviews

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

### 12.10 Warranties

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
- Daftar pesanan customer
- Daftar pesanan teknisi
- Terima atau tolak pesanan
- Perubahan status pesanan

### Penyederhanaan MVP

Untuk versi demo:

- Alamat dapat menggunakan input teks
- Google Maps dapat ditambahkan setelah alur utama berjalan
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
- Admin dapat memverifikasi teknisi.
- Teknisi terverifikasi dapat membuat layanan.
- Teknisi dapat menerima atau menolak pesanan.

### Customer

- Customer dapat melihat kategori.
- Customer dapat melihat teknisi.
- Customer dapat memilih layanan.
- Customer dapat membuat pesanan.
- Customer dapat melihat status pesanan.

### Admin

- Admin dapat login melalui Flutter Web.
- Admin dapat melihat teknisi pending.
- Admin dapat menyetujui atau menolak teknisi.
- Admin dapat menyetujui atau menolak layanan.
- Admin dapat melihat seluruh pesanan.

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
5. Customer mengisi data kerusakan.
6. Customer mengirim pesanan.
7. Teknisi menerima pesanan.
8. Customer melihat perubahan status.

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

Versi MVP difokuskan pada autentikasi, verifikasi teknisi, pengelolaan layanan, pemesanan, dan perubahan status pesanan. Fitur tambahan seperti pembayaran lengkap, garansi, rating, Google Maps, invoice, dan laporan dapat dikembangkan setelah alur utama berjalan dengan baik.
