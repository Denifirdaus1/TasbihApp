🛠️ Tech Stack - Zikir Progresif

Dokumen ini merinci semua teknologi, *framework*, dan *library* yang digunakan untuk membangun proyek.

## 1. Core Framework & Backend

* **Framework:** Flutter (Target: iOS, Android)
* **Backend as a Service (BaaS):** Supabase (Platform)
* **Database:** PostgreSQL (via Supabase)
* **Bahasa:** Dart (Flutter), SQL/PLpgSQL (Supabase Functions & Triggers)

## 2. Layanan Supabase yang Digunakan

* **Supabase Auth:**
    * Provider: Google (OAuth).
    * Integrasi: `supabase_flutter` untuk *session management* dan *deep link redirect* (`io.supabase.yourapp://login-callback/`).
* **Supabase Database (Postgres):**
    * Digunakan untuk semua data aplikasi (profil, zikir, grup).
    * *Row Level Security (RLS)* akan diaktifkan untuk semua tabel yang berisi data pengguna.
    * *Triggers* & *Functions (RPC)* digunakan untuk logika bisnis kritikal (Auth Flow, Atomic Counters).
* **Supabase Realtime:**
    * Digunakan untuk "mendengarkan" perubahan pada tabel `circle_goals`.
    * Memungkinkan UI *progress bar* di *Prayer Circles* ter-update secara otomatis di semua perangkat anggota.

## 3. Flutter: State Management

* **Pilihan Utama:** `flutter_riverpod` (Riverpod)
* **Alasan:** Sangat cocok untuk *dependency injection* dan mengelola *stream* (seperti status autentikasi `onAuthStateChange` dan *stream* Realtime Supabase). Memudahkan pemisahan logika bisnis (Notifier) dari UI (Widget).

## 4. Flutter: Paket Kunci (Pub.dev)

Berikut adalah daftar `pubspec.yaml` utama:

* `supabase_flutter`: Klien resmi Supabase. Wajib.
* `flutter_riverpod`: Untuk *state management*.
* `lottie`: Untuk animasi Pohon Zikir dan *badges*.
* `flutter_local_notifications`: Untuk "Pengingat Cerdas" (Smart Reminder) zikir.
* `vibration` atau `haptic_feedback`: Untuk fitur "Mode Tasbih Fisik".
* `volume_controller` atau `hardware_buttons`: (Perlu riset lebih lanjut) Untuk fitur "Hitung Tombol Volume" (hanya *foreground*).
* `intl`: Untuk format tanggal dan angka.
* `google_fonts`: Untuk kustomisasi UI/Tipografi.