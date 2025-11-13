# 🛠️ Tech Stack Tambahan: Arabic Text Rendering

Dokumen ini merinci teknologi dan aset yang diperlukan untuk menampilkan teks Arab (Tasbih, Doa, dan Ayat Al-Qur'an) dengan benar dan sesuai kaidah (tajwid/rasm) di dalam aplikasi Flutter.

## 1. Masalah Utama

Menampilkan teks Arab berbeda dari teks Latin. Kita perlu menangani dua hal:
1.  **Arah Teks (RTL):** Teks harus mengalir dari Kanan-ke-Kiri (Right-to-Left).
2.  **Font (Tipografi):** Huruf Arab memiliki bentuk sambung (ligature) dan tanda baca/harakat (diacritics) yang kompleks. Font standar HP sering gagal menampilkannya dengan benar, sehingga teks "patah" atau sulit dibaca.

## 2. Tools & Aset yang Diperlukan

Risetmu tentang `quran` dan `quran_library` sudah tepat. Kita akan kombinasikan itu dengan *font* yang tepat.

### A. Untuk Data Zikir & Ayat (Paket Pilihan)

Kamu tidak perlu keduanya, pilih satu sesuai kebutuhan:

* **1. `quran` (Paket Data):**
    * **Gunakan jika:** Kamu butuh *data mentah* ayat, terjemahan, atau audio per ayat. Ini sangat fleksibel.
    * **Contoh:** Menampilkan satu ayat sebagai "Ayat Hari Ini" atau menampilkan bacaan Tasbih (`Subhanallah...`).
    * **Status:** **Direkomendasikan** untuk fitur zikir dan *deep dive*.

* **2. `quran_library` (Paket Komponen UI):**
    * **Gunakan jika:** Kamu ingin menampilkan Al-Qur'an *satu halaman penuh* persis seperti Mushaf Madinah (Lengkap dengan layout halaman, nomor ayat, dll).
    * **Status:** **Opsional (Mungkin Overkill)** untuk MVP, kecuali kamu berencana punya fitur "Baca Qur'an" lengkap.

### B. Untuk Tampilan/Rendering (Tool Wajib)

Ini adalah "tool tambahan" yang kamu tanyakan. Kamu perlu Font Arab yang berkualitas. Cara termudah adalah menggunakan `google_fonts`.

* **1. `google_fonts` (Paket Font Dinamis):**
    * **Kenapa:** Ini cara termudah untuk memakai font Arab berkualitas tinggi (seperti Noto Naskh) tanpa harus meng-embed file `.ttf` secara manual ke proyekmu.
    * **Instalasi:** `flutter pub add google_fonts`

* **2. Font Pilihan (Yang akan ditarik oleh `google_fonts`):**
    * **`Noto Naskh Arabic`**: Ini adalah pilihan terbaik untuk teks Arab umum (Tasbih, doa, konten UI). Sangat jelas, lengkap harakatnya, dan mudah dibaca.
    * **`Cairo`**: Alternatif modern yang juga sangat baik.

## 3. Implementasi di Flutter

Berikut cara menggabungkan *data* dari zikirmu dengan *font* dari `google_fonts`.

**1. Tambahkan `google_fonts` ke `pubspec.yaml`:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.2.1 # (Ganti dengan versi terbaru)
  # 'quran' package jika kamu pakai untuk data
  quran: ^2.1.0