# Checklist E2E Android - Pembayaran Sampai Invoice dan Garansi

Checklist ini dipakai untuk mengetes flow utama di device Android fisik sebelum demo atau rilis.

## Persiapan

- [ ] Jalankan aplikasi di Android via USB.
- [ ] Pastikan aplikasi memakai Supabase remote yang benar.
- [ ] Pastikan migration terbaru sudah dipush ke Supabase remote.
- [ ] Pastikan Edge Function Midtrans sudah dideploy.
- [ ] Pastikan webhook Midtrans Sandbox mengarah ke function `midtrans-webhook`.
- [ ] Pastikan akun customer dan teknisi sudah dibuat dari aplikasi.
- [ ] Pastikan teknisi sudah diverifikasi admin.
- [ ] Pastikan teknisi punya layanan aktif dengan harga dan foto layanan.
- [ ] Pastikan customer punya foto profil.
- [ ] Pastikan permission lokasi dan notifikasi di Android diizinkan.

## Data Uji

- [ ] Customer test:
  - Email:
  - Password:
  - Nomor telepon:
- [ ] Teknisi test:
  - Email:
  - Password:
  - Nomor telepon:
- [ ] Layanan test:
  - Kategori:
  - Nama layanan:
  - Harga awal:
- [ ] Metode pembayaran sandbox:
  - QRIS

## Flow Customer Membuat Pesanan

- [ ] Login sebagai customer.
- [ ] Home menampilkan kategori dari database.
- [ ] Home menampilkan teknisi terdekat.
- [ ] Klik kategori.
- [ ] Aplikasi menampilkan teknisi sesuai kategori dan lokasi.
- [ ] Buka detail teknisi.
- [ ] Foto profil teknisi tampil.
- [ ] Layanan teknisi tampil dengan foto layanan.
- [ ] Klik `Pesan Teknisi`.
- [ ] Isi deskripsi kerusakan.
- [ ] Gunakan lokasi saat ini.
- [ ] Kota, kecamatan, kelurahan, kode pos, alamat, latitude, dan longitude terisi sesuai lokasi.
- [ ] Lengkapi jadwal kunjungan.
- [ ] Buat pesanan.
- [ ] Pesanan muncul di tab `Order Saya`.
- [ ] Status awal pesanan sesuai database, misalnya `Menunggu Konfirmasi`.

## Flow Teknisi Menerima dan Mengerjakan

- [ ] Login sebagai teknisi.
- [ ] Teknisi menerima notifikasi order baru.
- [ ] Order baru tampil di halaman teknisi.
- [ ] Detail order menampilkan:
  - Nomor order
  - Nama customer
  - Nomor telepon customer dan bisa dicopy
  - Alamat customer lengkap
  - Deskripsi masalah
  - Jadwal
  - Estimasi awal
- [ ] Klik `Terima`.
- [ ] Customer menerima notifikasi order diterima.
- [ ] Status customer berubah menjadi diterima.
- [ ] Teknisi mulai pengerjaan.
- [ ] Customer menerima notifikasi sedang dikerjakan.
- [ ] Teknisi mengisi diagnosis kerusakan.
- [ ] Teknisi menambahkan sparepart jika ada:
  - Nama sparepart
  - Qty
  - Harga satuan
- [ ] Teknisi upload foto sebelum pengerjaan.
- [ ] Teknisi upload foto sesudah pengerjaan.
- [ ] Teknisi mengirim estimasi biaya final.

## Flow Customer Menyetujui Biaya

- [ ] Customer membuka detail pesanan.
- [ ] Detail menampilkan diagnosis dari teknisi.
- [ ] Detail menampilkan sparepart dan subtotal.
- [ ] Detail menampilkan foto sebelum dan sesudah.
- [ ] Detail menampilkan biaya layanan Rp6.000.
- [ ] Detail menampilkan total final.
- [ ] Customer klik setujui biaya.
- [ ] Status berubah menjadi menunggu pembayaran.
- [ ] Teknisi melihat status menunggu pembayaran.
- [ ] Jika customer menolak biaya, status dan feedback tampil jelas.

## Flow Pembayaran Midtrans Sandbox QRIS

- [ ] Customer klik bayar.
- [ ] Aplikasi membuat transaksi Midtrans.
- [ ] Halaman pembayaran sandbox terbuka.
- [ ] Pilih QRIS.
- [ ] QRIS sandbox tampil.
- [ ] Selesaikan pembayaran sandbox.
- [ ] Kembali ke aplikasi.
- [ ] Tombol bayar tidak membuat transaksi ganda.
- [ ] Jika invoice sudah lunas, feedback menampilkan bahwa pembayaran sudah selesai.
- [ ] Status pembayaran di customer berubah menjadi paid/lunas.
- [ ] Status pesanan tidak lagi menunggu pembayaran.
- [ ] Status di teknisi ikut berubah setelah webhook masuk.
- [ ] Data pembayaran muncul di dashboard admin.

## Flow Selesai, Invoice, dan Garansi

- [ ] Teknisi menyelesaikan order setelah pembayaran lunas.
- [ ] Customer menerima notifikasi order selesai.
- [ ] Invoice otomatis dibuat.
- [ ] Garansi otomatis dibuat.
- [ ] Customer dapat membuka detail invoice.
- [ ] Invoice menampilkan:
  - Nomor invoice
  - Nomor order
  - Customer
  - Teknisi
  - Layanan
  - Sparepart
  - Biaya layanan Rp6.000
  - Total pembayaran
  - Status lunas
- [ ] Garansi menampilkan:
  - Nomor garansi
  - Order terkait
  - Teknisi
  - Masa berlaku
  - Ketentuan garansi
- [ ] Admin dapat melihat pembayaran, invoice, dan status order.

## Validasi Notifikasi

- [ ] Customer menerima notifikasi saat order diterima.
- [ ] Customer menerima notifikasi saat order mulai dikerjakan.
- [ ] Customer menerima notifikasi saat menunggu pembayaran.
- [ ] Customer menerima notifikasi saat order selesai.
- [ ] Teknisi menerima notifikasi saat ada order baru.
- [ ] Admin menerima indikator/verifikasi untuk teknisi atau layanan pending.
- [ ] Notifikasi tetap muncul saat aplikasi background.

## Validasi Error Handling

- [ ] Jika internet mati, aplikasi menampilkan feedback error custom.
- [ ] Jika pembayaran sudah lunas dan tombol bayar ditekan lagi, tampil pesan jelas tanpa transaksi baru.
- [ ] Jika webhook belum masuk, aplikasi bisa refresh status pembayaran.
- [ ] Jika upload foto gagal, teknisi mendapat feedback jelas.
- [ ] Jika teknisi belum diverifikasi dan menambah layanan, feedback menjelaskan perlu verifikasi.
- [ ] Tidak ada `SnackBar` bawaan atau dialog bawaan sederhana pada flow utama.

## Hasil Akhir

- [ ] Flow customer selesai tanpa error.
- [ ] Flow teknisi selesai tanpa error.
- [ ] Pembayaran sandbox mengubah status di customer, teknisi, dan admin.
- [ ] Invoice tampil benar.
- [ ] Garansi tampil benar.
- [ ] Tidak ada crash di Android.
- [ ] Tidak ada overflow UI di layar kecil.
- [ ] Tidak ada data ganda akibat klik berulang.
