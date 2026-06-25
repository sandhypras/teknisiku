# Supabase Backend

Backend Si Teknisi disiapkan melalui SQL migration di folder `migrations/`.

## Cara Menjalankan

Dengan Supabase CLI:

```bash
supabase db reset
```

Atau jalankan file berikut secara berurutan lewat Supabase SQL editor:

1. `supabase/migrations/20260625163000_initial_backend.sql`
2. `supabase/seed.sql`

## Isi Backend

- Enum role dan status sesuai PRD
- Tabel utama marketplace teknisi
- Relasi customer, teknisi, layanan, order, pembayaran, ulasan, invoice, dan garansi
- Trigger `updated_at`
- Auto profile dari Supabase Auth
- Perhitungan komisi otomatis pada order
- Row Level Security untuk customer, technician, admin, dan guest
- Storage bucket untuk profil, dokumen teknisi, gambar layanan, lampiran order, dan bukti pembayaran

## Catatan Admin

Admin tidak bisa dibuat lewat registrasi umum. Setelah akun dibuat di Supabase Auth, ubah role lewat SQL:

```sql
update public.profiles
set role = 'admin'
where email = 'admin@example.com';
```
