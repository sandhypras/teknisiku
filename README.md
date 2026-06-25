# Si Teknisi

Si Teknisi adalah aplikasi marketplace jasa teknisi untuk wilayah Solo. Aplikasi ini menghubungkan customer dengan teknisi untuk layanan komputer, laptop, handphone, printer, CCTV, dan jaringan.

Project ini dibuat sebagai project kuliah menggunakan Flutter Android, Flutter Web, dan Supabase.

## Platform

- Flutter Android untuk guest, customer, dan teknisi
- Flutter Web untuk admin
- Supabase untuk auth, database, storage, dan realtime

## Struktur Repository

```text
si-teknisi/
├── mobile_app/
├── admin_web/
├── supabase/
│   ├── migrations/
│   ├── policies/
│   └── seed.sql
├── documentation/
│   └── PRD.md
└── README.md
```

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

Instruksi teknis akan dilengkapi setelah project Flutter dan Supabase mulai dibuat.

Rencana awal:

1. Buat project Flutter di `mobile_app/`.
2. Buat project Flutter Web admin di `admin_web/`.
3. Buat schema Supabase di `supabase/migrations/`.
4. Tambahkan seed data demo di `supabase/seed.sql`.
5. Isi konfigurasi environment berdasarkan `.env.example`.
