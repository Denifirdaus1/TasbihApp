# Dzikir Planner – Revisi Spesifikasi (Daily Todo Timeline)

> **Dokumen untuk AI Agent.**  
> Fokus: menyederhanakan Dzikir Planner jadi **todo harian** berbasis dzikir yang sudah ada, bukan “koleksi dalam koleksi”.  
> Semua perubahan Supabase harus dieksekusi via **Supabase MCP**.

---

## 0. Klarifikasi Misunderstanding

**Masalah di versi sekarang:**

- Dzikir Plan saat ini dirancang seolah:
  - Satu `tasbih_goal` = satu “plan per koleksi”.
  - Di dalamnya ada `tasbih_goal_sessions` yang terasa seperti “koleksi di dalam koleksi” bagi user.
- UI-nya membuat user merasa seperti harus mengerti:
  - Koleksi → Plan → Session → Baru dzikir.
- Padahal **yang diinginkan user:**

> Tab 2 = **Dzikir Planner harian** yang isinya list **todo dzikir** (per waktu), bukan list plan per koleksi.

**Revisi konsep utama:**

- Anggap fitur ini sebagai **daily dzikir todo list** (mirip to-do list harian), bukan sistem multi-plan rumit.
- User tidak perlu mikir “plan per koleksi”.  
  Mereka hanya:
  1. Menambahkan **todo dzikir** (jam + target + dzikir yang dipilih).
  2. Melihat todo-todo hari ini dalam bentuk **timeline berdasarkan waktu**.
  3. Menyelesaikan semua todo → streak harian bertambah.

---

## 1. Desired UX – Seperti Apa yang Diinginkan User

### 1.1. Tab 2 = “Dzikir Planner (Todos Hari Ini)”

- Tab 2 menampilkan **TODOS dzikir untuk hari ini**, bukan daftar “plan per koleksi”.
- Visualnya:
  - **Timeline vertikal**:
    - Setiap todo = 1 node di timeline (bulatan) dengan garis tipis penghubung antar todo, diurutkan berdasarkan jam.
    - Contoh:
      - 07:00 – “Dzikir Pagi (Subhanallah 33x)” – progress
      - 13:00 – “Dzikir Dzuhur (Alhamdulillah 33x)” – progress
      - 18:00 – “Dzikir Petang (Campur)” – progress
      - 21:00 – “Dzikir Malam (Istighfar 100x)” – progress
- Setiap todo menampilkan:
  - Nama dzikir (dari koleksi yang sudah ada).
  - Jam target.
  - Target hitungan.
  - Progress hari ini (0/target, bar, status selesai/belum).
  - Tap ke todo:
    - **Langsung masuk ke halaman counter tasbih** dengan context todo tersebut.

### 1.2. Flow "Add Todo" (Bukan Add Plan per Koleksi)

Saat user klik tombol tambah (FAB) di Tab 2:

1. User **memilih dzikir dari koleksi yang sudah ada**:
   - Ambil dari `tasbih_collections` dan `dhikr_items`.
   - Idealnya:
     - Step 1: pilih koleksi (misal “Dzikir Setelah Sholat”).
     - Step 2: pilih dzikir item di dalamnya (jika koleksi punya beberapa).
   - Atau jika 1 koleksi = 1 item, bisa langsung.

2. User menentukan detail todo:
   - Jam (TimeOfDay).
   - Target count:
     - Default: `dhikr_items.target_count`, tapi boleh diubah.
   - Days-of-week:
     - Opsi “Setiap Hari”.
     - Atau checklist Senin–Minggu.

3. Simpan sebagai **1 row todo**:
   - Todo ini akan muncul di timeline **pada hari-hari yang sesuai** (days_of_week) dan di jam yang sudah dipilih.

### 1.3. Streak Logic (Global Harian)

- Streak **tidak per koleksi**.
- Streak dihitung berdasarkan:
  > “Apakah **SEMUA todo aktif di hari itu** selesai?”

Detail:

- Untuk tanggal D:
  - Cari semua todo (goal_sessions) yang `is_active = true` dan `days_of_week` mengandung hari D.
  - Todo dianggap **selesai** jika count di `tasbih_sessions` untuk todo tersebut di D memenuhi target.
- Jika:
  - Semua todo hari itu selesai → hari D = “success day”.
  - Minimal 1 todo tidak selesai → hari D “gagal”.
- Streak:
  - Kalau hari kemarin success dan hari ini success → `current_streak++`.
  - Kalau ada 1 hari aktif di antara yang gagal / tidak semua todo selesai → streak di-reset ke 0, lalu saat success lagi → mulai dari 1.

---

## 2. Mapping ke Schema Sekarang

Schema yang sudah ada:

```sql
CREATE TABLE public.tasbih_goals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  collection_id uuid,
  goal_type text NOT NULL CHECK (goal_type = ANY (ARRAY['daily','weekly','monthly'])),
  target_count integer NOT NULL,
  start_date date NOT NULL,
  end_date date,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  name text,
  current_streak integer DEFAULT 0,
  longest_streak integer DEFAULT 0,
  last_completed_date date,
  days_of_week int[] DEFAULT ARRAY[1,2,3,4,5,6,7] CHECK (is_valid_weekdays(days_of_week)),
  repeat_daily boolean DEFAULT true,
  total_daily_target integer DEFAULT 0,
  ...
);

CREATE TABLE public.tasbih_goal_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  goal_id uuid NOT NULL,
  name text,
  session_time time,
  target_count integer NOT NULL,
  order_index integer DEFAULT 0,
  days_of_week int[] CHECK (is_valid_weekdays(days_of_week)),
  is_active boolean DEFAULT true,
  ...
);

CREATE TABLE public.tasbih_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  collection_id uuid,
  dhikr_item_id uuid,
  count integer DEFAULT 0,
  target_count integer NOT NULL,
  session_date date DEFAULT CURRENT_DATE,
  completed_at timestamptz,
  goal_session_id uuid,
  ...
);
