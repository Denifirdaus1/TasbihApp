Solusi Kritis 2: Efisiensi Database (Zikir Counter)
Masalah: Mengirim request update ke DB (dan memicu broadcast Realtime) untuk setiap 1 tap zikir (cth: 1000 tap = 1000 request) akan membengkak biaya, membebani DB, dan boros.

Solusi: Client-Side Batching dengan Debouncing + RPC (Remote Procedure Call).

Logika di Klien (Flutter - Riverpod/StateNotifier):

Pisahkan State: Buat 2 variabel:

int totalCount: Hitungan yang sudah ada di DB.

int pendingCount: Hitungan baru yang belum dikirim ke DB (default 0).

UI Instan: Angka yang dilihat pengguna adalah totalCount + pendingCount.

Saat Tap Zikir (onZikirTap):

Hanya menambah pendingCount++. UI langsung update (instan).

Cek: Jika pendingCount >= 10 (batas batch), panggil _syncToSupabase().

Jika tidak, reset Timer 3 detik (_resetSyncTimer()). Jika 3 detik tidak ada tap baru, panggil _syncToSupabase().

Fungsi Sync (_syncToSupabase):

Jika pendingCount == 0, return.

Simpan int countToSend = pendingCount.

Reset pendingCount = 0 (penting!)

Tambah totalCount += countToSend.

Panggil RPC Supabase: supabase.rpc('increment_goal_count', params: {'amount_to_add': countToSend, ...}).

Batalkan Timer.

Logika di Backend (Supabase RPC Function): Operasi ini atomik (anti-tubrukan data).

Eksekusi (Jalankan 1x di SQL Editor Supabase):
CREATE OR REPLACE FUNCTION increment_goal_count(
  goal_id_input INT,
  amount_to_add INT,
  user_id_input UUID
)
RETURNS void AS $$
BEGIN
  -- 1. Update target hitungan di Prayer Circle (jika ada goal_id)
  IF goal_id_input IS NOT NULL THEN
    UPDATE public.circle_goals
    SET current_count = current_count + amount_to_add
    WHERE id = goal_id_input;
  END IF;

  -- 2. Catat juga di histori pribadi pengguna
  -- (Kita ambil zikir_id dari goal_id jika ada, atau perlu parameter lain)
  -- Untuk contoh ini, kita asumsikan histori dicatat terpisah
  INSERT INTO public.user_zikir_history(user_id, count, zikir_id)
  VALUES (user_id_input, amount_to_add, (SELECT zikir_id FROM circle_goals WHERE id = goal_id_input));
  -- Note: Logika insert history mungkin perlu disesuaikan
END;
$$ LANGUAGE plpgsql;

Solusi Kritis 3: Penanganan Data Loss (Robust Sync)
Masalah: Jika pengguna memiliki pendingCount = 9 (belum mencapai batch 10) lalu menutup aplikasi, 9 zikir itu akan hilang.

Solusi: Memicu _syncToSupabase() saat lifecycle aplikasi berubah.

Eksekusi (Implementasi di Flutter - StatefulWidget Halaman Zikir): Gunakan dua "jaring pengaman".

Jaring 1: dispose()

Dipanggil saat pengguna pindah halaman (cth: menekan tombol "Back").
@override
  void dispose() {
    ref.read(zikirNotifierProvider.notifier).syncOnExit(); // syncOnExit() memanggil _syncToSupabase()
    super.dispose();
  }

  Jaring 2: WidgetsBindingObserver

Dipanggil saat aplikasi di-minimize, ditutup paksa, atau layar dikunci.
class _ZikirScreenState extends ConsumerState<ZikirScreen> with WidgetsBindingObserver {
    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addObserver(this);
    }

    @override
    void dispose() {
      WidgetsBinding.instance.removeObserver(this);
      ref.read(zikirNotifierProvider.notifier).syncOnExit();
      super.dispose();
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      super.didChangeAppLifecycleState(state);
      // Jika aplikasi di-minimize atau ditutup
      if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
        ref.read(zikirNotifierProvider.notifier).syncOnExit();
      }
    }
    // ... build method ...
  }

