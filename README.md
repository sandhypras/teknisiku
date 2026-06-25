# Si Teknisi

Si Teknisi adalah aplikasi marketplace jasa teknisi untuk wilayah Solo. Aplikasi ini menghubungkan customer dengan teknisi untuk layanan komputer, laptop, handphone, printer, CCTV, dan jaringan.

Project ini dibuat sebagai project kuliah menggunakan Flutter Android, Flutter Web, dan Supabase.

## Platform

- Flutter Android untuk guest, customer, dan teknisi
- Flutter Web untuk admin
- Supabase untuk auth, database, storage, dan realtime

## Struktur Repository

Project Flutter saat ini berada di root repository.

```text
teknisiku/
|-- android/
|-- lib/
|-- web/
|-- windows/
|-- supabase/
|   |-- migrations/
|   |-- policies/
|   `-- seed.sql
|-- documentation/
|   `-- PRD.md
|-- pubspec.yaml
`-- README.md
```

Folder `mobile_app/` dan `admin_web/` disiapkan sebagai placeholder apabila project mobile dan admin web ingin dipisah sesuai rencana PRD.

## Role

- Guest: melihat home, kategori, layanan, teknisi, dan estimasi harga
- Customer: membuat pesanan, menyetujui biaya, membayar, melihat invoice, dan memberi ulasan
- Teknisi: mengelola profil, layanan, pesanan, diagnosis, dokumentasi pekerjaan, dan pendapatan
- Admin: mengelola verifikasi teknisi, layanan, pesanan, pembayaran, ulasan, komisi, dan laporan

## MVP

Prioritas demo satu hari:

- Login dan register
- Role customer, teknisi, dan admin
- Home guest
- Daftar kategori dan teknisi
- Profil teknisi
- Registrasi dan verifikasi teknisi
- Penambahan dan persetujuan layanan
- Pembuatan pesanan
- Daftar pesanan customer dan teknisi
- Terima atau tolak pesanan
- Perubahan status pesanan

Detail lengkap kebutuhan produk tersedia di [documentation/PRD.md](documentation/PRD.md).

## Setup Pengembangan

Pastikan Flutter SDK sudah terpasang, lalu jalankan:

```bash
flutter pub get
flutter run
```

Untuk menjalankan target web:

```bash
flutter run -d chrome
```

Konfigurasi environment dapat mengikuti `.env.example`.

## Repository

```text
https://github.com/sandhypras/teknisiku.git
```
