# 📝 Product Requirements Document (PRD) - Zikir Progresif

## 1. Ikhtisar

**Masalah:** Kebanyakan aplikasi tasbih digital di pasaran bersifat "pasif" dan "utilitarians". Mereka hanya berfungsi sebagai alat hitung. Hal ini membuat pengguna kurang termotivasi untuk konsisten (menjaga *streak*) dan tidak mendapatkan pengalaman spiritual yang mendalam. Ibadah zikir terasa soliter dan progresnya tidak terlihat.

**Tujuan:** Menciptakan aplikasi zikir yang "hidup". Sebuah pendamping ibadah yang memotivasi pengguna melalui visualisasi progres (gamifikasi), menghubungkan mereka dalam doa bersama (sosial), dan memperkaya pemahaman mereka akan bacaan zikir (kontekstual).

## 2. Target Pengguna (Persona)

* **Nama:** "Fatimah, The Consistent"
* **Demografi:** Wanita, 20-35 tahun, pengguna smartphone aktif.
* **Kebutuhan:** Ia sudah rutin berzikir setelah sholat tetapi sering lupa atau tidak konsisten. Ia butuh "dorongan" kecil dan ingin ibadahnya terasa lebih bermakna. Ia juga senang menjadi bagian dari komunitas yang positif.
* **Frustrasi:** Aplikasi yang ada "membosankan", hanya angka. Jika lupa satu hari, tidak ada bedanya.

## 3. Persyaratan Fungsional & User Stories

### F-01: Autentikasi
* **User Story:** Sebagai pengguna baru, saya ingin dapat mendaftar atau masuk dengan cepat menggunakan akun Google saya agar saya tidak perlu mengisi formulir.
* **Persyaratan:**
    * Menggunakan Supabase Auth dengan Google Provider.
    * Data pengguna baru (nama, avatar) harus **otomatis** tersimpan di tabel `profiles` (dijelaskan di `project.md`).

### F-02: Gamifikasi (Pohon Zikir & Badges)
* **User Story:** Sebagai pengguna, saya ingin melihat progres visual dari konsistensi zikir saya, seperti "pohon" yang tumbuh, agar saya termotivasi untuk tidak bolong satu hari pun.
* **Persyaratan:**
    * Sistem mendeteksi zikir harian yang selesai.
    * Jika *streak* (beruntun) tercapai, `current_tree_level` di `profiles` bertambah.
    * UI menampilkan animasi Lottie/visual pohon yang berbeda sesuai level.
    * Sistem memberikan *badge* saat *milestone* tertentu (total hitungan, *streak*) tercapai.

### F-03: Lingkaran Doa (Prayer Circles)
* **User Story:** Sebagai pengguna, saya ingin membuat grup zikir privat dengan keluarga saya untuk mendoakan kakek saya yang sakit, dan kami bisa "mencicil" target 10.000 Istighfar bersama-sama.
* **Persyaratan:**
    * Pengguna dapat membuat *circle* (grup) dan mendapat kode unik.
    * Pengguna dapat bergabung dengan *circle* menggunakan kode.
    * Admin *circle* dapat membuat `circle_goals` (pilih zikir, set target).
    * Semua anggota dapat berkontribusi pada `current_count` goal tersebut.
    * *Progress bar* di halaman *circle* harus ter-update secara *near-realtime* (menggunakan Supabase Realtime + RPC *batching*).

### F-04: Konten Kontekstual
* **User Story:** Sebagai pengguna, saat saya merasa cemas, saya ingin aplikasi merekomendasikan zikir apa yang sebaiknya saya baca untuk menenangkan hati.
* **Persyaratan:**
    * Halaman utama/Modal menanyakan "Bagaimana perasaanmu?" (Cemas, Syukur, Lelah, dll).
    * Aplikasi menampilkan daftar zikir yang relevan (logika *client-side*).
    * Setiap zikir memiliki ikon (i) untuk menampilkan *bottom sheet* berisi `fadilah_content` (keutamaan, terjemahan, tafsir singkat).

### F-05: Inovasi UI/UX (Haptic & Volume)
* **User Story:** Sebagai pengguna, saya ingin merasakan getaran yang berbeda saat mencapai hitungan ke-33 agar saya tidak perlu terus-menerus melihat layar.
* **User Story 2:** Sebagai pengguna, saya ingin tetap bisa menghitung zikir saat berjalan dengan menekan tombol volume, tanpa harus menyentuh layar.
* **Persyaratan:**
    * Menggunakan `haptic_feedback` untuk *impact* ringan (per tap) dan berat (per 33/100).
    * Aplikasi mendengarkan *event* tombol volume (naik/turun) **HANYA SAAT** halaman tasbih terbuka di *foreground* untuk menambah hitungan.

## 4. Metrik Sukses MVP

* **Retensi:** D1, D7, D30 (Target utama).
* **Engagement:**
    * Jumlah *streak* harian yang aktif.
    * Jumlah *Prayer Circles* yang dibuat dan diselesaikan.
* **Adopsi Fitur:** Persentase pengguna yang menggunakan fitur selain tasbih dasar (Pohon, Circles).