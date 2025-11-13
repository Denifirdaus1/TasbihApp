# 🚀 MVP (Minimum Viable Product) - Zikir Progresif

## 1. Visi Utama MVP

MVP ini bertujuan untuk meluncurkan aplikasi zikir yang melampaui sekadar "tasbih digital". Fokusnya adalah pada **retensi pengguna** melalui gamifikasi yang memotivasi (Pohon Zikir), fitur sosial yang bermakna (Lingkaran Doa), dan pengalaman pengguna yang cerdas (Kontekstual & UI Inovatif).

## 2. Proposisi Nilai Inti

"Sebuah aplikasi zikir yang membuat ibadah harian Anda terasa progresif, terhubung, dan lebih bermakna."

## 3. Fitur MVP (In-Scope)

Fitur-fitur ini **HARUS** ada saat peluncuran:

### A. Core Fungsionalitas (Dasar)
* **Autentikasi:** Wajib menggunakan Supabase Auth (Provider: Google).
* **Tasbih Digital:** Antarmuka hitungan zikir standar.
* **Koleksi Zikir:** Pengguna dapat menambah, mengedit, dan menyimpan zikir kustom mereka.
* **Set Target:** Menetapkan target harian/sesi untuk setiap zikir.

### B. Fitur Unggulan "Pembeda" (Wajib MVP)
1.  **Gamifikasi (Zikir Progresif & Visual):**
    * **Pohon Zikir (Dhikr Tree):** Pohon digital yang tumbuh (menggunakan Lottie/animasi) seiring konsistensi (streak) zikir harian. Level pohon disimpan di tabel `profiles`.
    * **Badges & Pencapaian:** Mendapatkan *badge* untuk *milestone* (cth: "Pejuang Subuh", "Istighfar Master 10k").
2.  **Sosial (Lingkaran Doa / Prayer Circles):**
    * Membuat/Bergabung dengan grup privat (via kode unik).
    * Menetapkan target zikir kolektif untuk niat tertentu (cth: "10.000 Shalawat untuk Grup").
    * *Progress bar* kolektif yang diperbarui secara *near-realtime* menggunakan Supabase Realtime (dengan **efisiensi batching**).
3.  **Kontekstual & "Deep Content":**
    * **Zikir Sesuai Kondisi (Mood-Based):** Rekomendasi zikir berdasarkan *input* perasaan pengguna (Cemas, Syukur, Lelah).
    * **"Kenapa Zikir Ini?":** Konten *pop-up/bottom sheet* yang berisi terjemahan, tafsir singkat, atau hadis keutamaan (fadilah) zikir yang sedang dibaca.
4.  **Inovasi UI/UX (Haptic & Volume):**
    * **Mode Tasbih Fisik:** *Haptic feedback* (getaran) yang berbeda pada hitungan ke-33, 100, atau saat target tercapai.
    * **Mode Hitung Tombol Volume:** Kemampuan menghitung zikir menggunakan tombol volume **SAAT APLIKASI TERBUKA (foreground)** untuk menghindari kompleksitas *background service* di iOS/Android pada MVP.

## 4. Fitur (Out-of-Scope untuk MVP)

Fitur-fitur ini sengaja **DITUNDA** untuk rilis berikutnya agar fokus MVP terjaga:

* **Hitungan Zikir Global:** Fitur "Gerakan 1 Juta Shalawat" yang melibatkan semua pengguna. (Ditunda karena kompleksitas skala).
* **Integrasi Smartwatch (Wear OS/watchOS):** (Ditunda karena butuh pengembangan platform terpisah).
* **Mode Stealth/Background Penuh:** Menghitung zikir saat layar mati atau aplikasi di *background* menggunakan tombol volume. (Ditunda karena sangat kompleks).
* **Login selain Google:** (Facebook, Apple, Email/Password).