# HealthQ

Aplikasi mobile antrean online dan informasi layanan puskesmas (Flutter + Firebase).
Tagline: *Sehat tanpa antre*. Implementasi dari dokumen Tahap 1, 2, dan 3.

## Fitur (mengikuti dokumen)

| Peran | Fitur |
| --- | --- |
| Pasien | Registrasi/login, profil (NIK, BPJS, HP), ambil antrean 3 langkah (Poli, Tanggal, Konfirmasi), pantau antrean real-time + estimasi, check-in (tombol + QR tiket), batal/jadwal ulang, jadwal dokter + sisa kuota, riwayat kunjungan, notifikasi dalam aplikasi, pengumuman/edukasi |
| Petugas | Panel antrean per poli (Panggil Berikutnya, Selesai, Lewati), daftar tunggu, walk-in (nomor dari antrean yang sama, buka kuota tambahan), verifikasi check-in |
| Admin | Dashboard (kunjungan, rata-rata tunggu, grafik per poli), kelola poli/dokter/jadwal+kuota, akun petugas, pengumuman, laporan harian/bulanan + ekspor CSV |

Ditunda sesuai Tabel 16: QR scanner, push notification FCM, ekspor PDF.

## Cara menjalankan

1. Pasang Flutter 3.24 atau lebih baru.
2. Di folder proyek, buat folder platform lalu ambil dependensi:
   ```
   flutter create --project-name healthq --org id.healthq --platforms android .
   flutter pub get
   ```
   Bila `test/widget_test.dart` dibuat otomatis dan menimbulkan galat, hapus berkas itu.
3. Di `android/app/build.gradle(.kts)` atur `minSdk = 26` (Android 8.0 ke atas).
4. Buat proyek Firebase, aktifkan **Authentication (Email/Password)** dan **Cloud Firestore**, lalu:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Perintah ini menimpa `lib/firebase_options.dart`.
5. Salin isi `firestore.rules` ke tab Rules di Firestore, lalu publikasikan.
6. `flutter run`

## Akun dan data awal

- **Pasien**: daftar langsung dari aplikasi.
- **Admin pertama**: daftar sebagai pasien, lalu di Firestore Console ubah field `role` pada dokumen `users/{uid}` menjadi `admin`. Login ulang.
- **Petugas**: dibuat admin lewat Kelola Data > Petugas.
- **Data contoh**: login admin, Kelola Data > menu titik tiga > Isi data contoh (4 poli, 4 dokter, jadwal 9 hari, 2 pengumuman).

## Struktur proyek

```
lib/
  main.dart, firebase_options.dart
  app/        routes.dart, theme.dart
  models/     user, poli, dokter, jadwal, antrean, notifikasi (+ pengumuman)
  services/   auth_service, antrean_service, jadwal_service
  providers/  auth_provider, antrean_provider
  screens/    auth, pasien, petugas, admin, shared
  widgets/    antrean_card, status_chip, primary_button, common, brand_logo, export_dialog
  utils/      validators, formatters, report
```

## Catatan rancangan

- Nomor antrean dibuat dengan Firestore transaction (tanpa nomor ganda).
- Estimasi = (nomor pasien - nomor yang sedang dilayani) x rata_durasi_menit.
- Field tambahan di luar ERD (denormalisasi agar query sederhana dan sesuai aturan privasi):
  `users.email`, `poli.kode`, `jadwal.sedang_dilayani`, dan pada `antrean`:
  `nama_poli`, `kode_poli`, `nama_pasien`, `durasi_menit`, `waktu_hadir`.
- Id jadwal = `{poliId}_{yyyy-MM-dd}` (satu jadwal per poli per hari).
- Login memakai email (Firebase Auth Email/Password).
