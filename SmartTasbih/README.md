# SmartTasbih

Aplikasi Flutter berbasis Supabase yang memadukan tasbih digital, gamifikasi Pohon Zikir, Lingkaran Doa (Prayer Circles), rekomendasi zikir kontekstual, serta fitur inovatif seperti pengingat cerdas, haptic feedback, dan dukungan tombol volume.

## Tech Stack

- Flutter 3.35 (Material 3, Riverpod 3)
- Supabase (Auth Google, Postgres, Realtime, RPC)
- Packages utama: `supabase_flutter`, `flutter_riverpod`, `lottie`, `flutter_local_notifications`, `vibration`, `volume_watcher`, `intl`, `google_fonts`

## Struktur Folder

```
lib
├── app.dart
├── bootstrap.dart
├── core/
│   ├── config/app_config.dart        # Tempat isi URL & anon key Supabase
│   ├── notifications/               # Smart reminder & celebration notif
│   ├── providers/global_providers.dart
│   └── theme/constants/widgets
├── features/
│   ├── auth/                        # Flow Google OAuth
│   ├── dashboard/                   # Pohon Zikir + rekomendasi mood
│   ├── dzikir/                      # Tasbih batching + RPC increment_goal_count
│   ├── prayer_circles/              # CRUD circle & stream realtime goals
│   ├── profile/                     # Profil & badges
│   └── recommendations/             # Data mood → zikir
└── main.dart                        # Entry point memanggil bootstrap()
```

## Setup Supabase

1. Jalankan SQL dari `App_Knowledge/Main_schema_tabel.md` untuk membuat seluruh tabel dan mengaktifkan RLS.
2. Tambahkan trigger `handle_new_user` (lihat `App_Knowledge/Project.md`) agar profil otomatis dibuat saat signup Google.
3. Deploy fungsi RPC `increment_goal_count` dari `App_Knowledge/solution.md` (digunakan batching tasbih).
4. Pastikan Realtime aktif minimal pada tabel `circle_goals`.

## Konfigurasi Aplikasi

1. Buka `lib/core/config/app_config.dart` dan ganti nilai:
   ```dart
   static const supabaseUrl = 'https://YOURPROJECT.supabase.co';
   static const supabaseAnonKey = 'public-anon-key';
   static const oauthRedirectUri = 'io.supabase.smarttasbih://login-callback/';
   ```
   Tambahkan skema deep-link yang sama di Android/iOS bila diperlukan.
2. Jalankan `flutter pub get`.
3. (Opsional) Perbarui `android/app/src/main/AndroidManifest.xml` untuk intent-filter Google OAuth sesuai bundle ID.

## Running

```bash
flutter run
```

Gunakan tab:
- **Beranda**: Lottie Pohon Zikir, mood-based zikir, shortcut pengingat.
- **Tasbih**: Riverpod StateNotifier dengan batching 10 tap / 3 detik → RPC Supabase, dukung tombol volume + haptic.
- **Lingkaran Doa**: Buat/gabung circle, stream progress goal, kirim goal aktif ke halaman Tasbih.
- **Profil**: Menampilkan level, poin, serta badges.

### Pengingat & Volume

- `flutter_local_notifications` + `timezone` untuk Smart Reminder (contoh default pukul 05:00).
- `volume_watcher` menangkap tombol volume (foreground) dan `vibration` memberi haptic berbeda setiap 33/target selesai.

## Catatan Lanjutan

- Integrasikan konten `fadilah_content` di Supabase untuk melengkapi bottom sheet zikir.
- Tambahkan edge function/logika awarding badges sesuai milestone `user_zikir_history`.
- Jika membutuhkan daftar zikir default, seed tabel `zikir_master` lewat Supabase SQL editor.
