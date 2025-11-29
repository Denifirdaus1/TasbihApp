# Dzikir Plan – Spesifikasi Fitur & Perubahan Schema  
*(Untuk AI Agent – dengan Supabase MCP)*

---

## 0. Instruksi Umum untuk Agent

1. **Gunakan Supabase MCP** untuk semua operasi yang menyentuh Supabase:
   - Eksekusi SQL (CREATE/ALTER TABLE, CREATE VIEW, CREATE FUNCTION, dll).
   - Pengecekan struktur schema yang sudah ada.
   - Pengujian query (SELECT dari view, panggil RPC, dll).

2. **Jangan** mengeksekusi SQL ini ke database lain (lokal/remote lain).  
   Targetnya adalah project Supabase yang sudah terhubung via **Supabase MCP** di Codex / environment user.

3. Semua perubahan schema harus:
   - Idempotent (gunakan `IF NOT EXISTS` bila perlu).
   - Tetap kompatibel dengan data & fitur yang sudah ada.

4. Untuk sisi Flutter:
   - Sesuaikan file, model, dan repository sesuai struktur project yang sudah ada.
   - Jangan mengubah arsitektur besar tanpa alasan (ikuti pola yang sudah dipakai app).

---

## 1. Konteks & Kondisi Saat Ini

### 1.1. Struktur Tab (Bottom Navigation)

Aplikasi Tasbih Flutter saat ini memiliki 3 tab:

- **Tab 1 – Tasbih**
  - Menampilkan **Koleksi Tasbih** seperti di screenshot (Dzikir Waktu, Dzikir Setelah Sholat, dst).
  - Menggunakan tabel:
    - `tasbih_collections`
    - `dhikr_items`
    - `tasbih_sessions` (bila sudah dimanfaatkan).

- **Tab 2 – (Kosong / akan digunakan untuk Dzikir Plan)**

- **Tab 3 – Profil**
  - Menggunakan tabel:
    - `profiles`
    - `user_badges` (jika digunakan untuk badges/pencapaian).

### 1.2. Tabel yang Sudah Ada (Relevan untuk Fitur Ini)

Schema yang relevan:

- `tasbih_collections`  
  Koleksi dzikir/tasbih (misal: Dzikir Waktu, Dzikir Setelah Sholat, Koleksi Kustom).

- `dhikr_items`  
  Item dzikir per koleksi (arab, terjemahan, target, urutan).

- `tasbih_goals`  
  Akan digunakan sebagai **Dzikir Plan** (target harian/mingguan/bulanan per koleksi).

- `tasbih_sessions`  
  Menyimpan session dzikir harian per koleksi / item (count per hari).

- `tasbih_reminders`  
  Untuk pengingat (nanti bisa diintegrasikan dengan Dzikir Plan, tapi bukan prioritas utama sekarang).

- `profiles`, `user_badges`  
  Untuk profil & pencapaian.

- `user_zikir_collections`, `user_zikir_history`, `zikir_master`  
  Saat ini dianggap sebagai sistem lain / legacy.  
  **Fitur Dzikir Plan akan fokus ke keluarga tabel `tasbih_*`.**

---

## 2. Definisi Fitur: Dzikir Plan (Tab 2)

### 2.1. Tujuan Fitur

**Dzikir Plan** adalah fitur untuk mengatur dan memantau **target dzikir** yang terhubung ke koleksi dzikir tertentu.

Contoh:

- Target harian “Dzikir Pagi & Petang” sebanyak 100x.
- Target harian “Dzikir Setelah Sholat Fardhu” 33x per hari.
- User bisa melihat:
  - Target vs progress hari ini (`today_count / target_count`).
  - Streak hari berturut-turut di mana target tercapai.
  - Longest streak sepanjang penggunaan.

### 2.2. Behavior Utama

1. **Tab 2 (Dzikir Plan)** menampilkan daftar plan aktif untuk user yang login, berdasarkan tabel `tasbih_goals`.
2. Untuk setiap plan:
   - Progres harian diambil dari `tasbih_sessions` (`session_date = CURRENT_DATE`).
   - Ditampilkan dalam bentuk angka & progress bar (`today_count / target_count`).
   - Ditampilkan juga `current_streak` dan `longest_streak`.
3. Saat user men-tap tombol **“Mulai Dzikir / Lanjutkan”** pada sebuah plan:
   - Aplikasi berpindah ke halaman detail koleksi tasbih (Tab 1 – view yang sudah ada).
   - Sesi dzikir berjalan seperti biasa, namun:
     - Session dicatat ke `tasbih_sessions` dengan `collection_id` + `user_id` (dan `dhikr_item_id` jika sudah digunakan).
4. Jika progress hari ini untuk plan tersebut mencapai atau melebihi `target_count`:
   - Sistem meng-update streak plan di `tasbih_goals`:
     - `current_streak`
     - `longest_streak`
     - `last_completed_date`

---

## 3. UX & UI Detail – Tab 2: Dzikir Plan

### 3.1. Struktur Layout

Tab 2 dijadikan halaman **“Dzikir Plan”** dengan struktur:

- **AppBar**
  - Title: `Dzikir Plan`.

- **Section 1: Ringkasan Harian (Header)**
  - Text: `Total dzikir hari ini: <sum(today_count)>`.
  - Text kecil: `Streak tertinggi: <max(longest_streak)> hari`.
  - (Opsional) Kalam/quote singkat.

- **Section 2: List Dzikir Plan**

  List scrollable berisi card, satu card per plan:

  Isi card:

  - Nama plan (atau nama koleksi):
    - Gunakan `COALESCE(goal.name, collection.name)` sebagai judul.
  - Deskripsi koleksi (`collection_description`).
  - Progress bar + text:
    - `Hari ini: <today_count> / <target_count>`.
  - Info streak:
    - `🔥 Streak: <current_streak> hari (Terpanjang: <longest_streak> hari)`.
  - Tombol `Mulai Dzikir` / `Lanjutkan`:
    - Menavigasi user ke halaman detail koleksi tasbih (page yang sudah ada di Tab 1), dengan mengirimkan:
      - `collectionId`
      - `goalId`
      - `targetCount` (opsional jika dibutuhkan di UI).

- **Floating Action Button (+)** (optional)
  - Untuk versi awal tidak wajib.
  - Jika diimplementasi:
    - Menampilkan form:
      - Pilih koleksi (`tasbih_collections` milik user).
      - Input `target_count`.
      - (Opsional) nama plan custom.
    - Insert ke `tasbih_goals`.

---

## 4. Data Model & Mapping ke Schema

### 4.1. Dzikir Plan = Row di `tasbih_goals`

Satu **Dzikir Plan** = satu baris di `tasbih_goals`.

Definisi existing:

```sql
CREATE TABLE public.tasbih_goals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  collection_id uuid,
  goal_type text NOT NULL CHECK (goal_type = ANY (ARRAY['daily'::text, 'weekly'::text, 'monthly'::text])),
  target_count integer NOT NULL,
  start_date date NOT NULL,
  end_date date,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tasbih_goals_pkey PRIMARY KEY (id),
  CONSTRAINT tasbih_goals_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT tasbih_goals_collection_id_fkey FOREIGN KEY (collection_id) REFERENCES public.tasbih_collections(id)
);
