# Checklist Rilis Play Store - Si Teknisi

Dokumen ini dipakai sebelum upload aplikasi ke Google Play Console.

## Identitas Aplikasi

- Package name Android: `com.ti24a6.siteknisi`
- Nama aplikasi Android: `Si Teknisi`
- Format upload Play Store: Android App Bundle (`.aab`)
- Output build: `build/app/outputs/bundle/release/app-release.aab`

## 1. Buat Upload Keystore

Jalankan dari root project:

```powershell
keytool -genkey -v -keystore android/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Simpan password dengan aman. File `android/upload-keystore.jks` tidak boleh masuk git.

## 2. Buat File Signing Lokal

Copy template:

```powershell
Copy-Item android/key.properties.example android/key.properties
```

Isi `android/key.properties`:

```properties
storePassword=PASSWORD_KEYSTORE_ANDA
keyPassword=PASSWORD_KEY_ANDA
keyAlias=upload
storeFile=../upload-keystore.jks
```

File `android/key.properties` tidak boleh masuk git.

## 3. Cek Konfigurasi Wajib

- [ ] `android/app/google-services.json` memakai package `com.ti24a6.siteknisi`.
- [ ] `.env` berisi Supabase URL dan anon key yang benar.
- [ ] Supabase migration remote sudah terbaru.
- [ ] Edge Function Midtrans sudah dideploy.
- [ ] Webhook Midtrans production atau sandbox sudah mengarah ke function yang benar.
- [ ] Firebase Cloud Messaging sudah aktif.
- [ ] Permission lokasi, kamera, internet, dan notifikasi memang digunakan aplikasi.
- [ ] Link reset password `siteknisi://reset-password` sudah terdaftar di Supabase Auth redirect URL.

## 4. Naikkan Versi Aplikasi

Sebelum upload ulang, ubah versi di `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Untuk rilis berikutnya, naikkan `versionCode`, misalnya:

```yaml
version: 1.0.1+2
```

## 5. Build AAB Release

Jalankan:

```powershell
flutter clean
flutter pub get
flutter analyze --no-pub
flutter test
flutter build appbundle --release
```

Jika signing belum dibuat, build release akan gagal dengan pesan untuk membuat `android/key.properties`.

## 6. Test Sebelum Upload

- [ ] Install dan test di Android fisik via USB.
- [ ] Login customer berhasil.
- [ ] Login teknisi berhasil.
- [ ] Registrasi OTP email berhasil.
- [ ] Reset password dari email berhasil membuka aplikasi.
- [ ] Lokasi saat ini mengisi alamat otomatis.
- [ ] Teknisi terdekat muncul sesuai lokasi/kategori.
- [ ] Upload foto profil, KTP, selfie, layanan, dan foto pekerjaan berhasil.
- [ ] Order selesai dari customer sampai teknisi.
- [ ] Pembayaran Midtrans berhasil.
- [ ] Invoice dan garansi muncul.
- [ ] Push notification masuk saat aplikasi background.
- [ ] Tidak ada overflow di layar kecil.

Gunakan checklist detail: `documentation/E2E_ANDROID_PAYMENT_CHECKLIST.md`.

## 7. Data Safety Play Console

Siapkan jawaban Data Safety karena aplikasi mengumpulkan:

- Data akun: nama, email, nomor telepon.
- Foto/gambar: foto profil, KTP, selfie, layanan, pekerjaan.
- Lokasi: lokasi customer dan teknisi untuk pencocokan teknisi terdekat.
- Data transaksi: order, pembayaran, invoice, garansi, penarikan teknisi.
- Device token: token notifikasi Firebase.

Pastikan privacy policy menjelaskan penggunaan data tersebut.

## 8. Upload ke Play Console

- [ ] Buat app baru di Play Console.
- [ ] Pilih package `com.ti24a6.siteknisi`.
- [ ] Upload `app-release.aab`.
- [ ] Isi App Content:
  - Privacy Policy
  - Data Safety
  - App Access
  - Ads declaration
  - Content rating
  - Target audience
- [ ] Tambahkan screenshot HP.
- [ ] Tambahkan icon, feature graphic, short description, full description.
- [ ] Rilis ke Internal Testing dulu.
- [ ] Test dari link internal testing.
- [ ] Baru lanjut Closed/Open Testing atau Production.

## 9. Catatan Keamanan

- Jangan commit `android/key.properties`.
- Jangan commit `android/upload-keystore.jks`.
- Jangan commit Firebase service account JSON.
- Jangan commit Midtrans server key.
- Jangan commit Supabase service role key.
