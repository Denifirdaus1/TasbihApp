# Daily Streak Feature (Duolingo-style) – SmartTasbih

## 1. Tujuan Fitur

Kita mau bikin fitur **daily streak ala Duolingo**:

- User dianggap **“hadir hari itu”** kalau berhasil mencapai **minimal 100 click tasbih** dalam 1 hari.
- Kalau user memenuhi target harian:
  - Streak bertambah / dipertahankan.
- Kalau user **tidak** memenuhi target harian:
  - Streak **putus** dan di-reset.
- Fitur ini sifatnya **global per user**, **bukan per collection atau per goal**, meskipun data aslinya tetap diambil dari `tasbih_sessions` dan sistem dzikir todo list.

> Catatan: Di schema sudah ada konsep streak di `tasbih_goals` (current_streak, longest_streak, last_completed_date). Fitur ini **beda**: ini streak global seperti api Duolingo, jadi kita simpan di `profiles`.


## 2. Perubahan Database

### 2.1. Tambahan kolom di `public.profiles`

Tambahkan kolom untuk global streak:

```sql
ALTER TABLE public.profiles
ADD COLUMN daily_streak_current integer NOT NULL DEFAULT 0,
ADD COLUMN daily_streak_longest integer NOT NULL DEFAULT 0,
ADD COLUMN daily_streak_last_date date;
daily_streak_current → streak berjalan sekarang (misal 5 hari berturut-turut).

daily_streak_longest → streak terpanjang yang pernah dicapai user.

daily_streak_last_date → tanggal terakhir streak dianggap “aktif” (dipakai buat cek apakah hari ini lanjutan, reset, dll).

2.2. View agregasi dzikir harian (opsional tapi recommended)
View ini bantu hitung total klik tasbih per hari per user, dari tabel tasbih_sessions:

sql
Copy code
CREATE OR REPLACE VIEW public.vw_daily_tasbih_stats AS
SELECT
  ts.user_id,
  ts.session_date,
  SUM(ts.count) AS total_count,
  SUM(ts.target_count) AS total_target_count,
  COUNT(*) AS session_count
FROM public.tasbih_sessions ts
GROUP BY ts.user_id, ts.session_date;
Data yang dipakai untuk streak nantinya terutama user_id, session_date, dan total_count.

Sumber data sudah meng-cover:

Dzikir biasa.

Dzikir yang datang dari todo list (karena todo tetap disimpan sebagai tasbih_sessions dengan goal_session_id / dhikr_item_id / collection_id).

3. Aturan Logika Streak
3.1 Definisi dasar
MIN_DAILY_COUNT (threshold minimal dzikir harian) = 100 (hard-coded di function, atau nanti bisa dibuat configurable kalau mau).

Satu hari didefinisikan berdasarkan tasbih_sessions.session_date (tipe date, bukan timestamp).

Streak hanya berubah kalau total dzikir per hari mencapai atau melewati MIN_DAILY_COUNT.

3.2. Kondisi yang dihitung “eligible untuk streak”
Untuk user u dan tanggal d:

Hitung:

sql
Copy code
SELECT total_count
FROM public.vw_daily_tasbih_stats
WHERE user_id = u AND session_date = d;
Kalau total_count < MIN_DAILY_COUNT → tidak ada perubahan streak.

daily_streak_current tidak naik.

Kalau di hari berikutnya masih tidak memenuhi, streak akan dianggap putus saat hari yang memenuhi datang lagi.

Kalau total_count >= MIN_DAILY_COUNT → cek kombinasi tanggal dengan profiles.daily_streak_last_date:

Misalkan:

last_date = daily_streak_last_date dari profiles.

today = d.

Kasus:

Kasus 1: first time streak

last_date IS NULL

Aksi:

daily_streak_current = 1

daily_streak_longest = GREATEST(daily_streak_longest, 1) (biasanya 1)

daily_streak_last_date = today

Kasus 2: user sudah diproses untuk hari yang sama

last_date = today

Artinya streak hari ini sudah pernah dihitung → tidak perlu update (idempotent).

Kasus 3: lanjutan dari hari kemarin

last_date = today - 1

Aksi:

daily_streak_current = daily_streak_current + 1

daily_streak_longest = GREATEST(daily_streak_longest, daily_streak_current)

daily_streak_last_date = today

Kasus 4: streak putus (ada gap ≥ 2 hari)

last_date < today - 1

Aksi:

daily_streak_current = 1 (mulai streak baru)

daily_streak_longest = GREATEST(daily_streak_longest, daily_streak_current_sebelum_reset)

Bisa disimpan sementara variabel lama sebelum direset kalau di implementasi SQL.

daily_streak_last_date = today

Intinya: selama user memenuhi threshold di hari berturut-turut tanpa bolong, streak nambah terus. Begitu ada hari yang nggak memenuhi threshold dan terlewati, streak di-reset ketika user memenuhi threshold lagi.

4. Integrasi dengan Dzikir Todo List
Di schema sudah ada beberapa tabel terkait goal & todo:

tasbih_goals

tasbih_goal_sessions

tasbih_sessions (ada goal_session_id)

Prinsip integrasi:

Sumber kebenaran streak harian = tasbih_sessions

Apapun bentuk UI/fitur (dzikir manual / dzikir dari todo), selama disimpan sebagai tasbih_sessions, otomatis akan dihitung.

Dzikir todo list seharusnya:

Saat user menyelesaikan satu dzikir dari todo list, membuat atau meng-update row di tasbih_sessions dengan:

user_id

session_date (tanggal hari ini)

count (total klik di session tersebut)

goal_session_id dan dhikr_item_id kalau perlu.

Setelah tasbih_sessions diinsert/diupdate, sistem memanggil function streak (lihat bagian 5).

5. Postgres Function untuk Update Streak
Bikin function update_daily_streak(user_id uuid, for_date date DEFAULT CURRENT_DATE):

sql
Copy code
CREATE OR REPLACE FUNCTION public.update_daily_streak(p_user_id uuid, p_date date DEFAULT CURRENT_DATE)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_total_count integer;
  v_min_daily_count integer := 100; -- threshold minimal harian
  v_last_date date;
  v_current_streak integer;
  v_longest_streak integer;
BEGIN
  -- Ambil total count dzikir per hari dari view
  SELECT total_count
  INTO v_total_count
  FROM public.vw_daily_tasbih_stats
  WHERE user_id = p_user_id
    AND session_date = p_date;

  -- Kalau tidak ada data atau kurang dari threshold, tidak update streak
  IF v_total_count IS NULL OR v_total_count < v_min_daily_count THEN
    RETURN;
  END IF;

  -- Ambil data streak sekarang
  SELECT daily_streak_last_date,
         daily_streak_current,
         daily_streak_longest
  INTO v_last_date,
       v_current_streak,
       v_longest_streak
  FROM public.profiles
  WHERE id = p_user_id
  FOR UPDATE;

  IF v_last_date IS NULL THEN
    -- Pertama kali streak
    v_current_streak := 1;
  ELSIF v_last_date = p_date THEN
    -- Hari ini sudah pernah dihitung, tidak perlu apa-apa
    RETURN;
  ELSIF v_last_date = p_date - 1 THEN
    -- Lanjutan hari kemarin
    v_current_streak := v_current_streak + 1;
  ELSE
    -- Streak putus, mulai baru
    v_current_streak := 1;
  END IF;

  -- Update longest streak
  IF v_longest_streak IS NULL OR v_current_streak > v_longest_streak THEN
    v_longest_streak := v_current_streak;
  END IF;

  -- Simpan ke profiles
  UPDATE public.profiles
  SET daily_streak_current = v_current_streak,
      daily_streak_longest = v_longest_streak,
      daily_streak_last_date = p_date,
      updated_at = now()
  WHERE id = p_user_id;
END;
$$;
5.1. Kapan function ini dipanggil?
Opsinya:

Dari backend / Edge Function / server

Setiap kali app men-simpan / meng-update tasbih_sessions untuk hari ini, panggil:

sql
Copy code
SELECT public.update_daily_streak(auth.uid(), CURRENT_DATE);
Atau dari Edge Function:

ts
Copy code
const { error } = await supabase.rpc('update_daily_streak', {
  p_user_id: userId,
  p_date: sessionDate
});
Scheduled (fallback)

Bisa juga bikin cron job harian yang:

Loop semua user

Cek vw_daily_tasbih_stats untuk hari kemarin

Panggil update_daily_streak sekali per user

Tapi untuk MVP, biasanya cukup dipanggil saat tasbih_sessions berubah.

6. Edge Case yang Perlu Di-handle
User melakukan dzikir setelah jam 00:00 tapi di timezone lain
→ Di schema sekarang session_date adalah date saja (tanpa timezone).

Untuk sementara, anggap session_date ditentukan oleh client sesuai timezone user.

User spam update tasbih_sessions di hari yang sama
→ Function sudah idempotent untuk hari yang sama (kalau last_date = p_date, function akan RETURN tanpa mengubah streak).

User ganti device / reinstall app
→ Data streak tetap aman karena semua dihitung dari data di server (tasbih_sessions + profiles).

7. Perubahan di UI (High-level)
(Bagian ini buat panduan FE, bisa dilewati kalau fokus backend aja)

Tambahkan card “Streak Harian” di dashboard:

Menampilkan:

🔥 daily_streak_current (misal “🔥 7-day streak”)

“Longest streak: X days”

Indikator hari ini:

Kalau belum mencapai 100 klik → tunjukkan progress, misal 60 / 100.

Di halaman dzikir session / dzikir todo:

Setelah user menekan tasbih dan progress hari ini >= 100:

Tampilkan animasi “Streak maintained!” atau semacam badge.