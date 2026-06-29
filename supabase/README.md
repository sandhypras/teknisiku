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

## Midtrans Sandbox

Pembayaran Midtrans dibuat melalui Supabase Edge Function agar `MIDTRANS_SERVER_KEY` tidak pernah disimpan di Flutter client.

Secrets yang perlu diset pada project Supabase:

```bash
supabase secrets set MIDTRANS_SERVER_KEY="SB-Mid-server-xxxxx"
supabase secrets set APP_PUBLIC_URL="https://domain-aplikasi-anda.com"
```

Deploy function:

```bash
supabase functions deploy midtrans-create-snap
supabase functions deploy midtrans-webhook --no-verify-jwt
```

Webhook URL:

```text
https://<project-ref>.supabase.co/functions/v1/midtrans-webhook
```

Function `midtrans-create-snap` otomatis mengirim webhook URL melalui header `X-Override-Notification`. Jika menu Payment Notification URL tidak muncul di dashboard Midtrans Sandbox, alur pembayaran tetap bisa berjalan tanpa pengaturan manual di dashboard.

Opsional, set secret berikut apabila ingin menentukan URL webhook secara eksplisit:

```bash
supabase secrets set MIDTRANS_NOTIFICATION_URL="https://<project-ref>.supabase.co/functions/v1/midtrans-webhook"
```

Alur pembayaran:

1. Customer membuka pesanan dengan status `waiting_payment`.
2. Aplikasi memanggil `midtrans-create-snap`.
3. Function membuat/menggunakan data `payments` dan meminta Snap token ke Midtrans Sandbox.
4. Flutter membuka `snap_redirect_url` dengan browser.
5. Midtrans mengirim notifikasi ke `midtrans-webhook`.
6. Webhook memvalidasi `signature_key`, lalu memperbarui status pembayaran di Supabase.
